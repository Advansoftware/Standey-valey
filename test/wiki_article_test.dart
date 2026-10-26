import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:stardew_guia/wiki_article.dart';

Map<String, String> _pages() {
  final raw = jsonDecode(utf8.decode(gzip.decode(File('assets/wiki/pages.json.gz').readAsBytesSync()))) as List;
  return {
    for (final p in raw.cast<Map<String, dynamic>>())
      p['t'] as String: (p['c'] as List).cast<String>().join('\n\n'),
  };
}

void main() {
  final pages = _pages();

  test('índice vira lista clicável e os títulos viram seções', () {
    final blocks = parseWikiPage(pages['Missões']!);
    final toc = blocks.firstWhere((b) => b.kind == WikiBlockKind.toc);
    expect(toc.toc.first.number, '1');
    expect(toc.toc.first.title, 'Missões Precisa-se de Ajuda');
    expect(toc.toc.firstWhere((t) => t.number == '1.1').depth, 1);
    final headings = blocks.where((b) => b.kind == WikiBlockKind.heading).map((b) => b.text).toList();
    expect(headings, contains('Missões Precisa-se de Ajuda'));
    expect(headings, isNot(contains('Índice')));
  });

  test('ficha do topo vira pares rótulo/valor', () {
    final blocks = parseWikiPage(pages['Abigail']!);
    final info = blocks.firstWhere((b) => b.kind == WikiBlockKind.infobox);
    expect(info.pairs, contains(('Aniversário', 'Outono 13')));
    expect(info.pairs.any((p) => p.$1 == 'Melhores Presentes' && p.$2.contains('Ametista')), isTrue);
  });

  test('ficha de item tem os valores por qualidade em grade', () {
    final info = parseWikiPage(pages['Baiacu']!).firstWhere((b) => b.kind == WikiBlockKind.infobox);
    expect(info.pairs, contains(('Hora', '12:00 - 16:00')));
    final energia = info.qualities.firstWhere((q) => q.label == 'Energia / Saúde');
    expect(energia.rowLabels, ['Energia', 'Saúde']);
    expect(energia.rows.first, ['−100', '−140', '−180', '−260']);
    final precos = info.qualities.firstWhere((q) => q.label == 'Preços de Venda');
    expect(precos.rowLabels, ['Original', 'Pescador (+25%)', 'Mestre pescador (+50%)']);
    expect(precos.rows.first, ['200 ouros', '250 ouros', '300 ouros', '400 ouros']);
  });

  test('barra de navegação vira links com rótulo', () {
    final blocks = parseWikiPage(pages['Cerejeira']!);
    final nav = blocks.firstWhere((b) => b.kind == WikiBlockKind.nav && b.text == 'Árvores Frutíferas');
    expect(nav.items, containsAll(['Bananeira', 'Cerejeira', 'Romãzeira']));
  });

  test('todas as páginas são lidas sem perder texto', () {
    final problems = <String>[];
    for (final e in pages.entries) {
      final blocks = parseWikiPage(e.value);
      final shown = blocks.map((b) => b.plain).join(' ');
      // O texto visível precisa conter as palavras da página (o título "Índice" vira o cartão do índice).
      final words = RegExp(r'[\p{L}\p{N}]{4,}', unicode: true).allMatches(e.value).map((m) => m.group(0)!).toSet()
        ..remove('Índice');
      final missing = words.where((w) => !shown.contains(w)).toList();
      if (missing.isNotEmpty) problems.add('${e.key}: ${missing.take(5)}');
    }
    expect(problems, isEmpty);
  });
}
