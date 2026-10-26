import 'package:flutter/material.dart';

import '../app_scope.dart';
import '../app_theme.dart';
import '../models.dart';
import '../widgets/sdv_notice.dart';
import '../widgets/common.dart';
import '../widgets/stardew_ui.dart';

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  @override
  Widget build(BuildContext context) {
    final scope = AppScope.of(context);
    final store = scope.store;
    final repo = scope.repo;

    return Scaffold(
      appBar: AppBar(title: const Text('Calendário')),
      body: ListenableBuilder(
        listenable: store,
        builder: (context, _) {
          // Sempre a estação atual do jogo: mudar a data em outra tela
          // (início, por exemplo) atualiza o calendário na hora.
          final season = store.season;
          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
            children: [
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    for (var s = 0; s < 4; s++)
                      Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: ChoiceChip(
                          label: Text('${seasonEmojis[s]} ${seasonNames[s]}'),
                          selected: season == s,
                          onSelected: (_) => store.setDate(s, store.day),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: parchment(context),
                child: Column(
                  children: [
                    Row(
                      children: [
                        for (final d in ['S', 'T', 'Q', 'Q', 'S', 'S', 'D'])
                          Expanded(
                            child: Center(
                              child: Text(
                                d,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    for (var week = 0; week < 4; week++)
                      Row(
                        children: [
                          for (var i = 0; i < 7; i++)
                            Expanded(
                              child: _DayCell(
                                season: season,
                                day: week * 7 + i + 1,
                              ),
                            ),
                        ],
                      ),
                  ],
                ),
              ),
              const SectionTitle('Eventos da estação'),
              for (var d = 1; d <= 28; d++)
                for (final ev in repo.eventsOn(season, d))
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 3),
                    child: Parchment(
                      onTap: () => openEntry(context, ev.entry),
                      child: Row(
                        children: [
                          SdvSlot(
                            size: 46,
                            child: Text(
                              ev.emoji,
                              style: const TextStyle(fontSize: 22),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  ev.label,
                                  style: sdvText(
                                    15,
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.onSurface,
                                  ),
                                ),
                                Text(
                                  '${seasonNames[season]} $d',
                                  style: Theme.of(context).textTheme.bodySmall,
                                ),
                              ],
                            ),
                          ),
                          const Icon(Icons.chevron_right_rounded),
                        ],
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

class _DayCell extends StatelessWidget {
  final int season;
  final int day;
  const _DayCell({required this.season, required this.day});

  @override
  Widget build(BuildContext context) {
    final scope = AppScope.of(context);
    final store = scope.store;
    final events = scope.repo.eventsOn(season, day);
    final isToday = store.season == season && store.day == day;
    final scheme = Theme.of(context).colorScheme;
    return GestureDetector(
      onTap: () => _showDay(context, events),
      onLongPress: () {
        store.setDate(season, day);
        showSdvNotice(context, 'Data do jogo: ${seasonNames[season]} $day');
      },
      child: Container(
        margin: const EdgeInsets.all(2),
        height: 54,
        decoration: BoxDecoration(
          color: isToday
              ? scheme.primary.withValues(alpha: 0.25)
              : (events.isNotEmpty
                    ? const Color(0xFFF9A825).withValues(alpha: 0.16)
                    : null),
          borderRadius: BorderRadius.circular(3),
          border: isToday ? Border.all(color: scheme.primary, width: 2) : null,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              '$day',
              style: TextStyle(
                fontWeight: isToday ? FontWeight.w700 : FontWeight.w600,
              ),
            ),
            if (events.isNotEmpty)
              Text(
                events.take(2).map((e) => e.emoji).join(),
                style: const TextStyle(fontSize: 12),
              ),
          ],
        ),
      ),
    );
  }

  void _showDay(BuildContext context, List<CalendarEvent> events) {
    final store = AppScope.of(context).store;
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${seasonNames[season]} $day',
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 8),
              if (events.isEmpty) const Text('Sem eventos neste dia.'),
              for (final ev in events)
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Text(ev.emoji, style: const TextStyle(fontSize: 26)),
                  title: Text(
                    ev.label,
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                  onTap: () {
                    Navigator.of(context).pop();
                    openEntry(context, ev.entry);
                  },
                ),
              const SizedBox(height: 8),
              FilledButton.icon(
                icon: const Icon(Icons.today_rounded),
                label: Text('Definir ${seasonNames[season]} $day como hoje'),
                onPressed: () {
                  store.setDate(season, day);
                  Navigator.of(context).pop();
                  showSdvNotice(
                    context,
                    'Data do jogo: ${seasonNames[season]} $day',
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
