# -*- coding: utf-8 -*-
"""Gera assets/data/*.json a partir das tabelas em data_core.py e data_guia.py.

Uso:  python3 tools/seed/build_seed.py
"""
import json
import os
import re
import sys
import unicodedata

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
import data_core as D  # noqa: E402
import data_guia as G  # noqa: E402
import enrich as E  # noqa: E402
import utility as U  # noqa: E402

OUT = os.path.abspath(os.path.join(HERE, "..", "..", "assets", "data"))
os.makedirs(OUT, exist_ok=True)


def slug(s):
    s = unicodedata.normalize("NFKD", s).encode("ascii", "ignore").decode()
    return re.sub(r"[^a-z0-9]+", "_", s.lower()).strip("_")


def png(en):
    return en.replace(" ", "_") + ".png"


def seasons_in(text):
    found = [s for s in D.ESTACOES if s in text]
    if "Todas" in text and not found:
        return list(D.ESTACOES)
    return found


def fmt_g(n):
    return f"{n:,}".replace(",", ".") + " g"


entries = {}


# ----------------------------------------------------------- PEIXES
def fish_entry(row, extra_tags=()):
    en, pt, loc, est, hora, clima, dif, preco, emoji = row[:9]
    tags = seasons_in(est) + list(extra_tags)
    return {
        "id": "fish_" + slug(en), "en": en, "pt": pt, "emoji": emoji,
        "sub": f"{loc.split(';')[0]} · {est.split('(')[0].strip()}",
        "tags": tags,
        "img": png(en),
        "fields": [["Onde pescar", loc], ["Estações", est], ["Horário", hora],
                   ["Clima", clima], ["Dificuldade", str(dif)], ["Preço base", fmt_g(preco)]],
        "desc": f"Peixe encontrado em: {loc}. Fica disponível em {est.lower()}, no horário {hora}, com clima: {clima.lower()}. Vale {fmt_g(preco)} (qualidade normal).",
        "meta": {"price": preco},
    }


fish = [fish_entry(r) for r in D.FISH]
fish += [fish_entry(r, ["Mercado Noturno"]) for r in D.FISH_NIGHT]
for en, pt, loc, est, hora, clima, dif, preco in D.FISH_LEGEND:
    fish.append(fish_entry((en, pt, loc, est, hora, clima, dif, preco, "🏆"), ["Lendário"]))
for en, pt, loc, c1, c2, preco, emoji in D.CRAB:
    fish.append({
        "id": "crab_" + slug(en), "en": en, "pt": pt, "emoji": emoji,
        "sub": f"Armadilha de caranguejo · {loc}", "tags": ["Armadilha"],
        "img": png(en),
        "fields": [["Onde", loc], ["Chance sem Marinheiro", c1], ["Chance com Marinheiro", c2], ["Preço base", fmt_g(preco)]],
        "desc": f"Pego em armadilhas de caranguejo colocadas em água ({loc.lower()}). Vale {fmt_g(preco)}.",
        "meta": {"price": preco},
    })
entries["peixes"] = fish


# ----------------------------------------------------------- CULTURAS
def crop_profit(grow, regrow, sell, yld, seed):
    if seed is None:
        return None
    if regrow:
        harvests = 1 + max(0, (28 - grow)) // regrow
        total = harvests * sell * yld - seed
    else:
        harvests = 28 // grow
        total = harvests * (sell * yld - seed)
    return round(total / 28, 1)


crops = []
for en, pt, est, fonte, preco_sem, dias, rebrota, venda, rend, emoji, nota in D.CROPS:
    lucro = crop_profit(dias, rebrota, venda, rend, preco_sem)
    fields = [["Estação", est], ["Semente", fonte + (f" — {fmt_g(preco_sem)}" if preco_sem else "")],
              ["Tempo de crescimento", f"{dias} dias"],
              ["Rebrota", f"a cada {rebrota} dias" if rebrota else "Colheita única"],
              ["Preço de venda", fmt_g(venda) + (f" (×{rend} por colheita)" if rend > 1 else "")]]
    if lucro is not None:
        fields.append(["Lucro/dia (aprox.)", f"{lucro:.1f} g (28 dias, sem qualidade)".replace(".", ",")])
    crops.append({
        "id": "crop_" + slug(en), "en": en, "pt": pt, "emoji": emoji,
        "sub": f"{est} · {dias} dias" + (f" · rebrota {rebrota}d" if rebrota else ""),
        "tags": seasons_in(est) + (["Refloresce"] if rebrota else []),
        "img": png(en), "fields": fields,
        "desc": nota or f"Cultura de {est.lower()} que leva {dias} dias para crescer.",
        "meta": {"price": venda, "profit": lucro},
    })
entries["culturas"] = crops

# ----------------------------------------------------------- COLETÁVEIS
forage = []
for en, pt, est, onde, preco, emoji, nota in D.FORAGE:
    forage.append({
        "id": "forage_" + slug(en), "en": en, "pt": pt, "emoji": emoji,
        "sub": f"{est} · {onde}", "tags": seasons_in(est) or list(D.ESTACOES),
        "img": png(en),
        "fields": [["Estação", est], ["Onde achar", onde], ["Preço base", fmt_g(preco)]],
        "desc": nota, "meta": {"price": preco},
    })
entries["coletaveis"] = forage

# ----------------------------------------------------------- MORADORES
vill = []
for en, pt, s, d, casavel, local, ama, nota, emoji in D.VILL:
    est = D.ESTACOES[s]
    vill.append({
        "id": "vill_" + slug(en), "en": en, "pt": pt, "emoji": emoji,
        "sub": f"Aniversário: {est} {d}" + (" · casável" if casavel else ""),
        "tags": [est, "Casável" if casavel else "Não casável"],
        "img": png(en),
        "fields": [["Aniversário", f"{est}, dia {d}"], ["Casável", "Sim" if casavel else "Não"],
                   ["Onde mora/trabalha", local], ["Presentes amados", ", ".join(ama)]],
        "desc": nota + " Dê presentes que ele(a) ama para ganhar muita amizade, principalmente no aniversário.",
        "meta": {"season": s, "day": d, "marry": casavel},
    })
entries["aldeoes"] = vill

# ----------------------------------------------------------- FESTIVAIS
fest = []
for en, pt, s, dias, hora, local, desc, emoji in D.FEST:
    est = D.ESTACOES[s]
    data = f"{est} {dias[0]}" if len(dias) == 1 else f"{est} {dias[0]}–{dias[-1]}"
    fest.append({
        "id": "fest_" + slug(en), "en": en, "pt": pt, "emoji": emoji,
        "sub": f"{data} · {local}", "tags": [est],
        "img": png(en),
        "fields": [["Data", data], ["Horário", hora], ["Local", local]],
        "desc": desc,
        "meta": {"season": s, "days": dias},
    })
entries["festivais"] = fest

# ----------------------------------------------------------- HABILIDADES
sk = []
for en, pt, emoji, sub, desc, profs in D.SKILLS:
    fields = [[nivel, texto] for nivel, texto in profs]
    sk.append({
        "id": "skill_" + slug(en), "en": en, "pt": pt, "emoji": emoji, "sub": sub,
        "tags": ["Habilidade"], "img": en + "_Skill_Icon.png", "fields": fields, "desc": desc,
    })
entries["habilidades"] = sk

# ----------------------------------------------------------- ANIMAIS
alt_img = {"Chicken": "White_Chicken.png", "Cow": "White_Cow.png"}
ANIMAL_ORIGIN = {
    "Dinosaur": "Choque um Ovo de dinossauro na Incubadora do Galinheiro grande",
    "Ostrich": "Choque um Ovo de avestruz na Incubadora de avestruz, dentro do Celeiro",
    "Horse": "Vem junto com o Estábulo, construído pelo Robin na Carpintaria",
}
an = []
for en, pt, pred, preco, prod, nota, emoji in D.ANIMALS:
    fields = [["Onde vive", pred], ["Preço", fmt_g(preco) if preco else "Não é comprado"]]
    if preco:
        fields.append(["Onde comprar", "Rancho da Marnie (Floresta Cinzaseiva), 9h–16h; fechado segunda e terça"])
    elif en in ANIMAL_ORIGIN:
        fields.append(["Como conseguir", ANIMAL_ORIGIN[en]])
    fields.append(["Produtos", prod])
    an.append({
        "id": "animal_" + slug(en), "en": en, "pt": pt, "emoji": emoji,
        "sub": f"{pred}" + (f" · {fmt_g(preco)}" if preco else ""),
        "tags": ["Galinheiro" if "Galinheiro" in pred else ("Celeiro" if "Celeiro" in pred else "Outros")],
        "img": alt_img.get(en, png(en)), "fields": fields, "desc": nota,
    })
entries["animais"] = an

# ----------------------------------------------------------- PACOTES
pk = []
for sala, lista in D.BUNDLES.items():
    for nome, itens, qtd, recompensa in lista:
        pk.append({
            "id": "bundle_" + slug(sala) + "_" + slug(nome),
            "en": nome, "pt": nome, "emoji": D.ROOM_EMOJI[sala],
            "sub": f"{sala} · entregue {qtd} de {len(itens)}",
            "tags": [sala], "img": "",
            "fields": [["Sala", sala], ["Quantidade", f"{qtd} de {len(itens)} itens"], ["Recompensa do pacote", recompensa],
                       ["Recompensa da sala", D.ROOM_REWARD[sala]]],
            "checklist": itens,
            "desc": f"Pacote da {sala}. Entregue {qtd} dos itens abaixo para completar.",
            "meta": {"need": qtd},
        })
entries["pacotes"] = pk

# ----------------------------------------------------------- GUIA
guide = []
for g in G.GUIDE:
    guide.append({
        "id": g["id"], "en": g["pt"], "pt": g["pt"], "emoji": g["emoji"], "sub": g["sub"],
        "tags": g["tags"], "img": g.get("img", ""), "fields": [], "desc": g["sub"], "body": g["body"],
    })
entries["guia"] = guide

E.enrich_v1(entries)
entries["guia"].append({
    "id": "guia_arvores", "en": "Como reconhecer as árvores", "pt": "Como reconhecer as árvores", "emoji": "🌲",
    "sub": "Carvalho, bordo ou pinheiro? Veja pela semente", "tags": ["Fazenda"],
    "img": E.img("images/trees/oak/portrait.png"), "fields": [], "desc": "Como diferenciar as árvores.",
    "body": "## O truque da semente\n• Bolota = Carvalho\n• Semente de bordo = Bordo\n• Pinha = Pinheiro\n"
            "Cada árvore selvagem solta a própria semente ao ser sacudida ou cortada.\n"
            "## Veja os sprites\nAbra Enciclopédia → Árvores: cada árvore mostra a semente e as fases de crescimento com os desenhos do jogo.\n"
            "## Dica\nCarvalho dá Resina de carvalho, bordo dá Xarope de bordo e pinheiro dá Alcatrão de pinho com a torneira.",
})
entries["guia"].append({
    "id": "guia_arvores_cultivo", "en": "Árvores: cortar, deixar ou plantar?", "pt": "Árvores: cortar, deixar ou plantar?",
    "emoji": "🌳", "sub": "O que cada árvore rende e por que vale a pena manter algumas", "tags": ["Fazenda", "Árvores"],
    "img": E.img("images/trees/pine/portrait.png"), "fields": [],
    "desc": "Vantagens de manter e plantar árvores, com o que cada uma produz.",
    "body": """## Devo deixar as árvores na fazenda?
• Sim, deixe pelo menos algumas. Árvores comuns dão Madeira, Seiva e sementes quando cortadas, e com uma Torneirinha viram renda passiva: o produto fica pronto sozinho e você só precisa passar para coletar.
• Carvalho, bordo e pinheiro produzem a cada 5–9 dias; árvores frutíferas dão 1 fruta por dia durante a estação depois de adultas (28 dias).
• Deixe 3×3 livre ao redor da muda para ela crescer. Depois de adulta, pode colocar objetos perto sem perder produção.
• Se estiver sem espaço, corte as árvores do meio do terreno e mantenha as da borda. Guarde as sementes para replantar onde quiser.
• Não é preciso regar árvores. Só cuide para não deixar mato, pedras ou outras árvores encostarem na muda.

## Para que serve cada árvore
• Carvalho: Torneirinha → Resina de Carvalho (150 g). A resina é usada para fazer o Barril, que transforma fruta em Vinho e vegetal em Suco — um dos maiores saltos de lucro do jogo.
• Bordo: Torneirinha → Xarope de Bordo (200 g). Serve para o Apiário (produz Mel) e para receitas.
• Pinheiro: Torneirinha → Alcatrão de Pinho (100 g). Serve para o Tear, o Solo Foliar, o Totem de Chuva e o pacote Recursos Exóticos. A Madeira e a Pinha também servem para construir e replantar.
• Mogno: Torneirinha → Seiva; ao cortar dá 8–13 Madeiras de Lei. É a melhor fonte renovável de Madeira de Lei para construções e melhorias.
• Árvore de Cogumelo: Torneirinha → Cogumelos comum, vermelho e roxo. É comida grátis e ajuda em receitas e pacotes.
• Árvore Mística: Torneirinha → Xarope Místico (1.000 g a cada 7 dias). É a árvore que mais rende com torneira.
• Palmeira: não aceita Torneirinha; ao sacudir ou cortar dá Coco e, na Ilha Gengibre, Coco Dourado.

## Vantagens de plantar um pinheiro
• Renda passiva: com Torneirinha, dá Alcatrão de Pinho a cada 5–6 dias (100 g cada).
• Madeira de graça: cortar rende Madeira, Seiva e Pinha; a Pinha replanta sem custo.
• O Alcatrão serve para o Tear (roupas), o Solo Foliar (acelera o crescimento), o Totem de Chuva e o pacote Recursos Exóticos.
• Cresce na primavera, no verão e no outono (não cresce no inverno) e ocupa só 1 tile.
• Dica: plante pinheiros nas bordas da fazenda, longe das culturas, e coloque Torneirinha em todos. Você não precisa regar.

## Cuidados
• Árvores e sementes precisam de 3×3 livre; se algo estiver ao redor, param no estágio 4.
• No inverno as árvores comuns não crescem; a Árvore Mística cresce com Fertilizante de Árvore.
• Raio destrói árvore comum e deixa só o toco; árvores frutíferas atingidas por raio produzem carvão por alguns dias.
• Cortar uma árvore não faz ela voltar do toco: é preciso plantar outra semente.
• Se quiser madeira sem acabar com o bosque, corte só as árvores adultas e replante as sementes no mesmo lugar.""",
})
entries["arvores"] = E.trees()
entries["minerais"] = E.minerals()
entries["monstros"] = E.monsters()
entries["culinaria"] = E.cooking()
entries["artefatos"] = E.artifacts()
entries["construcoes"] = E.buildings()
entries["ferramentas"] = E.tools()

# A utilidade depende da categoria; define antes de enriquecer.
for cid, items in entries.items():
    for e in items:
        e["cat"] = cid
U.enrich(entries)

CATS = [
    ("guia", "Comece aqui", "📖", "#2E7D32", "Guia do iniciante: o que fazer, em que ordem e como progredir.", ""),
    ("culturas", "Culturas", "🌱", "#5B8C3A", "Tudo sobre plantio: tempo de crescimento, lucro e estações.", "Já plantei"),
    ("peixes", "Peixes", "🐟", "#3F7FBF", "Onde, quando e como pescar cada peixe.", "Já pesquei"),
    ("aldeoes", "Moradores", "🧑‍🌾", "#C2185B", "Aniversários, presentes amados e casamento.", "Amizade máxima"),
    ("festivais", "Calendário e festivais", "🎉", "#F57C00", "Eventos de cada estação.", "Já fui"),
    ("pacotes", "Centro Comunitário", "🏛️", "#8E24AA", "Todos os pacotes, com checklist de itens.", "Concluído"),
    ("coletaveis", "Coletáveis", "🍄", "#7B5E2A", "Itens da natureza por estação.", "Já coletei"),
    ("habilidades", "Habilidades", "⭐", "#FBC02D", "Habilidades e profissões.", ""),
    ("animais", "Animais", "🐄", "#A1887F", "Animais da fazenda e seus produtos.", "Tenho"),
    ("arvores", "Árvores", "🌳", "#33691E", "Carvalho, bordo, pinheiro e frutíferas: veja o sprite e a semente.", "Já vi"),
    ("minerais", "Minerais e geodos", "💎", "#00838F", "Gemas, minérios, barras e geodos.", "Já tenho"),
    ("monstros", "Monstros", "👾", "#6A1B9A", "Vida, dano, onde aparecem e o que soltam.", "Já derrotei"),
    ("culinaria", "Culinária", "🍲", "#D84315", "Receitas, bônus e como desbloquear.", "Já cozinhei"),
    ("artefatos", "Artefatos", "🏺", "#795548", "Para doar ao museu.", "Já doei"),
    ("construcoes", "Construções", "🏠", "#546E7A", "Celeiro, galinheiro, poço e mais.", "Já construí"),
    ("ferramentas", "Ferramentas", "🔧", "#607D8B", "Melhorias e custos.", "Tenho"),
]
index = []
for cid, title, emoji, color, desc, collect in CATS:
    items = entries[cid]
    for e in items:
        e.setdefault("gallery", [])
    for i, e in enumerate(items):
        e["n"] = i + 1
        e["cat"] = cid
        e.setdefault("meta", {})
    with open(os.path.join(OUT, cid + ".json"), "w", encoding="utf-8") as f:
        json.dump({"id": cid, "title": title, "entries": items}, f, ensure_ascii=False, separators=(",", ":"))
    index.append({"id": cid, "title": title, "emoji": emoji, "color": color, "desc": desc, "collect": collect, "count": len(items)})

with open(os.path.join(OUT, "index.json"), "w", encoding="utf-8") as f:
    json.dump({"categories": index}, f, ensure_ascii=False, indent=1)

print("OK", {c["id"]: c["count"] for c in index})
