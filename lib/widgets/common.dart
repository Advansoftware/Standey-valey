import 'package:flutter/material.dart';

import '../app_scope.dart';
import '../app_theme.dart';
import '../models.dart';
import '../screens/detail_screen.dart';

void openEntry(BuildContext context, Entry e) {
  Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => DetailScreen(entry: e)));
}

/// Imagem da entrada: sprite do jogo embutido em assets/img (emoji se faltar o arquivo).
class EntryImage extends StatelessWidget {
  final Entry entry;
  final double size;
  const EntryImage({super.key, required this.entry, this.size = 64});

  Widget _emoji() => Center(
        child: Text(entry.emoji, style: TextStyle(fontSize: size * 0.62)),
      );

  @override
  Widget build(BuildContext context) {
    if (entry.img.isEmpty) return SizedBox(width: size, height: size, child: _emoji());
    return SizedBox(
      width: size,
      height: size,
      child: Image.asset(
        'assets/img/${entry.img}',
        fit: BoxFit.contain,
        filterQuality: FilterQuality.none,
        errorBuilder: (context, error, stack) => _emoji(),
      ),
    );
  }
}

class SectionTitle extends StatelessWidget {
  final String text;
  final Widget? trailing;
  const SectionTitle(this.text, {super.key, this.trailing});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
      child: Row(
        children: [
          Expanded(
            child: Text(text, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800)),
          ),
          if (trailing != null) trailing!,
        ],
      ),
    );
  }
}

/// Cartão estilo Pokédex: número, imagem, nome.
class DexCard extends StatelessWidget {
  final Entry entry;
  final Color color;
  final bool showCollected;
  const DexCard({super.key, required this.entry, required this.color, this.showCollected = true});

  @override
  Widget build(BuildContext context) {
    final store = AppScope.of(context).store;
    return ListenableBuilder(
      listenable: store,
      builder: (context, _) {
        final got = store.isCollected(entry.id);
        final fav = store.isFav(entry.id);
        return Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(20),
            onTap: () => openEntry(context, entry),
            child: Ink(
              decoration: parchment(context, accent: got ? color : null),
              child: Padding(
                padding: const EdgeInsets.all(10),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Text(entry.numberLabel,
                            style: Theme.of(context).textTheme.labelSmall?.copyWith(fontWeight: FontWeight.w700, color: color)),
                        const Spacer(),
                        if (fav) const Icon(Icons.star_rounded, size: 16, color: Color(0xFFF9A825)),
                        if (showCollected && got) Icon(Icons.check_circle_rounded, size: 16, color: color),
                      ],
                    ),
                    Expanded(
                      child: Container(
                        margin: const EdgeInsets.symmetric(vertical: 4),
                        decoration: BoxDecoration(
                          color: color.withValues(alpha: 0.14),
                          shape: BoxShape.circle,
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(14),
                          child: LayoutBuilder(
                            builder: (context, c) => EntryImage(entry: entry, size: c.biggest.shortestSide),
                          ),
                        ),
                      ),
                    ),
                    Text(
                      entry.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14),
                    ),
                    Text(
                      entry.sub,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

/// Linha de lista com imagem, nome e subtítulo.
class EntryTile extends StatelessWidget {
  final Entry entry;
  final Color? color;
  final VoidCallback? onTap;
  const EntryTile({super.key, required this.entry, this.color, this.onTap});

  @override
  Widget build(BuildContext context) {
    final c = color ?? Theme.of(context).colorScheme.primary;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: onTap ?? () => openEntry(context, entry),
          child: Ink(
            decoration: parchment(context, radius: 18),
            padding: const EdgeInsets.all(10),
            child: Row(
              children: [
                Container(
                  width: 56,
                  height: 56,
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(color: c.withValues(alpha: 0.14), shape: BoxShape.circle),
                  child: EntryImage(entry: entry, size: 44),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(entry.name, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
                      if (entry.sub.isNotEmpty)
                        Text(entry.sub, maxLines: 2, overflow: TextOverflow.ellipsis, style: Theme.of(context).textTheme.bodySmall),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right_rounded),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Pequeno rótulo colorido.
class TagPill extends StatelessWidget {
  final String text;
  final Color color;
  const TagPill(this.text, {super.key, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: color.withValues(alpha: 0.18), borderRadius: BorderRadius.circular(20)),
      child: Text(text, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: color)),
    );
  }
}
