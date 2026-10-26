import 'package:flutter/painting.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stardew_guia/search_snippet.dart';

const _missoes = 'Encontre o machado perdido da Robin. Pode ser encontrado perto do cano de esgoto.\n\n'
    '250 ouros\n\n'
    'O prefeito Lewis perdeu seus "shorts" roxos. Ele está pedindo que você encontre-os e os devolva... Discretamente.\n\n'
    'Encontre e devolva os shorts roxos do prefeito Lewis. Podem se encontrados no quarto da Marnie.\n\n'
    '750 ouros';

void main() {
  test('o trecho mostra a frase da busca, não o começo do texto', () {
    final s = bestSnippet(_missoes, 'shorts roxos do prefeito');
    expect(s, contains('shorts'));
    expect(s, isNot(contains('machado')));
  });

  test('sem palavras em comum, mostra o começo', () {
    expect(bestSnippet(_missoes, 'xyz'), startsWith('Encontre o machado'));
  });

  test('o trecho da página com mais termos é escolhido', () {
    final chunks = ['Lewis é o prefeito.', 'Os shorts roxos estão no quarto da Marnie.'];
    expect(bestChunk(chunks, 'shorts roxos'), 1);
  });

  test('destaca as palavras da busca, com e sem acento', () {
    const mark = TextStyle(fontWeight: FontWeight.w800);
    final spans = highlightSpans('Missão do Prefeito: devolva os shorts.', 'missao shorts', mark);
    final marked = spans.where((s) => s.style == mark).map((s) => s.text).toList();
    expect(marked, ['Missão', 'shorts']);
  });
}
