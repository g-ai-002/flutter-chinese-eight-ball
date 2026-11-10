import 'package:flutter/material.dart';

import '../utils/system_ui.dart';

export 'table_skin.dart';

/// 深绿台呢 + 黄铜点缀的视觉基调。
const Color appGreen = Color(0xFF14684E);
const Color appGold = Color(0xFFC9A961);
const Color appCream = Color(0xFFF6F0E2);
const Color appInk = Color(0xFF1D2A24);

ThemeData buildLightTheme({String? fontFamily}) {
  const scheme = ColorScheme.light(
    primary: Color(0xFF14684E),
    onPrimary: Color(0xFFF8F4E8),
    primaryContainer: Color(0xFFD5E8DF),
    onPrimaryContainer: Color(0xFF073527),
    secondary: Color(0xFF8A6A3B),
    onSecondary: Color(0xFFFFF8EA),
    surface: Color(0xFFFFFCF5),
    onSurface: Color(0xFF1E2A24),
    surfaceContainerHighest: Color(0xFFEDE6D6),
    onSurfaceVariant: Color(0xFF6F746B),
    outline: Color(0xFFDCD3BF),
    outlineVariant: Color(0xFFEAE2D0),
    error: Color(0xFFB3261E),
    surfaceTint: Colors.transparent,
    tertiary: Color(0xFFB08A57),
  );

  return _buildBase(
    colorScheme: scheme,
    scaffoldColor: const Color(0xFFF3ECDC),
    fontFamily: fontFamily,
  );
}

ThemeData buildDarkTheme({String? fontFamily}) {
  const scheme = ColorScheme.dark(
    primary: Color(0xFF6EC3A2),
    onPrimary: Color(0xFF06291D),
    primaryContainer: Color(0xFF14473A),
    onPrimaryContainer: Color(0xFFCBEBDB),
    secondary: Color(0xFFD6B77E),
    onSecondary: Color(0xFF3A2A10),
    surface: Color(0xFF1B211E),
    onSurface: Color(0xFFEAE5D8),
    surfaceContainerHighest: Color(0xFF262E29),
    onSurfaceVariant: Color(0xFFA3A99F),
    outline: Color(0xFF343D37),
    outlineVariant: Color(0xFF2A322C),
    error: Color(0xFFF2B8B5),
    onError: Color(0xFF3A0A08),
    surfaceTint: Colors.transparent,
    tertiary: Color(0xFFD6B77E),
  );

  return _buildBase(
    colorScheme: scheme,
    scaffoldColor: const Color(0xFF121614),
    fontFamily: fontFamily,
  );
}

ThemeData _buildBase({
  required ColorScheme colorScheme,
  required Color scaffoldColor,
  String? fontFamily,
}) {
  final base = ThemeData(
    useMaterial3: true,
    colorScheme: colorScheme,
    scaffoldBackgroundColor: scaffoldColor,
    fontFamily: fontFamily,
  );
  final textTheme = base.textTheme.apply(
    bodyColor: colorScheme.onSurface,
    displayColor: colorScheme.onSurface,
    fontFamily: fontFamily,
  );

  return base.copyWith(
    textTheme: textTheme.copyWith(
      headlineMedium: textTheme.headlineMedium?.copyWith(
        fontWeight: FontWeight.w700,
        letterSpacing: 3,
      ),
      titleLarge: textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
      titleMedium: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
      titleSmall: textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: Colors.transparent,
      foregroundColor: colorScheme.onSurface,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: true,
      surfaceTintColor: Colors.transparent,
      systemOverlayStyle: systemOverlayStyleFor(scaffoldColor),
      toolbarHeight: 52,
      titleTextStyle: TextStyle(
        fontSize: 17,
        fontWeight: FontWeight.w600,
        color: colorScheme.onSurface,
        fontFamily: fontFamily,
      ),
    ),
    cardTheme: CardThemeData(
      elevation: 0,
      color: colorScheme.surface,
      surfaceTintColor: Colors.transparent,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: colorScheme.outline.withValues(alpha: 0.7)),
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        elevation: 0,
        minimumSize: const Size(0, 46),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        textStyle: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, fontFamily: fontFamily),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        minimumSize: const Size(0, 46),
        side: BorderSide(color: colorScheme.outline),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        textStyle: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, fontFamily: fontFamily),
      ),
    ),
    chipTheme: ChipThemeData(
      showCheckmark: false,
      side: BorderSide(color: colorScheme.outline),
      shape: const StadiumBorder(),
      backgroundColor: colorScheme.surface,
      selectedColor: colorScheme.primaryContainer,
      labelStyle: TextStyle(fontSize: 13, color: colorScheme.onSurface, fontFamily: fontFamily),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
    ),
    sliderTheme: const SliderThemeData(
      trackHeight: 4,
      showValueIndicator: ShowValueIndicator.never,
    ),
    dividerTheme: DividerThemeData(
      color: colorScheme.outline.withValues(alpha: 0.6),
      thickness: 0.6,
      space: 1,
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: colorScheme.surface,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    ),
    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    ),
    splashFactory: InkSparkle.splashFactory,
  );
}
