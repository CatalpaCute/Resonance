import 'package:flutter/material.dart';

import '../models/reader_settings.dart';

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
    required this.linkText,
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
  final Color linkText;
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
    Color? linkText,
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
      linkText: linkText ?? this.linkText,
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
      shellBackground: Color.lerp(shellBackground, other.shellBackground, t) ??
          shellBackground,
      chromeBackground:
          Color.lerp(chromeBackground, other.chromeBackground, t) ??
              chromeBackground,
      sidebarBackground:
          Color.lerp(sidebarBackground, other.sidebarBackground, t) ??
              sidebarBackground,
      canvasBackground:
          Color.lerp(canvasBackground, other.canvasBackground, t) ??
              canvasBackground,
      panelBackground: Color.lerp(panelBackground, other.panelBackground, t) ??
          panelBackground,
      panelMutedBackground:
          Color.lerp(panelMutedBackground, other.panelMutedBackground, t) ??
              panelMutedBackground,
      border: Color.lerp(border, other.border, t) ?? border,
      divider: Color.lerp(divider, other.divider, t) ?? divider,
      hover: Color.lerp(hover, other.hover, t) ?? hover,
      primarySoft: Color.lerp(primarySoft, other.primarySoft, t) ?? primarySoft,
      linkText: Color.lerp(linkText, other.linkText, t) ?? linkText,
      secondaryText:
          Color.lerp(secondaryText, other.secondaryText, t) ?? secondaryText,
      tertiaryText:
          Color.lerp(tertiaryText, other.tertiaryText, t) ?? tertiaryText,
      shadow: Color.lerp(shadow, other.shadow, t) ?? shadow,
    );
  }
}

class AppTheme {
  static final Map<String, ThemeData> _themeCache = <String, ThemeData>{};

  static const List<String> themeIds = <String>[
    'warm_default',
    'deep_default',
    'neutral_minimal',
    'material_you_light',
    'wechat_green',
    'ink_black_white',
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
        return 'Warm Default';
      case 'deep_default':
        return 'Deep Default';
      case 'neutral_minimal':
        return 'Neutral Minimal';
      case 'material_you_light':
        return 'Material You';
      case 'wechat_green':
        return 'WeChat Green';
      case 'ink_black_white':
        return 'Ink Black & White';
      default:
        return 'Warm Default';
    }
  }

  static ThemeMode themeModeFor(AppearanceMode mode) {
    switch (mode) {
      case AppearanceMode.light:
        return ThemeMode.light;
      case AppearanceMode.dark:
        return ThemeMode.dark;
      case AppearanceMode.system:
        return ThemeMode.system;
    }
  }

  static Brightness resolveBrightness(
    AppearanceMode mode,
    Brightness systemBrightness,
  ) {
    switch (mode) {
      case AppearanceMode.light:
        return Brightness.light;
      case AppearanceMode.dark:
        return Brightness.dark;
      case AppearanceMode.system:
        return systemBrightness;
    }
  }

  static ThemeData themeFor(
    String id, {
    required Brightness brightness,
    ColorScheme? materialYouLightColorScheme,
    ColorScheme? materialYouDarkColorScheme,
  }) {
    if (id == 'material_you_light') {
      final ColorScheme? dynamicScheme = brightness == Brightness.dark
          ? materialYouDarkColorScheme
          : materialYouLightColorScheme;
      return _buildMaterialYouTheme(brightness, dynamicScheme);
    }

    final String cacheKey = '$id:${brightness.name}';
    return _themeCache.putIfAbsent(cacheKey, () {
      switch (id) {
        case 'deep_default':
          return _buildDeepTheme(brightness);
        case 'neutral_minimal':
          return _buildNeutralTheme(brightness);
        case 'wechat_green':
          return _buildWechatGreenTheme(brightness);
        case 'ink_black_white':
          return _buildInkBlackWhiteTheme(brightness);
        case 'warm_default':
        default:
          return _buildWarmTheme(brightness);
      }
    });
  }

  static ReaderPalette paletteOf(BuildContext context) {
    return Theme.of(context).extension<ReaderPalette>()!;
  }

  static ThemeData _buildWarmTheme(Brightness brightness) {
    const Color primary = Color(0xFFA58D71);
    if (brightness == Brightness.dark) {
      final ColorScheme scheme = ColorScheme.fromSeed(
        seedColor: primary,
        brightness: Brightness.dark,
        primary: const Color(0xFFD1B89B),
        onPrimary: const Color(0xFF2F2418),
        surface: const Color(0xFF1D1814),
      );
      return _buildTheme(
        scheme: scheme,
        scaffoldBackground: const Color(0xFF171310),
        bodyColor: const Color(0xFFF2E7DB),
        palette: const ReaderPalette(
          shellBackground: Color(0xFF171310),
          chromeBackground: Color(0xFF1D1814),
          sidebarBackground: Color(0xFF1C1713),
          canvasBackground: Color(0xFF201A16),
          panelBackground: Color(0xFF26201B),
          panelMutedBackground: Color(0xFF2E2721),
          border: Color(0xFF43382D),
          divider: Color(0xFF382F26),
          hover: Color(0xFF312922),
          primarySoft: Color.fromRGBO(209, 184, 155, 0.16),
          linkText: Color(0xFFE1C8AA),
          secondaryText: Color(0xFFC8B39B),
          tertiaryText: Color(0xFF988674),
          shadow: Color.fromRGBO(0, 0, 0, 0.22),
        ),
      );
    }

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
        linkText: Color(0xFF8F7658),
        secondaryText: Color(0xFF8A8074),
        tertiaryText: Color(0xFFB0A597),
        shadow: Color.fromRGBO(93, 74, 48, 0.05),
      ),
    );
  }

  static ThemeData _buildDeepTheme(Brightness brightness) {
    const Color primary = Color(0xFFD0B18A);
    if (brightness == Brightness.light) {
      final ColorScheme scheme = ColorScheme.fromSeed(
        seedColor: primary,
        brightness: Brightness.light,
        primary: const Color(0xFFA9855D),
        onPrimary: Colors.white,
        surface: const Color(0xFFF8F1E8),
      );
      return _buildTheme(
        scheme: scheme,
        scaffoldBackground: const Color(0xFFF3ECE3),
        bodyColor: const Color(0xFF33281D),
        palette: const ReaderPalette(
          shellBackground: Color(0xFFF3ECE3),
          chromeBackground: Color(0xFFFAF5EF),
          sidebarBackground: Color(0xFFFAF5EF),
          canvasBackground: Color(0xFFF6EFE5),
          panelBackground: Color(0xFFFFFBF7),
          panelMutedBackground: Color(0xFFF3E8DA),
          border: Color(0xFFE5D5C3),
          divider: Color(0xFFECDDCD),
          hover: Color(0xFFF1E4D5),
          primarySoft: Color(0xFFF0E0CE),
          linkText: Color(0xFF8F6540),
          secondaryText: Color(0xFF8B7561),
          tertiaryText: Color(0xFFB29D89),
          shadow: Color.fromRGBO(78, 52, 25, 0.06),
        ),
      );
    }

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
        linkText: Color(0xFFE0C49A),
        secondaryText: Color(0xFFC0B19D),
        tertiaryText: Color(0xFF8E8376),
        shadow: Color.fromRGBO(0, 0, 0, 0.18),
      ),
    );
  }

  static ThemeData _buildNeutralTheme(Brightness brightness) {
    const Color primary = Color(0xFF4A5056);
    if (brightness == Brightness.dark) {
      final ColorScheme scheme = ColorScheme.fromSeed(
        seedColor: primary,
        brightness: Brightness.dark,
        primary: const Color(0xFFBAC1C8),
        onPrimary: const Color(0xFF1A2025),
        surface: const Color(0xFF191C1F),
      );
      return _buildTheme(
        scheme: scheme,
        scaffoldBackground: const Color(0xFF14171A),
        bodyColor: const Color(0xFFE9EDF0),
        palette: const ReaderPalette(
          shellBackground: Color(0xFF14171A),
          chromeBackground: Color(0xFF1A1E22),
          sidebarBackground: Color(0xFF181C20),
          canvasBackground: Color(0xFF1D2126),
          panelBackground: Color(0xFF22272C),
          panelMutedBackground: Color(0xFF292E34),
          border: Color(0xFF363D45),
          divider: Color(0xFF30363D),
          hover: Color(0xFF2B3138),
          primarySoft: Color.fromRGBO(186, 193, 200, 0.14),
          linkText: Color(0xFFD1D7DD),
          secondaryText: Color(0xFFB0B8C0),
          tertiaryText: Color(0xFF818A93),
          shadow: Color.fromRGBO(0, 0, 0, 0.18),
        ),
      );
    }

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
        linkText: Color(0xFF3F4850),
        secondaryText: Color(0xFF69717A),
        tertiaryText: Color(0xFF9AA2AB),
        shadow: Color.fromRGBO(25, 32, 40, 0.04),
      ),
    );
  }

  static ThemeData _buildWechatGreenTheme(Brightness brightness) {
    const Color primary = Color(0xFF07C160);
    if (brightness == Brightness.dark) {
      final ColorScheme scheme = ColorScheme.fromSeed(
        seedColor: primary,
        brightness: Brightness.dark,
        primary: const Color(0xFF3BE38E),
        onPrimary: const Color(0xFF032411),
        surface: const Color(0xFF101613),
      );
      return _buildTheme(
        scheme: scheme,
        scaffoldBackground: const Color(0xFF0C110F),
        bodyColor: const Color(0xFFE5F7EC),
        palette: const ReaderPalette(
          shellBackground: Color(0xFF0C110F),
          chromeBackground: Color(0xFF101613),
          sidebarBackground: Color(0xFF101613),
          canvasBackground: Color(0xFF121A16),
          panelBackground: Color(0xFF16201A),
          panelMutedBackground: Color(0xFF1A261F),
          border: Color(0xFF24352B),
          divider: Color(0xFF223128),
          hover: Color(0xFF1D2B23),
          primarySoft: Color.fromRGBO(59, 227, 142, 0.16),
          linkText: Color(0xFF6DF0AC),
          secondaryText: Color(0xFFA9D2B8),
          tertiaryText: Color(0xFF729A80),
          shadow: Color.fromRGBO(0, 0, 0, 0.16),
        ),
      );
    }

    final ColorScheme scheme = ColorScheme.fromSeed(
      seedColor: primary,
      brightness: Brightness.light,
      primary: primary,
      onPrimary: Colors.white,
      surface: Colors.white,
    );
    return _buildTheme(
      scheme: scheme,
      scaffoldBackground: const Color(0xFFF7F7F7),
      bodyColor: const Color(0xFF1A1A1A),
      palette: const ReaderPalette(
        shellBackground: Color(0xFFF7F7F7),
        chromeBackground: Color(0xFFFFFFFF),
        sidebarBackground: Color(0xFFFFFFFF),
        canvasBackground: Color(0xFFF7F7F7),
        panelBackground: Color(0xFFFFFFFF),
        panelMutedBackground: Color(0xFFF7F7F7),
        border: Color(0xFFEDEDED),
        divider: Color(0xFFEDEDED),
        hover: Color(0xFFF2F2F2),
        primarySoft: Color.fromRGBO(7, 193, 96, 0.10),
        linkText: Color(0xFF047A3D),
        secondaryText: Color(0xFF7F7F7F),
        tertiaryText: Color(0xFFA6A6A6),
        shadow: Color.fromRGBO(0, 0, 0, 0.04),
      ),
    );
  }

  static ThemeData _buildMaterialYouTheme(
    Brightness brightness, [
    ColorScheme? dynamicScheme,
  ]) {
    const Color primary = Color(0xFF6750A4);
    final ColorScheme fallbackScheme = ColorScheme.fromSeed(
      seedColor: primary,
      brightness: brightness,
      primary:
          brightness == Brightness.dark ? const Color(0xFFD0BCFF) : primary,
      onPrimary: brightness == Brightness.dark
          ? const Color(0xFF381E72)
          : Colors.white,
      primaryContainer: brightness == Brightness.dark
          ? const Color(0xFF4F378B)
          : const Color(0xFFEADDFF),
      onPrimaryContainer: brightness == Brightness.dark
          ? const Color(0xFFEADDFF)
          : const Color(0xFF21005D),
      surface: brightness == Brightness.dark
          ? const Color(0xFF141218)
          : const Color(0xFFFFFBFE),
      surfaceContainerLowest: brightness == Brightness.dark
          ? const Color(0xFF0F0D13)
          : const Color(0xFFFFFFFF),
      surfaceContainerLow: brightness == Brightness.dark
          ? const Color(0xFF1D1B20)
          : const Color(0xFFF7F2FA),
      surfaceContainer: brightness == Brightness.dark
          ? const Color(0xFF211F26)
          : const Color(0xFFF3EDF7),
      surfaceContainerHigh: brightness == Brightness.dark
          ? const Color(0xFF2B2930)
          : const Color(0xFFECE6F0),
      surfaceContainerHighest: brightness == Brightness.dark
          ? const Color(0xFF36343B)
          : const Color(0xFFE6E0E9),
    );
    final ColorScheme scheme = dynamicScheme ?? fallbackScheme;
    return _buildTheme(
      scheme: scheme,
      scaffoldBackground: scheme.surface,
      bodyColor: scheme.onSurface,
      palette: ReaderPalette(
        shellBackground: scheme.surface,
        chromeBackground: scheme.surface,
        sidebarBackground: scheme.surface,
        canvasBackground: scheme.surfaceContainerLow,
        panelBackground: scheme.surfaceContainerLowest,
        panelMutedBackground: scheme.surfaceContainer,
        border: scheme.outlineVariant,
        divider: scheme.outlineVariant,
        hover: scheme.surfaceContainerHigh,
        primarySoft: scheme.primaryContainer,
        linkText: scheme.primary,
        secondaryText: scheme.onSurfaceVariant,
        tertiaryText: scheme.outline,
        shadow: scheme.shadow.withValues(alpha: 0.08),
      ),
    );
  }

  static ThemeData _buildInkBlackWhiteTheme(Brightness brightness) {
    final ColorScheme scheme = brightness == Brightness.dark
        ? const ColorScheme(
            brightness: Brightness.dark,
            primary: Colors.white,
            onPrimary: Colors.black,
            secondary: Colors.white,
            onSecondary: Colors.black,
            tertiary: Colors.white,
            onTertiary: Colors.black,
            primaryContainer: Color(0xFF3A3A3A),
            onPrimaryContainer: Colors.white,
            primaryFixed: Color(0xFF4A4A4A),
            primaryFixedDim: Color(0xFF3A3A3A),
            onPrimaryFixed: Colors.white,
            onPrimaryFixedVariant: Colors.white,
            secondaryContainer: Color(0xFF3A3A3A),
            onSecondaryContainer: Colors.white,
            secondaryFixed: Color(0xFF4A4A4A),
            secondaryFixedDim: Color(0xFF3A3A3A),
            onSecondaryFixed: Colors.white,
            onSecondaryFixedVariant: Colors.white,
            tertiaryContainer: Color(0xFF303030),
            onTertiaryContainer: Colors.white,
            tertiaryFixed: Color(0xFF4A4A4A),
            tertiaryFixedDim: Color(0xFF3A3A3A),
            onTertiaryFixed: Colors.white,
            onTertiaryFixedVariant: Colors.white,
            surface: Color(0xFF111111),
            onSurface: Colors.white,
            surfaceDim: Color(0xFF111111),
            surfaceBright: Color(0xFF1A1A1A),
            surfaceContainerLowest: Color(0xFF0D0D0D),
            surfaceContainerLow: Color(0xFF151515),
            surfaceContainer: Color(0xFF1C1C1C),
            surfaceContainerHigh: Color(0xFF242424),
            surfaceContainerHighest: Color(0xFF2C2C2C),
            onSurfaceVariant: Colors.white,
            outline: Color(0xFF8A8A8A),
            outlineVariant: Color(0xFF5F5F5F),
            shadow: Colors.transparent,
            scrim: Colors.black,
            inverseSurface: Colors.white,
            onInverseSurface: Colors.black,
            inversePrimary: Colors.black,
            surfaceTint: Colors.transparent,
            error: Colors.white,
            onError: Colors.black,
            errorContainer: Color(0xFF3A3A3A),
            onErrorContainer: Colors.white,
          )
        : const ColorScheme(
            brightness: Brightness.light,
            primary: Colors.black,
            onPrimary: Colors.white,
            secondary: Colors.black,
            onSecondary: Colors.white,
            tertiary: Colors.black,
            onTertiary: Colors.white,
            primaryContainer: Color(0xFFC2C2C2),
            onPrimaryContainer: Colors.black,
            primaryFixed: Color(0xFFD9D9D9),
            primaryFixedDim: Color(0xFFC2C2C2),
            onPrimaryFixed: Colors.black,
            onPrimaryFixedVariant: Colors.black,
            secondaryContainer: Color(0xFFD9D9D9),
            onSecondaryContainer: Colors.black,
            secondaryFixed: Color(0xFFD9D9D9),
            secondaryFixedDim: Color(0xFFC2C2C2),
            onSecondaryFixed: Colors.black,
            onSecondaryFixedVariant: Colors.black,
            tertiaryContainer: Color(0xFFE0E0E0),
            onTertiaryContainer: Colors.black,
            tertiaryFixed: Color(0xFFD9D9D9),
            tertiaryFixedDim: Color(0xFFC2C2C2),
            onTertiaryFixed: Colors.black,
            onTertiaryFixedVariant: Colors.black,
            surface: Colors.white,
            onSurface: Colors.black,
            surfaceDim: Color(0xFFE0E0E0),
            surfaceBright: Colors.white,
            surfaceContainerLowest: Colors.white,
            surfaceContainerLow: Colors.white,
            surfaceContainer: Colors.white,
            surfaceContainerHigh: Color(0xFFF2F2F2),
            surfaceContainerHighest: Color(0xFFE0E0E0),
            onSurfaceVariant: Colors.black,
            outline: Color(0xFF5F5F5F),
            outlineVariant: Color(0xFF8A8A8A),
            shadow: Colors.transparent,
            scrim: Colors.black,
            inverseSurface: Colors.black,
            onInverseSurface: Colors.white,
            inversePrimary: Colors.white,
            surfaceTint: Colors.transparent,
            error: Colors.black,
            onError: Colors.white,
            errorContainer: Color(0xFFE0E0E0),
            onErrorContainer: Colors.black,
          );
    return _buildTheme(
      scheme: scheme,
      scaffoldBackground: brightness == Brightness.dark
          ? const Color(0xFF111111)
          : Colors.white,
      bodyColor: brightness == Brightness.dark ? Colors.white : Colors.black,
      palette: brightness == Brightness.dark
          ? const ReaderPalette(
              shellBackground: Color(0xFF111111),
              chromeBackground: Color(0xFF111111),
              sidebarBackground: Color(0xFF111111),
              canvasBackground: Color(0xFF111111),
              panelBackground: Color(0xFF161616),
              panelMutedBackground: Color(0xFF242424),
              border: Color(0xFF5F5F5F),
              divider: Color(0xFF3F3F3F),
              hover: Color(0xFF2A2A2A),
              primarySoft: Color(0xFF3A3A3A),
              linkText: Color(0xFFFFFFFF),
              secondaryText: Color(0xFFD8D8D8),
              tertiaryText: Color(0xFF9A9A9A),
              shadow: Color.fromRGBO(0, 0, 0, 0),
            )
          : const ReaderPalette(
              shellBackground: Color(0xFFFFFFFF),
              chromeBackground: Color(0xFFFFFFFF),
              sidebarBackground: Color(0xFFFFFFFF),
              canvasBackground: Color(0xFFFFFFFF),
              panelBackground: Color(0xFFFFFFFF),
              panelMutedBackground: Color(0xFFF2F2F2),
              border: Color(0xFF8A8A8A),
              divider: Color(0xFF5F5F5F),
              hover: Color(0xFFE0E0E0),
              primarySoft: Color(0xFFC2C2C2),
              linkText: Color(0xFF000000),
              secondaryText: Color(0xFF333333),
              tertiaryText: Color(0xFF666666),
              shadow: Color.fromRGBO(0, 0, 0, 0),
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
      navigationBarTheme: NavigationBarThemeData(
        height: 72,
        backgroundColor: palette.panelBackground,
        elevation: 0,
        indicatorColor: palette.primarySoft,
        indicatorShape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(999),
        ),
        iconTheme: WidgetStateProperty.resolveWith((Set<WidgetState> states) {
          return IconThemeData(
            color: states.contains(WidgetState.selected)
                ? scheme.onSurface
                : palette.secondaryText,
            size: 24,
          );
        }),
        labelTextStyle:
            WidgetStateProperty.resolveWith((Set<WidgetState> states) {
          return TextStyle(
            color: states.contains(WidgetState.selected)
                ? scheme.onSurface
                : palette.secondaryText,
            fontWeight: states.contains(WidgetState.selected)
                ? FontWeight.w600
                : FontWeight.w500,
            fontSize: 12,
          );
        }),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: palette.panelBackground,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
          side: BorderSide(color: palette.border),
        ),
      ),
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
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
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
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          textStyle: const TextStyle(fontWeight: FontWeight.w600),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: bodyColor,
          side: BorderSide(color: palette.border),
          padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 13),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((Set<WidgetState> states) {
          if (states.contains(WidgetState.disabled)) {
            return palette.tertiaryText;
          }
          if (states.contains(WidgetState.selected)) {
            return scheme.onPrimary;
          }
          return palette.panelBackground;
        }),
        trackColor: WidgetStateProperty.resolveWith((Set<WidgetState> states) {
          if (states.contains(WidgetState.disabled)) {
            return palette.panelMutedBackground;
          }
          if (states.contains(WidgetState.selected)) {
            return scheme.primary;
          }
          return palette.panelMutedBackground;
        }),
        trackOutlineColor: WidgetStateProperty.all(palette.border),
      ),
      segmentedButtonTheme: SegmentedButtonThemeData(
        style: ButtonStyle(
          backgroundColor:
              WidgetStateProperty.resolveWith((Set<WidgetState> states) {
            if (states.contains(WidgetState.selected)) {
              return palette.primarySoft;
            }
            return palette.panelBackground;
          }),
          foregroundColor:
              WidgetStateProperty.resolveWith((Set<WidgetState> states) {
            return bodyColor;
          }),
          side: WidgetStateProperty.all(BorderSide(color: palette.border)),
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
      headlineSmall: _decorateText(
        base.headlineSmall,
        bodyColor,
        fontWeight: FontWeight.w700,
        height: 1.18,
      ),
      titleLarge: _decorateText(
        base.titleLarge,
        bodyColor,
        fontWeight: FontWeight.w700,
        height: 1.24,
      ),
      titleMedium: _decorateText(
        base.titleMedium,
        bodyColor,
        fontWeight: FontWeight.w600,
        height: 1.28,
      ),
      titleSmall: _decorateText(
        base.titleSmall,
        bodyColor,
        fontWeight: FontWeight.w600,
        height: 1.32,
      ),
      bodyLarge: _decorateText(base.bodyLarge, bodyColor, height: 1.55),
      bodyMedium: _decorateText(base.bodyMedium, bodyColor, height: 1.50),
      bodySmall: _decorateText(base.bodySmall, bodyColor, height: 1.40),
      labelLarge: _decorateText(
        base.labelLarge,
        bodyColor,
        fontWeight: FontWeight.w600,
      ),
      labelMedium: _decorateText(
        base.labelMedium,
        bodyColor,
        fontWeight: FontWeight.w500,
      ),
      labelSmall: _decorateText(
        base.labelSmall,
        bodyColor,
        fontWeight: FontWeight.w500,
      ),
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
