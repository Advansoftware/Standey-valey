import 'package:flutter/material.dart';

import '../app_scope.dart';
import '../app_theme.dart';
import '../models.dart';
import '../widgets/common.dart';

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  int? _season;

  @override
  Widget build(BuildContext context) {
    final scope = AppScope.of(context);
    final store = scope.store;
    final repo = scope.repo;
    final season = _season ?? store.season;

    return Scaffold(
      appBar: AppBar(title: const Text('Calendário')),
      body: ListenableBuilder(
        listenable: store,
        builder: (context, _) {
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
                          onSelected: (_) => setState(() => _season = s),
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
                          Expanded(child: Center(child: Text(d, style: const TextStyle(fontWeight: FontWeight.w800)))),
                      ],
                    ),
                    const SizedBox(height: 6),
                    for (var week = 0; week < 4; week++)
                      Row(
                        children: [
                          for (var i = 0; i < 7; i++) Expanded(child: _DayCell(season: season, day: week * 7 + i + 1)),
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
                    child: ListTile(
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      tileColor: Theme.of(context).brightness == Brightness.dark ? const Color(0xFF2A241A) : const Color(0xFFFFFBEB),
                      leading: Text(ev.emoji, style: const TextStyle(fontSize: 26)),
                      title: Text(ev.label, style: const TextStyle(fontWeight: FontWeight.w800)),
                      subtitle: Text('${seasonNames[season]} $d'),
                      trailing: const Icon(Icons.chevron_right_rounded),
                      onTap: () => openEntry(context, ev.entry),
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
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Data do jogo: ${seasonNames[season]} $day')),
        );
      },
      child: Container(
        margin: const EdgeInsets.all(2),
        height: 54,
        decoration: BoxDecoration(
          color: isToday ? scheme.primary.withValues(alpha: 0.25) : (events.isNotEmpty ? const Color(0xFFF9A825).withValues(alpha: 0.16) : null),
          borderRadius: BorderRadius.circular(10),
          border: isToday ? Border.all(color: scheme.primary, width: 2) : null,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('$day', style: TextStyle(fontWeight: isToday ? FontWeight.w900 : FontWeight.w600)),
            if (events.isNotEmpty)
              Text(events.take(2).map((e) => e.emoji).join(), style: const TextStyle(fontSize: 12)),
          ],
        ),
      ),
    );
  }

  void _showDay(BuildContext context, List<CalendarEvent> events) {
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
              Text('${seasonNames[season]} $day', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900)),
              const SizedBox(height: 8),
              if (events.isEmpty) const Text('Sem eventos. Segure o dedo no dia para defini-lo como "hoje".'),
              for (final ev in events)
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Text(ev.emoji, style: const TextStyle(fontSize: 26)),
                  title: Text(ev.label, style: const TextStyle(fontWeight: FontWeight.w800)),
                  onTap: () {
                    Navigator.of(context).pop();
                    openEntry(context, ev.entry);
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }
}
