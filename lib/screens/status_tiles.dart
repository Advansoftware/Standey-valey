part of 'status_screen.dart';

/// Objetivo vindo do conselheiro, desenhado como entrada do diário de missões.
class _AiObjectiveTile extends StatelessWidget {
  final AiObjective objective;
  final int index;
  const _AiObjectiveTile({required this.objective, required this.index});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 5),
      padding: const EdgeInsets.fromLTRB(6, 6, 7, 6),
      decoration: BoxDecoration(
        color: _paper2,
        borderRadius: BorderRadius.circular(6),
        border: const Border(left: BorderSide(color: _blue, width: 3)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 21,
            height: 21,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(4),
              border: Border.all(
                color: _blue.withValues(alpha: 0.65),
                width: 1.4,
              ),
            ),
            child: Text(
              '${index + 1}',
              style: const TextStyle(
                fontFamily: 'PixelifySans',
                fontSize: 12,
                height: 1,
                fontWeight: FontWeight.w700,
                color: _blue,
              ),
            ),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  objective.action,
                  style: const TextStyle(
                    fontFamily: 'PixelifySans',
                    fontSize: 14,
                    height: 1.1,
                    fontWeight: FontWeight.w700,
                    color: _ink,
                  ),
                ),
                if ((objective.place ?? '').isNotEmpty ||
                    (objective.detail ?? '').isNotEmpty) ...[
                  const SizedBox(height: 3),
                  Wrap(
                    spacing: 5,
                    runSpacing: 3,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      if ((objective.place ?? '').isNotEmpty)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 5,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: _green.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(4),
                            border: Border.all(
                              color: _green.withValues(alpha: 0.35),
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.place_rounded,
                                size: 11,
                                color: _green,
                              ),
                              const SizedBox(width: 2),
                              Text(
                                objective.place!,
                                style: const TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w900,
                                  color: _green,
                                ),
                              ),
                            ],
                          ),
                        ),
                      if ((objective.detail ?? '').isNotEmpty)
                        Text(
                          objective.detail!,
                          style: const TextStyle(
                            fontSize: 10.5,
                            height: 1.15,
                            color: Color(0xFF6B5238),
                          ),
                        ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _QuestTile extends StatelessWidget {
  final ApiQuest quest;
  const _QuestTile({required this.quest});

  @override
  Widget build(BuildContext context) {
    final objective = quest.currentObjective.trim();
    final desc = quest.description.trim();
    return Container(
      margin: const EdgeInsets.only(bottom: 5),
      padding: const EdgeInsets.fromLTRB(7, 6, 7, 6),
      decoration: BoxDecoration(
        color: _paper2,
        borderRadius: BorderRadius.circular(6),
        border: Border(left: BorderSide(color: _blue, width: 3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  quest.title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: 12.5,
                    color: _ink,
                  ),
                ),
              ),
              if (quest.isTimedQuest && quest.daysLeft != null)
                _TinyTag('${quest.daysLeft}D', _red),
            ],
          ),
          if (objective.isNotEmpty) ...[
            const SizedBox(height: 2),
            Text(
              objective,
              style: const TextStyle(
                fontSize: 11.5,
                height: 1.18,
                color: Color(0xFF4E3926),
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
          if (desc.isNotEmpty && desc != objective) ...[
            const SizedBox(height: 1),
            Text(
              desc,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 10.5,
                height: 1.15,
                color: Color(0xFF6B5238),
              ),
            ),
          ],
          if (quest.hasMoneyReward ||
              (quest.hasReward &&
                  (quest.rewardDescription ?? '').isNotEmpty)) ...[
            const SizedBox(height: 3),
            Wrap(
              spacing: 4,
              children: [
                if (quest.hasMoneyReward && quest.moneyReward != null)
                  _TinyTag('+${moneyLabel(quest.moneyReward!)}', _gold),
                if (quest.hasReward &&
                    (quest.rewardDescription ?? '').isNotEmpty)
                  _TinyTag(quest.rewardDescription!, _green),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _BirthdayChip extends StatelessWidget {
  final Entry? entry;
  final String name;
  const _BirthdayChip({this.entry, required this.name});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(4, 2, 6, 2),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF3D6),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: const Color(0xFFE6B34A)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (entry != null)
            EntryImage(entry: entry!, size: 20)
          else
            const Text('🎂', style: TextStyle(fontSize: 14)),
          const SizedBox(width: 3),
          Text(
            '🎂 ${entry?.name ?? name}',
            style: const TextStyle(
              fontSize: 10.5,
              fontWeight: FontWeight.w800,
              color: _ink,
            ),
          ),
        ],
      ),
    );
  }
}

class _ItemTile extends StatelessWidget {
  final ApiItem item;
  final Entry? entry;
  const _ItemTile({required this.item, this.entry});

  Color _qualityColor() {
    switch (item.quality) {
      case 1:
        return const Color(0xFF90A4AE);
      case 2:
        return const Color(0xFFF9A825);
      case 3:
      case 4:
        return const Color(0xFF8E24AA);
      default:
        return Colors.transparent;
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = entry != null
        ? AppScope.of(context).repo.category(entry!.cat).color
        : const Color(0xFF8D6E63);
    final icon = entry != null
        ? EntryImage(entry: entry!, size: 28)
        : Text(
            entry?.emoji ?? (item.typeDefinitionId == 'H' ? '🎩' : '📦'),
            style: const TextStyle(fontSize: 19),
          );
    return Tooltip(
      message:
          '${item.displayName.isNotEmpty ? item.displayName : item.name}\n'
          'Quantidade: ${item.stackSize}\nQualidade: ${item.quality}\nID: ${item.qualifiedItemId}\nCategoria: ${item.category}',
      child: Container(
        width: 59,
        height: 72,
        padding: const EdgeInsets.fromLTRB(3, 3, 3, 2),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.11),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: color.withValues(alpha: 0.5), width: 1),
        ),
        child: Column(
          children: [
            Expanded(
              child: Stack(
                children: [
                  Center(child: icon),
                  if (item.quality > 0)
                    Positioned(
                      top: 0,
                      left: 0,
                      child: Text(
                        '★',
                        style: TextStyle(
                          fontSize: 9,
                          color: _qualityColor(),
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: Text(
                      'x${item.stackSize}',
                      style: const TextStyle(
                        fontSize: 8.5,
                        fontWeight: FontWeight.w900,
                        color: _ink,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Text(
              item.displayName.isNotEmpty ? item.displayName : item.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 8, height: 1.05, color: _ink),
            ),
          ],
        ),
      ),
    );
  }
}

class _SkillTile extends StatelessWidget {
  final ApiSkill skill;
  const _SkillTile({required this.skill});

  @override
  Widget build(BuildContext context) {
    final asset = skillAsset(skill);
    final professions = skill.professions
        .map((p) => professionNamePt(p.name))
        .where((p) => p.trim().isNotEmpty)
        .toList();
    return Container(
      padding: const EdgeInsets.fromLTRB(6, 5, 6, 5),
      decoration: BoxDecoration(
        color: _paper2,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: const Color(0xFFD2B77F)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              SizedBox(
                width: 22,
                height: 22,
                child: asset != null
                    ? Image.asset(
                        'assets/img/$asset',
                        filterQuality: FilterQuality.none,
                        errorBuilder: (_, _, _) =>
                            Center(child: Text(skillEmoji(skill))),
                      )
                    : Text(
                        skillEmoji(skill),
                        style: const TextStyle(fontSize: 16),
                      ),
              ),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  skillNamePt(skill),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w900,
                    color: _ink,
                  ),
                ),
              ),
              Text(
                '${skill.level}',
                style: const TextStyle(
                  fontFamily: 'PixelifySans',
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: _ink,
                ),
              ),
            ],
          ),
          const SizedBox(height: 3),
          ClipRRect(
            borderRadius: BorderRadius.circular(2),
            child: LinearProgressIndicator(
              value: clamp01(skill.level / 10),
              minHeight: 4,
              backgroundColor: const Color(0xFFDCC79E),
              valueColor: const AlwaysStoppedAnimation(_green),
            ),
          ),
          if (professions.isNotEmpty) ...[
            const SizedBox(height: 3),
            Text(
              professions.join(' · '),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 8.5,
                height: 1.1,
                color: Color(0xFF6B5238),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _RelationshipTile extends StatelessWidget {
  final ApiRelationship rel;
  final Entry? entry;
  const _RelationshipTile({required this.rel, this.entry});

  String get _status {
    if (rel.isMarried) return 'casado(a)';
    if (rel.isEngaged) return 'noivo(a)';
    if (rel.isDating) return 'namorando';
    if (rel.isRoommate) return 'colega';
    if (rel.isDivorced) return 'divorciado(a)';
    return '';
  }

  @override
  Widget build(BuildContext context) {
    final target = rel.isMarried ? 14 : 10;
    final pct = clamp01(rel.hearts / target);
    final name = entry?.name ?? rel.npcName;
    final status = _status;
    return Container(
      margin: const EdgeInsets.only(bottom: 4),
      padding: const EdgeInsets.fromLTRB(5, 4, 6, 4),
      decoration: BoxDecoration(
        color: _paper2,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: const Color(0xFFD2B77F)),
      ),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            padding: const EdgeInsets.all(2),
            decoration: BoxDecoration(
              color: const Color(0xFFC2185B).withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: entry != null
                ? EntryImage(entry: entry!, size: 30)
                : Center(
                    child: Text(
                      name.isNotEmpty ? name[0].toUpperCase() : '?',
                      style: const TextStyle(
                        fontWeight: FontWeight.w900,
                        color: _ink,
                      ),
                    ),
                  ),
          ),
          const SizedBox(width: 5),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w900,
                          color: _ink,
                        ),
                      ),
                    ),
                    if (status.isNotEmpty)
                      _TinyTag(status, const Color(0xFFC2185B)),
                    const SizedBox(width: 3),
                    Text(
                      '${rel.hearts}♥',
                      style: const TextStyle(
                        fontSize: 10.5,
                        fontWeight: FontWeight.w900,
                        color: Color(0xFFC2185B),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                ClipRRect(
                  borderRadius: BorderRadius.circular(2),
                  child: LinearProgressIndicator(
                    value: pct,
                    minHeight: 4,
                    backgroundColor: const Color(0xFFE3C7BE),
                    valueColor: const AlwaysStoppedAnimation(Color(0xFFC2185B)),
                  ),
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    Text(
                      '${rel.points} pts · ${rel.giftsGivenThisWeek}/2 presentes na semana',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 8.5,
                        color: Color(0xFF6B5238),
                      ),
                    ),
                    if (rel.hasBeenGivenGiftToday) ...[
                      const SizedBox(width: 4),
                      const Icon(
                        Icons.check_circle_rounded,
                        size: 10,
                        color: _green,
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _EquipSlot extends StatelessWidget {
  final String label;
  final ApiItem? item;
  final IconData icon;
  const _EquipSlot({
    required this.label,
    required this.item,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final name = item == null
        ? '—'
        : (item!.displayName.isNotEmpty ? item!.displayName : item!.name);
    return Tooltip(
      message: item == null
          ? '$label vazio'
          : '$label: $name\nID: ${item!.qualifiedItemId}',
      child: Container(
        padding: const EdgeInsets.fromLTRB(4, 4, 4, 5),
        decoration: BoxDecoration(
          color: _paper2,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: const Color(0xFFD2B77F)),
        ),
        child: Column(
          children: [
            Icon(
              item == null ? icon : Icons.checkroom_rounded,
              size: 20,
              color: item == null ? const Color(0xFF9E8A6A) : _green,
            ),
            const SizedBox(height: 2),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 7.5,
                fontWeight: FontWeight.w900,
                color: Color(0xFF6B5238),
              ),
            ),
            Text(
              name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 8.5, color: _ink),
            ),
          ],
        ),
      ),
    );
  }
}

class _AchievementTile extends StatelessWidget {
  final ApiAchievement a;
  const _AchievementTile({required this.a});

  @override
  Widget build(BuildContext context) {
    final unlocked = a.hasPlayerUnlocked;
    final color = unlocked ? _green : const Color(0xFF9E8A6A);
    return Container(
      margin: const EdgeInsets.only(bottom: 4),
      padding: const EdgeInsets.fromLTRB(5, 4, 6, 4),
      decoration: BoxDecoration(
        color: unlocked ? const Color(0xFFE7F0D3) : _paper2,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            unlocked ? Icons.emoji_events_rounded : Icons.lock_outline_rounded,
            size: 16,
            color: color,
          ),
          const SizedBox(width: 5),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  a.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w900,
                    color: unlocked ? _ink : const Color(0xFF7A6750),
                  ),
                ),
                if (a.canPlayerSeeDetails || unlocked)
                  Text(
                    a.description,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 9.5,
                      height: 1.12,
                      color: Color(0xFF6B5238),
                    ),
                  ),
              ],
            ),
          ),
          if (a.reward != null) ...[
            const SizedBox(width: 3),
            Icon(Icons.card_giftcard_rounded, size: 13, color: _gold),
          ],
        ],
      ),
    );
  }
}

class _EmptyText extends StatelessWidget {
  final String text;
  const _EmptyText(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 11.5,
        height: 1.2,
        color: Color(0xFF6B5238),
      ),
    );
  }
}

class _NoSnapshot extends StatelessWidget {
  final GameApi api;
  final VoidCallback onClose;
  const _NoSnapshot({required this.api, required this.onClose});

  @override
  Widget build(BuildContext context) {
    final message = !api.connected
        ? 'A conexão com o servidor caiu. Feche esta tela e conecte de novo em Sobre e ajustes.'
        : (api.error?.trim().isNotEmpty == true
              ? api.error!
              : 'Servidor conectado. Carregue um save no Stardew Valley para a API enviar os dados do jogador.');
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 520),
        child: _GamePanel(
          accent: _gold,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('🌾', style: TextStyle(fontSize: 44)),
              const SizedBox(height: 4),
              const Text(
                'SINAL DO JOGO',
                style: TextStyle(
                  fontFamily: 'PixelifySans',
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: _ink,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                message,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 13, height: 1.3, color: _ink),
              ),
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (api.connected)
                    FilledButton.icon(
                      onPressed: () => api.sync(),
                      icon: const Icon(Icons.refresh_rounded),
                      label: const Text('Tentar de novo'),
                    ),
                  const SizedBox(width: 8),
                  OutlinedButton.icon(
                    onPressed: onClose,
                    icon: const Icon(Icons.close_rounded),
                    label: const Text('Fechar'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
