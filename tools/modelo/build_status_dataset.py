"""Exemplos do Conselheiro do Vale (tela Meu Status, botão AJUDA).

Replica lib/game_status.dart (buildStatusPrompt, recommendedNextStep,
buildStatusTips, weatherInfo, locationInfo) com saves aleatórios e gera a
resposta no formato que parseAiObjectives espera:

    AÇÃO CURTA | LUGAR | MOTIVO CURTO     (até 3 linhas, sem markdown)

As respostas só usam dados presentes no prompt (status + sugestões do guia).
Mantenha em sincronia com lib/game_status.dart e lib/map_data.dart.
"""
import json
import os
import random
import re
import sys

sys.stdout.reconfigure(encoding='utf-8')
HERE = os.path.dirname(os.path.abspath(__file__))
APP = os.environ.get('GUIA_APP') or os.path.join(HERE, '..', '..')
rng = random.Random(2026)

SEASONS = ['Primavera', 'Verão', 'Outono', 'Inverno']
WEEK = ['segunda', 'terça', 'quarta', 'quinta', 'sexta', 'sábado', 'domingo']


def load(cat):
    return json.load(open(os.path.join(APP, 'assets', 'data', f'{cat}.json'), encoding='utf-8'))['entries']


def fields(e):
    return {f[0]: f[1] for f in e.get('fields', []) if len(f) >= 2}


VILLAGERS = []
for e in load('aldeoes'):
    F = fields(e)
    VILLAGERS.append({'name': e.get('pt') or e['en'], 'en': e['en'], 'home': F.get('Onde mora/trabalha', ''),
                      'loves': [x.strip() for x in F.get('Presentes amados', '').split(',') if x.strip()],
                      'bday': F.get('Aniversário', ''), 'marry': F.get('Casável', '').lower().startswith('sim')})
FESTIVALS = []
for e in load('festivais'):
    F = fields(e)
    FESTIVALS.append({'name': e.get('pt') or e['en'], 'data': F.get('Data', ''), 'local': F.get('Local', '')})
CROPS = {s: [] for s in SEASONS}
for e in load('culturas'):
    est = fields(e).get('Estação', '')
    for s in SEASONS:
        if s in est:
            CROPS[s].append(e.get('pt') or e['en'])
ITEMS = [e.get('pt') or e['en'] for cat in ('culturas', 'minerais', 'peixes', 'coletaveis', 'culinaria') for e in load(cat)]

# ---- lib/map_data.dart: nome, região e dica de cada lugar ----
_map = open(os.path.join(APP, 'lib', 'map_data.dart'), encoding='utf-8').read()
REGION = {'norte': 'Norte', 'centro': 'Centro', 'sul': 'Sul', 'fora': 'Fora do vale'}
PLACES = {}
for blk in _map.split('MapPlace(')[2:]:
    name = re.search(r"name: '([^']*)'", blk)
    reg = re.search(r'region: MapRegion\.(\w+)', blk)
    tip = re.search(r"tip:\s*((?:'(?:[^'\\]|\\.)*'\s*)+)", blk)
    if name and reg:
        t = ''.join(re.findall(r"'((?:[^'\\]|\\.)*)'", tip.group(1))).replace("\\'", "'") if tip else ''
        PLACES[name.group(1)] = {'region': REGION[reg.group(1)], 'tip': t}

# ---- lib/game_status.dart: tabelas de locais ----
_gs = open(os.path.join(APP, 'lib', 'game_status.dart'), encoding='utf-8').read()


def dart_map(var):
    body = _gs[_gs.index(f'const {var} = {{'):]
    body = body[:body.index('};')]
    out = {}
    for k, v in re.findall(r"'([^']+)':\s*((?:'[^']*'\s*)+),", body):
        out[k] = ''.join(re.findall(r"'([^']*)'", v))
    return out


PLACE_BY_LOC = dart_map('_placeByLocation')
INTERIOR = dart_map('_interiorNames')
DIRECTIONS = dart_map('_directions')

WEATHER = {
    'sun': ('Sol', 'Dia de sol: regue as plantas, cuide dos animais e aproveite para explorar.'),
    'rain': ('Chuva', 'Chovendo: as plantas já estão regadas. Bom dia para pescar ou minerar.'),
    'storm': ('Tempestade', 'Tempestade: os animais ficam assustados e há raios. Evite a praia e cuide da fazenda.'),
    'snow': ('Neve', 'Neve: nada cresce ao ar livre. Foque em minas, pesca, animais e amizades.'),
    'wind': ('Vento', 'Dia de vento: aparecem folhas e sementes. Vale dar uma volta pela floresta.'),
    'green': ('Chuva verde', 'Chuva verde hoje: colete musgo, sementes e fibras. As plantas ficam regadas.'),
}
SKILLS = ['Cultivo', 'Pesca', 'Coleta', 'Mineração', 'Combate']
ACHIEVEMENTS = [('Agricultor', 'Ganhe 15.000g'), ('Pescador', 'Pesque 10 peixes diferentes'),
                ('Cozinheiro', 'Cozinhe 10 receitas diferentes'), ('Bom Vizinho', 'Chegue a 5 corações com 4 pessoas'),
                ('Explorador', 'Chegue ao andar 40 das minas'), ('Colecionador', 'Doe 20 itens ao museu')]


def location_info(raw):
    pname = PLACE_BY_LOC.get(raw)
    place = PLACES.get(pname) if pname else None
    display = INTERIOR.get(raw) or pname or re.sub(r'([a-z])([A-Z])', r'\1 \2', raw.replace('_', ' '))
    region = place['region'] if place else 'Fora do mapa'
    directions = DIRECTIONS.get(pname, 'Use o mapa do vale para se orientar.')
    tip = (place or {}).get('tip') or 'Abra o Mapa do Vale para ver os caminhos e os lugares próximos.'
    return {'display': display, 'place': pname, 'region': region, 'directions': directions, 'tip': tip}


def money(v):
    s = f'{abs(v):,}'.replace(',', '.')
    return f"{'-' if v < 0 else ''}{s}g"


def luck_phrase(l):
    if l >= 0.07:
        return 'Os espíritos estão muito felizes hoje.'
    if l >= 0.02:
        return 'A sorte está um pouco acima do normal.'
    if l <= -0.07:
        return 'Os espíritos estão bem irritados hoje.'
    if l <= -0.02:
        return 'A sorte está um pouco abaixo do normal.'
    return 'A sorte está neutra hoje.'


def short_place(v):
    """Lugar curto para a coluna LUGAR (o app corta em 42 caracteres)."""
    v = re.sub(r'\s*\(.*?\)', '', v or '').strip()
    return v.split(';')[0].split(',')[0].strip()[:40] or 'Vila Pelicanos'


# ---- Missões no estilo do jogo (título, objetivo, lugar, ação) ----
def make_quest():
    v = rng.choice(VILLAGERS)
    item = rng.choice(ITEMS)
    kind = rng.random()
    if kind < 0.45:
        return {'title': 'Ajuda Necessária', 'obj': f'Leve {item} para {v["name"]}.',
                'action': f'Entregar {item} para {v["name"]}', 'place': short_place(v['home'])}
    if kind < 0.6:
        fish = rng.choice([e.get('pt') or e['en'] for e in load('peixes')])
        return {'title': 'Pescaria', 'obj': f'Pesque um(a) {fish} para {v["name"]}.',
                'action': f'Pescar {fish} e levar para {v["name"]}', 'place': short_place(v['home'])}
    if kind < 0.75:
        n = rng.choice([5, 10, 15, 20, 40])
        return {'title': 'Explorando a Mina', 'obj': f'Chegue ao andar {n} das minas.',
                'action': f'Descer até o andar {n}', 'place': 'Minas'}
    if kind < 0.87:
        mon = rng.choice(['Slime verde', 'Morcego', 'Mosca da caverna', 'Caranguejo de pedra'])
        n = rng.choice([5, 10])
        return {'title': 'Controle de Pragas', 'obj': f'Derrote {n} {mon}.',
                'action': f'Derrotar {n} {mon}', 'place': 'Minas'}
    return {'title': 'Introduções', 'obj': 'Converse com todos os moradores da vila.',
            'action': 'Conversar com os moradores', 'place': 'Vila Pelicanos'}


LOCS = ['Farm', 'FarmHouse', 'Town', 'SeedShop', 'Saloon', 'Beach', 'FishShop', 'Mountain', 'Mine',
        'UndergroundMine', 'Forest', 'AnimalShop', 'BusStop', 'Coop', 'Barn', 'Greenhouse', 'ScienceHouse',
        'Blacksmith', 'CommunityCenter', 'Desert', 'Railroad', 'IslandSouth', 'WizardHouse']


def random_snapshot():
    season = rng.randrange(4)
    day = rng.randint(1, 28)
    w = {'season': season, 'day': day, 'year': rng.choice([1, 1, 1, 2, 2, 3]), 'weekday': WEEK[(day - 1) % 7],
         'weather': rng.choice(['sun'] * 5 + ['rain'] * 2 + ['storm', 'wind'] + (['snow'] * 3 if season == 3 else [])),
         'festival': None, 'birthdays': [], 'farm': rng.choice(['Girassol', 'Vale Verde', 'Recanto', 'Esperança'])}
    fest = [f for f in FESTIVALS if SEASONS[season] in f['data'] and str(day) in re.findall(r'\d+', f['data'])]
    if fest and rng.random() < 0.8:
        w['festival'] = fest[0]['name']
    bd = [v for v in VILLAGERS if v['bday'] and SEASONS[season] in v['bday'] and re.findall(r'\d+', v['bday']) == [str(day)]]
    if bd:
        w['birthdays'] = bd[:1]
    max_st = rng.choice([270, 270, 300, 348, 400])
    max_hp = rng.choice([100, 100, 115, 125, 150])
    p = {'name': rng.choice(['Bruno', 'Ana', 'Lia', 'Caio', 'Duda', 'Rafa']), 'money': rng.choice([120, 500, 1250, 4800, 12000, 56000]),
         'stamina': max_st * rng.choice([1, 0.9, 0.6, 0.3, 0.15, 0.08]), 'max_st': max_st,
         'health': int(max_hp * rng.choice([1, 1, 0.8, 0.5, 0.3])), 'max_hp': max_hp,
         'luck': rng.choice([-0.09, -0.04, 0, 0.01, 0.04, 0.09]), 'location': rng.choice(LOCS),
         'quests': [make_quest() for _ in range(rng.choice([0, 0, 0, 1, 1, 2]))]}
    for q in p['quests']:
        q['days'] = rng.choice([None, 1, 2, 3, 5])
    friends = rng.sample(VILLAGERS, rng.randint(0, 6))
    p['friends'] = [{'name': v['name'], 'hearts': rng.randint(0, 10), 'married': False, 'gift': rng.random() < 0.3,
                     'home': v['home'], 'loves': v['loves']} for v in friends]
    p['skills'] = {s: rng.randint(0, 10) for s in SKILLS}
    inv_n = rng.choice([3, 8, 14, 24, 31, 36])
    p['inventory'] = [(rng.choice(ITEMS), rng.randint(1, 30)) for _ in range(inv_n)]
    ach = rng.sample(ACHIEVEMENTS, len(ACHIEVEMENTS))
    p['ach_unlocked'] = rng.randint(0, len(ach) - 1)
    p['ach_next'] = ach[p['ach_unlocked']]
    return w, p


def closest_friend(friends):
    best, gap = None, 99
    for f in friends:
        if f['hearts'] <= 0:
            continue
        g = 10 - f['hearts']
        if 0 < g < gap:
            best, gap = f, g
    return best


def next_step(w, p):
    """recommendedNextStep: (título, corpo, tipo)"""
    qs = sorted(p['quests'], key=lambda q: q['days'] if q['days'] is not None else 99)
    if qs:
        q = qs[0]
        body = q['obj'] + (f" · {q['days']} dia(s) restante(s)" if q['days'] is not None else '')
        return f"Missão: {q['title']}", body, ('quest', q)
    if w['birthdays']:
        v = w['birthdays'][0]
        return (f"Aniversário de {v['name']}", 'Passe na casa ou no lugar onde essa pessoa costuma ficar e entregue um presente que ela ama.',
                ('birthday', v))
    if w['festival']:
        return (f"Hoje tem festival: {w['festival']}",
                'Vá até o local do festival, converse com os moradores e participe das atividades. As lojas podem fechar.', ('festival', None))
    if p['stamina'] / p['max_st'] < 0.2:
        return 'Energia baixa', 'Coma algo da mochila ou volte para casa e durma. Sem energia, você não consegue minerar nem regar.', ('energy', None)
    if p['health'] / p['max_hp'] < 0.35:
        return 'Vida baixa', 'Leve comida e evite descer mais fundo nas minas. Se a vida zerar, você acorda na cama e perde itens.', ('health', None)
    if w['day'] >= 25:
        return 'Fim da estação chegando', 'Colha tudo o que puder até o dia 28: o que ficar no campo morre na virada. Replante só o que ainda dá tempo.', ('season', None)
    f = closest_friend(p['friends'])
    if f and 8 <= f['hearts'] < 10:
        return (f"{f['name']} está quase no máximo", f"Faltam {10 - f['hearts']} coração(ões). Entregue um presente que essa pessoa ama hoje.",
                ('friend', f))
    label, tip = WEATHER[w['weather']]
    return 'Plano do dia', f'{tip} Regue as plantas, colete o que aparecer e converse com pelo menos um morador.', ('weather', None)


def status_tips(w, p, loc):
    tips = []
    label, wtip = WEATHER[w['weather']]
    if w['festival']:
        tips.append(('Festival hoje', f"{w['festival']}: largue as tarefas da fazenda e vá participar. É uma chance de amizade e itens exclusivos.", 'festival'))
    if p['stamina'] / p['max_st'] < 0.35:
        tips.append((f"Energia em {round(p['stamina'] / p['max_st'] * 100)}%", 'Leve comida para a mina ou faça uma pausa. Não espere passar mal no fim do dia.', 'energy'))
    if p['health'] / p['max_hp'] < 0.6:
        tips.append((f"Vida em {round(p['health'] / p['max_hp'] * 100)}%", 'Cuidado com slimes e morcegos. Comida com buff de defesa ajuda nas minas.', 'health'))
    if w['day'] >= 24:
        tips.append(('Últimos dias da estação', 'Colha e venda o que estiver maduro; o que ficar no campo morre no dia 28.', 'season'))
    tips.append((f'Clima: {label}', wtip, 'weather'))
    if len(p['inventory']) >= 30:
        tips.append(('Mochila quase cheia', f"Você está com {len(p['inventory'])} itens. Venda o que não usa ou guarde em um baú antes de minerar.", 'inventory'))
    f = closest_friend(p['friends'])
    if f and f['hearts'] >= 7:
        tips.append((f"{f['name']}: {f['hearts']}/10 corações",
                     'O presente de hoje já foi dado. Converse para manter a amizade.' if f['gift']
                     else 'Ainda dá tempo de entregar um presente hoje e subir mais um coração.', 'friend'))
    a = p['ach_next']
    tips.append((f'Próxima conquista: {a[0]}', a[1], 'achievement'))
    low = min((s for s in SKILLS if p['skills'][s] < 10), key=lambda s: p['skills'][s], default=None)
    if low:
        tips.append((f"{low} no nível {p['skills'][low]}",
                     'É a habilidade que mais pode crescer agora. Um pouco de prática todos os dias rende profissões melhores.', 'skill'))
    tips.append((f"Onde você está: {loc['display']}", loc['directions'], 'location'))
    return tips[:8]


def build_prompt(w, p, loc, nxt, tips):
    L = ['Você é o conselheiro do Guia do Vale, um subagente que ajuda uma pessoa a jogar Stardew Valley 1.6.',
         'Fale em português do Brasil, direto, como um amigo que conhece o jogo. Não invente dados.',
         'Ela está com o celular deitado ao lado do PC enquanto joga.',
         'Dê prioridade absoluta ao próximo passo prático e diga para onde ir. Não repita a ficha inteira.',
         'Se houver missão, fale dela primeiro. Se não houver, escolha a ação mais útil para hoje.',
         '', 'STATUS:',
         f"- Data: {SEASONS[w['season']]} {w['day']}, Ano {w['year']} ({w['weekday']}); clima: {WEATHER[w['weather']][0]}."]
    if w['festival']:
        L.append(f"- Festival hoje: {w['festival']}.")
    if w['birthdays']:
        L.append(f"- Aniversários: {', '.join(v['name'] for v in w['birthdays'])}.")
    L.append(f"- Local: {loc['display']} ({loc['region']}). {loc['directions']} {loc['tip']}")
    L.append(f"- Jogador: {p['name']}; fazenda: {w['farm']}; dinheiro: {money(p['money'])}.")
    pct = p['luck'] * 100
    L.append(f"- Energia: {round(p['stamina'])}/{p['max_st']}; vida: {p['health']}/{p['max_hp']}; "
             f"sorte: {'+' if pct >= 0 else ''}{pct:.1f}% ({luck_phrase(p['luck'])}).")
    if p['quests']:
        L.append('- Missões:')
        for q in p['quests'][:5]:
            days = f" ({q['days']} dia(s))" if q['days'] is not None else ''
            L.append(f"  · {q['title']}: {q['obj']}{days}")
    else:
        L.append('- Missões: nenhuma ativa.')
    L.append(f"- Mochila ({len(p['inventory'])} itens): {', '.join(f'{n} x{c}' for n, c in p['inventory'][:12])}.")
    fr = sorted(p['friends'], key=lambda f: -f['hearts'])
    if fr:
        L.append(f"- Amizades: {', '.join(f'{f["name"]} {f["hearts"]}♥' for f in fr[:6])}.")
    L.append(f"- Habilidades: {', '.join(f'{s} {p["skills"][s]}' for s in SKILLS)}.")
    L.append(f"- Conquistas: {p['ach_unlocked']} de {len(ACHIEVEMENTS)}.")
    crops = CROPS[SEASONS[w['season']]][:6]
    if crops:
        L.append(f"- Culturas da estação no guia: {', '.join(crops)}.")
    L += ['', 'SUGESTÃO DO GUIA (use como base, mas escolha a prioridade):', f'- {nxt[0]}: {nxt[1]}']
    for t, b, _ in tips[:4]:
        L.append(f'- {t}: {b}')
    L += ['', 'FORMATO OBRIGATÓRIO: responda SOMENTE com até 3 linhas, sem título, sem introdução e sem markdown.',
          'Cada linha deve seguir exatamente este formato:', 'AÇÃO CURTA | LUGAR | MOTIVO CURTO',
          'Exemplo: Regar as plantas | Fazenda | O dia está ensolarado e elas precisam de água',
          'Uma linha por objetivo. Diga o lugar mais próximo ou o caminho a seguir. Não escreva parágrafos.', 'Resposta:']
    return '\n'.join(L) + '\n'


def weather_line(w, loc):
    k = w['weather']
    if w['season'] == 3 and k in ('sun', 'wind'):
        return 'Minerar, pescar ou cuidar dos animais | Minas | Inverno: nada cresce ao ar livre'
    if k in ('rain', 'storm', 'green'):
        if k == 'storm':
            return 'Cuidar dos animais e da fazenda | Sua fazenda | Tempestade: evite a praia hoje'
        return ('Pescar ou descer nas minas | Praia ou Minas | Está chovendo e as plantas já estão regadas'
                if k == 'rain' else 'Coletar musgo, sementes e fibras | Floresta Cinzaseiva | Chuva verde: as plantas ficam regadas')
    if k == 'snow':
        return 'Minerar ou pescar | Minas | Neve: nada cresce ao ar livre'
    if k == 'wind':
        return 'Coletar folhas e sementes | Floresta Cinzaseiva | Dia de vento traz sementes pelo chão'
    return 'Regar as plantas | Sua fazenda | Dia de sol: elas precisam de água'


def answer(w, p, loc, nxt, tips):
    lines = []
    kind, obj = nxt[2]
    here = loc['place'] or loc['display']
    if kind == 'quest':
        days = f" ({obj['days']} dia(s))" if obj['days'] is not None else ''
        lines.append(f"{obj['action']} | {obj['place']} | Missão {obj['title']}{days}")
    elif kind == 'birthday':
        gift = f" ({obj['loves'][0]})" if obj['loves'] else ''
        lines.append(f"Dar um presente amado para {obj['name']}{gift} | {short_place(obj['home'])} | Hoje é aniversário: o presente vale 8x")
    elif kind == 'festival':
        f = next(f for f in FESTIVALS if f['name'] == w['festival'])
        lines.append(f"Ir ao {w['festival']} | {short_place(f['local'])} | Festival hoje: as lojas podem fechar")
    elif kind == 'energy':
        lines.append(f"Comer algo da mochila ou dormir | {here} | Energia em {round(p['stamina'] / p['max_st'] * 100)}%")
    elif kind == 'health':
        lines.append(f"Comer e evitar descer nas minas | {here} | Vida em {round(p['health'] / p['max_hp'] * 100)}%")
    elif kind == 'season':
        lines.append('Colher tudo o que estiver maduro | Sua fazenda | A estação acaba no dia 28' if w['season'] != 3
                     else 'Preparar as sementes da primavera | Armazém do Pierre | O inverno acaba no dia 28')
    elif kind == 'friend':
        lines.append(f"Dar um presente para {obj['name']} | {short_place(obj['home'])} | Faltam {10 - obj['hearts']} coração(ões)")
    else:
        lines.append(weather_line(w, loc))

    # Aniversário hoje vale 8x a amizade: entra logo depois da prioridade principal.
    if kind != 'birthday' and w['birthdays']:
        v = w['birthdays'][0]
        gift = f" ({v['loves'][0]})" if v['loves'] else ''
        lines.append(f"Dar um presente amado para {v['name']}{gift} | {short_place(v['home'])} | Hoje é aniversário: o presente vale 8x")

    for title, body, k in tips:
        if len(lines) >= 3:
            break
        if k == kind or (k == 'weather' and kind == 'weather'):
            continue
        if k == 'festival' and kind != 'festival':
            f = next(f for f in FESTIVALS if f['name'] == w['festival'])
            lines.append(f"Ir ao {w['festival']} | {short_place(f['local'])} | Chance de amizade e itens exclusivos")
        elif k == 'energy' and kind != 'energy':
            lines.append(f"Comer algo antes de continuar | {here} | {title}")
        elif k == 'health' and kind != 'health':
            if any(l.startswith('Comer') for l in lines):
                lines = [f"{l} e {title.lower()}" if l.startswith('Comer') else l for l in lines]
            else:
                lines.append(f"Comer algo e ir com calma | {here} | {title}")
        elif k == 'season' and kind != 'season' and w['season'] != 3:
            lines.append('Colher e vender o que estiver maduro | Sua fazenda | O que ficar no campo morre no dia 28')
        elif k == 'weather':
            l = weather_line(w, loc)
            if l not in lines:
                lines.append(l)
        elif k == 'inventory':
            lines.append(f"Guardar itens em um baú | Sua fazenda | Mochila com {len(p['inventory'])} itens")
        elif k == 'friend':
            f = closest_friend(p['friends'])
            if not f['gift'] and kind != 'friend':
                lines.append(f"Dar um presente para {f['name']} | {short_place(f['home'])} | {f['hearts']}/10 corações")
    return '\n'.join(lines[:3])


def main(n_train=1500, n_eval=60):
    rows = []
    while len(rows) < n_train + n_eval:
        w, p = random_snapshot()
        loc = location_info(p['location'])
        nxt = next_step(w, p)
        tips = status_tips(w, p, loc)
        rows.append({'prompt': build_prompt(w, p, loc, nxt, tips), 'answer': answer(w, p, loc, nxt, tips),
                     'cat': '_status', 'entry': '_status', 'q': nxt[0]})
    out = os.path.join(HERE, 'status')
    os.makedirs(out, exist_ok=True)
    for name, part in (('train.jsonl', rows[:n_train]), ('eval.jsonl', rows[n_train:])):
        with open(os.path.join(out, name), 'w', encoding='utf-8') as f:
            for r in part:
                f.write(json.dumps(r, ensure_ascii=False) + '\n')
    print(f'Status: treino {n_train} | validação {n_eval}')
    for r in rows[:2]:
        print('\n' + r['prompt'][-900:] + '\n>>> ' + r['answer'])


if __name__ == '__main__':
    main()
