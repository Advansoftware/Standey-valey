import 'package:flutter/material.dart';

/// Região do mapa, usada para agrupar a lista e colorir os pinos.
enum MapRegion { norte, centro, sul, fora }

const mapRegionNames = {
  MapRegion.norte: 'Norte',
  MapRegion.centro: 'Centro',
  MapRegion.sul: 'Sul',
  MapRegion.fora: 'Fora do vale',
};

Color mapRegionColor(MapRegion r) => switch (r) {
      MapRegion.norte => const Color(0xFF3F7FBF),
      MapRegion.centro => const Color(0xFF2E7D32),
      MapRegion.sul => const Color(0xFFF57C00),
      MapRegion.fora => const Color(0xFF8E24AA),
    };

/// Um lugar do vale. As posições [x] e [y] são frações da imagem do mapa
/// (0 = esquerda/topo, 1 = direita/baixo). Sem posição, o lugar só aparece
/// na lista (é o caso da Ilha Gengibre e do Cume).
class MapPlace {
  final String name;
  final String emoji;
  final MapRegion region;
  final bool beginner;
  final double? x;
  final double? y;
  final String tagline;
  final String what;
  final String how;
  final String tip;
  final String guideId;
  final String wiki;

  const MapPlace({
    required this.name,
    required this.emoji,
    required this.region,
    required this.beginner,
    this.x,
    this.y,
    required this.tagline,
    required this.what,
    required this.how,
    required this.tip,
    this.guideId = '',
    this.wiki = '',
  });
}

/// Locais na ordem em que aparecem no mapa e na lista.
const mapPlaces = <MapPlace>[
  MapPlace(
    name: 'Sua fazenda',
    emoji: '🏡',
    region: MapRegion.centro,
    beginner: true,
    x: 0.34,
    y: 0.42,
    tagline: 'Sua base e onde tudo começa',
    what: 'Casa, caixa de entregas, lavouras, construções e a Caverna da fazenda.',
    how: 'Você começa aqui. O portão de saída fica no canto sudeste e leva ao Ponto de Ônibus.',
    tip: 'No começo, plante perto de casa: você economiza tempo e energia.',
    guideId: 'guia_comeco',
    wiki: 'A_Fazenda',
  ),
  MapPlace(
    name: 'Vila Pelicanos',
    emoji: '🏘️',
    region: MapRegion.centro,
    beginner: true,
    x: 0.57,
    y: 0.46,
    tagline: 'Lojas, serviços e moradores',
    what: 'Armazém do Pierre, JojaMart, ferreiro, salão, Centro Comunitário, museu e praça.',
    how: 'Saia da fazenda pelo portão sudeste e siga para leste.',
    tip: 'O Pierre fecha às quartas; o Clint não trabalha às sextas depois que o Centro Comunitário é restaurado.',
    guideId: 'guia_comeco',
    wiki: 'Vila_Pelicanos',
  ),
  MapPlace(
    name: 'Ponto de Ônibus',
    emoji: '🚌',
    region: MapRegion.centro,
    beginner: true,
    x: 0.4,
    y: 0.32,
    tagline: 'A porta de entrada do vale',
    what: 'Onde você chega no início e de onde sai o ônibus para o Deserto de Calico.',
    how: 'Fica entre a fazenda e a cidade, na estrada principal.',
    tip: 'Se estiver perdido, volte para cá e siga a estrada: oeste é a fazenda, leste é a cidade.',
    wiki: 'Ponto de Ônibus',
  ),
  MapPlace(
    name: 'Montanha',
    emoji: '⛰️',
    region: MapRegion.norte,
    beginner: true,
    x: 0.68,
    y: 0.1,
    tagline: 'Minas, lago e casa da Robin',
    what: 'Minas, Lago da Montanha, Carpintaria da Robin, Guilda dos Aventureiros e acesso à Ferrovia.',
    how: 'Da Vila Pelicanos, siga para o norte.',
    tip: 'A pedra da ponte sai no dia 5 da Primavera e libera as Minas e a Guilda.',
    guideId: 'guia_minas',
    wiki: 'A_Montanha',
  ),
  MapPlace(
    name: 'Minas',
    emoji: '⛏️',
    region: MapRegion.norte,
    beginner: true,
    x: 0.56,
    y: 0.24,
    tagline: 'Mineração e combate',
    what: '119 andares com pedra, minérios, inimigos e a Caverna da Caveira depois.',
    how: 'A entrada fica na Montanha, ao norte da cidade.',
    tip: 'Desça 5 andares por dia e volte pelo elevador; leve comida e não fique até tarde.',
    guideId: 'guia_minas',
    wiki: 'As_Minas',
  ),
  MapPlace(
    name: 'Lago da Montanha',
    emoji: '🎣',
    region: MapRegion.norte,
    beginner: true,
    x: 0.71,
    y: 0.25,
    tagline: 'Pesca de água doce',
    what: 'Peixes de lago, alguns bem caros, e a paisagem mais tranquila do norte.',
    how: 'Fica no meio da Montanha, perto da casa da Robin.',
    tip: 'Pesque em horários diferentes: alguns peixes só aparecem à noite ou na chuva.',
    guideId: 'guia_pesca',
  ),
  MapPlace(
    name: 'Ferrovia',
    emoji: '🚂',
    region: MapRegion.norte,
    beginner: false,
    x: 0.84,
    y: 0.06,
    tagline: 'Trem e Spa',
    what: 'Trilhos, trem ocasional, Spa que recupera energia e o caminho para o Cume.',
    how: 'Siga para o norte da Montanha; a passagem abre no dia 3 do Verão com um terremoto.',
    tip: 'O Spa é de graça: entre, recupere a energia e depois vá minerar.',
    wiki: 'Ferrovia',
  ),
  MapPlace(
    name: 'Pedreira',
    emoji: '🪨',
    region: MapRegion.norte,
    beginner: false,
    x: 0.84,
    y: 0.23,
    tagline: 'Pedra e minérios',
    what: 'Muitas pedras, nós de minério e geodos de uma vez.',
    how: 'Atravesse a ponte a leste das Minas e da Guilda, liberada ao completar a Sala de Artesanato do Centro Comunitário (ou comprando o reparo na Joja).',
    tip: 'Vá com picareta melhorada e espaço na mochila; traga uma bomba para acelerar.',
    wiki: 'Pedreira',
  ),
  MapPlace(
    name: 'Floresta Cinzaseiva',
    emoji: '🌲',
    region: MapRegion.centro,
    beginner: true,
    x: 0.33,
    y: 0.68,
    tagline: 'Madeira, forrageio e o rancho da Marnie',
    what: 'Árvores, itens de coleta, Rancho da Marnie, Cabana da Leah, Torre do Mago e a entrada do Bosque Secreto.',
    how: 'Saia da fazenda pelo portão sul e siga para o sul/oeste.',
    tip: 'Corte só as árvores adultas e replante as sementes: a madeira não acaba.',
    guideId: 'guia_arvores',
    wiki: 'Floresta_Cinzaseiva',
  ),
  MapPlace(
    name: 'Bosque Secreto',
    emoji: '🍄',
    region: MapRegion.centro,
    beginner: false,
    x: 0.17,
    y: 0.62,
    tagline: 'Madeira de Lei e cogumelos',
    what: 'Tocos de Madeira de Lei, cogumelos, gosmas e peixes exclusivos.',
    how: 'No noroeste da Floresta Cinzaseiva; o tronco caído só sai com Machado de Aço.',
    tip: 'Os tocos voltam a crescer: passe aqui de vez em quando para juntar Madeira de Lei.',
    guideId: 'guia_arvores_cultivo',
    wiki: 'Bosque_Secreto',
  ),
  MapPlace(
    name: 'Praia',
    emoji: '🏖️',
    region: MapRegion.sul,
    beginner: true,
    x: 0.69,
    y: 0.83,
    tagline: 'Pesca, mar e Willy',
    what: 'Oceano, Peixaria do Willy, conchas, ouriços e o Velho Marinheiro em dias de chuva.',
    how: 'Da Vila Pelicanos, siga para o sul.',
    tip: 'Pesque no cais e procure conchas na areia; a ponte do leste pede 300 Madeiras para ser consertada.',
    guideId: 'guia_pesca',
    wiki: 'A_Praia',
  ),
  MapPlace(
    name: 'Deserto de Calico',
    emoji: '🌵',
    region: MapRegion.fora,
    beginner: false,
    x: 0.06,
    y: 0.10,
    tagline: 'Caverna da Caveira e comércio',
    what: 'Caverna da Caveira, Oásis, Comerciante do Deserto e areia.',
    how: 'Pegue o ônibus no Ponto de Ônibus; ele é liberado ao completar o Cofre do Centro Comunitário (ou comprar o reparo por 40.000 g na Joja).',
    tip: 'Não entre na Caverna da Caveira sem comida, bombas e escadas.',
    guideId: 'guia_minas',
    wiki: 'O_Deserto',
  ),
  MapPlace(
    name: 'Caverna da fazenda',
    emoji: '🦇',
    region: MapRegion.centro,
    beginner: true,
    tagline: 'Cogumelos ou morcegos',
    what: 'Uma escolha no começo: cogumelos todos os dias ou frutas de morcego de vez em quando.',
    how: 'Fica na área da sua fazenda, perto da casa.',
    tip: 'Cogumelos são mais previsíveis para comida e receitas; morcegos podem dar frutas para presentes.',
    wiki: 'A_Caverna',
  ),
  MapPlace(
    name: 'Esgotos',
    emoji: '🕳️',
    region: MapRegion.centro,
    beginner: false,
    tagline: 'Krobus e peixes raros',
    what: 'Loja do Krobus, peixes exclusivos e itens úteis.',
    how: 'Use a Chave Enferrujada (doação de 60 itens ao museu) na tampa perto da cidade ou na floresta.',
    tip: 'O Krobus vende um item diferente a cada dia; vale a visita semanal.',
  ),
  MapPlace(
    name: 'Ilha Gengibre',
    emoji: '🏝️',
    region: MapRegion.fora,
    beginner: false,
    tagline: 'Ilha tropical (conteúdo avançado)',
    what: 'Novas culturas, vulcão, caverna, bananas e Nozes Douradas.',
    how: 'Conserte o barco do Willy depois de completar o Centro Comunitário (ou o formulário da Joja).',
    tip: 'É conteúdo de fim de jogo; não precisa correr para chegar lá.',
    wiki: 'Ilha_Gengibre',
  ),
  MapPlace(
    name: 'Cume',
    emoji: '🏔️',
    region: MapRegion.fora,
    beginner: false,
    tagline: 'A vista do fim do jogo',
    what: 'Uma vista de todo o vale e a cena de perfeição.',
    how: 'Liberado ao atingir a perfeição (100%).',
    tip: 'É uma recompensa, não uma obrigação. Jogue no seu ritmo.',
  ),
];

/// Lugares que aparecem na imagem do mapa (os outros só na lista).
Iterable<MapPlace> get pinnedPlaces => mapPlaces.where((p) => p.x != null && p.y != null);
