import 'package:flutter/material.dart';

import '../app_scope.dart';
import '../app_theme.dart';
import '../models.dart';
import '../search.dart';
import '../search_snippet.dart';
import '../wiki_article.dart';
import '../widgets/common.dart';
import '../widgets/stardew_ui.dart';
import 'detail_screen.dart';

/// Leitura de um artigo da wiki offline, formatado no estilo do jogo: cabeçalho
/// com o sprite (quando a página é de algo da enciclopédia), índice clicável,
/// ficha do topo, seções em placas de madeira, falas em caixa de diálogo,
/// tabelas em cartões e links para outras páginas.
///
/// Com [query], rola até o trecho da busca ([focusText] ou o que mais combina)
/// e destaca as palavras buscadas.
class WikiPageScreen extends StatefulWidget {
  final WikiPage page;
  final String query;
  final String? focusText;
  const WikiPageScreen({super.key, required this.page, this.query = '', this.focusText});

  @override
  State<WikiPageScreen> createState() => _WikiPageScreenState();
}

class _WikiPageScreenState extends State<WikiPageScreen> {
  // O texto raspado repete o título da página no começo: some com essa linha.
  late final List<WikiBlock> _blocks = () {
    final all = parseWikiPage(widget.page.text);
    if (all.isNotEmpty &&
        all.first.kind == WikiBlockKind.paragraph &&
        normalize(all.first.text) == normalize(widget.page.title)) {
      return all.sublist(1);
    }
    return all;
  }();
  late final Map<int, GlobalKey> _keys = {
    for (var i = 0; i < _blocks.length; i++)
      if (_blocks[i].kind == WikiBlockKind.heading || _blocks[i].kind == WikiBlockKind.toc) i: GlobalKey(),
  };
  final _focusKey = GlobalKey();
  final _scroll = ScrollController();
  late final int _focus = _findFocus();
  bool _showTocButton = false;

  /// Busca que só repete o título da página não precisa de destaque nem rolagem.
  late final String _query = () {
    final terms = queryTerms(widget.query);
    final title = queryTerms(widget.page.title).toSet();
    return terms.isEmpty || terms.every(title.contains) ? '' : widget.query;
  }();

  int _findFocus() {
    if (_query.isEmpty) return -1;
    // Índice e barras de links não servem de destaque: só texto.
    var candidates = [
      for (var i = 0; i < _blocks.length; i++)
        if (_blocks[i].kind != WikiBlockKind.toc && _blocks[i].kind != WikiBlockKind.nav) i,
    ];
    if (candidates.isEmpty) return -1;
    final f = widget.focusText;
    if (f != null) {
      final at = widget.page.text.indexOf(f);
      if (at >= 0) {
        final inside = candidates.where((i) => _blocks[i].end > at && _blocks[i].start < at + f.length).toList();
        if (inside.isNotEmpty) candidates = inside;
      }
    }
    final best = bestChunk([for (final i in candidates) _blocks[i].plain], _query);
    return candidates[best];
  }

  @override
  void initState() {
    super.initState();
    _scroll.addListener(() {
      final show = _scroll.offset > 600;
      if (show != _showTocButton) setState(() => _showTocButton = show);
    });
    if (_focus > 0) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _goTo(_focusKey, alignment: 0.15));
    }
  }

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  void _goTo(GlobalKey key, {double alignment = 0}) {
    final ctx = key.currentContext;
    if (ctx != null) {
      Scrollable.ensureVisible(ctx, alignment: alignment, duration: const Duration(milliseconds: 380), curve: Curves.easeOutCubic);
    }
  }

  void _goToSection(String title) {
    final want = normalize(title);
    for (var i = 0; i < _blocks.length; i++) {
      final b = _blocks[i];
      if (b.kind == WikiBlockKind.heading && normalize(b.text) == want) {
        _goTo(i == _focus ? _focusKey : _keys[i]!);
        return;
      }
    }
  }

  void _openPage(String title) {
    final page = AppScope.of(context).search.pages[title];
    if (page == null) return;
    Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => WikiPageScreen(page: page)));
  }

  @override
  Widget build(BuildContext context) {
    final scope = AppScope.of(context);
    final entries = _EntryLookup.of(scope.repo.all);
    final pageEntry = entries[normalize(widget.page.title)];
    final ctx = _Ctx(
      query: _query,
      entries: entries,
      portrait: pageEntry?.cat == 'aldeoes' ? pageEntry : null,
      hasPage: (t) => scope.search.pages.containsKey(t),
      onSection: _goToSection,
      onPage: _openPage,
    );
    final tocIndex = _blocks.indexWhere((b) => b.kind == WikiBlockKind.toc);
    final children = <Widget>[];
    for (var i = 0; i < _blocks.length; i++) {
      Widget w = _BlockView(block: _blocks[i], ctx: ctx);
      if (i == _focus) w = _Focus(child: w);
      children.add(KeyedSubtree(key: i == _focus ? _focusKey : _keys[i], child: w));
    }
    return Scaffold(
      appBar: AppBar(title: Text(widget.page.title.replaceAll('_', ' '), maxLines: 1, overflow: TextOverflow.ellipsis)),
      floatingActionButton: tocIndex >= 0 && _showTocButton
          ? SdvIconButton(
              icon: Icons.format_list_bulleted_rounded,
              tooltip: 'Voltar ao índice',
              size: 50,
              onTap: () => _goTo(_keys[tocIndex]!),
            )
          : null,
      body: ContentWidth(child: SingleChildScrollView(
        controller: _scroll,
        padding: const EdgeInsets.fromLTRB(14, 12, 14, 40),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (pageEntry != null) _EntryHeader(entry: pageEntry),
            ...children,
            const SizedBox(height: 18),
            Text('Texto da Stardew Valley Wiki (CC BY-NC-SA 3.0).', style: Theme.of(context).textTheme.bodySmall),
          ],
        ),
      )),
    );
  }
}

/// Liga nomes de páginas às fichas da enciclopédia (para mostrar o sprite).
class _EntryLookup {
  static List<Entry>? _source;
  static Map<String, Entry> _byName = {};

  static Map<String, Entry> of(List<Entry> all) {
    if (!identical(_source, all)) {
      _source = all;
      _byName = {
        for (final e in all) ...{normalize(e.en): e, normalize(e.name): e},
      };
    }
    return _byName;
  }
}

class _Ctx {
  final String query;
  final Map<String, Entry> entries;
  final Entry? portrait;
  final bool Function(String title) hasPage;
  final ValueChanged<String> onSection;
  final ValueChanged<String> onPage;

  const _Ctx({
    required this.query,
    required this.entries,
    required this.portrait,
    required this.hasPage,
    required this.onSection,
    required this.onPage,
  });

  Entry? entry(String title) => entries[normalize(title)];
}

/// Cabeçalho da página quando ela fala de algo da enciclopédia.
class _EntryHeader extends StatelessWidget {
  final Entry entry;
  const _EntryHeader({required this.entry});

  @override
  Widget build(BuildContext context) {
    final cat = AppScope.of(context).repo.categories.where((c) => c.id == entry.cat).firstOrNull;
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Parchment(
        padding: const EdgeInsets.all(4),
        child: Row(
          children: [
            SdvSlot(size: 76, child: EntryImage(entry: entry, size: 58)),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(entry.name, style: sdvText(19, color: Theme.of(context).colorScheme.onSurface)),
                  if (cat != null) ...[
                    const SizedBox(height: 2),
                    Text('${cat.emoji} ${cat.title}', style: Theme.of(context).textTheme.bodySmall),
                  ],
                  const SizedBox(height: 8),
                  SdvButton(
                    label: 'Abrir ficha',
                    size: 13,
                    icon: const Icon(Icons.menu_book_rounded, color: Colors.white, size: 16),
                    onTap: () => Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => DetailScreen(entry: entry))),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Destaque do trecho encontrado pela busca.
class _Focus extends StatelessWidget {
  final Widget child;
  const _Focus({required this.child});

  @override
  Widget build(BuildContext context) {
    final c = Theme.of(context).colorScheme.primary;
    return Container(
      padding: const EdgeInsets.fromLTRB(10, 6, 6, 6),
      decoration: BoxDecoration(
        color: c.withValues(alpha: 0.08),
        border: Border(left: BorderSide(color: c, width: 4)),
      ),
      child: child,
    );
  }
}

class _BlockView extends StatelessWidget {
  final WikiBlock block;
  final _Ctx ctx;
  const _BlockView({required this.block, required this.ctx});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;
    final body = theme.textTheme.bodyLarge?.copyWith(height: 1.45);
    final mark = TextStyle(fontWeight: FontWeight.w800, backgroundColor: primary.withValues(alpha: 0.22));
    Widget rich(String text, {TextStyle? style}) =>
        Text.rich(TextSpan(style: style ?? body, children: highlightSpans(text, ctx.query, mark)));

    switch (block.kind) {
      case WikiBlockKind.heading:
        if (block.level == 2) {
          // Placa de madeira, como os títulos das janelas do jogo.
          return Padding(
            padding: const EdgeInsets.only(top: 22, bottom: 10),
            child: SdvFrame(
              style: SdvFrameStyle.wood,
              px: 2,
              fill: const Color(0xFFB4561A),
              padding: const EdgeInsets.fromLTRB(14, 9, 14, 10),
              child: Text(block.text, style: sdvText(17, color: Colors.white, shadow: true)),
            ),
          );
        }
        return Padding(
          padding: const EdgeInsets.only(top: 14, bottom: 6),
          child: Row(
            children: [
              Container(width: 8, height: 8, color: SdvColors.wood),
              const SizedBox(width: 8),
              Expanded(child: Text(block.text, style: sdvText(block.level == 3 ? 16 : 14, color: primary))),
            ],
          ),
        );

      case WikiBlockKind.toc:
        return Padding(
          padding: const EdgeInsets.only(top: 6, bottom: 8),
          child: _Toc(items: block.toc, onTap: ctx.onSection),
        );

      case WikiBlockKind.infobox:
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Parchment(
            padding: const EdgeInsets.all(4),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text('Informações', style: sdvText(16, color: primary)),
                const SizedBox(height: 6),
                for (var i = 0; i < block.pairs.length; i++) ...[
                  if (i > 0) Divider(height: 14, color: primary.withValues(alpha: 0.2)),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(width: 118, child: Text(block.pairs[i].$1, style: sdvText(13, color: primary))),
                      Expanded(
                        child: block.pairs[i].$1.contains('Presentes') && block.pairs[i].$2.contains(' • ')
                            ? Wrap(
                                spacing: 6,
                                runSpacing: 6,
                                children: [
                                  for (final g in block.pairs[i].$2.split(' • '))
                                    if (g.trim().isNotEmpty) TagPill('❤ ${g.trim()}', color: SdvColors.heart),
                                ],
                              )
                            : rich(block.pairs[i].$2, style: theme.textTheme.bodyMedium),
                      ),
                    ],
                  ),
                ],
                for (final q in block.qualities) ...[
                  Divider(height: 18, color: primary.withValues(alpha: 0.2)),
                  _QualityView(quality: q),
                ],
              ],
            ),
          ),
        );

      case WikiBlockKind.quote:
        // Caixa de diálogo do jogo, com o retrato do morador quando a página é dele.
        final who = ctx.portrait;
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: SdvFrame(
            px: 2,
            fill: theme.brightness == Brightness.dark ? const Color(0xFF4A2E19) : null,
            padding: const EdgeInsets.all(12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (who != null) ...[
                  SdvSlot(size: 48, child: EntryImage(entry: who, size: 36)),
                  const SizedBox(width: 10),
                ],
                Expanded(child: rich(block.text, style: body?.copyWith(fontStyle: FontStyle.italic))),
              ],
            ),
          ),
        );

      case WikiBlockKind.bullets:
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (final it in block.items)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 3),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(top: 8, right: 10),
                        child: Container(width: 6, height: 6, color: SdvColors.wood),
                      ),
                      Expanded(child: rich(it)),
                    ],
                  ),
                ),
            ],
          ),
        );

      case WikiBlockKind.table:
        return _TableView(block: block, ctx: ctx, rich: rich);

      case WikiBlockKind.cells:
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [for (final it in block.items) _Cell(child: rich(it, style: theme.textTheme.bodyMedium))],
          ),
        );

      case WikiBlockKind.nav:
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (block.text.isNotEmpty) ...[
                Text(block.text, style: sdvText(14, color: primary)),
                const SizedBox(height: 6),
              ],
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [
                  for (final it in block.items)
                    _LinkChip(
                      label: it,
                      entry: ctx.entry(it),
                      onTap: ctx.hasPage(it) ? () => ctx.onPage(it) : null,
                    ),
                ],
              ),
            ],
          ),
        );

      case WikiBlockKind.paragraph:
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: rich(block.text),
        );
    }
  }
}

/// Tabela da wiki em cartões: títulos das colunas no topo e uma linha por cartão.
/// A primeira célula de cada linha (em geral o nome) fica em destaque, com o
/// sprite quando é algo da enciclopédia.
class _TableView extends StatelessWidget {
  final WikiBlock block;
  final _Ctx ctx;
  final Widget Function(String text, {TextStyle? style}) rich;
  const _TableView({required this.block, required this.ctx, required this.rich});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;
    final cols = block.items.where((c) => c != 'Imagem').toList();
    final all = [...block.items, for (final r in block.rows) ...r];
    if (all.where(_time.hasMatch).length >= 3) return _schedule(context, all);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (cols.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Text(cols.join('  ·  '), style: sdvText(12, color: primary)),
            ),
          for (final row in block.rows)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: _Cell(
                expand: true,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        if (ctx.entry(row.first) != null) ...[
                          SdvSlot(size: 34, child: EntryImage(entry: ctx.entry(row.first)!, size: 24)),
                          const SizedBox(width: 8),
                        ],
                        Expanded(child: rich(row.first, style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800))),
                      ],
                    ),
                    for (final c in row.skip(1))
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: rich(c, style: theme.textTheme.bodyMedium?.copyWith(height: 1.35)),
                      ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

final _time = RegExp(r'^\d{1,2}:\d{2}$');

extension on _TableView {
  /// Agenda (horário + onde está): linha do tempo, com os dias especiais como subtítulos.
  Widget _schedule(BuildContext context, List<String> cells) {
    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;
    // Títulos de coluna repetidos no meio da tabela achatada.
    const skip = {'hora', 'horario', 'localizacao', 'local', 'imagem'};
    final children = <Widget>[];
    for (var k = 0; k < cells.length; k++) {
      final c = cells[k];
      if (skip.contains(normalize(c))) continue;
      if (_time.hasMatch(c)) {
        final what = k + 1 < cells.length && !_time.hasMatch(cells[k + 1]) ? cells[++k] : '';
        children.add(Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 62,
                padding: const EdgeInsets.symmetric(vertical: 3),
                alignment: Alignment.center,
                decoration: BoxDecoration(color: SdvColors.wood.withValues(alpha: 0.22), borderRadius: BorderRadius.circular(3)),
                child: Text(c, style: sdvText(13, color: theme.colorScheme.onSurface)),
              ),
              const SizedBox(width: 10),
              Expanded(child: rich(what, style: theme.textTheme.bodyMedium?.copyWith(height: 1.35))),
            ],
          ),
        ));
      } else {
        children.add(Padding(
          padding: const EdgeInsets.only(top: 12, bottom: 4),
          child: Text(c, style: sdvText(14, color: primary)),
        ));
      }
    }
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: _Cell(expand: true, child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: children)),
    );
  }
}

/// Valores por qualidade com as estrelas do jogo (normal, prata, ouro, irídio).
class _QualityView extends StatelessWidget {
  final WikiQuality quality;
  const _QualityView({required this.quality});

  static const _stars = [null, Color(0xFFB7C3CC), Color(0xFFFFC928), Color(0xFFB15CFF)];
  static const _names = ['Normal', 'Prata', 'Ouro', 'Irídio'];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;
    final cells = [for (final r in quality.rows) ...r, ...quality.values];
    final gold = cells.isNotEmpty && cells.every((c) => c.endsWith('ouros') || c.endsWith('ouro'));
    String short(String v) => gold ? v.replaceAll(RegExp(r'\s*ouros?$'), '') : v;
    final title = Text(gold ? '${quality.label} (ouros)' : quality.label, style: sdvText(13, color: primary));

    if (quality.plainTable) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          title,
          const SizedBox(height: 6),
          Table(
            defaultVerticalAlignment: TableCellVerticalAlignment.middle,
            children: [
              TableRow(children: [
                for (final h in quality.header)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Text(h, textAlign: TextAlign.center, style: theme.textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w700)),
                  ),
              ]),
              for (var r = 0; r < quality.rows.length; r++)
                TableRow(
                  decoration: BoxDecoration(color: r.isEven ? primary.withValues(alpha: 0.06) : null),
                  children: [
                    for (final v in quality.rows[r])
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 5),
                        child: Text(short(v), textAlign: TextAlign.center, style: theme.textTheme.bodyMedium),
                      ),
                  ],
                ),
            ],
          ),
        ],
      );
    }
    if (!quality.grid) {
      final names = [for (final h in quality.header) h.replaceAll('\n', ' ')];
      if (names.length == quality.values.length) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            title,
            const SizedBox(height: 6),
            Wrap(spacing: 6, runSpacing: 6, children: [
              for (var k = 0; k < names.length; k++)
                _Cell(
                  child: Text.rich(TextSpan(children: [
                    TextSpan(text: '${names[k]}  ', style: theme.textTheme.bodySmall),
                    TextSpan(text: short(quality.values[k]), style: const TextStyle(fontWeight: FontWeight.w700)),
                  ])),
                ),
            ]),
          ],
        );
      }
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          title,
          if (quality.header.isNotEmpty)
            Text(quality.header.join(' · ').replaceAll('\n', ' '), style: theme.textTheme.bodySmall),
          const SizedBox(height: 6),
          Wrap(spacing: 6, runSpacing: 6, children: [for (final v in quality.values) _Cell(child: Text(short(v)))]),
        ],
      );
    }

    Widget star(int q) => Tooltip(
          message: _names[q],
          child: _stars[q] == null
              ? Text('—', textAlign: TextAlign.center, style: theme.textTheme.bodySmall)
              : Icon(Icons.star_rounded, size: 18, color: _stars[q], shadows: const [Shadow(color: Color(0x88000000), offset: Offset(1, 1))]),
        );
    final hasLabels = quality.rowLabels.any((l) => l.isNotEmpty);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        title,
        const SizedBox(height: 6),
        Table(
          columnWidths: {0: hasLabels ? const FlexColumnWidth(1.6) : const FixedColumnWidth(0)},
          defaultVerticalAlignment: TableCellVerticalAlignment.middle,
          children: [
            TableRow(children: [const SizedBox(), for (var q = 0; q < 4; q++) Center(child: star(q))]),
            for (var r = 0; r < quality.rows.length; r++)
              TableRow(
                decoration: BoxDecoration(color: r.isEven ? primary.withValues(alpha: 0.06) : null),
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 5, horizontal: 4),
                    child: Text(quality.rowLabels[r], style: theme.textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w700)),
                  ),
                  for (final v in quality.rows[r])
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 5),
                      child: Text(short(v), textAlign: TextAlign.center, style: theme.textTheme.bodyMedium),
                    ),
                ],
              ),
          ],
        ),
      ],
    );
  }
}

/// Caixinha de papel (célula de tabela).
class _Cell extends StatelessWidget {
  final Widget child;
  final bool expand;
  const _Cell({required this.child, this.expand = false});

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    return Container(
      width: expand ? double.infinity : null,
      padding: EdgeInsets.symmetric(horizontal: expand ? 12 : 10, vertical: expand ? 10 : 6),
      decoration: BoxDecoration(
        color: primary.withValues(alpha: 0.07),
        border: Border.all(color: primary.withValues(alpha: 0.28)),
        borderRadius: BorderRadius.circular(4),
      ),
      child: child,
    );
  }
}

/// Índice da página: cada item rola até a seção. Índices longos começam recolhidos.
class _Toc extends StatefulWidget {
  final List<WikiTocItem> items;
  final ValueChanged<String> onTap;
  const _Toc({required this.items, required this.onTap});

  @override
  State<_Toc> createState() => _TocState();
}

class _TocState extends State<_Toc> {
  static const _collapsed = 8;
  bool _all = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final items = _all ? widget.items : widget.items.take(_collapsed).toList();
    return Parchment(
      padding: const EdgeInsets.all(4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(Icons.format_list_bulleted_rounded, size: 20, color: theme.colorScheme.primary),
              const SizedBox(width: 8),
              Text('Índice', style: sdvText(17, color: theme.colorScheme.primary)),
            ],
          ),
          const SizedBox(height: 6),
          for (final t in items)
            InkWell(
              onTap: () => widget.onTap(t.title),
              child: Padding(
                padding: EdgeInsets.fromLTRB(16.0 * t.depth, 7, 4, 7),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      width: 34 + 8.0 * t.depth,
                      child: Text(t.number, style: sdvText(13, color: SdvColors.wood)),
                    ),
                    Expanded(
                      child: Text(
                        t.title,
                        style: (t.depth == 0 ? theme.textTheme.bodyLarge : theme.textTheme.bodyMedium)
                            ?.copyWith(fontWeight: t.depth == 0 ? FontWeight.w700 : FontWeight.w500),
                      ),
                    ),
                    Icon(Icons.chevron_right_rounded, size: 18, color: theme.colorScheme.primary.withValues(alpha: 0.6)),
                  ],
                ),
              ),
            ),
          if (widget.items.length > _collapsed)
            TextButton.icon(
              onPressed: () => setState(() => _all = !_all),
              icon: Icon(_all ? Icons.expand_less_rounded : Icons.expand_more_rounded),
              label: Text(_all ? 'Mostrar menos' : 'Mostrar tudo (${widget.items.length})'),
            ),
        ],
      ),
    );
  }
}

/// Link para outra página da wiki, com o sprite quando é algo da enciclopédia
/// (cinza quando a página não está na wiki offline).
class _LinkChip extends StatelessWidget {
  final String label;
  final Entry? entry;
  final VoidCallback? onTap;
  const _LinkChip({required this.label, this.entry, this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final active = onTap != null;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(4),
      child: Container(
        padding: EdgeInsets.fromLTRB(entry != null ? 4 : 10, 4, 10, 4),
        decoration: BoxDecoration(
          color: active ? SdvColors.wood.withValues(alpha: 0.16) : Colors.transparent,
          border: Border.all(color: active ? SdvColors.woodDark.withValues(alpha: 0.7) : theme.dividerColor.withValues(alpha: 0.4)),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (entry != null) ...[
              SizedBox(width: 24, height: 24, child: EntryImage(entry: entry!, size: 24)),
              const SizedBox(width: 6),
            ],
            Text(
              label,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: active ? FontWeight.w700 : FontWeight.w400,
                color: active ? null : theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.6),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
