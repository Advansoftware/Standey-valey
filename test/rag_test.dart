import 'package:flutter_test/flutter_test.dart';
import 'package:stardew_guia/ai_cloud.dart';
import 'package:stardew_guia/ai_rag.dart';
import 'package:stardew_guia/repository.dart';
import 'package:stardew_guia/search.dart';

/// Perguntas reais, escritas como um jogador escreve, que a busca antiga
/// respondia com falas de moradores em vez da página do assunto.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late SearchService search;

  setUpAll(() async {
    search = SearchService(await Repository.load());
    await search.loadWiki();
  });

  String top(String q, [List<ChatTurn> history = const []]) {
    final h = retrieveForChat(search, q, history, limit: 12).first.doc;
    return h.pageTitle ?? search.entryOf(h)!.name;
  }

  test('a pergunta longa acha a página do assunto', () {
    expect(top('estou tentando fazer uma fornalha no stardew valley mas não consigo o que faço para forçar acontecer?'),
        'Fornalha');
    expect(top('onde consigo argila, to travado com 5 faz tempo mesmo mineirando'), 'Argila');
    expect(top('como colocar isca na vara'), 'Isca');
    expect(
      retrieveForChat(search, 'eu tenho um galinheiro com até 4 galinhas, quero comprar um que caiba 8 da pra demolir e comprar?',
              const [], limit: 12)
          .take(4)
          .map((h) => h.doc.pageTitle),
      contains('Galinheiro'),
    );
    expect(
      top('estou no festival do vale do orvalho la pedia para eu levar 9 itens bons mas o que eu faço com eles?'),
      'Feira do Vale Stardew',
    );
  });

  test('falas de morador não tomam o lugar do assunto', () {
    final hits = retrieveForChat(search, 'estou tentando fazer uma fornalha mas não consigo', const [], limit: 12);
    expect(hits.take(6).where((h) => '“'.allMatches(h.doc.text).length >= 3), isEmpty);
  });

  test('pergunta de continuação usa o assunto anterior', () {
    final hits = retrieveForChat(search, 'e quanto custa?', const [
      ChatTurn(true, 'como faço o galinheiro grande?'),
      ChatTurn(false, 'Na Carpintaria da Robin.'),
    ]);
    expect(hits.map((h) => h.doc.pageTitle), contains('Galinheiro'));
    final carvao = retrieveForChat(search, 'e depois, quanto carvao ela gasta?', const [
      ChatTurn(true, 'como faco para liberar a fornalha'),
      ChatTurn(false, 'Pegue 1 Minério de Cobre.'),
    ]);
    expect(carvao.take(5).map((h) => h.doc.pageTitle), contains('Fornalha'));
  });

  test('o contexto web traz a página inteira do assunto', () {
    final hits = retrieveForChat(search, 'onde consigo argila', const [], limit: 12);
    final ctx = buildCloudContext(search, hits);
    expect(ctx, contains('Argila'));
    expect(ctx.length, lessThanOrEqualTo(24000 + 2600));
  });
}
