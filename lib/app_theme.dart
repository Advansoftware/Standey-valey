import 'package:flutter/material.dart';

import 'widgets/stardew_ui.dart';

const _pixelFont = 'PixelifySans';

/// Tema no estilo da interface do Stardew Valley: papel dos menus, madeira
/// nas bordas e botões, fonte de pixel nos títulos. O modo escuro é a
/// "noite" do jogo: madeira escura com papel envelhecido.
ThemeData buildTheme(Brightness b) {
  final dark = b == Brightness.dark;
  final paper = dark ? const Color(0xFF3A2414) : const Color(0xFFF8DFAE);
  final ink = dark ? const Color(0xFFF6DDB0) : SdvColors.ink;
  final scheme = ColorScheme.fromSeed(seedColor: SdvColors.wood, brightness: b).copyWith(
    surface: paper,
    onSurface: ink,
    primary: dark ? const Color(0xFFF2A953) : const Color(0xFFB4561A),
    onPrimary: Colors.white,
    secondary: dark ? const Color(0xFF9CCC65) : const Color(0xFF3F7A2A),
    surfaceContainerHighest: dark ? const Color(0xFF4A2E19) : SdvColors.paper,
    outline: dark ? const Color(0xFF8A5A33) : SdvColors.woodDark,
  );
  final pixelShape = RoundedRectangleBorder(
    borderRadius: BorderRadius.circular(3),
    side: const BorderSide(color: SdvColors.outline, width: 2),
  );
  final base = ThemeData(useMaterial3: true, colorScheme: scheme, brightness: b);
  TextStyle? px(TextStyle? s) => s?.copyWith(fontFamily: _pixelFont, color: ink);
  final text = base.textTheme.apply(bodyColor: ink, displayColor: ink);
  return base.copyWith(
    scaffoldBackgroundColor: dark ? const Color(0xFF241409) : const Color(0xFFEFCB8A),
    textTheme: text.copyWith(
      displayLarge: px(text.displayLarge),
      displayMedium: px(text.displayMedium),
      displaySmall: px(text.displaySmall),
      headlineLarge: px(text.headlineLarge),
      headlineMedium: px(text.headlineMedium),
      headlineSmall: px(text.headlineSmall),
      titleLarge: px(text.titleLarge),
      titleMedium: px(text.titleMedium),
      titleSmall: px(text.titleSmall),
      labelLarge: px(text.labelLarge),
      labelMedium: px(text.labelMedium),
      labelSmall: px(text.labelSmall),
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: dark ? const Color(0xFF4A2210) : SdvColors.woodDark,
      foregroundColor: Colors.white,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: false,
      shape: const Border(bottom: BorderSide(color: SdvColors.outline, width: 3)),
      titleTextStyle: sdvText(21, color: Colors.white, shadow: true),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: const Color(0xFFB4561A),
        foregroundColor: Colors.white,
        shape: pixelShape,
        textStyle: sdvText(15, color: Colors.white),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: SdvColors.paper,
        foregroundColor: SdvColors.ink,
        shape: pixelShape,
        textStyle: sdvText(15),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: ink,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(3)),
        side: BorderSide(color: scheme.outline, width: 2),
        textStyle: sdvText(15),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(foregroundColor: scheme.primary, textStyle: sdvText(15)),
    ),
    segmentedButtonTheme: SegmentedButtonThemeData(
      style: SegmentedButton.styleFrom(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(3)),
        side: BorderSide(color: scheme.outline, width: 2),
        selectedBackgroundColor: dark ? const Color(0xFF6B3A18) : const Color(0xFFF2A953),
        textStyle: sdvText(14),
      ),
    ),
    chipTheme: ChipThemeData(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(3)),
      side: BorderSide(color: scheme.outline, width: 1.5),
      backgroundColor: dark ? const Color(0xFF4A2E19) : SdvColors.paper,
      selectedColor: dark ? const Color(0xFF6B3A18) : const Color(0xFFF2A953),
      labelStyle: sdvText(13, color: ink),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: dark ? const Color(0xFF4A2E19) : const Color(0xFFFFEFCB),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(3),
        borderSide: BorderSide(color: scheme.outline, width: 2),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(3),
        borderSide: BorderSide(color: scheme.outline, width: 2),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(3),
        borderSide: const BorderSide(color: Color(0xFFE8331C), width: 2.5),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: paper,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(4),
        side: const BorderSide(color: SdvColors.woodDark, width: 4),
      ),
      titleTextStyle: sdvText(20, color: ink),
    ),
    snackBarTheme: SnackBarThemeData(
      backgroundColor: SdvColors.paper,
      contentTextStyle: sdvText(14),
      actionTextColor: const Color(0xFFB4561A),
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(3),
        side: const BorderSide(color: SdvColors.woodDark, width: 3),
      ),
    ),
    dividerTheme: DividerThemeData(color: scheme.outline.withValues(alpha: 0.6), thickness: 2),
    progressIndicatorTheme: const ProgressIndicatorThemeData(color: Color(0xFF4FBF3B)),
    switchTheme: SwitchThemeData(
      thumbColor: WidgetStateProperty.resolveWith(
        (s) => s.contains(WidgetState.selected) ? Colors.white : SdvColors.woodDark,
      ),
      trackColor: WidgetStateProperty.resolveWith(
        (s) => s.contains(WidgetState.selected) ? const Color(0xFF3F7A2A) : SdvColors.paper,
      ),
      trackOutlineColor: WidgetStateProperty.all(SdvColors.woodDark),
    ),
    checkboxTheme: CheckboxThemeData(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(1)),
      side: const BorderSide(color: SdvColors.woodDark, width: 2),
      fillColor: WidgetStateProperty.resolveWith(
        (s) => s.contains(WidgetState.selected) ? const Color(0xFF3F7A2A) : SdvColors.slot,
      ),
    ),
    listTileTheme: ListTileThemeData(
      titleTextStyle: sdvText(15, color: ink),
      iconColor: scheme.primary,
    ),
    sliderTheme: SliderThemeData(
      activeTrackColor: const Color(0xFFB4561A),
      thumbColor: SdvColors.woodDark,
      inactiveTrackColor: scheme.outline.withValues(alpha: 0.3),
    ),
  );
}

/// Cartão "papel de menu" usado em todo o app (decoração simples, sem moldura
/// de pixel: para listas longas e lugares onde só cabe uma [BoxDecoration]).
BoxDecoration parchment(BuildContext context, {Color? accent, double radius = 20}) {
  final dark = Theme.of(context).brightness == Brightness.dark;
  return BoxDecoration(
    color: dark ? const Color(0xFF4A2E19) : SdvColors.paper,
    borderRadius: BorderRadius.circular(4),
    border: Border.all(color: accent ?? SdvColors.woodDark, width: 2.5),
    boxShadow: const [BoxShadow(color: Color(0x55000000), offset: Offset(2, 3))],
  );
}

/// Cartão com a moldura de madeira em pixel art das janelas do jogo.
///
/// Usa [Material] para que as ondas de toque apareçam sobre o papel e para
/// que ListTiles dentro dele tenham o Material certo.
class Parchment extends StatelessWidget {
  final Widget child;
  final Color? accent;
  final double radius;
  final EdgeInsetsGeometry? padding;
  final VoidCallback? onTap;

  const Parchment({
    super.key,
    required this.child,
    this.accent,
    this.radius = 20,
    this.padding,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final content = Padding(padding: padding ?? EdgeInsets.zero, child: child);
    return SdvFrame(
      px: 2,
      padding: const EdgeInsets.all(10),
      fill: dark ? const Color(0xFF4A2E19) : null,
      child: Material(
        color: Colors.transparent,
        child: onTap == null
            ? content
            : InkWell(borderRadius: BorderRadius.circular(3), onTap: onTap, child: content),
      ),
    );
  }
}
