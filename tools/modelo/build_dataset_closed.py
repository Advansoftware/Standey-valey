"""Dataset "de memória" (sem RAG) para o Espírito do Vale.

O app envia ao modelo treinado SOMENTE a pergunta do usuário (sem trechos da
wiki). Então o modelo precisa ter os fatos nos pesos:
  * Enciclopédia (565 entradas, 18 categorias): todas as paráfrases das regras do v2,
    com as respostas montadas a partir da entrada completa.
  * Wiki do app (assets/wiki/pages.json.gz): "o que é X" -> resumo da página.
  * Guias, "não encontrei", fora de assunto e cumprimentos.

Validação: paráfrases inéditas de fatos que estão no treino (mede se ele
aprendeu o fato, e não só a frase exata).
"""
import gzip
import json
import os
import re
import sys
from collections import Counter

sys.stdout.reconfigure(encoding='utf-8')
HERE = os.path.dirname(os.path.abspath(__file__))

# Reaproveita as regras de perguntas/respostas do v2 (tudo antes de augment()).
_full = open(os.path.join(HERE, 'build_dataset_v2.py'), encoding='utf-8').read()


def _block(start, end):
    i = _full.index(start)
    return _full[i:_full.index(end, i)]


_src = _full[:_full.index('# --------------------------------------------------------------------------\ndef augment')]
# listas de "não encontrei", fora de assunto, cumprimentos e perguntas reais
_src += _block('FAKE = [', 'for x in FAKE:') + _block('OFFTOPIC = [', 'for q in OFFTOPIC:') + _block('REAL = [', 'real = []')
_src = _src.replace("index = build_index(entries, with_wiki=True)", "index = None").replace("print(f'Docs no índice: {len(index.docs)}')", '')
exec(compile(_src, 'build_dataset_v2.py', 'exec'))

from app_replica import ASSETS  # noqa: E402


class FullCtx:
    """Sem RAG o modelo 'vê' a entrada inteira: todo fato existente pode ser usado."""

    def has(self, v):
        return bool(v and ws(v))


FULL = FullCtx()


def augment_all(q):
    """Variações de digitação e de jeito de perguntar que o usuário usa no celular."""
    out = {q}
    out.add(normalize(q))
    out.add(q.lower().rstrip('?'))
    base = q.rstrip('?')
    out.add(rng.choice([f'{base} no Stardew?', f'me diz: {base[:1].lower() + base[1:]}?',
                        f'{base} no jogo?', f'stardew {base.lower()}']))
    return list(out)


train, evals = [], []
stats = Counter()


def add(rows, q, a, cat, entry):
    rows.append({'prompt': q, 'answer': a.strip(), 'cat': cat, 'entry': entry, 'q': q})


# ---- Enciclopédia ----
eval_entries = set(rng.sample([e['id'] for e in entries if e['cat'] != 'guia'], k=int(len(entries) * 0.15)))
for e in entries:
    for qs, fn in tasks_for(e):
        ans = fn(FULL)
        if not ans:
            stats['noans'] += 1
            continue
        qs = list(qs)
        rng.shuffle(qs)
        held = qs.pop() if (e['id'] in eval_entries and len(qs) >= 3) else None
        for q in qs:
            for qq in augment_all(q):
                add(train, qq, ans, e['cat'], e['id'])
        if held:
            add(evals, held, ans, e['cat'], e['id'])
        stats['ok'] += 1

# ---- Guias divididos por seção (resposta = a seção que trata do assunto) ----
from app_replica import tokenize  # noqa: E402


def guide_sections(e):
    out = []
    for raw in re.split(r'\n(?=## )', e.get('body') or ''):
        lines = [l.strip() for l in raw.strip().split('\n') if l.strip()]
        if not lines:
            continue
        head = lines[0][3:].strip() if lines[0].startswith('## ') else name_of(e)
        body = lines[1:] if lines[0].startswith('## ') else lines
        txt = []
        for l in body:
            txt.append('- ' + l.lstrip('•').strip() if l.startswith('•') else l)
        content = f'**{head}**\n' + '\n'.join(txt)
        if len(body) >= 1 and len(content) > 40:
            out.append((head, content[:900]))
    return out


SEC_Q = ['{h}?', '{h} no Stardew', 'Me explica: {h}', '{g}: {h}', 'Dicas de {hl}']
guide_secs = 0
for e in entries:
    if e['cat'] != 'guia':
        continue
    secs = guide_sections(e)
    for head, content in secs:
        for t in SEC_Q:
            add(train, t.format(h=head, hl=head.lower(), g=name_of(e)), content, 'guia', e['id'])
        guide_secs += 1
    # perguntas fixas do guia -> a seção com mais palavras em comum
    for q in GUIA_QS.get(e['id'], []):
        qt = set(tokenize(q))
        best = max(secs, key=lambda hc: len(qt & set(tokenize(hc[0] + ' ' + hc[1])))) if secs else None
        if best:
            for qq in augment_all(q):
                add(train, qq, best[1], 'guia', e['id'])
print('Seções de guia:', guide_secs)

# ---- Ficha completa de cada entrada (todos os campos) ----
FICHA_Q = ['Me fale sobre {n}', 'O que é {n}?', 'Tudo sobre {n}', 'ficha de {n}', '{n}']
for e in entries:
    if e['cat'] == 'guia' or not e.get('fields'):
        continue
    keys = []
    for f in e['fields']:
        if f and f[0] not in keys:
            keys.append(f[0])
    ans = fields_answer(e, FULL, keys, maxk=9)
    d = first_sentence(e.get('desc', ''))
    if ans and d:
        ans = ans + '\n' + d
    if not ans:
        continue
    for t in rng.sample(FICHA_Q, 3):
        add(train, t.format(n=name_of(e)), ans, e['cat'], e['id'])

# ---- Wiki do app ----
entry_names = {normalize(name_of(e)) for e in entries} | {normalize(e.get('en') or '') for e in entries}
_SKIP_LINE = re.compile(r'^(Para |Veja também|Ver também|Este artigo|Esta página|Informações$|## |• )')


def wiki_summary(chunk, max_chars=420):
    sents = []
    for line in str(chunk).split('\n'):
        line = line.strip()
        if not line or _SKIP_LINE.match(line) or len(line) < 40 or line.endswith(':'):
            continue
        for s in re.split(r'(?<=[.!?])\s+', line):
            if sum(len(x) for x in sents) + len(s) > max_chars and sents:
                return ' '.join(sents)
            sents.append(s)
        if len(sents) >= 3:
            break
    return ' '.join(sents)


WIKI_Q = ['O que é {t}?', 'Me fale sobre {t}', 'O que você sabe sobre {t}?', '{t}, o que é?']
wiki_added = 0
for p in json.load(gzip.open(os.path.join(ASSETS, 'wiki', 'pages.json.gz'))):
    t = (p.get('t') or '').strip()
    chunks = p.get('c') or []
    if not t or not chunks or normalize(t) in entry_names or ':' in t:
        continue
    s = wiki_summary(chunks[0])
    if len(s) < 60:
        continue
    qs = rng.sample(WIKI_Q, 4)
    for q in qs[:3]:
        add(train, q.format(t=t), s, '_wiki', t)
    if rng.random() < 0.05:
        add(evals, qs[3].format(t=t), s, '_wiki', t)
    wiki_added += 1
print('Páginas da wiki usadas:', wiki_added)

# ---- Não encontrei / fora de assunto / cumprimentos ----
for x in FAKE:
    for t in FAKE_Q:
        add(train, t.format(x=x), rng.choice(NOTFOUND).format(x=x).replace(' nos dados do guia', '')
            .replace(' nos dados do jogo que tenho aqui', ' no Stardew Valley'), '_notfound', '_notfound')
for q in OFFTOPIC:
    for qq in {q, q.lower()}:
        add(train, qq, OFF_ANS, '_off', '_off')
for q, a in GREET:
    for qq in {q, q.lower()}:
        add(train, qq, a, '_greet', '_greet')

status_path = os.path.join(HERE, 'status', 'train.jsonl')
if os.path.exists(status_path):
    status_rows = [json.loads(l) for l in open(status_path, encoding='utf-8')]
    train.extend(status_rows * 2)
    print('Conselheiro:', len(status_rows), 'x2')

rng.shuffle(train)

real = [{'prompt': q, 'q': q, 'expect': kw} for q, kw in REAL]


def dump(path, rows):
    with open(path, 'w', encoding='utf-8') as f:
        for r in rows:
            f.write(json.dumps(r, ensure_ascii=False) + '\n')


out = os.path.join(HERE, 'closed')
os.makedirs(out, exist_ok=True)
dump(os.path.join(out, 'train.jsonl'), train)
dump(os.path.join(out, 'eval.jsonl'), evals)
dump(os.path.join(out, 'real_questions.jsonl'), real)
print('Estatísticas:', dict(stats))
print(f'Treino: {len(train)} | Validação: {len(evals)} | Reais: {len(real)}')
print('Por categoria:', dict(Counter(r['cat'] for r in train)))
for r in [x for x in train if x['entry'] == 'animal_chicken'][:2] + [x for x in train if x['cat'] == '_wiki'][:2]:
    print(f"\nP: {r['q']}\nR: {r['answer']}")
