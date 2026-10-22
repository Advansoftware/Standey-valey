part of 'status_screen.dart';

extension _StatusPanels on _StatusScreenState {
  Widget _vitalsPanel(ApiSnapshot snap) {
    final p = snap.player;
    return _GamePanel(
      dark: true,
      padding: const EdgeInsets.fromLTRB(8, 7, 8, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const _PanelLabel(
            'STATUS DO FAZENDEIRO',
            icon: Icons.favorite_rounded,
          ),
          const SizedBox(height: 6),
          LayoutBuilder(
            builder: (context, c) {
              final w = (c.maxWidth - 6) / 2;
              return Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [
                  SizedBox(
                    width: w,
                    child: _StatTile(
                      icon: 'assets/img/misc_gold.png',
                      label: 'DINHEIRO',
                      value: moneyLabel(p.money),
                      color: _gold,
                    ),
                  ),
                  SizedBox(
                    width: w,
                    child: _StatTile(
                      icon: 'assets/img/misc_energy.png',
                      label: 'ENERGIA',
                      value: '${p.stamina.round()}/${p.maxStamina}',
                      color: const Color(0xFF8BC34A),
                      fraction: p.maxStamina > 0 ? p.stamina / p.maxStamina : 0,
                    ),
                  ),
                  SizedBox(
                    width: w,
                    child: _StatTile(
                      icon: Icons.favorite_rounded,
                      label: 'VIDA',
                      value: '${p.health}/${p.maxHealth}',
                      color: _red,
                      fraction: p.maxHealth > 0 ? p.health / p.maxHealth : 0,
                    ),
                  ),
                  SizedBox(
                    width: w,
                    child: _StatTile(
                      icon: Icons.auto_awesome_rounded,
                      label: 'SORTE',
                      value: luckLabel(p),
                      color: p.dailyLuck >= 0
                          ? const Color(0xFF7E57C2)
                          : const Color(0xFF8D6E63),
                      sub: luckPhrase(p.dailyLuck),
                      tooltip: p.dailyLuckDescription,
                    ),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _mapPanel(BuildContext context, ApiSnapshot snap, LocationInfo loc) {
    return _GamePanel(
      dark: true,
      padding: const EdgeInsets.fromLTRB(7, 7, 7, 7),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const _PanelLabel('ONDE VOCÊ ESTÁ', icon: Icons.place_rounded),
              const Spacer(),
              Text(
                loc.region,
                style: const TextStyle(
                  color: _goldSoft,
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          _MapCanvas(info: loc, onTap: () => _showFullMap(context, loc)),
          const SizedBox(height: 6),
          Row(
            children: [
              Text(loc.emoji, style: const TextStyle(fontSize: 18)),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  loc.displayName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontFamily: 'PixelifySans',
                    color: Colors.white,
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const Icon(Icons.zoom_in_rounded, color: _goldSoft, size: 18),
            ],
          ),
        ],
      ),
    );
  }

  Widget _locationPanel(LocationInfo loc) {
    return _GamePanel(
      accent: _green,
      padding: const EdgeInsets.all(9),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.signpost_rounded, color: _green, size: 17),
              const SizedBox(width: 5),
              const Text(
                'COMO SE ORIENTAR',
                style: TextStyle(
                  fontWeight: FontWeight.w900,
                  fontSize: 11,
                  color: _green,
                ),
              ),
              const Spacer(),
              _TinyTag(loc.region, _green),
            ],
          ),
          const SizedBox(height: 5),
          Text(
            loc.directions,
            style: const TextStyle(
              fontSize: 12,
              height: 1.22,
              color: _ink,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            loc.tip,
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 11.5,
              height: 1.2,
              color: Color(0xFF5B4630),
            ),
          ),
        ],
      ),
    );
  }

  Widget _farmPanel(ApiSnapshot snap) {
    final p = snap.player;
    final w = snap.world;
    return _GamePanel(
      padding: const EdgeInsets.fromLTRB(9, 8, 9, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _PanelLabel('FAZENDA', icon: Icons.home_rounded),
          const SizedBox(height: 4),
          Text(
            w.farmName.isEmpty ? 'Sua fazenda' : w.farmName,
            style: const TextStyle(
              fontWeight: FontWeight.w900,
              fontSize: 14,
              color: _ink,
            ),
          ),
          if (w.currentMusicTrack.trim().isNotEmpty) ...[
            const SizedBox(height: 3),
            Row(
              children: [
                const Icon(Icons.music_note_rounded, size: 14, color: _green),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    'Trilha: ${w.currentMusicTrack}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 11,
                      color: Color(0xFF5B4630),
                    ),
                  ),
                ),
              ],
            ),
          ],
          const SizedBox(height: 3),
          Text(
            '${p.skills.isEmpty ? '' : '${p.skills.length} habilidades · '}${p.relationships.length} amizades · ${snap.inventory.length} itens',
            style: const TextStyle(fontSize: 11, color: Color(0xFF5B4630)),
          ),
        ],
      ),
    );
  }

  Widget _nextStepPanel(
    BuildContext context,
    ApiSnapshot snap,
    LocationInfo loc,
    StatusTip next,
    List<StatusTip> tips,
    bool canAi,
  ) {
    final objectives = parseAiObjectives(_aiText);
    return _GamePanel(
      accent: _gold,
      padding: const EdgeInsets.fromLTRB(10, 8, 10, 9),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const _PanelLabel('PRÓXIMO PASSO', icon: Icons.explore_rounded),
              const Spacer(),
              _TinyTag(
                canAi ? 'CONSELHEIRO IA' : 'PLANO DO GUIA',
                canAi ? _blue : _green,
              ),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(next.emoji, style: const TextStyle(fontSize: 30)),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      next.title,
                      style: const TextStyle(
                        fontFamily: 'PixelifySans',
                        fontSize: 18,
                        height: 1.05,
                        fontWeight: FontWeight.w700,
                        color: _ink,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      next.body,
                      style: const TextStyle(
                        fontSize: 12.5,
                        height: 1.2,
                        color: Color(0xFF4E3926),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 5),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.near_me_rounded, size: 15, color: _green),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  '${loc.displayName} · ${loc.directions}',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 11,
                    height: 1.15,
                    color: Color(0xFF5B4630),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 7),
          Row(
            children: [
              Expanded(
                child: Text(
                  canAi
                      ? 'Quer um plano para este save? O conselheiro só pensa quando você pede.'
                      : 'A IA local é opcional. O plano acima já usa as regras do guia.',
                  style: TextStyle(
                    fontSize: 10.5,
                    height: 1.15,
                    color: _ink.withValues(alpha: 0.66),
                  ),
                ),
              ),
              const SizedBox(width: 6),
              FilledButton.icon(
                style: FilledButton.styleFrom(
                  backgroundColor: _gold,
                  foregroundColor: _ink,
                  disabledBackgroundColor: _gold.withValues(alpha: 0.45),
                  disabledForegroundColor: _ink.withValues(alpha: 0.6),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 11,
                    vertical: 9,
                  ),
                  minimumSize: const Size(0, 34),
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                onPressed: _aiBusy
                    ? null
                    : (canAi ? _askAi : _showAiUnavailable),
                icon: _aiBusy
                    ? const SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: _ink,
                        ),
                      )
                    : const Icon(Icons.auto_awesome_rounded, size: 16),
                label: Text(
                  _aiBusy
                      ? 'LENDO…'
                      : (objectives.isEmpty ? 'AJUDA' : 'OUTRO PLANO'),
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.6,
                  ),
                ),
              ),
            ],
          ),
          if (_aiBusy) ...[
            const SizedBox(height: 7),
            const Row(
              children: [
                SizedBox(
                  width: 12,
                  height: 12,
                  child: CircularProgressIndicator(
                    strokeWidth: 1.8,
                    color: _blue,
                  ),
                ),
                SizedBox(width: 6),
                Expanded(
                  child: Text(
                    'Lendo o seu save e escolhendo o próximo passo…',
                    style: TextStyle(fontSize: 11, color: Color(0xFF5B4630)),
                  ),
                ),
              ],
            ),
          ],
          if (_aiError != null) ...[
            const SizedBox(height: 6),
            Text(
              _aiError!,
              style: const TextStyle(fontSize: 11.5, height: 1.2, color: _red),
            ),
          ],
          if (objectives.isNotEmpty) ...[
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 7),
              child: Divider(height: 1, color: Color(0x33A1783F)),
            ),
            Row(
              children: [
                const Icon(Icons.auto_awesome_rounded, size: 15, color: _blue),
                const SizedBox(width: 4),
                const Text(
                  'PLANO DO CONSELHEIRO',
                  style: TextStyle(
                    fontSize: 10,
                    letterSpacing: 0.8,
                    fontWeight: FontWeight.w900,
                    color: _blue,
                  ),
                ),
                const Spacer(),
                _TinyTag(
                  '${objectives.length} OBJETIVO${objectives.length > 1 ? 'S' : ''}',
                  _blue,
                ),
              ],
            ),
            const SizedBox(height: 5),
            for (var i = 0; i < objectives.length; i++)
              _AiObjectiveTile(objective: objectives[i], index: i),
          ] else if (canAi && !_aiBusy && _aiError == null) ...[
            const SizedBox(height: 5),
            Text(
              'Toque em AJUDA para receber até 3 objetivos com lugar e motivo.',
              style: TextStyle(
                fontSize: 10.5,
                height: 1.15,
                color: _ink.withValues(alpha: 0.58),
              ),
            ),
          ],
          if (tips.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              'Outras prioridades: ${tips.take(2).map((t) => t.title).join(' · ')}',
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 10.5, color: Color(0xFF6B5238)),
            ),
          ],
        ],
      ),
    );
  }

  Widget _questsPanel(ApiSnapshot snap) {
    final quests = snap.player.quests
        .where((q) => q.title.trim().isNotEmpty)
        .toList();
    return _GamePanel(
      accent: _blue,
      padding: const EdgeInsets.fromLTRB(9, 8, 9, 9),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _PanelHeader(
            title: 'MISSÕES',
            icon: Icons.menu_book_rounded,
            color: _blue,
            count: '${quests.length}',
          ),
          const SizedBox(height: 5),
          if (quests.isEmpty)
            const _EmptyText(
              'Nenhuma missão ativa. Explore, converse e cuide da fazenda.',
            )
          else
            for (final q in quests) _QuestTile(quest: q),
        ],
      ),
    );
  }

  Widget _todayPanel(AppScope scope, ApiSnapshot snap) {
    final w = snap.world;
    final birthdays = w.birthdays;
    final upcoming = scope.repo
        .upcoming(scope.store.season, scope.store.day, 7)
        .where((e) => e.key > 0)
        .take(5)
        .toList();
    final weather = weatherInfo(w.weather);
    return _GamePanel(
      accent: _green,
      padding: const EdgeInsets.fromLTRB(9, 8, 9, 9),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _PanelHeader(
            title: 'HOJE E AMANHÃ',
            icon: Icons.wb_sunny_rounded,
            color: _green,
          ),
          const SizedBox(height: 5),
          Row(
            children: [
              Text(weather.emoji, style: const TextStyle(fontSize: 21)),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  '${weather.label} · ${seasonEmojiFor(w.season)} ${seasonNameFor(w.season)} ${w.day}',
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 12.5,
                    color: _ink,
                  ),
                ),
              ),
              if (w.festival != null) _TinyTag('FESTIVAL', _red),
            ],
          ),
          if (birthdays.isNotEmpty) ...[
            const SizedBox(height: 5),
            Wrap(
              spacing: 6,
              runSpacing: 4,
              children: [
                for (final npc in birthdays)
                  _BirthdayChip(
                    entry: villagerEntry(scope.repo, npc.name),
                    name: npc.name,
                  ),
              ],
            ),
          ],
          if (upcoming.isNotEmpty) ...[
            const SizedBox(height: 5),
            const Text(
              'PRÓXIMOS DIAS',
              style: TextStyle(
                fontSize: 10,
                letterSpacing: 0.7,
                fontWeight: FontWeight.w900,
                color: _green,
              ),
            ),
            const SizedBox(height: 2),
            for (final e in upcoming)
              Padding(
                padding: const EdgeInsets.only(top: 1),
                child: Text(
                  '${e.value.emoji} ${e.value.label} — ${e.key == 1 ? 'amanhã' : 'em ${e.key} dias'}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 11.5,
                    color: Color(0xFF4E3926),
                  ),
                ),
              ),
          ],
        ],
      ),
    );
  }

  Widget _inventoryPanel(ApiSnapshot snap) {
    return _GamePanel(
      padding: const EdgeInsets.fromLTRB(9, 8, 9, 9),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _PanelHeader(
            title: 'MOCHILA',
            icon: Icons.backpack_rounded,
            color: const Color(0xFF8D6E63),
            count: '${snap.inventory.length} itens',
          ),
          const SizedBox(height: 6),
          if (snap.inventory.isEmpty)
            const _EmptyText(
              'A mochila está vazia. Abra o jogo e sincronize de novo.',
            )
          else
            Wrap(
              spacing: 5,
              runSpacing: 5,
              children: [
                for (final item in snap.inventory)
                  _ItemTile(item: item, entry: _entryFor(item)),
              ],
            ),
        ],
      ),
    );
  }

  Widget _skillsPanel(ApiSnapshot snap) {
    final skills = [...snap.player.skills]
      ..sort((a, b) => b.level.compareTo(a.level));
    return _GamePanel(
      padding: const EdgeInsets.fromLTRB(9, 8, 9, 9),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _PanelHeader(
            title: 'HABILIDADES',
            icon: Icons.workspace_premium_rounded,
            color: const Color(0xFF6D4C41),
            count: '${skills.length}',
          ),
          const SizedBox(height: 6),
          if (skills.isEmpty)
            const _EmptyText('A API não devolveu habilidades neste save.')
          else
            LayoutBuilder(
              builder: (context, c) {
                final width = (c.maxWidth - 6) / 2;
                return Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    for (final s in skills)
                      SizedBox(
                        width: c.maxWidth < 330 ? c.maxWidth : width,
                        child: _SkillTile(skill: s),
                      ),
                  ],
                );
              },
            ),
        ],
      ),
    );
  }

  Widget _relationshipsPanel(ApiSnapshot snap) {
    final rels = [...snap.player.relationships]
      ..sort((a, b) {
        final am = a.isMarried ? 1 : 0;
        final bm = b.isMarried ? 1 : 0;
        if (am != bm) return bm.compareTo(am);
        return b.hearts.compareTo(a.hearts);
      });
    return _GamePanel(
      padding: const EdgeInsets.fromLTRB(9, 8, 9, 9),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _PanelHeader(
            title: 'AMIZADES',
            icon: Icons.people_alt_rounded,
            color: const Color(0xFFC2185B),
            count: '${rels.length}',
          ),
          const SizedBox(height: 5),
          if (rels.isEmpty)
            const _EmptyText('A API não devolveu amizades neste save.')
          else
            for (final r in rels)
              _RelationshipTile(
                rel: r,
                entry: villagerEntry(AppScope.of(context).repo, r.npcName),
              ),
        ],
      ),
    );
  }

  Widget _equipmentPanel(ApiSnapshot snap) {
    final c = snap.player.clothing;
    final slots = <(String, String, ApiItem?, IconData)>[
      ('CHAPÉU', 'hat', c.hat, Icons.checkroom_rounded),
      ('CAMISA', 'shirt', c.shirt, Icons.dry_cleaning_rounded),
      ('CALÇA', 'pants', c.pants, Icons.straighten_rounded),
      ('BOTAS', 'boots', c.boots, Icons.hiking_rounded),
      ('ANEL D.', 'rightRing', c.rightRing, Icons.radio_button_checked_rounded),
      ('ANEL E.', 'leftRing', c.leftRing, Icons.radio_button_checked_rounded),
    ];
    return _GamePanel(
      padding: const EdgeInsets.fromLTRB(9, 8, 9, 9),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const _PanelHeader(
            title: 'EQUIPAMENTO',
            icon: Icons.checkroom_rounded,
            color: Color(0xFF6D4C41),
          ),
          const SizedBox(height: 6),
          LayoutBuilder(
            builder: (context, c) {
              final w = (c.maxWidth - 10) / 3;
              return Wrap(
                spacing: 5,
                runSpacing: 5,
                children: [
                  for (final s in slots)
                    SizedBox(
                      width: w,
                      child: _EquipSlot(label: s.$1, item: s.$3, icon: s.$4),
                    ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _achievementsPanel(ApiSnapshot snap) {
    final all = [...snap.player.achievements]
      ..sort((a, b) {
        if (a.hasPlayerUnlocked != b.hasPlayerUnlocked) {
          return a.hasPlayerUnlocked ? -1 : 1;
        }
        return a.id.compareTo(b.id);
      });
    final unlocked = all.where((a) => a.hasPlayerUnlocked).length;
    return _GamePanel(
      padding: const EdgeInsets.fromLTRB(9, 8, 9, 9),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _PanelHeader(
            title: 'CONQUISTAS',
            icon: Icons.emoji_events_rounded,
            color: _gold,
            count: '$unlocked/${all.length}',
          ),
          const SizedBox(height: 5),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: all.isEmpty ? 0 : unlocked / all.length,
              minHeight: 6,
              backgroundColor: const Color(0xFFE3D0A2),
              valueColor: const AlwaysStoppedAnimation(_gold),
            ),
          ),
          const SizedBox(height: 5),
          if (all.isEmpty)
            const _EmptyText('A API não devolveu conquistas neste save.')
          else
            for (final a in all) _AchievementTile(a: a),
        ],
      ),
    );
  }

  Widget _footer(GameApi api) {
    final last = api.lastSync;
    final time = last == null
        ? 'nunca'
        : '${last.hour.toString().padLeft(2, '0')}:${last.minute.toString().padLeft(2, '0')}';
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 0, 4, 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.sync_rounded, size: 13, color: Colors.white70),
          const SizedBox(width: 4),
          Flexible(
            child: Text(
              'Atualizado $time · ${api.lastAutoMarked} fichas automáticas · ${api.baseUrl}',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: Colors.white70, fontSize: 10),
            ),
          ),
        ],
      ),
    );
  }

  void _showFullMap(BuildContext context, LocationInfo loc) {
    showGeneralDialog<void>(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Fechar mapa',
      barrierColor: Colors.black.withValues(alpha: 0.86),
      transitionDuration: const Duration(milliseconds: 250),
      pageBuilder: (context, animation, secondaryAnimation) {
        return Scaffold(
          backgroundColor: Colors.transparent,
          body: SafeArea(
            child: Stack(
              children: [
                Positioned.fill(
                  child: InteractiveViewer(
                    minScale: 1,
                    maxScale: 4,
                    child: Center(
                      child: AspectRatio(
                        aspectRatio: 400 / 244,
                        child: Stack(
                          fit: StackFit.expand,
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(10),
                              child: Image.asset(
                                'assets/img/map_valley.png',
                                fit: BoxFit.fill,
                                filterQuality: FilterQuality.none,
                              ),
                            ),
                            for (var i = 0; i < mapPlaces.length; i++)
                              if (mapPlaces[i].x != null &&
                                  mapPlaces[i].y != null)
                                Positioned(
                                  left:
                                      mapPlaces[i].x! *
                                          MediaQuery.of(context).size.width *
                                          0.9 -
                                      10,
                                  top:
                                      mapPlaces[i].y! *
                                          MediaQuery.of(context).size.width *
                                          0.9 *
                                          244 /
                                          400 -
                                      10,
                                  child: Container(
                                    width: 20,
                                    height: 20,
                                    alignment: Alignment.center,
                                    decoration: BoxDecoration(
                                      color: mapRegionColor(
                                        mapPlaces[i].region,
                                      ),
                                      shape: BoxShape.circle,
                                    ),
                                    child: Text(
                                      '${i + 1}',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 9,
                                        fontWeight: FontWeight.w900,
                                      ),
                                    ),
                                  ),
                                ),
                            if (loc.hasPin)
                              Positioned(
                                left:
                                    loc.x! *
                                        MediaQuery.of(context).size.width *
                                        0.9 -
                                    15,
                                top:
                                    loc.y! *
                                        MediaQuery.of(context).size.width *
                                        0.9 *
                                        244 /
                                        400 -
                                    30,
                                child: _YouPin(label: loc.displayName),
                              ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                Positioned(
                  top: 8,
                  right: 8,
                  child: _CloseButton(onTap: () => Navigator.of(context).pop()),
                ),
                Positioned(
                  left: 12,
                  bottom: 12,
                  right: 12,
                  child: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: _paper.withValues(alpha: 0.94),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: _gold, width: 2),
                    ),
                    child: Text(
                      '${loc.emoji} Você está em ${loc.displayName}. ${loc.directions}',
                      style: const TextStyle(
                        color: _ink,
                        fontWeight: FontWeight.w800,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
