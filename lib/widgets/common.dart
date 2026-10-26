import 'package:flutter/material.dart';

import '../app_scope.dart';
import '../app_theme.dart';
import 'stardew_ui.dart';
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

/// Título de seção com a fonte de pixel e um traço de madeira, como nos menus.
class SectionTitle extends StatelessWidget {
  final String text;
  final Widget? trailing;
  const SectionTitle(this.text, {super.key, this.trailing});

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(text, style: sdvText(18, color: dark ? const Color(0xFFF6DDB0) : SdvColors.ink)),
              ),
              ?trailing,
            ],
          ),
          Container(height: 3, margin: const EdgeInsets.only(top: 4), color: SdvColors.woodDark),
        ],
      ),
    );
  }
}

/// Cartão estilo Pokédex: número, sprite no slot e nome, na moldura do jogo.
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
        return Parchment(
          onTap: () => openEntry(context, entry),
          padding: const EdgeInsets.fromLTRB(6, 4, 6, 4),
          child: Column(
            children: [
              Row(
                children: [
                  Text(entry.numberLabel, style: sdvText(12, color: color)),
                  const Spacer(),
                  if (fav) const Icon(Icons.star_rounded, size: 16, color: Color(0xFFF9A825)),
                  if (showCollected && got) Icon(Icons.check_circle_rounded, size: 16, color: color),
                ],
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: LayoutBuilder(
                    builder: (context, c) {
                      final side = c.biggest.shortestSide;
                      return Center(
                        child: SdvSlot(
                          size: side,
                          child: EntryImage(entry: entry, size: side * 0.7),
                        ),
                      );
                    },
                  ),
                ),
              ),
              Text(
                entry.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: sdvText(14, color: Theme.of(context).colorScheme.onSurface),
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
        );
      },
    );
  }
}

/// Linha de lista com sprite no slot, nome e subtítulo.
class EntryTile extends StatelessWidget {
  final Entry entry;
  final Color? color;
  final VoidCallback? onTap;
  const EntryTile({super.key, required this.entry, this.color, this.onTap});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 3),
      child: Parchment(
        onTap: onTap ?? () => openEntry(context, entry),
        padding: const EdgeInsets.fromLTRB(4, 4, 2, 4),
        child: Row(
          children: [
            SdvSlot(size: 54, child: EntryImage(entry: entry, size: 38)),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(entry.name, style: sdvText(16, color: Theme.of(context).colorScheme.onSurface)),
                  if (entry.sub.isNotEmpty)
                    Text(entry.sub, maxLines: 2, overflow: TextOverflow.ellipsis, style: Theme.of(context).textTheme.bodySmall),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded),
          ],
        ),
      ),
    );
  }
}

/// Pequeno rótulo colorido (quadrado, como as etiquetas do jogo).
class TagPill extends StatelessWidget {
  final String text;
  final Color color;
  const TagPill(this.text, {super.key, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(2),
        border: Border.all(color: color.withValues(alpha: 0.7), width: 1.5),
      ),
      child: Text(text, style: sdvText(12, color: color)),
    );
  }
}

/// Limita a largura do conteúdo em telas largas (celular deitado, tablet) e
/// centraliza: o texto não estica de ponta a ponta. Em telas estreitas não muda nada.
class ContentWidth extends StatelessWidget {
  final Widget child;
  final double maxWidth;
  const ContentWidth({super.key, required this.child, this.maxWidth = 920});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(constraints: BoxConstraints(maxWidth: maxWidth), child: child),
    );
  }
}
