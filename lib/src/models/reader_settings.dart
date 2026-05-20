import 'app_route.dart';
import '../localization/app_language.dart';
import 'auto_refresh.dart';

enum StartupHomeMode {
  allArticles,
  sources,
  bookmarks,
}

enum MobileSidebarMode {
  adaptive,
  drawer,
  rail,
}

enum MobileWorkspaceMode {
  singlePane,
  multiPane,
}

enum DesktopWorkspaceMode {
  threePane,
  focusedReader,
}

enum DesktopContentSurfaceMode {
  flat,
  layered,
}

enum ArticleListDensity {
  comfortable,
  compact,
}

enum AppearanceMode {
  light,
  dark,
  system,
}

enum ArticleContentMode {
  rich,
  textOnly,
}

enum AutoRefreshMode {
  allOff,
  partial,
  allOn,
}

enum SubscriptionNotificationMode {
  sourceSummary,
  perArticle,
  minimal,
}

enum CloudIdentityMode {
  official,
  privateCloud,
}

enum CloudContentMode {
  official,
  privateCloud,
}

enum PrivateCloudProtocol {
  webdav,
}

class ReaderSettings {
  const ReaderSettings({
    required this.startupHomeMode,
    required this.themeId,
    required this.appearanceMode,
    required this.mobileSidebarMode,
    required this.mobileWorkspaceMode,
    required this.desktopWorkspaceMode,
    required this.desktopContentSurfaceMode,
    required this.autoRefreshMode,
    required this.globalAutoRefreshIntervalMinutes,
    required this.subscriptionNotificationMode,
    required this.sourceFilterHintDismissed,
    required this.desktopSidebarCollapsed,
    required this.articleListDensity,
    required this.articleContentMode,
    required this.blurEffectsEnabled,
    required this.appLanguageMode,
    required this.cloudServiceEnabled,
    required this.privateCloudEnabled,
    required this.advancedCloudModeEnabled,
    required this.cloudIdentityMode,
    required this.cloudContentMode,
    required this.privateCloudProtocol,
    required this.privateCloudBaseUrl,
    required this.privateCloudUsername,
    required this.privateCloudPassword,
    required this.privateCloudBasePath,
    required this.privateCloudUserEndpoint,
    required this.privateCloudContentEndpoint,
  });

  final StartupHomeMode startupHomeMode;
  final String themeId;
  final AppearanceMode appearanceMode;
  final MobileSidebarMode mobileSidebarMode;
  final MobileWorkspaceMode mobileWorkspaceMode;
  final DesktopWorkspaceMode desktopWorkspaceMode;
  final DesktopContentSurfaceMode desktopContentSurfaceMode;
  final AutoRefreshMode autoRefreshMode;
  final int globalAutoRefreshIntervalMinutes;
  final SubscriptionNotificationMode subscriptionNotificationMode;
  final bool sourceFilterHintDismissed;
  final bool desktopSidebarCollapsed;
  final ArticleListDensity articleListDensity;
  final ArticleContentMode articleContentMode;
  final bool blurEffectsEnabled;
  final AppLanguageMode appLanguageMode;
  final bool cloudServiceEnabled;
  final bool privateCloudEnabled;
  final bool advancedCloudModeEnabled;
  final CloudIdentityMode cloudIdentityMode;
  final CloudContentMode cloudContentMode;
  final PrivateCloudProtocol privateCloudProtocol;
  final String privateCloudBaseUrl;
  final String privateCloudUsername;
  final String privateCloudPassword;
  final String privateCloudBasePath;
  final String privateCloudUserEndpoint;
  final String privateCloudContentEndpoint;

  bool get autoRefreshEnabled => autoRefreshMode != AutoRefreshMode.allOff;
  bool get autoRefreshAllEnabled => autoRefreshMode == AutoRefreshMode.allOn;

  static const ReaderSettings defaults = ReaderSettings(
    startupHomeMode: StartupHomeMode.allArticles,
    themeId: 'warm_default',
    appearanceMode: AppearanceMode.system,
    mobileSidebarMode: MobileSidebarMode.adaptive,
    mobileWorkspaceMode: MobileWorkspaceMode.singlePane,
    desktopWorkspaceMode: DesktopWorkspaceMode.threePane,
    desktopContentSurfaceMode: DesktopContentSurfaceMode.flat,
    autoRefreshMode: AutoRefreshMode.allOff,
    globalAutoRefreshIntervalMinutes: 1440,
    subscriptionNotificationMode: SubscriptionNotificationMode.sourceSummary,
    sourceFilterHintDismissed: false,
    desktopSidebarCollapsed: false,
    articleListDensity: ArticleListDensity.comfortable,
    articleContentMode: ArticleContentMode.rich,
    blurEffectsEnabled: true,
    appLanguageMode: AppLanguageMode.system,
    cloudServiceEnabled: false,
    privateCloudEnabled: false,
    advancedCloudModeEnabled: false,
    cloudIdentityMode: CloudIdentityMode.official,
    cloudContentMode: CloudContentMode.official,
    privateCloudProtocol: PrivateCloudProtocol.webdav,
    privateCloudBaseUrl: '',
    privateCloudUsername: '',
    privateCloudPassword: '',
    privateCloudBasePath: '/resonance/',
    privateCloudUserEndpoint: '',
    privateCloudContentEndpoint: '',
  );

  AppRouteId get startupRoute {
    switch (startupHomeMode) {
      case StartupHomeMode.allArticles:
        return AppRouteId.allArticles;
      case StartupHomeMode.sources:
        return AppRouteId.allArticles;
      case StartupHomeMode.bookmarks:
        return AppRouteId.bookmarks;
    }
  }

  ReaderSettings copyWith({
    StartupHomeMode? startupHomeMode,
    String? themeId,
    AppearanceMode? appearanceMode,
    MobileSidebarMode? mobileSidebarMode,
    MobileWorkspaceMode? mobileWorkspaceMode,
    DesktopWorkspaceMode? desktopWorkspaceMode,
    DesktopContentSurfaceMode? desktopContentSurfaceMode,
    AutoRefreshMode? autoRefreshMode,
    int? globalAutoRefreshIntervalMinutes,
    SubscriptionNotificationMode? subscriptionNotificationMode,
    bool? sourceFilterHintDismissed,
    bool? desktopSidebarCollapsed,
    ArticleListDensity? articleListDensity,
    ArticleContentMode? articleContentMode,
    bool? blurEffectsEnabled,
    AppLanguageMode? appLanguageMode,
    bool? cloudServiceEnabled,
    bool? privateCloudEnabled,
    bool? advancedCloudModeEnabled,
    CloudIdentityMode? cloudIdentityMode,
    CloudContentMode? cloudContentMode,
    PrivateCloudProtocol? privateCloudProtocol,
    String? privateCloudBaseUrl,
    String? privateCloudUsername,
    String? privateCloudPassword,
    String? privateCloudBasePath,
    String? privateCloudUserEndpoint,
    String? privateCloudContentEndpoint,
  }) {
    return ReaderSettings(
      startupHomeMode: startupHomeMode ?? this.startupHomeMode,
      themeId: themeId ?? this.themeId,
      appearanceMode: appearanceMode ?? this.appearanceMode,
      mobileSidebarMode: mobileSidebarMode ?? this.mobileSidebarMode,
      mobileWorkspaceMode: mobileWorkspaceMode ?? this.mobileWorkspaceMode,
      desktopWorkspaceMode: desktopWorkspaceMode ?? this.desktopWorkspaceMode,
      desktopContentSurfaceMode:
          desktopContentSurfaceMode ?? this.desktopContentSurfaceMode,
      autoRefreshMode: autoRefreshMode ?? this.autoRefreshMode,
      globalAutoRefreshIntervalMinutes: normalizeAutoRefreshInterval(
        globalAutoRefreshIntervalMinutes ??
            this.globalAutoRefreshIntervalMinutes,
      ),
      subscriptionNotificationMode:
          subscriptionNotificationMode ?? this.subscriptionNotificationMode,
      sourceFilterHintDismissed:
          sourceFilterHintDismissed ?? this.sourceFilterHintDismissed,
      desktopSidebarCollapsed:
          desktopSidebarCollapsed ?? this.desktopSidebarCollapsed,
      articleListDensity: articleListDensity ?? this.articleListDensity,
      articleContentMode: articleContentMode ?? this.articleContentMode,
      blurEffectsEnabled: blurEffectsEnabled ?? this.blurEffectsEnabled,
      appLanguageMode: appLanguageMode ?? this.appLanguageMode,
      cloudServiceEnabled: cloudServiceEnabled ?? this.cloudServiceEnabled,
      privateCloudEnabled: privateCloudEnabled ?? this.privateCloudEnabled,
      advancedCloudModeEnabled:
          advancedCloudModeEnabled ?? this.advancedCloudModeEnabled,
      cloudIdentityMode: cloudIdentityMode ?? this.cloudIdentityMode,
      cloudContentMode: cloudContentMode ?? this.cloudContentMode,
      privateCloudProtocol: privateCloudProtocol ?? this.privateCloudProtocol,
      privateCloudBaseUrl: privateCloudBaseUrl ?? this.privateCloudBaseUrl,
      privateCloudUsername: privateCloudUsername ?? this.privateCloudUsername,
      privateCloudPassword: privateCloudPassword ?? this.privateCloudPassword,
      privateCloudBasePath: privateCloudBasePath ?? this.privateCloudBasePath,
      privateCloudUserEndpoint:
          privateCloudUserEndpoint ?? this.privateCloudUserEndpoint,
      privateCloudContentEndpoint:
          privateCloudContentEndpoint ?? this.privateCloudContentEndpoint,
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'startupHomeMode': startupHomeMode.name,
      'themeId': themeId,
      'appearanceMode': appearanceMode.name,
      'mobileSidebarMode': mobileSidebarMode.name,
      'mobileWorkspaceMode': mobileWorkspaceMode.name,
      'desktopWorkspaceMode': desktopWorkspaceMode.name,
      'desktopContentSurfaceMode': desktopContentSurfaceMode.name,
      'autoRefreshMode': autoRefreshMode.name,
      'globalAutoRefreshIntervalMinutes': globalAutoRefreshIntervalMinutes,
      'subscriptionNotificationMode': subscriptionNotificationMode.name,
      'sourceFilterHintDismissed': sourceFilterHintDismissed,
      'desktopSidebarCollapsed': desktopSidebarCollapsed,
      'articleListDensity': articleListDensity.name,
      'articleContentMode': articleContentMode.name,
      'blurEffectsEnabled': blurEffectsEnabled,
      'appLanguageMode': appLanguageMode.storageValue,
      'cloudServiceEnabled': cloudServiceEnabled,
      'privateCloudEnabled': privateCloudEnabled,
      'advancedCloudModeEnabled': advancedCloudModeEnabled,
      'cloudIdentityMode': cloudIdentityMode.name,
      'cloudContentMode': cloudContentMode.name,
      'privateCloudProtocol': privateCloudProtocol.name,
      'privateCloudBaseUrl': privateCloudBaseUrl,
      'privateCloudUsername': privateCloudUsername,
      'privateCloudPassword': privateCloudPassword,
      'privateCloudBasePath': privateCloudBasePath,
      'privateCloudUserEndpoint': privateCloudUserEndpoint,
      'privateCloudContentEndpoint': privateCloudContentEndpoint,
    };
  }

  factory ReaderSettings.fromJson(Map<String, dynamic> json) {
    return ReaderSettings(
      startupHomeMode: StartupHomeMode.values.firstWhere(
        (StartupHomeMode value) => value.name == json['startupHomeMode'],
        orElse: () => defaults.startupHomeMode,
      ),
      themeId: json['themeId'] as String? ?? defaults.themeId,
      appearanceMode: AppearanceMode.values.firstWhere(
        (AppearanceMode value) => value.name == json['appearanceMode'],
        orElse: () => defaults.appearanceMode,
      ),
      mobileSidebarMode: MobileSidebarMode.values.firstWhere(
        (MobileSidebarMode value) => value.name == json['mobileSidebarMode'],
        orElse: () => defaults.mobileSidebarMode,
      ),
      mobileWorkspaceMode: MobileWorkspaceMode.values.firstWhere(
        (MobileWorkspaceMode value) =>
            value.name == json['mobileWorkspaceMode'],
        orElse: () => defaults.mobileWorkspaceMode,
      ),
      desktopWorkspaceMode: DesktopWorkspaceMode.values.firstWhere(
        (DesktopWorkspaceMode value) =>
            value.name == json['desktopWorkspaceMode'],
        orElse: () => defaults.desktopWorkspaceMode,
      ),
      desktopContentSurfaceMode: DesktopContentSurfaceMode.values.firstWhere(
        (DesktopContentSurfaceMode value) =>
            value.name == json['desktopContentSurfaceMode'],
        orElse: () => defaults.desktopContentSurfaceMode,
      ),
      autoRefreshMode: AutoRefreshMode.values.firstWhere(
        (AutoRefreshMode value) => value.name == json['autoRefreshMode'],
        orElse: () {
          final bool legacyEnabled = json['autoRefreshEnabled'] as bool? ??
              defaults.autoRefreshEnabled;
          return legacyEnabled
              ? AutoRefreshMode.partial
              : AutoRefreshMode.allOff;
        },
      ),
      globalAutoRefreshIntervalMinutes: normalizeAutoRefreshInterval(
        json['globalAutoRefreshIntervalMinutes'] as int? ??
            defaults.globalAutoRefreshIntervalMinutes,
      ),
      subscriptionNotificationMode:
          SubscriptionNotificationMode.values.firstWhere(
        (SubscriptionNotificationMode value) =>
            value.name == json['subscriptionNotificationMode'],
        orElse: () => defaults.subscriptionNotificationMode,
      ),
      sourceFilterHintDismissed: json['sourceFilterHintDismissed'] as bool? ??
          defaults.sourceFilterHintDismissed,
      desktopSidebarCollapsed: json['desktopSidebarCollapsed'] as bool? ??
          defaults.desktopSidebarCollapsed,
      articleListDensity: ArticleListDensity.values.firstWhere(
        (ArticleListDensity value) => value.name == json['articleListDensity'],
        orElse: () => defaults.articleListDensity,
      ),
      articleContentMode: ArticleContentMode.values.firstWhere(
        (ArticleContentMode value) => value.name == json['articleContentMode'],
        orElse: () => defaults.articleContentMode,
      ),
      blurEffectsEnabled:
          json['blurEffectsEnabled'] as bool? ?? defaults.blurEffectsEnabled,
      appLanguageMode:
          AppLanguageModeX.fromStorageValue(json['appLanguageMode'] as String?),
      cloudServiceEnabled:
          json['cloudServiceEnabled'] as bool? ?? defaults.cloudServiceEnabled,
      privateCloudEnabled:
          json['privateCloudEnabled'] as bool? ?? defaults.privateCloudEnabled,
      advancedCloudModeEnabled: json['advancedCloudModeEnabled'] as bool? ??
          defaults.advancedCloudModeEnabled,
      cloudIdentityMode: CloudIdentityMode.values.firstWhere(
        (CloudIdentityMode value) => value.name == json['cloudIdentityMode'],
        orElse: () => defaults.cloudIdentityMode,
      ),
      cloudContentMode: CloudContentMode.values.firstWhere(
        (CloudContentMode value) => value.name == json['cloudContentMode'],
        orElse: () => defaults.cloudContentMode,
      ),
      privateCloudProtocol: PrivateCloudProtocol.values.firstWhere(
        (PrivateCloudProtocol value) =>
            value.name == json['privateCloudProtocol'],
        orElse: () => defaults.privateCloudProtocol,
      ),
      privateCloudBaseUrl: json['privateCloudBaseUrl'] as String? ??
          defaults.privateCloudBaseUrl,
      privateCloudUsername: json['privateCloudUsername'] as String? ??
          defaults.privateCloudUsername,
      privateCloudPassword: json['privateCloudPassword'] as String? ??
          defaults.privateCloudPassword,
      privateCloudBasePath: json['privateCloudBasePath'] as String? ??
          defaults.privateCloudBasePath,
      privateCloudUserEndpoint: json['privateCloudUserEndpoint'] as String? ??
          defaults.privateCloudUserEndpoint,
      privateCloudContentEndpoint:
          json['privateCloudContentEndpoint'] as String? ??
              defaults.privateCloudContentEndpoint,
    );
  }
}
