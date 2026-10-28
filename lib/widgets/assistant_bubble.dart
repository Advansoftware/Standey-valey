import 'package:flutter/material.dart';

import '../app_scope.dart';
import '../app_theme.dart';
import '../models.dart';
import '../search.dart';
import 'common.dart';
import 'markdown_lite.dart';

/// Uma mensagem do chat (do usuário ou do assistente).
class ChatMessage {
  final bool user;
  String text;
  List<Hit> sources;
  bool busy;
  ChatMessage({required this.user, this.text = '', this.sources = const [], this.busy = false});
}

/// Balão de uma mensagem do chat.
class AssistantBubble extends StatelessWidget {
  final ChatMessage msg;
  const AssistantBubble({super.key, required this.msg});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final search = AppScope.of(context).search;
    final entries = <Entry>[];
    final seen = <String>{};
    for (final h in msg.sources) {
      final e = search.entryOf(h.doc);
      if (e != null && seen.add(e.id)) entries.add(e);
    }
    // Atalhos para as fichas que a resposta cita, na ordem do texto; se ela
    // não citar nenhuma (ex.: resposta da busca sem IA), ficam as duas
    // primeiras da busca.
    final shortcuts = msg.busy || msg.user ? <Entry>[] : citedEntries(AppScope.of(context).repo.all, msg.text);
    if (shortcuts.isEmpty) shortcuts.addAll(entries.take(2));
    return Align(
      alignment: msg.user ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(top: 10),
        padding: const EdgeInsets.all(12),
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.88),
        decoration: msg.user
            ? BoxDecoration(color: scheme.primary.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(18))
            : parchment(context, radius: 18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (msg.text.isEmpty && msg.busy)
              const Text('pensando…')
            else if (msg.user)
              SelectableText(msg.text)
            else
              MarkdownLite(msg.text),
            if (!msg.user && !msg.busy && shortcuts.isNotEmpty) ...[
              const SizedBox(height: 8),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [
                  for (final e in shortcuts.take(4))
                    ActionChip(
                      avatar: EntryImage(entry: e, size: 24),
                      label: Text(e.name),
                      onPressed: () => openEntry(context, e),
                    ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Sugestões de perguntas para começar a conversa.
class AssistantSuggestions extends StatelessWidget {
  final void Function(String) onTap;
  const AssistantSuggestions({super.key, required this.onTap});

  static const questions = [
    'O que devo fazer no primeiro dia?',
    'Como ganhar dinheiro no começo?',
    'Qual árvore é o carvalho?',
    'O que a Abigail ama?',
    'Onde pescar o baiacu?',
    'O que plantar na primavera?',
  ];

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [for (final q in questions) ActionChip(label: Text(q), onPressed: () => onTap(q))],
    );
  }
}

/// Fichas cujo nome aparece no texto (palavra inteira), na ordem em que
/// aparecem. Nomes curtos demais ficam de fora para não confundir.
List<Entry> citedEntries(Iterable<Entry> all, String text) {
  final t = ' ${normalize(text).replaceAll(RegExp(r'[^a-z0-9]+'), ' ')} ';
  final found = <(int, Entry)>[];
  final seen = <String>{};
  for (final e in all) {
    final name = normalize(e.name).replaceAll(RegExp(r'[^a-z0-9]+'), ' ').trim();
    if (name.length < 4 || !seen.add(name)) continue;
    final at = t.indexOf(' $name ');
    if (at >= 0) found.add((at, e));
  }
  found.sort((a, b) => a.$1.compareTo(b.$1));
  // "Isca Mágica" já cobre "Isca": tira nomes contidos num nome maior citado.
  final names = [for (final f in found) normalize(f.$2.name)];
  return [
    for (final f in found)
      if (!names.any((n) => n != normalize(f.$2.name) && n.contains(normalize(f.$2.name)))) f.$2,
  ];
}
