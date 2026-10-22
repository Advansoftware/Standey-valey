// Testes de interface: percorrem todas as telas do app e verificam que
// nada quebra (exceções) e que o conteúdo esperado aparece.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:stardew_guia/ai_service.dart';
import 'package:stardew_guia/app_scope.dart';
import 'package:stardew_guia/app_theme.dart';
import 'package:stardew_guia/repository.dart';
import 'package:stardew_guia/screens/about_screen.dart';
import 'package:stardew_guia/screens/assistant_screen.dart';
import 'package:stardew_guia/screens/category_screen.dart';
import 'package:stardew_guia/screens/detail_screen.dart';
import 'package:stardew_guia/screens/search_screen.dart';
import 'package:stardew_guia/screens/shell.dart';
import 'package:stardew_guia/search.dart';
import 'package:stardew_guia/store.dart';
import 'package:stardew_guia/widgets/common.dart';

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
Future<Store> pumpScreen(WidgetTester tester, Widget screen, {SearchService? search}) async {
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
      child: MaterialApp(theme: buildTheme(Brightness.light), home: screen),
    ),
  );
  await tester.pump();
  return s;
}

/// Rola a lista principal da tela até o fim.
Future<void> scrollMain(WidgetTester tester, {int times = 3, double dy = -350}) async {
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
    expect(s.wikiAvailable, isTrue, reason: 'assets/wiki/pages.json.gz deve existir');
    expect(s.pages.length, greaterThan(100));
    final hits = s.search('peixe');
    expect(hits, isNotEmpty);
    expect(hits.any((h) => h.doc.entryId == null), isTrue, reason: 'deve haver trechos da wiki');
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
    expect(find.byType(NavigationBar), findsOneWidget);
    // rola até as seções de baixo
    await scrollMain(tester, times: 4);
    expect(find.textContaining('Explorar'), findsOneWidget);
    expect(find.textContaining('Comece aqui'), findsOneWidget);
  });

  testWidgets('enciclopédia abre uma categoria com cartões', (tester) async {
    await pumpFullApp(tester);
    await tester.tap(find.text('Enciclopédia').last);
    await tester.pumpAndSettle();
    expect(find.byType(CategoryTile), findsWidgets);
    // a primeira categoria é o guia (lista); a segunda são as culturas (grade)
    await tester.tap(find.byType(CategoryTile).at(1));
    await tester.pumpAndSettle();
    expect(find.byType(DexCard), findsWidgets);
  });

  testWidgets('detalhe mostra dados, alterna coletado e favorita', (tester) async {
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

  testWidgets('calendário mostra a grade de 28 dias e os eventos', (tester) async {
    await pumpFullApp(tester);
    await tester.tap(find.text('Calendário').last);
    await tester.pumpAndSettle();
    expect(find.text('Eventos da estação'), findsOneWidget);
    expect(find.text('1'), findsWidgets);
    expect(find.text('28'), findsWidgets);
    expect(tester.takeException(), isNull);
  });

  testWidgets('assistente mostra o cartão de modelo e responde', (tester) async {
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

  testWidgets('assistente com pergunta inicial responde sozinho', (tester) async {
    await pumpScreen(tester, const AssistantScreen(initialQuestion: 'O que devo fazer no primeiro dia?'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Encontrei isto no guia'), findsOneWidget);
  });

  testWidgets('favoritos começa vazio e lista o que foi favoritado', (tester) async {
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

  testWidgets('a navegação inferior troca entre as 5 abas', (tester) async {
    await pumpFullApp(tester);
    for (final label in ['Enciclopédia', 'Calendário', 'Assistente', 'Favoritos', 'Início']) {
      await tester.tap(find.text(label).last);
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull, reason: label);
    }
  });

  testWidgets('a data do jogo muda pelo cartão "Hoje na fazenda"', (tester) async {
    final store = await pumpFullApp(tester);
    expect(store.day, 1);
    await tester.tap(find.byIcon(Icons.chevron_right_rounded).first);
    await tester.pumpAndSettle();
    expect(store.day, 2);
  });
}
