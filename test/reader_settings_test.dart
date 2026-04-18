import 'package:flutter_test/flutter_test.dart';
import 'package:rsstool/src/models/reader_settings.dart';

void main() {
  group('ReaderSettings', () {
    test('serializes and restores all public fields', () {
      const ReaderSettings settings = ReaderSettings(
        startupHomeMode: StartupHomeMode.bookmarks,
        themeId: 'deep_default',
        mobileSidebarMode: MobileSidebarMode.rail,
        desktopSidebarCollapsed: true,
        articleListDensity: ArticleListDensity.compact,
      );

      final Map<String, dynamic> json = settings.toJson();
      final ReaderSettings restored = ReaderSettings.fromJson(json);

      expect(restored.startupHomeMode, StartupHomeMode.bookmarks);
      expect(restored.themeId, 'deep_default');
      expect(restored.mobileSidebarMode, MobileSidebarMode.rail);
      expect(restored.desktopSidebarCollapsed, isTrue);
      expect(restored.articleListDensity, ArticleListDensity.compact);
    });

    test('falls back to defaults for missing values', () {
      final ReaderSettings restored = ReaderSettings.fromJson(<String, dynamic>{});

      expect(restored.startupHomeMode, ReaderSettings.defaults.startupHomeMode);
      expect(restored.themeId, ReaderSettings.defaults.themeId);
      expect(restored.mobileSidebarMode, ReaderSettings.defaults.mobileSidebarMode);
      expect(restored.desktopSidebarCollapsed, ReaderSettings.defaults.desktopSidebarCollapsed);
      expect(restored.articleListDensity, ReaderSettings.defaults.articleListDensity);
    });
  });
}
