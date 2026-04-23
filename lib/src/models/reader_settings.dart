import 'app_route.dart';
import '../localization/app_language.dart';

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

enum ArticleListDensity {
  comfortable,
  compact,
}

enum ArticleContentMode {
  rich,
  textOnly,
}

class ReaderSettings {
  const ReaderSettings({
    required this.startupHomeMode,
    required this.themeId,
    required this.mobileSidebarMode,
    required this.mobileWorkspaceMode,
    required this.desktopSidebarCollapsed,
    required this.articleListDensity,
    required this.articleContentMode,
    required this.appLanguageMode,
  });

  final StartupHomeMode startupHomeMode;
  final String themeId;
  final MobileSidebarMode mobileSidebarMode;
  final MobileWorkspaceMode mobileWorkspaceMode;
  final bool desktopSidebarCollapsed;
  final ArticleListDensity articleListDensity;
  final ArticleContentMode articleContentMode;
  final AppLanguageMode appLanguageMode;

  static const ReaderSettings defaults = ReaderSettings(
    startupHomeMode: StartupHomeMode.allArticles,
    themeId: 'warm_default',
    mobileSidebarMode: MobileSidebarMode.adaptive,
    mobileWorkspaceMode: MobileWorkspaceMode.singlePane,
    desktopSidebarCollapsed: false,
    articleListDensity: ArticleListDensity.comfortable,
    articleContentMode: ArticleContentMode.rich,
    appLanguageMode: AppLanguageMode.system,
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
    MobileSidebarMode? mobileSidebarMode,
    MobileWorkspaceMode? mobileWorkspaceMode,
    bool? desktopSidebarCollapsed,
    ArticleListDensity? articleListDensity,
    ArticleContentMode? articleContentMode,
    AppLanguageMode? appLanguageMode,
  }) {
    return ReaderSettings(
      startupHomeMode: startupHomeMode ?? this.startupHomeMode,
      themeId: themeId ?? this.themeId,
      mobileSidebarMode: mobileSidebarMode ?? this.mobileSidebarMode,
      mobileWorkspaceMode: mobileWorkspaceMode ?? this.mobileWorkspaceMode,
      desktopSidebarCollapsed:
          desktopSidebarCollapsed ?? this.desktopSidebarCollapsed,
      articleListDensity: articleListDensity ?? this.articleListDensity,
      articleContentMode: articleContentMode ?? this.articleContentMode,
      appLanguageMode: appLanguageMode ?? this.appLanguageMode,
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'startupHomeMode': startupHomeMode.name,
      'themeId': themeId,
      'mobileSidebarMode': mobileSidebarMode.name,
      'mobileWorkspaceMode': mobileWorkspaceMode.name,
      'desktopSidebarCollapsed': desktopSidebarCollapsed,
      'articleListDensity': articleListDensity.name,
      'articleContentMode': articleContentMode.name,
      'appLanguageMode': appLanguageMode.storageValue,
    };
  }

  factory ReaderSettings.fromJson(Map<String, dynamic> json) {
    return ReaderSettings(
      startupHomeMode: StartupHomeMode.values.firstWhere(
        (StartupHomeMode value) => value.name == json['startupHomeMode'],
        orElse: () => defaults.startupHomeMode,
      ),
      themeId: json['themeId'] as String? ?? defaults.themeId,
      mobileSidebarMode: MobileSidebarMode.values.firstWhere(
        (MobileSidebarMode value) => value.name == json['mobileSidebarMode'],
        orElse: () => defaults.mobileSidebarMode,
      ),
      mobileWorkspaceMode: MobileWorkspaceMode.values.firstWhere(
        (MobileWorkspaceMode value) => value.name == json['mobileWorkspaceMode'],
        orElse: () => defaults.mobileWorkspaceMode,
      ),
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
      appLanguageMode:
          AppLanguageModeX.fromStorageValue(json['appLanguageMode'] as String?),
    );
  }
}
