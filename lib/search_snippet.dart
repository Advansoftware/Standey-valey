import 'package:flutter/painting.dart';

import 'search.dart';

final _word = RegExp(r'[\p{L}\p{N}]+', unicode: true);
final _sentenceEnd = RegExp(r'(?<=[.!?])\s+|\n+');

/// Termos da busca já normalizados (sem acento, sem stop words, sem plural).
List<String> queryTerms(String query) => tokenize(query).toSet().toList();

/// A palavra [word] do texto bate com algum termo da busca (por prefixo, como o índice).
bool matchesTerm(String word, List<String> terms) {
  final t = tokenize(word);
  if (t.isEmpty) return false;
  final w = t.first;
  for (final q in terms) {
    if (w == q) return true;
    if (q.length >= 3 && w.startsWith(q)) return true;
    if (w.length >= 3 && q.startsWith(w) && w.length >= q.length - 2) return true;
  }
  return false;
}

int _score(String sentence, List<String> terms) {
  final found = <String>{};
  for (final m in _word.allMatches(sentence)) {
    final w = m.group(0)!;
    for (final q in terms) {
      if (matchesTerm(w, [q])) found.add(q);
    }
  }
  return found.length;
}

/// Trecho de [text] que mais combina com [query]: a frase com mais termos da busca,
/// completada com a seguinte se for curta. Sem termos em comum, devolve o começo.
String bestSnippet(String text, String query, {int maxChars = 220}) {
  // Só a exibição: tira os marcadores de título/lista do texto da wiki.
  final clean = text
      .replaceAll(RegExp(r'^#{2,4}\s*', multiLine: true), '')
      .replaceAll(RegExp(r'^•\s*', multiLine: true), '')
      .replaceAll(RegExp(r'[ \t]+'), ' ')
      .trim();
  final terms = queryTerms(query);
  final parts = clean.split(_sentenceEnd).map((s) => s.trim()).where((s) => s.isNotEmpty).toList();
  if (parts.isEmpty) return '';
  var best = 0;
  var bestScore = 0;
  if (terms.isNotEmpty) {
    for (var i = 0; i < parts.length; i++) {
      final s = _score(parts[i], terms);
      if (s > bestScore) {
        bestScore = s;
        best = i;
      }
    }
  }
  var out = parts[best];
  var next = best + 1;
  while (out.length < 90 && next < parts.length) {
    out = '$out ${parts[next++]}';
  }
  final cut = out.length > maxChars;
  if (cut) out = out.substring(0, maxChars).replaceFirst(RegExp(r'\s+\S*$'), '');
  final prefix = best > 0 ? '… ' : '';
  final suffix = cut || next < parts.length ? ' …' : '';
  return '$prefix$out$suffix';
}

/// Índice do trecho (chunk) da página que mais combina com a busca.
int bestChunk(List<String> chunks, String query) {
  final terms = queryTerms(query);
  var best = 0;
  var bestScore = -1;
  for (var i = 0; i < chunks.length; i++) {
    final s = _score(chunks[i], terms);
    if (s > bestScore) {
      bestScore = s;
      best = i;
    }
  }
  return best;
}

/// [text] em pedaços, com as palavras da busca no estilo [highlight].
List<TextSpan> highlightSpans(String text, String query, TextStyle highlight) {
  final terms = queryTerms(query);
  if (terms.isEmpty) return [TextSpan(text: text)];
  final spans = <TextSpan>[];
  var last = 0;
  for (final m in _word.allMatches(text)) {
    if (!matchesTerm(m.group(0)!, terms)) continue;
    if (m.start > last) spans.add(TextSpan(text: text.substring(last, m.start)));
    spans.add(TextSpan(text: m.group(0), style: highlight));
    last = m.end;
  }
  if (last < text.length) spans.add(TextSpan(text: text.substring(last)));
  return spans;
}
