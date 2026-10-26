"""Réplica fiel (em Python) da busca BM25 e do prompt do app Guia do Vale.

Mantenha em sincronia com:
  - lib/search.dart      (tokenize, Bm25Index, buildIndex, SearchService)
  - lib/models.dart      (Entry.fullText)
  - lib/ai_service.dart  (buildPrompt, ramo isFineTuned)
"""
import bisect
import gzip
import json
import math
import os
import re

ASSETS = os.environ.get('GUIA_ASSETS') or os.path.join(os.path.dirname(os.path.abspath(__file__)), '..', '..', 'assets')

_FROM = 'àáâãäåèéêëìíîïòóôõöùúûüçñ'
_TO = 'aaaaaaeeeeiiiiooooouuuucn'
_STOP = {
    'de', 'da', 'do', 'das', 'dos', 'a', 'o', 'as', 'os', 'e', 'em', 'no', 'na',
    'nos', 'nas', 'um', 'uma', 'que', 'para', 'por', 'com', 'como', 'qual',
    'quais', 'onde', 'quando', 'se', 'eu', 'meu', 'minha', 'ao', 'ou', 'the',
    'of', 'to', 'in', 'is', 'sao', 'ser', 'tem', 'ter', 'posso', 'devo',
    'sobre', 'explique', 'explicar', 'explica', 'fale', 'falar', 'conte',
    'conta', 'queria', 'quero', 'gostaria', 'saber', 'sabe', 'funciona',
    'funcionam', 'serve', 'servem', 'usar', 'usado', 'usada', 'usam', 'pra',
    'pro', 'mim', 'ele', 'ela', 'eles', 'elas', 'isso', 'isto', 'aqui', 'ali',
    'me', 'te', 'lhe', 'lhes', 'seu', 'sua', 'seus', 'suas', 'quanto', 'quantos',
    'quanta', 'quantas', 'porque', 'jogo',
}
_WORD = re.compile(r'[a-z0-9]+')


def normalize(s):
    out = []
    for ch in s.lower():
        i = _FROM.find(ch)
        out.append(_TO[i] if i >= 0 else ch)
    return ''.join(out)


def tokenize(s):
    out = []
    for m in _WORD.finditer(normalize(s)):
        t = m.group(0)
        if len(t) < 2 or t in _STOP:
            continue
        if len(t) > 3 and t.endswith('s'):
            t = t[:-1]
        out.append(t)
    return out


# ---- Strings no estilo Dart (comprimento em unidades UTF-16) ----
def u16len(s):
    return len(s.encode('utf-16-le')) // 2


def u16sub(s, n):
    """Equivale a s.substring(0, n) do Dart."""
    b = s.encode('utf-16-le')[: n * 2]
    return b.decode('utf-16-le', errors='ignore')


class Doc:
    __slots__ = ('title', 'text', 'entry_id', 'page_title')

    def __init__(self, title, text, entry_id=None, page_title=None):
        self.title = title
        self.text = text
        self.entry_id = entry_id
        self.page_title = page_title


class Bm25:
    K1 = 1.4
    B = 0.75

    def __init__(self):
        self.docs = []
        self.lens = []
        self.post = {}       # termo -> [doc, tf, doc, tf...]  (ordem de inserção = Dart)
        self.order = {}      # termo -> índice de inserção
        self.avg = 1.0
        self._sorted = []

    def add(self, d, title_boost=5):
        did = len(self.docs)
        self.docs.append(d)
        tf = {}
        tt = tokenize(d.title)
        for _ in range(title_boost):
            for t in tt:
                tf[t] = tf.get(t, 0) + 1
        bt = tokenize(d.text)
        for t in bt:
            tf[t] = tf.get(t, 0) + 1
        self.lens.append(len(tt) * title_boost + len(bt))
        for term, f in tf.items():
            if term not in self.post:
                self.post[term] = []
                self.order[term] = len(self.order)
            self.post[term].extend((did, f))

    def finish(self):
        self.avg = (sum(self.lens) / len(self.lens)) if self.lens else 1.0
        self._sorted = sorted(self.post.keys())

    def _expansions(self, q):
        """Mesmos termos (e mesma ordem/limite de 25) que o laço em search.dart."""
        cands = []
        i = bisect.bisect_left(self._sorted, q)
        while i < len(self._sorted) and self._sorted[i].startswith(q):
            t = self._sorted[i]
            if t != q:
                cands.append((self.order[t], t, 0.4))
            i += 1
        for k in range(4, len(q)):
            t = q[:k]
            if t in self.post:
                cands.append((self.order[t], t, 0.35))
        cands.sort()
        return cands[:25]

    def search(self, query, limit=10):
        qt = tokenize(query)
        if not qt or not self.docs:
            return []
        n = len(self.docs)
        scores = {}

        def score_term(term, w):
            post = self.post.get(term)
            if post is None:
                return
            df = len(post) // 2
            idf = math.log(1 + (n - df + 0.5) / (df + 0.5))
            for j in range(0, len(post), 2):
                d, tf = post[j], post[j + 1]
                norm = tf + self.K1 * (1 - self.B + self.B * self.lens[d] / self.avg)
                scores[d] = scores.get(d, 0.0) + w * idf * (tf * (self.K1 + 1)) / norm

        for q in qt:
            score_term(q, 1.0)
            if len(q) >= 3:
                for _, term, w in self._expansions(q):
                    score_term(term, w)
        # Dart: sort estável por score desc (empates mantêm a ordem do Map = 1ª pontuação)
        items = sorted(scores.items(), key=lambda kv: -kv[1])
        return [(self.docs[d], s) for d, s in items[:limit]]


def full_text(e):
    name = e.get('pt') or e.get('en') or ''
    en = e.get('en') or ''
    lines = [name]
    if en and en != name:
        lines.append(f'({en})')
    if e.get('sub'):
        lines.append(e['sub'])
    for f in e.get('fields', []):
        if len(f) >= 2:
            lines.append(f'{f[0]}: {f[1]}')
    if e.get('desc'):
        lines.append(e['desc'])
    if e.get('checklist'):
        lines.append('Itens: ' + ', '.join(e['checklist']))
    if e.get('body'):
        lines.append(e['body'])
    return '\n'.join(lines) + '\n'


def load_entries():
    idx = json.load(open(os.path.join(ASSETS, 'data', 'index.json'), encoding='utf-8'))
    try:
        names_pt = json.load(open(os.path.join(ASSETS, 'data', 'names_pt.json'), encoding='utf-8'))
    except Exception:
        names_pt = {}
    entries = []
    for c in idx['categories']:
        data = json.load(open(os.path.join(ASSETS, 'data', f"{c['id']}.json"), encoding='utf-8'))
        for e in data['entries']:
            e = dict(e)
            e['cat'] = e.get('cat') or c['id']
            pt = e.get('pt') or ''
            en = e.get('en') or ''
            ov = names_pt.get(en)
            if (not pt or pt == en) and isinstance(ov, str) and ov and ov != en:
                e['pt'] = ov
            entries.append(e)
    return entries


def build_index(entries, with_wiki=True):
    idx = Bm25()
    for e in entries:
        name = e.get('pt') or e.get('en') or ''
        idx.add(Doc(f"{name} {e.get('en') or ''}", full_text(e), entry_id=e['id']))
    if with_wiki:
        path = os.path.join(ASSETS, 'wiki', 'pages.json.gz')
        if os.path.exists(path):
            for p in json.load(gzip.open(path)):
                t = p.get('t') or ''
                for ch in p.get('c') or []:
                    idx.add(Doc(t, str(ch), page_title=t), title_boost=2)
    idx.finish()
    return idx


_WS = re.compile(r'\s+')


def context_lines(hits):
    """Retorna [(doc, texto_visível)] exatamente como buildPrompt monta."""
    out = []
    total = 0
    for i, (d, _) in enumerate(hits[:4]):
        limit = 700 if i == 0 else 250
        t = _WS.sub(' ', d.text).strip()
        if u16len(t) > limit:
            t = u16sub(t, limit) + '…'
        if total + u16len(t) > 1300:
            break
        total += u16len(t)
        out.append((d, t))
    return out


def build_prompt(question, hits):
    lines = [
        'Você é o Espírito do Vale, assistente especialista em Stardew Valley.',
        'Responda sempre em português brasileiro de forma direta, clara, amigável e precisa.',
        'Use as informações do jogo abaixo para responder. Não invente dados.',
    ]
    ctx = context_lines(hits) if hits else []
    if hits:
        lines.append('')
        lines.append('Dados do jogo:')
        for d, t in ctx:
            lines.append(f'- {d.title}: {t}')
    lines.append('')
    lines.append(f'Pergunta: {question}')
    lines.append('Resposta:')
    return '\n'.join(lines) + '\n', ctx


def device_chat_text(prompt, answer=None):
    """Formato exato que o template do .litertlm produz (sem system)."""
    s = f'<|im_start|>user\n{prompt}<|im_end|>\n<|im_start|>assistant\n'
    if answer is not None:
        s += f'{answer}<|im_end|>\n'
    return s
