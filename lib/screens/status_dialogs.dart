part of 'status_screen.dart';

/// Abre um diálogo temático com o visual autêntico do Stardew Valley.
/// Garante que qualquer texto longo seja exibido por completo com rolagem confortável.
void showStatusDetailDialog(
  BuildContext context, {
  required String title,
  required Widget content,
  String? tag,
  Color? tagColor,
  IconData? icon,
  String? emoji,
}) {
  showGeneralDialog<void>(
    context: context,
    barrierDismissible: true,
    barrierLabel: 'Fechar',
    barrierColor: Colors.black.withValues(alpha: 0.72),
    transitionDuration: const Duration(milliseconds: 200),
    pageBuilder: (dialogContext, _, _) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480, maxHeight: 600),
            child: Material(
              color: Colors.transparent,
              child: DefaultTextStyle(
                style: const TextStyle(
                  color: _ink,
                  decoration: TextDecoration.none,
                ),
                child: _GamePanel(
                  accent: _gold,
                  padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Cabeçalho RPG
                      Row(
                        children: [
                          if (emoji != null)
                            Padding(
                              padding: const EdgeInsets.only(right: 6),
                              child: Text(emoji, style: const TextStyle(fontSize: 22)),
                            )
                          else if (icon != null)
                            Padding(
                              padding: const EdgeInsets.only(right: 6),
                              child: Icon(icon, color: _gold, size: 22),
                            ),
                          Expanded(
                            child: Text(
                              title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontFamily: 'PixelifySans',
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                                color: _ink,
                                height: 1.1,
                              ),
                            ),
                          ),
                          if (tag != null) ...[
                            const SizedBox(width: 6),
                            _TinyTag(tag, tagColor ?? _blue),
                          ],
                          const SizedBox(width: 4),
                          GestureDetector(
                            onTap: () => Navigator.of(dialogContext).pop(),
                            child: Container(
                              padding: const EdgeInsets.all(4),
                              decoration: BoxDecoration(
                                color: _wood.withValues(alpha: 0.1),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.close_rounded, size: 18, color: _ink),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Container(
                        height: 1.5,
                        decoration: BoxDecoration(
                          color: _gold.withValues(alpha: 0.4),
                          borderRadius: BorderRadius.circular(1),
                        ),
                      ),
                      const SizedBox(height: 10),

                      // Conteúdo rolável completo
                      Flexible(
                        child: SingleChildScrollView(
                          physics: const BouncingScrollPhysics(),
                          child: content,
                        ),
                      ),

                      const SizedBox(height: 12),
                      // Rodapé com botão de fechar estilo Stardew
                      Align(
                        alignment: Alignment.centerRight,
                        child: FilledButton.tonal(
                          style: FilledButton.styleFrom(
                            backgroundColor: _gold,
                            foregroundColor: _ink,
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(6),
                              side: const BorderSide(color: _woodDark, width: 1.2),
                            ),
                          ),
                          onPressed: () => Navigator.of(dialogContext).pop(),
                          child: const Text(
                            'ENTENDI',
                            style: TextStyle(
                              fontFamily: 'PixelifySans',
                              fontWeight: FontWeight.w700,
                              fontSize: 13,
                              letterSpacing: 1,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      );
    },
  );
}

/// Modal detalhado para Missões com texto 100% completo e recompensas.
void showQuestDetailDialog(BuildContext context, ApiQuest quest) {
  final objective = quest.currentObjective.trim();
  final desc = quest.description.trim();

  showStatusDetailDialog(
    context,
    title: quest.title,
    emoji: '📜',
    tag: quest.isTimedQuest && quest.daysLeft != null
        ? '${quest.daysLeft} DIA(S) RESTANTE(S)'
        : 'DIÁRIO',
    tagColor: quest.isTimedQuest ? _red : _blue,
    content: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (objective.isNotEmpty) ...[
          Container(
            padding: const EdgeInsets.all(9),
            decoration: BoxDecoration(
              color: _paper2,
              borderRadius: BorderRadius.circular(6),
              border: const Border(left: BorderSide(color: _gold, width: 4)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'OBJETIVO ATUAL',
                  style: TextStyle(
                    fontSize: 9.5,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.8,
                    color: Color(0xFF7A5826),
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  objective,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    height: 1.25,
                    color: _ink,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
        ],

        if (desc.isNotEmpty) ...[
          const Text(
            'DESCRIÇÃO DA MISSÃO',
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.8,
              color: Color(0xFF7A5826),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            desc,
            style: const TextStyle(
              fontSize: 12.5,
              height: 1.35,
              color: Color(0xFF3E2818),
            ),
          ),
          const SizedBox(height: 10),
        ],

        if (quest.hasMoneyReward || (quest.rewardDescription ?? '').isNotEmpty) ...[
          const Text(
            'RECOMPENSAS',
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.8,
              color: Color(0xFF7A5826),
            ),
          ),
          const SizedBox(height: 4),
          Wrap(
            spacing: 6,
            runSpacing: 4,
            children: [
              if (quest.hasMoneyReward && quest.moneyReward != null)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: _gold.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: _gold),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text('🪙', style: TextStyle(fontSize: 13)),
                      const SizedBox(width: 4),
                      Text(
                        '+${moneyLabel(quest.moneyReward!)}',
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 12,
                          color: _ink,
                        ),
                      ),
                    ],
                  ),
                ),
              if (quest.rewardDescription != null && quest.rewardDescription!.isNotEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: _green.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: _green),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text('🎁', style: TextStyle(fontSize: 13)),
                      const SizedBox(width: 4),
                      Text(
                        quest.rewardDescription!,
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 11.5,
                          color: _ink,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ],
      ],
    ),
  );
}

/// Modal detalhado para Itens do inventário com qualidade e utilidade.
void showItemDetailDialog(BuildContext context, ApiItem item, Entry? entry) {
  final name = item.displayName.isNotEmpty ? item.displayName : item.name;
  final qualityLabel = switch (item.quality) {
    1 => '★ Prata',
    2 => '★★ Ouro',
    4 => '★★★ Irídio',
    _ => 'Normal',
  };

  showStatusDetailDialog(
    context,
    title: name,
    emoji: entry != null ? null : '📦',
    icon: entry != null ? null : Icons.inventory_2_rounded,
    tag: 'QTD: x${item.stackSize}',
    tagColor: _green,
    content: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Container(
              width: 54,
              height: 54,
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: _paper2,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: _gold, width: 1.5),
              ),
              child: entry != null
                  ? Center(child: EntryImage(entry: entry, size: 44))
                  : const Center(child: Text('📦', style: TextStyle(fontSize: 28))),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: const TextStyle(
                      fontFamily: 'PixelifySans',
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: _ink,
                    ),
                  ),
                  if (item.name != name && item.name.isNotEmpty) ...[
                    Text(
                      item.name,
                      style: const TextStyle(fontSize: 11, color: Color(0xFF7A5826)),
                    ),
                  ],
                  const SizedBox(height: 3),
                  Wrap(
                    spacing: 4,
                    children: [
                      _TinyTag(qualityLabel, _gold),
                      if (entry != null)
                        _TinyTag(entry.cat.toUpperCase(), _blue),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (entry != null && entry.desc.isNotEmpty) ...[
          const Text(
            'SOBRE O ITEM',
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.8,
              color: Color(0xFF7A5826),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            entry.desc,
            style: const TextStyle(fontSize: 12.5, height: 1.3, color: Color(0xFF3E2818)),
          ),
          const SizedBox(height: 8),
        ],
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: _paper2,
            borderRadius: BorderRadius.circular(6),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('• ID Técnico: ${item.qualifiedItemId.isNotEmpty ? item.qualifiedItemId : item.itemId}',
                  style: const TextStyle(fontSize: 11, color: Color(0xFF6B5238))),
              Text('• Quantidade na mochila: ${item.stackSize}',
                  style: const TextStyle(fontSize: 11, color: Color(0xFF6B5238))),
              Text('• Qualidade da colheita: $qualityLabel',
                  style: const TextStyle(fontSize: 11, color: Color(0xFF6B5238))),
            ],
          ),
        ),
      ],
    ),
  );
}

