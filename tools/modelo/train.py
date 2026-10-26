"""Fine-tuning do Espírito do Vale (Gemma 4, Qwen3 ou outro --base).

* O prompt é montado pelo chat template do próprio modelo, sem system prompt e sem raciocínio
  (enable_thinking=False), igual ao que o LiteRT-LM monta no celular.
* Linhas {"prompt","answer"}: a perda é só na resposta. Linhas {"text"}: texto bruto da wiki,
  perda em tudo (o modelo lê a wiki inteira, não só as perguntas).
* --full treina todos os pesos de texto; torres de imagem/áudio e tabelas de embedding ficam
  congeladas. Sem --full, LoRA. O melhor checkpoint vai para out/merged, pronto para converter.

Uso: python train.py --base google/gemma-4-E2B-it --data full --full
"""
import argparse
import json
import math
import os
import random
import re
import shutil
import sys
import time

import torch
from transformers import AutoModelForCausalLM, AutoTokenizer, get_cosine_schedule_with_warmup

sys.stdout.reconfigure(encoding='utf-8')
HERE = os.path.dirname(os.path.abspath(__file__))
BASE = 'google/gemma-4-E2B-it'
OUT = os.path.join(HERE, 'out')
DATA = HERE
# Imagem, áudio e tabelas de embedding: não guardam os fatos do jogo e ocupam muita memória.
FROZEN = re.compile(r'vision|audio|embed|lm_head')


def load_jsonl(name):
    with open(os.path.join(DATA, name), encoding='utf-8') as f:
        return [json.loads(l) for l in f if l.strip()]


def chat_prompt(tok, question):
    """Prompt do usuário + início da resposta, pelo template do modelo (sem raciocínio)."""
    return tok.apply_chat_template([{'role': 'user', 'content': question}], tokenize=False,
                                   add_generation_prompt=True, enable_thinking=False)


def answer_suffix(tok):
    """O que o template põe depois do texto da resposta (ex.: '<|im_end|>' + quebra de linha)."""
    full = tok.apply_chat_template([{'role': 'user', 'content': 'P'}, {'role': 'assistant', 'content': 'RESPOSTA'}],
                                   tokenize=False, enable_thinking=False)
    tail = full[full.rindex('RESPOSTA') + len('RESPOSTA'):]
    return tail or (tok.eos_token or '')


def encode(tok, ex, max_len, suffix):
    if 'text' in ex:
        ids = tok(ex['text'], add_special_tokens=False)['input_ids']
        if tok.bos_token_id is not None:
            ids = [tok.bos_token_id] + ids
        ids = ids[:max_len]
        return ids, list(ids)
    p = tok(chat_prompt(tok, ex['prompt']), add_special_tokens=False)['input_ids']
    r = tok(ex['answer'] + suffix, add_special_tokens=False)['input_ids']
    ids = (p + r)[:max_len]
    labels = ([-100] * len(p) + r)[:max_len]
    return ids, labels


def batches(data, bs, rng):
    # agrupa por tamanho parecido (menos padding = mais rápido), em ordem aleatória
    idx = sorted(range(len(data)), key=lambda i: len(data[i][0]) + rng.random() * 40)
    chunks = [idx[i:i + bs] for i in range(0, len(idx), bs)]
    rng.shuffle(chunks)
    return chunks


def collate(data, ids, pad_id):
    L = max(len(data[i][0]) for i in ids)
    inp = torch.full((len(ids), L), pad_id)
    lab = torch.full((len(ids), L), -100)
    att = torch.zeros((len(ids), L), dtype=torch.long)
    for j, i in enumerate(ids):
        x, y = data[i]
        inp[j, :len(x)] = torch.tensor(x)
        lab[j, :len(y)] = torch.tensor(y)
        att[j, :len(x)] = 1
    return inp.cuda(), lab.cuda(), att.cuda()


@torch.no_grad()
def eval_loss(model, data, bs, pad_id, amp=torch.float16):
    model.eval()
    tot = n = 0
    for k in range(0, len(data), bs):
        inp, lab, att = collate(data, list(range(k, min(k + bs, len(data)))), pad_id)
        with torch.autocast('cuda', dtype=amp):
            loss = model(input_ids=inp, attention_mask=att, labels=lab).loss
        tot += loss.item()
        n += 1
    model.train()
    return tot / max(n, 1)


def save_full(model, base, out):
    """Salva em bf16 com os arquivos do tokenizer/processador (o conversor precisa deles)."""
    model.save_pretrained(out, state_dict={k: v.to(torch.bfloat16) for k, v in model.state_dict().items()})
    if os.path.isdir(base):
        src = base
    else:
        from huggingface_hub import snapshot_download
        src = snapshot_download(base, allow_patterns=['*.json', '*.jinja', '*.model'])
    for f in os.listdir(src):
        if f.endswith(('.jinja', '.model')) or f.startswith(
                ('tokenizer', 'processor', 'preprocessor', 'chat_template', 'generation_config', 'special_tokens')):
            shutil.copy(os.path.join(src, f), os.path.join(out, f))


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument('--epochs', type=float, default=2)
    ap.add_argument('--lr', type=float, default=2e-4)
    ap.add_argument('--bs', type=int, default=4)
    ap.add_argument('--accum', type=int, default=4)
    ap.add_argument('--rank', type=int, default=64)
    ap.add_argument('--max_len', type=int, default=1024)
    ap.add_argument('--base', default=BASE)
    ap.add_argument('--data', default='.', help='pasta do dataset (ex.: full)')
    ap.add_argument('--out', default=OUT)
    ap.add_argument('--full', action='store_true', help='fine-tuning completo (GPU grande, ex.: Colab H100)')
    ap.add_argument('--evals_per_epoch', type=int, default=1)
    a = ap.parse_args()
    global DATA
    DATA = os.path.join(HERE, a.data)

    rng = random.Random(42)
    torch.manual_seed(42)
    tok = AutoTokenizer.from_pretrained(a.base)
    suffix = answer_suffix(tok)
    print('Prompt de exemplo:', repr(chat_prompt(tok, 'Pergunta?')), '| fim da resposta:', repr(suffix), flush=True)
    pad_id = tok.pad_token_id if tok.pad_token_id is not None else tok.eos_token_id

    train = [encode(tok, e, a.max_len, suffix) for e in load_jsonl('train.jsonl')]
    val = [encode(tok, e, a.max_len, suffix) for e in load_jsonl('eval.jsonl') if 'text' not in e]
    lens = sorted(len(x) for x, _ in train)
    print(f'Treino: {len(train)} | Val: {len(val)} | tokens total={sum(lens)} p50={lens[len(lens) // 2]} max={lens[-1]}')

    amp = torch.bfloat16 if torch.cuda.is_bf16_supported() else torch.float16
    if a.full:
        # Pesos de texto treinam em fp32 (memoriza melhor os fatos); o resto fica congelado em bf16.
        model = AutoModelForCausalLM.from_pretrained(a.base, dtype=amp).cuda()
        model.config.use_cache = False
        frozen = trainable = 0
        for n, p in model.named_parameters():
            if FROZEN.search(n):
                p.requires_grad = False
                frozen += p.numel()
            else:
                p.data = p.data.float()
                trainable += p.numel()
        print(f'Parâmetros treináveis: {trainable / 1e9:.2f}B | congelados: {frozen / 1e9:.2f}B', flush=True)
        # Prompts longos (Conselheiro do Meu Status) não cabem sem checkpointing.
        model.gradient_checkpointing_enable(gradient_checkpointing_kwargs={'use_reentrant': False})
        model.enable_input_require_grads()
    else:
        from peft import LoraConfig, get_peft_model
        # Base congelada em meia precisão (cabe na GTX 1650 de 4 GB); o LoRA treina em fp32.
        model = AutoModelForCausalLM.from_pretrained(a.base, dtype=amp).cuda()
        model.gradient_checkpointing_enable(gradient_checkpointing_kwargs={'use_reentrant': False})
        model.enable_input_require_grads()
        model.config.use_cache = False
        model = get_peft_model(model, LoraConfig(
            r=a.rank, lora_alpha=a.rank * 2, lora_dropout=0.05, task_type='CAUSAL_LM',
            target_modules=['q_proj', 'k_proj', 'v_proj', 'o_proj', 'gate_proj', 'up_proj', 'down_proj']))
        for p in model.parameters():
            if p.requires_grad:
                p.data = p.data.float()
        model.print_trainable_parameters()

    steps_per_epoch = math.ceil(len(train) / a.bs / a.accum)
    eval_every = max(1, steps_per_epoch // a.evals_per_epoch)
    total = int(steps_per_epoch * a.epochs)
    opt = torch.optim.AdamW([p for p in model.parameters() if p.requires_grad], lr=a.lr, weight_decay=0.0)
    sched = get_cosine_schedule_with_warmup(opt, int(total * 0.03), total)
    scaler = torch.amp.GradScaler('cuda', enabled=amp == torch.float16)

    print(f'Passos de otimização: {total} | val loss inicial: {eval_loss(model, val, a.bs, pad_id, amp):.4f}', flush=True)
    model.train()
    step = micro = 0
    run = 0.0
    t0 = time.time()
    best = float('inf')
    done = False
    while not done:
        for ids in batches(train, a.bs, rng):
            inp, lab, att = collate(train, ids, pad_id)
            with torch.autocast('cuda', dtype=amp):
                loss = model(input_ids=inp, attention_mask=att, labels=lab).loss / a.accum
            scaler.scale(loss).backward()
            run += loss.item()
            micro += 1
            if micro % a.accum:
                continue
            scaler.unscale_(opt)
            torch.nn.utils.clip_grad_norm_([p for p in model.parameters() if p.requires_grad], 1.0)
            scaler.step(opt)
            scaler.update()
            opt.zero_grad(set_to_none=True)
            sched.step()
            step += 1
            if step % 10 == 0:
                el = time.time() - t0
                print(f'passo {step}/{total} loss={run / 10:.4f} lr={sched.get_last_lr()[0]:.2e} '
                      f'{el / 60:.1f}min (faltam ~{el / step * (total - step) / 60:.0f}min) '
                      f'vram={torch.cuda.max_memory_allocated() / 2**30:.2f}GB', flush=True)
                run = 0.0
            if step % eval_every == 0 or step == total:
                vl = eval_loss(model, val, a.bs, pad_id, amp)
                print(f'== val loss {vl:.4f} (passo {step})', flush=True)
                if vl < best:
                    best = vl
                    if a.full:
                        save_full(model, a.base, os.path.join(a.out, 'merged'))
                    else:
                        model.save_pretrained(os.path.join(a.out, 'adapter'))
                    print('   melhor modelo salvo', flush=True)
            if step >= total:
                done = True
                break

    print(f'Treino concluído em {(time.time() - t0) / 60:.1f} min. Melhor val loss: {best:.4f}')
    if a.full:
        print('Modelo salvo em', os.path.join(a.out, 'merged'))
        return
    del model, opt
    torch.cuda.empty_cache()

    from peft import PeftModel
    base = AutoModelForCausalLM.from_pretrained(a.base, dtype=torch.float32)
    merged = PeftModel.from_pretrained(base, os.path.join(a.out, 'adapter')).merge_and_unload()
    merged.to(torch.float16).save_pretrained(os.path.join(a.out, 'merged'))
    tok.save_pretrained(os.path.join(a.out, 'merged'))
    print('Modelo mesclado salvo em', os.path.join(a.out, 'merged'))


if __name__ == '__main__':
    main()
