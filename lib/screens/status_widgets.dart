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

  const _GamePanel({
    required this.child,
    this.accent,
    this.padding = const EdgeInsets.all(10),
  });

  @override
  Widget build(BuildContext context) {
    return SdvFrame(
      px: 2.5,
      padding: padding.add(const EdgeInsets.all(12)),
      child: child,
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
          fontWeight: FontWeight.w700,
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
              fontWeight: FontWeight.w700,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
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
                fontWeight: FontWeight.w700,
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
