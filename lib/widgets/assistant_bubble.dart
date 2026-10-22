import 'package:flutter/material.dart';

import '../app_scope.dart';
import '../app_theme.dart';
import '../models.dart';
import '../search.dart';
import 'common.dart';

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
            if (msg.text.isEmpty && msg.busy) const Text('pensando…') else SelectableText(msg.text),
            if (!msg.user && !msg.busy && entries.isNotEmpty) ...[
              const SizedBox(height: 8),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [
                  for (final e in entries.take(4))
                    ActionChip(
                      avatar: Text(e.emoji),
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
