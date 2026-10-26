import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import 'models.dart';
import 'repository.dart';
import 'search.dart';
import 'store.dart';
import 'game_events.dart';
import 'game_status.dart';
import 'game_ws.dart';

/// Erro de comunicação com a API local.
class ApiException implements Exception {
  final int statusCode;
  final String message;
  const ApiException(this.statusCode, this.message);

  @override
  String toString() => message;
}

class DiscoveredServer {
  final String name;
  final String host;
  final int port;

  const DiscoveredServer({
    required this.name,
    required this.host,
    required this.port,
  });

  String get url =>
      host.contains(':') ? 'http://[$host]:$port' : 'http://$host:$port';
}

/// Data do jogo como a API devolve (a estação e o dia da semana vêm como texto).
class ApiDate {
  final int season;
  final int day;
  final int year;
  final String dayOfWeek;
  final String shortDayOfWeek;

  const ApiDate({
    required this.season,
    required this.day,
    required this.year,
    this.dayOfWeek = '',
    this.shortDayOfWeek = '',
  });

  factory ApiDate.fromJson(Map<String, dynamic> j) {
    final seasonName = (j['season'] as String?) ?? 'Spring';
    return ApiDate(
      season: seasonFromApi(seasonName),
      day: (j['day'] as num?)?.toInt() ?? 1,
      year: (j['year'] as num?)?.toInt() ?? 1,
      dayOfWeek: (j['dayOfWeek'] as String?) ?? '',
      shortDayOfWeek: (j['shortDayOfWeek'] as String?) ?? '',
    );
  }
}

class ApiNpc {
  final String name;
  final String type;

  const ApiNpc({required this.name, this.type = ''});

  factory ApiNpc.fromJson(Map<String, dynamic> j) {
    return ApiNpc(
      name: (j['name'] as String?) ?? '',
      // A API pode mandar "Villager" (texto) ou um número em versões antigas.
      type: '${j['type'] ?? ''}',
    );
  }
}

class ApiWorld {
  final int season;
  final int day;
  final int year;
  final String dayOfWeek;
  final String shortDayOfWeek;
  final String weather;
  final String farmName;
  final String currentMusicTrack;
  final String? festival;
  final List<ApiNpc> birthdays;

  const ApiWorld({
    required this.season,
    required this.day,
    required this.year,
    required this.weather,
    required this.farmName,
    this.dayOfWeek = '',
    this.shortDayOfWeek = '',
    this.currentMusicTrack = '',
    this.festival,
    this.birthdays = const [],
  });

  factory ApiWorld.fromJson(Map<String, dynamic> j) {
    final today =
        (j['today'] as Map?)?.cast<String, dynamic>() ??
        const <String, dynamic>{};
    final date =
        (today['date'] as Map?)?.cast<String, dynamic>() ??
        const <String, dynamic>{};
    final parsed = ApiDate.fromJson(date);
    return ApiWorld(
      season: parsed.season,
      day: parsed.day,
      year: parsed.year,
      dayOfWeek: parsed.dayOfWeek,
      shortDayOfWeek: parsed.shortDayOfWeek,
      weather: (today['weather'] as String?) ?? '',
      farmName: (j['farmName'] as String?) ?? '',
      currentMusicTrack: (j['currentMusicTrack'] as String?) ?? '',
      festival: today['festival'] as String?,
      birthdays: _objectList(today['birthdays'], ApiNpc.fromJson),
    );
  }
}

int seasonFromApi(String value) {
  switch (value.toLowerCase()) {
    case 'summer':
      return 1;
    case 'fall':
    case 'autumn':
      return 2;
    case 'winter':
      return 3;
    default:
      return 0;
  }
}

List<T> _objectList<T>(dynamic raw, T Function(Map<String, dynamic>) parse) {
  if (raw is! List) return const [];
  return raw
      .whereType<Map>()
      .map((e) => parse(e.cast<String, dynamic>()))
      .toList();
}

class ApiProfession {
  final int id;
  final String name;
  final String description;

  const ApiProfession({
    required this.id,
    required this.name,
    required this.description,
  });

  factory ApiProfession.fromJson(Map<String, dynamic> j) {
    return ApiProfession(
      id: (j['id'] as num?)?.toInt() ?? 0,
      name: (j['name'] as String?) ?? '',
      description: (j['description'] as String?) ?? '',
    );
  }
}

class ApiSkill {
  final int id;
  final String name;
  final int level;
  final List<ApiProfession> professions;

  const ApiSkill({
    required this.id,
    required this.name,
    required this.level,
    this.professions = const [],
  });

  factory ApiSkill.fromJson(Map<String, dynamic> j) {
    return ApiSkill(
      id: (j['id'] as num?)?.toInt() ?? 0,
      name: (j['name'] as String?) ?? '',
      level: (j['level'] as num?)?.toInt() ?? 0,
      professions: _objectList(j['professions'], ApiProfession.fromJson),
    );
  }
}

class ApiQuest {
  final String title;
  final String description;
  final bool hasReward;
  final String? rewardDescription;
  final bool hasMoneyReward;
  final int? moneyReward;
  final String currentObjective;
  final bool isTimedQuest;
  final int? daysLeft;

  const ApiQuest({
    required this.title,
    required this.description,
    required this.hasReward,
    this.rewardDescription,
    required this.hasMoneyReward,
    this.moneyReward,
    required this.currentObjective,
    required this.isTimedQuest,
    this.daysLeft,
  });

  factory ApiQuest.fromJson(Map<String, dynamic> j) {
    return ApiQuest(
      title: (j['title'] as String?) ?? '',
      description: (j['description'] as String?) ?? '',
      hasReward: (j['hasReward'] as bool?) ?? false,
      rewardDescription: j['rewardDescription'] as String?,
      hasMoneyReward: (j['hasMoneyReward'] as bool?) ?? false,
      moneyReward: (j['moneyReward'] as num?)?.toInt(),
      currentObjective: (j['currentObjective'] as String?) ?? '',
      isTimedQuest: (j['isTimedQuest'] as bool?) ?? false,
      daysLeft: (j['daysLeft'] as num?)?.toInt(),
    );
  }
}

class ApiAchievement {
  final int id;
  final String name;
  final String description;
  final bool hasPlayerUnlocked;
  final bool canPlayerSeeDetails;
  final bool showIfPrerequisiteMet;
  final bool hasPrerequisiteAchievement;
  final int? prerequisiteAchievement;
  final ApiItem? reward;

  const ApiAchievement({
    required this.id,
    required this.name,
    required this.description,
    required this.hasPlayerUnlocked,
    required this.canPlayerSeeDetails,
    required this.showIfPrerequisiteMet,
    required this.hasPrerequisiteAchievement,
    this.prerequisiteAchievement,
    this.reward,
  });

  factory ApiAchievement.fromJson(Map<String, dynamic> j) {
    return ApiAchievement(
      id: (j['id'] as num?)?.toInt() ?? 0,
      name: (j['name'] as String?) ?? '',
      description: (j['description'] as String?) ?? '',
      hasPlayerUnlocked: (j['hasPlayerUnlocked'] as bool?) ?? false,
      canPlayerSeeDetails: (j['canPlayerSeeDetails'] as bool?) ?? false,
      showIfPrerequisiteMet: (j['showIfPrerequisiteMet'] as bool?) ?? false,
      hasPrerequisiteAchievement:
          (j['hasPrerequisiteAchievement'] as bool?) ?? false,
      prerequisiteAchievement: (j['prerequisiteAchievement'] as num?)?.toInt(),
      reward: _itemOrNull(j['reward']),
    );
  }
}

class ApiItem {
  final String itemId;
  final String typeDefinitionId;
  final String name;
  final String displayName;
  final String qualifiedItemId;
  final int quality;
  final int category;
  final int stackSize;
  final String url;

  const ApiItem({
    required this.name,
    required this.displayName,
    required this.qualifiedItemId,
    required this.stackSize,
    this.itemId = '',
    this.typeDefinitionId = '',
    this.quality = 0,
    this.category = 0,
    this.url = '',
  });

  factory ApiItem.fromJson(Map<String, dynamic> j) {
    return ApiItem(
      itemId: (j['itemId'] as String?) ?? '',
      typeDefinitionId: (j['typeDefinitionId'] as String?) ?? '',
      name: (j['name'] as String?) ?? '',
      displayName: (j['displayName'] as String?) ?? '',
      qualifiedItemId: (j['qualifiedItemId'] as String?) ?? '',
      quality: (j['quality'] as num?)?.toInt() ?? 0,
      category: (j['category'] as num?)?.toInt() ?? 0,
      stackSize: (j['stackSize'] as num?)?.toInt() ?? 0,
      url: (j['url'] as String?) ?? '',
    );
  }
}

ApiItem? _itemOrNull(dynamic raw) {
  if (raw is! Map) return null;
  return ApiItem.fromJson(raw.cast<String, dynamic>());
}

class ApiClothing {
  final ApiItem? hat;
  final ApiItem? shirt;
  final ApiItem? pants;
  final ApiItem? boots;
  final ApiItem? rightRing;
  final ApiItem? leftRing;

  const ApiClothing({
    this.hat,
    this.shirt,
    this.pants,
    this.boots,
    this.rightRing,
    this.leftRing,
  });

  factory ApiClothing.fromJson(Map<String, dynamic>? j) {
    if (j == null) return const ApiClothing();
    return ApiClothing(
      hat: _itemOrNull(j['hat']),
      shirt: _itemOrNull(j['shirt']),
      pants: _itemOrNull(j['pants']),
      boots: _itemOrNull(j['boots']),
      rightRing: _itemOrNull(j['rightRing']),
      leftRing: _itemOrNull(j['leftRing']),
    );
  }
}

class ApiRelationship {
  final String npcName;
  final String npcType;
  final int points;
  final int hearts;
  final bool hasBeenGivenGiftToday;
  final int giftsGivenToday;
  final int giftsGivenThisWeek;
  final ApiDate? lastGiftDate;
  final bool isDating;
  final bool isEngaged;
  final bool isMarried;
  final bool isRoommate;
  final bool isDivorced;

  const ApiRelationship({
    required this.npcName,
    required this.hearts,
    required this.isMarried,
    this.npcType = '',
    this.points = 0,
    this.hasBeenGivenGiftToday = false,
    this.giftsGivenToday = 0,
    this.giftsGivenThisWeek = 0,
    this.lastGiftDate,
    this.isDating = false,
    this.isEngaged = false,
    this.isRoommate = false,
    this.isDivorced = false,
  });

  factory ApiRelationship.fromJson(Map<String, dynamic> j) {
    final npc =
        (j['npc'] as Map?)?.cast<String, dynamic>() ??
        const <String, dynamic>{};
    final lastGift = (j['lastGiftDate'] as Map?)?.cast<String, dynamic>();
    return ApiRelationship(
      npcName: (npc['name'] as String?) ?? '',
      npcType: '${npc['type'] ?? ''}',
      points: (j['points'] as num?)?.toInt() ?? 0,
      hearts: (j['hearts'] as num?)?.toInt() ?? 0,
      hasBeenGivenGiftToday: (j['hasBeenGivenGiftToday'] as bool?) ?? false,
      giftsGivenToday: (j['giftsGivenToday'] as num?)?.toInt() ?? 0,
      giftsGivenThisWeek: (j['giftsGivenThisWeek'] as num?)?.toInt() ?? 0,
      lastGiftDate: lastGift == null ? null : ApiDate.fromJson(lastGift),
      isDating: (j['isDating'] as bool?) ?? false,
      isEngaged: (j['isEngaged'] as bool?) ?? false,
      isMarried: (j['isMarried'] as bool?) ?? false,
      isRoommate: (j['isRoommate'] as bool?) ?? false,
      isDivorced: (j['isDivorced'] as bool?) ?? false,
    );
  }
}

class ApiPlayer {
  final String name;
  final String displayName;
  final String farmName;
  final int money;
  final double stamina;
  final int maxStamina;
  final int health;
  final int maxHealth;
  final String location;
  final double dailyLuck;
  final String dailyLuckFriendlyValue;
  final String dailyLuckDescription;
  final ApiClothing clothing;
  final List<ApiSkill> skills;
  final List<ApiQuest> quests;
  final List<ApiAchievement> achievements;
  final List<ApiRelationship> relationships;

  const ApiPlayer({
    required this.name,
    required this.farmName,
    required this.money,
    required this.location,
    required this.relationships,
    this.displayName = '',
    this.stamina = 0,
    this.maxStamina = 0,
    this.health = 0,
    this.maxHealth = 0,
    this.dailyLuck = 0,
    this.dailyLuckFriendlyValue = '',
    this.dailyLuckDescription = '',
    this.clothing = const ApiClothing(),
    this.skills = const [],
    this.quests = const [],
    this.achievements = const [],
  });

  factory ApiPlayer.fromJson(Map<String, dynamic> j) {
    return ApiPlayer(
      name: (j['name'] as String?) ?? '',
      displayName: (j['displayName'] as String?) ?? '',
      farmName: (j['farmName'] as String?) ?? '',
      money: (j['money'] as num?)?.toInt() ?? 0,
      stamina: (j['stamina'] as num?)?.toDouble() ?? 0,
      maxStamina: (j['maxStamina'] as num?)?.toInt() ?? 0,
      health: (j['health'] as num?)?.toInt() ?? 0,
      maxHealth: (j['maxHealth'] as num?)?.toInt() ?? 0,
      location: (j['location'] as String?) ?? '',
      dailyLuck: (j['dailyLuck'] as num?)?.toDouble() ?? 0,
      dailyLuckFriendlyValue: (j['dailyLuckFriendlyValue'] as String?) ?? '',
      dailyLuckDescription: (j['dailyLuckDescription'] as String?) ?? '',
      clothing: ApiClothing.fromJson(
        (j['clothing'] as Map?)?.cast<String, dynamic>(),
      ),
      skills: _objectList(j['skills'], ApiSkill.fromJson),
      quests: _objectList(j['quests'], ApiQuest.fromJson),
      achievements: _objectList(j['achievements'], ApiAchievement.fromJson),
      relationships: _objectList(j['relationships'], ApiRelationship.fromJson),
    );
  }
}

class ApiSnapshot {
  final ApiWorld world;
  final ApiPlayer player;
  final List<ApiItem> inventory;

  const ApiSnapshot({
    required this.world,
    required this.player,
    required this.inventory,
  });

  /// Cópia com o jogador em outro local (evento PlayerWarped).
  ApiSnapshot withLocation(String location) {
    final p = player;
    return ApiSnapshot(
      world: world,
      inventory: inventory,
      player: ApiPlayer(
        name: p.name,
        displayName: p.displayName,
        farmName: p.farmName,
        money: p.money,
        stamina: p.stamina,
        maxStamina: p.maxStamina,
        health: p.health,
        maxHealth: p.maxHealth,
        location: location,
        dailyLuck: p.dailyLuck,
        dailyLuckFriendlyValue: p.dailyLuckFriendlyValue,
        dailyLuckDescription: p.dailyLuckDescription,
        clothing: p.clothing,
        skills: p.skills,
        quests: p.quests,
        achievements: p.achievements,
        relationships: p.relationships,
      ),
    );
  }
}

/// Integração opcional com a Stardew Web API na rede local.
///
/// A API só acrescenta progresso: nunca desmarca o que o jogador marcou à mão.
/// Ela também não substitui o conteúdo offline do app quando está indisponível.
class GameApi extends ChangeNotifier with WidgetsBindingObserver {
  static const _channel = MethodChannel('guia_do_vale/nsd');

  /// Categorias em que ter o item na mochila significa "já tenho/coletei".
  /// Ficam de fora as categorias em que o inventário não prova progresso,
  /// como "já plantei", "já doei" ou "já derrotei".
  static const _inventoryCategories = {
    'peixes',
    'coletaveis',
    'minerais',
    'culinaria',
    'ferramentas',
  };

  final Store store;
  final Repository repo;

  String baseUrl = '';
  bool connected = false;
  bool linking = false;
  bool scanning = false;
  String? error;
  ApiSnapshot? snapshot;
  int lastAutoMarked = 0;
  DateTime? lastSync;

  /// Hora do jogo (HHMM) vinda do evento TimeChanged; null até o 1º evento.
  int? gameTime;

  /// Mensagens recentes dos eventos ao vivo (mais nova primeiro).
  final List<HudMessage> hud = [];
  Map<String, List<Entry>>? _nameIndex;
  Timer? _timer;
  GameWebSocket? _ws;
  bool _syncing = false;
  bool _observing = false;
  int _session = 0;

  bool get wsConnected => _ws?.isConnected ?? false;

  GameApi(this.store, this.repo) {
    final ms = store.apiLastSyncMs;
    if (ms > 0) lastSync = DateTime.fromMillisecondsSinceEpoch(ms);
  }

  Future<void> init() async {
    if (!_observing) {
      WidgetsBinding.instance.addObserver(this);
      _observing = true;
    }
    final saved = store.apiUrl.trim();
    if (saved.isNotEmpty) {
      await connect(saved, remember: false, silent: true);
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _ws?.disconnect();
    if (_observing) {
      WidgetsBinding.instance.removeObserver(this);
      _observing = false;
    }
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && connected && store.apiAuto) {
      sync(silent: true);
    }
  }

  Future<List<DiscoveredServer>> discover() async {
    if (scanning) return const [];
    scanning = true;
    error = null;
    notifyListeners();

    try {
      final raw = await _channel
          .invokeMethod<List<dynamic>>('discover')
          .timeout(const Duration(seconds: 8));
      final out = <DiscoveredServer>[];
      for (final item in raw ?? const []) {
        if (item is! Map) continue;
        final host = (item['host'] as String?)?.trim() ?? '';
        final port = (item['port'] as num?)?.toInt() ?? 0;
        if (host.isEmpty || port <= 0) continue;
        out.add(
          DiscoveredServer(
            name: (item['name'] as String?) ?? 'Stardew Web API',
            host: host,
            port: port,
          ),
        );
      }
      return out;
    } on MissingPluginException {
      error =
          'Busca automática indisponível neste aparelho. Informe o endereço.';
      return const [];
    } on PlatformException catch (e) {
      error = e.message?.trim().isNotEmpty == true
          ? e.message!
          : 'Não foi possível procurar o servidor na rede.';
      return const [];
    } on TimeoutException {
      error = 'A busca demorou demais. Tente de novo ou informe o endereço.';
      return const [];
    } finally {
      scanning = false;
      notifyListeners();
    }
  }

  Future<bool> connect(
    String raw, {
    bool remember = true,
    String? name,
    bool silent = false,
  }) async {
    if (linking) return false;
    final url = normalizeBaseUrl(raw);
    if (url == null) {
      error = 'Endereço inválido. Exemplo: http://192.168.0.10:7882';
      notifyListeners();
      return false;
    }

    linking = true;
    error = null;
    notifyListeners();

    try {
      final health = await _getJson(url, '/api/v1/mods');
      if (health is! List) {
        throw const ApiException(
          0,
          'O endereço respondeu, mas não parece ser a Stardew Web API.',
        );
      }

      _session++;
      baseUrl = url;
      connected = true;

      if (remember) {
        store.setApiUrl(url);
        store.setApiName(name ?? '');
        store.setApiAuto(true);
      }

      _startTimer();
      _connectWs(url);
      await sync(silent: silent);
      return true;
    } on ApiException catch (e) {
      connected = false;
      error = _friendlyError(e);
      _timer?.cancel();
      _ws?.disconnect();
      return false;
    } catch (e) {
      connected = false;
      error = 'Não foi possível conectar à API: $e';
      _timer?.cancel();
      _ws?.disconnect();
      return false;
    } finally {
      linking = false;
      notifyListeners();
    }
  }

  Future<bool> sync({bool silent = false}) async {
    if (!connected || baseUrl.isEmpty || _syncing) return false;
    _syncing = true;
    final session = _session;
    if (!silent) notifyListeners();

    try {
      final results = await Future.wait([
        _getJson(baseUrl, '/api/v1/world'),
        _getJson(baseUrl, '/api/v1/players/main'),
        _getJson(baseUrl, '/api/v1/players/main/inventory'),
      ]);

      if (session != _session || !connected) return false;

      final world = ApiWorld.fromJson(
        (results[0] as Map).cast<String, dynamic>(),
      );
      final player = ApiPlayer.fromJson(
        (results[1] as Map).cast<String, dynamic>(),
      );
      final inventory = ((results[2] as List?) ?? const [])
          .whereType<Map>()
          .map((e) => ApiItem.fromJson(e.cast<String, dynamic>()))
          .toList();

      snapshot = ApiSnapshot(
        world: world,
        player: player,
        inventory: inventory,
      );
      store.setDate(world.season, world.day);

      final ids = _autoCollectedIds(player, inventory);
      lastAutoMarked = store.addCollected(ids);
      lastSync = DateTime.now();
      store.setApiLastSync(lastSync);
      error = null;
      return true;
    } on ApiException catch (e) {
      if (e.statusCode == 400 &&
          e.message.toLowerCase().contains('no save loaded')) {
        if (snapshot == null) {
          error =
              'API conectada. Carregue um save no jogo para sincronizar o progresso.';
        }
      } else {
        error = _friendlyError(e);
      }
      return false;
    } catch (e) {
      error = 'Falha ao sincronizar: $e';
      return false;
    } finally {
      _syncing = false;
      notifyListeners();
    }
  }

  void setAuto(bool value) {
    store.setApiAuto(value);
    if (value && connected) {
      _startTimer();
      sync(silent: true);
    } else {
      _timer?.cancel();
    }
    notifyListeners();
  }

  void disconnect() {
    _session++;
    _timer?.cancel();
    _ws?.disconnect();
    _ws = null;
    baseUrl = '';
    connected = false;
    snapshot = null;
    error = null;
    lastAutoMarked = 0;
    lastSync = null;
    store.setApiUrl('');
    store.setApiName('');
    store.setApiAuto(false);
    store.setApiLastSync(null);
    notifyListeners();
  }

  void _connectWs(String url) {
    _ws?.disconnect();
    _ws = GameWebSocket(
      onEvent: _handleWsEvent,
      onConnected: () => notifyListeners(),
      onDisconnected: () => notifyListeners(),
    )..connect(url);
  }

  void _handleWsEvent(Map<String, dynamic> raw) {
    final e = LiveEvent.parse(raw);
    if (e == null) return;

    if (e.name == 'TimeChanged') {
      gameTime = e.intOf('newTime') ?? gameTime;
    } else if (e.name == 'DayStarted' || e.name == 'SaveLoaded') {
      gameTime = 600;
    } else if (e.name == 'ReturnedToTitle') {
      gameTime = null;
    } else if (e.name == 'PlayerWarped' && snapshot != null) {
      final to = e.strOf('newLocation');
      if (to.isNotEmpty) snapshot = snapshot!.withLocation(to);
    }

    final msg = hudMessageFor(e, place: (raw) => locationInfo(raw).displayName);
    if (msg != null) {
      hud.insert(0, msg);
      if (hud.length > 6) hud.removeRange(6, hud.length);
    }
    notifyListeners();
    if (e.needsSync) sync(silent: true);
  }

  void _startTimer() {
    _timer?.cancel();
    if (!connected || !store.apiAuto) return;
    final interval = snapshot == null
        ? const Duration(seconds: 3)
        : const Duration(seconds: 30);
    _timer = Timer.periodic(interval, (_) {
      if (connected && store.apiAuto) {
        final hadSnapshot = snapshot != null;
        sync(silent: true).then((ok) {
          if (ok && !hadSnapshot && snapshot != null) {
            _startTimer();
          }
        });
      }
    });
  }

  Set<String> _autoCollectedIds(ApiPlayer player, List<ApiItem> inventory) {
    final ids = <String>{};
    final index = _nameIndex ??= _buildNameIndex();

    for (final item in inventory) {
      for (final raw in [item.name, item.displayName]) {
        final key = normalize(raw.trim());
        if (key.isEmpty) continue;
        for (final entry in index[key] ?? const <Entry>[]) {
          if (_inventoryCategories.contains(entry.cat)) ids.add(entry.id);
        }
      }
    }

    final villagers = {
      for (final e in repo.byCat['aldeoes'] ?? const <Entry>[])
        normalize(e.en): e,
    };
    for (final rel in player.relationships) {
      final target = rel.isMarried ? 14 : 10;
      if (rel.hearts < target) continue;
      final entry = villagers[normalize(rel.npcName)];
      if (entry != null) ids.add(entry.id);
    }

    return ids;
  }

  Map<String, List<Entry>> _buildNameIndex() {
    final map = <String, List<Entry>>{};
    for (final entry in repo.all) {
      for (final raw in [entry.en, entry.pt]) {
        final key = normalize(raw.trim());
        if (key.isEmpty) continue;
        final list = map.putIfAbsent(key, () => <Entry>[]);
        if (!list.contains(entry)) list.add(entry);
      }
    }
    return map;
  }

  static String? normalizeBaseUrl(String raw) {
    var value = raw.trim();
    if (value.isEmpty) return null;
    if (!value.contains('://')) value = 'http://$value';

    final uri = Uri.tryParse(value);
    if (uri == null || uri.host.isEmpty) return null;
    if (uri.scheme != 'http' && uri.scheme != 'https') return null;

    final host = uri.host.contains(':') ? '[${uri.host}]' : uri.host;
    final port = uri.hasPort ? ':${uri.port}' : ':7882';
    return '${uri.scheme}://$host$port';
  }

  static String _friendlyError(ApiException e) {
    if (e.statusCode == 0) return e.message;
    if (e.statusCode == 400) return e.message;
    if (e.statusCode == 404) {
      return 'A API respondeu, mas o endereço não foi encontrado.';
    }
    return 'A API respondeu com erro ${e.statusCode}: ${e.message}';
  }

  static Future<dynamic> _getJson(String base, String path) async {
    final client = HttpClient()
      ..connectionTimeout = const Duration(seconds: 4)
      ..idleTimeout = const Duration(seconds: 4);
    try {
      final request = await client
          .getUrl(Uri.parse('$base$path'))
          .timeout(const Duration(seconds: 5));
      request.headers.set(HttpHeaders.acceptHeader, 'application/json');
      final response = await request.close().timeout(
        const Duration(seconds: 5),
      );
      final body = await response
          .transform(utf8.decoder)
          .join()
          .timeout(const Duration(seconds: 5));

      if (response.statusCode < 200 || response.statusCode >= 300) {
        var message = body.trim();
        try {
          final decoded = jsonDecode(body);
          if (decoded is Map && decoded['error'] is String) {
            message = decoded['error'] as String;
          }
        } catch (_) {}
        throw ApiException(
          response.statusCode,
          message.isEmpty ? 'sem detalhes' : message,
        );
      }

      return jsonDecode(body);
    } on TimeoutException {
      throw const ApiException(
        0,
        'A API não respondeu a tempo. Confira se o jogo está aberto.',
      );
    } on SocketException {
      throw const ApiException(
        0,
        'Não foi possível alcançar a API. Confira o IP, a porta 7882 e se o jogo está aberto.',
      );
    } on HttpException catch (e) {
      throw ApiException(0, 'Falha de rede ao falar com a API: ${e.message}');
    } finally {
      client.close(force: true);
    }
  }
}
