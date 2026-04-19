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

enum ArticleListDensity {
  comfortable,
  compact,
}

class ReaderSettings {
  const ReaderSettings({
    required this.startupHomeMode,
    required this.themeId,
    required this.mobileSidebarMode,
    required this.desktopSidebarCollapsed,
    required this.articleListDensity,
    required this.appLanguageMode,
  });

  final StartupHomeMode startupHomeMode;
  final String themeId;
  final MobileSidebarMode mobileSidebarMode;
  final bool desktopSidebarCollapsed;
  final ArticleListDensity articleListDensity;
  final AppLanguageMode appLanguageMode;

  static const ReaderSettings defaults = ReaderSettings(
    startupHomeMode: StartupHomeMode.allArticles,
    themeId: 'warm_default',
    mobileSidebarMode: MobileSidebarMode.adaptive,
    desktopSidebarCollapsed: false,
    articleListDensity: ArticleListDensity.comfortable,
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
    bool? desktopSidebarCollapsed,
    ArticleListDensity? articleListDensity,
    AppLanguageMode? appLanguageMode,
  }) {
    return ReaderSettings(
      startupHomeMode: startupHomeMode ?? this.startupHomeMode,
      themeId: themeId ?? this.themeId,
      mobileSidebarMode: mobileSidebarMode ?? this.mobileSidebarMode,
      desktopSidebarCollapsed:
          desktopSidebarCollapsed ?? this.desktopSidebarCollapsed,
      articleListDensity: articleListDensity ?? this.articleListDensity,
      appLanguageMode: appLanguageMode ?? this.appLanguageMode,
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'startupHomeMode': startupHomeMode.name,
      'themeId': themeId,
      'mobileSidebarMode': mobileSidebarMode.name,
      'desktopSidebarCollapsed': desktopSidebarCollapsed,
      'articleListDensity': articleListDensity.name,
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
      desktopSidebarCollapsed: json['desktopSidebarCollapsed'] as bool? ??
          defaults.desktopSidebarCollapsed,
      articleListDensity: ArticleListDensity.values.firstWhere(
        (ArticleListDensity value) => value.name == json['articleListDensity'],
        orElse: () => defaults.articleListDensity,
      ),
      appLanguageMode:
          AppLanguageModeX.fromStorageValue(json['appLanguageMode'] as String?),
    );
  }
}
