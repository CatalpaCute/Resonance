import 'package:flutter/material.dart';

@immutable
class ReaderPalette extends ThemeExtension<ReaderPalette> {
  const ReaderPalette({
    required this.shellBackground,
    required this.chromeBackground,
    required this.sidebarBackground,
    required this.canvasBackground,
    required this.panelBackground,
    required this.panelMutedBackground,
    required this.border,
    required this.divider,
    required this.hover,
    required this.primarySoft,
    required this.secondaryText,
    required this.tertiaryText,
    required this.shadow,
  });

  final Color shellBackground;
  final Color chromeBackground;
  final Color sidebarBackground;
  final Color canvasBackground;
  final Color panelBackground;
  final Color panelMutedBackground;
  final Color border;
  final Color divider;
  final Color hover;
  final Color primarySoft;
  final Color secondaryText;
  final Color tertiaryText;
  final Color shadow;

  @override
  ReaderPalette copyWith({
    Color? shellBackground,
    Color? chromeBackground,
    Color? sidebarBackground,
    Color? canvasBackground,
    Color? panelBackground,
    Color? panelMutedBackground,
    Color? border,
    Color? divider,
    Color? hover,
    Color? primarySoft,
    Color? secondaryText,
    Color? tertiaryText,
    Color? shadow,
  }) {
    return ReaderPalette(
      shellBackground: shellBackground ?? this.shellBackground,
      chromeBackground: chromeBackground ?? this.chromeBackground,
      sidebarBackground: sidebarBackground ?? this.sidebarBackground,
      canvasBackground: canvasBackground ?? this.canvasBackground,
      panelBackground: panelBackground ?? this.panelBackground,
      panelMutedBackground: panelMutedBackground ?? this.panelMutedBackground,
      border: border ?? this.border,
      divider: divider ?? this.divider,
      hover: hover ?? this.hover,
      primarySoft: primarySoft ?? this.primarySoft,
      secondaryText: secondaryText ?? this.secondaryText,
      tertiaryText: tertiaryText ?? this.tertiaryText,
      shadow: shadow ?? this.shadow,
    );
  }

  @override
  ThemeExtension<ReaderPalette> lerp(
    covariant ThemeExtension<ReaderPalette>? other,
    double t,
  ) {
    if (other is! ReaderPalette) {
      return this;
    }
    return ReaderPalette(
      shellBackground: Color.lerp(shellBackground, other.shellBackground, t) ?? shellBackground,
      chromeBackground: Color.lerp(chromeBackground, other.chromeBackground, t) ?? chromeBackground,
      sidebarBackground: Color.lerp(sidebarBackground, other.sidebarBackground, t) ?? sidebarBackground,
      canvasBackground: Color.lerp(canvasBackground, other.canvasBackground, t) ?? canvasBackground,
      panelBackground: Color.lerp(panelBackground, other.panelBackground, t) ?? panelBackground,
      panelMutedBackground: Color.lerp(panelMutedBackground, other.panelMutedBackground, t) ?? panelMutedBackground,
      border: Color.lerp(border, other.border, t) ?? border,
      divider: Color.lerp(divider, other.divider, t) ?? divider,
      hover: Color.lerp(hover, other.hover, t) ?? hover,
      primarySoft: Color.lerp(primarySoft, other.primarySoft, t) ?? primarySoft,
      secondaryText: Color.lerp(secondaryText, other.secondaryText, t) ?? secondaryText,
      tertiaryText: Color.lerp(tertiaryText, other.tertiaryText, t) ?? tertiaryText,
      shadow: Color.lerp(shadow, other.shadow, t) ?? shadow,
    );
  }
}

class AppTheme {
  static const List<String> themeIds = <String>[
    'warm_default',
    'deep_default',
    'neutral_minimal',
  ];

  static const List<String> _fontFallback = <String>[
    'Microsoft YaHei UI',
    'Microsoft YaHei',
    'PingFang SC',
    'Hiragino Sans GB',
    'HarmonyOS Sans SC',
    'Noto Sans CJK SC',
    'Source Han Sans SC',
    'Segoe UI Symbol',
    'Segoe UI',
  ];

  static String displayName(String id) {
    switch (id) {
      case 'warm_default':
        return '暖灰默认';
      case 'deep_default':
        return '深色默认';
      case 'neutral_minimal':
        return '极简中性';
      default:
        return '暖灰默认';
    }
  }

  static ThemeData themeFor(String id) {
    switch (id) {
      case 'deep_default':
        return _buildDeepTheme();
      case 'neutral_minimal':
        return _buildNeutralTheme();
      case 'warm_default':
      default:
        return _buildWarmTheme();
    }
  }

  static ReaderPalette paletteOf(BuildContext context) {
    return Theme.of(context).extension<ReaderPalette>()!;
  }

  static ThemeData _buildWarmTheme() {
    const Color primary = Color(0xFFA58D71);
    final ColorScheme scheme = ColorScheme.fromSeed(
      seedColor: primary,
      brightness: Brightness.light,
      primary: primary,
      onPrimary: Colors.white,
      surface: const Color(0xFFFBF8F2),
    );
    return _buildTheme(
      scheme: scheme,
      scaffoldBackground: const Color(0xFFF7F4EE),
      bodyColor: const Color(0xFF40372E),
      palette: const ReaderPalette(
        shellBackground: Color(0xFFF7F4EE),
        chromeBackground: Color(0xFFFDFBF8),
        sidebarBackground: Color(0xFFFDFBF8),
        canvasBackground: Color(0xFFF7F3EB),
        panelBackground: Color(0xFFFFFDFC),
        panelMutedBackground: Color(0xFFF6F1E8),
        border: Color(0xFFE6DED2),
        divider: Color(0xFFEEE7DB),
        hover: Color(0xFFF2ECE2),
        primarySoft: Color(0xFFF1E8DB),
        secondaryText: Color(0xFF8A8074),
        tertiaryText: Color(0xFFB0A597),
        shadow: Color.fromRGBO(93, 74, 48, 0.05),
      ),
    );
  }

  static ThemeData _buildDeepTheme() {
    const Color primary = Color(0xFFD0B18A);
    final ColorScheme scheme = ColorScheme.fromSeed(
      seedColor: primary,
      brightness: Brightness.dark,
      primary: primary,
      onPrimary: const Color(0xFF201A14),
      surface: const Color(0xFF211C17),
    );
    return _buildTheme(
      scheme: scheme,
      scaffoldBackground: const Color(0xFF181411),
      bodyColor: const Color(0xFFF1E8D9),
      palette: const ReaderPalette(
        shellBackground: Color(0xFF181411),
        chromeBackground: Color(0xFF1E1915),
        sidebarBackground: Color(0xFF1D1814),
        canvasBackground: Color(0xFF201A16),
        panelBackground: Color(0xFF26201B),
        panelMutedBackground: Color(0xFF2B241E),
        border: Color(0xFF393026),
        divider: Color(0xFF312921),
        hover: Color(0xFF2D261F),
        primarySoft: Color.fromRGBO(208, 177, 138, 0.14),
        secondaryText: Color(0xFFC0B19D),
        tertiaryText: Color(0xFF8E8376),
        shadow: Color.fromRGBO(0, 0, 0, 0.18),
      ),
    );
  }

  static ThemeData _buildNeutralTheme() {
    const Color primary = Color(0xFF4A5056);
    final ColorScheme scheme = ColorScheme.fromSeed(
      seedColor: primary,
      brightness: Brightness.light,
      primary: primary,
      onPrimary: Colors.white,
      surface: const Color(0xFFF9F9F8),
    );
    return _buildTheme(
      scheme: scheme,
      scaffoldBackground: const Color(0xFFF3F3F1),
      bodyColor: const Color(0xFF1C2126),
      palette: const ReaderPalette(
        shellBackground: Color(0xFFF3F3F1),
        chromeBackground: Color(0xFFFFFFFF),
        sidebarBackground: Color(0xFFFFFFFF),
        canvasBackground: Color(0xFFF7F7F5),
        panelBackground: Color(0xFFFFFFFF),
        panelMutedBackground: Color(0xFFF2F2F0),
        border: Color(0xFFE2E5E7),
        divider: Color(0xFFECEEED),
        hover: Color(0xFFF2F4F5),
        primarySoft: Color.fromRGBO(74, 80, 86, 0.10),
        secondaryText: Color(0xFF69717A),
        tertiaryText: Color(0xFF9AA2AB),
        shadow: Color.fromRGBO(25, 32, 40, 0.04),
      ),
    );
  }

  static ThemeData _buildTheme({
    required ColorScheme scheme,
    required Color scaffoldBackground,
    required Color bodyColor,
    required ReaderPalette palette,
  }) {
    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: scaffoldBackground,
      textTheme: _baseTextTheme(bodyColor),
      extensions: <ThemeExtension<dynamic>>[palette],
      dividerColor: palette.divider,
      cardTheme: CardThemeData(
        color: palette.panelBackground,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: palette.border),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: palette.panelBackground,
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: palette.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: palette.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: scheme.primary.withValues(alpha: 0.45)),
        ),
        labelStyle: TextStyle(color: palette.secondaryText),
        hintStyle: TextStyle(color: palette.tertiaryText),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: scheme.primary,
          foregroundColor: scheme.onPrimary,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          textStyle: const TextStyle(fontWeight: FontWeight.w600),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: bodyColor,
          side: BorderSide(color: palette.border),
          padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 13),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: palette.panelBackground,
        selectedColor: palette.primarySoft,
        disabledColor: palette.panelMutedBackground,
        side: BorderSide(color: palette.border),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        labelStyle: TextStyle(color: bodyColor),
        secondaryLabelStyle: TextStyle(color: scheme.primary),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      ),
    );
  }

  static TextTheme _baseTextTheme(Color bodyColor) {
    final TextTheme base = Typography.blackMountainView;
    return base.copyWith(
      displayLarge: _decorateText(base.displayLarge, bodyColor),
      displayMedium: _decorateText(base.displayMedium, bodyColor),
      displaySmall: _decorateText(base.displaySmall, bodyColor),
      headlineLarge: _decorateText(base.headlineLarge, bodyColor),
      headlineMedium: _decorateText(base.headlineMedium, bodyColor),
      headlineSmall: _decorateText(base.headlineSmall, bodyColor, fontWeight: FontWeight.w700, height: 1.18),
      titleLarge: _decorateText(base.titleLarge, bodyColor, fontWeight: FontWeight.w700, height: 1.24),
      titleMedium: _decorateText(base.titleMedium, bodyColor, fontWeight: FontWeight.w600, height: 1.28),
      titleSmall: _decorateText(base.titleSmall, bodyColor, fontWeight: FontWeight.w600, height: 1.32),
      bodyLarge: _decorateText(base.bodyLarge, bodyColor, height: 1.55),
      bodyMedium: _decorateText(base.bodyMedium, bodyColor, height: 1.50),
      bodySmall: _decorateText(base.bodySmall, bodyColor, height: 1.40),
      labelLarge: _decorateText(base.labelLarge, bodyColor, fontWeight: FontWeight.w600),
      labelMedium: _decorateText(base.labelMedium, bodyColor, fontWeight: FontWeight.w500),
      labelSmall: _decorateText(base.labelSmall, bodyColor, fontWeight: FontWeight.w500),
    );
  }

  static TextStyle? _decorateText(
    TextStyle? base,
    Color color, {
    FontWeight? fontWeight,
    double? height,
  }) {
    if (base == null) {
      return null;
    }

    return base.copyWith(
      color: color,
      fontWeight: fontWeight ?? base.fontWeight,
      height: height ?? base.height,
      fontFamilyFallback: _fontFallback,
    );
  }
}
