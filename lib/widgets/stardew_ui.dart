import 'package:flutter/material.dart';

/// Peças visuais no estilo da interface do Stardew Valley: molduras de madeira
/// em pixel art, papel do menu, slots da mochila, corações e barras.
///
/// Tudo é desenhado em código (sem sprites da interface do jogo), com a mesma
/// paleta e o mesmo "degrau" de pixel das janelas originais.
class SdvColors {
  static const outline = Color(0xFF3B1B0B);
  static const woodDark = Color(0xFF853A10);
  static const wood = Color(0xFFD27A2C);
  static const woodLight = Color(0xFFF2A953);
  static const paper = Color(0xFFFBD597);
  static const paperDark = Color(0xFFF1BE76);
  static const slot = Color(0xFFF6CB86);
  static const slotShadow = Color(0xFFC98340);
  static const ink = Color(0xFF3E1F0C);
  static const inkSoft = Color(0xFF7A4520);
  static const heart = Color(0xFFE2283D);
  static const heartEmpty = Color(0xFFC9996B);
  static const energy = Color(0xFF4FBF3B);
  static const health = Color(0xFFE2283D);
  static const gold = Color(0xFFFFD34E);
  static const night = Color(0xFF1B2A4A);
}

/// Fonte de pixel do app (PixelifySans) com sombra de texto como no jogo.
TextStyle sdvText(
  double size, {
  Color color = SdvColors.ink,
  bool shadow = false,
  FontWeight weight = FontWeight.w700,
  double? height,
}) {
  return TextStyle(
    fontFamily: 'PixelifySans',
    fontSize: size,
    fontWeight: weight,
    color: color,
    height: height,
    shadows: shadow
        ? const [Shadow(color: Color(0x88000000), offset: Offset(1.2, 1.2))]
        : null,
  );
}

enum SdvFrameStyle {
  /// Janela de menu: madeira laranja e papel claro.
  menu,

  /// Painel escuro de madeira (relógio, barras).
  wood,

  /// Caixa interna afundada (slot, campo).
  inset,
}

/// Moldura em pixel art. [px] é o tamanho do "pixel" do desenho.
class SdvFrame extends StatelessWidget {
  final Widget child;
  final SdvFrameStyle style;
  final EdgeInsetsGeometry padding;
  final double px;
  final Color? fill;
  final double? width;

  const SdvFrame({
    super.key,
    required this.child,
    this.style = SdvFrameStyle.menu,
    this.padding = const EdgeInsets.all(12),
    this.px = 3,
    this.fill,
    this.width,
  });

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _FramePainter(style, px, fill),
      child: SizedBox(width: width, child: Padding(padding: padding, child: child)),
    );
  }
}

class _FramePainter extends CustomPainter {
  final SdvFrameStyle style;
  final double px;
  final Color? fill;
  _FramePainter(this.style, this.px, this.fill);

  void _box(Canvas c, Size s, double inset, double cut, Color color) {
    final p = Paint()..color = color;
    final l = inset, t = inset, r = s.width - inset, b = s.height - inset;
    final path = Path()
      ..moveTo(l + cut, t)
      ..lineTo(r - cut, t)
      ..lineTo(r - cut, t + px)
      ..lineTo(r, t + px)
      ..lineTo(r, b - px)
      ..lineTo(r - cut, b - px)
      ..lineTo(r - cut, b)
      ..lineTo(l + cut, b)
      ..lineTo(l + cut, b - px)
      ..lineTo(l, b - px)
      ..lineTo(l, t + px)
      ..lineTo(l + cut, t + px)
      ..close();
    c.drawPath(path, p);
  }

  @override
  void paint(Canvas canvas, Size size) {
    switch (style) {
      case SdvFrameStyle.menu:
        _box(canvas, size, 0, px, SdvColors.outline);
        _box(canvas, size, px, px, SdvColors.woodDark);
        _box(canvas, size, px * 2, px, SdvColors.wood);
        _box(canvas, size, px * 3, px, SdvColors.woodLight);
        _box(canvas, size, px * 4, 0, SdvColors.woodDark);
        _box(canvas, size, px * 5, 0, fill ?? SdvColors.paper);
        // brilho do papel no topo
        canvas.drawRect(
          Rect.fromLTWH(px * 5, px * 5, size.width - px * 10, px),
          Paint()..color = const Color(0x55FFFFFF),
        );
      case SdvFrameStyle.wood:
        _box(canvas, size, 0, px, SdvColors.outline);
        _box(canvas, size, px, px, SdvColors.woodDark);
        _box(canvas, size, px * 2, px, SdvColors.wood);
        _box(canvas, size, px * 3, 0, fill ?? const Color(0xFF6B2E0E));
      case SdvFrameStyle.inset:
        _box(canvas, size, 0, 0, SdvColors.slotShadow);
        _box(canvas, size, px, 0, fill ?? SdvColors.slot);
        canvas.drawRect(
          Rect.fromLTWH(px, px, size.width - px * 2, px),
          Paint()..color = const Color(0x33000000),
        );
    }
  }

  @override
  bool shouldRepaint(_FramePainter o) =>
      o.style != style || o.px != px || o.fill != fill;
}

/// Slot da mochila/barra de ferramentas.
class SdvSlot extends StatelessWidget {
  final Widget? child;
  final double size;
  final int? count;
  final int quality;
  final String? hotkey;
  final bool selected;
  final VoidCallback? onTap;

  const SdvSlot({
    super.key,
    this.child,
    this.size = 44,
    this.count,
    this.quality = 0,
    this.hotkey,
    this.selected = false,
    this.onTap,
  });

  Color get _starColor => switch (quality) {
        1 => const Color(0xFFC7D2D9),
        2 => const Color(0xFFFFD34E),
        _ => const Color(0xFFB65CE0),
      };

  @override
  Widget build(BuildContext context) {
    final countSize = (size * 0.26).clamp(9.0, 15.0);
    return GestureDetector(
      onTap: onTap,
      child: SizedBox(
        width: size,
        height: size,
        child: Stack(
          children: [
            Positioned.fill(
              child: SdvFrame(
                style: SdvFrameStyle.inset,
                px: (size / 22).clamp(1.5, 3),
                padding: EdgeInsets.all(size * 0.12),
                child: Center(child: child ?? const SizedBox()),
              ),
            ),
            if (selected)
              Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    border: Border.all(color: const Color(0xFFE8331C), width: 2),
                  ),
                ),
              ),
            if (hotkey != null)
              Positioned(
                left: 2,
                top: 0,
                child: Text(hotkey!, style: sdvText(size * 0.2, color: SdvColors.inkSoft)),
              ),
            if (quality > 0)
              Positioned(
                left: 2,
                bottom: 1,
                child: Text('★', style: TextStyle(fontSize: size * 0.26, color: _starColor, height: 1,
                    shadows: const [Shadow(color: Colors.black54, offset: Offset(1, 1))])),
              ),
            if (count != null && count! > 1)
              Positioned(
                right: 3,
                bottom: 0,
                child: Text(
                  '$count',
                  style: sdvText(countSize, color: Colors.white, shadow: true, height: 1.1),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// Coração de amizade em pixel art.
class SdvHeart extends StatelessWidget {
  final bool filled;
  final double size;
  const SdvHeart({super.key, required this.filled, this.size = 14});

  @override
  Widget build(BuildContext context) =>
      CustomPaint(size: Size.square(size), painter: _HeartPainter(filled));
}

class _HeartPainter extends CustomPainter {
  final bool filled;
  _HeartPainter(this.filled);

  // Coração 7x6 do jogo: 1 = contorno, 2 = preenchimento, 3 = brilho.
  static const _grid = [
    [0, 1, 1, 0, 1, 1, 0],
    [1, 3, 2, 1, 2, 2, 1],
    [1, 2, 2, 2, 2, 2, 1],
    [0, 1, 2, 2, 2, 1, 0],
    [0, 0, 1, 2, 1, 0, 0],
    [0, 0, 0, 1, 0, 0, 0],
  ];

  @override
  void paint(Canvas canvas, Size size) {
    final px = size.width / 7;
    final top = (size.height - px * 6) / 2;
    final colors = {
      1: filled ? const Color(0xFF6B0F1A) : const Color(0xFF7A5236),
      2: filled ? SdvColors.heart : SdvColors.heartEmpty,
      3: filled ? const Color(0xFFFFA3AE) : const Color(0xFFE3C19A),
    };
    for (var y = 0; y < _grid.length; y++) {
      for (var x = 0; x < 7; x++) {
        final v = _grid[y][x];
        if (v == 0) continue;
        canvas.drawRect(
          Rect.fromLTWH(x * px, top + y * px, px + 0.4, px + 0.4),
          Paint()..color = colors[v]!,
        );
      }
    }
  }

  @override
  bool shouldRepaint(_HeartPainter o) => o.filled != filled;
}

/// Fileira de corações (10, ou 14 para cônjuge).
class SdvHearts extends StatelessWidget {
  final int hearts;
  final int max;
  final double size;
  const SdvHearts({super.key, required this.hearts, this.max = 10, this.size = 13});

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 1,
      runSpacing: 1,
      children: [
        for (var i = 0; i < max; i++) SdvHeart(filled: i < hearts, size: size),
      ],
    );
  }
}

/// As 10 caixinhas de nível da aba Habilidades (5 e 10 são maiores e douradas).
class SdvLevelBoxes extends StatelessWidget {
  final int level;
  final double size;
  const SdvLevelBoxes({super.key, required this.level, this.size = 12});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        for (var i = 1; i <= 10; i++) ...[
          _box(i),
          if (i < 10) SizedBox(width: size * 0.22),
        ],
      ],
    );
  }

  Widget _box(int i) {
    final big = i == 5 || i == 10;
    final on = i <= level;
    final s = big ? size * 1.35 : size;
    return Container(
      width: s,
      height: s,
      decoration: BoxDecoration(
        color: on
            ? (big ? const Color(0xFFFFC23A) : const Color(0xFFF08A2A))
            : const Color(0xFFD9A868),
        border: Border.all(
          color: on ? const Color(0xFF8A3A10) : const Color(0xFFB07A43),
          width: 1.5,
        ),
      ),
    );
  }
}

/// Barra vertical de Energia/Vida do canto da tela, como no jogo.
class SdvVitalBar extends StatelessWidget {
  final String label;
  final double value;
  final double max;
  final Color color;
  final double height;

  const SdvVitalBar({
    super.key,
    required this.label,
    required this.value,
    required this.max,
    required this.color,
    this.height = 150,
  });

  Color _fill(double f) {
    if (color == SdvColors.health) return color;
    if (f > 0.5) return SdvColors.energy;
    if (f > 0.25) return const Color(0xFFE8C21E);
    return const Color(0xFFE2462B);
  }

  @override
  Widget build(BuildContext context) {
    final f = max <= 0 ? 0.0 : (value / max).clamp(0.0, 1.0);
    return SizedBox(
      width: 34,
      height: height,
      child: SdvFrame(
        style: SdvFrameStyle.wood,
        px: 2.5,
        padding: const EdgeInsets.fromLTRB(9, 6, 9, 9),
        child: Column(
          children: [
            Text(label, style: sdvText(13, color: SdvColors.gold, shadow: true, height: 1)),
            const SizedBox(height: 4),
            Expanded(
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: const Color(0xFF2A1206),
                  border: Border.all(color: SdvColors.outline, width: 1.5),
                ),
                alignment: Alignment.bottomCenter,
                child: AnimatedFractionallySizedBox(
                  duration: const Duration(milliseconds: 500),
                  curve: Curves.easeOut,
                  heightFactor: f,
                  widthFactor: 1,
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                        colors: [_fill(f), Color.lerp(_fill(f), Colors.white, 0.35)!, _fill(f)],
                        stops: const [0, 0.35, 1],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Botão de madeira no estilo do jogo.
class SdvButton extends StatelessWidget {
  final String label;
  final VoidCallback? onTap;
  final Widget? icon;
  final double size;
  const SdvButton({super.key, required this.label, this.onTap, this.icon, this.size = 14});

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: onTap == null ? 0.55 : 1,
      child: GestureDetector(
        onTap: onTap,
        child: SdvFrame(
          style: SdvFrameStyle.wood,
          px: 2.5,
          fill: const Color(0xFFB4561A),
          padding: const EdgeInsets.fromLTRB(14, 9, 14, 10),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[icon!, const SizedBox(width: 6)],
              Text(label, style: sdvText(size, color: Colors.white, shadow: true)),
            ],
          ),
        ),
      ),
    );
  }
}

/// Item da barra inferior.
class SdvNavItem {
  final IconData icon;
  final String label;
  final bool locked;
  const SdvNavItem(this.icon, this.label, {this.locked = false});
}

/// Barra inferior do app no formato da barra de ferramentas do jogo.
class SdvNavBar extends StatelessWidget {
  final List<SdvNavItem> items;
  final int selected;
  final ValueChanged<int> onTap;
  const SdvNavBar({super.key, required this.items, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFF2A1206),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(6, 6, 6, 4),
          child: SdvFrame(
            px: 2,
            padding: const EdgeInsets.all(11),
            child: Row(
              children: [
                for (var i = 0; i < items.length; i++)
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 2),
                      child: _slot(items[i], i == selected, () => onTap(i)),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _slot(SdvNavItem item, bool on, VoidCallback tap) {
    return Semantics(
      button: true,
      selected: on,
      label: item.label,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: tap,
        child: Stack(
          children: [
            SdvFrame(
              style: SdvFrameStyle.inset,
              px: 2,
              fill: on ? const Color(0xFFFFE3AE) : null,
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(7, 7, 7, 6),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(item.locked ? Icons.lock_rounded : item.icon,
                      size: 24, color: on ? const Color(0xFFB4561A) : SdvColors.inkSoft),
                  const SizedBox(height: 2),
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(item.label, maxLines: 1, style: sdvText(11, color: on ? SdvColors.ink : SdvColors.inkSoft)),
                  ),
                ],
              ),
            ),
            if (on)
              Positioned.fill(
                child: IgnorePointer(
                  child: DecoratedBox(
                    decoration: BoxDecoration(border: Border.all(color: const Color(0xFFE8331C), width: 2)),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// Botão quadrado de madeira com ícone (barra de topo das telas).
class SdvIconButton extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback? onTap;
  final double size;
  const SdvIconButton({super.key, required this.icon, required this.tooltip, this.onTap, this.size = 42});

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: GestureDetector(
        onTap: onTap,
        child: SizedBox(
          width: size,
          height: size,
          child: SdvFrame(
            style: SdvFrameStyle.wood,
            px: 2,
            fill: const Color(0xFFB4561A),
            padding: EdgeInsets.zero,
            child: Center(
              child: Icon(icon, color: Colors.white, size: size * 0.5,
                  shadows: const [Shadow(color: Color(0x88000000), offset: Offset(1, 1))]),
            ),
          ),
        ),
      ),
    );
  }
}

/// Placa de madeira com título em pixel (cabeçalho das telas principais).
class SdvTitleBoard extends StatelessWidget {
  final String title;
  final String? subtitle;
  final List<Widget> actions;
  final Widget? leading;
  const SdvTitleBoard({super.key, required this.title, this.subtitle, this.actions = const [], this.leading});

  @override
  Widget build(BuildContext context) {
    return SdvFrame(
      style: SdvFrameStyle.wood,
      px: 2.5,
      padding: const EdgeInsets.fromLTRB(14, 11, 11, 12),
      child: Row(
        children: [
          if (leading != null) ...[leading!, const SizedBox(width: 10)],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, maxLines: 1, overflow: TextOverflow.ellipsis,
                    style: sdvText(24, color: Colors.white, shadow: true, height: 1.1)),
                if (subtitle != null)
                  Text(subtitle!, maxLines: 2, overflow: TextOverflow.ellipsis,
                      style: sdvText(13, color: SdvColors.gold, shadow: true, weight: FontWeight.w500)),
              ],
            ),
          ),
          for (final a in actions) ...[const SizedBox(width: 6), a],
        ],
      ),
    );
  }
}

/// Barra de progresso em pixel (coleções, metas).
class SdvProgressBar extends StatelessWidget {
  final double value;
  final Color color;
  final double height;
  const SdvProgressBar({super.key, required this.value, this.color = SdvColors.energy, this.height = 10});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      decoration: BoxDecoration(
        color: const Color(0xFF6B3A18),
        border: Border.all(color: SdvColors.outline, width: 1.5),
      ),
      alignment: Alignment.centerLeft,
      child: FractionallySizedBox(
        widthFactor: value.clamp(0.0, 1.0),
        heightFactor: 1,
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color.lerp(color, Colors.white, 0.35)!, color],
            ),
          ),
        ),
      ),
    );
  }
}
