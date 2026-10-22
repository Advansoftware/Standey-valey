# -*- coding: utf-8 -*-
"""Usa o dataset (npm stardew-valley-data) para: anexar sprites reais às entradas
v1 e criar as categorias novas. Chamado por build_seed.py."""
import json
import os
import re
import shutil
import unicodedata

from pt_names import pt as _pt
from pt_names import NAMES

HERE = os.path.dirname(os.path.abspath(__file__))
PKG = os.path.join(HERE, ".cache", "package")
DATA = os.path.join(PKG, "data")
ROOT = os.path.abspath(os.path.join(HERE, "..", ".."))
IMG_OUT = os.path.join(ROOT, "assets", "img")
os.makedirs(IMG_OUT, exist_ok=True)

EXTRA = {
    "Elvish Jewelry": "Joia élfica", "Silo": "Silo", "Bruschetta": "Bruschetta", "Escargot": "Escargot",
    "Pizza": "Pizza", "Poi": "Poi", "Sashimi": "Sashimi", "Lingcod": "Lingcod", "Slimejack": "Slimejack",
    "Walleye": "Walleye", "Woodskip": "Woodskip", "Coral": "Coral", "Jade": "Jade", "Duggy": "Duggy",
    "Pepper Rex": "Pepper Rex", "Any Egg": "Qualquer ovo", "Any Milk": "Qualquer leite", "Any Fish": "Qualquer peixe",
    "Any Fruit": "Qualquer fruta", "Any Vegetable": "Qualquer vegetal", "Any Flower": "Qualquer flor",
    "Oak Tree": "Carvalho", "Summer Spangle": "Flor-Miçanga", "Maple Tree": "Bordo", "Pine Tree": "Pinheiro", "Mahogany Tree": "Mogno",
    "Mushroom Tree": "Árvore de cogumelo", "Mystic Tree": "Árvore mística", "Fiddlehead Stalk": "Samambaia-gigante",
    "Palm Tree": "Palmeira", "Acorn": "Bolota", "Maple Seed": "Semente de bordo", "Pine Cone": "Pinha",
}
STATS = {"Farming": "Agricultura", "Fishing": "Pesca", "Foraging": "Coleta", "Mining": "Mineração",
         "Combat": "Combate", "Luck": "Sorte", "Max Energy": "Energia máx.", "Magnetism": "Magnetismo",
         "Speed": "Velocidade", "Defense": "Defesa", "Attack": "Ataque"}
SEASON = {"spring": "Primavera", "summer": "Verão", "fall": "Outono", "winter": "Inverno"}

# Frases de "onde achar" do dataset (inglês) traduzidas para PT-BR.
# As mais longas primeiro, para as substituições não se atropelarem.
LOC_PHRASES = [
    ("Crates and barrels in Mines/Skull Cavern/Volcano Dungeon",
     "caixas e barris nas Minas, Caverna da Caveira e Masmorra do Vulcão"),
    ("Hill-top / Four Corners farm", "fazenda na Colina ou em Quatro Cantos"),
    ("Breaking rocks in The Mines", "quebrando pedras nas Minas"),
    ("Tilling in Mines/Skull Cavern (any floor)", "arando em qualquer andar das Minas ou da Caverna da Caveira"),
    ("Tilling in Mines/Skull Cavern", "arando nas Minas ou na Caverna da Caveira"),
    ("Tilling in Mines (floor 40-79)", "arando nas Minas (andares 40-79)"),
    ("Tilling in Mines (floor 80+)", "arando nas Minas (andares 80+)"),
    ("Tilling in Mines (floor 1-39)", "arando nas Minas (andares 1-39)"),
    ("Prehistoric floors in Skull Cavern", "andares pré-históricos na Caverna da Caveira"),
    ("Skull Cavern treasure rooms", "salas de tesouro da Caverna da Caveira"),
    ("Skull Cavern (crates and barrels)", "Caverna da Caveira (caixas e barris)"),
    ("Skull Cavern (Desert Festival only)", "Caverna da Caveira (só no Festival do Deserto)"),
    ("Ginger Island West (beach)", "praia do oeste da Ilha Gengibre"),
    ("Ginger Island Dig Site", "sítios de escavação da Ilha Gengibre"),
    ("Ginger Island (dropped by enemies)", "Ilha Gengibre (soltado pelos inimigos)"),
    ("Ginger Island (foraged)", "Ilha Gengibre (coletável)"),
    ("Volcano Dungeon (Cinder Shard Nodes)", "Masmorra do Vulcão (veios de fragmento de brasa)"),
    ("Coal Nodes (Quarry, Quarry Mine, Volcano Dungeon)",
     "veios de carvão (Pedreira, Mina da Pedreira, Masmorra do Vulcão)"),
    ("Charcoal Kiln (10 Wood → 1 Coal)", "Fornalha de Carvão (10 de Madeira → 1 de Carvão)"),
    ("Recycling Machine (Trash or Driftwood)", "Máquina de Reciclagem (Lixo ou Madeira à Deriva)"),
    ("Dust Sprites (50% drop, Floors 41-79)", "Fadas-de-poeira (50% de chance, andares 41-79)"),
    ("Ghost, Frost Bat, Dust Sprite, Blue Slime drop (0.5%)",
     "Fantasma, Morcego de gelo, Fada-de-poeira ou Gosma azul (0,5%)"),
    ("Shadow Brute, Shadow Shaman, Spider drop (0.3%)",
     "Bruto das sombras, Xamã das sombras ou Aranha (0,3%)"),
    ("Magma Sprite, Magma Sparker, Magma Duggy, False Magma Cap drops",
     "Duende de magma, Fagulha de magma, Escavador de magma ou Capa de magma falso"),
    ("Bug, Cave Fly, Grub drop (0.5%)", "Bicho, Mosca da caverna ou Lagarta (0,5%)"),
    ("Skeleton and Lava Lurk drops", "Esqueletos e Espreitadores de Lava"),
    ("Most monsters (0.1%)", "a maioria dos monstros (0,1%)"),
    ("Most Bats (0.1%)", "a maioria dos morcegos (0,1%)"),
    ("Several monsters (0.5% each)", "vários monstros (0,5% cada)"),
    ("Several monsters (0.5-1.5%)", "vários monstros (0,5% a 1,5%)"),
    ("Monster drops (0.05%)", "monstros (0,05%)"),
    ("Monster Drops", "monstros"),
    ("Skeleton Drops", "esqueletos"),
    ("Various dig spots (very rare)", "vários pontos de escavação (muito raro)"),
    ("Various outdoor areas", "várias áreas externas"),
    ("Various Events", "eventos variados"),
    ("Special Rewards", "recompensas especiais"),
    ("Winter Tilling", "arando no inverno"),
    ("Stingray Fish Pond (population 7+)", "Lago de arraias (com 7 ou mais arraias)"),
    ("Mystic Stone (Mines Floor 100+)", "Pedra mística (Minas, andar 100+)"),
    ("Duggy drop (2%)", "Escavador de magma (2%)"),
    ("Duggy (10%)", "Escavador de magma (10%)"),
    ("Duggy (25%)", "Escavador de magma (25%)"),
    ("Desert Trader (3 Omni Geodes)", "Comerciante do Deserto (3 Ômnigeodos)"),
    ("Fishing Treasure Chests", "baús do tesouro (pescando)"),
    ("Fishing Treasure Chest (3.1-3.4%)", "baú do tesouro (pescando, 3,1% a 3,4%)"),
    ("Fishing Treasure Chest", "baú do tesouro (pescando)"),
    ("Artifact Trove (3.6%)", "baú de artefatos (3,6%)"),
    ("Artifact Spots", "pontos de artefato"),
    ("Bones on Ginger Island", "ossos na Ilha Gengibre"),
    ("Bone Nodes on Ginger Island", "veios de ossos na Ilha Gengibre"),
    ("Bone Nodes (0.8%)", "veios de ossos (0,8%)"),
    ("Amethyst Node", "veio de ametista"), ("Emerald Node", "veio de esmeralda"),
    ("Ruby Node", "veio de rubi"), ("Topaz Node", "veio de topázio"),
    ("Jade Node", "veio de jade"), ("Diamond Node", "veio de diamante"),
    ("Iridium Node (4%)", "veio de irídio (4%)"),
    ("Geodes (all types)", "geodos (todos os tipos)"),
    ("The Mines (Floors 80-120)", "as Minas (andares 80-120)"),
    ("The Mines (Floors 81-120)", "as Minas (andares 81-120)"),
    ("The Mines (Floors 81-119)", "as Minas (andares 81-119)"),
    ("The Mines (Floors 80+)", "as Minas (andares 80+)"),
    ("The Mines (Floors 1-120)", "as Minas (andares 1-120)"),
    ("The Mines (Floors 1-39)", "as Minas (andares 1-39)"),
    ("The Mines (Floors 1-29)", "as Minas (andares 1-29)"),
    ("The Mines (Floors 2-39)", "as Minas (andares 2-39)"),
    ("The Mines (Floors 31-39)", "as Minas (andares 31-39)"),
    ("The Mines (Floors 40-79)", "as Minas (andares 40-79)"),
    ("The Mines (Floors 41-79)", "as Minas (andares 41-79)"),
    ("The Mines (Floor 100+)", "as Minas (andar 100+)"),
    ("The Mines (Floor 80+)", "as Minas (andar 80+)"),
    ("The Mines (Floor 50+)", "as Minas (andar 50+)"),
    ("The Mines (Floor 40+)", "as Minas (andar 40+)"),
    ("The Mines (any floor)", "as Minas (qualquer andar)"),
    ("The Mines", "as Minas"),
    ("Mines", "Minas"),
    ("Skull Cavern", "Caverna da Caveira"),
    ("Volcano Dungeon", "Masmorra do Vulcão"),
    ("Quarry Mine", "Mina da Pedreira"),
    ("Quarry", "Pedreira"),
    ("Ginger Island", "Ilha Gengibre"),
    ("Bus Stop", "ponto de ônibus"),
    ("Backwoods", "mata"),
    ("Beach", "praia"),
    ("Forest", "floresta"),
    ("Mountain", "montanha"),
    ("Town", "cidade"),
    ("Desert", "deserto"),
    ("Farm", "fazenda"), ("Oasis", "oásis"),
    ("Garbage Can", "lixeira"),
    ("Haunted Skull", "crânio assombrado"),
    ("Dwarvish Sentry", "guarda anã"),
    ("Slime Ball", "bola de gosma"),
    ("Secret Note", "bilhete secreto"),
    ("Mining Level", "Nível de Mineração"),
    ("Fishing", "pescando"),
    ("Panning", "peneirando"),
    ("Tilling", "arando"),
    ("drop", "solta"),
    ("drops", "soltam"),
    ("Floors", "andares"),
    ("floor", "andar"),
    ("in ", "em "),
]

LOC = [("The Mines", "Minas"), ("Skull Cavern", "Caverna da Caveira"), ("Garbage Can", "Lixeira"),
       ("Floors", "andares"), ("Floor", "andar"), ("Any floor", "qualquer andar"), ("any floor", "qualquer andar"),
       ("The Farm", "Fazenda"), ("Ginger Island", "Ilha Gengibre"), ("Volcano Dungeon", "Masmorra do Vulcão"),
       ("Volcano", "Vulcão"), ("Mountain", "Montanha"), ("Beach", "Praia"), ("Desert", "Deserto"),
       ("Railroad", "Ferrovia"), ("Secret Woods", "Floresta Secreta"), ("Cindersap Forest", "Floresta Cindersap"),
       ("Bus Stop", "Ponto de ônibus"), ("Town", "Cidade"), ("Ocean", "Oceano"), ("River", "Rio"),
       ("Mountain Lake", "Lago da montanha"), ("Quarry", "Pedreira"), ("Mine", "Mina"), ("Tilling", "Arando"),
       ("Artifact Spot", "Ponto de artefato"), ("Artifact Spots", "Pontos de artefato"), ("Several monsters", "Vários monstros"),
       ("Fishing", "Pescando"), ("Panning", "Peneirando"), ("Crab Pot", "Armadilha de caranguejo"),
       ("Stone Golem", "Golem de pedra"), ("Wilderness Golem", "Golem selvagem"), ("Bats", "Morcegos"),
       ("Bat", "Morcego"), ("Dust Sprite", "Duende de poeira"), ("Geode", "Geodo"), ("Omni", "Omni"),
       ("Frozen", "Congelado"), ("Magma", "Magma"), ("Artifact Trove", "Baú de artefatos"),
       ("Tree", "Árvore"), ("Dwarf", "Anão"), ("Slimes", "Slimes"), ("Slime", "Slime"),
       ("Island", "Ilha"), ("Field Office", "Escritório de campo"), ("Night Market", "Mercado Noturno"),
       ("Witch's Swamp", "Pântano da Bruxa"), ("Swamp", "Pântano"), ("Forest", "Floresta"), ("Lake", "Lago"),
       ("Pond", "Lagoa"), ("Cave", "Caverna"), ("Sewers", "Esgoto"), ("Mutant Bug Lair", "Covil dos insetos mutantes")]


def pt(n):
    return EXTRA.get(n) or _pt(n)


def loc_pt(s):
    """Traduz a frase de local do dataset (inglês) para português."""
    if not s:
        return s
    out = s
    for en, p in sorted(LOC_PHRASES, key=lambda x: -len(x[0])):
        out = re.sub(re.escape(en), p, out, flags=re.IGNORECASE)
    for en, p in sorted(LOC, key=lambda x: -len(x[0])):
        out = re.sub(r"\b" + re.escape(en) + r"\b", p, out)
    # nomes de itens e monstros que ficaram em inglês
    for en, p in sorted(NAMES.items(), key=lambda x: -len(x[0])):
        if len(en) > 3 and re.search(r"\b" + re.escape(en) + r"\b", out):
            out = re.sub(r"\b" + re.escape(en) + r"\b", p, out)
    return out



def load(name):
    with open(os.path.join(DATA, name + ".json"), encoding="utf-8") as f:
        return json.load(f)


def flat_name(rel):
    r = rel[len("images/"):] if rel.startswith("images/") else rel
    r = unicodedata.normalize("NFKD", r).encode("ascii", "ignore").decode().lower()
    return re.sub(r"[^a-z0-9.]+", "_", r).strip("_")


_used = set()


def img(rel):
    """Copia a imagem para assets/img (nome achatado) e devolve o nome; '' se não existir."""
    if not rel:
        return ""
    src = os.path.join(PKG, rel)
    if not os.path.isfile(src):
        return ""
    n = flat_name(rel)
    dst = os.path.join(IMG_OUT, n)
    if n not in _used:
        shutil.copyfile(src, dst)
        _used.add(n)
    return n


# índice global por nome-base (fallback)
_base = {}
for dp, _, fs in os.walk(os.path.join(PKG, "images")):
    for f in fs:
        if f.lower().endswith((".png", ".gif")):
            k = os.path.splitext(f)[0].lower().replace("_", " ")
            _base.setdefault(k, os.path.relpath(os.path.join(dp, f), PKG))


def by_basename(en):
    return _base.get(en.lower().replace("_", " "), "")


def gold(n):
    return f"{n:,}".replace(",", ".") + " g"


def idify(s):
    s = unicodedata.normalize("NFKD", s).encode("ascii", "ignore").decode()
    return re.sub(r"[^a-z0-9]+", "_", s.lower()).strip("_")


# ------------------------------------------------------------ v1 enrich
# nome em português do pacote -> nome no dataset (para pegar o ícone)
BUNDLE_EN = {
    "Forrageio de Primavera": "Spring Foraging Bundle",
    "Forrageio de Verão": "Summer Foraging Bundle",
    "Forrageio de Outono": "Fall Foraging Bundle",
    "Forrageio de Inverno": "Winter Foraging Bundle",
    "Construção": "Construction Bundle",
    "Forrageio Exótico": "Exotic Foraging Bundle",
    "Culturas de Primavera": "Spring Crops Bundle",
    "Culturas de Verão": "Summer Crops Bundle",
    "Culturas de Outono": "Fall Crops Bundle",
    "Culturas de Qualidade": "Quality Crops Bundle",
    "Animais": "Animal Bundle",
    "Artesão": "Artisan Bundle",
    "Peixes de Rio": "River Fish Bundle",
    "Peixes de Lago": "Lake Fish Bundle",
    "Peixes do Oceano": "Ocean Fish Bundle",
    "Pesca Noturna": "Night Fishing Bundle",
    "Peixes Especiais": "Specialty Fish Bundle",
    "Armadilha de Caranguejo": "Crab Pot Bundle",
    "Ferreiro": "Blacksmith Bundle",
    "Geólogo": "Geologist's Bundle",
    "Aventureiro": "Adventurer's Bundle",
    "Chef": "Chef's Bundle",
    "Tintureiro": "Dye Bundle",
    "Pesquisa de Campo": "Field Research Bundle",
    "Ração": "Fodder Bundle",
    "Encantador": "Enchanter's Bundle",
    "2.500 ouro": "2500 Bundle",
    "5.000 ouro": "5000 Bundle",
    "10.000 ouro": "10000 Bundle",
    "25.000 ouro": "25000 Bundle",
}


def enrich_v1(entries):
    crops = {c["name"]: c for c in load("crops")}
    fish = {c["name"]: c for c in load("fish")}
    forage = {c["name"]: c for c in load("forageables")}
    vil = {c["name"]: c for c in load("villagers")}
    fests = {}
    for s in load("seasons"):
        for f in s.get("festivals", []):
            fests[f["name"]] = f

    for e in entries["culturas"]:
        c = crops.get(e["en"])
        if c:
            e["img"] = img(c["image"]) or img(by_basename(e["en"]))
            g = [[img(c["seedImage"]), "Semente"]] if c.get("seedImage") else []
            for i, st in enumerate(c.get("stages", []), 1):
                g.append([img(st["image"]), f"Estágio {i}"])
            g.append([e["img"], "Colheita"])
            e["gallery"] = [x for x in g if x[0]]
        else:
            e["img"] = img(by_basename(e["en"]))
    for e in entries["peixes"]:
        c = fish.get(e["en"])
        e["img"] = img(c["image"]) if c else img(by_basename(e["en"]))
    for e in entries["coletaveis"]:
        c = forage.get(e["en"])
        e["img"] = img(c["image"]) if c else img(by_basename(e["en"]))
    for e in entries["aldeoes"]:
        c = vil.get(e["en"])
        e["img"] = img(c["image"]) if c else img(by_basename(e["en"]))
        if c and c.get("spouseImage"):
            e["gallery"] = [[e["img"], "Retrato"], [img(c["spouseImage"]), "Casado(a)"]]
    for e in entries["festivais"]:
        f = fests.get(e["en"])
        e["img"] = img(f["image"]) if f else img(by_basename(e["en"]))
    for e in entries["habilidades"]:
        e["img"] = img("images/skills/%s.png" % e["en"]) or img(by_basename(e["en"]))
    for e in entries["animais"]:
        e["img"] = img(by_basename(e["en"])) or img(by_basename(e.get("img", "").replace(".png", "")))
    for g in entries["guia"]:
        if g.get("img"):
            g["img"] = img(by_basename(os.path.splitext(g["img"])[0])) or ""
    for e in entries["pacotes"]:
        # o ícone do pacote vem do dataset (imagens/bundles/bundle-images)
        en = BUNDLE_EN.get(e["pt"], "")
        e["img"] = img(by_basename(en)) if en else ""


# ------------------------------------------------------------ novas categorias
def money_fields(price):
    return [["Preço de venda", gold(price)]] if price else []


def trees():
    out = []
    for t in load("trees"):
        n = t["name"]
        gal = [[img(s["image"]), s["name"].replace("stage", "Fase").replace("mature", "Adulta")] for s in t.get("stages", [])]
        if t.get("seedImage") or t.get("saplingImage"):
            gal.insert(0, [img(t.get("saplingImage") or t["seedImage"]), "Semente/Muda"])
        gal = [x for x in gal if x[0]]
        if t["type"] == "fruit-tree":
            est = ", ".join(SEASON[s] for s in t["seasons"])
            fields = [["Tipo", "Árvore frutífera"], ["Estação da fruta", est], ["Amadurece em", f"{t['daysToMature']} dias"],
                      ["Muda", pt(t["saplingName"])]]
            for b in t.get("saplingBuyPrices", []):
                fields.append(["Compra da muda", f"{gold(b['price'])} ({b['place']})"])
            desc = (f"Árvore frutífera que dá {pt(n.replace(' Tree', ''))} em {est.lower()}. Plante a muda com espaço "
                    f"livre ao redor (3×3 tiles) e espere {t['daysToMature']} dias; depois ela dá 1 fruta por dia na estação.")
            sub = f"Fruta · {est}"
            tags = ["Frutífera"] + [SEASON[s] for s in t["seasons"]]
        else:
            seed = t.get("seedName")
            fields = [["Tipo", "Árvore selvagem"]]
            if seed:
                fields.append(["Semente (identifica a árvore)", pt(seed)])
            tp = t.get("tapper")
            if tp:
                fields.append(["Com torneira", pt(tp["name"]) + f" — {gold(tp['sellPrice'])}"])
            if t.get("choppedProduce"):
                fields.append(["Ao cortar", ", ".join(pt(x["name"]) for x in t["choppedProduce"])])
            desc = (f"Árvore selvagem. Como reconhecer: olhe a semente que ela solta — "
                    f"{pt(seed) if seed else 'nenhuma'} — e compare o sprite adulto na galeria abaixo.")
            sub = f"Selvagem · semente: {pt(seed)}" if seed else "Selvagem"
            tags = ["Selvagem"]
        out.append({"id": "tree_" + idify(n), "en": n, "pt": pt(n), "emoji": "🌳", "sub": sub, "tags": tags,
                    "img": img(t.get("image")) or (gal[-1][0] if gal else ""), "gallery": gal, "fields": fields, "desc": desc})
    return out


KIND = {"mineral": "Mineral", "node": "Veio de pedra", "geode": "Geodo", "bar": "Barra", "ore": "Minério", "resource": "Recurso"}


def minerals():
    out = []
    for m in load("minerals"):
        kind = KIND.get(m.get("kind"), "Item")
        fields = [["Tipo", kind]] + money_fields(m.get("sellPrice"))
        if m.get("locations"):
            fields.append(["Onde achar", "; ".join(loc_pt(x) for x in m["locations"][:6])])
        if m.get("gemologistPrice"):
            fields.append(["Preço com Gemólogo", gold(m["gemologistPrice"])])
        if m.get("contents"):
            fields.append(["Contém", ", ".join(pt(x if isinstance(x, str) else x.get("name", "")) for x in m["contents"][:10])])
        out.append({"id": "min_" + idify(m["name"] + str(m.get("id", ""))), "en": m["name"], "pt": pt(m["name"]), "emoji": "💎",
                    "sub": kind + (f" · {gold(m['sellPrice'])}" if m.get("sellPrice") else ""), "tags": [kind],
                    "img": img(m.get("image")), "fields": fields,
                    "desc": f"{kind} do jogo. Use os campos abaixo para saber onde encontrar e quanto vale."})
    return out


def monsters():
    loot = {l["id"]: l for l in load("monster-loot")}
    out = []
    for m in load("monsters"):
        variants = [m] + m.get("variants", [])
        gal = [[img(v.get("image")), pt(v["name"])] for v in variants if img(v.get("image"))]
        fields = [["Vida", str(m["hp"])], ["Dano", str(m["damage"])], ["XP", str(m["xp"])],
                  ["Onde", "; ".join(loc_pt(x) for x in m.get("locations", []))]]
        drops = [pt(loot[i]["name"]) for i in m.get("lootIds", []) if i in loot]
        if drops:
            fields.append(["Solta", ", ".join(drops)])
        if len(variants) > 1:
            fields.append(["Variantes", ", ".join(pt(v["name"]) for v in variants[1:])])
        out.append({"id": "mon_" + idify(m["name"]), "en": m["name"], "pt": pt(m["name"]), "emoji": "👾",
                    "sub": f"Vida {m['hp']} · dano {m['damage']}" + (" · perigoso" if m.get("dangerous") else ""),
                    "tags": ["Perigoso" if m.get("dangerous") else "Comum"], "img": img(m.get("image")),
                    "gallery": gal, "fields": fields,
                    "desc": f"Monstro com {m['hp']} de vida e {m['damage']} de dano. Veja onde aparece e o que solta."})
    return out


def src_pt(s):
    t = s["type"]
    if t == "default":
        return "Já vem conhecida"
    if t == "friendship":
        return f"{s['villager']}: {s['hearts']} corações"
    if t == "queen-of-sauce":
        return f"Rainha do Molho: {SEASON[s['season']]} dia {s['day']}, ano {s['year']}"
    if t == "purchase":
        return f"Compra com {s['from']} por {gold(s['price'])}" if s.get("currency", "g") == "g" else f"Compra com {s['from']}"
    if t == "skill":
        return f"Habilidade {STATS.get(s.get('skill'), s.get('skill', ''))} nível {s.get('level', '')}"
    return "Evento especial"


def cooking():
    out = []
    for c in load("cooking"):
        fields = [["Ingredientes", ", ".join(f"{i['quantity']}× {pt(i['name'])}" for i in c["ingredients"])]]
        eh = c.get("energyHealth") or {}
        if eh:
            fields.append(["Energia / Vida", f"{eh.get('energy', 0)} / {eh.get('health', 0)}"])
        if c.get("buffs"):
            dur = c.get("buffDuration")
            fields.append(["Bônus", ", ".join(f"{STATS.get(b['stat'], b['stat'])} +{b['value']}" for b in c["buffs"])
                           + (f" ({dur // 60} min)" if dur else "")])
        fields.append(["Receita", "; ".join(src_pt(s) for s in c["recipeSources"])])
        fields += money_fields(c.get("sellPrice"))
        out.append({"id": "cook_" + idify(c["name"]), "en": c["name"], "pt": pt(c["name"]), "emoji": "🍲",
                    "sub": f"Energia {eh.get('energy', 0)}" + (" · com bônus" if c.get("buffs") else ""),
                    "tags": ["Com bônus" if c.get("buffs") else "Simples"], "img": img(c.get("image")), "fields": fields,
                    "desc": "Prato que você cozinha na cozinha da fazenda (precisa da receita)."})
    return out


def artifacts():
    out = []
    for a in load("artifacts"):
        fields = money_fields(a.get("sellPrice"))
        if a.get("locations"):
            fields.append(["Onde achar", "; ".join(loc_pt(x) for x in a["locations"][:6])])
        out.append({"id": "art_" + idify(a["name"]), "en": a["name"], "pt": pt(a["name"]), "emoji": "🏺",
                    "sub": "Doe ao museu", "tags": ["Artefato"], "img": img(a.get("image")), "fields": fields,
                    "desc": "Artefato para doar à Biblioteca-Museu. Aparece ao cavar pontos de minhoca, pescar baús e vencer monstros."})
    return out


def buildings():
    out = []
    for b in load("buildings"):
        fields = [["Construtor", b.get("builder") or "—"], ["Custo", gold(b["buildCost"]) if b.get("buildCost") else "Grátis"],
                  ["Tempo", f"{b.get('buildDays', 0)} dias"]]
        if b.get("materials"):
            fields.append(["Materiais", ", ".join(f"{m['quantity']}× {pt(m['item'])}" for m in b["materials"])])
        if b.get("animalCapacity"):
            fields.append(["Capacidade de animais", str(b["animalCapacity"])])
        out.append({"id": "bld_" + idify(b["id"]), "en": b["name"], "pt": pt(b["name"]), "emoji": "🏠",
                    "sub": gold(b["buildCost"]) if b.get("buildCost") else "Construção", "tags": ["Construção"],
                    "img": img(b.get("image")), "fields": fields,
                    "desc": "Construção da fazenda. Peça ao Robin na Carpintaria (Montanha)."})
    return out


LVL = {"basic": "Básico", "copper": "Cobre", "steel": "Aço", "gold": "Ouro", "iridium": "Irídio"}


def tools():
    out = []
    for t in load("tools"):
        levels = t.get("levels") or []
        gal, fields = [], [["Tipo", {"upgradeable": "Melhorável", "simple": "Simples", "backpack": "Mochila",
                                      "fishing-rod": "Vara de pesca"}.get(t["type"], "Ferramenta")]]
        for l in levels:
            raw = str(l.get("level") or l.get("name") or "")
            label = LVL.get(raw.lower()) or pt(raw)
            if img(l.get("image")):
                gal.append([img(l["image"]), label])
            cost = l.get("upgradeCost") or l.get("cost")
            if cost:
                mat = f" + {l['materialQuantity']}× {pt(l['materialName'])}" if l.get("materialName") else ""
                fields.append([label, gold(cost) + mat])
            elif l.get("fishingLevelRequired") is not None:
                fields.append([label, f"Pesca nível {l['fishingLevelRequired']}"])
        if t.get("cost"):
            fields.append(["Custo", gold(t["cost"])])
        if t.get("slots"):
            fields.append(["Espaços", str(t["slots"])])
        image = img(t.get("image")) or (gal[0][0] if gal else "")
        out.append({"id": "tool_" + idify(t["id"]), "en": t["name"], "pt": pt(t["name"]), "emoji": "🔧",
                    "sub": "Ferramenta", "tags": ["Ferramenta"], "img": image, "gallery": gal, "fields": fields,
                    "desc": "Ferramenta de uso diário. Melhore no Ferreiro (Clint) levando barras de metal."})
    return out
