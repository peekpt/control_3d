import 'package:flutter/material.dart';
import 'app_theme.dart';

class _Palette {
  const _Palette({
    required this.bg,
    required this.surface,
    required this.surface0,
    required this.surface1,
    required this.overlay,
    required this.muted,
    required this.fg,
    required this.blue,
    required this.cyan,
    required this.green,
    required this.orange,
    required this.purple,
    required this.red,
    required this.yellow,
    required this.teal,
  });

  final Color bg, surface, surface0, surface1;
  final Color overlay, muted, fg;
  final Color blue, cyan, green, orange, purple, red, yellow, teal;
}

const _dark = _Palette(
  bg: Color(0xFF1A1B26),
  surface: Color(0xFF24283B),
  surface0: Color(0xFF2F3346),
  surface1: Color(0xFF3B4261),
  overlay: Color(0xFF565F89),
  muted: Color(0xFF6C77A0),
  fg: Color(0xFFA9B1D6),
  blue: Color(0xFF7AA2F7),
  cyan: Color(0xFF7DCFFF),
  green: Color(0xFF9ECE6A),
  orange: Color(0xFFFF9E64),
  purple: Color(0xFFBB9AF7),
  red: Color(0xFFF7768E),
  yellow: Color(0xFFE0AF68),
  teal: Color(0xFF1ABC9C),
);

const _light = _Palette(
  bg: Color(0xFFE1E2E7),
  surface: Color(0xFFCBCCD1),
  surface0: Color(0xFFB6B8C4),
  surface1: Color(0xFFA1A6C5),
  overlay: Color(0xFF848CB5),
  muted: Color(0xFF6C7A96),
  fg: Color(0xFF3760BF),
  blue: Color(0xFF2E7DE9),
  cyan: Color(0xFF0DB9D7),
  green: Color(0xFF587539),
  orange: Color(0xFFB15C00),
  purple: Color(0xFF7847BD),
  red: Color(0xFFF52A65),
  yellow: Color(0xFF8C6C3E),
  teal: Color(0xFF1ABC9C),
);

ThemeData themeFromAppTheme(AppTheme theme) => switch (theme) {
      AppTheme.light => _buildTheme(_light, Brightness.light),
      AppTheme.dark || AppTheme.system => _buildTheme(_dark, Brightness.dark),
    };

ThemeData _buildTheme(_Palette p, Brightness brightness) {
  final isDark = brightness == Brightness.dark;

  final colorScheme = ColorScheme(
    brightness: brightness,
    primary: p.blue,
    onPrimary: isDark ? Colors.black : Colors.white,
    primaryContainer: p.blue.withValues(alpha: 0.2),
    onPrimaryContainer: p.blue,
    secondary: p.purple,
    onSecondary: isDark ? Colors.black : Colors.white,
    secondaryContainer: p.purple.withValues(alpha: 0.2),
    onSecondaryContainer: p.purple,
    tertiary: p.green,
    onTertiary: isDark ? Colors.black : Colors.white,
    error: p.red,
    onError: isDark ? Colors.black : Colors.white,
    errorContainer: p.red.withValues(alpha: 0.2),
    onErrorContainer: p.red,
    surface: p.surface,
    onSurface: p.fg,
    surfaceContainerHighest: p.surface0,
    onSurfaceVariant: p.muted,
    outline: p.overlay,
    outlineVariant: p.surface1,
    inversePrimary: p.blue,
    shadow: Colors.black,
  );

  return ThemeData(
    useMaterial3: true,
    colorScheme: colorScheme,
    scaffoldBackgroundColor: p.bg,
    appBarTheme: AppBarTheme(
      backgroundColor: p.bg,
      foregroundColor: p.fg,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
    ),
    cardTheme: CardThemeData(
      color: p.surface,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(color: p.surface1, width: 0.5),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: p.surface0,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(6),
        borderSide: BorderSide(color: p.surface1),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(6),
        borderSide: BorderSide(color: p.surface1),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(6),
        borderSide: BorderSide(color: p.blue, width: 1.5),
      ),
      labelStyle: TextStyle(color: p.muted),
      hintStyle: TextStyle(color: p.overlay),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: p.blue,
        foregroundColor: isDark ? Colors.black : Colors.white,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: p.blue,
        side: BorderSide(color: p.blue),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(foregroundColor: p.blue),
    ),
    sliderTheme: SliderThemeData(
      activeTrackColor: p.blue,
      inactiveTrackColor: p.surface1,
      thumbColor: p.blue,
      overlayColor: p.blue.withValues(alpha: 0.12),
      valueIndicatorColor: p.blue,
      valueIndicatorTextStyle: TextStyle(color: isDark ? Colors.black : Colors.white),
    ),
    chipTheme: ChipThemeData(
      backgroundColor: p.surface0,
      labelStyle: TextStyle(color: p.fg, fontSize: 12),
      side: BorderSide(color: p.surface1),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
    ),
    dividerTheme: DividerThemeData(color: p.surface1, thickness: 0.5),
    dividerColor: p.surface1,
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: p.bg,
      indicatorColor: p.blue.withValues(alpha: 0.2),
      labelTextStyle: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return TextStyle(color: p.blue, fontSize: 12);
        }
        return TextStyle(color: p.muted, fontSize: 12);
      }),
      iconTheme: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return IconThemeData(color: p.blue);
        }
        return IconThemeData(color: p.muted);
      }),
    ),
    textTheme: TextTheme(
      bodyLarge: TextStyle(color: p.fg),
      bodyMedium: TextStyle(color: p.fg),
      bodySmall: TextStyle(color: p.muted),
      labelLarge: TextStyle(color: p.muted),
      labelMedium: TextStyle(color: p.muted),
      titleLarge: TextStyle(color: p.blue, fontWeight: FontWeight.w600),
      titleMedium: TextStyle(color: p.fg, fontWeight: FontWeight.w600),
    ),
  );
}
