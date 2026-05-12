import 'package:flutter/material.dart';

/// Matches `etrade-next/src/app/globals.css` TradeHub shell (dark + indigo + sky).
abstract final class TradeHubColors {
  static const Color bg = Color(0xFF0B1020);
  static const Color surface = Color(0xFF121A33);
  static const Color surface2 = Color(0xFF1E293B);
  static const Color panel = Color(0xFF273549);
  static const Color outline = Color(0x26FFFFFF);
  static const Color textPrimary = Color(0xFFE8ECFF);
  static const Color textMuted = Color(0xFF94A3B8);
  static const Color primary = Color(0xFF818CF8);
  static const Color primaryDeep = Color(0xFF6366F1);
  static const Color accent = Color(0xFF38BDF8);
  static const Color success = Color(0xFF34D399);
  static const Color danger = Color(0xFFF87171);
  static const Color warning = Color(0xFFFBBF24);
}

ThemeData buildTradeHubTheme() {
  final base = ColorScheme.dark(
    brightness: Brightness.dark,
    primary: TradeHubColors.primary,
    onPrimary: Color(0xFF0B1020),
    secondary: TradeHubColors.accent,
    onSecondary: Color(0xFF0B1020),
    surface: TradeHubColors.surface2,
    onSurface: TradeHubColors.textPrimary,
    outline: TradeHubColors.outline,
    error: TradeHubColors.danger,
  );

  return ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    colorScheme: base,
    scaffoldBackgroundColor: TradeHubColors.bg,
    appBarTheme: const AppBarTheme(
      backgroundColor: TradeHubColors.bg,
      foregroundColor: TradeHubColors.textPrimary,
      elevation: 0,
      scrolledUnderElevation: 0,
      surfaceTintColor: Colors.transparent,
      shadowColor: Colors.transparent,
    ),
    cardTheme: CardThemeData(
      color: TradeHubColors.surface2,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.white.withValues(alpha: 0.08)),
      ),
    ),
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: TradeHubColors.surface,
      selectedItemColor: TradeHubColors.primary,
      unselectedItemColor: TradeHubColors.textMuted,
      type: BottomNavigationBarType.fixed,
      elevation: 12,
      showUnselectedLabels: true,
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: TradeHubColors.surface,
      indicatorColor: TradeHubColors.primary.withValues(alpha: 0.28),
      labelTextStyle: WidgetStateProperty.resolveWith((s) {
        final selected = s.contains(WidgetState.selected);
        return TextStyle(
          fontSize: 12,
          fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
          color: selected ? TradeHubColors.primary : TradeHubColors.textMuted,
        );
      }),
      iconTheme: WidgetStateProperty.resolveWith((s) {
        final selected = s.contains(WidgetState.selected);
        return IconThemeData(
          color: selected ? TradeHubColors.primary : TradeHubColors.textMuted,
          size: 24,
        );
      }),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: TradeHubColors.surface2,
      hintStyle: const TextStyle(color: TradeHubColors.textMuted),
      labelStyle: const TextStyle(color: TradeHubColors.textMuted),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.12)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.12)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: TradeHubColors.accent, width: 1.5),
      ),
    ),
    chipTheme: ChipThemeData(
      backgroundColor: TradeHubColors.surface2,
      selectedColor: TradeHubColors.primary.withValues(alpha: 0.35),
      disabledColor: TradeHubColors.surface2,
      labelStyle: const TextStyle(color: TradeHubColors.textPrimary, fontSize: 13),
      secondaryLabelStyle: const TextStyle(color: TradeHubColors.textMuted),
      padding: const EdgeInsets.symmetric(horizontal: 4),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.white.withValues(alpha: 0.08)),
      ),
      showCheckmark: false,
    ),
    dividerTheme: DividerThemeData(color: Colors.white.withValues(alpha: 0.08)),
    iconTheme: const IconThemeData(color: TradeHubColors.textMuted),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: TradeHubColors.primaryDeep,
        foregroundColor: Colors.white,
        elevation: 0,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: TradeHubColors.textPrimary,
        side: BorderSide(color: Colors.white.withValues(alpha: 0.2)),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: TradeHubColors.accent,
        foregroundColor: Color(0xFF0B1020),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
    ),
    floatingActionButtonTheme: const FloatingActionButtonThemeData(
      backgroundColor: TradeHubColors.primary,
      foregroundColor: Colors.white,
    ),
    progressIndicatorTheme: const ProgressIndicatorThemeData(
      color: TradeHubColors.accent,
    ),
    snackBarTheme: SnackBarThemeData(
      backgroundColor: TradeHubColors.surface2,
      contentTextStyle: const TextStyle(color: TradeHubColors.textPrimary),
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
    ),
  );
}
