// Testes de interface: percorrem todas as telas do app e verificam que
// nada quebra (exceções) e que o conteúdo esperado aparece.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:stardew_guia/ai_service.dart';
import 'package:stardew_guia/app_scope.dart';
import 'package:stardew_guia/app_theme.dart';
import 'package:stardew_guia/game_api.dart';
import 'package:stardew_guia/repository.dart';
import 'package:stardew_guia/screens/about_screen.dart';
import 'package:stardew_guia/screens/assistant_screen.dart';
import 'package:stardew_guia/screens/category_screen.dart';
import 'package:stardew_guia/screens/detail_screen.dart';
import 'package:stardew_guia/screens/map_screen.dart';
import 'package:stardew_guia/screens/search_screen.dart';
import 'package:stardew_guia/screens/shell.dart';
import 'package:stardew_guia/screens/status_screen.dart';
import 'package:stardew_guia/search.dart';
import 'package:stardew_guia/store.dart';
import 'package:stardew_guia/updater_service.dart';
import 'package:stardew_guia/widgets/common.dart';
import 'package:stardew_guia/widgets/markdown_lite.dart';
import 'package:stardew_guia/widgets/stardew_ui.dart';

late Repository repo;

Future<Store> makeStore() async {
  SharedPreferences.setMockInitialValues({});
  return Store.withPrefs(await SharedPreferences.getInstance());
}

/// Janela alta para que todo o conteúdo da tela seja construído de uma vez.
void setBigScreen(WidgetTester tester) {
  tester.view.physicalSize = const Size(1200, 2600);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);
}

/// Monta o app inteiro (MaterialApp + AppScope) sem depender do `main`.
Future<Store> pumpFullApp(WidgetTester tester) async {
  setBigScreen(tester);
  final s = await makeStore();
  await tester.pumpWidget(
    AppScope(
      store: s,
      repo: repo,
      search: SearchService(repo),
      ai: AiService(),
      api: GameApi(s, repo),
      updater: UpdaterService(),
      child: Builder(
        builder: (context) => MaterialApp(
          theme: buildTheme(Brightness.light),
          home: const AppShell(),
        ),
      ),
    ),
  );
  await tester.pump();
  return s;
}

/// Monta uma tela isolada dentro do AppScope.
Future<Store> pumpScreen(
  WidgetTester tester,
  Widget screen, {
  SearchService? search,
}) async {
  setBigScreen(tester);
  final s = await makeStore();
  final svc = search ?? SearchService(repo);
  await tester.runAsync(() => svc.loadWiki());
  await tester.pumpWidget(
    AppScope(
      store: s,
      repo: repo,
      search: svc,
      ai: AiService(),
      api: GameApi(s, repo),
      updater: UpdaterService(),
      child: MaterialApp(theme: buildTheme(Brightness.light), home: screen),
    ),
  );
  await tester.pump();
  return s;
}

/// Rola a lista principal da tela até o fim.
Future<void> scrollMain(
  WidgetTester tester, {
  int times = 3,
  double dy = -350,
}) async {
  final list = find.byType(ListView).first;
  for (var i = 0; i < times; i++) {
    if (list.evaluate().isEmpty) return;
    await tester.drag(list, Offset(0, dy));
    await tester.pumpAndSettle();
  }
}

void main() {
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    repo = await Repository.load();
  });

  test('o conteúdo offline carrega com categorias e entradas', () {
    expect(repo.categories.length, greaterThan(10));
    expect(repo.all.length, greaterThan(300));
    expect(repo.byId.containsKey('crop_parsnip'), isTrue);
    expect(repo.category('culturas').title, isNotEmpty);
  });

  test('toda entrada tem imagem local ou emoji', () {
    for (final e in repo.all) {
      if (e.img.isNotEmpty) {
        expect(
          RegExp(r'\.(png|jpg|jpeg|gif)$').hasMatch(e.img),
          isTrue,
          reason: e.id,
        );
      } else {
        expect(e.emoji, isNotEmpty, reason: e.id);
      }
    }
  });

  test('a busca encontra o carvalho, o baiacu e a Abigail', () {
    final s = SearchService(repo);
    expect(s.search('carvalho').first.doc.entryId, 'tree_oak_tree');
    expect(s.search('baiacu').first.doc.entryId, 'fish_pufferfish');
    expect(s.search('Abigail').first.doc.entryId, contains('abigail'));
  });

  test('a wiki offline está embutida e responde às buscas', () async {
    final s = SearchService(repo);
    await s.loadWiki();
    expect(
      s.wikiAvailable,
      isTrue,
      reason: 'assets/wiki/pages.json.gz deve existir',
    );
    expect(s.pages.length, greaterThan(100));
    final hits = s.search('peixe');
    expect(hits, isNotEmpty);
    expect(
      hits.any((h) => h.doc.entryId == null),
      isTrue,
      reason: 'deve haver trechos da wiki',
    );
  });

  test('entradas sem tradução recebem o nome da wiki', () {
    final entry = repo.byId['fish_pufferfish'];
    expect(entry, isNotNull);
    expect(entry!.pt, isNotEmpty);
    expect(entry.pt, isNot(entry.en));
  });

  testWidgets('início mostra saudação, busca e atalhos', (tester) async {
    await pumpFullApp(tester);
    expect(find.text('Guia do Vale'), findsOneWidget);
    expect(find.text('Hoje na fazenda'), findsOneWidget);
    expect(find.byType(SdvNavBar), findsOneWidget);
    // rola até as seções de baixo
    await scrollMain(tester, times: 4);
    expect(find.textContaining('Explorar'), findsOneWidget);
    expect(find.textContaining('Comece aqui'), findsOneWidget);
  });

  testWidgets('enciclopédia abre uma categoria em lista por padrão', (
    tester,
  ) async {
    await pumpFullApp(tester);
    await tester.tap(find.text('Enciclopédia').last);
    await tester.pumpAndSettle();
    expect(find.byType(CategoryTile), findsWidgets);
    // a segunda categoria é a de culturas, que agora começa em lista
    await tester.tap(find.byType(CategoryTile).at(1));
    await tester.pumpAndSettle();
    expect(find.byType(EntryTile), findsWidgets);
    expect(find.byType(DexCard), findsNothing);
    // o botão de alternância continua levando para os cartões
    await tester.tap(find.byIcon(Icons.grid_view_rounded));
    await tester.pumpAndSettle();
    expect(find.byType(DexCard), findsWidgets);
    expect(find.byIcon(Icons.view_list_rounded), findsOneWidget);
  });

  testWidgets('mapa do vale mostra orientação, pinos e ficha do lugar', (
    tester,
  ) async {
    await pumpScreen(tester, const MapScreen());
    await tester.pumpAndSettle();
    expect(find.text('Como se orientar'), findsOneWidget);
    expect(find.byType(InteractiveViewer), findsOneWidget);
    expect(find.text('Sua fazenda'), findsWidgets);
    expect(find.text('Vila Pelicanos'), findsWidgets);
    expect(find.text('Praia'), findsWidgets);

    await tester.tap(find.text('Vila Pelicanos').last);
    await tester.pumpAndSettle();
    expect(find.text('O que tem'), findsOneWidget);
    expect(find.text('Como chegar'), findsOneWidget);
    expect(find.text('Página da wiki'), findsOneWidget);

    await tester.tap(find.text('Página da wiki'));
    await tester.pumpAndSettle();
    expect(find.text('Vila_Pelicanos'), findsOneWidget);
  });

  testWidgets('detalhe mostra dados, alterna coletado e favorita', (
    tester,
  ) async {
    final entry = repo.byId['crop_parsnip']!;
    final store = await pumpScreen(tester, DetailScreen(entry: entry));
    await tester.pump();
    expect(find.text(entry.name), findsWidgets);
    expect(find.text(entry.numberLabel), findsOneWidget);

    final switchFinder = find.byType(SwitchListTile);
    if (switchFinder.evaluate().isNotEmpty) {
      await tester.tap(switchFinder);
      await tester.pump();
      expect(store.isCollected(entry.id), isTrue);
    }
    await tester.tap(find.byIcon(Icons.star_border_rounded));
    await tester.pump();
    expect(find.byIcon(Icons.star_rounded), findsOneWidget);
    expect(store.isFav(entry.id), isTrue);

    // botão de perguntar à IA fica no fim da tela
    await scrollMain(tester);
    expect(find.text('Perguntar à IA'), findsOneWidget);
  });

  testWidgets('a galeria de estágios aparece no detalhe', (tester) async {
    final entry = repo.byId['tree_oak_tree']!;
    expect(entry.gallery.length, greaterThan(1));
    await pumpScreen(tester, DetailScreen(entry: entry));
    await tester.pump();
    expect(find.byType(Image), findsWidgets);
    expect(tester.takeException(), isNull);
  });

  testWidgets('filtro por texto na categoria', (tester) async {
    await pumpScreen(tester, CategoryScreen(cat: repo.category('peixes')));
    await tester.pump();
    await tester.enterText(find.byType(TextField).first, 'baiacu');
    await tester.pumpAndSettle();
    expect(find.text('Baiacu'), findsWidgets);
    expect(tester.takeException(), isNull);
  });

  testWidgets('busca global retorna resultados', (tester) async {
    await pumpScreen(tester, const SearchScreen());
    await tester.pump();
    await tester.enterText(find.byType(TextField).first, 'carvalho');
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('Carvalho'), findsWidgets);
  });

  testWidgets('calendário abre pelo atalho da home e mostra os eventos', (
    tester,
  ) async {
    await pumpFullApp(tester);
    await tester.tap(find.byTooltip('Calendário'));
    await tester.pumpAndSettle();
    expect(find.text('Eventos da estação'), findsOneWidget);
    expect(find.text('1'), findsWidgets);
    expect(find.text('28'), findsWidgets);
    expect(tester.takeException(), isNull);
  });

  testWidgets('assistente mostra o cartão de modelo e responde', (
    tester,
  ) async {
    await pumpFullApp(tester);
    await tester.tap(find.text('Assistente').last);
    await tester.pumpAndSettle();
    expect(find.textContaining('IA no seu celular'), findsOneWidget);
    expect(find.textContaining('Gemma 4 E4B'), findsWidgets);
    expect(find.textContaining('Recomendado'), findsWidgets);
    // as sugestões ficam abaixo do cartão de modelo
    await scrollMain(tester, times: 2);
    expect(find.text('Qual árvore é o carvalho?'), findsOneWidget);
    await tester.tap(find.text('Qual árvore é o carvalho?'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Encontrei isto no guia'), findsOneWidget);
  });

  testWidgets('assistente com pergunta inicial responde sozinho', (
    tester,
  ) async {
    await pumpScreen(
      tester,
      const AssistantScreen(
        initialQuestion: 'O que devo fazer no primeiro dia?',
      ),
    );
    await tester.pumpAndSettle();
    expect(find.textContaining('Encontrei isto no guia'), findsOneWidget);
  });

  testWidgets('favoritos começa vazio e lista o que foi favoritado', (
    tester,
  ) async {
    final store = await pumpFullApp(tester);
    await tester.tap(find.text('Favoritos').last);
    await tester.pumpAndSettle();
    expect(find.textContaining('Nada por aqui ainda'), findsOneWidget);

    store.toggleFav('crop_parsnip');
    await tester.pumpAndSettle();
    expect(find.text('Pastinaca'), findsOneWidget);
  });

  testWidgets('sobre: troca de tema e mostra créditos', (tester) async {
    final store = await pumpScreen(tester, const AboutScreen());
    await tester.pump();
    expect(find.text('Créditos e avisos'), findsOneWidget);
    expect(find.textContaining('ConcernedApe'), findsOneWidget);
    await tester.tap(find.text('Escuro'));
    await tester.pumpAndSettle();
    expect(store.themeMode, ThemeMode.dark);
  });

  testWidgets('a navegação inferior troca entre as abas disponíveis', (
    tester,
  ) async {
    await pumpFullApp(tester);
    for (final label in ['Enciclopédia', 'Assistente', 'Favoritos', 'Início']) {
      await tester.tap(find.text(label).last);
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull, reason: label);
    }
  });

  testWidgets('Meu Status fica travado enquanto a API não está conectada', (
    tester,
  ) async {
    await pumpFullApp(tester);
    expect(find.text('Meu Status'), findsOneWidget);
    expect(find.byIcon(Icons.lock_rounded), findsOneWidget);
    await tester.tap(find.text('Meu Status'));
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.textContaining('Conecte ao servidor'), findsOneWidget);
    expect(find.byType(StatusScreen), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Meu Status abre em tela cheia quando a API está conectada', (
    tester,
  ) async {
    setBigScreen(tester);
    final store = await makeStore();
    final api = GameApi(store, repo)
      ..connected = true
      ..snapshot = const ApiSnapshot(
        world: ApiWorld(
          season: 0,
          day: 1,
          year: 1,
          weather: 'Sunny',
          farmName: 'Fazenda',
        ),
        player: ApiPlayer(
          name: 'Bruno',
          farmName: 'Fazenda',
          money: 1234,
          location: 'Farm',
          relationships: [],
        ),
        inventory: [],
      );
    addTearDown(api.dispose);
    await tester.pumpWidget(
      AppScope(
        store: store,
        repo: repo,
        search: SearchService(repo),
        ai: AiService(),
        api: api,
        updater: UpdaterService(),
        child: MaterialApp(
          theme: buildTheme(Brightness.light),
          home: const AppShell(),
        ),
      ),
    );
    await tester.pump();
    expect(find.byIcon(Icons.lock_rounded), findsNothing);
    await tester.tap(find.text('Meu Status'));
    await tester.pumpAndSettle();
    expect(find.byType(StatusScreen), findsOneWidget);
    // HUD do jogo: barras de energia e vida, e o Conselheiro aberto
    expect(find.byType(SdvVitalBar), findsNWidgets(2));
    expect(find.text('Conselheiro'), findsWidgets);
    expect(find.text('AJUDA'), findsOneWidget);
    await tester.tap(find.text('✕').first);
    await tester.pumpAndSettle();
    expect(find.byType(StatusScreen), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('o conselheiro só roda no botão e mostra objetivos em cartões', (
    tester,
  ) async {
    setBigScreen(tester);
    final store = await makeStore();
    store.setAiInstalled(true);
    final ai = _FakeAi();
    final api = GameApi(store, repo)
      ..connected = true
      ..snapshot = const ApiSnapshot(
        world: ApiWorld(
          season: 0,
          day: 1,
          year: 1,
          weather: 'Sunny',
          farmName: 'Fazenda',
        ),
        player: ApiPlayer(
          name: 'Bruno',
          farmName: 'Fazenda',
          money: 1234,
          location: 'Farm',
          relationships: [],
        ),
        inventory: [],
      );
    addTearDown(api.dispose);
    await tester.pumpWidget(
      AppScope(
        store: store,
        repo: repo,
        search: SearchService(repo),
        ai: ai,
        api: api,
        updater: UpdaterService(),
        child: MaterialApp(
          theme: buildTheme(Brightness.light),
          home: const StatusScreen(),
        ),
      ),
    );
    await tester.pump();
    expect(ai.calls, 0, reason: 'a IA não pode rodar sozinha ao abrir a tela');

    await tester.tap(find.text('AJUDA'));
    await tester.pumpAndSettle();

    expect(ai.calls, 1);
    expect(find.text('Plano do conselheiro para agora:'), findsOneWidget);
    expect(find.text('Regar as plantas'), findsOneWidget);
    expect(find.textContaining('Fazenda'), findsWidgets);
    expect(find.text('Visitar a Abigail'), findsOneWidget);
    expect(find.textContaining('Vila Pelicanos'), findsWidgets);
    expect(find.text('Minerar cobre'), findsOneWidget);
    expect(find.textContaining('Falta cobre'), findsOneWidget);

    await tester.pump(const Duration(seconds: 2));
    expect(ai.calls, 1, reason: 'sem polling nem chamadas repetidas');
  });

  testWidgets('a data do jogo muda pelo cartão "Hoje na fazenda"', (
    tester,
  ) async {
    final store = await pumpFullApp(tester);
    expect(store.day, 1);
    await tester.tap(
      find.widgetWithIcon(IconButton, Icons.chevron_right_rounded),
    );
    await tester.pumpAndSettle();
    expect(store.day, 2);
    // O texto do cartão precisa refletir a mudança sem sair da tela.
    expect(find.textContaining('Primavera 2'), findsWidgets);
  });

  testWidgets('o slider da data atualiza o cartão na hora', (tester) async {
    final store = await pumpFullApp(tester);
    expect(find.byType(Slider), findsOneWidget);
    await tester.drag(find.byType(Slider), const Offset(360, 0));
    await tester.pumpAndSettle();
    expect(store.day, greaterThan(1));
    expect(find.textContaining('Primavera ${store.day}'), findsWidgets);
  });

  testWidgets('o calendário acompanha a estação escolhida no início', (
    tester,
  ) async {
    final store = await pumpFullApp(tester);
    await tester.tap(find.byTooltip('Calendário'));
    await tester.pumpAndSettle();
    // Muda a data em outra tela (como o slider/chips do início fariam).
    store.setDate(1, 10);
    await tester.pumpAndSettle();
    final chip = tester.widget<ChoiceChip>(
      find.widgetWithText(ChoiceChip, '☀️ Verão'),
    );
    expect(chip.selected, isTrue);
    expect(tester.takeException(), isNull);
  });

  test('todo item tem utilidade e toda árvore tem preço de venda', () {
    for (final cat in repo.categories) {
      if (cat.id == 'guia') continue;
      for (final e in repo.byCat[cat.id]!) {
        expect(
          e.fields.any((f) => f[0] == 'Utilidade'),
          isTrue,
          reason: '${cat.id}/${e.id} sem Utilidade',
        );
      }
    }
    for (final e in repo.byCat['arvores']!) {
      expect(
        e.fields.any((f) => f[0].startsWith('Preço de venda')),
        isTrue,
        reason: '${e.id} sem preço de venda',
      );
    }
  });

  test(
    'o guia das árvores responde deixar, plantar e vantagens do pinheiro',
    () {
      final guia = repo.byId['guia_arvores_cultivo'];
      expect(guia, isNotNull);
      expect(guia!.body, contains('Devo deixar as árvores'));
      expect(guia.body, contains('Vantagens de plantar um pinheiro'));
      expect(guia.body, contains('Alcatrão de Pinho'));
      final pinheiro = repo.byId['tree_pine_tree'];
      expect(pinheiro, isNotNull);
      expect(pinheiro!.fields.any((f) => f[0] == 'Utilidade'), isTrue);
      expect(
        pinheiro.fields.any((f) => f[0].contains('Preço de venda')),
        isTrue,
      );
    },
  );

  test('o guia de lavouras explica rega, espantalho e fim de estação', () {
    final guia = repo.byId['guia_lavoura'];
    expect(guia, isNotNull);
    expect(guia!.name, contains('Lavouras'));
    expect(guia.body.toLowerCase(), contains('regue todos os dias'));
    expect(guia.body.toLowerCase(), contains('espantalho'));
    expect(guia.body.toLowerCase(), contains('dia 28'));
    expect(guia.body.toLowerCase(), contains('treliça'));
    expect(guia.img, isNotEmpty);
  });

  test('a busca por vantagens do pinheiro encontra o guia', () {
    final s = SearchService(repo);
    final hits = s.search(
      'quais as vantagens de plantar um pinheiro',
      limit: 8,
    );
    expect(hits.any((h) => h.doc.entryId == 'guia_arvores_cultivo'), isTrue);
    expect(hits.first.doc.entryId, 'guia_arvores_cultivo');
    expect(hits, isNotEmpty);
  });

  test('pergunta natural sobre o pinheiro acha a ficha do pinheiro', () {
    final hits = SearchService(
      repo,
    ).search('Me explique sobre Pinheiro', limit: 5);
    expect(hits, isNotEmpty);
    expect(hits.first.doc.entryId, 'tree_pine_tree');
  });

  test('o prompt da IA pede utilidade, preço e prós e contras', () {
    final hits = SearchService(repo).search('pinheiro', limit: 4);
    final prompt = buildPrompt(
      'quais as vantagens de plantar um pinheiro',
      hits,
    );
    expect(prompt, contains('Utilidade'));
    expect(prompt, contains('Preço de venda'));
    expect(prompt, contains('prós e contras'));
  });

  testWidgets('o chat renderiza negrito, itálico e listas sem asteriscos', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: MarkdownLite(
            '*Olá!* **Utilidade:**\n* Primeiro item\n* Segundo item',
          ),
        ),
      ),
    );
    final st = tester.widget<SelectableText>(find.byType(SelectableText));
    final plain = st.textSpan!.toPlainText();
    expect(plain, contains('Olá!'));
    expect(plain, contains('Utilidade:'));
    expect(plain, contains('Primeiro item'));
    expect(plain, contains('•'));
    expect(plain, isNot(contains('*')));
  });
}

class _FakeAi extends AiService {
  _FakeAi() {
    engineReady = true;
  }

  int calls = 0;

  @override
  Stream<String> ask(String prompt, {bool exact = false}) async* {
    calls++;
    yield '1. Regar as plantas | Fazenda | O dia está ensolarado\n';
    yield '2. Visitar a Abigail | Vila Pelicanos | Ela está quase no próximo coração\n';
    yield '3. Minerar cobre | Minas | Falta cobre para a melhoria\n';
  }
}
