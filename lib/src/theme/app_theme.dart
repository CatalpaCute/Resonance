import 'package:flutter/material.dart';

@immutable
class ReaderPalette extends ThemeExtension<ReaderPalette> {
  const ReaderPalette({
    required this.shellBackground,
    required this.surface,
    required this.softSurface,
    required this.border,
    required this.hover,
    required this.primarySoft,
    required this.secondaryText,
    required this.tertiaryText,
    required this.glowA,
    required this.glowB,
    required this.glowC,
    required this.shadow,
  });

  final Color shellBackground;
  final Color surface;
  final Color softSurface;
  final Color border;
  final Color hover;
  final Color primarySoft;
  final Color secondaryText;
  final Color tertiaryText;
  final Color glowA;
  final Color glowB;
  final Color glowC;
  final Color shadow;

  @override
  ReaderPalette copyWith({
    Color? shellBackground,
    Color? surface,
    Color? softSurface,
    Color? border,
    Color? hover,
    Color? primarySoft,
    Color? secondaryText,
    Color? tertiaryText,
    Color? glowA,
    Color? glowB,
    Color? glowC,
    Color? shadow,
  }) {
    return ReaderPalette(
      shellBackground: shellBackground ?? this.shellBackground,
      surface: surface ?? this.surface,
      softSurface: softSurface ?? this.softSurface,
      border: border ?? this.border,
      hover: hover ?? this.hover,
      primarySoft: primarySoft ?? this.primarySoft,
      secondaryText: secondaryText ?? this.secondaryText,
      tertiaryText: tertiaryText ?? this.tertiaryText,
      glowA: glowA ?? this.glowA,
      glowB: glowB ?? this.glowB,
      glowC: glowC ?? this.glowC,
      shadow: shadow ?? this.shadow,
    );
  }

  @override
  ThemeExtension<ReaderPalette> lerp(covariant ThemeExtension<ReaderPalette>? other, double t) {
    if (other is! ReaderPalette) {
      return this;
    }
    return ReaderPalette(
      shellBackground: Color.lerp(shellBackground, other.shellBackground, t) ?? shellBackground,
      surface: Color.lerp(surface, other.surface, t) ?? surface,
      softSurface: Color.lerp(softSurface, other.softSurface, t) ?? softSurface,
      border: Color.lerp(border, other.border, t) ?? border,
      hover: Color.lerp(hover, other.hover, t) ?? hover,
      primarySoft: Color.lerp(primarySoft, other.primarySoft, t) ?? primarySoft,
      secondaryText: Color.lerp(secondaryText, other.secondaryText, t) ?? secondaryText,
      tertiaryText: Color.lerp(tertiaryText, other.tertiaryText, t) ?? tertiaryText,
      glowA: Color.lerp(glowA, other.glowA, t) ?? glowA,
      glowB: Color.lerp(glowB, other.glowB, t) ?? glowB,
      glowC: Color.lerp(glowC, other.glowC, t) ?? glowC,
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
    const Color primary = Color(0xFF8B7355);
    const Color onPrimary = Colors.white;
    final ColorScheme scheme = ColorScheme.fromSeed(
      seedColor: primary,
      brightness: Brightness.light,
      primary: primary,
      onPrimary: onPrimary,
      surface: const Color(0xFFF9F6F0),
    );
    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: const Color(0xFFF0EEE9),
      textTheme: _baseTextTheme(const Color(0xFF2F2C27)),
      extensions: const <ThemeExtension<dynamic>>[
        ReaderPalette(
          shellBackground: Color(0xFFF0EEE9),
          surface: Color.fromRGBO(255, 255, 255, 0.72),
          softSurface: Color.fromRGBO(255, 255, 255, 0.90),
          border: Color.fromRGBO(70, 54, 30, 0.10),
          hover: Color.fromRGBO(70, 54, 30, 0.06),
          primarySoft: Color.fromRGBO(139, 115, 85, 0.12),
          secondaryText: Color(0xFF69655E),
          tertiaryText: Color(0xFF9B958D),
          glowA: Color.fromRGBO(139, 115, 85, 0.26),
          glowB: Color.fromRGBO(215, 197, 160, 0.28),
          glowC: Color.fromRGBO(255, 255, 255, 0.40),
          shadow: Color.fromRGBO(38, 31, 21, 0.10),
        ),
      ],
      cardTheme: const CardThemeData(
        color: Color.fromRGBO(255, 255, 255, 0.72),
        elevation: 0,
        margin: EdgeInsets.zero,
      ),
    );
  }

  static ThemeData _buildDeepTheme() {
    const Color primary = Color(0xFFC9A86C);
    final ColorScheme scheme = ColorScheme.fromSeed(
      seedColor: primary,
      brightness: Brightness.dark,
      primary: primary,
      onPrimary: const Color(0xFF111111),
      surface: const Color(0xFF211D19),
    );
    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: const Color(0xFF171412),
      textTheme: _baseTextTheme(const Color(0xFFF3EEDF)),
      extensions: const <ThemeExtension<dynamic>>[
        ReaderPalette(
          shellBackground: Color(0xFF171412),
          surface: Color.fromRGBO(40, 34, 28, 0.92),
          softSurface: Color.fromRGBO(49, 42, 34, 0.98),
          border: Color.fromRGBO(255, 255, 255, 0.08),
          hover: Color.fromRGBO(255, 255, 255, 0.05),
          primarySoft: Color.fromRGBO(201, 168, 108, 0.14),
          secondaryText: Color(0xFFC3B7A6),
          tertiaryText: Color(0xFF8B8378),
          glowA: Color.fromRGBO(201, 168, 108, 0.16),
          glowB: Color.fromRGBO(84, 69, 48, 0.40),
          glowC: Color.fromRGBO(255, 255, 255, 0.04),
          shadow: Color.fromRGBO(0, 0, 0, 0.36),
        ),
      ],
      cardTheme: const CardThemeData(
        color: Color.fromRGBO(40, 34, 28, 0.92),
        elevation: 0,
        margin: EdgeInsets.zero,
      ),
    );
  }

  static ThemeData _buildNeutralTheme() {
    const Color primary = Color(0xFF3F434A);
    final ColorScheme scheme = ColorScheme.fromSeed(
      seedColor: primary,
      brightness: Brightness.light,
      primary: primary,
      onPrimary: Colors.white,
      surface: const Color(0xFFF7F7F7),
    );
    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: const Color(0xFFF5F5F5),
      textTheme: _baseTextTheme(const Color(0xFF111317)),
      extensions: const <ThemeExtension<dynamic>>[
        ReaderPalette(
          shellBackground: Color(0xFFF5F5F5),
          surface: Color.fromRGBO(255, 255, 255, 0.90),
          softSurface: Color(0xFFFFFFFF),
          border: Color.fromRGBO(25, 32, 45, 0.08),
          hover: Color.fromRGBO(25, 32, 45, 0.04),
          primarySoft: Color.fromRGBO(63, 67, 74, 0.10),
          secondaryText: Color(0xFF5E646E),
          tertiaryText: Color(0xFF959DAA),
          glowA: Color.fromRGBO(214, 216, 220, 0.50),
          glowB: Color.fromRGBO(255, 255, 255, 0.40),
          glowC: Color.fromRGBO(221, 229, 238, 0.45),
          shadow: Color.fromRGBO(17, 19, 23, 0.08),
        ),
      ],
      cardTheme: const CardThemeData(
        color: Color.fromRGBO(255, 255, 255, 0.90),
        elevation: 0,
        margin: EdgeInsets.zero,
      ),
    );
  }

  static TextTheme _baseTextTheme(Color bodyColor) {
    final TextTheme base = Typography.blackMountainView;

    // 设计意图：为中文准备稳定的系统回退链，避免标题和正文命中不同字体导致粗细不一致。
    return base.copyWith(
      displayLarge: _decorateText(base.displayLarge, bodyColor),
      displayMedium: _decorateText(base.displayMedium, bodyColor),
      displaySmall: _decorateText(base.displaySmall, bodyColor),
      headlineLarge: _decorateText(base.headlineLarge, bodyColor),
      headlineMedium: _decorateText(base.headlineMedium, bodyColor),
      headlineSmall: _decorateText(base.headlineSmall, bodyColor, fontWeight: FontWeight.w700, height: 1.2),
      titleLarge: _decorateText(base.titleLarge, bodyColor, fontWeight: FontWeight.w700, height: 1.3),
      titleMedium: _decorateText(base.titleMedium, bodyColor, fontWeight: FontWeight.w600, height: 1.3),
      titleSmall: _decorateText(base.titleSmall, bodyColor, fontWeight: FontWeight.w600, height: 1.35),
      bodyLarge: _decorateText(base.bodyLarge, bodyColor, height: 1.6),
      bodyMedium: _decorateText(base.bodyMedium, bodyColor, height: 1.55),
      bodySmall: _decorateText(base.bodySmall, bodyColor, height: 1.45),
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
