part of 'status_screen.dart';

// ---------------------------------------------------------------------------
// Peças visuais no estilo do jogo.
// ---------------------------------------------------------------------------

class _Backdrop extends StatelessWidget {
  final ApiSnapshot? snap;
  const _Backdrop({this.snap});

  @override
  Widget build(BuildContext context) {
    final season = snap?.world.season ?? 0;
    final mine = (snap?.player.location ?? '').toLowerCase().contains('mine');
    final image = mine
        ? 'assets/img/locations_the_mines.png'
        : 'assets/img/map_valley.png';
    final tint = switch (season) {
      1 => const Color(0xFFF9A825),
      2 => const Color(0xFFE65100),
      3 => const Color(0xFF4FC3F7),
      _ => const Color(0xFF66BB6A),
    };
    return Stack(
      fit: StackFit.expand,
      children: [
        Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0xFF18384A), Color(0xFF2A1A12), Color(0xFF160E09)],
            ),
          ),
        ),
        Opacity(
          opacity: mine ? 0.42 : 0.20,
          child: Image.asset(
            image,
            fit: BoxFit.cover,
            filterQuality: FilterQuality.none,
            errorBuilder: (_, _, _) => const SizedBox.shrink(),
          ),
        ),
        Container(color: tint.withValues(alpha: 0.11)),
        Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.black.withValues(alpha: 0.48),
                Colors.black.withValues(alpha: 0.20),
                Colors.black.withValues(alpha: 0.72),
              ],
            ),
          ),
        ),
        const IgnorePointer(child: _PixelGrain()),
      ],
    );
  }
}

class _PixelGrain extends StatelessWidget {
  const _PixelGrain();

  @override
  Widget build(BuildContext context) {
    return CustomPaint(painter: _GrainPainter(), size: Size.infinite);
  }
}

class _GrainPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = Colors.white.withValues(alpha: 0.025);
    const step = 14.0;
    for (var y = 0.0; y < size.height; y += step) {
      for (var x = 0.0; x < size.width; x += step) {
        if (((x / step).round() + (y / step).round()) % 5 == 0) {
          canvas.drawRect(Rect.fromLTWH(x, y, 1, 1), paint);
        }
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _GamePanel extends StatelessWidget {
  final Widget child;
  final Color? accent;
  final EdgeInsetsGeometry padding;
  final bool dark;

  const _GamePanel({
    required this.child,
    this.accent,
    this.padding = const EdgeInsets.all(10),
    this.dark = false,
  });

  @override
  Widget build(BuildContext context) {
    final border =
        accent ??
        (dark ? _gold.withValues(alpha: 0.65) : const Color(0xFFB78645));
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: _woodDark, width: 2.2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.42),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      padding: const EdgeInsets.all(2),
      child: Container(
        decoration: BoxDecoration(
          color: dark ? _wood.withValues(alpha: 0.92) : _paper,
          borderRadius: BorderRadius.circular(7),
          border: Border.all(color: border, width: 1.4),
        ),
        padding: padding,
        child: child,
      ),
    );
  }
}

class _PanelLabel extends StatelessWidget {
  final String text;
  final IconData icon;
  const _PanelLabel(this.text, {required this.icon});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: _gold),
        const SizedBox(width: 4),
        Text(
          text,
          style: const TextStyle(
            fontFamily: 'PixelifySans',
            fontSize: 11,
            letterSpacing: 1.2,
            fontWeight: FontWeight.w700,
            color: _goldSoft,
          ),
        ),
      ],
    );
  }
}

class _PanelHeader extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color color;
  final String? count;
  const _PanelHeader({
    required this.title,
    required this.icon,
    required this.color,
    this.count,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 17, color: color),
        const SizedBox(width: 5),
        Expanded(
          child: Text(
            title,
            style: TextStyle(
              fontFamily: 'PixelifySans',
              fontSize: 15,
              letterSpacing: 1.1,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ),
        if (count != null)
          Text(
            count!,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w900,
              color: color.withValues(alpha: 0.8),
            ),
          ),
      ],
    );
  }
}

class _TinyTag extends StatelessWidget {
  final String text;
  final Color color;
  const _TinyTag(this.text, this.color);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(5),
        border: Border.all(color: color.withValues(alpha: 0.5)),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 8.5,
          fontWeight: FontWeight.w900,
          color: color,
          letterSpacing: 0.4,
        ),
      ),
    );
  }
}

class _LivePill extends StatelessWidget {
  const _LivePill();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.42),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: const Color(0xFF9CCC65).withValues(alpha: 0.7),
        ),
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.circle, size: 7, color: Color(0xFF9CCC65)),
          SizedBox(width: 4),
          Text(
            'AO VIVO',
            style: TextStyle(
              color: Color(0xFFD9F0B8),
              fontSize: 9,
              fontWeight: FontWeight.w900,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }
}

class _DatePill extends StatelessWidget {
  final ApiWorld world;
  final WeatherInfo weather;
  const _DatePill({required this.world, required this.weather});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: _paper.withValues(alpha: 0.95),
        borderRadius: BorderRadius.circular(7),
        border: Border.all(color: _gold, width: 1.3),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.25),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(weather.emoji, style: const TextStyle(fontSize: 15)),
          const SizedBox(width: 4),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${seasonEmojiFor(world.season)} ${seasonNameFor(world.season)} ${world.day}',
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w900,
                  color: _ink,
                  height: 1.1,
                ),
              ),
              Text(
                'Ano ${world.year} · ${weather.label}',
                style: const TextStyle(
                  fontSize: 9,
                  color: Color(0xFF6B5238),
                  height: 1.1,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _CloseButton extends StatelessWidget {
  final VoidCallback onTap;
  const _CloseButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: _wood.withValues(alpha: 0.92),
            shape: BoxShape.circle,
            border: Border.all(color: _gold, width: 2),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.45),
                blurRadius: 5,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: const Icon(Icons.close_rounded, color: _goldSoft, size: 22),
        ),
      ),
    );
  }
}

class _StatTile extends StatelessWidget {
  final Object icon;
  final String label;
  final String value;
  final Color color;
  final double? fraction;
  final String? sub;
  final String? tooltip;
  final VoidCallback? onTap;

  const _StatTile({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
    this.fraction,
    this.sub,
    this.tooltip,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final content = InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(6),
      child: Container(
        padding: const EdgeInsets.fromLTRB(6, 5, 6, 5),
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.18),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: color.withValues(alpha: 0.35)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                SizedBox(
                  width: 15,
                  height: 15,
                  child: icon is String
                      ? Image.asset(
                          icon as String,
                          filterQuality: FilterQuality.none,
                          errorBuilder: (_, _, _) =>
                              Icon(Icons.circle, size: 11, color: color),
                        )
                      : Icon(icon as IconData, size: 13, color: color),
                ),
                const SizedBox(width: 3),
                Expanded(
                  child: Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 8,
                      letterSpacing: 0.7,
                      fontWeight: FontWeight.w900,
                      color: _goldSoft,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 1),
            Text(
              value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontFamily: 'PixelifySans',
                fontSize: 15,
                height: 1.05,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
            if (fraction != null) ...[
              const SizedBox(height: 3),
              ClipRRect(
                borderRadius: BorderRadius.circular(3),
                child: LinearProgressIndicator(
                  value: clamp01(fraction!),
                  minHeight: 4,
                  backgroundColor: Colors.white.withValues(alpha: 0.12),
                  valueColor: AlwaysStoppedAnimation(color),
                ),
              ),
            ] else if (sub != null) ...[
              const SizedBox(height: 1),
              Text(
                sub!,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 8.5,
                  height: 1.1,
                  color: Color(0xFFD9C9A8),
                ),
              ),
            ],
          ],
        ),
      ),
    );
    return tooltip == null || tooltip!.trim().isEmpty
        ? content
        : Tooltip(message: tooltip!, child: content);
  }
}

class _MapCanvas extends StatelessWidget {
  final LocationInfo info;
  final VoidCallback onTap;
  const _MapCanvas({required this.info, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, c) {
        final available = c.maxWidth;
        var w = available;
        var h = w * 244 / 400;
        const maxH = 152.0;
        if (h > maxH) {
          h = maxH;
          w = h * 400 / 244;
        }
        return Center(
          child: GestureDetector(
            onTap: onTap,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: Container(
                width: w,
                height: h,
                decoration: BoxDecoration(
                  border: Border.all(
                    color: _gold.withValues(alpha: 0.7),
                    width: 1.2,
                  ),
                ),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    Image.asset(
                      'assets/img/map_valley.png',
                      fit: BoxFit.fill,
                      filterQuality: FilterQuality.none,
                    ),
                    Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.black.withValues(alpha: 0.08),
                            Colors.black.withValues(alpha: 0.28),
                          ],
                        ),
                      ),
                    ),
                    if (info.hasPin)
                      Positioned(
                        left: (info.x! * w - 18).clamp(0.0, w - 36),
                        top: (info.y! * h - 30).clamp(0.0, h - 38),
                        child: _YouPin(label: info.displayName),
                      ),
                    Positioned(
                      right: 5,
                      bottom: 4,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 5,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.62),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Text(
                          'N',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 9,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _YouPin extends StatelessWidget {
  final String label;
  const _YouPin({required this.label});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 78,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
            decoration: BoxDecoration(
              color: _red,
              borderRadius: BorderRadius.circular(3),
              border: Border.all(color: Colors.white, width: 1),
            ),
            child: Text(
              'VOCÊ',
              maxLines: 1,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 7.5,
                fontWeight: FontWeight.w900,
                letterSpacing: 0.5,
              ),
            ),
          ),
          const Icon(
            Icons.place_rounded,
            color: _red,
            size: 26,
            shadows: [Shadow(color: Colors.black54, blurRadius: 4)],
          ),
        ],
      ),
    );
  }
}
