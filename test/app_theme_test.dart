import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rsstool/src/theme/app_theme.dart';

void main() {
  group('AppTheme', () {
    test('exposes the WeChat green theme', () {
      expect(AppTheme.themeIds, contains('wechat_green'));
      expect(AppTheme.displayName('wechat_green'), '微信绿');
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
      expect(palette.secondaryText, const Color(0xFF7F7F7F));
      expect(palette.tertiaryText, const Color(0xFFA6A6A6));
      expect(palette.shadow, const Color.fromRGBO(0, 0, 0, 0.04));
    });
  });
}
