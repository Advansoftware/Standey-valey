import 'dart:convert';

import 'package:flutter/services.dart';

import 'models.dart';

/// Carrega o conteúdo da enciclopédia a partir dos assets.
class Repository {
  final List<Category> categories;
  final Map<String, List<Entry>> byCat;
  final List<Entry> all;
  final Map<String, Entry> byId;
  final Map<int, List<CalendarEvent>> _events;

  Repository._(this.categories, this.byCat, this.all, this.byId, this._events);

  static Future<Repository> load() async {
    final idx = jsonDecode(await rootBundle.loadString('assets/data/index.json'))
        as Map<String, dynamic>;
    final cats = <Category>[];
    final byCat = <String, List<Entry>>{};
    final all = <Entry>[];
    final byId = <String, Entry>{};

    // Nomes em PT-BR vindos da wiki (gerado por tools/scrape_wiki.py), opcional.
    // Só entram onde ainda não há tradução (nome vazio ou igual ao inglês):
    // assim a wiki completa o que falta sem sobrescrever traduções curadas.
    Map<String, dynamic> namesPt = const {};
    try {
      namesPt = jsonDecode(await rootBundle.loadString('assets/data/names_pt.json'))
          as Map<String, dynamic>;
    } catch (_) {}

    for (final c in (idx['categories'] as List)) {
      final cat = Category.fromJson(c as Map<String, dynamic>);
      cats.add(cat);
      final data = jsonDecode(await rootBundle.loadString('assets/data/${cat.id}.json'))
          as Map<String, dynamic>;
      final list = <Entry>[];
      for (final e in (data['entries'] as List)) {
        final entry = Entry.fromJson(e as Map<String, dynamic>);
        final needsTranslation = entry.pt.isEmpty || entry.pt == entry.en;
        final override = namesPt[entry.en];
        if (needsTranslation && override is String && override.isNotEmpty && override != entry.en) {
          entry.pt = override;
        }
        list.add(entry);
        all.add(entry);
        byId[entry.id] = entry;
      }
      byCat[cat.id] = list;
    }

    final events = <int, List<CalendarEvent>>{};
    for (final e in byCat['aldeoes'] ?? const <Entry>[]) {
      final s = (e.meta['season'] as num?)?.toInt();
      final d = (e.meta['day'] as num?)?.toInt();
      if (s != null && d != null) {
        events.putIfAbsent(s * 100 + d, () => []).add(CalendarEvent(e, 'aniversario'));
      }
    }
    for (final e in byCat['festivais'] ?? const <Entry>[]) {
      final s = (e.meta['season'] as num?)?.toInt();
      final days = (e.meta['days'] as List?) ?? const [];
      if (s != null) {
        for (final d in days) {
          events.putIfAbsent(s * 100 + (d as num).toInt(), () => []).add(CalendarEvent(e, 'festival'));
        }
      }
    }
    return Repository._(cats, byCat, all, byId, events);
  }

  Category category(String id) => categories.firstWhere((c) => c.id == id);

  List<CalendarEvent> eventsOn(int season, int day) =>
      _events[season * 100 + day] ?? const [];

  /// Próximos eventos a partir de (season, day), até [days] dias à frente.
  List<MapEntry<int, CalendarEvent>> upcoming(int season, int day, int days) {
    final out = <MapEntry<int, CalendarEvent>>[];
    final seen = <String>{};
    var s = season;
    var d = day;
    for (var i = 0; i <= days; i++) {
      for (final ev in eventsOn(s, d)) {
        // Festivais de vários dias aparecem só no primeiro dia.
        if (seen.add(ev.label)) out.add(MapEntry(i, ev));
      }
      d++;
      if (d > 28) {
        d = 1;
        s = (s + 1) % 4;
      }
    }
    return out;
  }

  /// Culturas que podem ser plantadas na estação.
  List<Entry> cropsFor(int season) {
    final name = seasonNames[season];
    return (byCat['culturas'] ?? const <Entry>[])
        .where((e) => e.tags.contains(name))
        .toList();
  }
}
