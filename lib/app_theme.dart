import 'package:flutter/material.dart';

const _seed = Color(0xFF5B8C3A);

ThemeData buildTheme(Brightness b) {
  final dark = b == Brightness.dark;
  final scheme = ColorScheme.fromSeed(seedColor: _seed, brightness: b).copyWith(
    surface: dark ? const Color(0xFF1F1B13) : const Color(0xFFFBF3DA),
    primary: dark ? const Color(0xFF9CCC65) : const Color(0xFF3F7A2A),
  );
  return ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    scaffoldBackgroundColor: scheme.surface,
    appBarTheme: AppBarTheme(
      backgroundColor: scheme.surface,
      foregroundColor: scheme.onSurface,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: false,
      titleTextStyle: TextStyle(
        color: scheme.onSurface,
        fontSize: 20,
        fontWeight: FontWeight.w800,
        letterSpacing: 0.2,
      ),
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: dark ? const Color(0xFF2A241A) : const Color(0xFFF3E5B8),
      indicatorColor: scheme.primary.withValues(alpha: 0.25),
      labelTextStyle: WidgetStateProperty.all(
        const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
      ),
    ),
    chipTheme: ChipThemeData(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: dark ? const Color(0xFF2A241A) : const Color(0xFFFFFBEB),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide.none,
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    ),
  );
}

/// Cartão "pergaminho" usado em todo o app.
BoxDecoration parchment(BuildContext context, {Color? accent, double radius = 20}) {
  final dark = Theme.of(context).brightness == Brightness.dark;
  return BoxDecoration(
    color: dark ? const Color(0xFF2A241A) : const Color(0xFFFFFBEB),
    borderRadius: BorderRadius.circular(radius),
    border: Border.all(
      color: (accent ?? (dark ? const Color(0xFF5D4E37) : const Color(0xFFD9C48F))).withValues(alpha: 0.9),
      width: 1.4,
    ),
    boxShadow: [
      BoxShadow(
        color: Colors.black.withValues(alpha: dark ? 0.35 : 0.08),
        blurRadius: 8,
        offset: const Offset(0, 3),
      ),
    ],
  );
}
