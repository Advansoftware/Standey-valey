# -*- coding: utf-8 -*-
"""Acrescenta a cada ficha a coluna "Utilidade" (para que o item serve no
jogo) e o preço de venda quando ele existe. Os textos são montados a partir
do dataset (usos em receitas, pacotes, presentes e produtos artesanais) e de
algumas listas curtas escritas à mão para construções, ferramentas e festas.

Chamado por build_seed.py depois de todas as categorias serem montadas.
"""
import json
import os

from enrich import BUNDLE_EN
from enrich import gold
from enrich import pt as tr

HERE = os.path.dirname(os.path.abspath(__file__))
DATA = os.path.join(HERE, ".cache", "package", "data")

BUNDLE_PT = {en: pt for pt, en in BUNDLE_EN.items()}


def load(name):
    with open(os.path.join(DATA, name + ".json"), encoding="utf-8") as f:
        return json.load(f)


def names(lst, limit=3):
    """Lista nomes traduzidos, sem repetir, no formato 'A, B e C'."""
    out = []
    for n in lst:
        p = tr(n)
        if p and p not in out:
            out.append(p)
        if len(out) >= limit:
            break
    if not out:
        return ""
    if len(out) == 1:
        return out[0]
    return ", ".join(out[:-1]) + " e " + out[-1]


# ---------------------------------------------------------------- listas fixas
BUILDING_USE = {
    "Coop": "Abriga galinhas, patos, coelhos e dinossauros. É o primeiro passo para ovos, penas e lã.",
    "Big Coop": "Aumenta a capacidade do galinheiro e libera a incubadora (choca ovos) e os patos.",
    "Deluxe Coop": "Maior capacidade e alimentação automática; libera os coelhos.",
    "Barn": "Abriga vacas. O leite diário vira queijo na prensa e rende bem.",
    "Big Barn": "Aumenta a capacidade do celeiro e libera as cabras.",
    "Deluxe Barn": "Maior capacidade, alimentação automática e libera ovelhas e porcos.",
    "Well": "Permite encher o regador sem ir até a água; útil em fazendas grandes.",
    "Silo": "Guarda o feno cortado da grama para alimentar os animais. Construa antes do galinheiro.",
    "Mill": "Transforma trigo em farinha e beterraba em açúcar para cozinhar.",
    "Shed": "Espaço extra para barris, jarras de conserva e outras máquinas.",
    "Big Shed": "Versão maior do galpão: mais máquinas no mesmo espaço.",
    "Fish Pond": "Cria peixes e produz ovas e itens; ótimo para renda passiva e peixes raros.",
    "Stable": "Desbloqueia o cavalo, que deixa você andar mais rápido pelo mapa.",
    "Slime Hutch": "Cria gosmas; elas soltam gosma, usada em receitas e artesanato.",
    "Cabin": "Casa extra para outro jogador no modo cooperativo.",
    "Pet Bowl": "Deixa você adotar e cuidar de um bichinho de estimação.",
    "Shipping Bin": "Vende automaticamente durante a noite o que você colocar dentro.",
    "Junimo Hut": "Junimos colhem as culturas ao redor da cabana sozinhos.",
    "Earth Obelisk": "Teleporta você para a Montanha.",
    "Water Obelisk": "Teleporta você para a Praia.",
    "Desert Obelisk": "Teleporta você para o Deserto Calico.",
    "Island Obelisk": "Teleporta você para a Ilha Gengibre.",
    "Gold Clock": "Impede que mato e cercas se espalhem e estraguem a fazenda; item de fim de jogo.",
    "Greenhouse": "Permite plantar qualquer cultura em qualquer estação, o ano todo.",
}

TOOL_USE = {
    "Hoe": "Ara a terra para plantar e desenterra pontos de artefato.",
    "Pickaxe": "Quebra pedras, minérios e nós de gemas; abre caminho nas Minas.",
    "Axe": "Corta árvores, tocos e galhos; dá Madeira, Seiva e sementes.",
    "Watering Can": "Rega as culturas todos os dias (menos em dias de chuva).",
    "Trash Can": "Joga itens fora; cada melhoria devolve parte do valor descartado.",
    "Pan": "Peneira o rio e a praia em busca de minérios e gemas.",
    "Fishing Rod": "Pesca peixes, algas e baús do tesouro.",
    "Scythe": "Corta grama e mato sem gastar energia; com silo, rende feno.",
    "Golden Scythe": "Foice mais forte: colhe grama e causa mais dano nos monstros.",
    "Iridium Scythe": "Colhe culturas e grama em área; é a melhor foice do jogo.",
    "Milk Pail": "Ordenha vacas e cabras para obter leite.",
    "Shears": "Tosa ovelhas para obter lã.",
    "Heater": "Mantém os animais aquecidos no inverno e evita perder amizade.",
    "Auto-Grabber": "Recolhe leite, ovos, lã e outros produtos automaticamente.",
    "Auto-Petter": "Acaricia os animais automaticamente, mantendo a amizade alta.",
    "Large Pack": "Aumenta a mochila para 24 espaços.",
    "Deluxe Pack": "Aumenta a mochila para 36 espaços.",
}

FESTIVAL_USE = {
    "Egg Festival": "Compre Sementes de Morango (só aparecem aqui) e participe do concurso de ovos.",
    "Desert Festival": "Corridas de ganso, missões e lojas exclusivas no Deserto Calico.",
    "Flower Dance": "Dance com um morador; é preciso ter pelo menos 4 corações com ele.",
    "Luau": "Leve um bom ingrediente para a sopa: todos os moradores ganham amizade.",
    "Trout Derby": "Pesque trutas para ganhar fichas e trocar por prêmios.",
    "Dance of the Moonlight Jellies": "Evento só de assistir, no fim do verão; ótimo para relaxar.",
    "Stardew Valley Fair": "Exiba itens na barraca, ganhe fichas e troque por prêmios raros.",
    "Spirit's Eve": "Labirinto, doces e itens exclusivos; compre abóboras e decorações.",
    "Festival of Ice": "Concurso de pesca no gelo e itens de inverno.",
    "SquidFest": "Pesque lulas para ganhar fichas e prêmios.",
    "Night Market": "Lojas raras na praia: sereia, pinturas, decorações e peixes exclusivos.",
    "Feast of the Winter Star": "Amigo secreto: dê um presente e receba outro no dia 25.",
}

SKILL_USE = {
    "Farming": "Cada nível libera receitas e melhora a qualidade da colheita. No nível 5 e no 10 você escolhe uma profissão.",
    "Mining": "Cada nível aumenta a resistência e libera receitas. No nível 5 e no 10 você escolhe uma profissão.",
    "Foraging": "Aumenta a qualidade dos coletáveis e a chance de itens raros; libera receitas.",
    "Fishing": "Melhora a barra de pesca e a qualidade do peixe; libera receitas e anzóis.",
    "Combat": "Aumenta vida e dano; libera receitas de anéis e armas.",
}

TREE_USE = {
    "Oak Tree": "Com Torneirinha dá Resina de Carvalho (150 g a cada 7–8 dias), usada para fazer o Barril — que transforma fruta em vinho e vegetal em suco. Ao cortar rende Madeira, Seiva e Bolota.",
    "Maple Tree": "Com Torneirinha dá Xarope de Bordo (200 g a cada 9 dias), usado no Apiário (mel) e em receitas. Ao cortar rende Madeira, Seiva e Semente de bordo.",
    "Pine Tree": "Com Torneirinha dá Alcatrão de Pinho (100 g a cada 5–6 dias), usado no Tear, no Solo Foliar, no Totem de Chuva e no pacote Recursos Exóticos. Ao cortar rende Madeira, Seiva e Pinha — a pinha replanta de graça.",
    "Mahogany Tree": "Com Torneirinha dá Seiva (2 g por dia). Ao cortar rende 8–13 Madeiras de Lei e Sementes de mogno; é a melhor fonte renovável de Madeira de Lei para construções e melhorias.",
    "Mushroom Tree": "Com Torneirinha dá Cogumelos comuns, vermelhos e roxos — ótimos para comer, cozinhar e completar pacotes. Ao cortar também rende cogumelos. Não solta sementes ao sacudir.",
    "Mystic Tree": "Com Torneirinha dá Xarope Místico (1.000 g a cada 7 dias), a maior renda passiva entre as árvores. Ao cortar rende Madeira de Lei. A semente é liberada pela maestria de Coleta.",
    "Fiddlehead Stalk": "Na verdade é uma samambaia gigante: dá Samambaia comestível, usada em receitas e no pacote de Coleta. Com Torneirinha também produz Samambaia.",
    "Palm Tree": "Não aceita Torneirinha. Ao sacudir ou cortar dá Madeira, Coco e, na Ilha Gengibre, Coco Dourado — usados em receitas e trocas.",
}


# ---------------------------------------------------------------- contexto
class Ctx:
    def __init__(self):
        self.price = {}
        self.energy = {}
        self.artisan = {}
        self.craft = {}
        self.cook = {}
        self.bundle = {}
        self.loved = {}
        self.liked = {}
        self.animals = {}
        self.crops = {}
        self.fish = {}
        self.trees = {}
        self._build()

    def _put(self, name, value):
        if name and value is not None:
            self.price.setdefault(name, value)

    def _build(self):
        crops = load("crops")
        for c in crops:
            self.crops[c["name"]] = c
            self._put(c["name"], c.get("cropSellPrice"))
            if c.get("energyHealth"):
                self.energy[c["name"]] = c["energyHealth"]
            self.artisan[c["name"]] = c.get("artisanUses") or {}

        for f in load("forageables"):
            self._put(f["name"], f.get("sellPrice"))
            if f.get("energyHealth"):
                self.energy[f["name"]] = f["energyHealth"]
            self.artisan[f["name"]] = f.get("artisanUses") or {}

        for f in load("fish"):
            self.fish[f["name"]] = f
            self._put(f["name"], f.get("sellPrice"))
            if f.get("energyHealth"):
                self.energy[f["name"]] = f["energyHealth"]

        for m in load("minerals"):
            self._put(m["name"], m.get("sellPrice"))
        for a in load("artifacts"):
            self._put(a["name"], a.get("sellPrice"))
        for c in load("cooking"):
            self._put(c["name"], c.get("sellPrice"))
            if c.get("energyHealth"):
                self.energy[c["name"]] = c["energyHealth"]

        for t in load("trees"):
            self.trees[t["name"]] = t
            produce = t.get("produce") or {}
            self._put(produce.get("name"), produce.get("sellPrice"))
            if produce.get("energyHealth"):
                self.energy[produce["name"]] = produce["energyHealth"]
            self.artisan[produce.get("name", "")] = produce.get("artisanUses") or {}
            tap = t.get("tapper") or {}
            self._put(tap.get("name"), tap.get("sellPrice"))
            if tap.get("energyHealth"):
                self.energy[tap["name"]] = tap["energyHealth"]

        for a in load("animals"):
            if a.get("type") == "farm-animal":
                self.animals[a["name"]] = a
                self._put(a["name"], a.get("sellPrice"))
                for p in (a.get("produce"), a.get("deluxeProduce")):
                    if p:
                        self._put(p.get("name"), p.get("sellPrice"))

        for b in load("bundles"):
            pt = BUNDLE_PT.get(b["name"])
            if not pt:
                continue
            for item in b.get("items", []):
                self.bundle.setdefault(item["name"], []).append(pt)

        for r in load("crafting"):
            out = r.get("output", {}).get("name") or r.get("name")
            for ing in r.get("ingredients", []):
                self.craft.setdefault(ing["name"], []).append(out)

        for r in load("cooking"):
            for ing in r.get("ingredients", []):
                self.cook.setdefault(ing["name"], []).append(r["name"])

        for v in load("villagers"):
            for n in v.get("loves", []):
                self.loved.setdefault(n, []).append(v["name"])
            for n in v.get("likes", []):
                self.liked.setdefault(n, []).append(v["name"])


# ---------------------------------------------------------------- textos
def sell_text(price):
    return f"Vende por {gold(price)}" if price else ""


def eat_text(eh):
    if not eh:
        return ""
    energy = eh.get("energy") or 0
    health = eh.get("health") or 0
    if eh.get("poison"):
        return f"Comer cru faz mal ({energy} de energia)"
    if energy > 0 or health > 0:
        return f"Comer: +{energy} energia / +{health} vida"
    return ""


def artisan_text(uses):
    parts = []
    if uses.get("wine"):
        parts.append("No Barril vira Vinho (3× o preço base)")
    if uses.get("juice"):
        parts.append("No Barril vira Suco (2,25× o preço base)")
    if uses.get("jelly"):
        parts.append("Na Jarra de Conserva vira Geleia (50 g + 2× o preço)")
    if uses.get("pickles"):
        parts.append("Na Jarra de Conserva vira Picles (50 g + 2× o preço)")
    if uses.get("driedFruit"):
        parts.append("No Desidratador vira Fruta seca")
    if uses.get("driedMushrooms"):
        parts.append("No Desidratador vira Cogumelo desidratado")
    if uses.get("honey"):
        parts.append("Perto do Apiário muda o tipo de mel")
    return " • ".join(parts)


def bundle_text(ctx, en, limit=2):
    lst = ctx.bundle.get(en, [])
    if not lst:
        return ""
    uniq = []
    for x in lst:
        if x.startswith("Pacote "):
            x = x[len("Pacote "):]
        if x not in uniq:
            uniq.append(x)
    return "Entra no pacote " + names(uniq, limit)


def gift_text(ctx, en):
    loved = ctx.loved.get(en, [])
    if loved:
        return "Presente amado por " + names(loved, 3)
    liked = ctx.liked.get(en, [])
    if liked:
        return "Presente que agrada " + names(liked, 3)
    return ""


def craft_text(ctx, en):
    lst = ctx.craft.get(en, [])
    return "Usado para fabricar " + names(lst, 3) if lst else ""


def cook_text(ctx, en):
    lst = ctx.cook.get(en, [])
    return "Usado na receita " + names(lst, 3) if lst else ""


def _join(parts):
    return " • ".join(p for p in parts if p)


def utility_for(e, ctx):
    en = e["en"]
    cat = e["cat"]
    price = ctx.price.get(en)
    eh = ctx.energy.get(en)
    parts = []

    if cat == "arvores":
        t = ctx.trees.get(en, {})
        if t.get("type") == "fruit-tree":
            produce = t.get("produce") or {}
            fruit = tr(produce.get("name", ""))
            p = produce.get("sellPrice")
            days = "1 fruta por dia na estação"
            parts.append(
                f"Plante a muda, espere {t.get('daysToMature', 28)} dias e colha {days}. "
                f"Cada {fruit.lower()} vende por {gold(p)} e pode virar Vinho (3×), Geleia (50 g + 2×) ou Fruta seca no Desidratador."
                if p else f"Plante a muda e colha {fruit.lower()} todos os dias na estação."
            )
            parts.append("Não precisa regar depois de adulta e ocupa só 1 tile; deixe 3×3 livre para crescer.")
        else:
            parts.append(TREE_USE.get(en, "Árvore do jogo."))
            tap = t.get("tapper") or {}
            if tap and en not in TREE_USE:
                parts.append(f"Produto da torneirinha: {tr(tap['name'])} ({gold(tap['sellPrice'])}).")
        parts.append(eat_text(eh))
        parts.append(craft_text(ctx, en))
        parts.append(bundle_text(ctx, en))
        parts.append(gift_text(ctx, en))
        return _join(parts)

    if cat == "culturas":
        c = ctx.crops.get(en, {})
        parts.append(eat_text(eh))
        parts.append(sell_text(price))
        parts.append(artisan_text(ctx.artisan.get(en, {})))
        if c.get("giant"):
            parts.append("Pode virar cultura gigante se 3×3 plantas iguais estiverem maduras")
        if c.get("trellis"):
            parts.append("Precisa de treliça (não dá para atravessar o canteiro)")
        parts.append(cook_text(ctx, en))
        parts.append(bundle_text(ctx, en))
        parts.append(gift_text(ctx, en))
        return _join(parts)

    if cat == "coletaveis":
        parts.append(eat_text(eh))
        parts.append(sell_text(price))
        parts.append(artisan_text(ctx.artisan.get(en, {})))
        parts.append(cook_text(ctx, en))
        parts.append(bundle_text(ctx, en))
        parts.append(gift_text(ctx, en))
        if not parts:
            parts.append("Coletável sazonal: venda, coma ou guarde para pacotes e presentes.")
        return _join(parts)

    if cat == "peixes":
        f = ctx.fish.get(en, {})
        parts.append(eat_text(eh))
        parts.append(sell_text(price))
        if f.get("canSmoke"):
            parts.append("No Defumador vira Peixe defumado (2× o preço)")
        if f.get("roe"):
            parts.append("No Lago de peixes produz Ova; a Ova maturada vale o dobro")
        used = f.get("usedIn", [])
        dishes = [x for x in used if "Bundle" not in x]
        bundles = [BUNDLE_PT.get(x, x.replace(" Bundle", "")).removeprefix("Pacote ") for x in used if "Bundle" in x]
        if dishes:
            parts.append("Usado em " + names(dishes, 3))
        if bundles:
            parts.append("Entra no pacote " + names(bundles, 2))
        parts.append(gift_text(ctx, en))
        return _join(parts)

    if cat == "minerais":
        kind = next((r[1] for r in e.get("fields", []) if r[0] == "Tipo"), "")
        parts.append(sell_text(price))
        if kind in ("Mineral", "Gema"):
            parts.append("Doe ao museu para completar a coleção")
        elif kind == "Geodo":
            parts.append("Leve ao ferreiro para abrir e revelar minerais ou artefatos")
        elif kind == "Veio de pedra":
            item = e["pt"].replace("Veio de ", "").replace("Veio do ", "").replace("Veio ", "").strip()
            if en == "Rock":
                parts.append("Quebre para obter Pedra, usada em construções e artesanato")
            elif item and item != "pedra":
                parts.append(f"Quebre para obter {item}; venda o material ou use no artesanato")
            else:
                parts.append("Quebre para obter pedras e minérios")
        parts.append(craft_text(ctx, en))
        parts.append(bundle_text(ctx, en))
        parts.append(gift_text(ctx, en))
        if not parts:
            parts.append("Minere ou quebre para coletar e vender")
        return _join(parts)

    if cat == "culinaria":
        parts.append(eat_text(eh))
        parts.append(sell_text(price))
        parts.append(gift_text(ctx, en))
        parts.append("Coma antes de minerar ou pescar para ganhar energia e bônus")
        return _join(parts)

    if cat == "artefatos":
        parts.append(sell_text(price))
        parts.append("Doe ao museu para completar a coleção e liberar recompensas")
        parts.append("Pode aparecer em pedidos e receitas de alfaiataria")
        return _join(parts)

    if cat == "animais":
        a = ctx.animals.get(en)
        if not a:
            alias = {
                "Chicken": ["White Chicken", "Brown Chicken", "Blue Chicken", "Void Chicken", "Golden Chicken"],
                "Cow": ["White Cow", "Brown Cow"],
            }.get(en, [])
            a = next((ctx.animals[x] for x in alias if x in ctx.animals), None)
        if a:
            prod = a.get("produce") or {}
            deluxe = a.get("deluxeProduce") or {}
            parts.append(f"Produz {tr(prod.get('name', ''))} ({gold(prod.get('sellPrice'))})" +
                         (f" e, às vezes, {tr(deluxe.get('name', ''))} ({gold(deluxe.get('sellPrice'))})" if deluxe else ""))
            parts.append(animal_product_use(en, a))
            days = a.get("daysToProduce") or 1
            if prod.get("sellPrice") and days:
                parts.append(f"Rende cerca de {gold(round(prod['sellPrice'] / days))} por dia (produto base)")
            parts.append(sell_text(a.get("sellPrice")))
        elif en == "Horse":
            parts.append("Montaria: deixa você andar mais rápido pelo mapa. Não precisa de comida nem produz nada.")
        else:
            parts.append("Animal da fazenda: cuide bem para manter a amizade e a produção.")
        return _join(parts)

    if cat == "construcoes":
        return BUILDING_USE.get(en, "Construção da fazenda: amplia espaço, produção ou utilidades.")

    if cat == "ferramentas":
        return TOOL_USE.get(en, "Ferramenta de uso diário na fazenda.")

    if cat == "festivais":
        return FESTIVAL_USE.get(en, "Evento sazonal: participe para ganhar amizade, itens e prêmios.")

    if cat == "habilidades":
        return SKILL_USE.get(en, "Habilidade que sobe com o uso e libera receitas e profissões.")

    if cat == "aldeoes":
        return ("Converse todo dia e dê presentes amados, principalmente no aniversário. "
                "Mais corações liberam receitas, eventos e, se for casável, o casamento.")

    if cat == "pacotes":
        reward = next((r[1] for r in e.get("fields", []) if r[0] == "Recompensa do pacote"), "")
        return (f"Complete entregando os itens do checklist e receba {reward}." if reward
                else "Complete entregando os itens do checklist para avançar no Centro Comunitário.")

    if cat == "monstros":
        return ("Derrote para ganhar XP de Combate e coletar os itens que solta; "
                "muitos contam para as metas de caça do Clube dos Aventureiros.")

    return ""


def animal_product_use(en, a):
    prod = (a.get("produce") or {}).get("name", "")
    if en.startswith("Chicken") or prod in ("Egg", "Brown Egg", "Void Egg", "Golden Egg"):
        return "O ovo vira Maionese na Máquina de Maionese (vale mais que o ovo cru)"
    if en == "Cow":
        return "O leite vira Queijo na Prensa de Queijo (vale mais que o leite cru)"
    if en == "Goat":
        return "O leite de cabra vira Queijo de cabra na Prensa"
    if en in ("Sheep", "Rabbit"):
        return "A lã vira Tecido no Tear" if prod == "Wool" else "O pé de coelho é um dos presentes mais amados do jogo"
    if en == "Pig":
        return "As trufas viram Óleo de trufa no Gerador de Óleo (mais lucro ainda)"
    if en == "Duck":
        return "Os ovos servem para maionese e receitas; as penas valem bem e são usadas em artesanato"
    if en == "Dinosaur":
        return "O ovo de dinossauro pode chocar outro dinossauro na incubadora; também vale bem"
    if en == "Ostrich":
        return "O ovo de avestruz é usado em receitas e vale bem"
    return ""


# ---------------------------------------------------------------- aplicação
def _insert_utility(e, text):
    if not text:
        return
    fields = e.setdefault("fields", [])
    if any(row[0] == "Utilidade" for row in fields):
        return
    fields.insert(0, ["Utilidade", text])


def _has_price(e):
    for row in e.get("fields", []):
        label = row[0].lower()
        if "preço" in label or "preco" in label:
            return True
    return False


def enrich(entries):
    ctx = Ctx()
    for cat, items in entries.items():
        if cat == "guia":
            continue
        for e in items:
            _insert_utility(e, utility_for(e, ctx))

            en = e["en"]
            price = ctx.price.get(en)
            fields = e.setdefault("fields", [])

            if cat == "arvores":
                t = ctx.trees.get(en, {})
                if t.get("type") == "fruit-tree":
                    produce = t.get("produce") or {}
                    if produce.get("sellPrice") and not any(r[0] == "Preço de venda (fruta)" for r in fields):
                        fields.append(["Preço de venda (fruta)", gold(produce["sellPrice"])])
                tap = t.get("tapper") or {}
                if tap.get("sellPrice") and not any(r[0] == "Preço de venda (torneirinha)" for r in fields):
                    if en == "Mushroom Tree":
                        fields.append(["Preço de venda (torneirinha)", "40 g (comum), 75 g (vermelho) ou 250 g (roxo)"])
                    else:
                        fields.append(["Preço de venda (torneirinha)", gold(tap["sellPrice"])])
                if en == "Mushroom Tree":
                    for row in fields:
                        if row[0] == "Com torneira":
                            row[1] = "Cogumelo comum (40 g), vermelho (75 g) e roxo (250 g)"
                if en == "Palm Tree" and not any(r[0] == "Preço de venda (coco)" for r in fields):
                    fields.append(["Preço de venda (coco)", "100 g (Coco); o Coco Dourado é aberto no ferreiro"])

            elif cat == "animais":
                a = ctx.animals.get(en)
                if not a:
                    alias = {
                        "Chicken": ["White Chicken", "Brown Chicken", "Blue Chicken", "Void Chicken", "Golden Chicken"],
                        "Cow": ["White Cow", "Brown Cow"],
                    }.get(en, [])
                    a = next((ctx.animals[x] for x in alias if x in ctx.animals), None)
                if a and a.get("sellPrice") and not any(r[0] == "Preço de venda (animal)" for r in fields):
                    fields.append(["Preço de venda (animal)", gold(a["sellPrice"])])
                if a:
                    prod = a.get("produce") or {}
                    deluxe = a.get("deluxeProduce") or {}
                    if prod.get("name") and not any(r[0] == "Produção" for r in fields):
                        days = a.get("daysToProduce") or 1
                        when = "todos os dias" if days == 1 else f"a cada {days} dias"
                        txt = f"{tr(prod['name'])} ({gold(prod.get('sellPrice'))}) {when}"
                        if deluxe.get("name"):
                            txt += f"; às vezes {tr(deluxe['name'])} ({gold(deluxe.get('sellPrice'))})"
                        fields.append(["Produção", txt])

            elif price and not _has_price(e):
                fields.insert(0, ["Preço de venda", gold(price)])
