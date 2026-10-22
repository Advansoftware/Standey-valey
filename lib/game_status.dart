import 'dart:math' as math;

import 'game_api.dart';
import 'map_data.dart';
import 'models.dart';
import 'repository.dart';
import 'search.dart';

/// Um conselho curto mostrado na tela de status.
enum StatusTipKind {
  quest,
  birthday,
  festival,
  weather,
  energy,
  health,
  season,
  inventory,
  relationship,
  achievement,
  skill,
  location,
  general,
}

class StatusTip {
  final String emoji;
  final String title;
  final String body;
  final StatusTipKind kind;
  final String? entryId;

  const StatusTip({
    required this.emoji,
    required this.title,
    required this.body,
    this.kind = StatusTipKind.general,
    this.entryId,
  });
}

class WeatherInfo {
  final String label;
  final String emoji;
  final String tip;

  const WeatherInfo({
    required this.label,
    required this.emoji,
    required this.tip,
  });
}

WeatherInfo weatherInfo(String raw) {
  final k = raw.toLowerCase();
  if (k.contains('green')) {
    return const WeatherInfo(
      label: 'Chuva verde',
      emoji: '🟢',
      tip:
          'Chuva verde hoje: colete musgo, sementes e fibras. As plantas ficam regadas.',
    );
  }
  if (k.contains('storm') || k.contains('thunder')) {
    return const WeatherInfo(
      label: 'Tempestade',
      emoji: '⛈️',
      tip:
          'Tempestade: os animais ficam assustados e há raios. Evite a praia e cuide da fazenda.',
    );
  }
  if (k.contains('rain')) {
    return const WeatherInfo(
      label: 'Chuva',
      emoji: '🌧️',
      tip:
          'Chovendo: as plantas já estão regadas. Bom dia para pescar ou minerar.',
    );
  }
  if (k.contains('snow')) {
    return const WeatherInfo(
      label: 'Neve',
      emoji: '❄️',
      tip:
          'Neve: nada cresce ao ar livre. Foque em minas, pesca, animais e amizades.',
    );
  }
  if (k.contains('wind')) {
    return const WeatherInfo(
      label: 'Vento',
      emoji: '🌬️',
      tip:
          'Dia de vento: aparecem folhas e sementes. Vale dar uma volta pela floresta.',
    );
  }
  if (k.contains('festival')) {
    return const WeatherInfo(
      label: 'Festival',
      emoji: '🎪',
      tip:
          'Hoje é dia de festival. Vá até o local e aproveite: as lojas podem fechar.',
    );
  }
  return const WeatherInfo(
    label: 'Sol',
    emoji: '☀️',
    tip:
        'Dia de sol: regue as plantas, cuide dos animais e aproveite para explorar.',
  );
}

String weekdayPt(String value) {
  switch (value.toLowerCase()) {
    case 'monday':
      return 'segunda';
    case 'tuesday':
      return 'terça';
    case 'wednesday':
      return 'quarta';
    case 'thursday':
      return 'quinta';
    case 'friday':
      return 'sexta';
    case 'saturday':
      return 'sábado';
    case 'sunday':
      return 'domingo';
    default:
      return value;
  }
}

String moneyLabel(int value) {
  final s = value.abs().toString();
  final b = StringBuffer();
  for (var i = 0; i < s.length; i++) {
    if (i > 0 && (s.length - i) % 3 == 0) b.write('.');
    b.write(s[i]);
  }
  return '${value < 0 ? '-' : ''}${b}g';
}

String luckLabel(ApiPlayer p) {
  if (p.dailyLuckFriendlyValue.trim().isNotEmpty) {
    return p.dailyLuckFriendlyValue;
  }
  final pct = (p.dailyLuck * 100);
  return '${pct >= 0 ? '+' : ''}${pct.toStringAsFixed(1)}%';
}

String luckPhrase(double luck) {
  if (luck >= 0.07) return 'Os espíritos estão muito felizes hoje.';
  if (luck >= 0.02) return 'A sorte está um pouco acima do normal.';
  if (luck <= -0.07) return 'Os espíritos estão bem irritados hoje.';
  if (luck <= -0.02) return 'A sorte está um pouco abaixo do normal.';
  return 'A sorte está neutra hoje.';
}

String seasonNameFor(int season) => season >= 0 && season < seasonNames.length
    ? seasonNames[season]
    : 'Primavera';

String seasonEmojiFor(int season) =>
    season >= 0 && season < seasonEmojis.length ? seasonEmojis[season] : '🌱';

String worldDateLabel(ApiWorld world) {
  final weekday = weekdayPt(world.dayOfWeek);
  final tail =
      weekday.isEmpty || weekday == world.dayOfWeek && world.dayOfWeek.isEmpty
      ? ''
      : ', $weekday';
  return '${seasonNameFor(world.season)} ${world.day}, Ano ${world.year}$tail';
}

const _skillNames = {
  'farming': ('Agricultura', '🌱', 'skills_farming.png'),
  'mining': ('Mineração', '⛏️', 'skills_mining.png'),
  'foraging': ('Coleta', '🌿', 'skills_foraging.png'),
  'fishing': ('Pesca', '🎣', 'skills_fishing.png'),
  'combat': ('Combate', '⚔️', 'skills_combat.png'),
};

String skillNamePt(ApiSkill skill) {
  final meta = _skillNames[skill.name.toLowerCase()];
  if (meta != null) return meta.$1;
  switch (skill.id) {
    case 0:
      return 'Agricultura';
    case 1:
      return 'Mineração';
    case 2:
      return 'Coleta';
    case 3:
      return 'Pesca';
    case 4:
      return 'Combate';
    default:
      return skill.name;
  }
}

String skillEmoji(ApiSkill skill) {
  final meta = _skillNames[skill.name.toLowerCase()];
  if (meta != null) return meta.$2;
  switch (skill.id) {
    case 0:
      return '🌱';
    case 1:
      return '⛏️';
    case 2:
      return '🌿';
    case 3:
      return '🎣';
    case 4:
      return '⚔️';
    default:
      return '✨';
  }
}

String? skillAsset(ApiSkill skill) {
  final meta = _skillNames[skill.name.toLowerCase()];
  if (meta != null) return meta.$3;
  switch (skill.id) {
    case 0:
      return 'skills_farming.png';
    case 1:
      return 'skills_mining.png';
    case 2:
      return 'skills_foraging.png';
    case 3:
      return 'skills_fishing.png';
    case 4:
      return 'skills_combat.png';
    default:
      return null;
  }
}

const _professionPt = {
  'rancher': 'Criador de gado',
  'tiller': 'Lavrador',
  'coopmaster': 'Mestre de galinheiros',
  'shepherder': 'Pastor',
  'artisan': 'Artesão',
  'agriculturist': 'Agrônomo',
  'miner': 'Mineiro',
  'geologist': 'Geólogo',
  'blacksmith': 'Ferreiro',
  'prospector': 'Garimpeiro',
  'excavator': 'Escavador',
  'gemologist': 'Gemólogo',
  'forester': 'Silvicultor',
  'gatherer': 'Coletor',
  'lumberjack': 'Lenhador',
  'tapper': 'Seringueiro',
  'botanist': 'Botânico',
  'tracker': 'Rastreador',
  'fisher': 'Pescador',
  'trapper': 'Armadilheiro',
  'angler': 'Pescador de anzol',
  'pirate': 'Pirata',
  'mariner': 'Marinheiro',
  'luremaster': 'Mestre de iscas',
  'fighter': 'Lutador',
  'scout': 'Batedor',
  'brute': 'Bruto',
  'defender': 'Defensor',
  'acrobat': 'Acrobata',
  'desperado': 'Desperado',
};

String professionNamePt(String name) =>
    _professionPt[name.toLowerCase()] ?? name;

/// Nome amigável do local interno da API, com o lugar correspondente no mapa.
class LocationInfo {
  final String displayName;
  final MapPlace? place;
  final String directions;
  final String tip;
  final String region;

  const LocationInfo({
    required this.displayName,
    this.place,
    required this.directions,
    required this.tip,
    required this.region,
  });

  double? get x => place?.x;
  double? get y => place?.y;
  String get emoji => place?.emoji ?? '📍';
  bool get hasPin => x != null && y != null;
}

const _placeByLocation = {
  'Farm': 'Sua fazenda',
  'FarmHouse': 'Sua fazenda',
  'Greenhouse': 'Sua fazenda',
  'Cellar': 'Sua fazenda',
  'Barn': 'Sua fazenda',
  'BigBarn': 'Sua fazenda',
  'DeluxeBarn': 'Sua fazenda',
  'Coop': 'Sua fazenda',
  'BigCoop': 'Sua fazenda',
  'DeluxeCoop': 'Sua fazenda',
  'Shed': 'Sua fazenda',
  'BigShed': 'Sua fazenda',
  'SlimeHutch': 'Sua fazenda',
  'Cabin': 'Sua fazenda',
  'FarmCave': 'Sua fazenda',
  'Backwoods': 'Sua fazenda',
  'Town': 'Vila Pelicanos',
  'SeedShop': 'Vila Pelicanos',
  'Saloon': 'Vila Pelicanos',
  'ManorHouse': 'Vila Pelicanos',
  'ArchaeologyHouse': 'Vila Pelicanos',
  'CommunityCenter': 'Vila Pelicanos',
  'JojaMart': 'Vila Pelicanos',
  'Hospital': 'Vila Pelicanos',
  'Blacksmith': 'Vila Pelicanos',
  'Trailer': 'Vila Pelicanos',
  'JoshHouse': 'Vila Pelicanos',
  'HaleyHouse': 'Vila Pelicanos',
  'SamHouse': 'Vila Pelicanos',
  'ElliottHouse': 'Vila Pelicanos',
  'AnimalShop': 'Floresta Cinzaseiva',
  'Forest': 'Floresta Cinzaseiva',
  'Woods': 'Floresta Cinzaseiva',
  'WizardHouse': 'Floresta Cinzaseiva',
  'SecretWoods': 'Bosque Secreto',
  'Mountain': 'Montanha',
  'ScienceHouse': 'Montanha',
  'Mine': 'Minas',
  'UndergroundMine': 'Minas',
  'Beach': 'Praia',
  'FishShop': 'Praia',
  'BusStop': 'Ponto de Ônibus',
  'Desert': 'Deserto de Calico',
  'SkullCave': 'Deserto de Calico',
  'Railroad': 'Ferrovia',
  'BathHouse_Entry': 'Ferrovia',
  'BathHouse_MensLocker': 'Ferrovia',
  'BathHouse_WomensLocker': 'Ferrovia',
  'Quarry': 'Pedreira',
  'IslandSouth': 'Ilha Gengibre',
  'IslandSouthEast': 'Ilha Gengibre',
  'IslandSouthEastCave': 'Ilha Gengibre',
  'IslandWest': 'Ilha Gengibre',
  'IslandNorth': 'Ilha Gengibre',
  'IslandEast': 'Ilha Gengibre',
  'IslandHut': 'Ilha Gengibre',
  'IslandShrine': 'Ilha Gengibre',
  'IslandFarmCave': 'Ilha Gengibre',
  'IslandFieldOffice': 'Ilha Gengibre',
  'IslandSecret': 'Ilha Gengibre',
  'VolcanoDungeon': 'Ilha Gengibre',
  'Sewer': 'Esgotos',
  'WitchHut': 'Esgotos',
};

const _interiorNames = {
  'FarmHouse': 'Casa da fazenda',
  'Greenhouse': 'Estufa',
  'Cellar': 'Adega',
  'Barn': 'Celeiro',
  'BigBarn': 'Celeiro grande',
  'DeluxeBarn': 'Celeiro de luxo',
  'Coop': 'Galinheiro',
  'BigCoop': 'Galinheiro grande',
  'DeluxeCoop': 'Galinheiro de luxo',
  'Shed': 'Galpão',
  'BigShed': 'Galpão grande',
  'SlimeHutch': 'Viveiro de slimes',
  'FarmCave': 'Caverna da fazenda',
  'Backwoods': 'Arredores da fazenda',
  'SeedShop': 'Armazém do Pierre',
  'Saloon': 'Saloon Frígido',
  'ManorHouse': 'Mansão do Prefeito',
  'ArchaeologyHouse': 'Museu da Vila',
  'CommunityCenter': 'Centro Comunitário',
  'JojaMart': 'JojaMart',
  'Hospital': 'Clínica da Vila',
  'Blacksmith': 'Ferraria do Clint',
  'AnimalShop': 'Rancho da Marnie',
  'WizardHouse': 'Torre do Mago',
  'ScienceHouse': 'Carpintaria da Robin',
  'FishShop': 'Peixaria do Willy',
  'Trailer': 'Trailer do Pam',
  'JoshHouse': 'Casa do Alex',
  'HaleyHouse': 'Casa da Haley',
  'SamHouse': 'Casa do Sam',
  'ElliottHouse': 'Cabana do Elliott',
  'BathHouse_Entry': 'Spa',
  'BathHouse_MensLocker': 'Spa',
  'BathHouse_WomensLocker': 'Spa',
  'Mine': 'Minas',
  'UndergroundMine': 'Minas',
  'SkullCave': 'Caverna da Caveira',
  'VolcanoDungeon': 'Vulcão',
  'Sewer': 'Esgotos',
  'WitchHut': 'Cabana da Bruxa',
  'IslandSouth': 'Ilha Gengibre',
  'IslandSouthEast': 'Ilha Gengibre',
  'IslandSouthEastCave': 'Ilha Gengibre',
  'IslandWest': 'Ilha Gengibre',
  'IslandNorth': 'Ilha Gengibre',
  'IslandEast': 'Ilha Gengibre',
  'IslandHut': 'Ilha Gengibre',
  'IslandShrine': 'Ilha Gengibre',
  'IslandFarmCave': 'Ilha Gengibre',
  'IslandFieldOffice': 'Ilha Gengibre',
  'IslandSecret': 'Ilha Gengibre',
};

const _directions = {
  'Sua fazenda': 'Saída sudeste → Ponto de Ônibus · Sul → Floresta Cinzaseiva',
  'Vila Pelicanos':
      'Oeste → Ponto de Ônibus/Fazenda · Norte → Montanha · Sul → Praia',
  'Ponto de Ônibus': 'Oeste → Fazenda · Leste → Vila Pelicanos',
  'Montanha':
      'Sul → Vila Pelicanos · Norte → Ferrovia · Leste → Minas/Pedreira',
  'Minas': 'Sul → Montanha',
  'Lago da Montanha': 'Sul → Vila Pelicanos · Oeste → Minas',
  'Ferrovia': 'Sul → Montanha · Leste → Pedreira',
  'Pedreira': 'Oeste → Minas · Sul → Montanha',
  'Floresta Cinzaseiva': 'Norte → Fazenda · Leste → Vila Pelicanos',
  'Bosque Secreto': 'Leste → Floresta Cinzaseiva',
  'Praia': 'Norte → Vila Pelicanos',
  'Deserto de Calico': 'Ônibus → Ponto de Ônibus',
  'Ilha Gengibre': 'Barco → Praia',
  'Esgotos': 'Tampa → Vila Pelicanos ou Floresta Cinzaseiva',
  'Cume': 'Sul → Ferrovia',
};

MapPlace? _findPlace(String? name) {
  if (name == null || name.isEmpty) return null;
  for (final p in mapPlaces) {
    if (p.name.toLowerCase() == name.toLowerCase()) return p;
  }
  return null;
}

String _prettyInternal(String raw) {
  if (raw.isEmpty) return 'Local desconhecido';
  final spaced = raw
      .replaceAll('_', ' ')
      .replaceAllMapped(RegExp(r'([a-z])([A-Z])'), (m) => '${m[1]} ${m[2]}');
  return spaced;
}

LocationInfo locationInfo(String raw) {
  final place = _findPlace(_placeByLocation[raw]);
  final display = _interiorNames[raw] ?? place?.name ?? _prettyInternal(raw);
  final region = place == null ? 'Fora do mapa' : mapRegionNames[place.region]!;
  final directions =
      _directions[place?.name] ?? 'Use o mapa do vale para se orientar.';
  final tip =
      place?.tip ??
      'Abra o Mapa do Vale para ver os caminhos e os lugares próximos.';
  return LocationInfo(
    displayName: display,
    place: place,
    directions: directions,
    tip: tip,
    region: region,
  );
}

Entry? villagerEntry(Repository repo, String name) {
  final key = normalize(name.trim());
  if (key.isEmpty) return null;
  for (final e in repo.byCat['aldeoes'] ?? const <Entry>[]) {
    if (normalize(e.en) == key || normalize(e.name) == key) return e;
  }
  return null;
}

Entry? entryForItem(Repository repo, ApiItem item) {
  final key = normalize(
    (item.displayName.isNotEmpty ? item.displayName : item.name).trim(),
  );
  if (key.isEmpty) return null;
  for (final e in repo.all) {
    if (normalize(e.en) == key || normalize(e.name) == key) return e;
  }
  return null;
}

StatusTip recommendedNextStep(ApiSnapshot snap, Repository repo) {
  final p = snap.player;
  final w = snap.world;

  final quests = p.quests.where((q) => q.title.trim().isNotEmpty).toList()
    ..sort((a, b) => (a.daysLeft ?? 99).compareTo(b.daysLeft ?? 99));
  if (quests.isNotEmpty) {
    final q = quests.first;
    final body = q.currentObjective.trim().isNotEmpty
        ? q.currentObjective.trim()
        : (q.description.trim().isNotEmpty
              ? q.description.trim()
              : 'Abra o diário de missões no jogo para ver o objetivo.');
    return StatusTip(
      emoji: '📜',
      title: 'Missão: ${q.title}',
      body: q.daysLeft != null
          ? '$body · ${q.daysLeft} dia(s) restante(s)'
          : body,
      kind: StatusTipKind.quest,
    );
  }

  if (w.birthdays.isNotEmpty) {
    final npc = w.birthdays.first;
    final entry = villagerEntry(repo, npc.name);
    return StatusTip(
      emoji: '🎂',
      title: 'Aniversário de ${entry?.name ?? npc.name}',
      body:
          'Passe na casa ou no lugar onde essa pessoa costuma ficar e entregue um presente que ela ama.',
      kind: StatusTipKind.birthday,
      entryId: entry?.id,
    );
  }

  if (w.festival != null && w.festival!.trim().isNotEmpty) {
    return StatusTip(
      emoji: '🎪',
      title: 'Hoje tem festival: ${w.festival}',
      body:
          'Vá até o local do festival, converse com os moradores e participe das atividades. As lojas podem fechar.',
      kind: StatusTipKind.festival,
    );
  }

  if (p.maxStamina > 0 && p.stamina / p.maxStamina < 0.2) {
    return StatusTip(
      emoji: '⚡',
      title: 'Energia baixa',
      body:
          'Coma algo da mochila ou volte para casa e durma. Sem energia, você não consegue minerar nem regar.',
      kind: StatusTipKind.energy,
    );
  }

  if (p.maxHealth > 0 && p.health / p.maxHealth < 0.35) {
    return StatusTip(
      emoji: '❤️',
      title: 'Vida baixa',
      body:
          'Leve comida e evite descer mais fundo nas minas. Se a vida zerar, você acorda na cama e perde itens.',
      kind: StatusTipKind.health,
    );
  }

  if (w.day >= 25) {
    return StatusTip(
      emoji: '🍂',
      title: 'Fim da estação chegando',
      body:
          'Colha tudo o que puder até o dia 28: o que ficar no campo morre na virada. Replante só o que ainda dá tempo.',
      kind: StatusTipKind.season,
    );
  }

  final weather = weatherInfo(w.weather);
  final closeFriend = _closestFriend(p.relationships);
  if (closeFriend != null) {
    final entry = villagerEntry(repo, closeFriend.npcName);
    final target = closeFriend.isMarried ? 14 : 10;
    if (closeFriend.hearts >= target - 2 && closeFriend.hearts < target) {
      return StatusTip(
        emoji: '💛',
        title: '${entry?.name ?? closeFriend.npcName} está quase no máximo',
        body:
            'Faltam ${target - closeFriend.hearts} coração(ões). Entregue um presente que essa pessoa ama hoje.',
        kind: StatusTipKind.relationship,
        entryId: entry?.id,
      );
    }
  }

  return StatusTip(
    emoji: weather.emoji,
    title: 'Plano do dia',
    body:
        '${weather.tip} Regue as plantas, colete o que aparecer e converse com pelo menos um morador.',
    kind: StatusTipKind.weather,
  );
}

ApiRelationship? _closestFriend(List<ApiRelationship> relationships) {
  ApiRelationship? best;
  var bestGap = 99;
  for (final r in relationships) {
    if (r.isDivorced || r.hearts <= 0) continue;
    final target = r.isMarried ? 14 : 10;
    final gap = target - r.hearts;
    if (gap > 0 && gap < bestGap) {
      best = r;
      bestGap = gap;
    }
  }
  return best;
}

List<StatusTip> buildStatusTips(ApiSnapshot snap, Repository repo) {
  final p = snap.player;
  final w = snap.world;
  final tips = <StatusTip>[];
  final weather = weatherInfo(w.weather);

  if (w.festival != null && w.festival!.trim().isNotEmpty) {
    tips.add(
      StatusTip(
        emoji: '🎪',
        title: 'Festival hoje',
        body:
            '${w.festival}: largue as tarefas da fazenda e vá participar. É uma chance de amizade e itens exclusivos.',
        kind: StatusTipKind.festival,
      ),
    );
  }

  if (p.maxStamina > 0 && p.stamina / p.maxStamina < 0.35) {
    tips.add(
      StatusTip(
        emoji: '⚡',
        title: 'Energia em ${(p.stamina / p.maxStamina * 100).round()}%',
        body:
            'Leve comida para a mina ou faça uma pausa. Não espere passar mal no fim do dia.',
        kind: StatusTipKind.energy,
      ),
    );
  }
  if (p.maxHealth > 0 && p.health / p.maxHealth < 0.6) {
    tips.add(
      StatusTip(
        emoji: '❤️',
        title: 'Vida em ${(p.health / p.maxHealth * 100).round()}%',
        body:
            'Cuidado com slimes e morcegos. Comida com buff de defesa ajuda nas minas.',
        kind: StatusTipKind.health,
      ),
    );
  }

  if (w.day >= 24) {
    tips.add(
      const StatusTip(
        emoji: '🍂',
        title: 'Últimos dias da estação',
        body:
            'Colha e venda o que estiver maduro; o que ficar no campo morre no dia 28.',
        kind: StatusTipKind.season,
      ),
    );
  }

  tips.add(
    StatusTip(
      emoji: weather.emoji,
      title: 'Clima: ${weather.label}',
      body: weather.tip,
      kind: StatusTipKind.weather,
    ),
  );

  if (snap.inventory.length >= 30) {
    tips.add(
      StatusTip(
        emoji: '🎒',
        title: 'Mochila quase cheia',
        body:
            'Você está com ${snap.inventory.length} itens. Venda o que não usa ou guarde em um baú antes de minerar.',
        kind: StatusTipKind.inventory,
      ),
    );
  }

  final friend = _closestFriend(p.relationships);
  if (friend != null) {
    final entry = villagerEntry(repo, friend.npcName);
    final target = friend.isMarried ? 14 : 10;
    if (friend.hearts >= target - 3) {
      tips.add(
        StatusTip(
          emoji: '💛',
          title:
              '${entry?.name ?? friend.npcName}: ${friend.hearts}/$target corações',
          body: friend.hasBeenGivenGiftToday
              ? 'O presente de hoje já foi dado. Converse para manter a amizade.'
              : 'Ainda dá tempo de entregar um presente hoje e subir mais um coração.',
          kind: StatusTipKind.relationship,
          entryId: entry?.id,
        ),
      );
    }
  }

  final locked = p.achievements
      .where((a) => !a.hasPlayerUnlocked && a.canPlayerSeeDetails)
      .toList();
  if (locked.isNotEmpty) {
    final a = locked.first;
    tips.add(
      StatusTip(
        emoji: '🏆',
        title: 'Próxima conquista: ${a.name}',
        body: a.description,
        kind: StatusTipKind.achievement,
      ),
    );
  }

  final lowSkill = _lowestSkill(p.skills);
  if (lowSkill != null) {
    tips.add(
      StatusTip(
        emoji: skillEmoji(lowSkill),
        title: '${skillNamePt(lowSkill)} no nível ${lowSkill.level}',
        body:
            'É a habilidade que mais pode crescer agora. Um pouco de prática todos os dias rende profissões melhores.',
        kind: StatusTipKind.skill,
      ),
    );
  }

  final loc = locationInfo(p.location);
  tips.add(
    StatusTip(
      emoji: loc.emoji,
      title: 'Onde você está: ${loc.displayName}',
      body: loc.directions,
      kind: StatusTipKind.location,
    ),
  );

  return tips.take(8).toList();
}

ApiSkill? _lowestSkill(List<ApiSkill> skills) {
  ApiSkill? low;
  for (final s in skills) {
    if (s.level >= 10) continue;
    if (low == null || s.level < low.level) low = s;
  }
  return low;
}

class AiObjective {
  final String action;
  final String? place;
  final String? detail;

  const AiObjective({required this.action, this.place, this.detail});
}

/// Transforma a resposta da IA em até três objetivos curtos, próprios para
/// aparecerem como cartões de missão — não como um bloco de texto.
List<AiObjective> parseAiObjectives(String raw) {
  var text = raw
      .replaceAll(RegExp(r'<think>.*?</think>', dotAll: true), '')
      .replaceAll(RegExp(r'```.*?```', dotAll: true), '')
      .replaceAll(RegExp(r'[*_`#]'), '')
      .replaceAll('\r', '')
      .trim();
  if (text.isEmpty) return const [];

  var lines = text
      .split('\n')
      .map((l) => l.trim())
      .where((l) => l.isNotEmpty)
      .where(
        (l) => !RegExp(
          r'^(agora|plano|resposta|conselheiro|próximo passo)',
          caseSensitive: false,
        ).hasMatch(l),
      )
      .where(
        (l) => !RegExp(r'^(ação|acao)\s*\|', caseSensitive: false).hasMatch(l),
      )
      .toList();

  if (lines.length == 1) {
    final one = lines.first;
    final sentences = one
        .split(RegExp(r'(?<=[.!?])\s+'))
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty)
        .toList();
    if (sentences.length > 1) lines = sentences;
  }

  final out = <AiObjective>[];
  for (final rawLine in lines) {
    var line = rawLine.replaceFirst(RegExp(r'^(\d+[.)]|[-•*])\s*'), '').trim();
    if (line.isEmpty) continue;
    line = line.replaceFirst(
      RegExp(
        r'^(agora|primeiro|depois|então|em seguida)\s*[:\-]\s*',
        caseSensitive: false,
      ),
      '',
    );

    String action = line;
    String? place;
    String? detail;
    if (line.contains('|')) {
      final parts = line
          .split('|')
          .map((p) => p.trim())
          .where((p) => p.isNotEmpty)
          .toList();
      if (parts.isNotEmpty) action = parts[0];
      if (parts.length > 1) place = parts[1];
      if (parts.length > 2) detail = parts.sublist(2).join(' · ');
    } else {
      final split = RegExp(r'\s+[—–-]\s+').firstMatch(line);
      if (split != null) {
        action = line.substring(0, split.start).trim();
        detail = line.substring(split.end).trim();
      }
    }
    if (action.isEmpty) continue;
    if (action.length > 96) action = '${action.substring(0, 93)}…';
    if (place != null && place.length > 42) {
      place = '${place.substring(0, 39)}…';
    }
    if (detail != null && detail.length > 96) {
      detail = '${detail.substring(0, 93)}…';
    }
    out.add(AiObjective(action: action, place: place, detail: detail));
    if (out.length == 3) break;
  }
  return out;
}

String buildStatusPrompt({
  required ApiSnapshot snap,
  required LocationInfo location,
  required StatusTip next,
  required List<StatusTip> tips,
  required Repository repo,
}) {
  final p = snap.player;
  final w = snap.world;
  final weather = weatherInfo(w.weather);
  final b = StringBuffer();
  b.writeln(
    'Você é o conselheiro do Guia do Vale, um subagente que ajuda uma pessoa a jogar Stardew Valley 1.6.',
  );
  b.writeln(
    'Fale em português do Brasil, direto, como um amigo que conhece o jogo. Não invente dados.',
  );
  b.writeln('Ela está com o celular deitado ao lado do PC enquanto joga.');
  b.writeln(
    'Dê prioridade absoluta ao próximo passo prático e diga para onde ir. Não repita a ficha inteira.',
  );
  b.writeln(
    'Se houver missão, fale dela primeiro. Se não houver, escolha a ação mais útil para hoje.',
  );
  b.writeln();
  b.writeln('STATUS:');
  b.writeln(
    '- Data: ${seasonNameFor(w.season)} ${w.day}, Ano ${w.year} (${weekdayPt(w.dayOfWeek)}); clima: ${weather.label}.',
  );
  if (w.festival != null) b.writeln('- Festival hoje: ${w.festival}.');
  if (w.birthdays.isNotEmpty) {
    b.writeln('- Aniversários: ${w.birthdays.map((e) => e.name).join(', ')}.');
  }
  b.writeln(
    '- Local: ${location.displayName} (${location.region}). ${location.directions} ${location.tip}',
  );
  b.writeln(
    '- Jogador: ${p.displayName.isEmpty ? p.name : p.displayName}; fazenda: ${w.farmName}; dinheiro: ${moneyLabel(p.money)}.',
  );
  b.writeln(
    '- Energia: ${p.stamina.round()}/${p.maxStamina}; vida: ${p.health}/${p.maxHealth}; sorte: ${luckLabel(p)} (${luckPhrase(p.dailyLuck)}).',
  );
  if (p.quests.isNotEmpty) {
    b.writeln('- Missões:');
    for (final q in p.quests.take(5)) {
      b.writeln(
        '  · ${q.title}: ${q.currentObjective}${q.daysLeft != null ? ' (${q.daysLeft} dia(s))' : ''}',
      );
    }
  } else {
    b.writeln('- Missões: nenhuma ativa.');
  }
  b.writeln(
    '- Mochila (${snap.inventory.length} itens): ${snap.inventory.take(12).map((i) => '${i.displayName} x${i.stackSize}').join(', ')}.',
  );
  final friends = [...p.relationships]
    ..sort((a, b) => b.hearts.compareTo(a.hearts));
  if (friends.isNotEmpty) {
    b.writeln(
      '- Amizades: ${friends.take(6).map((r) => '${r.npcName} ${r.hearts}♥${r.isMarried ? ' (casado)' : ''}').join(', ')}.',
    );
  }
  if (p.skills.isNotEmpty) {
    b.writeln(
      '- Habilidades: ${p.skills.map((s) => '${skillNamePt(s)} ${s.level}').join(', ')}.',
    );
  }
  final unlocked = p.achievements.where((a) => a.hasPlayerUnlocked).length;
  b.writeln('- Conquistas: $unlocked de ${p.achievements.length}.');
  final crops = repo
      .cropsFor(w.season)
      .map((e) => e.name)
      .where((n) => n.trim().isNotEmpty)
      .take(6)
      .toList();
  if (crops.isNotEmpty) {
    b.writeln('- Culturas da estação no guia: ${crops.join(', ')}.');
  }
  b.writeln();
  b.writeln('SUGESTÃO DO GUIA (use como base, mas escolha a prioridade):');
  b.writeln('- ${next.title}: ${next.body}');
  for (final t in tips.take(4)) {
    b.writeln('- ${t.title}: ${t.body}');
  }
  b.writeln();
  b.writeln(
    'FORMATO OBRIGATÓRIO: responda SOMENTE com até 3 linhas, sem título, sem introdução e sem markdown.',
  );
  b.writeln('Cada linha deve seguir exatamente este formato:');
  b.writeln('AÇÃO CURTA | LUGAR | MOTIVO CURTO');
  b.writeln(
    'Exemplo: Regar as plantas | Fazenda | O dia está ensolarado e elas precisam de água',
  );
  b.writeln(
    'Uma linha por objetivo. Diga o lugar mais próximo ou o caminho a seguir. Não escreva parágrafos.',
  );
  b.writeln('Resposta:');
  return b.toString();
}

double clamp01(double v) => math.max(0.0, math.min(1.0, v));
