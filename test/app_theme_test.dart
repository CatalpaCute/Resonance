import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rsstool/src/theme/app_theme.dart';

void main() {
  group('AppTheme', () {
    test('exposes the WeChat green theme', () {
      expect(AppTheme.themeIds, contains('wechat_green'));
      expect(AppTheme.displayName('wechat_green'), '微信绿');
    });

    test('exposes the ink black and white theme', () {
      expect(AppTheme.themeIds, contains('ink_black_white'));
      expect(AppTheme.displayName('ink_black_white'), '墨水黑白');
    });

    test('exposes the Material You theme', () {
      expect(AppTheme.themeIds, contains('material_you_light'));
      expect(AppTheme.displayName('material_you_light'), 'Material You');
    });

    test('builds the Material You theme palette', () {
      final ThemeData theme = AppTheme.themeFor('material_you_light');
      final ReaderPalette? palette = theme.extension<ReaderPalette>();

      expect(theme.useMaterial3, isTrue);
      expect(theme.brightness, Brightness.light);
      expect(theme.colorScheme.primary, const Color(0xFF6750A4));
      expect(theme.scaffoldBackgroundColor, const Color(0xFFFFFBFE));
      expect(theme.navigationBarTheme.height, 72);
      expect(palette, isNotNull);
      expect(palette!.shellBackground, const Color(0xFFFFFBFE));
      expect(palette.panelMutedBackground, const Color(0xFFF3EDF7));
      expect(palette.primarySoft, const Color(0xFFEADDFF));
      expect(palette.linkText, const Color(0xFF6750A4));
    });

    test('builds the WeChat green theme palette', () {
      final ThemeData theme = AppTheme.themeFor('wechat_green');
      final ReaderPalette? palette = theme.extension<ReaderPalette>();

      expect(theme.brightness, Brightness.light);
      expect(theme.colorScheme.primary, const Color(0xFF07C160));
      expect(theme.colorScheme.onPrimary, Colors.white);
      expect(theme.scaffoldBackgroundColor, const Color(0xFFF7F7F7));
      expect(palette, isNotNull);
      expect(palette!.shellBackground, const Color(0xFFF7F7F7));
      expect(palette.chromeBackground, Colors.white);
      expect(palette.panelBackground, Colors.white);
      expect(palette.border, const Color(0xFFEDEDED));
      expect(palette.divider, const Color(0xFFEDEDED));
      expect(palette.hover, const Color(0xFFF2F2F2));
      expect(palette.primarySoft, const Color.fromRGBO(7, 193, 96, 0.10));
      expect(palette.linkText, const Color(0xFF047A3D));
      expect(palette.secondaryText, const Color(0xFF7F7F7F));
      expect(palette.tertiaryText, const Color(0xFFA6A6A6));
      expect(palette.shadow, const Color.fromRGBO(0, 0, 0, 0.04));
    });

    test('builds the ink black and white theme palette', () {
      final ThemeData theme = AppTheme.themeFor('ink_black_white');
      final ReaderPalette? palette = theme.extension<ReaderPalette>();

      expect(theme.brightness, Brightness.light);
      expect(theme.colorScheme.primary, Colors.black);
      expect(theme.colorScheme.onPrimary, Colors.white);
      expect(theme.colorScheme.secondary, Colors.black);
      expect(theme.colorScheme.tertiary, Colors.black);
      expect(theme.colorScheme.primaryContainer, const Color(0xFFC2C2C2));
      expect(theme.colorScheme.secondaryContainer, const Color(0xFFD9D9D9));
      expect(theme.colorScheme.tertiaryContainer, const Color(0xFFE0E0E0));
      expect(theme.colorScheme.primaryFixed, const Color(0xFFD9D9D9));
      expect(theme.colorScheme.secondaryFixed, const Color(0xFFD9D9D9));
      expect(theme.colorScheme.tertiaryFixed, const Color(0xFFD9D9D9));
      expect(theme.colorScheme.surfaceContainerLowest, Colors.white);
      expect(theme.colorScheme.surfaceContainerLow, Colors.white);
      expect(theme.colorScheme.surfaceContainer, Colors.white);
      expect(theme.colorScheme.surfaceContainerHigh, const Color(0xFFF2F2F2));
      expect(
        theme.colorScheme.surfaceContainerHighest,
        const Color(0xFFE0E0E0),
      );
      expect(theme.colorScheme.surfaceTint, Colors.transparent);
      expect(theme.scaffoldBackgroundColor, Colors.white);
      expect(theme.dialogTheme.backgroundColor, Colors.white);
      expect(theme.dialogTheme.surfaceTintColor, Colors.transparent);
      expect(
        theme.switchTheme.trackColor?.resolve(<WidgetState>{
          WidgetState.selected,
        }),
        Colors.black,
      );
      expect(
        theme.segmentedButtonTheme.style?.backgroundColor
            ?.resolve(<WidgetState>{WidgetState.selected}),
        const Color(0xFFC2C2C2),
      );
      expect(palette, isNotNull);
      expect(palette!.shellBackground, Colors.white);
      expect(palette.chromeBackground, Colors.white);
      expect(palette.panelBackground, Colors.white);
      expect(palette.panelMutedBackground, const Color(0xFFF2F2F2));
      expect(palette.border, const Color(0xFF8A8A8A));
      expect(palette.divider, const Color(0xFF5F5F5F));
      expect(palette.hover, const Color(0xFFE0E0E0));
      expect(palette.primarySoft, const Color(0xFFC2C2C2));
      expect(palette.linkText, Colors.black);
      expect(palette.secondaryText, const Color(0xFF333333));
      expect(palette.tertiaryText, const Color(0xFF666666));
      expect(palette.shadow, const Color.fromRGBO(0, 0, 0, 0));
    });

    test('provides coordinated link colors for every theme', () {
      const Map<String, Color> expectedLinkColors = <String, Color>{
        'warm_default': Color(0xFF8F7658),
        'deep_default': Color(0xFFE0C49A),
        'neutral_minimal': Color(0xFF3F4850),
        'material_you_light': Color(0xFF6750A4),
        'wechat_green': Color(0xFF047A3D),
        'ink_black_white': Colors.black,
      };

      expect(AppTheme.themeIds, expectedLinkColors.keys);
      for (final MapEntry<String, Color> entry in expectedLinkColors.entries) {
        final ReaderPalette? palette =
            AppTheme.themeFor(entry.key).extension<ReaderPalette>();

        expect(palette, isNotNull);
        expect(palette!.linkText, entry.value);
      }
    });
  });
}
