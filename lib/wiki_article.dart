/// Entende a estrutura de uma página da wiki offline (texto puro raspado da wiki)
/// para a tela de leitura: títulos, índice, ficha do topo, listas, barras de
/// navegação e as células soltas das tabelas.
library;

enum WikiBlockKind {
  /// Título de seção (`##`, `###`, `####`); [WikiBlock.level] é 2, 3 ou 4.
  heading,

  /// Índice da página: [WikiBlock.toc] com número, título e profundidade.
  toc,

  /// Ficha do topo (Aniversário, Mora em…): [WikiBlock.pairs].
  infobox,

  /// Parágrafo comum.
  paragraph,

  /// Citação (“…” ou — autor).
  quote,

  /// Lista com marcadores: [WikiBlock.items].
  bullets,

  /// Linhas curtas seguidas (tabelas achatadas): [WikiBlock.items].
  cells,

  /// Barra de navegação "A • B • C" (links para outras páginas): [WikiBlock.items],
  /// com o rótulo do grupo em [WikiBlock.text].
  nav,

  /// Tabela remontada: colunas em [WikiBlock.items] e linhas em [WikiBlock.rows].
  table,
}

class WikiTocItem {
  final String number;
  final String title;
  const WikiTocItem(this.number, this.title);

  /// 0 para "3", 1 para "3.1", 2 para "3.1.2".
  int get depth => '.'.allMatches(number).length;
}

/// Valores por qualidade da ficha de item (normal, prata, ouro, irídio).
///
/// Com [grid], cada linha de [rows] tem os 4 valores de [rowLabels] na ordem das
/// qualidades. Sem grade (contagem que não fecha em 4), [values] vem como lista.
class WikiQuality {
  final String label;
  final List<String> rowLabels;
  final List<List<String>> rows;
  final List<String> header;
  final List<String> values;

  /// Tabela simples (colunas em [header]), sem as estrelas de qualidade.
  final bool plainTable;
  const WikiQuality(this.label,
      {this.rowLabels = const [], this.rows = const [], this.header = const [], this.values = const [], this.plainTable = false});

  bool get grid => rows.isNotEmpty && !plainTable;
  String get plain => [label, ...header, ...rowLabels, for (final r in rows) ...r, ...values].join(' ');
}

class WikiBlock {
  final WikiBlockKind kind;
  final String text;
  final int level;
  final List<String> items;
  final List<(String, String)> pairs;
  final List<WikiTocItem> toc;
  final List<List<String>> rows;
  final List<WikiQuality> qualities;

  /// Posição do bloco no texto da página (para achar o trecho da busca).
  final int start;
  final int end;

  const WikiBlock(
    this.kind, {
    this.text = '',
    this.level = 0,
    this.items = const [],
    this.pairs = const [],
    this.toc = const [],
    this.rows = const [],
    this.qualities = const [],
    required this.start,
    required this.end,
  });

  /// Todo o texto visível do bloco (para busca e destaque).
  String get plain => switch (kind) {
        WikiBlockKind.infobox =>
          ['Informações', 'Informação', ...pairs.map((p) => '${p.$1} ${p.$2}'), ...qualities.map((q) => q.plain)].join('\n'),
        WikiBlockKind.toc => toc.map((t) => t.title).join('\n'),
        WikiBlockKind.bullets || WikiBlockKind.cells || WikiBlockKind.nav => [text, ...items].join('\n'),
        WikiBlockKind.table => [text, ...items, for (final r in rows) ...r].join('\n'),
        _ => text,
      };
}

class _Raw {
  final String text;
  final int start;
  final int end;
  const _Raw(this.text, this.start, this.end);
}

final _heading = RegExp(r'^(#{2,4})\s+(.+)$');
final _tocLine = RegExp(r'^•\s*(\d+(?:\.\d+)*)\s+(.+)$');

bool _isShort(String s) =>
    s.length <= 60 && !s.contains('\n') && !RegExp(r'[.!?:;]$').hasMatch(s);

bool _isNav(String s) {
  if (s.startsWith('• ') || s.contains('\n')) return false;
  final parts = s.split('•').map((p) => p.trim()).where((p) => p.isNotEmpty).toList();
  return parts.length >= 3 && parts.every((p) => p.length <= 45);
}

/// Divide [text] (a página inteira) em blocos para exibição.
List<WikiBlock> parseWikiPage(String text) {
  final raws = <_Raw>[];
  for (final m in RegExp(r'[^\n]+(?:\n(?!\n)[^\n]*)*').allMatches(text)) {
    final t = m.group(0)!.trim();
    if (t.isNotEmpty) raws.add(_Raw(t, m.start, m.end));
  }

  final out = <WikiBlock>[];
  var sawHeading = false;
  var i = 0;

  void flushCells(List<_Raw> run) {
    if (run.isEmpty) return;
    if (run.length == 1) {
      out.add(WikiBlock(WikiBlockKind.paragraph, text: run.first.text, start: run.first.start, end: run.first.end));
    } else {
      out.add(WikiBlock(WikiBlockKind.cells,
          items: [for (final r in run) r.text], start: run.first.start, end: run.last.end));
    }
    run.clear();
  }

  final cells = <_Raw>[];
  while (i < raws.length) {
    final r = raws[i];
    final t = r.text;
    if (t == '“' || t == '”' || t == '"') {
      i++;
      continue;
    }

    // Título de seção (e o índice logo abaixo de "## Índice").
    final h = _heading.firstMatch(t);
    if (h != null) {
      flushCells(cells);
      final title = h.group(2)!.trim();
      if (title == 'Índice' || title == 'Indice' || title == 'Conteúdo') {
        final toc = <WikiTocItem>[];
        var j = i + 1;
        while (j < raws.length) {
          final m = _tocLine.firstMatch(raws[j].text);
          if (m == null) break;
          toc.add(WikiTocItem(m.group(1)!, m.group(2)!.trim()));
          j++;
        }
        if (toc.isNotEmpty) {
          out.add(WikiBlock(WikiBlockKind.toc, toc: toc, start: r.start, end: raws[j - 1].end));
          i = j;
          continue;
        }
      }
      sawHeading = true;
      out.add(WikiBlock(WikiBlockKind.heading, text: title, level: h.group(1)!.length, start: r.start, end: r.end));
      i++;
      continue;
    }

    // Ficha do topo: "Informações" (morador) ou "Informação" (item) e pares rótulo/valor.
    if (!sawHeading && (t == 'Informações' || t == 'Informação')) {
      final box = _infobox(raws, i);
      if (box != null) {
        flushCells(cells);
        out.add(box.$1);
        i = box.$2;
        continue;
      }
    }

    // Lista com marcadores.
    if (t.startsWith('•')) {
      flushCells(cells);
      final items = <String>[];
      var j = i;
      while (j < raws.length && raws[j].text.startsWith('•') && !_tocLine.hasMatch(raws[j].text)) {
        items.addAll(raws[j].text.split('\n').map((l) => l.replaceFirst(RegExp(r'^•\s*'), '').trim()).where((l) => l.isNotEmpty));
        j++;
      }
      if (j == i) {
        // Linha "• 1 Algo" fora do índice: trata como item comum.
        items.add(t.replaceFirst(RegExp(r'^•\s*'), ''));
        j++;
      }
      out.add(WikiBlock(WikiBlockKind.bullets, items: items, start: r.start, end: raws[j - 1].end));
      i = j;
      continue;
    }

    // Barra de navegação: o rótulo é a última linha curta antes dela.
    if (_isNav(t)) {
      final label = cells.isNotEmpty ? cells.removeLast().text : '';
      flushCells(cells);
      out.add(WikiBlock(WikiBlockKind.nav,
          text: label,
          items: t.split('•').map((p) => p.trim()).where((p) => p.isNotEmpty).toList(),
          start: r.start,
          end: r.end));
      i++;
      continue;
    }

    if (_isShort(t)) {
      cells.add(r);
      i++;
      continue;
    }

    flushCells(cells);
    final quote = t.startsWith('“') || t.startsWith('"') || t.startsWith('— ');
    out.add(WikiBlock(quote ? WikiBlockKind.quote : WikiBlockKind.paragraph,
        text: t.replaceAll(RegExp(r'^“\s*$'), '').trim(), start: r.start, end: r.end));
    i++;
  }
  flushCells(cells);
  return _tables(out.where((b) => b.kind != WikiBlockKind.paragraph || b.text.isNotEmpty).toList());
}

bool _isLong(String s) => s.length > 60 || RegExp(r'[.!?]$').hasMatch(s);

/// Os "•" soltos do texto raspado eram as estrelas de qualidade (imagens).
String _clean(String s) => s.replaceAll(RegExp(r'\n•\s*$'), '').trim();
final _number = RegExp(r'^[−-]?\d[\d   .,]*(?:\s*ouros?)?$');

/// Junta as linhas de um título de coluna quebrado ("Mestre" + "pescador (+50%)").
List<String> _mergeLines(Iterable<String> lines) {
  final out = <String>[];
  for (final l in lines.map((l) => l.trim()).where((l) => l.isNotEmpty)) {
    if (out.isNotEmpty && RegExp(r'^[a-zà-ÿ(]').hasMatch(l)) {
      out[out.length - 1] = '${out.last} $l';
    } else {
      out.add(l);
    }
  }
  return out;
}

/// Ficha do topo: pares rótulo/valor e os valores por qualidade (energia, preços).
(WikiBlock, int)? _infobox(List<_Raw> raws, int start) {
  final pairs = <(String, String)>[];
  final quals = <WikiQuality>[];
  var j = start + 1;
  int skipBullets(int k) {
    while (k < raws.length && raws[k].text == '•') {
      k++;
    }
    return k;
  }

  while (true) {
    j = skipBullets(j);
    if (j >= raws.length) break;
    final label = _clean(raws[j].text);
    // Rótulo e valor no mesmo bloco ("Semente" / "Sementes de Couve-flor").
    final lines = label.split('\n');
    if (lines.length == 2 && lines[0].length <= 30 && !_number.hasMatch(lines[0]) && lines[1].length <= 120) {
      pairs.add((lines[0].trim(), lines[1].trim()));
      j++;
      continue;
    }
    if (_heading.hasMatch(label) || label.length > 40 || label.startsWith('“') || label.startsWith('•') || _isLong(label)) {
      break;
    }
    // Títulos de coluna (sem números) seguidos de uma sequência de números = valores por qualidade.
    var k = skipBullets(j + 1);
    final header = <String>[];
    while (k < raws.length && header.length < 3 && !_number.hasMatch(_clean(raws[k].text)) &&
        !_heading.hasMatch(raws[k].text) && _clean(raws[k].text).length <= 60 &&
        !RegExp(r'^[−-]?\d').hasMatch(raws[k].text)) {
      final next = skipBullets(k + 1);
      if (next >= raws.length || (!_number.hasMatch(_clean(raws[next].text)) && header.length >= 2)) break;
      header.add(_clean(raws[k].text));
      k = next;
    }
    final values = <String>[];
    var m = k;
    while (m < raws.length && _number.hasMatch(_clean(raws[m].text))) {
      values.add(_clean(raws[m].text).replaceAll(RegExp(r'\s+'), ' '));
      m = skipBullets(m + 1);
    }
    if (values.length >= 2) {
      quals.add(_quality(label, header, values));
      j = m;
      continue;
    }
    // Par simples rótulo/valor.
    final v = j + 1 < raws.length ? raws[j + 1].text : '';
    if (v.isEmpty || _heading.hasMatch(v) || v.length > 160 || v == '•') break;
    pairs.add((label, _clean(v).replaceAll('\n', ' · ').replaceAll(RegExp(r'\s*•\s*'), ' • ')));
    j += 2;
  }
  if (pairs.length + quals.length < 2) return null;
  return (
    WikiBlock(WikiBlockKind.infobox, pairs: pairs, qualities: quals, start: raws[start].start, end: raws[j - 1].end),
    j,
  );
}

WikiQuality _quality(String label, List<String> header, List<String> values) {
  // Energia / Saúde: um par por qualidade.
  if (label.contains('/') && values.length == 8) {
    final names = label.split('/').map((s) => s.trim()).toList();
    return WikiQuality(label, rowLabels: names, rows: [
      [for (var q = 0; q < 4; q++) values[q * 2]],
      [for (var q = 0; q < 4; q++) values[q * 2 + 1]],
    ]);
  }
  // Artesão: produtos (suco, picles…) em colunas Base / Artesão, sem qualidade.
  if (label.contains('Artesão')) {
    final cols = _mergeLines(header.expand((h) => h.split('\n')));
    if (cols.length >= 2 && values.length % cols.length == 0) {
      final per = values.length ~/ cols.length;
      return WikiQuality(label,
          header: cols,
          plainTable: true,
          rows: [
            for (var p = 0; p < per; p++) [for (var c = 0; c < cols.length; c++) values[c * per + p]],
          ]);
    }
    return WikiQuality(label, header: header, values: values);
  }
  // Preços: uma coluna de 4 qualidades para cada profissão (Original, +25%, +50%).
  if (values.length % 4 == 0 && values.length <= 16) {
    final n = values.length ~/ 4;
    final cols = _mergeLines(header.expand((h) => h.split('\n')));
    return WikiQuality(label,
        rowLabels: cols.length == n ? cols : (n == 1 ? [''] : List.filled(n, '')),
        rows: [for (var c = 0; c < n; c++) values.sublist(c * 4, c * 4 + 4)],
        header: cols.length == n ? const [] : header);
  }
  return WikiQuality(label, header: header, values: values);
}

/// Remonta tabelas achatadas: um bloco de células curtas (os títulos das colunas)
/// seguido de células e parágrafos vira uma tabela. Uma linha nova começa quando
/// já tem todas as colunas, ou num nome curto seguido de uma descrição longa.
List<WikiBlock> _tables(List<WikiBlock> blocks) {
  final out = <WikiBlock>[];
  var i = 0;
  while (i < blocks.length) {
    final head = blocks[i];
    final cols = head.items;
    final isHeader = head.kind == WikiBlockKind.cells &&
        cols.length >= 2 &&
        cols.length <= 8 &&
        cols.every((c) => c.length <= 30 && !_isLong(c));
    if (!isHeader) {
      out.add(head);
      i++;
      continue;
    }
    // Lago de Peixes: cada linha vem num bloco só ("3", "5" e a tarefa).
    if (cols.contains('Antes') && cols.contains('Depois')) {
      final pond = RegExp(r'^(\d+)\n(\d+)\n([\s\S]+)$');
      final rows = <List<String>>[];
      var j = i + 1;
      while (j < blocks.length && blocks[j].kind == WikiBlockKind.paragraph) {
        final m = pond.firstMatch(blocks[j].text);
        if (m == null) break;
        rows.add(['${m.group(1)} → ${m.group(2)} peixes', m.group(3)!.replaceAll('\n', ' ')]);
        j++;
      }
      if (rows.isNotEmpty) {
        out.add(WikiBlock(WikiBlockKind.table,
            text: cols.join('\n'), items: const ['Capacidade', 'Tarefa'], rows: rows, start: head.start, end: blocks[j - 1].end));
        i = j;
        continue;
      }
    }
    final cells = <String>[];
    var j = i + 1;
    while (j < blocks.length) {
      final b = blocks[j];
      if (b.kind == WikiBlockKind.cells) {
        cells.addAll(b.items);
      } else if (b.kind == WikiBlockKind.paragraph || b.kind == WikiBlockKind.quote) {
        cells.add(b.text);
      } else {
        break;
      }
      j++;
    }
    if (cells.length < cols.length) {
      out.add(head);
      i++;
      continue;
    }
    // A tabela vem achatada e às vezes falta célula: as linhas servem só para agrupar
    // na tela (sem rótulo por coluna, que poderia cair no valor errado). Se houver o
    // padrão "nome curto + descrição longa", ele marca o começo de cada linha.
    bool nameThenDesc(int k) =>
        !_isLong(cells[k]) && cells[k].length <= 40 && k + 1 < cells.length && cells[k + 1].length > 60;
    final byName = List.generate(cells.length, nameThenDesc).where((x) => x).length >= 2;
    // O nome da primeira linha costuma grudar nos títulos das colunas.
    var columns = cols;
    if (byName && _isLong(cells.first) && cols.length > 2) {
      columns = cols.sublist(0, cols.length - 1);
      cells.insert(0, cols.last);
    }
    final rows = <List<String>>[];
    var row = <String>[];
    for (var k = 0; k < cells.length; k++) {
      final c = cells[k];
      final startsRow = row.isNotEmpty && (byName ? nameThenDesc(k) : row.length >= columns.length);
      if (startsRow) {
        rows.add(row);
        row = <String>[];
      }
      row.add(c);
    }
    if (row.isNotEmpty) rows.add(row);
    out.add(WikiBlock(WikiBlockKind.table, items: columns, rows: rows, start: head.start, end: blocks[j - 1].end));
    i = j;
  }
  return out;
}
