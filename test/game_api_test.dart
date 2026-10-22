// Testes da integração opcional com a Stardew Web API.
//
// Cada teste sobe um HttpServer local (porta 0) na interface de loopback:
// nenhuma requisição sai para a rede externa.
import 'dart:convert';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:stardew_guia/game_api.dart';
import 'package:stardew_guia/repository.dart';
import 'package:stardew_guia/store.dart';

late Repository repo;
late Store store;

const Map<String, dynamic> _worldJson = {
  'today': {
    'date': {'season': 'Spring', 'day': 12, 'year': 1},
    'weather': 'Sunny',
    'festival': null,
  },
  'farmName': 'Fazenda',
};

const Map<String, dynamic> _playerJson = {
  'name': 'Bruno',
  'farmName': 'Fazenda',
  'money': 1000,
  'location': 'Farm',
  'relationships': [
    {
      'npc': {'name': 'Abigail'},
      'hearts': 10,
      'isMarried': false,
    },
    {
      'npc': {'name': 'Penny'},
      'hearts': 14,
      'isMarried': true,
    },
    // Casado, mas ainda com 10 corações: não é amizade máxima.
    {
      'npc': {'name': 'Sebastian'},
      'hearts': 10,
      'isMarried': true,
    },
  ],
};

const List<Map<String, dynamic>> _inventoryJson = [
  // Uma de cada categoria que o inventário comprova.
  {
    'name': 'Pufferfish',
    'displayName': 'Baiacu',
    'qualifiedItemId': '(O)128',
    'stackSize': 1,
  },
  {
    'name': 'Wild Horseradish',
    'displayName': 'Raiz-forte selvagem',
    'qualifiedItemId': '(O)16',
    'stackSize': 2,
  },
  {
    'name': 'Quartz',
    'displayName': 'Quartzo',
    'qualifiedItemId': '(O)80',
    'stackSize': 5,
  },
  {
    'name': 'Fried Egg',
    'displayName': 'Ovo frito',
    'qualifiedItemId': '(O)194',
    'stackSize': 1,
  },
  {
    'name': 'Hoe',
    'displayName': 'Enxada',
    'qualifiedItemId': '(T)Hoe',
    'stackSize': 1,
  },
  // Cultura: ter na mochila não prova que já foi plantada/colhida.
  {
    'name': 'Parsnip',
    'displayName': 'Pastinaca',
    'qualifiedItemId': '(O)24',
    'stackSize': 3,
  },
];

/// Stardew Web API falsa, servida apenas no loopback.
class FakeStardewApi {
  FakeStardewApi._(this._server);

  final HttpServer _server;

  String get baseUrl => 'http://${_server.address.address}:${_server.port}';

  Future<void> close() => _server.close(force: true);

  static Future<FakeStardewApi> start({
    bool noSave = false,
    bool healthIsNotList = false,
    Map<String, dynamic>? world,
    Map<String, dynamic>? player,
    List<Map<String, dynamic>>? inventory,
  }) async {
    final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    server.listen((request) async {
      final response = request.response;
      response.headers.contentType = ContentType.json;

      void reply(Object body, [int status = HttpStatus.ok]) {
        response.statusCode = status;
        response.write(jsonEncode(body));
      }

      final path = request.uri.path;
      if (noSave && path != '/api/v1/mods') {
        reply({
          'error': 'No save loaded. Please load a save and try again.',
        }, HttpStatus.badRequest);
      } else {
        switch (path) {
          case '/api/v1/mods':
            reply(
              healthIsNotList
                  ? {'ok': true}
                  : [
                      {'name': 'Stardew Web API', 'version': '1.0.0'},
                    ],
            );
          case '/api/v1/world':
            reply(world ?? _worldJson);
          case '/api/v1/players/main':
            reply(player ?? _playerJson);
          case '/api/v1/players/main/inventory':
            reply(inventory ?? _inventoryJson);
          default:
            reply({'error': 'not found'}, HttpStatus.notFound);
        }
      }

      await response.close();
    });
    return FakeStardewApi._(server);
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  // O binding de teste instala um HttpClient falso que responde 400 a tudo.
  // Estes testes precisam falar com o HttpServer local de verdade.
  HttpOverrides.global = null;

  setUpAll(() async {
    repo = await Repository.load();
  });

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    store = Store.withPrefs(await SharedPreferences.getInstance());
  });

  test(
    'normalizeBaseUrl aceita formatos comuns e rejeita endereços inválidos',
    () {
      expect(
        GameApi.normalizeBaseUrl('192.168.0.10'),
        'http://192.168.0.10:7882',
      );
      expect(
        GameApi.normalizeBaseUrl('192.168.0.10:7882'),
        'http://192.168.0.10:7882',
      );
      expect(
        GameApi.normalizeBaseUrl('http://192.168.0.10'),
        'http://192.168.0.10:7882',
      );
      expect(
        GameApi.normalizeBaseUrl('http://192.168.0.10:7882/'),
        'http://192.168.0.10:7882',
      );
      expect(
        GameApi.normalizeBaseUrl('  http://192.168.0.10:7882  '),
        'http://192.168.0.10:7882',
      );
      expect(
        GameApi.normalizeBaseUrl('https://stardew.local:9000'),
        'https://stardew.local:9000',
      );

      expect(GameApi.normalizeBaseUrl(''), isNull);
      expect(GameApi.normalizeBaseUrl('   '), isNull);
      expect(GameApi.normalizeBaseUrl('ftp://192.168.0.10'), isNull);
      expect(GameApi.normalizeBaseUrl('http://'), isNull);
    },
  );

  test('ApiPlayer aceita o tipo do NPC como texto, número ou ausente', () {
    final player = ApiPlayer.fromJson({
      'name': 'Bruno',
      'relationships': [
        {
          'npc': {'name': 'Abigail', 'type': 'Villager'},
          'hearts': 10,
        },
        {
          'npc': {'name': 'Penny', 'type': 1},
          'hearts': 8,
        },
        {
          'npc': {'name': 'Sam'},
          'hearts': 4,
        },
      ],
    });

    expect(player.relationships, hasLength(3));
    expect(player.relationships[0].npcType, 'Villager');
    expect(player.relationships[1].npcType, '1');
    expect(player.relationships[2].npcType, isEmpty);
  });

  test('ApiWorld converte a estação da API para o índice do app', () {
    final world = ApiWorld.fromJson({
      'today': {
        'date': {'season': 'Fall', 'day': 5, 'year': 2},
        'weather': 'Rain',
        'festival': 'Feira da Lua',
      },
      'farmName': 'Fazenda',
    });

    expect(world.season, 2);
    expect(world.day, 5);
    expect(world.year, 2);
    expect(world.weather, 'Rain');
    expect(world.farmName, 'Fazenda');
    expect(world.festival, 'Feira da Lua');

    expect(seasonFromApi('Summer'), 1);
    expect(seasonFromApi('Autumn'), 2);
    expect(seasonFromApi('Winter'), 3);
    expect(seasonFromApi('Spring'), 0);
    expect(seasonFromApi('desconhecida'), 0);
  });

  test(
    'connect sincroniza data, inventário e aldeões de amizade máxima',
    () async {
      final server = await FakeStardewApi.start();
      addTearDown(server.close);
      final api = GameApi(store, repo);
      addTearDown(api.dispose);

      // Progresso manual antigo: não pode ser desmarcado pela API.
      store.toggleCollected('fish_tuna');

      final ok = await api.connect(server.baseUrl, name: 'PC da sala');

      expect(ok, isTrue);
      expect(api.connected, isTrue);
      expect(api.error, isNull);
      expect(api.baseUrl, server.baseUrl);
      expect(store.apiUrl, server.baseUrl);
      expect(store.apiName, 'PC da sala');
      expect(store.apiAuto, isTrue);

      // Data do jogo vinda de /api/v1/world.
      expect(store.season, 0);
      expect(store.day, 12);

      final snapshot = api.snapshot;
      expect(snapshot, isNotNull);
      expect(snapshot!.world.weather, 'Sunny');
      expect(snapshot.world.farmName, 'Fazenda');
      expect(snapshot.player.name, 'Bruno');
      expect(snapshot.player.money, 1000);
      expect(snapshot.player.relationships, hasLength(3));
      expect(snapshot.inventory, hasLength(6));
      expect(snapshot.inventory.first.name, 'Pufferfish');
      expect(snapshot.inventory.first.displayName, 'Baiacu');

      // Itens de categorias em que estar no inventário comprova o progresso.
      for (final id in [
        'fish_pufferfish',
        'forage_wild_horseradish',
        'min_quartz80',
        'cook_fried_egg',
        'tool_hoe',
      ]) {
        expect(store.isCollected(id), isTrue, reason: id);
      }

      // Cultura no inventário não marca a ficha.
      expect(store.isCollected('crop_parsnip'), isFalse);

      // 10 corações (solteiro), 14 (casado) marcam; casado com 10 não marca.
      expect(store.isCollected('vill_abigail'), isTrue);
      expect(store.isCollected('vill_penny'), isTrue);
      expect(store.isCollected('vill_sebastian'), isFalse);

      // A sincronização nunca desmarca o progresso manual.
      expect(store.isCollected('fish_tuna'), isTrue);

      expect(api.lastSync, isNotNull);
      expect(store.apiLastSyncMs, greaterThan(0));
      expect(api.lastAutoMarked, greaterThanOrEqualTo(7));
    },
  );

  test(
    'itens fora das categorias automáticas não são marcados só por estar na mochila',
    () async {
      final server = await FakeStardewApi.start(
        inventory: const [
          {
            'name': 'Parsnip',
            'displayName': 'Pastinaca',
            'qualifiedItemId': '(O)24',
            'stackSize': 3,
          },
        ],
        player: const {
          'name': 'Bruno',
          'farmName': 'Fazenda',
          'money': 1000,
          'location': 'Farm',
          'relationships': <Map<String, dynamic>>[],
        },
      );
      addTearDown(server.close);
      final api = GameApi(store, repo);
      addTearDown(api.dispose);

      final ok = await api.connect(server.baseUrl);

      expect(ok, isTrue);
      expect(api.connected, isTrue);
      expect(api.snapshot!.inventory.single.name, 'Parsnip');
      expect(store.isCollected('crop_parsnip'), isFalse);
      expect(store.collected, isEmpty);
      expect(api.lastAutoMarked, 0);
      expect(api.lastSync, isNotNull);
    },
  );

  test(
    'erro 400 sem save mantém a conexão e mostra mensagem amigável',
    () async {
      final server = await FakeStardewApi.start(noSave: true);
      addTearDown(server.close);
      final api = GameApi(store, repo);
      addTearDown(api.dispose);

      await api.connect(server.baseUrl);

      // O health check passou, então a API continua conectada mesmo sem save.
      expect(api.connected, isTrue);
      expect(api.baseUrl, server.baseUrl);
      expect(
        api.error,
        'API conectada. Carregue um save no jogo para sincronizar o progresso.',
      );
      expect(api.error, isNot(contains('No save loaded')));

      // Nada de progresso/data foi aplicado.
      expect(api.snapshot, isNull);
      expect(api.lastSync, isNull);
      expect(store.apiLastSyncMs, 0);
      expect(store.season, 0);
      expect(store.day, 1);
      expect(store.collected, isEmpty);
    },
  );

  test(
    'disconnect limpa URL, nome, modo automático e última sincronização',
    () async {
      final server = await FakeStardewApi.start();
      addTearDown(server.close);
      final api = GameApi(store, repo);
      addTearDown(api.dispose);

      await api.connect(server.baseUrl, name: 'PC da sala');
      expect(api.connected, isTrue);
      expect(store.apiUrl, server.baseUrl);
      expect(store.apiAuto, isTrue);

      api.disconnect();

      expect(api.baseUrl, isEmpty);
      expect(api.connected, isFalse);
      expect(api.snapshot, isNull);
      expect(api.error, isNull);
      expect(api.lastSync, isNull);
      expect(api.lastAutoMarked, 0);
      expect(store.apiUrl, isEmpty);
      expect(store.apiName, isEmpty);
      expect(store.apiAuto, isFalse);
      expect(store.apiLastSyncMs, 0);
    },
  );

  test(
    'discover converte a resposta NSD em DiscoveredServer e ignora entradas inválidas',
    () async {
      const channel = MethodChannel('guia_do_vale/nsd');
      final messenger =
          TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;

      messenger.setMockMethodCallHandler(channel, (call) async {
        expect(call.method, 'discover');
        return [
          {'name': 'PC do Bruno', 'host': '192.168.0.10', 'port': 7882},
          // Sem nome: usa o padrão.
          {'host': '192.168.0.20', 'port': 7882},
          // Sem host ou com porta inválida: descartados.
          {'name': 'Sem host', 'port': 7882},
          {'name': 'Sem porta', 'host': '192.168.0.30'},
          {'name': 'Porta zero', 'host': '192.168.0.40', 'port': 0},
          'lixo',
        ];
      });
      addTearDown(() {
        messenger.setMockMethodCallHandler(channel, null);
      });

      final api = GameApi(store, repo);
      addTearDown(api.dispose);

      final found = await api.discover();

      expect(found, hasLength(2));
      expect(found[0].name, 'PC do Bruno');
      expect(found[0].host, '192.168.0.10');
      expect(found[0].port, 7882);
      expect(found[0].url, 'http://192.168.0.10:7882');
      expect(found[1].name, 'Stardew Web API');
      expect(found[1].host, '192.168.0.20');
      expect(api.error, isNull);
      expect(api.scanning, isFalse);
    },
  );
}
