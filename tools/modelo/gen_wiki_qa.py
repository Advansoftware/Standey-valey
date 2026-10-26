# -*- coding: utf-8 -*-
"""Gera perguntas e respostas sobre TODOS os fatos de cada trecho da wiki offline do app.

Roda no Colab (GPU grande) com vLLM e um modelo professor (Qwen3-14B por padrão).
Cada trecho de assets/wiki/pages.json.gz vira de 4 a 15 pares pergunta/resposta, cada um com
uma segunda forma de perguntar (q2, usada na avaliação), mais até 2 "pegadinhas" (pergunta com
um detalhe errado e resposta que corrige). Retoma de onde parou se for interrompido.

As respostas ainda passam por build_dataset_full.py, que descarta o que não estiver no texto.

Uso (no Colab): python gen_wiki_qa.py --pages pages.json.gz --out wiki_qa.jsonl
"""
import argparse
import gzip
import json
import os
import re
import time

PROMPT = """Página da wiki de Stardew Valley: {title}
Seção: {section}
Texto:
<<<
{text}
>>>

Crie perguntas e respostas que cubram TODOS os fatos deste texto: nomes, lugares, quem dá ou vende,
preços, datas, horários, estações, quantidades, requisitos, recompensas, efeitos e como conseguir.
Regras:
- Pergunte como um jogador perguntaria no celular, citando o assunto pelo nome (nunca "neste texto",
  "nesta seção", "nesta página").
- A resposta usa SÓ o que está no texto, é completa e curta (1 a 3 frases) e repete o nome do assunto.
- Para cada pergunta, escreva outra forma de perguntar a mesma coisa (q2), com outras palavras.
- Inclua até 2 pegadinhas: perguntas com um detalhe errado (cor, lugar, pessoa ou número trocado);
  a resposta diz que o detalhe está errado e dá o dado certo do texto.
- Se o texto for só menu, lista de links, galeria ou não tiver fatos úteis, devolva listas vazias.
Responda só com JSON: {{"qa":[{{"q":"...","q2":"...","a":"..."}}],"pegadinhas":[{{"q":"...","a":"..."}}]}}"""


def chunks(pages):
    """(id, título, seção, texto) de cada trecho; a seção vem do último '## ' visto na página."""
    for pi, p in enumerate(pages):
        title = (p.get('t') or '').strip()
        section = title
        for ci, c in enumerate(p.get('c') or []):
            text = str(c).strip()
            heads = re.findall(r'^## (.+)$', text, flags=re.M)
            sec_here = heads[0].strip() if text.startswith('## ') else section
            if len(text) >= 60:
                yield f'{pi}:{ci}', title, sec_here, text
            if heads:
                section = heads[-1].strip()


def parse(out):
    m = re.search(r'\{.*\}', out, flags=re.S)
    if not m:
        return None
    try:
        d = json.loads(m.group(0))
    except json.JSONDecodeError:
        return None
    qa = [x for x in d.get('qa') or [] if isinstance(x, dict) and x.get('q') and x.get('a')]
    pg = [x for x in d.get('pegadinhas') or [] if isinstance(x, dict) and x.get('q') and x.get('a')]
    return qa, pg


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument('--pages', default='pages.json.gz')
    ap.add_argument('--out', default='wiki_qa.jsonl')
    ap.add_argument('--model', default='Qwen/Qwen3-14B')
    ap.add_argument('--batch', type=int, default=512)
    ap.add_argument('--limit', type=int, default=0)
    a = ap.parse_args()

    from vllm import LLM, SamplingParams

    pages = json.load(gzip.open(a.pages))
    todo = list(chunks(pages))
    if a.limit:
        todo = todo[:a.limit]
    done = set()
    if os.path.exists(a.out):
        with open(a.out, encoding='utf-8') as f:
            done = {json.loads(l)['id'] for l in f if l.strip()}
    todo = [t for t in todo if t[0] not in done]
    print(f'Trechos: {len(todo)} a fazer ({len(done)} já feitos)', flush=True)

    llm = LLM(a.model, max_model_len=4096, gpu_memory_utilization=0.92)
    sp = SamplingParams(temperature=0.3, top_p=0.9, max_tokens=2200)
    t0 = time.time()
    with open(a.out, 'a', encoding='utf-8') as f:
        for k in range(0, len(todo), a.batch):
            part = todo[k:k + a.batch]
            msgs = [[{'role': 'user', 'content': PROMPT.format(title=t, section=s, text=x)}] for _, t, s, x in part]
            outs = llm.chat(msgs, sp, chat_template_kwargs={'enable_thinking': False}, use_tqdm=False)
            bad = 0
            for (cid, t, s, x), o in zip(part, outs):
                r = parse(o.outputs[0].text)
                if r is None:
                    bad += 1
                    r = ([], [])
                f.write(json.dumps({'id': cid, 'title': t, 'section': s, 'text': x,
                                    'qa': r[0], 'pegadinhas': r[1]}, ensure_ascii=False) + '\n')
            f.flush()
            el = time.time() - t0
            n = k + len(part)
            print(f'{n}/{len(todo)} trechos | JSON inválido no lote: {bad} | {el / 60:.1f} min '
                  f'(faltam ~{el / n * (len(todo) - n) / 60:.0f} min)', flush=True)
    print('GERADO', flush=True)


if __name__ == '__main__':
    main()
