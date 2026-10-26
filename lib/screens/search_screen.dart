import 'package:flutter/material.dart';

import '../app_scope.dart';
import '../models.dart';
import '../search.dart';
import '../search_snippet.dart';
import '../widgets/common.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final _controller = TextEditingController();
  String _query = '';
  int _mode = 0; // 0 tudo, 1 enciclopédia, 2 wiki offline
  bool _started = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_started) {
      _started = true;
      AppScope.of(context).search.loadWiki();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final search = AppScope.of(context).search;
    return Scaffold(
      appBar: AppBar(
        titleSpacing: 0,
        title: TextField(
          controller: _controller,
          autofocus: true,
          textInputAction: TextInputAction.search,
          onChanged: (v) => setState(() => _query = v),
          decoration: InputDecoration(
            hintText: 'Buscar peixe, árvore, morador, dica…',
            isDense: true,
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            suffixIcon: _query.isEmpty
                ? null
                : IconButton(
                    icon: const Icon(Icons.close_rounded),
                    onPressed: () {
                      _controller.clear();
                      setState(() => _query = '');
                    },
                  ),
          ),
        ),
      ),
      body: ListenableBuilder(
        listenable: search,
        builder: (context, _) {
          final all = _query.trim().isEmpty
              ? const <Hit>[]
              : search.search(_query, limit: _mode == 2 ? 80 : 40, entriesOnly: _mode == 1);
          final hits = _mode == 2 ? all.where((h) => h.doc.entryId == null).toList() : all;
          final seenPages = <String>{};
          final shown = <Hit>[];
          for (final h in hits) {
            if (h.doc.entryId == null) {
              if (!seenPages.add(h.doc.pageTitle ?? h.doc.title)) continue;
            }
            shown.add(h);
          }
          return Column(
            children: [
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Row(
                  children: [
                    for (final m in const [(0, 'Tudo'), (1, 'Enciclopédia'), (2, 'Wiki offline')])
                      Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: ChoiceChip(label: Text(m.$2), selected: _mode == m.$1, onSelected: (_) => setState(() => _mode = m.$1)),
                      ),
                  ],
                ),
              ),
              if (search.wikiLoading) const LinearProgressIndicator(minHeight: 3),
              Expanded(
                child: _query.trim().isEmpty
                    ? _Hint(
                        onPick: (q) {
                          _controller.text = q;
                          setState(() => _query = q);
                        },
                      )
                    : shown.isEmpty
                        ? Center(
                            child: Padding(
                              padding: const EdgeInsets.all(24),
                              child: Text(
                                _mode == 2 && !search.wikiAvailable
                                    ? 'A wiki offline ainda não foi incluída neste app. Veja o HANDOFF.md (passo D).'
                                    : 'Nada encontrado. Tente outras palavras.',
                                textAlign: TextAlign.center,
                              ),
                            ),
                          )
                        : ListView.builder(
                            padding: const EdgeInsets.only(top: 8, bottom: 24),
                            itemCount: shown.length,
                            itemBuilder: (context, i) {
                              final h = shown[i];
                              final entry = search.entryOf(h.doc);
                              if (entry != null) return EntryTile(entry: entry);
                              return _WikiTile(hit: h, query: _query);
                            },
                          ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _Hint extends StatelessWidget {
  final ValueChanged<String> onPick;
  const _Hint({required this.onPick});

  @override
  Widget build(BuildContext context) {
    final repo = AppScope.of(context).repo;
    final examples = ['carvalho', 'baiacu', 'como ganhar dinheiro', 'presentes da Abigail', 'inverno'];
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text('Experimente buscar', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [for (final e in examples) ActionChip(label: Text(e), onPressed: () => onPick(e))],
        ),
        const SizedBox(height: 16),
        Text('${repo.all.length} itens na enciclopédia, tudo offline.'),
      ],
    );
  }
}

class _WikiTile extends StatelessWidget {
  final Hit hit;
  final String query;
  const _WikiTile({required this.hit, required this.query});

  @override
  Widget build(BuildContext context) {
    final search = AppScope.of(context).search;
    final title = hit.doc.pageTitle ?? hit.doc.title;
    final theme = Theme.of(context);
    final mark = TextStyle(fontWeight: FontWeight.w800, color: theme.colorScheme.primary);
    return ListTile(
      leading: const Text('📜', style: TextStyle(fontSize: 26)),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
      subtitle: Text.rich(
        TextSpan(children: highlightSpans(bestSnippet(hit.doc.text, query), query, mark)),
        maxLines: 4,
        overflow: TextOverflow.ellipsis,
      ),
      onTap: () {
        final page = search.pages[title];
        if (page != null) {
          Navigator.of(context).push(MaterialPageRoute<void>(
            builder: (_) => WikiPageScreen(page: page, query: query, focusText: hit.doc.text),
          ));
        }
      },
    );
  }
}

/// Leitura de um artigo da wiki offline. Com [query], rola até o trecho da busca
/// ([focusText], ou o que mais combina) e destaca as palavras buscadas.
class WikiPageScreen extends StatefulWidget {
  final WikiPage page;
  final String query;
  final String? focusText;
  const WikiPageScreen({super.key, required this.page, this.query = '', this.focusText});

  @override
  State<WikiPageScreen> createState() => _WikiPageScreenState();
}

class _WikiPageScreenState extends State<WikiPageScreen> {
  final _focusKey = GlobalKey();
  late final int _focus = widget.query.trim().isEmpty
      ? -1
      : (widget.focusText != null && widget.page.chunks.contains(widget.focusText)
          ? widget.page.chunks.indexOf(widget.focusText!)
          : bestChunk(widget.page.chunks, widget.query));

  @override
  void initState() {
    super.initState();
    if (_focus > 0) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final ctx = _focusKey.currentContext;
        if (ctx != null) Scrollable.ensureVisible(ctx, alignment: 0.05, duration: const Duration(milliseconds: 350));
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final body = theme.textTheme.bodyLarge;
    final mark = TextStyle(
      fontWeight: FontWeight.w800,
      backgroundColor: theme.colorScheme.primary.withValues(alpha: 0.22),
    );
    final chunks = widget.page.chunks;
    return Scaffold(
      appBar: AppBar(title: Text(widget.page.title, maxLines: 1, overflow: TextOverflow.ellipsis)),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (var i = 0; i < chunks.length; i++)
              Container(
                key: i == _focus ? _focusKey : null,
                margin: const EdgeInsets.only(bottom: 16),
                padding: i == _focus ? const EdgeInsets.all(10) : EdgeInsets.zero,
                decoration: i == _focus
                    ? BoxDecoration(
                        color: theme.colorScheme.primary.withValues(alpha: 0.07),
                        border: Border(left: BorderSide(color: theme.colorScheme.primary, width: 3)),
                      )
                    : null,
                child: SelectableText.rich(
                  TextSpan(style: body, children: highlightSpans(chunks[i], widget.query, mark)),
                ),
              ),
            Text('Texto da Stardew Valley Wiki (CC BY-NC-SA 3.0).', style: theme.textTheme.bodySmall),
          ],
        ),
      ),
    );
  }
}

/// Sugestão de uso: mostra entradas de uma lista de IDs.
List<Entry> entriesByIds(BuildContext context, Iterable<String> ids) {
  final repo = AppScope.of(context).repo;
  return [for (final id in ids) if (repo.byId[id] != null) repo.byId[id]!];
}
