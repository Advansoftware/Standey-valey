import 'package:flutter/material.dart';

class Category {
  final String id;
  final String title;
  final String emoji;
  final String desc;
  final String collect;
  final Color color;
  final int count;

  const Category({
    required this.id,
    required this.title,
    required this.emoji,
    required this.desc,
    required this.collect,
    required this.color,
    required this.count,
  });

  factory Category.fromJson(Map<String, dynamic> j) {
    final hex = (j['color'] as String).replaceFirst('#', '');
    return Category(
      id: j['id'] as String,
      title: j['title'] as String,
      emoji: j['emoji'] as String,
      desc: (j['desc'] as String?) ?? '',
      collect: (j['collect'] as String?) ?? '',
      color: Color(0xFF000000 | int.parse(hex, radix: 16)),
      count: (j['count'] as num?)?.toInt() ?? 0,
    );
  }
}

class Entry {
  final String id;
  final String cat;
  final String en;
  String pt;
  final String emoji;
  final String sub;
  final String img;
  final String desc;
  final String body;
  final int n;
  final List<String> tags;
  final List<List<String>> fields;
  final List<String> checklist;
  final List<List<String>> gallery;
  final Map<String, dynamic> meta;

  Entry({
    required this.id,
    required this.cat,
    required this.en,
    required this.pt,
    required this.emoji,
    required this.sub,
    required this.img,
    required this.desc,
    required this.body,
    required this.n,
    required this.tags,
    required this.fields,
    required this.checklist,
    required this.gallery,
    required this.meta,
  });

  String get name => pt.isNotEmpty ? pt : en;
  String get numberLabel => '#${n.toString().padLeft(3, '0')}';

  factory Entry.fromJson(Map<String, dynamic> j) {
    final fields = <List<String>>[];
    for (final row in (j['fields'] as List? ?? const [])) {
      fields.add((row as List).map((e) => e.toString()).toList());
    }
    return Entry(
      id: j['id'] as String,
      cat: (j['cat'] as String?) ?? '',
      en: (j['en'] as String?) ?? '',
      pt: (j['pt'] as String?) ?? '',
      emoji: (j['emoji'] as String?) ?? '📦',
      sub: (j['sub'] as String?) ?? '',
      img: (j['img'] as String?) ?? '',
      desc: (j['desc'] as String?) ?? '',
      body: (j['body'] as String?) ?? '',
      n: (j['n'] as num?)?.toInt() ?? 0,
      tags: ((j['tags'] as List?) ?? const []).map((e) => e.toString()).toList(),
      fields: fields,
      gallery: ((j['gallery'] as List?) ?? const []).map((e) => (e as List).map((x) => x.toString()).toList()).toList(),
      checklist: ((j['checklist'] as List?) ?? const []).map((e) => e.toString()).toList(),
      meta: Map<String, dynamic>.from((j['meta'] as Map?) ?? const {}),
    );
  }

  /// Texto completo usado na busca e como contexto da IA.
  String get fullText {
    final b = StringBuffer();
    b.writeln(name);
    if (en.isNotEmpty && en != name) b.writeln('($en)');
    if (sub.isNotEmpty) b.writeln(sub);
    for (final f in fields) {
      if (f.length >= 2) b.writeln('${f[0]}: ${f[1]}');
    }
    if (desc.isNotEmpty) b.writeln(desc);
    if (checklist.isNotEmpty) b.writeln('Itens: ${checklist.join(', ')}');
    if (body.isNotEmpty) b.writeln(body);
    return b.toString();
  }
}

class CalendarEvent {
  final Entry entry;
  final String kind; // 'aniversario' | 'festival'
  const CalendarEvent(this.entry, this.kind);

  String get label =>
      kind == 'aniversario' ? 'Aniversário de ${entry.name}' : entry.name;
  String get emoji => kind == 'aniversario' ? '🎂' : entry.emoji;
}

const seasonNames = ['Primavera', 'Verão', 'Outono', 'Inverno'];
const seasonEmojis = ['🌱', '☀️', '🍂', '❄️'];
