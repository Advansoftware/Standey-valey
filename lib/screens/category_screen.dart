import 'package:flutter/material.dart';

import '../app_scope.dart';
import '../app_theme.dart';
import '../models.dart';
import '../search.dart';
import '../widgets/common.dart';
import '../widgets/stardew_ui.dart';

class CategoryScreen extends StatefulWidget {
  final Category cat;
  const CategoryScreen({super.key, required this.cat});

  @override
  State<CategoryScreen> createState() => _CategoryScreenState();
}

class _CategoryScreenState extends State<CategoryScreen> {
  String _query = '';
  String? _tag;
  bool? _grid;

  @override
  Widget build(BuildContext context) {
    final scope = AppScope.of(context);
    final store = scope.store;
    final cat = widget.cat;
    final all = scope.repo.byCat[cat.id] ?? const <Entry>[];
    final grid = _grid ?? false;

    // Tags para filtro, na ordem de aparição.
    final tags = <String>[];
    for (final e in all) {
      for (final t in e.tags) {
        if (!tags.contains(t)) tags.add(t);
      }
    }

    var list = all.where((e) => _tag == null || e.tags.contains(_tag)).toList();
    if (_query.trim().isNotEmpty) {
      final q = normalize(_query);
      list = list.where((e) => normalize('${e.name} ${e.en} ${e.sub}').contains(q)).toList();
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('${cat.emoji} ${cat.title}'),
        actions: [
          IconButton(
            tooltip: grid ? 'Ver em lista' : 'Ver em grade',
            icon: Icon(grid ? Icons.view_list_rounded : Icons.grid_view_rounded),
            onPressed: () => setState(() => _grid = !grid),
          ),
        ],
      ),
      body: ListenableBuilder(
        listenable: store,
        builder: (context, _) {
          final got = all.where((e) => store.isCollected(e.id)).length;
          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
                child: TextField(
                  onChanged: (v) => setState(() => _query = v),
                  decoration: InputDecoration(
                    hintText: 'Filtrar ${cat.title.toLowerCase()}…',
                    prefixIcon: const Icon(Icons.search_rounded),
                  ),
                ),
              ),
              if (cat.collect.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                  child: Row(
                    children: [
                      Text('${cat.collect}: $got/${all.length}', style: sdvText(14, color: Theme.of(context).colorScheme.onSurface)),
                      const SizedBox(width: 12),
                      Expanded(
                        child: SdvProgressBar(value: all.isEmpty ? 0 : got / all.length, color: cat.color),
                      ),
                    ],
                  ),
                ),
              if (tags.length > 1)
                SizedBox(
                  height: 44,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        child: ChoiceChip(label: const Text('Todos'), selected: _tag == null, onSelected: (_) => setState(() => _tag = null)),
                      ),
                      for (final t in tags)
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                          child: ChoiceChip(label: Text(t), selected: _tag == t, onSelected: (_) => setState(() => _tag = _tag == t ? null : t)),
                        ),
                    ],
                  ),
                ),
              Expanded(
                child: list.isEmpty
                    ? const Center(child: Text('Nada encontrado.'))
                    : grid
                        ? GridView.builder(
                            padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                            // 2 colunas em pé; mais colunas deitado ou no tablet.
                            gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                              maxCrossAxisExtent: 200,
                              mainAxisSpacing: 12,
                              crossAxisSpacing: 12,
                              childAspectRatio: 0.82,
                            ),
                            itemCount: list.length,
                            itemBuilder: (context, i) => DexCard(entry: list[i], color: cat.color, showCollected: cat.collect.isNotEmpty),
                          )
                        : LayoutBuilder(
                            // Tela larga (deitado, tablet): a lista vira colunas de linhas.
                            builder: (context, c) => c.maxWidth >= 700
                                ? GridView.builder(
                                    padding: const EdgeInsets.only(top: 4, bottom: 24),
                                    gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                                      maxCrossAxisExtent: 520,
                                      mainAxisExtent: 118,
                                    ),
                                    itemCount: list.length,
                                    itemBuilder: (context, i) => EntryTile(entry: list[i], color: cat.color),
                                  )
                                : ListView.builder(
                                    padding: const EdgeInsets.only(top: 4, bottom: 24),
                                    itemCount: list.length,
                                    itemBuilder: (context, i) => EntryTile(entry: list[i], color: cat.color),
                                  ),
                          ),
              ),
            ],
          );
        },
      ),
    );
  }
}

/// Aba "Enciclopédia": todas as categorias com progresso.
class EncyclopediaScreen extends StatelessWidget {
  const EncyclopediaScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final scope = AppScope.of(context);
    final store = scope.store;
    final cats = scope.repo.categories;
    return Scaffold(
      appBar: AppBar(title: const Text('Enciclopédia')),
      body: ListenableBuilder(
        listenable: store,
        builder: (context, _) {
          return GridView.builder(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
            gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
              maxCrossAxisExtent: 240,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              mainAxisExtent: 160,
            ),
            itemCount: cats.length,
            itemBuilder: (context, i) {
              final c = cats[i];
              final list = scope.repo.byCat[c.id] ?? const <Entry>[];
              final got = list.where((e) => store.isCollected(e.id)).length;
              return CategoryTile(cat: c, total: list.length, got: got);
            },
          );
        },
      ),
    );
  }
}

class CategoryTile extends StatelessWidget {
  final Category cat;
  final int total;
  final int got;
  const CategoryTile({super.key, required this.cat, required this.total, required this.got});

  @override
  Widget build(BuildContext context) {
    return Parchment(
      onTap: () => Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => CategoryScreen(cat: cat))),
      padding: const EdgeInsets.fromLTRB(6, 4, 6, 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              SdvSlot(size: 50, child: Text(cat.emoji, style: const TextStyle(fontSize: 24))),
              const Spacer(),
              if (cat.collect.isNotEmpty) Text('$got/$total', style: sdvText(14, color: cat.color)),
            ],
          ),
          const Spacer(),
          Text(cat.title, maxLines: 2, overflow: TextOverflow.ellipsis,
              style: sdvText(16, color: Theme.of(context).colorScheme.onSurface, height: 1.1)),
          Text(cat.collect.isNotEmpty ? cat.collect.toLowerCase() : '$total itens',
              maxLines: 1, overflow: TextOverflow.ellipsis, style: Theme.of(context).textTheme.bodySmall),
          if (cat.collect.isNotEmpty) ...[
            const SizedBox(height: 5),
            SdvProgressBar(value: total == 0 ? 0 : got / total, color: cat.color),
          ],
        ],
      ),
    );
  }
}
