import 'package:flutter_test/flutter_test.dart';
import 'package:rsstool/src/localization/app_language.dart';
import 'package:rsstool/src/models/reader_settings.dart';

void main() {
  group('ReaderSettings', () {
    test('serializes and restores all public fields', () {
      const ReaderSettings settings = ReaderSettings(
        startupHomeMode: StartupHomeMode.bookmarks,
        themeId: 'deep_default',
        appearanceMode: AppearanceMode.system,
        mobileSidebarMode: MobileSidebarMode.rail,
        mobileWorkspaceMode: MobileWorkspaceMode.multiPane,
        desktopWorkspaceMode: DesktopWorkspaceMode.focusedReader,
        desktopContentSurfaceMode: DesktopContentSurfaceMode.layered,
        autoRefreshMode: AutoRefreshMode.allOn,
        globalAutoRefreshIntervalMinutes: 4320,
        subscriptionNotificationMode: SubscriptionNotificationMode.perArticle,
        sourceFilterHintDismissed: true,
        desktopSidebarCollapsed: true,
        articleListDensity: ArticleListDensity.compact,
        articleContentMode: ArticleContentMode.textOnly,
        blurEffectsEnabled: false,
        appLanguageMode: AppLanguageMode.zhHant,
        cloudServiceEnabled: true,
        cloudAutoSyncEnabled: true,
        privateCloudEnabled: true,
        advancedCloudModeEnabled: true,
        cloudIdentityMode: CloudIdentityMode.privateCloud,
        cloudContentMode: CloudContentMode.privateCloud,
        privateCloudProtocol: PrivateCloudProtocol.webdav,
        privateCloudBaseUrl: 'https://private.example.com',
        privateCloudUsername: 'catal',
        privateCloudPassword: 'secret',
        privateCloudBasePath: '/resonance/',
        privateCloudUserEndpoint: '/identity',
        privateCloudContentEndpoint: '/content',
      );

      final Map<String, dynamic> json = settings.toJson();
      final ReaderSettings restored = ReaderSettings.fromJson(json);

      expect(restored.startupHomeMode, StartupHomeMode.bookmarks);
      expect(restored.themeId, 'deep_default');
      expect(restored.mobileSidebarMode, MobileSidebarMode.rail);
      expect(restored.mobileWorkspaceMode, MobileWorkspaceMode.multiPane);
      expect(
        restored.desktopWorkspaceMode,
        DesktopWorkspaceMode.focusedReader,
      );
      expect(
        restored.desktopContentSurfaceMode,
        DesktopContentSurfaceMode.layered,
      );
      expect(restored.autoRefreshMode, AutoRefreshMode.allOn);
      expect(restored.globalAutoRefreshIntervalMinutes, 4320);
      expect(
        restored.subscriptionNotificationMode,
        SubscriptionNotificationMode.perArticle,
      );
      expect(restored.autoRefreshEnabled, isTrue);
      expect(restored.sourceFilterHintDismissed, isTrue);
      expect(restored.desktopSidebarCollapsed, isTrue);
      expect(restored.articleListDensity, ArticleListDensity.compact);
      expect(restored.articleContentMode, ArticleContentMode.textOnly);
      expect(restored.blurEffectsEnabled, isFalse);
      expect(restored.appLanguageMode, AppLanguageMode.zhHant);
      expect(restored.cloudServiceEnabled, isTrue);
      expect(restored.cloudAutoSyncEnabled, isTrue);
      expect(restored.privateCloudEnabled, isTrue);
      expect(restored.advancedCloudModeEnabled, isTrue);
      expect(restored.cloudIdentityMode, CloudIdentityMode.privateCloud);
      expect(restored.cloudContentMode, CloudContentMode.privateCloud);
      expect(restored.privateCloudProtocol, PrivateCloudProtocol.webdav);
      expect(restored.privateCloudBaseUrl, 'https://private.example.com');
      expect(restored.privateCloudUsername, 'catal');
      expect(restored.privateCloudPassword, 'secret');
      expect(restored.privateCloudBasePath, '/resonance/');
      expect(restored.privateCloudUserEndpoint, '/identity');
      expect(restored.privateCloudContentEndpoint, '/content');
    });

    test('falls back to defaults for missing values', () {
      final ReaderSettings restored =
          ReaderSettings.fromJson(<String, dynamic>{});

      expect(restored.startupHomeMode, ReaderSettings.defaults.startupHomeMode);
      expect(restored.themeId, ReaderSettings.defaults.themeId);
      expect(
        restored.mobileSidebarMode,
        ReaderSettings.defaults.mobileSidebarMode,
      );
      expect(
        restored.mobileWorkspaceMode,
        ReaderSettings.defaults.mobileWorkspaceMode,
      );
      expect(
        restored.desktopWorkspaceMode,
        ReaderSettings.defaults.desktopWorkspaceMode,
      );
      expect(
        restored.desktopContentSurfaceMode,
        ReaderSettings.defaults.desktopContentSurfaceMode,
      );
      expect(
        restored.sourceFilterHintDismissed,
        ReaderSettings.defaults.sourceFilterHintDismissed,
      );
      expect(
        restored.desktopSidebarCollapsed,
        ReaderSettings.defaults.desktopSidebarCollapsed,
      );
      expect(
        restored.articleListDensity,
        ReaderSettings.defaults.articleListDensity,
      );
      expect(
        restored.articleContentMode,
        ReaderSettings.defaults.articleContentMode,
      );
      expect(
        restored.blurEffectsEnabled,
        ReaderSettings.defaults.blurEffectsEnabled,
      );
      expect(restored.appLanguageMode, ReaderSettings.defaults.appLanguageMode);
      expect(
        restored.cloudServiceEnabled,
        ReaderSettings.defaults.cloudServiceEnabled,
      );
      expect(
        restored.cloudAutoSyncEnabled,
        ReaderSettings.defaults.cloudAutoSyncEnabled,
      );
      expect(
        restored.privateCloudEnabled,
        ReaderSettings.defaults.privateCloudEnabled,
      );
      expect(
        restored.advancedCloudModeEnabled,
        ReaderSettings.defaults.advancedCloudModeEnabled,
      );
      expect(
        restored.cloudIdentityMode,
        ReaderSettings.defaults.cloudIdentityMode,
      );
      expect(
        restored.cloudContentMode,
        ReaderSettings.defaults.cloudContentMode,
      );
      expect(
        restored.privateCloudProtocol,
        ReaderSettings.defaults.privateCloudProtocol,
      );
      expect(
        restored.privateCloudBaseUrl,
        ReaderSettings.defaults.privateCloudBaseUrl,
      );
      expect(
        restored.privateCloudUsername,
        ReaderSettings.defaults.privateCloudUsername,
      );
      expect(
        restored.privateCloudPassword,
        ReaderSettings.defaults.privateCloudPassword,
      );
      expect(
        restored.privateCloudBasePath,
        ReaderSettings.defaults.privateCloudBasePath,
      );
      expect(
        restored.privateCloudUserEndpoint,
        ReaderSettings.defaults.privateCloudUserEndpoint,
      );
      expect(
        restored.privateCloudContentEndpoint,
        ReaderSettings.defaults.privateCloudContentEndpoint,
      );
    });
  });
}
