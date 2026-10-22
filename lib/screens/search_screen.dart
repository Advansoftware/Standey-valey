import 'package:flutter/material.dart';

import '../app_scope.dart';
import '../models.dart';
import '../search.dart';
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
            filled: false,
            border: InputBorder.none,
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
                    ? const _Hint()
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
                              return _WikiTile(hit: h);
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
  const _Hint();

  @override
  Widget build(BuildContext context) {
    final repo = AppScope.of(context).repo;
    final examples = ['carvalho', 'baiacu', 'como ganhar dinheiro', 'presentes da Abigail', 'inverno'];
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text('Experimente buscar', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800)),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [for (final e in examples) Chip(label: Text(e))],
        ),
        const SizedBox(height: 16),
        Text('${repo.all.length} itens na enciclopédia, tudo offline.'),
      ],
    );
  }
}

class _WikiTile extends StatelessWidget {
  final Hit hit;
  const _WikiTile({required this.hit});

  @override
  Widget build(BuildContext context) {
    final search = AppScope.of(context).search;
    final title = hit.doc.pageTitle ?? hit.doc.title;
    var snippet = hit.doc.text.replaceAll(RegExp(r'\s+'), ' ').trim();
    if (snippet.length > 160) snippet = '${snippet.substring(0, 160)}…';
    return ListTile(
      leading: const Text('📜', style: TextStyle(fontSize: 26)),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w800)),
      subtitle: Text(snippet, maxLines: 3, overflow: TextOverflow.ellipsis),
      onTap: () {
        final page = search.pages[title];
        if (page != null) {
          Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => WikiPageScreen(page: page)));
        }
      },
    );
  }
}

/// Leitura de um artigo da wiki offline.
class WikiPageScreen extends StatelessWidget {
  final WikiPage page;
  const WikiPageScreen({super.key, required this.page});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(page.title, maxLines: 1, overflow: TextOverflow.ellipsis)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          SelectableText(page.text, style: Theme.of(context).textTheme.bodyLarge),
          const SizedBox(height: 16),
          Text('Texto da Stardew Valley Wiki (CC BY-NC-SA 3.0).', style: Theme.of(context).textTheme.bodySmall),
        ],
      ),
    );
  }
}

/// Sugestão de uso: mostra entradas de uma lista de IDs.
List<Entry> entriesByIds(BuildContext context, Iterable<String> ids) {
  final repo = AppScope.of(context).repo;
  return [for (final id in ids) if (repo.byId[id] != null) repo.byId[id]!];
}
