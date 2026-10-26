import 'package:flutter/material.dart';

import '../app_scope.dart';
import '../app_theme.dart';
import '../models.dart';
import '../widgets/common.dart';
import '../widgets/stardew_ui.dart';
import 'assistant_screen.dart';

class DetailScreen extends StatelessWidget {
  final Entry entry;
  const DetailScreen({super.key, required this.entry});

  @override
  Widget build(BuildContext context) {
    final scope = AppScope.of(context);
    final store = scope.store;
    final cat = scope.repo.category(entry.cat);
    return ListenableBuilder(
      listenable: store,
      builder: (context, _) {
        final fav = store.isFav(entry.id);
        return Scaffold(
          appBar: AppBar(
            title: Text(entry.name, maxLines: 1, overflow: TextOverflow.ellipsis),
            actions: [
              IconButton(
                tooltip: 'Favoritar',
                icon: Icon(fav ? Icons.star_rounded : Icons.star_border_rounded, color: fav ? const Color(0xFFF9A825) : null),
                onPressed: () => store.toggleFav(entry.id),
              ),
            ],
          ),
          body: ContentWidth(child: ListView(
            padding: const EdgeInsets.only(bottom: 32),
            children: [
              _Header(entry: entry, cat: cat),
              if (cat.collect.isNotEmpty && entry.checklist.isEmpty)
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                  child: Parchment(
                    accent: cat.color,
                    child: SwitchListTile(
                      value: store.isCollected(entry.id),
                      onChanged: (_) => store.toggleCollected(entry.id),
                      title: Text(cat.collect, style: const TextStyle(fontWeight: FontWeight.w700)),
                      secondary: Icon(Icons.check_circle_outline_rounded, color: cat.color),
                    ),
                  ),
                ),
              if (entry.desc.isNotEmpty && entry.body.isEmpty)
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                  child: Text(entry.desc, style: Theme.of(context).textTheme.bodyLarge),
                ),
              if (entry.gallery.length > 1) _Gallery(entry: entry, color: cat.color),
              if (entry.fields.isNotEmpty) _Fields(entry: entry, color: cat.color),
              if (entry.checklist.isNotEmpty) _Checklist(entry: entry, color: cat.color),
              if (entry.body.isNotEmpty) BodyView(text: entry.body),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
                child: Row(
                  children: [
                    Expanded(
                      child: FilledButton.icon(
                        icon: const Icon(Icons.auto_awesome_rounded),
                        label: const Text('Perguntar à IA'),
                        onPressed: () => Navigator.of(context).push(MaterialPageRoute<void>(
                          builder: (_) => AssistantScreen(initialQuestion: 'Me explique sobre ${entry.name}'),
                        )),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          )),
        );
      },
    );
  }
}

class _Header extends StatelessWidget {
  final Entry entry;
  final Category cat;
  const _Header({required this.entry, required this.cat});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
      child: Parchment(
      padding: const EdgeInsets.all(6),
      child: Column(
        children: [
          Row(
            children: [
              Text('${cat.emoji} ${cat.title}',
                  style: sdvText(14, color: cat.color)),
              const Spacer(),
              if (entry.n > 0)
                Text(entry.numberLabel, style: sdvText(15, color: cat.color)),
            ],
          ),
          const SizedBox(height: 8),
          SdvSlot(size: 150, child: EntryImage(entry: entry, size: 110)),
          const SizedBox(height: 12),
          Text(entry.name,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700)),
          if (entry.en.isNotEmpty && entry.en != entry.name)
            Text(entry.en, style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontStyle: FontStyle.italic)),
          if (entry.tags.isNotEmpty) ...[
            const SizedBox(height: 10),
            Wrap(
              alignment: WrapAlignment.center,
              spacing: 6,
              runSpacing: 6,
              children: [for (final t in entry.tags) TagPill(t, color: cat.color)],
            ),
          ],
        ],
      ),
      ),
    );
  }
}

class _Fields extends StatelessWidget {
  final Entry entry;
  final Color color;
  const _Fields({required this.entry, required this.color});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 14, 12, 0),
      child: Parchment(
      padding: const EdgeInsets.all(4),
      child: Column(
        children: [
          for (var i = 0; i < entry.fields.length; i++) ...[
            if (i > 0) Divider(height: 18, color: color.withValues(alpha: 0.25)),
            _FieldRow(label: entry.fields[i][0], value: entry.fields[i].length > 1 ? entry.fields[i][1] : '', color: color),
          ],
        ],
      ),
      ),
    );
  }
}

class _FieldRow extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  const _FieldRow({required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    final asChips = label == 'Presentes amados';
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 118,
          child: Text(label, style: sdvText(14, color: Theme.of(context).colorScheme.primary)),
        ),
        Expanded(
          child: asChips
              ? Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [for (final g in value.split(', ')) TagPill('❤ $g', color: color)],
                )
              : Text(value),
        ),
      ],
    );
  }
}

class _Checklist extends StatelessWidget {
  final Entry entry;
  final Color color;
  const _Checklist({required this.entry, required this.color});

  @override
  Widget build(BuildContext context) {
    final store = AppScope.of(context).store;
    final need = (entry.meta['need'] as num?)?.toInt() ?? entry.checklist.length;
    final done = store.checkedCount(entry.id, entry.checklist);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: Parchment(
        accent: color,
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
              child: Row(
                children: [
                  Text('Checklist', style: sdvText(16, color: Theme.of(context).colorScheme.primary)),
                  const Spacer(),
                  Text('$done de $need', style: sdvText(15, color: Theme.of(context).colorScheme.onSurface)),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: SdvProgressBar(value: need == 0 ? 0 : done / need, color: color),
            ),
            for (final item in entry.checklist)
              CheckboxListTile(
                dense: true,
                value: store.isChecked(entry.id, item),
                onChanged: (_) => store.toggleCheck(entry.id, item),
                title: Text(item),
                controlAffinity: ListTileControlAffinity.leading,
                activeColor: color,
              ),
          ],
        ),
      ),
    );
  }
}

/// Renderiza texto simples com '## títulos' e '• itens'.
class BodyView extends StatelessWidget {
  final String text;
  const BodyView({super.key, required this.text});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final widgets = <Widget>[];
    for (final raw in text.split('\n')) {
      final line = raw.trimRight();
      if (line.isEmpty) {
        widgets.add(const SizedBox(height: 6));
      } else if (line.startsWith('## ')) {
        widgets.add(Padding(
          padding: const EdgeInsets.only(top: 14, bottom: 4),
          child: Text(line.substring(3), style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700, color: theme.colorScheme.primary)),
        ));
      } else if (line.startsWith('• ')) {
        widgets.add(Padding(
          padding: const EdgeInsets.symmetric(vertical: 3),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('•  ', style: TextStyle(fontWeight: FontWeight.w700)),
              Expanded(child: Text(line.substring(2), style: theme.textTheme.bodyLarge)),
            ],
          ),
        ));
      } else {
        widgets.add(Text(line, style: theme.textTheme.bodyLarge));
      }
    }
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 14, 12, 0),
      child: Parchment(
        padding: const EdgeInsets.all(6),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: widgets),
      ),
    );
  }
}


/// Faixa horizontal com os sprites do jogo (estágios de crescimento, variantes…).
class _Gallery extends StatelessWidget {
  final Entry entry;
  final Color color;
  const _Gallery({required this.entry, required this.color});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 16),
      child: SizedBox(
        height: 112,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          itemCount: entry.gallery.length,
          separatorBuilder: (_, _) => const SizedBox(width: 10),
          itemBuilder: (context, i) {
            final g = entry.gallery[i];
            return SizedBox(
              width: 92,
              child: SdvFrame(
              style: SdvFrameStyle.inset,
              px: 2,
              padding: const EdgeInsets.all(7),
              child: Column(
                children: [
                  Expanded(
                    child: Image.asset('assets/img/${g[0]}', fit: BoxFit.contain, filterQuality: FilterQuality.none,
                        errorBuilder: (_, _, _) => const SizedBox()),
                  ),
                  const SizedBox(height: 4),
                  Text(g.length > 1 ? g[1] : '', maxLines: 1, overflow: TextOverflow.ellipsis, style: sdvText(11)),
                ],
              ),
              ),
            );
          },
        ),
      ),
    );
  }
}
