import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import 'models.dart';
import 'repository.dart';
import 'search.dart';
import 'store.dart';

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

  const DiscoveredServer({required this.name, required this.host, required this.port});

  String get url => host.contains(':') ? 'http://[$host]:$port' : 'http://$host:$port';
}

class ApiWorld {
  final int season;
  final int day;
  final int year;
  final String weather;
  final String farmName;
  final String? festival;

  const ApiWorld({
    required this.season,
    required this.day,
    required this.year,
    required this.weather,
    required this.farmName,
    this.festival,
  });

  factory ApiWorld.fromJson(Map<String, dynamic> j) {
    final today = (j['today'] as Map?)?.cast<String, dynamic>() ?? const <String, dynamic>{};
    final date = (today['date'] as Map?)?.cast<String, dynamic>() ?? const <String, dynamic>{};
    final seasonName = (date['season'] as String?) ?? 'Spring';
    return ApiWorld(
      season: seasonFromApi(seasonName),
      day: (date['day'] as num?)?.toInt() ?? 1,
      year: (date['year'] as num?)?.toInt() ?? 1,
      weather: (today['weather'] as String?) ?? '',
      farmName: (j['farmName'] as String?) ?? '',
      festival: today['festival'] as String?,
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

class ApiRelationship {
  final String npcName;
  final int hearts;
  final bool isMarried;

  const ApiRelationship({
    required this.npcName,
    required this.hearts,
    required this.isMarried,
  });

  factory ApiRelationship.fromJson(Map<String, dynamic> j) {
    final npc = (j['npc'] as Map?)?.cast<String, dynamic>() ?? const <String, dynamic>{};
    return ApiRelationship(
      npcName: (npc['name'] as String?) ?? '',
      hearts: (j['hearts'] as num?)?.toInt() ?? 0,
      isMarried: (j['isMarried'] as bool?) ?? false,
    );
  }
}

class ApiPlayer {
  final String name;
  final String farmName;
  final int money;
  final String location;
  final List<ApiRelationship> relationships;

  const ApiPlayer({
    required this.name,
    required this.farmName,
    required this.money,
    required this.location,
    required this.relationships,
  });

  factory ApiPlayer.fromJson(Map<String, dynamic> j) {
    return ApiPlayer(
      name: (j['name'] as String?) ?? '',
      farmName: (j['farmName'] as String?) ?? '',
      money: (j['money'] as num?)?.toInt() ?? 0,
      location: (j['location'] as String?) ?? '',
      relationships: ((j['relationships'] as List?) ?? const [])
          .whereType<Map>()
          .map((e) => ApiRelationship.fromJson(e.cast<String, dynamic>()))
          .toList(),
    );
  }
}

class ApiItem {
  final String name;
  final String displayName;
  final String qualifiedItemId;
  final int stackSize;

  const ApiItem({
    required this.name,
    required this.displayName,
    required this.qualifiedItemId,
    required this.stackSize,
  });

  factory ApiItem.fromJson(Map<String, dynamic> j) {
    return ApiItem(
      name: (j['name'] as String?) ?? '',
      displayName: (j['displayName'] as String?) ?? '',
      qualifiedItemId: (j['qualifiedItemId'] as String?) ?? '',
      stackSize: (j['stackSize'] as num?)?.toInt() ?? 0,
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
  Map<String, List<Entry>>? _nameIndex;
  Timer? _timer;
  bool _syncing = false;
  bool _observing = false;
  int _session = 0;

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
        out.add(DiscoveredServer(
          name: (item['name'] as String?) ?? 'Stardew Web API',
          host: host,
          port: port,
        ));
      }
      return out;
    } on MissingPluginException {
      error = 'Busca automática indisponível neste aparelho. Informe o endereço.';
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
        throw const ApiException(0, 'O endereço respondeu, mas não parece ser a Stardew Web API.');
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
      await sync(silent: silent);
      return true;
    } on ApiException catch (e) {
      connected = false;
      error = _friendlyError(e);
      _timer?.cancel();
      return false;
    } catch (e) {
      connected = false;
      error = 'Não foi possível conectar à API: $e';
      _timer?.cancel();
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

      final world = ApiWorld.fromJson((results[0] as Map).cast<String, dynamic>());
      final player = ApiPlayer.fromJson((results[1] as Map).cast<String, dynamic>());
      final inventory = ((results[2] as List?) ?? const [])
          .whereType<Map>()
          .map((e) => ApiItem.fromJson(e.cast<String, dynamic>()))
          .toList();

      snapshot = ApiSnapshot(world: world, player: player, inventory: inventory);
      store.setDate(world.season, world.day);

      final ids = _autoCollectedIds(player, inventory);
      lastAutoMarked = store.addCollected(ids);
      lastSync = DateTime.now();
      store.setApiLastSync(lastSync);
      error = null;
      return true;
    } on ApiException catch (e) {
      if (e.statusCode == 400 && e.message.toLowerCase().contains('no save loaded')) {
        error = 'API conectada. Carregue um save no jogo para sincronizar o progresso.';
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

  void _startTimer() {
    _timer?.cancel();
    if (!connected || !store.apiAuto) return;
    _timer = Timer.periodic(const Duration(seconds: 60), (_) {
      if (connected && store.apiAuto) sync(silent: true);
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
      for (final e in repo.byCat['aldeoes'] ?? const <Entry>[]) normalize(e.en): e,
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
      final response = await request.close().timeout(const Duration(seconds: 5));
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
        throw ApiException(response.statusCode, message.isEmpty ? 'sem detalhes' : message);
      }

      return jsonDecode(body);
    } on TimeoutException {
      throw const ApiException(0, 'A API não respondeu a tempo. Confira se o jogo está aberto.');
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
