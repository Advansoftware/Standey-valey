"""Testa o modelo no formato EXATO do app (template do .litertlm, sem system).

Uso:
  python evaluate.py                      # modelo base (antes do treino)
  python evaluate.py --model out/merged   # modelo treinado

Métricas:
  * fatos: % dos números e nomes da resposta de referência que aparecem na resposta
    gerada (paráfrases que o modelo nunca viu no treino).
  * reais: perguntas reais do app com fatos esperados.
  * loops: respostas que repetem uma frase 3x ou mais.
"""
import argparse
import json
import os
import re
import sys
import time

import torch
from transformers import AutoModelForCausalLM, AutoTokenizer

sys.stdout.reconfigure(encoding='utf-8')
HERE = os.path.dirname(os.path.abspath(__file__))
BASE = 'google/gemma-4-E2B-it'


def device_chat_text(tok, prompt):
    """Mesmo prompt do treino e do celular: template do modelo, sem system e sem raciocínio."""
    return tok.apply_chat_template([{'role': 'user', 'content': prompt}], tokenize=False,
                                   add_generation_prompt=True, enable_thinking=False)


DATA = HERE


def load_jsonl(name):
    with open(os.path.join(DATA, name), encoding='utf-8') as f:
        return [json.loads(l) for l in f if l.strip()]


_FACT = re.compile(r'\d[\d.,]*|[A-ZÀ-Ý][a-zà-ÿ]{2,}(?:[ -][A-ZÀ-Ý][a-zà-ÿ]+)*')
_SKIP = {'Sim', 'Não', 'Depois', 'Primeiro', 'Para', 'Pesque', 'Vale', 'Dê', 'Bons', 'Ama', 'Mora',
         'Aniversário', 'Recompensa', 'Pacote', 'Lucro', 'Produção', 'Plante', 'Estação', 'Horário',
         'Clima', 'Dificuldade', 'Completando', 'Mas', 'Em', 'No', 'Ao', 'Vive', 'Vende', 'Data',
         'Utilidade', 'Preço', 'Onde', 'Ingredientes', 'Receita', 'Energia', 'Bônus', 'Custo',
         'Materiais', 'Tempo', 'Construtor', 'Capacidade', 'Contém', 'Solta', 'Vida', 'Dano', 'Tipo'}


def facts(ref):
    out = []
    for m in _FACT.findall(ref):
        m = m.rstrip('.,')
        if m and m not in _SKIP and m not in out:
            out.append(m)
    return out


def norm(s):
    return re.sub(r'\s+', ' ', s.lower())


def has_loop(text):
    sents = [s.strip().lower() for s in re.split(r'[.\n!?]', text) if len(s.strip()) > 12]
    return any(sents.count(s) >= 3 for s in set(sents))


@torch.no_grad()
def generate(model, tok, prompts, max_new=220, bs=8):
    outs = []
    tok.padding_side = 'left'
    from train import answer_suffix
    end_ids = [tok.eos_token_id] + tok(answer_suffix(tok).strip(), add_special_tokens=False)['input_ids'][:1]
    for i in range(0, len(prompts), bs):
        batch = [device_chat_text(tok, p) for p in prompts[i:i + bs]]
        enc = tok(batch, return_tensors='pt', padding=True, add_special_tokens=False).to(model.device)
        gen = model.generate(**enc, max_new_tokens=max_new, do_sample=False, repetition_penalty=1.0,
                             eos_token_id=end_ids, pad_token_id=tok.pad_token_id if tok.pad_token_id is not None else tok.eos_token_id)
        for row in gen[:, enc['input_ids'].shape[1]:]:
            txt = tok.decode(row, skip_special_tokens=True)
            outs.append(re.sub(r'<think>.*?</think>', '', txt, flags=re.S).strip())
    return outs


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument('--model', default=BASE)
    ap.add_argument('--base', default=BASE, help='tokenizer/base quando usar --adapter')
    ap.add_argument('--adapter', default=None, help='pasta do LoRA (sem merge)')
    ap.add_argument('--data', default='.', help='pasta do dataset (ex.: closed)')
    ap.add_argument('--limit', type=int, default=0)
    ap.add_argument('--status', default=None, help='pasta com eval.jsonl do Conselheiro (Meu Status)')
    ap.add_argument('--train_sample', type=int, default=0, help='testa N perguntas exatas do treino')
    ap.add_argument('--out', default=None)
    a = ap.parse_args()
    global DATA
    DATA = os.path.join(HERE, a.data)

    tok = AutoTokenizer.from_pretrained(a.model if not a.adapter else a.base)
    model = AutoModelForCausalLM.from_pretrained(a.model, dtype=torch.bfloat16).cuda().eval()
    if a.adapter:
        from peft import PeftModel
        model = PeftModel.from_pretrained(model, a.adapter).eval()

    evals = load_jsonl('eval.jsonl')
    real = load_jsonl('real_questions.jsonl')
    if a.limit:
        evals = evals[:a.limit]

    train_rows = []
    if a.train_sample:
        import random
        pool = load_jsonl('train.jsonl')
        train_rows = random.Random(7).sample(pool, min(a.train_sample, len(pool)))

    t0 = time.time()
    gens = generate(model, tok, [e['prompt'] for e in evals])
    tgens = generate(model, tok, [e['prompt'] for e in train_rows]) if train_rows else []
    rgens = generate(model, tok, [r['prompt'] for r in real])
    dt = time.time() - t0

    log = []

    def score(rows, outs, cat=None):
        tot_f = hit_f = exact = lp = 0
        for e, g in zip(rows, outs):
            fs = facts(e['answer'])
            h = sum(1 for f in fs if norm(f) in norm(g))
            tot_f += len(fs)
            hit_f += h
            lp += has_loop(g)
            exact += (h == len(fs))
            log.append({'q': e['q'], 'cat': cat or e['cat'], 'ref': e['answer'], 'gen': g, 'facts': fs, 'hit': h})
        return tot_f, hit_f, exact, lp

    tot_f, hit_f, exact, loops = score(evals, gens)
    t_tot = t_hit = t_exact = 0
    if train_rows:
        t_tot, t_hit, t_exact, t_loops = score(train_rows, tgens, '_train')
        loops += t_loops

    real_ok = 0
    print('\n================ PERGUNTAS REAIS ================')
    for r, g in zip(real, rgens):
        ok = all(norm(k) in norm(g) for k in r['expect'])
        real_ok += ok
        loops += has_loop(g)
        print(f"\n[{'OK ' if ok else 'ERR'}] {r['q']}  (espera: {r['expect']})\n  -> {g[:400]}")
        log.append({'q': r['q'], 'cat': '_real', 'expect': r['expect'], 'gen': g, 'ok': ok})

    print('\n================ AMOSTRAS (paráfrases inéditas) ================')
    for l in log[:8]:
        print(f"\nP: {l['q']}\nREF: {l['ref']}\nGEN: {l['gen'][:400]}")

    n = len(evals) + len(real) + len(train_rows)
    print('\n================ RESUMO ================')
    print(f'Modelo: {a.adapter or a.model}')
    if train_rows:
        print(f'Perguntas do treino 100% corretas: {t_exact}/{len(train_rows)} = {100 * t_exact / len(train_rows):.1f}%'
              f'  (fatos {100 * t_hit / max(t_tot, 1):.1f}%)')
    print(f'Fatos corretos (paráfrases inéditas): {hit_f}/{tot_f} = {100 * hit_f / max(tot_f, 1):.1f}%')
    print(f'Respostas 100% corretas: {exact}/{len(evals)} = {100 * exact / max(len(evals), 1):.1f}%')
    print(f'Perguntas reais corretas: {real_ok}/{len(real)}')
    print(f'Respostas com loop: {loops}/{n}')
    print(f'Tempo: {dt:.0f}s')
    if a.status:
        rows = [json.loads(l) for l in open(os.path.join(HERE, a.status, 'eval.jsonl'), encoding='utf-8')]
        outs = generate(model, tok, [r['prompt'] for r in rows], max_new=160, bs=4)
        fmt = first = 0
        for r, g in zip(rows, outs):
            lines = [l.strip() for l in g.split('\n') if l.strip()]
            ok = 1 <= len(lines) <= 3 and all(len(l.split('|')) == 3 for l in lines)
            fmt += ok
            ref1 = r['answer'].split('\n')[0].split('|')[0].strip().lower()
            first += bool(lines) and lines[0].split('|')[0].strip().lower() == ref1
            log.append({'q': r['q'], 'cat': '_status', 'ref': r['answer'], 'gen': g, 'ok': ok})
        print(f'Conselheiro: formato AÇÃO|LUGAR|MOTIVO ok {fmt}/{len(rows)} | prioridade certa {first}/{len(rows)}')
        for r, g in list(zip(rows, outs))[:3]:
            print(f"\nREF:\n{r['answer']}\nGEN:\n{g}")
    if a.out:
        with open(a.out, 'w', encoding='utf-8') as f:
            json.dump(log, f, ensure_ascii=False, indent=1)


if __name__ == '__main__':
    main()
