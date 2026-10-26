"""Fine-tuning LoRA do Qwen3-0.6B (ou outro --base) na GPU local (GTX 1650 4 GB).

* Formato idêntico ao do app no celular: template do .litertlm SEM system prompt.
* A perda é calculada só na resposta (o modelo aprende a responder, não a copiar o prompt).
* No fim salva o LoRA (out/adapter) e o modelo completo já mesclado (out/merged),
  pronto para converter em .litertlm.

Uso: python train.py [--epochs 2]
"""
import argparse
import json
import math
import os
import random
import sys
import time

import torch
from peft import LoraConfig, get_peft_model
from transformers import AutoModelForCausalLM, AutoTokenizer, get_cosine_schedule_with_warmup

sys.stdout.reconfigure(encoding='utf-8')
HERE = os.path.dirname(os.path.abspath(__file__))
BASE = 'Qwen/Qwen3-0.6B'
OUT = os.path.join(HERE, 'out')


def think_prefix(base):
    # Qwen3 sem raciocínio: bloco <think> vazio antes da resposta (formato oficial enable_thinking=False)
    return '<think>\n\n</think>\n\n' if 'qwen3' in base.lower() else ''


DATA = HERE


def load_jsonl(name):
    with open(os.path.join(DATA, name), encoding='utf-8') as f:
        return [json.loads(l) for l in f if l.strip()]


def encode(tok, ex, max_len, prefix=''):
    prompt = f"<|im_start|>user\n{ex['prompt']}<|im_end|>\n<|im_start|>assistant\n"
    answer = f"{ex['answer']}<|im_end|>\n"
    p = tok(prompt, add_special_tokens=False)['input_ids']
    r = tok(answer, add_special_tokens=False)['input_ids']
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


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument('--epochs', type=float, default=2)
    ap.add_argument('--lr', type=float, default=2e-4)
    ap.add_argument('--bs', type=int, default=4)
    ap.add_argument('--accum', type=int, default=4)
    ap.add_argument('--rank', type=int, default=64)
    ap.add_argument('--max_len', type=int, default=1024)
    ap.add_argument('--base', default=BASE)
    ap.add_argument('--data', default='.', help='pasta do dataset (ex.: closed)')
    ap.add_argument('--out', default=OUT)
    ap.add_argument('--full', action='store_true', help='fine-tuning completo (GPU grande, ex.: Colab L4/A100)')
    a = ap.parse_args()
    global DATA
    DATA = os.path.join(HERE, a.data)

    rng = random.Random(42)
    torch.manual_seed(42)
    tok = AutoTokenizer.from_pretrained(a.base)
    pre = think_prefix(a.base)
    pad_id = tok.pad_token_id

    train = [encode(tok, e, a.max_len, pre) for e in load_jsonl('train.jsonl')]
    val = [encode(tok, e, a.max_len, pre) for e in load_jsonl('eval.jsonl')]
    lens = sorted(len(x) for x, _ in train)
    print(f'Treino: {len(train)} | Val: {len(val)} | tokens p50={lens[len(lens) // 2]} max={lens[-1]}')

    amp = torch.bfloat16 if torch.cuda.is_bf16_supported() else torch.float16
    if a.full:
        # Todos os pesos treinam (memoriza melhor os fatos); pesos mestres em fp32.
        model = AutoModelForCausalLM.from_pretrained(a.base, dtype=torch.float32).cuda()
        model.config.use_cache = False
        # Prompts longos (Conselheiro do Meu Status) não cabem sem checkpointing.
        model.gradient_checkpointing_enable(gradient_checkpointing_kwargs={'use_reentrant': False})
    else:
        # Base congelada em meia precisão (cabe nos 4 GB da GTX 1650); o LoRA treina em fp32.
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
    total = int(steps_per_epoch * a.epochs)
    opt = torch.optim.AdamW([p for p in model.parameters() if p.requires_grad], lr=a.lr, weight_decay=0.0)
    sched = get_cosine_schedule_with_warmup(opt, int(total * 0.05), total)
    scaler = torch.amp.GradScaler('cuda', enabled=amp == torch.float16)

    print(f'Passos de otimização: {total} | val loss inicial: {eval_loss(model, val, a.bs, pad_id, amp):.4f}')
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
            torch.nn.utils.clip_grad_norm_(model.parameters(), 1.0)
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
            if step % steps_per_epoch == 0 or step == total:
                vl = eval_loss(model, val, a.bs, pad_id, amp)
                print(f'== val loss {vl:.4f} (passo {step})', flush=True)
                if vl < best:
                    best = vl
                    if a.full:
                        model.save_pretrained(os.path.join(a.out, 'merged'))
                        tok.save_pretrained(os.path.join(a.out, 'merged'))
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
