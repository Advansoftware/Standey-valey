# -*- coding: utf-8 -*-
"""Dados-base do guia (peixes, culturas, moradores, festivais, pacotes, etc.).

Tudo em português do Brasil. Os dados numéricos vêm da Stardew Valley Wiki
(CC BY-NC-SA 3.0). Nomes em PT-BR marcados como '' caem para o nome em inglês
e são corrigidos automaticamente pelo scraper (tools/scrape_wiki.py), que lê os
links de idioma da própria wiki.
"""

ESTACOES = ["Primavera", "Verão", "Outono", "Inverno"]

# ---------------------------------------------------------------- PEIXES
# (en, pt, local, estações, horário, clima, dificuldade, preço, emoji)
Q = "Qualquer"
FISH = [
    ("Pufferfish", "Baiacu", "Oceano; oceanos da Ilha Gengibre", "Verão (todas na Ilha Gengibre)", "12h–16h", "Ensolarado", 80, 200, "🐡"),
    ("Anchovy", "Anchova", "Oceano", "Primavera, Outono", "Qualquer hora", Q, 30, 30, "🐟"),
    ("Tuna", "Atum", "Oceano; oceanos da Ilha Gengibre", "Verão, Inverno (todas na Ilha Gengibre)", "6h–19h", Q, 70, 100, "🐟"),
    ("Sardine", "Sardinha", "Oceano", "Primavera, Outono, Inverno", "6h–19h", Q, 30, 40, "🐟"),
    ("Bream", "Brema", "Rio da cidade; rio da floresta", "Todas", "18h–2h", Q, 35, 45, "🐟"),
    ("Largemouth Bass", "", "Lago da montanha", "Todas", "6h–19h", Q, 50, 100, "🐟"),
    ("Smallmouth Bass", "", "Rio da cidade; lagoa da floresta", "Primavera, Outono", "Qualquer hora", Q, 28, 50, "🐟"),
    ("Rainbow Trout", "", "Rio da cidade; rio da floresta; lago da montanha", "Verão", "6h–19h", "Ensolarado", 45, 65, "🐟"),
    ("Salmon", "Salmão", "Rio da cidade; rio da floresta; cachoeiras da floresta", "Outono", "6h–19h", Q, 50, 75, "🐟"),
    ("Walleye", "", "Rios; lagoa da floresta; lago da montanha", "Outono, Inverno (com Totem da Chuva)", "12h–2h", "Chuva", 45, 105, "🐟"),
    ("Perch", "Perca", "Rios; lagoa da floresta; lago da montanha", "Inverno", "Qualquer hora", Q, 35, 55, "🐟"),
    ("Carp", "Carpa", "Lago da montanha; Bosque Secreto; Esgoto; Covil dos Insetos Mutantes", "Todas", "Qualquer hora", Q, 15, 30, "🐟"),
    ("Catfish", "Bagre", "Rios; Bosque Secreto; Pântano da Bruxa", "Primavera, Outono (Primavera e Verão no Bosque Secreto)", "6h–0h", "Chuva", 75, 200, "🐟"),
    ("Pike", "Lúcio", "Rios; lagoa da floresta", "Verão, Inverno", "Qualquer hora", Q, 60, 100, "🐟"),
    ("Sunfish", "", "Rio da cidade; rio da floresta", "Primavera, Verão", "6h–19h", "Ensolarado ou com vento", 30, 30, "🐟"),
    ("Red Mullet", "", "Oceano", "Verão, Inverno", "6h–19h", Q, 55, 75, "🐟"),
    ("Herring", "Arenque", "Oceano", "Primavera, Inverno", "Qualquer hora", Q, 25, 30, "🐟"),
    ("Eel", "Enguia", "Oceano", "Primavera, Outono", "16h–2h", "Chuva", 70, 85, "🐍"),
    ("Octopus", "Polvo", "Oceano; oceanos da Ilha Gengibre", "Verão (todas na Ilha Gengibre)", "6h–13h", Q, 95, 150, "🐙"),
    ("Red Snapper", "", "Oceano", "Verão, Outono, Inverno (com Totem da Chuva)", "6h–19h", "Chuva", 40, 50, "🐟"),
    ("Squid", "Lula", "Oceano", "Inverno", "18h–2h", Q, 75, 80, "🦑"),
    ("Sea Cucumber", "Pepino-do-mar", "Oceano", "Outono, Inverno", "6h–19h", Q, 40, 75, "🐛"),
    ("Super Cucumber", "", "Oceano; oceanos da Ilha Gengibre", "Verão, Outono (todas na Ilha Gengibre)", "18h–2h", Q, 80, 250, "🐟"),
    ("Ghostfish", "", "Minas (andares 20 e 60); fantasmas", "Todas", "Qualquer hora", Q, 50, 45, "👻"),
    ("Stonefish", "", "Minas (andar 20)", "Todas", "Qualquer hora", Q, 65, 300, "🐟"),
    ("Ice Pip", "", "Minas (andar 60)", "Todas", "Qualquer hora", Q, 85, 500, "🐟"),
    ("Lava Eel", "", "Minas (andar 100); Caldeira do Vulcão", "Todas", "Qualquer hora", Q, 90, 700, "🐍"),
    ("Sandfish", "", "Deserto", "Todas", "6h–20h", Q, 65, 75, "🐟"),
    ("Scorpion Carp", "", "Deserto (exige nível 4 de Pesca)", "Todas", "6h–20h", Q, 90, 150, "🐟"),
    ("Flounder", "Linguado", "Oceano; oceanos da Ilha Gengibre", "Primavera, Verão (todas na Ilha Gengibre)", "6h–20h", Q, 50, 100, "🐟"),
    ("Midnight Carp", "", "Lagoa da floresta; lago da montanha; rios da Ilha Gengibre", "Outono, Inverno (todas na Ilha Gengibre)", "22h–2h", Q, 55, 150, "🐟"),
    ("Sturgeon", "Esturjão", "Lago da montanha", "Verão, Inverno", "6h–19h", Q, 78, 200, "🐟"),
    ("Tiger Trout", "", "Rio da cidade; rio da floresta", "Outono, Inverno", "6h–19h", Q, 60, 150, "🐟"),
    ("Bullhead", "", "Lago da montanha", "Todas", "Qualquer hora", Q, 46, 75, "🐟"),
    ("Tilapia", "Tilápia", "Oceano; rios da Ilha Gengibre", "Verão, Outono (todas na Ilha Gengibre)", "6h–14h", Q, 50, 75, "🐟"),
    ("Chub", "", "Rio da floresta; lago da montanha", "Todas", "Qualquer hora", Q, 35, 50, "🐟"),
    ("Dorado", "", "Rio da floresta", "Verão", "6h–19h", Q, 78, 100, "🐟"),
    ("Albacore", "", "Oceano", "Outono, Inverno", "6h–11h e 18h–2h", Q, 60, 75, "🐟"),
    ("Shad", "", "Rio da cidade; rio da floresta", "Primavera, Verão, Outono", "9h–2h", "Chuva", 45, 60, "🐟"),
    ("Lingcod", "", "Rios; lago da montanha", "Inverno", "Qualquer hora", Q, 85, 120, "🐟"),
    ("Halibut", "", "Oceano", "Primavera, Verão, Inverno", "6h–11h e 19h–2h", Q, 50, 80, "🐟"),
    ("Woodskip", "", "Bosque Secreto; fazenda da floresta", "Todas", "Qualquer hora", Q, 50, 75, "🐟"),
    ("Void Salmon", "", "Pântano da Bruxa", "Todas", "Qualquer hora", Q, 80, 150, "🐟"),
    ("Slimejack", "", "Covil dos Insetos Mutantes", "Todas", "Qualquer hora", Q, 55, 100, "🐟"),
    ("Stingray", "", "Enseada dos Piratas (Ilha Gengibre)", "Todas", "Qualquer hora", Q, 80, 180, "🐟"),
    ("Lionfish", "", "Oceanos da Ilha Gengibre", "Todas", "Qualquer hora", Q, 50, 100, "🐠"),
    ("Blue Discus", "", "Rios da Ilha Gengibre", "Todas", "Qualquer hora", Q, 60, 120, "🐠"),
    ("Goby", "", "Cachoeiras da floresta", "Todas", "Qualquer hora", Q, 55, 150, "🐟"),
]
FISH_NIGHT = [
    ("Midnight Squid", "", "Submarino do Mercado Noturno", "Inverno 15–17", "17h–2h", "—", 55, 100, "🦑"),
    ("Spook Fish", "", "Submarino do Mercado Noturno", "Inverno 15–17", "17h–2h", "—", 60, 220, "🐟"),
    ("Blobfish", "", "Submarino do Mercado Noturno", "Inverno 15–17", "17h–2h", "—", 75, 500, "🐟"),
]
FISH_LEGEND = [
    ("Crimsonfish", "", "Píer leste da Praia (exige nível 5 de Pesca)", "Verão", "Qualquer hora", Q, 95, 1500),
    ("Angler", "", "Cachoeira ao norte da JojaMart (exige nível 3)", "Outono", "Qualquer hora", Q, 85, 900),
    ("Legend", "", "Lago da montanha, perto do tronco (exige nível 10)", "Primavera", "Qualquer hora", "Chuva", 110, 5000),
    ("Glacierfish", "", "Sul da Ilha Flecha, Floresta Cindersap (exige nível 6)", "Inverno", "Qualquer hora", Q, 100, 1000),
    ("Mutant Carp", "", "Esgoto", "Todas", "Qualquer hora", Q, 80, 1000),
]
CRAB = [
    # en, pt, local, chance sem Marinheiro, com Marinheiro, preço, emoji
    ("Clam", "Amêijoa", "Oceano", "9%", "14%", 50, "🐚"),
    ("Lobster", "Lagosta", "Oceano", "4%", "14%", 120, "🦞"),
    ("Crayfish", "Lagostim", "Água doce", "21%", "33%", 75, "🦞"),
    ("Crab", "Caranguejo", "Oceano", "8%", "14%", 100, "🦀"),
    ("Cockle", "Berbigão", "Oceano", "12%", "14%", 50, "🐚"),
    ("Mussel", "Mexilhão", "Oceano", "10%", "14%", 30, "🐚"),
    ("Shrimp", "Camarão", "Oceano", "10%", "14%", 60, "🦐"),
    ("Snail", "Caracol", "Água doce", "20%", "33%", 65, "🐌"),
    ("Periwinkle", "", "Água doce", "21%", "33%", 20, "🐌"),
    ("Oyster", "Ostra", "Oceano", "10%", "14%", 40, "🦪"),
]

# ---------------------------------------------------------------- CULTURAS
# (en, pt, estações, semente, preço_semente(int|None), dias, rebrota(int|None), venda, rendimento, emoji, nota)
CROPS = [
    ("Parsnip", "Pastinaca", "Primavera", "Pierre", 20, 4, None, 35, 1, "🥕", "Ótima para o primeiro dia: você já começa com sementes."),
    ("Green Bean", "Vagem", "Primavera", "Pierre", 60, 10, 3, 40, 1, "🫛", "Cresce em treliça e rebrota a cada 3 dias."),
    ("Cauliflower", "Couve-flor", "Primavera", "Pierre", 80, 12, None, 175, 1, "🥦", "Pode virar cultura gigante e vale para o Centro Comunitário."),
    ("Potato", "Batata", "Primavera", "Pierre", 50, 6, None, 80, 1, "🥔", "Às vezes rende mais de uma unidade."),
    ("Garlic", "Alho", "Primavera", "Pierre (a partir do 2º ano)", 40, 4, None, 60, 1, "🧄", ""),
    ("Kale", "Couve", "Primavera", "Pierre", 70, 6, None, 110, 1, "🥬", "Boa para ganhar dinheiro cedo."),
    ("Rhubarb", "Ruibarbo", "Primavera", "Loja do Oásis (Deserto)", 100, 13, None, 220, 1, "🌿", ""),
    ("Strawberry", "Morango", "Primavera", "Festival do Ovo (Primavera 13)", 100, 8, 4, 120, 1, "🍓", "Compre bastante no Festival do Ovo: é o melhor lucro da primavera."),
    ("Tulip", "Tulipa", "Primavera", "Pierre", 20, 6, None, 30, 1, "🌷", ""),
    ("Blue Jazz", "Jazz-azul", "Primavera", "Pierre", 30, 7, None, 50, 1, "💠", ""),
    ("Coffee Bean", "Grão de café", "Primavera, Verão", "Carrinho Viajante", None, 10, 2, 15, 4, "☕", "Rende vários grãos e serve para fazer café."),
    ("Melon", "Melão", "Verão", "Pierre", 80, 12, None, 250, 1, "🍈", "Valioso e vira cultura gigante."),
    ("Tomato", "Tomate", "Verão", "Pierre", 50, 11, 4, 60, 1, "🍅", ""),
    ("Blueberry", "Mirtilo", "Verão", "Pierre", 80, 13, 4, 50, 3, "🫐", "Rende cerca de 3 frutas por colheita."),
    ("Hot Pepper", "Pimenta", "Verão", "Pierre", 40, 5, 3, 40, 1, "🌶️", ""),
    ("Radish", "Rabanete", "Verão", "Pierre", 40, 6, None, 90, 1, "🫚", ""),
    ("Red Cabbage", "Repolho-roxo", "Verão", "Pierre (a partir do 2º ano)", 100, 9, None, 260, 1, "🥬", ""),
    ("Starfruit", "Carambola", "Verão", "Loja do Oásis (Deserto)", 400, 13, None, 750, 1, "⭐", "Uma das melhores culturas de verão."),
    ("Corn", "Milho", "Verão, Outono", "Pierre", 150, 14, 4, 50, 1, "🌽", "Cresce em duas estações."),
    ("Wheat", "Trigo", "Verão, Outono", "Pierre", 10, 4, None, 25, 1, "🌾", "Barato e serve de ração para os animais."),
    ("Hops", "Lúpulo", "Verão", "Pierre", 60, 11, 1, 25, 1, "🌿", "Rebrota todo dia e vira cerveja em barris."),
    ("Poppy", "Papoula", "Verão", "Pierre", 100, 7, None, 140, 1, "🌺", ""),
    ("Summer Spangle", "", "Verão", "Pierre", 50, 8, None, 90, 1, "🌼", ""),
    ("Sunflower", "Girassol", "Verão, Outono", "Pierre", 200, 8, None, 80, 1, "🌻", "Também rende sementes."),
    ("Pumpkin", "Abóbora", "Outono", "Pierre", 100, 13, None, 320, 1, "🎃", "Valiosa e vira cultura gigante."),
    ("Eggplant", "Berinjela", "Outono", "Pierre", 20, 5, 5, 60, 1, "🍆", ""),
    ("Yam", "Inhame", "Outono", "Pierre", 60, 10, None, 160, 1, "🍠", ""),
    ("Bok Choy", "", "Outono", "Pierre", 50, 4, None, 80, 1, "🥬", ""),
    ("Artichoke", "Alcachofra", "Outono", "Pierre (a partir do 2º ano)", 30, 8, None, 160, 1, "🌿", ""),
    ("Beet", "Beterraba", "Outono", "Loja do Oásis (Deserto)", 20, 6, None, 100, 1, "🫜", ""),
    ("Amaranth", "Amaranto", "Outono", "Pierre", 70, 7, None, 150, 1, "🌾", ""),
    ("Cranberries", "Oxicoco", "Outono", "Pierre", 240, 7, 5, 75, 2, "🔴", "Rende 2 frutas por colheita."),
    ("Grape", "Uva", "Outono", "Pierre", 60, 10, 3, 80, 1, "🍇", "Cresce em treliça."),
    ("Fairy Rose", "Rosa-fada", "Outono", "Pierre", 200, 12, None, 290, 1, "🌹", ""),
    ("Powdermelon", "", "Inverno", "Sementes de Inverno (coletadas)", None, 7, None, 60, 1, "🍉", "Única cultura de inverno comum: plante em estufa ou use Sementes de Inverno."),
    ("Ancient Fruit", "Fruta ancestral", "Verão, Outono, Inverno (estufa: todas)", "Semente Ancestral", None, 28, 7, 550, 1, "🍇", "Rebrota e vira vinho valioso; ótima para a estufa."),
    ("Sweet Gem Berry", "", "Outono", "Semente Rara", None, 24, None, 3000, 1, "💎", "Semente rara do Carrinho Viajante."),
    ("Cactus Fruit", "Fruta de cacto", "Todas (interior/estufa)", "Loja do Oásis (Deserto)", 150, 12, 3, 75, 1, "🌵", ""),
    ("Pineapple", "Abacaxi", "Verão (Ilha Gengibre)", "Mercador da Ilha", None, 14, 7, 300, 1, "🍍", ""),
    ("Taro Root", "", "Verão (Ilha Gengibre)", "Mercador da Ilha", None, 10, None, 100, 1, "🥔", ""),
]

# ---------------------------------------------------------------- MORADORES
# (en, pt, aniv_estacao(0-3), aniv_dia, casavel, local, ama[], nota, emoji)
VILL = [
    ("Abigail", "Abigail", 2, 13, True, "Loja do Pierre (cidade)", ["Ametista", "Pudim de banana", "Torta de amora", "Bolo de chocolate", "Baiacu", "Abóbora", "Enguia apimentada"], "Gosta de aventura, minas e jogos.", "🧑‍🦰"),
    ("Alex", "Alex", 1, 13, True, "Casa da cidade, com George e Evelyn", ["Café da manhã completo", "Jantar de salmão"], "Atleta que sonha em virar profissional.", "🧑"),
    ("Elliott", "Elliott", 2, 5, True, "Cabana na praia", ["Bolinho de caranguejo", "Pena de pato", "Lagosta", "Romã", "Tinta de lula", "Sopa Tom Kha"], "Escritor que mora sozinho na praia.", "🧑‍🎤"),
    ("Emily", "Emily", 0, 27, True, "Willow Lane, na cidade", ["Ametista", "Água-marinha", "Tecido", "Esmeralda", "Jade", "Rubi", "Hambúrguer da sobrevivência", "Topázio", "Lã"], "Garçonete do Saloon; adora tecidos e gemas.", "👩"),
    ("Haley", "Haley", 0, 14, True, "Willow Lane, na cidade", ["Coco", "Salada de frutas", "Bolo rosa", "Girassol"], "Mora com a irmã Emily e gosta de moda e fotografia.", "👱‍♀️"),
    ("Harvey", "Harvey", 3, 14, True, "Clínica, na cidade", ["Café", "Picles", "Refeição super", "Óleo de trufa", "Vinho"], "O médico da cidade.", "👨‍⚕️"),
    ("Leah", "Leah", 3, 23, True, "Chalé na Floresta Cindersap", ["Queijo de cabra", "Muffin de semente de papoula", "Salada", "Refogado", "Trufa", "Mix de legumes", "Vinho"], "Artista que vive na floresta.", "👩‍🎨"),
    ("Maru", "Maru", 1, 10, True, "Oficina da Robin, nas montanhas", ["Bateria", "Couve-flor", "Couve-flor com queijo", "Diamante", "Barra de ouro", "Barra de irídio", "Torta de ruibarbo", "Morango"], "Filha da Robin, cientista e inventora.", "👩‍🔬"),
    ("Penny", "Penny", 2, 2, True, "Trailer, na cidade", ["Diamante", "Esmeralda", "Melão", "Papoula", "Muffin de semente de papoula", "Prato vermelho", "Prato de raízes", "Sandfish", "Sopa Tom Kha"], "Dá aulas para Jas e Vincent.", "👩‍🏫"),
    ("Sam", "Sam", 1, 17, True, "1 Willow Lane, na cidade", ["Fruta de cacto", "Barra de bordo", "Pizza", "Olho-de-tigre"], "Músico que toca em uma banda.", "🧑‍🎸"),
    ("Sebastian", "Sebastian", 3, 10, True, "Oficina da Robin, nas montanhas", ["Lágrima congelada", "Obsidiana", "Sopa de abóbora", "Sashimi", "Ovo do vazio"], "Programador que vive no porão.", "🧑‍💻"),
    ("Shane", "Shane", 0, 20, True, "Rancho da Marnie", ["Cerveja", "Pimenta", "Pimentas recheadas", "Pizza"], "Trabalha no rancho e cuida das galinhas.", "🧑‍🌾"),
    ("Caroline", "Caroline", 3, 7, False, "Loja do Pierre", ["Taco de peixe", "Chá verde", "Flor-Miçanga", "Curry tropical"], "Esposa do Pierre.", "👩"),
    ("Clint", "Clint", 3, 26, False, "Ferraria", ["Ametista", "Água-marinha", "Pasta de alcachofra", "Esmeralda", "Risoto de samambaia", "Barra de ouro", "Barra de irídio", "Jade", "Ômnigeodo", "Rubi", "Topázio"], "Ferreiro: melhora suas ferramentas e quebra geodos.", "🔨"),
    ("Demetrius", "Demetrius", 1, 19, False, "Oficina da Robin", ["Cozido de feijão", "Sorvete", "Pudim de arroz", "Morango"], "Cientista, marido da Robin.", "👨‍🔬"),
    ("Dwarf", "Anão", 1, 22, False, "Minas (precisa do Idioma Anão)", ["Ametista", "Água-marinha", "Esmeralda", "Jade", "Pedra-limão", "Ômnigeodo", "Rubi", "Topázio"], "Vende itens úteis para quem aprende o idioma anão.", "🧙"),
    ("Evelyn", "Evelyn", 3, 20, False, "Casa do Alex", ["Beterraba", "Bolo de chocolate", "Diamante", "Rosa-fada", "Recheio", "Tulipa"], "Avó do Alex.", "👵"),
    ("George", "George", 2, 24, False, "Casa do Alex", ["Cogumelo frito", "Alho-poró"], "Avô do Alex.", "👴"),
    ("Gus", "Gus", 1, 8, False, "Saloon da Estrela", ["Diamante", "Escargot", "Taco de peixe", "Laranja"], "Dono do Saloon, vende refeições e receitas.", "👨‍🍳"),
    ("Jas", "Jas", 1, 4, False, "Rancho da Marnie", ["Rosa-fada", "Bolo rosa", "Pudim de ameixa"], "Sobrinha da Marnie.", "👧"),
    ("Jodi", "Jodi", 2, 11, False, "1 Willow Lane", ["Bolo de chocolate", "Baixo crocante", "Diamante", "Berinjela à parmegiana", "Enguia frita", "Panquecas", "Torta de ruibarbo", "Mix de legumes"], "Mãe do Sam e do Vincent.", "👩"),
    ("Kent", "Kent", 0, 4, False, "1 Willow Lane (volta no 2º ano)", ["Risoto de samambaia", "Avelãs assadas"], "Pai do Sam, aparece a partir do segundo ano.", "🧑‍✈️"),
    ("Krobus", "Krobus", 3, 1, False, "Esgoto", ["Diamante", "Barra de irídio", "Abóbora", "Ovo do vazio", "Maionese do vazio", "Raiz-forte selvagem"], "Criatura sombria do esgoto que vende itens raros.", "👤"),
    ("Leo", "Leo", 1, 26, False, "Ilha Gengibre", ["Pena de pato", "Manga", "Ovo de avestruz", "Poi"], "Garoto da Ilha Gengibre.", "🧒"),
    ("Lewis", "Lewis", 0, 7, False, "Casa do prefeito", ["Bênção do outono", "Inhame glaceado", "Chá verde", "Pimenta", "Mix de legumes"], "Prefeito da cidade.", "👨‍💼"),
    ("Linus", "Linus", 3, 3, False, "Tenda nas montanhas", ["Torta de mirtilo", "Fruta de cacto", "Coco", "Prato do mar", "Inhame"], "Vive em uma tenda perto da mina.", "🧔"),
    ("Marnie", "Marnie", 2, 18, False, "Rancho da Marnie", ["Diamante", "Almoço do fazendeiro", "Bolo rosa", "Torta de abóbora"], "Vende animais, ração e feno.", "👩‍🌾"),
    ("Pam", "Pam", 0, 18, False, "Trailer, na cidade", ["Cerveja", "Fruta de cacto", "Inhame glaceado", "Hidromel", "Cerveja pale ale", "Pastinaca", "Sopa de pastinaca", "Piña colada"], "Dirige o ônibus para o deserto.", "👩"),
    ("Pierre", "Pierre", 0, 26, False, "Loja do Pierre", ["Lula frita"], "Dono da loja geral: sementes e mudas.", "🧑‍💼"),
    ("Robin", "Robin", 2, 21, False, "Oficina da Robin, nas montanhas", ["Queijo de cabra", "Pêssego", "Espaguete"], "Carpinteira: constrói e melhora a fazenda.", "👷‍♀️"),
    ("Sandy", "Sandy", 2, 15, False, "Oásis, no Deserto Calico", ["Açafrão", "Narciso", "Arroz-doce com manga", "Ervilha-de-cheiro"], "Dona da loja do Oásis.", "👩"),
    ("Vincent", "Vincent", 0, 10, False, "1 Willow Lane", ["Doce de oxicoco", "Uva", "Bolo rosa", "Caracol"], "Filho mais novo da Jodi.", "👦"),
    ("Willy", "Willy", 1, 24, False, "Loja de pesca, no cais", ["Bagre", "Diamante", "Barra de irídio", "Hidromel", "Polvo", "Abóbora", "Ouriço-do-mar", "Esturjão"], "Pescador: vende varas e iscas.", "🎣"),
    ("Wizard", "Mago", 3, 17, False, "Torre do Mago, na floresta", ["Cogumelo roxo", "Essência solar", "Super pepino", "Essência do vazio"], "Mago misterioso da floresta.", "🧙‍♂️"),
]

# ---------------------------------------------------------------- FESTIVAIS
# (en, pt, estação, dias[], horário, local, descrição, emoji)
FEST = [
    ("Egg Festival", "Festival do Ovo", 0, [13], "9h–14h", "Praça da cidade", "Participe da caça aos ovos. Aqui você compra Sementes de Morango, uma das melhores culturas da primavera.", "🥚"),
    ("Desert Festival", "Festival do Deserto", 0, [15, 16, 17], "2h–2h (3 dias)", "Deserto Calico", "Feira de três dias no deserto com barracas, desafios e a Loja dos Fósseis.", "🏜️"),
    ("Flower Dance", "Dança das Flores", 0, [24], "9h–14h", "Floresta Cindersap", "Dança tradicional da primavera; você pode convidar um morador para dançar.", "💐"),
    ("Luau", "Luau", 1, [11], "9h–14h", "Praia", "Contribua com um ingrediente para a sopa do governador. Escolha um item bom, porque isso afeta o resultado.", "🍲"),
    ("Trout Derby", "Torneio de Trutas", 1, [20, 21], "9h–15h", "Floresta Cindersap", "Competição de pesca de truta-arco-íris com prêmios.", "🎣"),
    ("Dance of the Moonlight Jellies", "Dança das Águas-vivas do Luar", 1, [28], "22h–0h", "Praia", "Evento noturno com as águas-vivas na praia.", "🪼"),
    ("Stardew Valley Fair", "Feira do Vale Stardew", 2, [16], "9h–15h", "Praça da cidade", "Monte uma exibição, jogue minijogos e ganhe fichas estelares para trocar por prêmios.", "🎡"),
    ("Spirit's Eve", "Noite dos Espíritos", 2, [27], "17h–0h", "Cidade", "Festival de Halloween com labirinto e abóbora dourada para quem explorar.", "🎃"),
    ("Festival of Ice", "Festival do Gelo", 3, [8], "9h–14h", "Floresta Cindersap", "Pesque no gelo e participe de desafios de inverno.", "🧊"),
    ("SquidFest", "Festival da Lula", 3, [12, 13], "6h–14h (2 dias)", "Praia", "Pesque lulas e ganhe prêmios exclusivos.", "🦑"),
    ("Night Market", "Mercado Noturno", 3, [15, 16, 17], "17h–2h (3 dias)", "Praia", "Mercado com barracas e um submarino para pescar peixes especiais.", "🌃"),
    ("Feast of the Winter Star", "Festa da Estrela de Inverno", 3, [25], "9h–14h", "Praça da cidade", "Festa de troca de presentes: você ganha um presente secreto de um morador.", "🎁"),
]

# ---------------------------------------------------------------- FORRAGEÁVEIS
# (en, pt, estação, onde, preço, emoji, nota)
FORAGE = [
    ("Wild Horseradish", "Raiz-forte selvagem", "Primavera", "Ao ar livre (cidade, floresta, praia)", 50, "🌱", "Entra no pacote Forrageio de Primavera."),
    ("Daffodil", "Narciso", "Primavera", "Ao ar livre", 30, "🌼", "Entra no pacote Forrageio de Primavera."),
    ("Leek", "Alho-poró", "Primavera", "Ao ar livre", 60, "🥬", "Entra no pacote Forrageio de Primavera."),
    ("Dandelion", "Dente-de-leão", "Primavera", "Ao ar livre", 40, "🌼", "Entra no pacote Forrageio de Primavera."),
    ("Grape", "Uva", "Verão", "Ao ar livre (praia, floresta)", 80, "🍇", "Entra no pacote Forrageio de Verão."),
    ("Spice Berry", "Baga-de-especiaria", "Verão", "Ao ar livre", 80, "🍒", "Entra no pacote Forrageio de Verão."),
    ("Sweet Pea", "Ervilha-de-cheiro", "Verão", "Ao ar livre", 50, "🌸", "Entra no pacote Forrageio de Verão."),
    ("Common Mushroom", "Cogumelo comum", "Outono", "Ao ar livre e na floresta", 40, "🍄", "Entra no pacote Forrageio de Outono."),
    ("Wild Plum", "Ameixa selvagem", "Outono", "Ao ar livre", 80, "🍑", "Entra no pacote Forrageio de Outono."),
    ("Hazelnut", "Avelã", "Outono", "Ao ar livre", 90, "🌰", "Entra no pacote Forrageio de Outono."),
    ("Blackberry", "Amora", "Outono", "Ao ar livre (veja a Temporada de Amora)", 20, "🫐", "Entra no pacote Forrageio de Outono."),
    ("Winter Root", "Raiz-de-inverno", "Inverno", "Escave com a enxada nos montinhos de terra", 70, "🌿", "Entra no pacote Forrageio de Inverno."),
    ("Crystal Fruit", "Fruta de cristal", "Inverno", "Ao ar livre", 150, "🔮", "Entra no pacote Forrageio de Inverno."),
    ("Snow Yam", "Inhame-de-neve", "Inverno", "Escave com a enxada nos montinhos de neve", 100, "🍠", "Entra no pacote Forrageio de Inverno."),
    ("Crocus", "Açafrão", "Inverno", "Ao ar livre", 60, "🌷", "Entra no pacote Forrageio de Inverno."),
    ("Salmonberry", "Amora-salmão", "Primavera (15 a 18)", "Arbustos ao ar livre", 5, "🫐", "Só aparece nesses dias; ótimo para ganhar energia e dinheiro."),
    ("Morel", "Morchela", "Primavera, Outono", "Bosque Secreto; floresta", 150, "🍄", "Entra no pacote Forrageio Exótico."),
    ("Chanterelle", "Cantarelo", "Outono", "Bosque Secreto; floresta", 160, "🍄", "Valioso."),
    ("Red Mushroom", "Cogumelo vermelho", "Verão, Outono", "Minas; Bosque Secreto", 75, "🍄", "Entra nos pacotes Forrageio Exótico e Tinturaria."),
    ("Purple Mushroom", "Cogumelo roxo", "Todas", "Minas (andares profundos)", 250, "🍄", "Entra nos pacotes Forrageio Exótico e Pesquisa de Campo."),
    ("Cave Carrot", "Cenoura-da-caverna", "Todas", "Minas", 25, "🥕", "Entra no pacote Forrageio Exótico."),
    ("Fiddlehead Fern", "Samambaia comestível", "Verão", "Bosque Secreto", 90, "🌿", "Entra no pacote do Chef."),
    ("Coconut", "Coco", "Todas", "Deserto Calico", 100, "🥥", "Entra no pacote Forrageio Exótico."),
]

# ---------------------------------------------------------------- HABILIDADES
SKILLS = [
    ("Farming", "Cultivo", "🌾", "Sobe ao plantar, colher e cuidar de animais.",
     "Você ganha XP plantando e colhendo. Subir de nível libera receitas de fabricação (como espantalhos, aspersores e Câmara de Sementes) e aumenta a qualidade das colheitas.",
     [("Nível 5", "Rancheiro: +20% de valor nos produtos animais."),
      ("Nível 5", "Cultivador: +10% de valor em todas as culturas."),
      ("Nível 10", "Mestre do galinheiro (de Rancheiro): galinheiro melhora a amizade com as aves."),
      ("Nível 10", "Pastor (de Rancheiro): mais amizade com animais do celeiro."),
      ("Nível 10", "Artesão (de Cultivador): +40% de valor em produtos artesanais."),
      ("Nível 10", "Agricultor (de Cultivador): culturas crescem 10% mais rápido.")]),
    ("Mining", "Mineração", "⛏️", "Sobe ao quebrar pedras e vencer monstros nas minas.",
     "Quebre pedras e minérios nas Minas e na Caverna da Caveira. Cada nível libera receitas como a Fornalha e bombas.",
     [("Nível 5", "Minerador: +1 de minério por veio."),
      ("Nível 5", "Geólogo: chance de gemas em dobro."),
      ("Nível 10", "Ferreiro (de Minerador): +50% de valor das barras."),
      ("Nível 10", "Garimpeiro (de Minerador): chance de pegar carvão em pedras."),
      ("Nível 10", "Escavador (de Geólogo): mais chance de gemas em geodos e pedras."),
      ("Nível 10", "Gemólogo (de Geólogo): +30% de valor das gemas.")]),
    ("Foraging", "Coleta", "🌳", "Sobe ao coletar itens e cortar árvores.",
     "Corte árvores e colete frutas selvagens. Libera receitas como o Kit de Seiva e armadilhas.",
     [("Nível 5", "Silvicultor: mais madeira ao cortar árvores."),
      ("Nível 5", "Coletor: chance de coletar o dobro."),
      ("Nível 10", "Lenhador (de Silvicultor): chance de madeira dura (hardwood) em árvores."),
      ("Nível 10", "Torneirinha (de Silvicultor): seiva de torneiras vale mais."),
      ("Nível 10", "Botanista (de Coletor): coletáveis sempre com qualidade alta."),
      ("Nível 10", "Rastreador (de Coletor): mostra onde estão os itens coletáveis.")]),
    ("Fishing", "Pesca", "🎣", "Sobe ao pescar.",
     "Comece com a Vara de Treino (barata) e vá evoluindo. Níveis mais altos tornam a barra de pesca maior e liberam peixes lendários.",
     [("Nível 5", "Pescador: +25% de valor nos peixes."),
      ("Nível 5", "Armadilheiro: vantagens no uso de armadilhas de caranguejo."),
      ("Nível 10", "Mestre pescador (de Pescador): +50% de valor nos peixes."),
      ("Nível 10", "Marinheiro (de Pescador): armadilhas só pegam peixes, sem lixo."),
      ("Nível 10", "Pirata (de Armadilheiro): mais chance de tesouros."),
      ("Nível 10", "Mestre da isca (de Armadilheiro): armadilhas de caranguejo não precisam de isca.")]),
    ("Combat", "Combate", "⚔️", "Sobe ao derrotar monstros.",
     "Derrote monstros nas Minas, na Caverna da Caveira e no Pântano. Cada nível aumenta sua vida máxima.",
     [("Nível 5", "Lutador: +10% de dano."),
      ("Nível 5", "Escoteiro: chance maior de crítico."),
      ("Nível 10", "Bárbaro (de Lutador): +15% de dano."),
      ("Nível 10", "Defensor (de Lutador): +25 de vida máxima."),
      ("Nível 10", "Acrobata (de Escoteiro): recarga de ferramentas menor."),
      ("Nível 10", "Salteador (de Escoteiro): crítico causa mais dano.")]),
]

# ---------------------------------------------------------------- ANIMAIS
# (en, pt, prédio, preço, produtos, nota, emoji)
ANIMALS = [
    ("Chicken", "Galinha", "Galinheiro", 800, "Ovo, Ovo grande", "A primeira escolha para começar: barata e rende ovos todo dia.", "🐔"),
    ("Duck", "Pato", "Galinheiro grande", 1200, "Ovo de pato, Pena de pato", "Produz a cada 2 dias; quanto mais feliz, mais penas.", "🦆"),
    ("Rabbit", "Coelho", "Galinheiro luxuoso", 8000, "Lã, Pé de coelho", "O pé de coelho é um dos presentes mais amados.", "🐇"),
    ("Dinosaur", "Dinossauro", "Galinheiro grande", None, "Ovo de dinossauro (a cada 7 dias)", "Choca de um Ovo de dinossauro na incubadora.", "🦖"),
    ("Cow", "Vaca", "Celeiro", 1500, "Leite, Leite grande", "Ordenhe todo dia com o balde de leite.", "🐄"),
    ("Goat", "Cabra", "Celeiro grande", 4000, "Leite de cabra, Leite de cabra grande", "Em geral produz a cada 2 dias.", "🐐"),
    ("Sheep", "Ovelha", "Celeiro luxuoso", 8000, "Lã", "A lã volta a crescer em poucos dias; use a tesoura.", "🐑"),
    ("Pig", "Porco", "Celeiro luxuoso", 16000, "Trufa", "Só procura trufas ao ar livre e não produz no inverno.", "🐖"),
    ("Ostrich", "Avestruz", "Celeiro", None, "Ovo de avestruz (a cada 7 dias)", "Não é comprada no rancho da Marnie.", "🦃"),
    ("Horse", "Cavalo", "Estábulo", None, "—", "Você usa como montaria; não precisa de comida.", "🐴"),
]

# ---------------------------------------------------------------- PACOTES
# sala -> [(pacote, itens[], qtd_necessária, recompensa)]
BUNDLES = {
    "Sala de Artesanato": [
        ("Forrageio de Primavera", ["Raiz-forte selvagem", "Narciso", "Alho-poró", "Dente-de-leão"], 4, "Sementes de Primavera ×30"),
        ("Forrageio de Verão", ["Uva", "Baga-de-especiaria", "Ervilha-de-cheiro"], 3, "Sementes de Verão ×30"),
        ("Forrageio de Outono", ["Cogumelo comum", "Ameixa selvagem", "Avelã", "Amora"], 4, "Sementes de Outono ×30"),
        ("Forrageio de Inverno", ["Raiz-de-inverno", "Fruta de cristal", "Inhame-de-neve", "Açafrão"], 4, "Sementes de Inverno ×30"),
        ("Construção", ["Madeira ×99", "Madeira ×99", "Pedra ×99", "Madeira dura ×10"], 4, "Forno de carvão"),
        ("Forrageio Exótico", ["Coco", "Fruta de cacto", "Cenoura-da-caverna", "Cogumelo vermelho", "Cogumelo roxo", "Xarope de bordo", "Resina de carvalho", "Piche de pinheiro", "Morchela"], 5, "Bênção do outono ×5"),
    ],
    "Despensa": [
        ("Culturas de Primavera", ["Pastinaca", "Vagem", "Couve-flor", "Batata"], 4, "Speed-Gro ×20"),
        ("Culturas de Verão", ["Tomate", "Pimenta", "Mirtilo", "Melão"], 4, "Aspersor de qualidade"),
        ("Culturas de Outono", ["Milho", "Berinjela", "Abóbora", "Inhame"], 4, "Colmeia"),
        ("Culturas de Qualidade", ["Pastinaca ★ ×5", "Melão ★ ×5", "Abóbora ★ ×5", "Milho ★ ×5"], 3, "Pote de conservas"),
        ("Animais", ["Leite grande", "Ovo grande (marrom)", "Ovo grande (branco)", "Leite de cabra grande", "Lã", "Ovo de pato"], 5, "Prensa de queijo"),
        ("Artesão", ["Óleo de trufa", "Tecido", "Queijo de cabra", "Queijo", "Mel", "Geleia", "Maçã", "Damasco", "Laranja", "Pêssego", "Romã", "Cereja"], 6, "Barril"),
    ],
    "Aquário": [
        ("Peixes de Rio", ["Sunfish", "Bagre", "Shad", "Tiger Trout"], 4, "Isca ×30"),
        ("Peixes de Lago", ["Largemouth Bass", "Carpa", "Bullhead", "Esturjão"], 4, "Isca giratória (Dressed Spinner)"),
        ("Peixes do Oceano", ["Sardinha", "Atum", "Red Snapper", "Tilápia"], 4, "Totem de Teleporte: Praia ×5"),
        ("Pesca Noturna", ["Walleye", "Brema", "Enguia"], 3, "Anel luminoso pequeno"),
        ("Peixes Especiais", ["Baiacu", "Ghostfish", "Sandfish", "Woodskip"], 4, "Prato do mar ×5"),
        ("Armadilha de Caranguejo", ["Lagosta", "Lagostim", "Caranguejo", "Berbigão", "Mexilhão", "Camarão", "Caracol", "Periwinkle", "Ostra", "Amêijoa"], 5, "Armadilha de caranguejo ×3"),
    ],
    "Sala da Caldeira": [
        ("Ferreiro", ["Barra de cobre", "Barra de ferro", "Barra de ouro"], 3, "Fornalha"),
        ("Geólogo", ["Quartzo", "Cristal da terra", "Lágrima congelada", "Quartzo de fogo"], 4, "Ômnigeodo"),
        ("Aventureiro", ["Gosma ×99", "Asa de morcego ×10", "Essência solar", "Essência do vazio"], 2, "Anel magnético pequeno"),
    ],
    "Quadro de Avisos": [
        ("Chef", ["Xarope de bordo", "Samambaia comestível", "Trufa", "Papoula", "Maki", "Ovo frito"], 6, "Bolo rosa ×3"),
        ("Tintureiro", ["Cogumelo vermelho", "Ouriço-do-mar", "Girassol", "Pena de pato", "Água-marinha", "Repolho-roxo"], 6, "Câmara de sementes"),
        ("Pesquisa de Campo", ["Cogumelo roxo", "Concha de náutilo", "Chub", "Geodo congelado"], 4, "Máquina de reciclagem"),
        ("Ração", ["Trigo ×10", "Feno ×10", "Maçã ×3"], 3, "Aquecedor"),
        ("Encantador", ["Resina de carvalho", "Vinho", "Pé de coelho", "Romã"], 4, "Painel solar ×2"),
    ],
    "Cofre": [
        ("2.500 ouro", ["2.500 g"], 1, "Bolo de chocolate ×3"),
        ("5.000 ouro", ["5.000 g"], 1, "Fertilizante de qualidade ×30"),
        ("10.000 ouro", ["10.000 g"], 1, "Para-raios"),
        ("25.000 ouro", ["25.000 g"], 1, "Cristalário"),
    ],
}
ROOM_REWARD = {
    "Sala de Artesanato": "Ponte da pedreira consertada",
    "Despensa": "Estufa liberada",
    "Aquário": "Pedra brilhante removida (acesso ao garimpo)",
    "Sala da Caldeira": "Carrinhos de mina liberados",
    "Quadro de Avisos": "Confira a recompensa no jogo",
    "Cofre": "Ônibus para o Deserto consertado",
}
ROOM_EMOJI = {"Sala de Artesanato": "🧵", "Despensa": "🥫", "Aquário": "🐠", "Sala da Caldeira": "🔥", "Quadro de Avisos": "📌", "Cofre": "💰"}
