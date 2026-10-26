part of 'status_screen.dart';

// ---------------------------------------------------------------------------
// HUD do jogo: relógio, ouro, barras de energia/vida, barra de ferramentas,
// mensagens ao vivo e as abas do menu. Layout em paisagem e em retrato.
// ---------------------------------------------------------------------------

enum _Tab { advisor, inventory, skills, social, quests, achievements, map }

const _tabInfo = {
  _Tab.advisor: ('✨', 'Conselheiro'),
  _Tab.inventory: ('🎒', 'Inventário'),
  _Tab.skills: ('⭐', 'Habilidades'),
  _Tab.social: ('💛', 'Social'),
  _Tab.quests: ('📜', 'Diário'),
  _Tab.achievements: ('🏆', 'Conquistas'),
  _Tab.map: ('🗺️', 'Mapa'),
};

/// Sprite de ferramenta do jogo a partir do nome em inglês (ex.: "Copper Hoe").
String? _toolAsset(String name) {
  final n = name.toLowerCase();
  const tiers = ['copper', 'steel', 'gold', 'iridium'];
  final tier = tiers.firstWhere((t) => n.contains(t), orElse: () => '');
  String tiered(String kind, String file) => tier.isEmpty
      ? 'tools_${kind}_$file.png'
      : 'tools_${kind}_${tier}_$file.png';
  if (n.contains('scythe')) {
    if (n.contains('golden')) return 'tools_golden_scythe.png';
    if (n.contains('iridium')) return 'tools_iridium_scythe.png';
    return 'tools_scythe.png';
  }
  if (n.contains('pickaxe')) return tiered('pickaxe', 'pickaxe');
  if (n.contains('axe')) return tiered('axe', 'axe');
  if (n.contains('hoe')) return tiered('hoe', 'hoe');
  if (n.contains('watering can')) return tiered('watering_can', 'watering_can');
  if (n.contains('trash can') && tier.isNotEmpty) return tiered('trash_can', 'trash_can');
  if (n.contains('pan')) return 'tools_pan_${tier.isEmpty ? 'copper' : tier}_pan.png';
  if (n.contains('advanced iridium rod')) return 'tools_fishing_rod_advanced_iridium_rod.png';
  if (n.contains('iridium rod')) return 'tools_fishing_rod_iridium_rod.png';
  if (n.contains('fiberglass')) return 'tools_fishing_rod_fiberglass_rod.png';
  if (n.contains('bamboo')) return 'tools_fishing_rod_bamboo_pole.png';
  if (n.contains('training rod')) return 'tools_fishing_rod_training_rod.png';
  if (n.contains('milk pail')) return 'tools_milk_pail.png';
  if (n.contains('shears')) return 'tools_shears.png';
  return null;
}

/// Recursos básicos que não estão na enciclopédia.
const _basicAssets = {'stone': 'minerals_nodes_stone_1.png', 'clay': 'minerals_nodes_clay_node.png'};
const _basicEmoji = {'wood': '🪵', 'hardwood': '🪵', 'fiber': '🌿', 'sap': '💧', 'stone': '🪨', 'clay': '🟫'};

String _typeEmoji(ApiItem item) {
  final basic = _basicEmoji[item.name.toLowerCase()];
  if (basic != null) return basic;
  final q = item.qualifiedItemId;
  if (q.startsWith('(W)')) return '⚔️';
  if (q.startsWith('(H)')) return '🎩';
  if (q.startsWith('(B)')) return '👢';
  if (q.startsWith('(S)')) return '👕';
  if (q.startsWith('(P)')) return '👖';
  if (q.startsWith('(F)')) return '🪑';
  if (q.startsWith('(BC)')) return '⚙️';
  if (q.contains('Ring') || q.startsWith('(R)')) return '💍';
  if (q.startsWith('(T)')) return '🛠️';
  return '📦';
}

String _seasonAsset(int season) =>
    'assets/img/seasons_${const ['spring', 'summer', 'fall', 'winter'][season.clamp(0, 3)]}.png';

String _shortWeekday(ApiWorld w) {
  final pt = weekdayPt(w.dayOfWeek);
  if (pt.isEmpty) return w.shortDayOfWeek;
  return '${pt[0].toUpperCase()}${pt.substring(1, pt.length < 3 ? pt.length : 3)}.';
}

/// Relógio do canto superior direito: dia, clima, estação, hora e ouro.
class _ClockBox extends StatelessWidget {
  final ApiWorld world;
  final int? time;
  final int money;
  final double scale;
  const _ClockBox({required this.world, required this.time, required this.money, this.scale = 1});

  @override
  Widget build(BuildContext context) {
    final weather = weatherInfo(world.weather);
    final s = scale;
    return SdvFrame(
      style: SdvFrameStyle.wood,
      px: 2.5 * s,
      padding: EdgeInsets.fromLTRB(9 * s, 8 * s, 9 * s, 9 * s),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              SizedBox(
                width: 46 * s,
                height: 30 * s,
                child: CustomPaint(painter: _DialPainter(time ?? 600)),
              ),
              SizedBox(width: 6 * s),
              Expanded(
                child: SdvFrame(
                  style: SdvFrameStyle.inset,
                  px: 2 * s,
                  padding: EdgeInsets.symmetric(horizontal: 6 * s, vertical: 3 * s),
                  child: Column(
                    children: [
                      Text('${_shortWeekday(world)} ${world.day}',
                          maxLines: 1, style: sdvText(15 * s, height: 1.1)),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(weather.emoji, style: TextStyle(fontSize: 13 * s)),
                          SizedBox(width: 5 * s),
                          Image.asset(_seasonAsset(world.season),
                              width: 18 * s, height: 18 * s, filterQuality: FilterQuality.none,
                              errorBuilder: (_, _, _) => const SizedBox()),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 5 * s),
          SdvFrame(
            style: SdvFrameStyle.inset,
            px: 2 * s,
            padding: EdgeInsets.symmetric(vertical: 2 * s),
            child: Center(
              child: Text(time == null ? '--:--' : gameClockLabel(time!),
                  style: sdvText(17 * s, height: 1.15)),
            ),
          ),
          SizedBox(height: 5 * s),
          _GoldCounter(money: money, scale: s),
        ],
      ),
    );
  }
}

/// Mostrador meia-lua: o ponteiro anda das 6h (esquerda) às 2h (direita).
class _DialPainter extends CustomPainter {
  final int time;
  _DialPainter(this.time);

  @override
  void paint(Canvas canvas, Size size) {
    final minutes = (time ~/ 100) * 60 + time % 100;
    final f = ((minutes - 360) / (1560 - 360)).clamp(0.0, 1.0);
    final c = Offset(size.width / 2, size.height);
    final r = size.width / 2 - 1;
    final rect = Rect.fromCircle(center: c, radius: r);
    final sky = Paint()
      ..shader = const SweepGradient(
        startAngle: math.pi,
        endAngle: math.pi * 2,
        colors: [Color(0xFF7EC8F0), Color(0xFFF7B44A), Color(0xFF2B2F6B)],
        stops: [0.25, 0.62, 0.95],
      ).createShader(rect);
    canvas.drawArc(rect, math.pi, math.pi, true, sky);
    canvas.drawArc(rect, math.pi, math.pi, true,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2
          ..color = SdvColors.outline);
    final a = math.pi + math.pi * f;
    final tip = c + Offset(math.cos(a), math.sin(a)) * (r - 3);
    canvas.drawLine(c, tip, Paint()
      ..color = const Color(0xFFB0261C)
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.square);
    canvas.drawCircle(c, 3, Paint()..color = SdvColors.outline);
  }

  @override
  bool shouldRepaint(_DialPainter o) => o.time != time;
}

/// Contador de ouro em casinhas, como no jogo.
class _GoldCounter extends StatelessWidget {
  final int money;
  final double scale;
  const _GoldCounter({required this.money, this.scale = 1});

  @override
  Widget build(BuildContext context) {
    final digits = money.abs().toString();
    const cells = 8;
    final shown = digits.length > cells ? digits.substring(digits.length - cells) : digits;
    final pad = cells - shown.length;
    final s = scale;
    return Container(
      padding: EdgeInsets.all(2 * s),
      color: const Color(0xFF3A1606),
      child: Row(
        children: [
          for (var i = 0; i < cells; i++)
            Expanded(
              child: Container(
                margin: EdgeInsets.symmetric(horizontal: 0.6 * s),
                height: 18 * s,
                color: const Color(0xFFF6CB86),
                alignment: Alignment.center,
                child: Text(i < pad ? '' : shown[i - pad],
                    style: sdvText(14 * s, color: const Color(0xFFB0261C), height: 1)),
              ),
            ),
        ],
      ),
    );
  }
}

/// Barra de ferramentas: os 12 primeiros itens da mochila.
class _Hotbar extends StatelessWidget {
  final List<ApiItem> items;
  final double slot;
  final Widget Function(ApiItem item, double size) icon;
  final void Function(ApiItem item) onTap;
  final int perRow;
  final double framePad;

  const _Hotbar({
    required this.items,
    required this.slot,
    required this.icon,
    required this.onTap,
    this.perRow = 12,
    this.framePad = 15,
  });

  static const _keys = ['1', '2', '3', '4', '5', '6', '7', '8', '9', '0', '-', '='];

  @override
  Widget build(BuildContext context) {
    Widget cell(int i) {
      final item = i < items.length ? items[i] : null;
      return Padding(
        padding: const EdgeInsets.all(1),
        child: SdvSlot(
          size: slot,
          hotkey: _keys[i],
          count: item?.stackSize,
          quality: item?.quality ?? 0,
          onTap: item == null ? null : () => onTap(item),
          child: item == null ? null : icon(item, slot * 0.62),
        ),
      );
    }

    final rows = <Widget>[];
    for (var start = 0; start < 12; start += perRow) {
      rows.add(Row(mainAxisSize: MainAxisSize.min, children: [
        for (var i = start; i < start + perRow && i < 12; i++) cell(i),
      ]));
    }
    return SdvFrame(
      px: framePad < 15 ? 2 : 2.5,
      padding: EdgeInsets.all(framePad),
      child: Column(mainAxisSize: MainAxisSize.min, children: rows),
    );
  }
}

/// Mensagens ao vivo (itens, níveis, amizades, locais), como no canto do jogo.
class _HudFeed extends StatelessWidget {
  final List<HudMessage> messages;
  const _HudFeed({required this.messages});

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final fresh = messages.where((m) => now.difference(m.at).inSeconds < 7).take(2).toList();
    return IgnorePointer(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (final m in fresh.reversed)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: SdvFrame(
                px: 2,
                padding: const EdgeInsets.fromLTRB(11, 7, 11, 7),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(m.icon, style: const TextStyle(fontSize: 12)),
                    const SizedBox(width: 6),
                    Flexible(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 240),
                        child: Text(m.text, maxLines: 1, overflow: TextOverflow.ellipsis, style: sdvText(11.5, height: 1.1)),
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// Aba do menu (fica "encaixada" na janela quando selecionada).
class _MenuTab extends StatelessWidget {
  final _Tab tab;
  final bool selected;
  final VoidCallback onTap;
  final double size;
  const _MenuTab({required this.tab, required this.selected, required this.onTap, this.size = 44});

  @override
  Widget build(BuildContext context) {
    final (emoji, label) = _tabInfo[tab]!;
    return Tooltip(
      message: label,
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          margin: EdgeInsets.only(top: selected ? 6 : 0, bottom: selected ? 0 : 6, right: 3),
          width: size,
          height: size,
          child: SdvFrame(
            px: 2,
            padding: const EdgeInsets.all(8),
            fill: selected ? SdvColors.paper : SdvColors.paperDark,
            child: Center(child: Text(emoji, style: TextStyle(fontSize: size * 0.36))),
          ),
        ),
      ),
    );
  }
}

/// Quadro fixo "Próximo passo": a tarefa do guia ou os objetivos da IA.
class _TodoBanner extends StatelessWidget {
  final StatusTip next;
  final List<AiObjective> objectives;
  final bool busy;
  final VoidCallback onHelp;
  final VoidCallback onOpen;
  final bool compact;

  const _TodoBanner({
    required this.next,
    required this.objectives,
    required this.busy,
    required this.onHelp,
    required this.onOpen,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    final ai = objectives.isNotEmpty;
    return GestureDetector(
      onTap: onOpen,
      child: SdvFrame(
        px: 2,
        padding: const EdgeInsets.fromLTRB(14, 10, 12, 11),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(children: [
              Text(ai ? '✨' : '❗', style: const TextStyle(fontSize: 14)),
              const SizedBox(width: 5),
              Expanded(
                child: Text(ai ? 'PLANO DO CONSELHEIRO' : 'PRÓXIMO PASSO',
                    style: sdvText(11, color: SdvColors.woodDark)),
              ),
              GestureDetector(
                onTap: busy ? null : onHelp,
                child: SdvFrame(
                  style: SdvFrameStyle.wood,
                  px: 1.5,
                  fill: const Color(0xFFB4561A),
                  padding: const EdgeInsets.fromLTRB(8, 4, 8, 5),
                  child: Text(busy ? 'PENSANDO…' : (ai ? 'DE NOVO' : 'AJUDA'),
                      style: sdvText(11, color: Colors.white, shadow: true)),
                ),
              ),
            ]),
            const SizedBox(height: 5),
            if (ai)
              for (final o in objectives.take(compact ? 2 : 3))
                Padding(
                  padding: const EdgeInsets.only(bottom: 3),
                  child: Text.rich(
                    TextSpan(children: [
                      TextSpan(text: '➤ ${o.action}', style: sdvText(13)),
                      if (o.place != null && o.place!.isNotEmpty)
                        TextSpan(text: '  📍${o.place}', style: sdvText(11.5, color: SdvColors.inkSoft)),
                    ]),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                )
            else ...[
              Text(next.title, maxLines: 1, overflow: TextOverflow.ellipsis, style: sdvText(14)),
              Text(next.body, maxLines: compact ? 2 : 3, overflow: TextOverflow.ellipsis,
                  style: sdvText(12, weight: FontWeight.w500, color: SdvColors.inkSoft, height: 1.15)),
            ],
          ],
        ),
      ),
    );
  }
}

class _RoundClose extends StatelessWidget {
  final VoidCallback onTap;
  const _RoundClose({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: SizedBox(
        width: 40,
        height: 40,
        child: SdvFrame(
          style: SdvFrameStyle.wood,
          px: 2,
          fill: const Color(0xFFB4561A),
          padding: EdgeInsets.zero,
          child: Center(child: Text('✕', style: sdvText(18, color: Colors.white, shadow: true))),
        ),
      ),
    );
  }
}

extension _StatusGame on _StatusScreenState {
  Widget _itemIcon(ApiItem item, double size) {
    final entry = _entryFor(item);
    if (entry != null) return EntryImage(entry: entry, size: size);
    final tool = _toolAsset(item.name) ?? _basicAssets[item.name.toLowerCase()];
    if (tool != null) {
      return Image.asset('assets/img/$tool',
          width: size, height: size, filterQuality: FilterQuality.none,
          errorBuilder: (_, _, _) => Text(_typeEmoji(item), style: TextStyle(fontSize: size * 0.7)));
    }
    return Text(_typeEmoji(item), style: TextStyle(fontSize: size * 0.7));
  }

  void _openItem(ApiItem item) => showItemDetailDialog(context, item, _entryFor(item));

  Widget _tabs(double size) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          for (final t in _Tab.values)
            _MenuTab(tab: t, size: size, selected: t == _tab, onTap: () => _selectTab(t)),
        ],
      ),
    );
  }

  Widget _menuWindow(AppScope scope, ApiSnapshot snap) {
    final (_, title) = _tabInfo[_tab]!;
    return SdvFrame(
      px: 3,
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(title, style: sdvText(19)),
          Container(height: 2, margin: const EdgeInsets.only(top: 4, bottom: 8), color: SdvColors.woodDark),
          Expanded(child: _page(scope, snap)),
        ],
      ),
    );
  }

  Widget _todo(AppScope scope, ApiSnapshot snap, {bool compact = false}) {
    final canAi = scope.store.aiModelInstalled && scope.ai.engineReady;
    return _TodoBanner(
      next: recommendedNextStep(snap, scope.repo),
      objectives: parseAiObjectives(_aiText),
      busy: _aiBusy,
      compact: compact,
      onHelp: canAi ? _askAi : _showAiUnavailable,
      onOpen: () => _selectTab(_Tab.advisor),
    );
  }

  Widget _buildGame(AppScope scope, ApiSnapshot snap, GameApi api) {
    final p = snap.player;
    return LayoutBuilder(builder: (context, c) {
      final landscape = c.maxWidth > c.maxHeight;
      final clock = _ClockBox(
        world: snap.world,
        time: api.gameTime,
        money: p.money,
        scale: landscape ? 1 : 0.92,
      );
      final bars = Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          SdvVitalBar(label: 'E', value: p.stamina, max: p.maxStamina.toDouble(),
              color: SdvColors.energy, height: landscape ? 140 : 130),
          const SizedBox(width: 4),
          SdvVitalBar(label: 'V', value: p.health.toDouble(), max: p.maxHealth.toDouble(),
              color: SdvColors.health, height: landscape ? 140 : 130),
        ],
      );

      if (landscape) {
        final center = c.maxWidth - 200 - 180 - 16;
        final slot = ((center - 30) / 12 - 2).clamp(24.0, 50.0);
        return Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SizedBox(
              width: 200,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _MiniMap(loc: locationInfo(p.location), onTap: () => _showFullMap(context)),
                  const SizedBox(height: 6),
                  if (_tab != _Tab.advisor)
                    Flexible(child: SingleChildScrollView(child: _todo(scope, snap))),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _tabs(42),
                  Expanded(child: _menuWindow(scope, snap)),
                  const SizedBox(height: 4),
                  Center(child: _Hotbar(items: snap.inventory, slot: slot, framePad: 11, icon: _itemIcon, onTap: _openItem)),
                ],
              ),
            ),
            const SizedBox(width: 8),
            SizedBox(
              width: 180,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      if (api.wsConnected) const _LivePill(),
                      const SizedBox(width: 6),
                      _RoundClose(onTap: _close),
                    ],
                  ),
                  const SizedBox(height: 6),
                  clock,
                  // As mensagens só usam o espaço que sobra (nunca empurram as barras).
                  Expanded(
                    child: SingleChildScrollView(
                      reverse: true,
                      physics: const NeverScrollableScrollPhysics(),
                      child: Align(alignment: Alignment.bottomRight, child: _HudFeed(messages: api.hud)),
                    ),
                  ),
                  const SizedBox(height: 6),
                  bars,
                ],
              ),
            ),
          ],
        );
      }

      final perRow = c.maxWidth >= 320 ? 12 : 6;
      final slot = ((c.maxWidth - 26) / perRow - 2).clamp(22.0, 54.0);
      return Stack(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Row(children: [
                          _RoundClose(onTap: _close),
                          const SizedBox(width: 8),
                          if (api.wsConnected) const _LivePill(),
                        ]),
                        const SizedBox(height: 6),
                        _MiniMap(loc: locationInfo(p.location), onTap: () => _showFullMap(context)),
                      ],
                    ),
                  ),
                  const SizedBox(width: 6),
                  SizedBox(width: 168, child: clock),
                ],
              ),
              if (_tab != _Tab.advisor) ...[
                const SizedBox(height: 6),
                _todo(scope, snap, compact: true),
              ],
              const SizedBox(height: 4),
              _tabs(44),
              Expanded(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Expanded(child: _menuWindow(scope, snap)),
                    const SizedBox(width: 4),
                    Column(mainAxisAlignment: MainAxisAlignment.end, children: [bars]),
                  ],
                ),
              ),
              const SizedBox(height: 4),
              Center(child: _Hotbar(items: snap.inventory, slot: slot, perRow: perRow, framePad: 11, icon: _itemIcon, onTap: _openItem)),
            ],
          ),
          Positioned(left: 8, bottom: (perRow == 6 ? slot * 2 + 4 : slot) + 30, child: _HudFeed(messages: api.hud)),
        ],
      );
    });
  }
}
