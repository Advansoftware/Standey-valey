"""Gera o dataset v2 do Espírito do Vale a partir dos 18 JSONs do app.

Diferenças em relação ao v1 (build_dataset.py):
  * Usa TODOS os arquivos de assets/data (guia, animais, construções, pacotes...).
  * Usa os nomes de campos REAIS (o v1 lia campos inexistentes e treinava
    respostas vazias como "vive em: ." — origem das alucinações).
  * O prompt de entrada é idêntico ao que o app envia (busca BM25 + contexto).
  * A resposta só usa fatos VISÍVEIS no contexto (ensina a ler, não a inventar).
  * Inclui exemplos de "não encontrei" e fora de assunto.
"""
import json
import os
import random
import re
import sys
from collections import Counter, defaultdict

sys.path.insert(0, os.path.dirname(__file__))
from app_replica import (build_index, build_prompt, device_chat_text,  # noqa: E402
                         load_entries, normalize)

sys.stdout.reconfigure(encoding='utf-8')
OUT_DIR = os.path.dirname(__file__)
rng = random.Random(1234)

entries = load_entries()
by_id = {e['id']: e for e in entries}
print(f'Entradas: {len(entries)}')
print('Montando índice (enciclopédia + wiki)...')
index = build_index(entries, with_wiki=True)
print(f'Docs no índice: {len(index.docs)}')

_WS = re.compile(r'\s+')


def ws(s):
    return _WS.sub(' ', s or '').strip()


def name_of(e):
    return e.get('pt') or e.get('en') or ''


def fields(e):
    d = defaultdict(list)
    for f in e.get('fields', []):
        if len(f) >= 2 and f[1].strip():
            d[f[0]].append(f[1].strip())
    return d


class Ctx:
    def __init__(self, ctx):
        self.text = ' '.join(t for _, t in ctx)

    def has(self, v):
        return bool(v) and ws(v) in self.text


def first_sentence(s):
    s = ws(s)
    m = re.match(r'(.+?[.!?])(\s|$)', s)
    return m.group(1) if m else s


def util_parts(c, value, maxn=4):
    """Partes da 'Utilidade' (separadas por •) que aparecem no contexto."""
    out = []
    for p in (value or '').split('•'):
        p = ws(p)
        if p and c.has(p):
            out.append(p.rstrip('.'))
        if len(out) >= maxn:
            break
    return out


def join_pt(items):
    items = [i for i in items if i]
    if len(items) <= 1:
        return ''.join(items)
    return ', '.join(items[:-1]) + ' e ' + items[-1]


def low1(s):
    return s[:1].lower() + s[1:] if s and not s[:2].isupper() else s


# --------------------------------------------------------------------------
# Tarefas por categoria. Cada tarefa = (perguntas, função_resposta(ctx)->str|None)
# --------------------------------------------------------------------------

def tasks_aldeoes(e):
    n, F = name_of(e), fields(e)
    pres = (F.get('Presentes amados') or [''])[0]
    aniv = (F.get('Aniversário') or [''])[0]
    cas = (F.get('Casável') or [''])[0]
    local = (F.get('Onde mora/trabalha') or [''])[0]
    T = []

    def a_pres(c):
        if not c.has(pres):
            return None
        s = f'{n} ama: {pres}.'
        if c.has(aniv):
            s += f' Dê um desses no aniversário de {n} ({aniv}): o presente vale 8 vezes mais amizade.'
        else:
            s += ' Presentes amados dão muitos pontos de amizade, principalmente no aniversário.'
        return s
    T.append(([f'O que {n} ama?', f'Quais presentes {n} mais gosta?', f'Qual o melhor presente para {n}?',
               f'o que dar de presente pra {n}', f'presente favorito de {n}', f'O que a pessoa {n} gosta de ganhar?'], a_pres))

    def a_aniv(c):
        if not c.has(aniv):
            return None
        s = f'O aniversário de {n} é em {aniv}.'
        if c.has(pres):
            s += f' Bons presentes: {pres}.'
        return s
    T.append(([f'Quando é o aniversário de {n}?', f'Qual o dia do aniversário de {n}?', f'aniversario de {n}',
               f'Que dia {n} faz aniversário?'], a_aniv))

    def a_cas(c):
        if not c.has(f'Casável: {cas}'):
            return None
        if cas.lower().startswith('sim'):
            return (f'Sim! {n} é casável. Para namorar, chegue a 8 corações e dê um Buquê; '
                    f'para casar, chegue a 10 corações e entregue o Pingente de Sereia.')
        return f'Não, {n} não é casável. Mas você pode chegar à amizade máxima conversando todo dia e dando presentes amados.'
    T.append(([f'{n} é casável?', f'Posso casar com {n}?', f'Dá pra namorar {n}?', f'como casar com {n}'], a_cas))

    def a_onde(c):
        if not c.has(local):
            return None
        return f'{n} mora/trabalha em: {local}.'
    T.append(([f'Onde encontro {n}?', f'Onde mora {n}?', f'onde fica {n}', f'Onde {n} trabalha?'], a_onde))

    def a_quem(c):
        bits = []
        d = first_sentence(e.get('desc', ''))
        if c.has(d):
            bits.append(f'{n}: {d}')
        if c.has(local):
            bits.append(f'Mora/trabalha em {local}.')
        if c.has(aniv):
            bits.append(f'Aniversário: {aniv}.')
        if c.has(pres):
            bits.append(f'Ama: {pres}.')
        return ' '.join(bits) if len(bits) >= 2 else None
    T.append(([f'Quem é {n}?', f'Me fale sobre {n}', f'quem e {n} no jogo'], a_quem))
    return T


def tasks_culturas(e):
    n, F = name_of(e), fields(e)
    est = (F.get('Estação') or [''])[0]
    sem = (F.get('Semente') or [''])[0]
    tempo = (F.get('Tempo de crescimento') or [''])[0]
    reb = (F.get('Rebrota') or [''])[0]
    preco = (F.get('Preço de venda') or [''])[0]
    lucro = (F.get('Lucro/dia (aprox.)') or [''])[0]
    util = (F.get('Utilidade') or [''])[0]

    def reb_txt():
        if not reb:
            return ''
        return 'colheita única' if 'única' in reb.lower() else f'depois rebrota {reb}'

    T = []

    def a_quando(c):
        if not (c.has(est) and c.has(tempo)):
            return None
        s = f'{n} é plantada na estação: {est}. Leva {tempo} para crescer'
        s += f' ({reb_txt()}).' if c.has(reb) else '.'
        return s
    T.append(([f'Quando plantar {n}?', f'Em que estação planto {n}?', f'{n} é de qual estação?',
               f'quanto tempo {n} demora pra crescer', f'Quantos dias leva {n}?'], a_quando))

    def a_sem(c):
        if not c.has(sem):
            return None
        return f'A semente de {n} é vendida em: {sem}.' + (f' Plante na estação: {est}.' if c.has(est) else '')
    T.append(([f'Onde compro semente de {n}?', f'Quanto custa a semente de {n}?', f'onde comprar {n}'], a_sem))

    def a_lucro(c):
        if not c.has(preco):
            return None
        s = f'{n} vende por {preco}'
        if c.has(tempo):
            s += f' e leva {tempo} para crescer'
        if c.has(reb):
            s += f' ({reb_txt()})'
        s += '.'
        if c.has(lucro):
            s += f' Lucro aproximado: {lucro}.'
        return s
    T.append(([f'Vale a pena plantar {n}?', f'Quanto rende {n}?', f'Quanto vende {n}?', f'{n} dá lucro?'], a_lucro))

    def a_util(c):
        parts = util_parts(c, util)
        if len(parts) < 2:
            return None
        return f'{n}: ' + '; '.join(low1(p) if i else p for i, p in enumerate(parts)) + '.'
    T.append(([f'Para que serve {n}?', f'O que fazer com {n}?', f'{n} serve pra quê?'], a_util))
    return T


def tasks_peixes(e):
    n, F = name_of(e), fields(e)
    onde = (F.get('Onde pescar') or F.get('Onde') or [''])[0]
    est = (F.get('Estações') or [''])[0]
    hora = (F.get('Horário') or [''])[0]
    clima = (F.get('Clima') or [''])[0]
    dif = (F.get('Dificuldade') or [''])[0]
    preco = (F.get('Preço base') or [''])[0]
    T = []

    def a_onde(c):
        if not c.has(onde):
            return None
        s = f'Pesque {n} em: {onde}.'
        extra = []
        if c.has(est):
            extra.append(f'estação: {est}')
        if c.has(hora):
            extra.append(f'horário: {hora}')
        if c.has(clima):
            extra.append(f'clima: {low1(clima)}')
        if extra:
            s += ' ' + '; '.join(extra).capitalize() + '.'
        return s
    T.append(([f'Onde pescar {n}?', f'Onde acho o peixe {n}?', f'como pegar {n}', f'onde pesca {n}',
               f'Onde encontro {n}?'], a_onde))

    def a_quando(c):
        if not (c.has(est) and c.has(hora)):
            return None
        s = f'{n} aparece em: {est}, no horário {hora}'
        s += f', com clima {low1(clima)}.' if c.has(clima) else '.'
        return s
    T.append(([f'Quando aparece {n}?', f'Que horas pescar {n}?', f'Qual estação do {n}?'], a_quando))

    def a_preco(c):
        if not c.has(preco):
            return None
        s = f'{n} vale {preco} (qualidade normal).'
        if c.has(f'Dificuldade: {dif}'):
            s += f' Dificuldade de pesca: {dif}.'
        return s
    T.append(([f'Quanto vale {n}?', f'Qual o preço do {n}?', f'{n} é difícil de pescar?'], a_preco))
    return T


def tasks_festivais(e):
    n, F = name_of(e), fields(e)
    data = (F.get('Data') or [''])[0]
    hora = (F.get('Horário') or [''])[0]
    local = (F.get('Local') or [''])[0]
    util = (F.get('Utilidade') or [''])[0]

    def a(c):
        if not c.has(data):
            return None
        s = f'{n} acontece em {data}'
        if c.has(hora):
            s += f', das {hora}'
        if c.has(local):
            s += f', em: {local}'
        s += '.'
        if c.has(util):
            s += f' {util}'
        return s
    def a_fazer(c):
        if not c.has(util):
            return None
        s = util
        if c.has(data):
            s += f' Data: {data}' + (f', {local}.' if c.has(local) else '.')
        return s
    return [([f'Quando é o {n}?', f'Que dia acontece {n}?', f'data do {n}', f'Quando vai ter {n}?'], a),
            ([f'O que fazer no {n}?', f'Como funciona o {n}?', f'Vale a pena ir no {n}?'], a_fazer)]


def tasks_pacotes(e):
    n, F = name_of(e), fields(e)
    sala = (F.get('Sala') or [''])[0]
    qtd = (F.get('Quantidade') or [''])[0]
    rp = (F.get('Recompensa do pacote') or [''])[0]
    rs = (F.get('Recompensa da sala') or [''])[0]
    itens = ', '.join(e.get('checklist') or [])

    def a_itens(c):
        if not (itens and c.has('Itens: ' + itens)):
            return None
        s = f'Pacote {n}'
        if c.has(sala):
            s += f' ({sala})'
        s += f': entregue {qtd} — {itens}.' if c.has(qtd) else f': {itens}.'
        if c.has(rp):
            s += f' Recompensa: {rp}.'
        return s

    def a_rec(c):
        if not c.has(rp):
            return None
        s = f'Ao completar o pacote {n} você recebe {rp}.'
        if c.has(rs):
            s += f' Completando a sala inteira ({sala}): {rs}.'
        return s
    return [([f'O que precisa para o pacote {n}?', f'Quais itens do pacote {n}?', f'pacote {n} itens',
              f'Como completar o pacote {n}?'], a_itens),
            ([f'Qual a recompensa do pacote {n}?', f'O que ganho no pacote {n}?'], a_rec)]


def tasks_coletaveis(e):
    n, F = name_of(e), fields(e)
    est = (F.get('Estação') or [''])[0]
    onde = (F.get('Onde achar') or [''])[0]
    preco = (F.get('Preço base') or [''])[0]
    util = (F.get('Utilidade') or [''])[0]

    def a(c):
        if not c.has(onde):
            return None
        s = f'{n} aparece'
        if c.has(est):
            s += f' na estação {est},'
        s += f' em: {low1(onde)}.'
        if c.has(preco):
            s += f' Vale {preco}.'
        d = ws(e.get('desc', ''))
        if c.has(d) and 'pacote' in d.lower():
            s += f' {d}'
        return s

    def a_util(c):
        parts = util_parts(c, util)
        if len(parts) < 2:
            return None
        return f'{n}: ' + '; '.join(low1(p) if i else p for i, p in enumerate(parts)) + '.'
    return [([f'Onde encontro {n}?', f'Onde acho {n}?', f'Quando aparece {n}?', f'onde coletar {n}'], a),
            ([f'Para que serve {n}?', f'Quanto vale {n}?'], a_util)]


def tasks_habilidades(e):
    n, F = name_of(e), fields(e)
    n5 = F.get('Nível 5') or []
    n10 = F.get('Nível 10') or []

    def a_prof(c):
        v5 = [v for v in n5 if c.has(v)]
        if len(v5) < 2:
            return None
        s = f'Em {n}, no nível 5 você escolhe: ' + ' ou '.join(v5) + '.'
        v10 = [v for v in n10 if c.has(v)]
        if v10:
            s += ' No nível 10: ' + '; '.join(v10) + '.'
        return s

    def a_subir(c):
        d = ws(e.get('desc', ''))
        sub = ws(e.get('sub', ''))
        if not (c.has(d) or c.has(sub)):
            return None
        return ' '.join(x for x in [sub if c.has(sub) else '', d if c.has(d) else ''] if x)
    return [([f'Quais as profissões de {n}?', f'Qual profissão escolher em {n}?', f'profissões nível 5 de {n}'], a_prof),
            ([f'Como subir {n}?', f'Como ganhar XP de {n}?', f'Como upar {n}?'], a_subir)]


def tasks_animais(e):
    n, F = name_of(e), fields(e)
    vive = (F.get('Onde vive') or [''])[0]
    preco = (F.get('Preço') or [''])[0]
    prod = (F.get('Produção') or F.get('Produtos') or [''])[0]
    venda = (F.get('Preço de venda (animal)') or [''])[0]
    desc = ws(e.get('desc', ''))
    util = (F.get('Utilidade') or [''])[0]

    def building_cost(c):
        b = next((x for x in entries if x['cat'] == 'construcoes' and name_of(x) == vive), None)
        if not b:
            return ''
        bf = fields(b)
        custo = (bf.get('Custo') or [''])[0]
        mat = (bf.get('Materiais') or [''])[0]
        if c.has(f'Custo: {custo}') and c.has(mat):
            return f' (custa {custo} + {mat})'
        return ''

    def a_conseguir(c):
        if not c.has(vive):
            return None
        if 'g' in preco and c.has(f'Preço: {preco}'):
            s = (f'Primeiro peça para a Robin, na Carpintaria, construir um {vive}{building_cost(c)}. '
                 f'Depois compre {n} no Rancho da Marnie por {preco}.')
        elif c.has(desc):
            s = f'{n} não é vendido(a) no rancho da Marnie. {desc} Vive em: {vive}.'
        else:
            return None
        if c.has(prod):
            s += f' Produção: {prod}.'
        return s
    T = [([f'Como conseguir {n}?', f'Como ter {n} na fazenda?', f'Onde compro {n}?', f'como consigo {n}',
           f'Quero criar {n}, como faço?'], a_conseguir)]

    def a_prod(c):
        if not c.has(prod):
            return None
        s = f'{n} produz: {prod}.'
        parts = util_parts(c, util, 4)
        extra = [p for p in parts if not p.lower().startswith('produz')]
        if extra:
            s += ' ' + '. '.join(extra[:2]) + '.'
        return s
    T.append(([f'O que {n} produz?', f'Para que serve {n}?', f'Vale a pena ter {n}?'], a_prod))

    def a_preco(c):
        if not c.has(f'Preço: {preco}'):
            return None
        s = f'{n}: preço de compra {preco}.' if 'g' in preco else f'{n}: {preco.lower()}.'
        if c.has(venda):
            s += f' Vende por {venda}.'
        if c.has(vive):
            s += f' Vive em: {vive}.'
        return s
    T.append(([f'Quanto custa {n}?', f'Qual o preço de {n}?', f'Onde vive {n}?'], a_preco))
    return T


def fields_answer(e, c, keys, intro=None, maxk=6):
    """Resposta genérica: lista dos campos pedidos que estão visíveis."""
    n, F = name_of(e), fields(e)
    lines = []
    for k in keys:
        for v in F.get(k, []):
            if k == 'Utilidade':
                parts = util_parts(c, v)
                if parts:
                    lines.append(f'- {k}: ' + '; '.join(parts))
            elif c.has(f'{k}: {v}'):
                lines.append(f'- {k}: {v}')
    if not lines:
        return None
    head = intro or f'**{n}**'
    return head + '\n' + '\n'.join(lines[:maxk])


def generic_tasks(e):
    n = name_of(e)
    cat = e['cat']
    if cat == 'arvores':
        return [([f'Como plantar {n}?', f'O que {n} produz?', f'Quanto custa a muda de {n}?', f'Como reconhecer {n}?'],
                 lambda c: fields_answer(e, c, ['Tipo', 'Estação da fruta', 'Amadurece em', 'Compra da muda',
                                                'Preço de venda (fruta)', 'Semente (identifica a árvore)',
                                                'Com torneira', 'Ao cortar']))]
    if cat == 'minerais':
        return [([f'Onde acho {n}?', f'Onde encontrar {n}?', f'como conseguir {n}'],
                 lambda c: fields_answer(e, c, ['Onde achar', 'Contém', 'Preço de venda'])),
                ([f'Quanto vale {n}?', f'Para que serve {n}?'],
                 lambda c: fields_answer(e, c, ['Preço de venda', 'Preço com Gemólogo', 'Utilidade']))]
    if cat == 'monstros':
        return [([f'Onde aparece {n}?', f'O que {n} solta?', f'Quanta vida tem {n}?', f'{n} é perigoso?'],
                 lambda c: fields_answer(e, c, ['Onde', 'Vida', 'Dano', 'XP', 'Solta']))]
    if cat == 'culinaria':
        return [([f'Como fazer {n}?', f'Quais os ingredientes de {n}?', f'receita de {n}'],
                 lambda c: fields_answer(e, c, ['Ingredientes', 'Receita', 'Energia / Vida', 'Bônus'])),
                ([f'Como consigo a receita de {n}?', f'Onde aprendo a fazer {n}?'],
                 lambda c: fields_answer(e, c, ['Receita', 'Ingredientes'])),
                ([f'Quanta energia dá {n}?', f'Vale a pena comer {n}?'],
                 lambda c: fields_answer(e, c, ['Energia / Vida', 'Bônus', 'Preço de venda']))]
    if cat == 'artefatos':
        return [([f'Onde acho {n}?', f'Como conseguir {n}?', f'Quanto vale {n}?'],
                 lambda c: fields_answer(e, c, ['Onde achar', 'Preço de venda', 'Utilidade']))]
    if cat == 'construcoes':
        return [([f'Quanto custa {n}?', f'Como construir {n}?', f'Para que serve {n}?', f'materiais do {n}'],
                 lambda c: fields_answer(e, c, ['Construtor', 'Custo', 'Materiais', 'Tempo',
                                                'Capacidade de animais', 'Utilidade']))]
    if cat == 'ferramentas':
        return [([f'Como melhorar {n}?', f'Quanto custa melhorar {n}?', f'Para que serve {n}?'],
                 lambda c: fields_answer(e, c, ['Utilidade', 'Cobre', 'Aço', 'Ouro', 'Irídio', 'Custo',
                                                'Training Rod', 'Bamboo Pole', 'Fiberglass Rod', 'Iridium Rod']))]
    return []


GUIA_QS = {
    'guia_comeco': ['O que devo fazer no primeiro dia?', 'Acabei de começar, o que faço?', 'Dicas para o dia 1'],
    'guia_roteiro_primavera': ['O que fazer na primavera do ano 1?', 'Roteiro da primavera', 'O que priorizar na primeira primavera?'],
    'guia_roteiro_verao': ['O que plantar no verão?', 'O que fazer no verão do ano 1?', 'Melhores culturas de verão'],
    'guia_roteiro_outono': ['O que plantar no outono?', 'O que fazer no outono do ano 1?', 'Melhores culturas de outono'],
    'guia_roteiro_inverno': ['O que fazer no inverno?', 'Nada cresce no inverno, o que eu faço?', 'Dicas para o inverno'],
    'guia_dinheiro': ['Como ganhar dinheiro no começo?', 'Como ficar rico rápido?', 'Melhor jeito de ganhar ouro no início'],
    'guia_ferramentas': ['Como melhorar as ferramentas?', 'Quanto custa melhorar ferramenta?', 'Qual ferramenta melhorar primeiro?'],
    'guia_energia': ['Como recuperar energia?', 'O que acontece se ficar acordado até 2h?', 'Fiquei sem energia, o que faço?'],
    'guia_amizade': ['Como fazer amizade com os moradores?', 'Quantos presentes posso dar por semana?', 'Como ganhar corações?'],
    'guia_pesca': ['Como pescar?', 'Dicas de pesca para iniciante', 'Qual vara de pesca comprar primeiro?'],
    'guia_minas': ['Dicas para as minas', 'O que levar para as minas?', 'Quantos andares têm as minas?'],
    'guia_centro': ['Centro Comunitário ou JojaMart?', 'Vale a pena o Centro Comunitário?', 'Como funcionam os pacotes dos Junimos?'],
    'guia_animais': ['Como começar a criar animais?', 'Como conseguir uma galinha?', 'Quanto custa o galinheiro?'],
    'guia_casamento': ['Como casar?', 'Com quem posso casar?', 'Onde compro o Pingente de Sereia?'],
    'guia_lavoura': ['Como plantar?', 'Minha planta morreu na troca de estação, por quê?', 'Como evitar corvos?'],
    'guia_erros': ['Quais erros evitar no começo?', 'Erros comuns de iniciante', 'O que não fazer no início?'],
    'guia_arvores': ['Qual árvore é o carvalho?', 'Como diferenciar as árvores?', 'Como saber se é bordo ou pinheiro?'],
    'guia_arvores_cultivo': ['Devo cortar as árvores da fazenda?', 'Vale a pena plantar pinheiro?', 'Para que serve a resina de carvalho?'],
}


def guia_answer(e, c, max_items=6, max_chars=520):
    body = e.get('body') or ''
    out, size = [], 0
    for raw in body.split('\n'):
        line = raw.strip()
        if not line:
            continue
        if not c.has(line):
            break  # a partir daqui o contexto foi cortado
        if line.startswith('##'):
            txt = f"**{line.lstrip('#').strip()}**"
        elif line.startswith('•'):
            txt = '- ' + line.lstrip('•').strip()
        else:
            txt = line
        if size + len(txt) > max_chars and out:
            break
        out.append(txt)
        size += len(txt)
        if sum(1 for x in out if x.startswith('- ')) >= max_items:
            break
    while out and out[-1].startswith('**'):
        out.pop()
    if len(out) < 2:
        return None
    return '\n'.join(out)


def tasks_for(e):
    cat = e['cat']
    if cat == 'guia':
        qs = GUIA_QS.get(e['id'])
        return [(qs, lambda c: guia_answer(e, c))] if qs else []
    fn = {
        'aldeoes': tasks_aldeoes, 'culturas': tasks_culturas, 'peixes': tasks_peixes,
        'festivais': tasks_festivais, 'pacotes': tasks_pacotes, 'coletaveis': tasks_coletaveis,
        'habilidades': tasks_habilidades, 'animais': tasks_animais,
    }.get(cat)
    return fn(e) if fn else generic_tasks(e)


# --------------------------------------------------------------------------
def augment(q):
    r = rng.random()
    if r < 0.15:
        q = normalize(q)                       # sem acentos, minúsculas
    elif r < 0.30:
        q = q.lower()
    if rng.random() < 0.25:
        q = q.rstrip('?')
    return q


def target_visible(e, ctx):
    return any(d.entry_id == e['id'] for d, _ in ctx)


def make_example(q, answer_fn, e, require_target=True):
    hits = index.search(q, limit=8)
    prompt, ctx = build_prompt(q, hits)
    if require_target and not target_visible(e, ctx):
        return None, 'miss'
    ans = answer_fn(Ctx(ctx))
    if not ans:
        return None, 'noans'
    return {'prompt': prompt, 'answer': ans.strip(), 'entry': e['id'], 'cat': e['cat'], 'q': q}, 'ok'


train, evals = [], []
stats = Counter()
eval_entries = set(rng.sample([e['id'] for e in entries], k=int(len(entries) * 0.12)))

for e in entries:
    for qs, fn in tasks_for(e):
        qs = list(qs)
        rng.shuffle(qs)
        held = None
        if e['id'] in eval_entries and len(qs) >= 3:
            held = qs.pop()                     # paráfrase nunca vista no treino
        for q in qs[:3]:
            ex, st = make_example(augment(q), fn, e)
            if not ex:
                ex, st = make_example(q, fn, e)  # tenta sem augmentation
            stats[st] += 1
            if ex:
                train.append(ex)
        if held:
            ex, st = make_example(held, fn, e)
            if ex:
                evals.append(ex)

print('Estatísticas:', dict(stats))

# ---- "Não encontrei": pergunta sobre algo cujo dado não está no contexto ----
FAKE = ['Dragão de Fogo', 'Espada Laser', 'Pokébola', 'Unicórnio Dourado', 'Moto Voadora', 'Tio Patinhas',
        'Feijão Mágico Azul', 'Castelo de Gelo', 'Peixe Arco-Íris Gigante', 'Mago Merlin', 'Robô Agricultor',
        'Cogumelo Falante', 'Fada Madrinha', 'Trator Turbo', 'Pinguim Real', 'Banana Cósmica']
FAKE_Q = ['Onde acho {x}?', 'Como conseguir {x}?', 'Quanto vale {x}?', 'O que {x} ama?', 'Quando aparece {x}?']
NOTFOUND = ['Não encontrei nada sobre {x} nos dados do guia. Confira se o nome está certo ou procure na Enciclopédia do app.',
            'Não achei {x} nos dados do jogo que tenho aqui. Tente escrever de outro jeito ou veja a Enciclopédia.']
for x in FAKE:
    for t in rng.sample(FAKE_Q, 3):
        q = t.format(x=x)
        hits = index.search(q, limit=8)
        prompt, ctx = build_prompt(q, hits)
        if any(normalize(x) in normalize(tx) for _, tx in ctx):
            continue
        train.append({'prompt': prompt, 'answer': rng.choice(NOTFOUND).format(x=x), 'entry': '_notfound',
                      'cat': '_notfound', 'q': q})

OFFTOPIC = ['Qual a capital da França?', 'Me conta uma piada', 'Quem ganhou a Copa de 2002?', 'Quanto é 25 vezes 4?',
            'Qual o melhor time de futebol?', 'Me ajuda com meu dever de matemática', 'Qual a previsão do tempo amanhã?',
            'Escreve um poema de amor', 'Como faço bolo de cenoura de verdade?', 'Quem é o presidente do Brasil?',
            'Qual o melhor celular para comprar?', 'Como programar em Python?']
OFF_ANS = 'Eu só sei ajudar com Stardew Valley! Pergunte sobre moradores, plantações, peixes, animais, festivais ou dicas do jogo.'
GREET = [('Oi', 'Oi! Sou o Espírito do Vale. Pergunte qualquer coisa sobre Stardew Valley: presentes, plantações, peixes, animais...'),
         ('Olá, tudo bem?', 'Tudo ótimo! Sou o Espírito do Vale. Em que posso ajudar na sua fazenda?'),
         ('Obrigado!', 'De nada! Boa sorte na fazenda. 🌱'),
         ('valeu', 'Por nada! Se precisar, é só perguntar.'),
         ('Quem é você?', 'Sou o Espírito do Vale, o assistente do Guia do Vale. Respondo dúvidas sobre Stardew Valley, 100% offline.')]
for q in OFFTOPIC:
    for qq in {q, q.lower()}:
        prompt, _ = build_prompt(qq, index.search(qq, limit=8))
        train.append({'prompt': prompt, 'answer': OFF_ANS, 'entry': '_off', 'cat': '_off', 'q': qq})
for q, a in GREET:
    for qq in {q, q.lower()}:
        prompt, _ = build_prompt(qq, index.search(qq, limit=8))
        train.append({'prompt': prompt, 'answer': a, 'entry': '_greet', 'cat': '_greet', 'q': qq})

rng.shuffle(train)

# ---- Validação das perguntas reais (com fatos esperados) ----
REAL = [
    ('como conseguir uma galinha', ['Marnie', '800']),
    ('como conseguir uma galinhak', ['Marnie', '800']),
    ('O que a Abigail ama?', ['Ametista', 'Abóbora']),
    ('Onde pescar o baiacu?', ['Oceano']),
    ('Quando é o aniversário do Sebastian?', ['Inverno']),
    ('Quanto custa o galinheiro?', ['4.000']),
    ('O que plantar na primavera?', []),
    ('Qual árvore é o carvalho?', ['Bolota']),
    ('Como ganhar dinheiro no começo?', []),
    ('O que devo fazer no primeiro dia?', ['Pastinaca']),
    ('Quais itens do pacote Forrageio de Primavera?', ['Narciso', 'Dente-de-leão']),
    ('Quando é o Festival do Ovo?', ['13']),
    ('Posso casar com a Haley?', ['Sim']),
    ('Onde acho Pokébola?', ['Não']),
    ('Qual a capital da França?', ['Stardew']),
]
real = []
for q, kw in REAL:
    prompt, _ = build_prompt(q, index.search(q, limit=8))
    real.append({'prompt': prompt, 'q': q, 'expect': kw})


def dump(path, rows):
    with open(path, 'w', encoding='utf-8') as f:
        for r in rows:
            f.write(json.dumps(r, ensure_ascii=False) + '\n')


dump(os.path.join(OUT_DIR, 'train.jsonl'), train)
dump(os.path.join(OUT_DIR, 'eval.jsonl'), evals)
dump(os.path.join(OUT_DIR, 'real_questions.jsonl'), real)
print(f'Treino: {len(train)}  |  Validação (paráfrases inéditas): {len(evals)}  |  Perguntas reais: {len(real)}')
print('Por categoria:', dict(Counter(r['cat'] for r in train)))
print('\n===== EXEMPLO =====')
ex = next(r for r in train if r['entry'] == 'animal_chicken')
print(device_chat_text(ex['prompt'], ex['answer']))
