part of 'status_screen.dart';

// ---------------------------------------------------------------------------
// Páginas do menu do jogo (abas): inventário, habilidades, social, diário,
// conquistas, mapa e conselheiro.
// ---------------------------------------------------------------------------

/// Ordem das habilidades na aba do jogo.
const _skillOrder = ['farming', 'mining', 'foraging', 'fishing', 'combat'];

int _skillRank(ApiSkill s) {
  final asset = (skillAsset(s) ?? '').replaceAll('skills_', '').replaceAll('.png', '');
  final i = _skillOrder.indexOf(asset);
  return i < 0 ? 99 : i;
}

class _InfoLine extends StatelessWidget {
  final String label;
  final String value;
  const _InfoLine(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Text.rich(
        TextSpan(children: [
          TextSpan(text: '$label: ', style: sdvText(13, color: SdvColors.inkSoft)),
          TextSpan(text: value, style: sdvText(14)),
        ]),
      ),
    );
  }
}

class _Row extends StatelessWidget {
  final Widget child;
  final VoidCallback? onTap;
  const _Row({required this.child, this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 6),
        child: SdvFrame(
          style: SdvFrameStyle.inset,
          px: 2,
          fill: const Color(0xFFF8D9A0),
          padding: const EdgeInsets.fromLTRB(8, 7, 8, 7),
          child: child,
        ),
      ),
    );
  }
}

extension _StatusMenu on _StatusScreenState {
  Widget _page(AppScope scope, ApiSnapshot snap) {
    return switch (_tab) {
      _Tab.inventory => _inventoryPage(snap),
      _Tab.skills => _skillsPage(snap),
      _Tab.social => _socialPage(scope, snap),
      _Tab.quests => _questsPage(snap),
      _Tab.achievements => _achievementsPage(snap),
      _Tab.map => _mapPage(snap),
      _Tab.advisor => _advisorPage(scope, snap),
    };
  }

  // ---------------- Inventário ----------------
  Widget _inventoryPage(ApiSnapshot snap) {
    final p = snap.player;
    final c = p.clothing;
    return LayoutBuilder(builder: (context, box) {
      final perRow = box.maxWidth / 12 >= 22 ? 12 : 6;
      final slot = (box.maxWidth / perRow - 2).clamp(20.0, 52.0);
      final total = math.max(36, snap.inventory.length);
      Widget equip(String label, ApiItem? item) => Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SdvSlot(
                size: 44,
                onTap: item == null ? null : () => _openItem(item),
                child: item == null
                    ? Text(label, style: sdvText(9, color: SdvColors.inkSoft))
                    : _itemIcon(item, 28),
              ),
            ],
          );
      return SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Wrap(
              spacing: 2,
              runSpacing: 2,
              children: [
                for (var i = 0; i < total; i++)
                  SdvSlot(
                    size: slot,
                    count: i < snap.inventory.length ? snap.inventory[i].stackSize : null,
                    quality: i < snap.inventory.length ? snap.inventory[i].quality : 0,
                    onTap: i < snap.inventory.length ? () => _openItem(snap.inventory[i]) : null,
                    child: i < snap.inventory.length ? _itemIcon(snap.inventory[i], slot * 0.62) : null,
                  ),
              ],
            ),
            Container(height: 2, margin: const EdgeInsets.symmetric(vertical: 10), color: SdvColors.woodDark),
            Wrap(
              spacing: 14,
              runSpacing: 10,
              crossAxisAlignment: WrapCrossAlignment.start,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Column(mainAxisSize: MainAxisSize.min, children: [
                      equip('anel', c.leftRing),
                      const SizedBox(height: 3),
                      equip('anel', c.rightRing),
                      const SizedBox(height: 3),
                      equip('botas', c.boots),
                    ]),
                    const SizedBox(width: 4),
                    Column(mainAxisSize: MainAxisSize.min, children: [
                      equip('chapéu', c.hat),
                      const SizedBox(height: 3),
                      equip('camisa', c.shirt),
                      const SizedBox(height: 3),
                      equip('calça', c.pants),
                    ]),
                  ],
                ),
                ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 340),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(p.displayName.isEmpty ? p.name : p.displayName, style: sdvText(20)),
                      const SizedBox(height: 4),
                      _InfoLine('Fazenda', snap.world.farmName),
                      _InfoLine('Dinheiro atual', moneyLabel(p.money)),
                      _InfoLine('Sorte do dia', '${luckLabel(p)} · ${luckPhrase(p.dailyLuck)}'),
                      _InfoLine('Local', locationInfo(p.location).displayName),
                      _InfoLine('Mochila', '${snap.inventory.length} itens'),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      );
    });
  }

  // ---------------- Habilidades ----------------
  Widget _skillsPage(ApiSnapshot snap) {
    final skills = [...snap.player.skills]..sort((a, b) => _skillRank(a).compareTo(_skillRank(b)));
    if (skills.isEmpty) return const _EmptyText('A API não devolveu habilidades neste save.');
    return ListView(
      children: [
        for (final s in skills)
          _Row(
            onTap: () => showSkillDetailDialog(context, s),
            child: LayoutBuilder(builder: (context, box) {
              final narrow = box.maxWidth < 380;
              final asset = skillAsset(s);
              final head = Row(children: [
                SizedBox(
                  width: 28,
                  height: 28,
                  child: asset == null
                      ? Center(child: Text(skillEmoji(s)))
                      : Image.asset('assets/img/$asset', filterQuality: FilterQuality.none),
                ),
                const SizedBox(width: 8),
                SizedBox(width: 104, child: Text(skillNamePt(s), style: sdvText(16))),
              ]);
              final boxes = Row(mainAxisSize: MainAxisSize.min, children: [
                SdvLevelBoxes(level: s.level, size: narrow ? 13 : 15),
                const SizedBox(width: 8),
                Text('${s.level}', style: sdvText(18, color: SdvColors.woodDark)),
              ]);
              final profs = s.professions.map((p) => professionNamePt(p.name)).where((p) => p.isNotEmpty);
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (narrow) ...[head, const SizedBox(height: 6), boxes] else Row(children: [head, boxes]),
                  if (profs.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 5, left: 36),
                      child: Text('Profissões: ${profs.join(' · ')}',
                          style: sdvText(12, color: SdvColors.inkSoft, weight: FontWeight.w500)),
                    ),
                ],
              );
            }),
          ),
        _Row(
          child: Row(children: [
            const Text('🍀', style: TextStyle(fontSize: 20)),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Sorte do dia ${luckLabel(snap.player)}: ${snap.player.dailyLuckDescription.isNotEmpty ? snap.player.dailyLuckDescription : luckPhrase(snap.player.dailyLuck)}',
                style: sdvText(13, weight: FontWeight.w500),
              ),
            ),
          ]),
        ),
      ],
    );
  }

  // ---------------- Social ----------------
  Widget _socialPage(AppScope scope, ApiSnapshot snap) {
    final rels = [...snap.player.relationships]
      ..sort((a, b) {
        if (a.isMarried != b.isMarried) return a.isMarried ? -1 : 1;
        return b.points.compareTo(a.points);
      });
    if (rels.isEmpty) return const _EmptyText('A API não devolveu amizades neste save.');
    return ListView(
      children: [
        for (final r in rels) _socialRow(scope, r),
      ],
    );
  }

  Widget _socialRow(AppScope scope, ApiRelationship r) {
    final entry = villagerEntry(scope.repo, r.npcName);
    final status = r.isMarried
        ? 'Cônjuge'
        : r.isEngaged
            ? 'Noivado'
            : r.isDating
                ? 'Namorando'
                : r.isRoommate
                    ? 'Colega de quarto'
                    : (entry?.fields.any((f) => f.length > 1 && f[0] == 'Casável' && f[1].toLowerCase().startsWith('sim')) ?? false)
                        ? 'Solteiro(a)'
                        : '';
    return _Row(
      onTap: () => showVillagerDetailDialog(context, r, entry),
      child: LayoutBuilder(builder: (context, box) {
        final narrow = box.maxWidth < 420;
        final portrait = SdvSlot(size: 50, child: entry != null ? EntryImage(entry: entry, size: 40) : Text(r.npcName[0], style: sdvText(20)));
        final name = Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(entry?.name ?? r.npcName, style: sdvText(16)),
            if (status.isNotEmpty) Text(status, style: sdvText(11, color: SdvColors.inkSoft, weight: FontWeight.w500)),
          ],
        );
        final hearts = SdvHearts(hearts: r.hearts, max: r.isMarried ? 14 : 10, size: narrow ? 14 : 16);
        final gifts = Row(mainAxisSize: MainAxisSize.min, children: [
          for (var i = 0; i < 2; i++)
            Padding(
              padding: const EdgeInsets.only(right: 3),
              child: Opacity(
                opacity: i < r.giftsGivenThisWeek ? 1 : 0.3,
                child: const Text('🎁', style: TextStyle(fontSize: 14)),
              ),
            ),
          if (r.hasBeenGivenGiftToday) Text('hoje ✓', style: sdvText(11, color: const Color(0xFF3F7A2A))),
        ]);
        if (narrow) {
          return Row(children: [
            portrait,
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(children: [Expanded(child: name), gifts]),
                  const SizedBox(height: 4),
                  hearts,
                ],
              ),
            ),
          ]);
        }
        return Row(children: [
          portrait,
          const SizedBox(width: 8),
          SizedBox(width: 120, child: name),
          Expanded(child: hearts),
          gifts,
        ]);
      }),
    );
  }

  // ---------------- Diário de missões ----------------
  Widget _questsPage(ApiSnapshot snap) {
    final quests = snap.player.quests.where((q) => q.title.trim().isNotEmpty).toList();
    if (quests.isEmpty) return const _EmptyText('Nenhuma missão ativa no diário.');
    final sel = _quest.clamp(0, quests.length - 1);
    final q = quests[sel];
    final list = ListView(
      children: [
        for (var i = 0; i < quests.length; i++)
          _Row(
            onTap: () => _selectQuest(i),
            child: Row(children: [
              Text(i == sel ? '📜' : '📃', style: const TextStyle(fontSize: 18)),
              const SizedBox(width: 8),
              Expanded(child: Text(quests[i].title, style: sdvText(15, color: i == sel ? SdvColors.woodDark : SdvColors.ink))),
              if (quests[i].daysLeft != null) Text('⏳ ${quests[i].daysLeft}d', style: sdvText(12, color: const Color(0xFFB0261C))),
            ]),
          ),
      ],
    );
    final detail = SdvFrame(
      style: SdvFrameStyle.inset,
      px: 2,
      fill: const Color(0xFFFFE3AE),
      padding: const EdgeInsets.all(12),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(q.title, style: sdvText(18)),
            const SizedBox(height: 6),
            if (q.description.isNotEmpty) Text(q.description, style: sdvText(13, weight: FontWeight.w500, height: 1.25)),
            const SizedBox(height: 10),
            if (q.currentObjective.isNotEmpty) Text('➤ ${q.currentObjective}', style: sdvText(14, color: SdvColors.woodDark)),
            if (q.daysLeft != null) ...[
              const SizedBox(height: 6),
              Text('Prazo: ${q.daysLeft} dia(s)', style: sdvText(13, color: const Color(0xFFB0261C))),
            ],
            if (q.hasReward) ...[
              const SizedBox(height: 10),
              Row(children: [
                Image.asset('assets/img/misc_gold.png', width: 18, height: 18, filterQuality: FilterQuality.none,
                    errorBuilder: (_, _, _) => const Text('💰')),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    q.hasMoneyReward && (q.moneyReward ?? 0) > 0
                        ? 'Recompensa: ${moneyLabel(q.moneyReward!)}'
                        : 'Recompensa: ${q.rewardDescription ?? 'sim'}',
                    style: sdvText(13),
                  ),
                ),
              ]),
            ],
          ],
        ),
      ),
    );
    return LayoutBuilder(builder: (context, box) {
      if (box.maxWidth > 340) {
        return Row(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          SizedBox(width: box.maxWidth * 0.42, child: list),
          const SizedBox(width: 10),
          Expanded(child: detail),
        ]);
      }
      return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        SizedBox(height: math.min(quests.length * 58.0, box.maxHeight * 0.4), child: list),
        Expanded(child: detail),
      ]);
    });
  }

  // ---------------- Conquistas ----------------
  Widget _achievementsPage(ApiSnapshot snap) {
    final all = snap.player.achievements.where((a) => a.canPlayerSeeDetails || a.hasPlayerUnlocked).toList()
      ..sort((a, b) => (b.hasPlayerUnlocked ? 1 : 0).compareTo(a.hasPlayerUnlocked ? 1 : 0));
    if (all.isEmpty) return const _EmptyText('A API não devolveu conquistas neste save.');
    final done = snap.player.achievements.where((a) => a.hasPlayerUnlocked).length;
    return ListView(
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Text('$done de ${snap.player.achievements.length} conquistas', style: sdvText(14, color: SdvColors.inkSoft)),
        ),
        for (final a in all)
          _Row(
            child: Row(children: [
              Opacity(opacity: a.hasPlayerUnlocked ? 1 : 0.35, child: const Text('🏆', style: TextStyle(fontSize: 22))),
              const SizedBox(width: 10),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(a.name, style: sdvText(15, color: a.hasPlayerUnlocked ? SdvColors.ink : SdvColors.inkSoft)),
                  if (a.description.isNotEmpty) Text(a.description, style: sdvText(12, weight: FontWeight.w500, color: SdvColors.inkSoft)),
                ]),
              ),
              if (a.hasPlayerUnlocked) Text('✓', style: sdvText(18, color: const Color(0xFF3F7A2A))),
            ]),
          ),
      ],
    );
  }

  // ---------------- Mapa ----------------
  Widget _mapPage(ApiSnapshot snap) {
    final loc = locationInfo(snap.player.location);
    return ListView(
      children: [
        GestureDetector(
          onTap: () => _showFullMap(context),
          child: SdvFrame(style: SdvFrameStyle.wood, px: 2, padding: const EdgeInsets.all(6), child: _ValleyMap(loc: loc, numbered: true)),
        ),
        const SizedBox(height: 10),
        Row(children: [
          Text(loc.emoji, style: const TextStyle(fontSize: 22)),
          const SizedBox(width: 8),
          Expanded(child: Text(loc.displayName, style: sdvText(20))),
          Text(loc.region, style: sdvText(13, color: SdvColors.inkSoft)),
        ]),
        const SizedBox(height: 6),
        _InfoLine('Caminhos', loc.directions),
        Text(loc.tip, style: sdvText(13, weight: FontWeight.w500, height: 1.25)),
      ],
    );
  }

  // ---------------- Conselheiro ----------------
  Widget _advisorPage(AppScope scope, ApiSnapshot snap) {
    final w = snap.world;
    final next = recommendedNextStep(snap, scope.repo);
    final tips = buildStatusTips(snap, scope.repo);
    final canAi = scope.store.aiModelInstalled && scope.ai.engineReady;
    final objectives = parseAiObjectives(_aiText);
    final weather = weatherInfo(w.weather);
    final upcoming = scope.repo.upcoming(w.season, w.day, 7).where((e) => e.key > 0).take(4).toList();
    Widget section(String t) => Padding(
          padding: const EdgeInsets.only(top: 8, bottom: 5),
          child: Text(t, style: sdvText(13, color: SdvColors.woodDark)),
        );
    return ListView(
      children: [
        _Row(
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            Row(children: [
              const Text('❗', style: TextStyle(fontSize: 18)),
              const SizedBox(width: 6),
              Expanded(child: Text(next.title, style: sdvText(16))),
            ]),
            const SizedBox(height: 4),
            Text(next.body, style: sdvText(13, weight: FontWeight.w500, height: 1.25)),
          ]),
        ),
        Row(children: [
          Expanded(
            child: Text(
              objectives.isNotEmpty
                  ? 'Plano do conselheiro para agora:'
                  : canAi
                      ? 'Peça um plano feito para o seu save:'
                      : 'Instale a IA no Assistente para pedir um plano.',
              style: sdvText(12.5, color: SdvColors.inkSoft, weight: FontWeight.w500),
            ),
          ),
          SdvButton(
            label: _aiBusy ? 'PENSANDO…' : (objectives.isEmpty ? 'AJUDA' : 'DE NOVO'),
            icon: const Text('✨', style: TextStyle(fontSize: 14)),
            onTap: _aiBusy ? null : (canAi ? _askAi : _showAiUnavailable),
          ),
        ]),
        if (_aiError != null)
          Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Text(_aiError!, style: sdvText(12.5, color: const Color(0xFFB0261C))),
          ),
        const SizedBox(height: 6),
        for (final o in objectives)
          _Row(
            child: Row(children: [
              const Text('➤', style: TextStyle(fontSize: 16, color: SdvColors.woodDark)),
              const SizedBox(width: 8),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(o.action, style: sdvText(15)),
                  if (o.place != null && o.place!.isNotEmpty) Text('📍 ${o.place}', style: sdvText(12, color: SdvColors.inkSoft)),
                  if (o.detail != null && o.detail!.isNotEmpty)
                    Text(o.detail!, style: sdvText(12, weight: FontWeight.w500, color: SdvColors.inkSoft)),
                ]),
              ),
            ]),
          ),
        section('HOJE'),
        _Row(
          child: Row(children: [
            Text(weather.emoji, style: const TextStyle(fontSize: 20)),
            const SizedBox(width: 8),
            Expanded(child: Text(weather.tip, style: sdvText(13, weight: FontWeight.w500, height: 1.2))),
          ]),
        ),
        if (w.festival != null && w.festival!.isNotEmpty)
          _Row(child: Text('🎪 Festival hoje: ${w.festival}', style: sdvText(14))),
        for (final b in w.birthdays)
          _Row(
            child: Row(children: [
              SdvSlot(size: 40, child: villagerEntry(scope.repo, b.name) != null
                  ? EntryImage(entry: villagerEntry(scope.repo, b.name)!, size: 30)
                  : const Text('🎂')),
              const SizedBox(width: 8),
              Expanded(child: Text('Aniversário de ${villagerEntry(scope.repo, b.name)?.name ?? b.name} hoje: presente amado vale 8x!', style: sdvText(13))),
            ]),
          ),
        section('DICAS DO GUIA'),
        for (final t in tips)
          _Row(
            child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(t.emoji, style: const TextStyle(fontSize: 16)),
              const SizedBox(width: 8),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(t.title, style: sdvText(14)),
                  Text(t.body, style: sdvText(12, weight: FontWeight.w500, color: SdvColors.inkSoft, height: 1.2)),
                ]),
              ),
            ]),
          ),
        if (upcoming.isNotEmpty) ...[
          section('PRÓXIMOS DIAS'),
          for (final e in upcoming)
            Padding(
              padding: const EdgeInsets.only(bottom: 3),
              child: Text('${e.value.emoji} ${e.value.label} — ${e.key == 1 ? 'amanhã' : 'em ${e.key} dias'}',
                  style: sdvText(13, weight: FontWeight.w500)),
            ),
        ],
      ],
    );
  }
}
