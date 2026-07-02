import 'package:flutter/widgets.dart';

import '../models/app_route.dart';
import '../models/article.dart';
import '../models/reader_settings.dart';
import 'app_language.dart';

class AppBrand {
  static const String mark = 'R';
  static const String nameZhCn = '回响';
  static const String nameZhHant = '回響';
  static const String nameEn = 'Resonance';
  static const String fullName = 'Resonance';
  static const String version = String.fromEnvironment(
    'APP_VERSION',
    defaultValue: 'dev',
  );
  static const String repoUrl = 'https://github.com/CatalpaCute/Resonance';
}

enum _AppTextLanguage {
  zhCn,
  zhHant,
  en,
}

class AppStrings {
  const AppStrings._(this._language);

  final _AppTextLanguage _language;

  static AppStrings of(BuildContext context) {
    return fromLocale(Localizations.localeOf(context));
  }

  static AppStrings fromLanguageMode(
    AppLanguageMode mode, {
    Locale? systemLocale,
  }) {
    return fromLocale(resolveAppLocale(mode, systemLocale: systemLocale));
  }

  static AppStrings fromLocale(Locale locale) {
    final Locale resolved = resolveSupportedAppLocale(locale);
    if (resolved == appLocaleZhHant) {
      return const AppStrings._(_AppTextLanguage.zhHant);
    }
    if (resolved == appLocaleZhCn) {
      return const AppStrings._(_AppTextLanguage.zhCn);
    }
    return const AppStrings._(_AppTextLanguage.en);
  }

  static Locale resolveLocaleList(
    List<Locale>? locales,
    Iterable<Locale> supportedLocales,
  ) {
    if (locales != null) {
      for (final Locale locale in locales) {
        if (locale.languageCode == 'zh' || locale.languageCode == 'en') {
          return resolveSupportedAppLocale(locale);
        }
      }
    }
    return appLocaleEnglish;
  }

  String _text({
    required String zhCn,
    String? zhHant,
    required String en,
  }) {
    switch (_language) {
      case _AppTextLanguage.zhCn:
        return zhCn;
      case _AppTextLanguage.zhHant:
        return zhHant ?? zhCn;
      case _AppTextLanguage.en:
        return en;
    }
  }

  String get appName => _text(
        zhCn: AppBrand.nameZhCn,
        zhHant: AppBrand.nameZhHant,
        en: AppBrand.nameEn,
      );

  String get appFullName => _text(
        zhCn: AppBrand.fullName,
        zhHant: AppBrand.fullName,
        en: AppBrand.fullName,
      );

  String routeTitle(
    AppRouteId route, {
    String? activeSourceTitle,
    String? selectedArticleTitle,
    BookmarkFilter? bookmarkFilter,
  }) {
    switch (route) {
      case AppRouteId.allArticles:
        return allArticles;
      case AppRouteId.sources:
        return sources;
      case AppRouteId.sourceDetail:
        return activeSourceTitle ?? sourceArticles;
      case AppRouteId.bookmarks:
        return bookmarkFilter == BookmarkFilter.savedForLater
            ? savedForLater
            : starred;
      case AppRouteId.discoverAddSource:
        return subscriptionManagement;
      case AppRouteId.settings:
        return settings;
      case AppRouteId.readerDetail:
        return selectedArticleTitle ?? readerDetail;
    }
  }

  String startupSummary(StartupHomeMode mode) {
    switch (mode) {
      case StartupHomeMode.allArticles:
      case StartupHomeMode.sources:
        return _text(
          zhCn: '启动后优先进入全部文章',
          zhHant: '啟動後優先進入全部文章',
          en: 'Open All Articles on startup',
        );
      case StartupHomeMode.bookmarks:
        return _text(
          zhCn: '启动后优先进入收藏与稍后读',
          zhHant: '啟動後優先進入收藏與稍後讀',
          en: 'Open Bookmarks on startup',
        );
    }
  }

  String startupLabel(StartupHomeMode mode) {
    switch (mode) {
      case StartupHomeMode.allArticles:
      case StartupHomeMode.sources:
        return allArticles;
      case StartupHomeMode.bookmarks:
        return bookmarksAndLater;
    }
  }

  String startupDesc(StartupHomeMode mode) {
    switch (mode) {
      case StartupHomeMode.allArticles:
      case StartupHomeMode.sources:
        return _text(
          zhCn: '适合快速扫读时间流。',
          zhHant: '適合快速掃讀時間流。',
          en: 'Best for sweeping through the timeline quickly.',
        );
      case StartupHomeMode.bookmarks:
        return _text(
          zhCn: '适合把阅读器当作长期收纳箱。',
          zhHant: '適合把閱讀器當作長期收納箱。',
          en: 'Best when you treat the reader as a long-term archive.',
        );
    }
  }

  String mobileSidebarLabel(MobileSidebarMode mode) {
    switch (mode) {
      case MobileSidebarMode.adaptive:
        return _text(zhCn: '自适应', zhHant: '自適應', en: 'Adaptive');
      case MobileSidebarMode.drawer:
        return _text(zhCn: '抽屉侧栏', zhHant: '抽屜側欄', en: 'Drawer');
      case MobileSidebarMode.rail:
        return _text(zhCn: '窄栏常驻', zhHant: '窄欄常駐', en: 'Rail');
    }
  }

  String mobileSidebarDesc(MobileSidebarMode mode) {
    switch (mode) {
      case MobileSidebarMode.adaptive:
        return _text(
          zhCn: '小屏抽屉，大屏窄栏，默认更稳。',
          zhHant: '小屏抽屜，大屏窄欄，預設更穩。',
          en: 'Use a drawer on small screens and a rail on wider screens.',
        );
      case MobileSidebarMode.drawer:
        return _text(
          zhCn: '始终通过抽屉打开导航。',
          zhHant: '始終透過抽屜打開導覽。',
          en: 'Always open navigation as a drawer.',
        );
      case MobileSidebarMode.rail:
        return _text(
          zhCn: '始终保留窄栏，并像桌面端一样从顶部按钮展开或收起。',
          zhHant: '始終保留窄欄，並像桌面端一樣從頂部按鈕展開或收起。',
          en: 'Keep a slim rail visible and toggle it from the top button like desktop.',
        );
    }
  }

  String mobileWorkspaceModeLabel(MobileWorkspaceMode mode) {
    switch (mode) {
      case MobileWorkspaceMode.singlePane:
        return _text(zhCn: '整页文章流', zhHant: '整頁文章流', en: 'Single Pane');
      case MobileWorkspaceMode.multiPane:
        return _text(zhCn: '多栏工作区', zhHant: '多欄工作區', en: 'Multi Pane');
    }
  }

  String desktopWorkspaceModeLabel(DesktopWorkspaceMode mode) {
    switch (mode) {
      case DesktopWorkspaceMode.threePane:
        return _text(zhCn: '三栏工作区', zhHant: '三欄工作區', en: 'Three Pane');
      case DesktopWorkspaceMode.focusedReader:
        return _text(
          zhCn: '双栏列表 + 独立阅读页',
          zhHant: '雙欄列表 + 獨立閱讀頁',
          en: 'Two Pane + Reader Page',
        );
    }
  }

  String desktopContentSurfaceModeLabel(DesktopContentSurfaceMode mode) {
    switch (mode) {
      case DesktopContentSurfaceMode.flat:
        return _text(zhCn: '扁平背景板', zhHant: '扁平背景板', en: 'Flat Surfaces');
      case DesktopContentSurfaceMode.layered:
        return _text(zhCn: '层叠背景板', zhHant: '層疊背景板', en: 'Layered Surfaces');
    }
  }

  String articleDensityLabel(ArticleListDensity density) {
    switch (density) {
      case ArticleListDensity.comfortable:
        return _text(zhCn: '舒展', zhHant: '舒展', en: 'Comfortable');
      case ArticleListDensity.compact:
        return _text(zhCn: '紧凑', zhHant: '緊湊', en: 'Compact');
    }
  }

  String articleContentModeLabel(ArticleContentMode mode) {
    switch (mode) {
      case ArticleContentMode.rich:
        return _text(zhCn: '完整版文章', zhHant: '完整版文章', en: 'Rich Article');
      case ArticleContentMode.textOnly:
        return _text(zhCn: '纯文本文章', zhHant: '純文字文章', en: 'Text Only');
    }
  }

  String languageModeLabel(AppLanguageMode mode) {
    switch (mode) {
      case AppLanguageMode.system:
        return _text(zhCn: '跟随系统', zhHant: '跟隨系統', en: 'Follow System');
      case AppLanguageMode.zhCn:
        return '中文（简体）';
      case AppLanguageMode.zhHant:
        return '中文（繁體）';
      case AppLanguageMode.english:
        return 'English';
    }
  }

  String appearanceModeLabel(AppearanceMode mode) {
    switch (mode) {
      case AppearanceMode.light:
        return _text(zhCn: '浅色', zhHant: '淺色', en: 'Light');
      case AppearanceMode.dark:
        return _text(zhCn: '深色', zhHant: '深色', en: 'Dark');
      case AppearanceMode.system:
        return _text(zhCn: '跟随系统', zhHant: '跟隨系統', en: 'Follow System');
    }
  }

  String themePresetName(String themeId) {
    switch (themeId) {
      case 'warm_default':
        return _text(zhCn: '暖灰默认', zhHant: '暖灰預設', en: 'Warm Default');
      case 'deep_default':
        return _text(zhCn: '深棕默认', zhHant: '深棕預設', en: 'Deep Default');
      case 'neutral_minimal':
        return _text(zhCn: '中性极简', zhHant: '中性極簡', en: 'Neutral Minimal');
      case 'material_you_light':
        return _text(
            zhCn: 'Material You', zhHant: 'Material You', en: 'Material You');
      case 'wechat_green':
        return _text(zhCn: '微信绿', zhHant: '微信綠', en: 'WeChat Green');
      case 'ink_black_white':
        return _text(zhCn: '墨水黑白', zhHant: '墨水黑白', en: 'Ink Black & White');
      default:
        return _text(zhCn: '暖灰默认', zhHant: '暖灰預設', en: 'Warm Default');
    }
  }

  String get allArticles =>
      _text(zhCn: '全部文章', zhHant: '全部文章', en: 'All Articles');
  String get sources => _text(zhCn: '订阅源', zhHant: '訂閱源', en: 'Sources');
  String get sourceArticles =>
      _text(zhCn: '来源文章', zhHant: '來源文章', en: 'Source Articles');
  String get bookmarksAndLater => _text(
        zhCn: '收藏与稍后读',
        zhHant: '收藏與稍後讀',
        en: 'Bookmarks & Later',
      );
  String get addSubscription => _text(
        zhCn: '添加订阅',
        zhHant: '添加訂閱',
        en: 'Add Subscription',
      );
  String get subscriptionManagement => _text(
        zhCn: '订阅管理',
        zhHant: '訂閱管理',
        en: 'Subscription Management',
      );
  String get subscriptionManagementIntro => _text(
        zhCn: '在这里集中管理订阅源。你可以添加、编辑、删除，并通过长按拖动调整顺序。',
        zhHant: '在這裡集中管理訂閱源。你可以添加、編輯、刪除，並透過長按拖動調整順序。',
        en: 'Manage sources here. Add, edit, remove, and long-press to reorder them.',
      );
  String get currentSubscriptionsHint => _text(
        zhCn: '长按右侧拖动柄可调整顺序，菜单里可以刷新、编辑或删除站点。',
        zhHant: '長按右側拖動柄可調整順序，選單裡可以重新整理、編輯或刪除站點。',
        en: 'Long-press the drag handle to reorder. Use the menu to refresh, edit, or delete a source.',
      );
  String get settings => _text(zhCn: '设置', zhHant: '設定', en: 'Settings');
  String get readerDetail =>
      _text(zhCn: '阅读详情', zhHant: '閱讀詳情', en: 'Reader Detail');
  String get starred => _text(zhCn: '收藏', zhHant: '收藏', en: 'Starred');
  String get savedForLater =>
      _text(zhCn: '稍后读', zhHant: '稍後讀', en: 'Read Later');
  String get home => _text(zhCn: '首页', zhHant: '首頁', en: 'Home');
  String get unlocked => _text(zhCn: '未锁定', zhHant: '未鎖定', en: 'Unlocked');
  String get localReader => _text(
        zhCn: '本地阅读器',
        zhHant: '本地閱讀器',
        en: 'Local Reader',
      );
  String get settingsIntro => _text(
        zhCn: '按分类管理同步、自动更新、通知、主题和显示方式。',
        zhHant: '按分類管理同步、自動更新、通知、主題和顯示方式。',
        en: 'Manage sync, automatic refresh, notifications, theme, and display preferences by category.',
      );
  String get settingsBack => _text(
        zhCn: '返回设置',
        zhHant: '返回設定',
        en: 'Back to Settings',
      );
  String get settingsAboutApp => _text(
        zhCn: '关于本应用',
        zhHant: '關於本應用',
        en: 'About This App',
      );
  String get settingsVersionLabel => _text(
        zhCn: '版本 ${AppBrand.version}',
        zhHant: '版本 ${AppBrand.version}',
        en: 'Version ${AppBrand.version}',
      );
  String get settingsAboutLicense => _text(
        zhCn: 'MIT 许可证',
        zhHant: 'MIT 許可證',
        en: 'MIT License',
      );
  String get settingsAboutRepo => _text(
        zhCn: '源代码仓库',
        zhHant: '原始碼倉庫',
        en: 'Source Repository',
      );
  String get settingsUpdateAvailable => _text(
        zhCn: '有新版本',
        zhHant: '有新版本',
        en: 'Update Available',
      );
  String get settingsCategorySyncAccount => _text(
        zhCn: '同步与账号',
        zhHant: '同步與帳號',
        en: 'Sync & Account',
      );
  String get settingsCategoryAi => _text(
        zhCn: 'AI',
        zhHant: 'AI',
        en: 'AI',
      );
  String get settingsCategoryAutoRefreshNotifications => _text(
        zhCn: '自动更新与通知',
        zhHant: '自動更新與通知',
        en: 'Refresh & Notifications',
      );
  String get settingsCategoryThemeDisplay => _text(
        zhCn: '主题与显示',
        zhHant: '主題與顯示',
        en: 'Theme & Display',
      );
  String get settingsCategoryAbout => _text(
        zhCn: '关于',
        zhHant: '關於',
        en: 'About',
      );
  String get settingsCategoryComingSoonTitle => _text(
        zhCn: '暂未开放',
        zhHant: '暫未開放',
        en: 'Not Available Yet',
      );
  String settingsCategoryComingSoonBody(String category) => _text(
        zhCn: '$category 入口已预留，后续版本再接入具体功能。',
        zhHant: '$category 入口已預留，後續版本再接入具體功能。',
        en: '$category is reserved for a future version.',
      );
  String get startupPage =>
      _text(zhCn: '启动页', zhHant: '啟動頁', en: 'Startup Page');
  String get visualTheme => _text(zhCn: '视觉主题', zhHant: '視覺主題', en: 'Theme');
  String get visualThemeHint => _text(
        zhCn: '选择主题预设，并决定是否跟随系统的明暗模式。',
        zhHant: '選擇主題預設，並決定是否跟隨系統的明暗模式。',
        en: 'Choose a theme preset and decide whether it follows the system appearance.',
      );
  String get articleDisplayMode =>
      _text(zhCn: '文章显示', zhHant: '文章顯示', en: 'Article Display');
  String get articleDisplayModeHint => _text(
        zhCn: '完整版保留图片和媒体占位，纯文本只显示段落与换行。',
        zhHant: '完整版保留圖片與媒體佔位，純文字只顯示段落與換行。',
        en: 'Rich mode keeps images and media placeholders. Text-only mode shows paragraphs and line breaks only.',
      );
  String get readerFontSizeTitle =>
      _text(zhCn: '正文字号', zhHant: '正文字級', en: 'Reading Font Size');
  String readerFontSizeLabel(ReaderFontSize size) {
    switch (size) {
      case ReaderFontSize.small:
        return _text(zhCn: '小', zhHant: '小', en: 'Small');
      case ReaderFontSize.medium:
        return _text(zhCn: '标准', zhHant: '標準', en: 'Medium');
      case ReaderFontSize.large:
        return _text(zhCn: '大', zhHant: '大', en: 'Large');
      case ReaderFontSize.xlarge:
        return _text(zhCn: '特大', zhHant: '特大', en: 'X-Large');
    }
  }

  String get readerLineHeightTitle =>
      _text(zhCn: '正文行距', zhHant: '正文行距', en: 'Line Spacing');
  String readerLineHeightLabel(ReaderLineHeight lineHeight) {
    switch (lineHeight) {
      case ReaderLineHeight.compact:
        return _text(zhCn: '紧凑', zhHant: '緊湊', en: 'Compact');
      case ReaderLineHeight.normal:
        return _text(zhCn: '标准', zhHant: '標準', en: 'Normal');
      case ReaderLineHeight.relaxed:
        return _text(zhCn: '宽松', zhHant: '寬鬆', en: 'Relaxed');
    }
  }

  String get readerContentWidthTitle =>
      _text(zhCn: '正文宽度', zhHant: '正文寬度', en: 'Content Width');
  String get readerContentWidthHint => _text(
        zhCn: '仅在桌面宽屏下生效，控制阅读区的最大宽度。',
        zhHant: '僅在桌面寬螢幕下生效，控制閱讀區的最大寬度。',
        en: 'Applies on wide desktop layouts only; limits the maximum width of the reading area.',
      );
  String readerContentWidthLabel(ReaderContentWidth width) {
    switch (width) {
      case ReaderContentWidth.narrow:
        return _text(zhCn: '窄', zhHant: '窄', en: 'Narrow');
      case ReaderContentWidth.medium:
        return _text(zhCn: '标准', zhHant: '標準', en: 'Medium');
      case ReaderContentWidth.wide:
        return _text(zhCn: '宽', zhHant: '寬', en: 'Wide');
    }
  }
  String get subscriptionNotificationModeTitle => _text(
        zhCn: '订阅通知方式',
        zhHant: '訂閱通知方式',
        en: 'Subscription Notifications',
      );
  String get subscriptionNotificationModeHint => _text(
        zhCn: '只针对自动更新带来的新文章生效。应用在前台时不会弹系统通知。',
        zhHant: '只針對自動更新帶來的新文章生效。應用在前景時不會彈出系統通知。',
        en: 'Only applies to new articles found by automatic refresh. System notifications are not shown while the app is in the foreground.',
      );
  String subscriptionNotificationModeLabel(
    SubscriptionNotificationMode mode,
  ) {
    switch (mode) {
      case SubscriptionNotificationMode.sourceSummary:
        return _text(zhCn: '按源汇总', zhHant: '按來源彙總', en: 'Group by Source');
      case SubscriptionNotificationMode.perArticle:
        return _text(zhCn: '逐篇通知', zhHant: '逐篇通知', en: 'Per Article');
      case SubscriptionNotificationMode.minimal:
        return _text(zhCn: '仅提示有更新', zhHant: '僅提示有更新', en: 'Update Only');
    }
  }

  String get mobileSidebar =>
      _text(zhCn: '移动端侧栏', zhHant: '移動端側欄', en: 'Mobile Sidebar');
  String get mobileWorkspaceLayout => _text(
        zhCn: '移动端首页与收藏布局',
        zhHant: '移動端首頁與收藏佈局',
        en: 'Mobile Home & Bookmarks Layout',
      );
  String get mobileWorkspaceLayoutHint => _text(
        zhCn: '只在手机和窄屏生效。可以保持现在的单栏文章流，或者切到桌面端那种多栏工作区。',
        zhHant: '只在手機和窄螢幕生效。可以保留目前的單欄文章流，或切到桌面端那種多欄工作區。',
        en: 'Applies only on phones and narrow screens. Keep the current single article flow or switch to the desktop-style multi-pane workspace.',
      );
  String get desktopWorkspaceLayout => _text(
        zhCn: '桌面端阅读布局',
        zhHant: '桌面端閱讀佈局',
        en: 'Desktop Reader Layout',
      );
  String get desktopWorkspaceLayoutHint => _text(
        zhCn: '三栏模式会把正文固定放在右侧。双栏模式会隐藏右侧阅读栏，点击文章后进入独立阅读页。',
        zhHant: '三欄模式會把正文固定放在右側。雙欄模式會隱藏右側閱讀欄，點擊文章後進入獨立閱讀頁。',
        en: 'Three-pane mode keeps the reader embedded on the right. Two-pane mode hides the reader pane and opens a dedicated reader page when an article is selected.',
      );
  String get desktopContentSurface => _text(
        zhCn: '桌面内容层级',
        zhHant: '桌面內容層級',
        en: 'Desktop Content Layers',
      );
  String get desktopContentSurfaceHint => _text(
        zhCn: '扁平模式会去掉内容区里作为背景板的大框，但保留文章、订阅源和控件本身的卡片层次。',
        zhHant: '扁平模式會去掉內容區裡作為背景板的大框，但保留文章、訂閱源和控制項本身的卡片層次。',
        en: 'Flat mode removes large background panels while keeping cards for articles, sources, and controls.',
      );
  String get searchArticlesOrSources => _text(
        zhCn: '搜索文章或源',
        zhHant: '搜尋文章或來源',
        en: 'Search articles or sources',
      );
  String get globalSearchIdleHint => _text(
        zhCn: '在全部来源和文章中搜寻...',
        zhHant: '在全部來源和文章中搜尋...',
        en: 'Search across all sources and articles...',
      );
  String get globalSearchNoResults => _text(
        zhCn: '没有找到匹配内容',
        zhHant: '沒有找到符合的內容',
        en: 'No matching results',
      );
  String get keyboardShortcutCtrlK => 'Ctrl+K';
  String get autoRefreshSettings => _text(
        zhCn: '自动更新订阅',
        zhHant: '自動更新訂閱',
        en: 'Automatic Subscription Refresh',
      );
  String get autoRefreshEnabledLabel => _text(
        zhCn: '开启自动更新订阅',
        zhHant: '開啟自動更新訂閱',
        en: 'Enable automatic subscription refresh',
      );
  String get autoRefreshSettingsHintWindows => _text(
        zhCn: 'Windows 开启后，关闭窗口会转入托盘常驻，并按订阅源配置定时刷新。',
        zhHant: 'Windows 開啟後，關閉視窗會轉入系統匣常駐，並依訂閱源設定定時刷新。',
        en: 'On Windows, closing the window keeps the app in the tray and refreshes enabled sources on schedule.',
      );
  String get autoRefreshSettingsHintAndroid => _text(
        zhCn: 'Android 会使用系统后台任务自动刷新，不显示常驻通知，实际执行时间可能会延后。',
        zhHant: 'Android 會使用系統背景任務自動刷新，不顯示常駐通知，實際執行時間可能延後。',
        en: 'Android uses system-managed background work without a persistent notification. Actual execution may be delayed.',
      );
  String get autoRefreshSettingsHintLinux => _text(
        zhCn: 'Linux 会在应用运行期间按订阅源配置定时刷新，并在发现新文章时发送系统通知。',
        zhHant: 'Linux 會在應用執行期間依訂閱源設定定時刷新，並在發現新文章時發送系統通知。',
        en: 'On Linux, the app refreshes enabled sources while it is running and sends system notifications when new articles are found.',
      );
  String get autoRefreshSettingsHintDefault => _text(
        zhCn: '自动刷新会根据当前平台支持情况运行，实际执行时机可能受系统限制。',
        zhHant: '自動刷新會依目前平台支援情況執行，實際執行時機可能受系統限制。',
        en: 'Automatic refresh runs when supported by the current platform. Actual timing may be limited by the system.',
      );
  String get autoRefreshDisabledNotice => _text(
        zhCn: '自动更新订阅未开启',
        zhHant: '自動更新訂閱尚未開啟',
        en: 'Automatic subscription refresh is turned off',
      );
  String get autoRefreshGoToSettings => _text(
        zhCn: '点击前往设置开启',
        zhHant: '點擊前往設定開啟',
        en: 'Tap to open Settings',
      );
  String get autoRefreshConfig => _text(
        zhCn: '自动更新',
        zhHant: '自動更新',
        en: 'Automatic Refresh',
      );
  String autoRefreshModeLabel(AutoRefreshMode mode) {
    switch (mode) {
      case AutoRefreshMode.allOff:
        return _text(zhCn: '全部关闭', zhHant: '全部關閉', en: 'All Off');
      case AutoRefreshMode.partial:
        return _text(zhCn: '部分开启', zhHant: '部分開啟', en: 'Partial');
      case AutoRefreshMode.allOn:
        return _text(zhCn: '全部开启', zhHant: '全部開啟', en: 'All On');
    }
  }

  String get autoRefreshSourceEnabled => _text(
        zhCn: '更新这个订阅源',
        zhHant: '更新這個訂閱源',
        en: 'Refresh this source automatically',
      );
  String get autoRefreshInterval => _text(
        zhCn: '更新间隔',
        zhHant: '更新間隔',
        en: 'Refresh interval',
      );
  String get autoRefreshSourceDisabledHint => _text(
        zhCn: '关闭后会保留当前间隔，但不会进入自动更新调度。',
        zhHant: '關閉後會保留目前間隔，但不會進入自動更新排程。',
        en: 'The saved interval stays in place, but this source stops participating in automatic refresh.',
      );
  String get autoRefreshPanelHint => _text(
        zhCn: '这里可以统一控制全部订阅源的自动更新方式。',
        zhHant: '這裡可以統一控制全部訂閱源的自動更新方式。',
        en: 'Control the automatic refresh mode for all subscriptions here.',
      );
  String get autoRefreshGlobalInterval => _text(
        zhCn: '全局更新间隔',
        zhHant: '全域更新間隔',
        en: 'Global refresh interval',
      );
  String get autoRefreshGlobalIntervalHint => _text(
        zhCn: '只在“全部开启”时生效，不会改写每个订阅源原本保存的间隔。',
        zhHant: '只在「全部開啟」時生效，不會改寫每個訂閱源原本保存的間隔。',
        en: 'Only applies in All On mode and does not overwrite per-source saved intervals.',
      );
  String get autoRefreshFollowGlobalHint => _text(
        zhCn: '当前已开启全部订阅源自动更新，更新间隔跟随全局设置。',
        zhHant: '目前已開啟全部訂閱源自動更新，更新間隔跟隨全域設定。',
        en: 'All subscriptions now follow the global automatic refresh interval.',
      );
  String autoRefreshGlobalSummary(int minutes) => _text(
        zhCn: '跟随全局：每 ${autoRefreshIntervalLabel(minutes)}',
        zhHant: '跟隨全域：每 ${autoRefreshIntervalLabel(minutes)}',
        en: 'Follow global: every ${autoRefreshIntervalLabel(minutes)}',
      );
  String get readingDensity =>
      _text(zhCn: '阅读密度', zhHant: '閱讀密度', en: 'Reading Density');
  String get interfaceLanguage =>
      _text(zhCn: '界面语言', zhHant: '介面語言', en: 'Interface Language');
  String get interfaceLanguageHint => _text(
        zhCn: '切换后立刻生效。跟随系统时，会在简体中文、繁体中文和 English 之间自动匹配。',
        zhHant: '切換後立刻生效。跟隨系統時，會在簡體中文、繁體中文和 English 之間自動匹配。',
        en: 'Changes apply immediately. Follow System picks Simplified Chinese, Traditional Chinese, or English automatically.',
      );
  String get desktopSidebarCollapsedTitle => _text(
        zhCn: '桌面端默认折叠侧栏',
        zhHant: '桌面端預設折疊側欄',
        en: 'Collapse Desktop Sidebar by Default',
      );
  String get desktopSidebarCollapsedHint => _text(
        zhCn: '给文章列表和阅读区让出更多空间。',
        zhHant: '讓文章列表和閱讀區獲得更多空間。',
        en: 'Leave more room for the list and reader.',
      );
  String get blurEffectsTitle => _text(
        zhCn: '界面模糊效果',
        zhHant: '介面模糊效果',
        en: 'Interface Blur Effects',
      );
  String get blurEffectsSwitchLabel => _text(
        zhCn: '开启界面模糊',
        zhHant: '開啟介面模糊',
        en: 'Enable interface blur',
      );
  String get blurEffectsHint => _text(
        zhCn: '用于阅读顶栏等半透明区域。关闭后会改用更稳定的实色背景。',
        zhHant: '用於閱讀頂欄等半透明區域。關閉後會改用更穩定的實色背景。',
        en: 'Used by translucent areas such as the reader toolbar. Turn it off to use steadier solid surfaces.',
      );

  String visibleArticleCount(int count) => _text(
        zhCn: '$count 篇可见文章',
        zhHant: '$count 篇可見文章',
        en: '$count visible article${count == 1 ? '' : 's'}',
      );

  String unreadCountStat(int count) => _text(
        zhCn: '$count 未读',
        zhHant: '$count 未讀',
        en: '$count unread',
      );

  String get refreshCurrentView => _text(
        zhCn: '刷新当前视图',
        zhHant: '重新整理目前視圖',
        en: 'Refresh Current View',
      );
  String get noReadableSummary => _text(
        zhCn: '这篇文章暂时没有可读摘要，可以直接打开原文。',
        zhHant: '這篇文章暫時沒有可讀摘要，可以直接打開原文。',
        en: 'No readable summary is available yet. Open the original page instead.',
      );
  String get emptyArticleListTitle =>
      _text(zhCn: '这里还没有文章', zhHant: '這裡還沒有文章', en: 'No Articles Yet');
  String get emptyArticleListBody => _text(
        zhCn: '先添加订阅源，或者放宽当前筛选条件。',
        zhHant: '先添加訂閱源，或放寬目前的篩選條件。',
        en: 'Add a subscription first, or loosen the current filters.',
      );

  String starAction(bool value) => value
      ? _text(zhCn: '取消收藏', zhHant: '取消收藏', en: 'Remove Star')
      : _text(zhCn: '收藏', zhHant: '收藏', en: 'Star');

  String readLaterAction(bool value) => value
      ? _text(zhCn: '取消稍后读', zhHant: '取消稍後讀', en: 'Remove from Later')
      : _text(zhCn: '稍后读', zhHant: '稍後讀', en: 'Read Later');

  String get readLaterDoneAction =>
      _text(zhCn: '已读', zhHant: '已讀', en: 'Done Reading');

  String readStateAction(bool isRead) => isRead
      ? _text(zhCn: '标为未读', zhHant: '標為未讀', en: 'Mark Unread')
      : _text(zhCn: '标为已读', zhHant: '標為已讀', en: 'Mark Read');

  String get openOriginal =>
      _text(zhCn: '打开原文', zhHant: '打開原文', en: 'Open Original');
  String estimatedReadingTime(int minutes) => _text(
        zhCn: '$minutes 分钟阅读',
        zhHant: '$minutes 分鐘閱讀',
        en: '$minutes min read',
      );
  String get noReadableBody => _text(
        zhCn: '这篇文章没有可直接显示的正文或摘要，可以打开原文继续阅读。',
        zhHant: '這篇文章沒有可直接顯示的正文或摘要，可以打開原文繼續閱讀。',
        en: 'This article has no readable body or summary to display directly.',
      );
  String get emptyReaderTitle => _text(
        zhCn: '点开一篇文章，阅读区会在这里安静展开。',
        zhHant: '點開一篇文章，閱讀區會在這裡安靜展開。',
        en: 'Open any article and the reader will expand here.',
      );
  String get addSourceTitle =>
      _text(zhCn: '添加订阅源', zhHant: '添加訂閱源', en: 'Add Source');
  String get feedUrlLabel => _text(
      zhCn: 'RSS / Atom 地址', zhHant: 'RSS / Atom 位址', en: 'RSS / Atom URL');
  String get feedUrlHint => 'https://example.com/feed.xml';
  String get enterFeedAddress => _text(
        zhCn: '请输入订阅地址',
        zhHant: '請輸入訂閱位址',
        en: 'Enter a subscription URL',
      );
  String get displayName =>
      _text(zhCn: '显示名称', zhHant: '顯示名稱', en: 'Display Name');
  String get displayNameHint => _text(
        zhCn: '留空时自动使用订阅标题',
        zhHant: '留空時自動使用訂閱標題',
        en: 'Leave empty to use the feed title automatically',
      );
  String get addNow => _text(zhCn: '立即添加', zhHant: '立即添加', en: 'Add Now');
  String get currentSubscriptions => _text(
        zhCn: '当前已有订阅',
        zhHant: '目前已有訂閱',
        en: 'Current Subscriptions',
      );
  String get noSubscriptionsYet => _text(
        zhCn: '还没有订阅源，先从最常看的站点开始。',
        zhHant: '還沒有訂閱源，先從最常看的站點開始。',
        en: 'There are no sources yet. Start with the sites you read most often.',
      );
  String get sourcesAndFilters => _text(
        zhCn: '来源与筛选',
        zhHant: '來源與篩選',
        en: 'Sources & Filters',
      );
  String get bookmarksAndFilters => _text(
        zhCn: '收藏与筛选',
        zhHant: '收藏與篩選',
        en: 'Bookmarks & Filters',
      );
  String get sourceFilterHintTitle => _text(
        zhCn: '先按来源筛一层，再进文章会更清楚。',
        zhHant: '先按來源篩一層，再進文章會更清楚。',
        en: 'Filter by source first so the next step stays clear.',
      );
  String get sourceFilterHintBody => _text(
        zhCn: '默认是全部文章，也可以随时切到单个站点。',
        zhHant: '預設是全部文章，也可以隨時切到單個站點。',
        en: 'The default is All Articles, but you can narrow down to one site.',
      );
  String get refreshAll =>
      _text(zhCn: '刷新全部', zhHant: '重新整理全部', en: 'Refresh All');
  String get unreadOnly => _text(zhCn: '仅未读', zhHant: '僅未讀', en: 'Unread Only');
  String get allSources =>
      _text(zhCn: '全部来源', zhHant: '全部來源', en: 'All Sources');
  String get editSource =>
      _text(zhCn: '编辑订阅源', zhHant: '編輯訂閱源', en: 'Edit Source');
  String get update => _text(zhCn: '更新', zhHant: '更新', en: 'Update');
  String get deleteSource =>
      _text(zhCn: '删除订阅源', zhHant: '刪除訂閱源', en: 'Delete Source');

  String deleteSourceConfirm(String title) => _text(
        zhCn: '确认删除 $title 吗？对应文章缓存也会一起移除。',
        zhHant: '確認刪除 $title 嗎？對應文章快取也會一起移除。',
        en: 'Delete $title? Its cached articles will be removed as well.',
      );

  String get refresh => _text(zhCn: '刷新', zhHant: '重新整理', en: 'Refresh');
  String get edit => _text(zhCn: '编辑', zhHant: '編輯', en: 'Edit');
  String get delete => _text(zhCn: '删除', zhHant: '刪除', en: 'Delete');
  String get cancel => _text(zhCn: '取消', zhHant: '取消', en: 'Cancel');
  String get save => _text(zhCn: '保存', zhHant: '儲存', en: 'Save');
  String get feedTitleAutoHint => _text(
        zhCn: '留空时会自动使用订阅标题',
        zhHant: '留空時會自動使用訂閱標題',
        en: 'Leave empty to use the feed title automatically',
      );
  String get feedUrlExample => _text(
        zhCn: '例如 https://example.com/feed.xml',
        zhHant: '例如 https://example.com/feed.xml',
        en: 'For example https://example.com/feed.xml',
      );
  String get emptySourcePanel => _text(
        zhCn: '先添加一个订阅源，文章列表才会开始生长。',
        zhHant: '先添加一個訂閱源，文章列表才會開始出現。',
        en: 'Add at least one source before the article list can start growing.',
      );

  String sourceStats(int count, int unread) {
    if (_language == _AppTextLanguage.en) {
      return unread > 0
          ? '$count article${count == 1 ? '' : 's'} · $unread unread'
          : '$count article${count == 1 ? '' : 's'}';
    }
    return unread > 0 ? '$count 篇文章 · $unread 未读' : '$count 篇文章';
  }

  String autoRefreshIntervalLabel(int minutes) {
    switch (minutes) {
      case 15:
        return _text(zhCn: '15 分钟', zhHant: '15 分鐘', en: '15 min');
      case 30:
        return _text(zhCn: '30 分钟', zhHant: '30 分鐘', en: '30 min');
      case 60:
        return _text(zhCn: '1 小时', zhHant: '1 小時', en: '1 hour');
      case 180:
        return _text(zhCn: '3 小时', zhHant: '3 小時', en: '3 hours');
      case 360:
        return _text(zhCn: '6 小时', zhHant: '6 小時', en: '6 hours');
      case 720:
        return _text(zhCn: '12 小时', zhHant: '12 小時', en: '12 hours');
      case 1440:
        return _text(zhCn: '1 天', zhHant: '1 天', en: '1 day');
      case 4320:
        return _text(zhCn: '3 天', zhHant: '3 天', en: '3 days');
      case 10080:
        return _text(zhCn: '7 天', zhHant: '7 天', en: '7 days');
      default:
        return _language == _AppTextLanguage.en
            ? '$minutes min'
            : '$minutes 分钟';
    }
  }

  String autoRefreshIntervalSummary(int minutes) => _text(
        zhCn: '自动更新：每 ${autoRefreshIntervalLabel(minutes)}',
        zhHant: '自動更新：每 ${autoRefreshIntervalLabel(minutes)}',
        en: 'Auto refresh: every ${autoRefreshIntervalLabel(minutes)}',
      );

  String get trayShowWindow => _text(
        zhCn: '显示主窗口',
        zhHant: '顯示主視窗',
        en: 'Show Window',
      );
  String get trayRefreshDueFeeds => _text(
        zhCn: '立即刷新到期订阅',
        zhHant: '立即刷新到期訂閱',
        en: 'Refresh Due Subscriptions',
      );
  String get trayExitApp => _text(
        zhCn: '退出应用',
        zhHant: '退出應用',
        en: 'Exit App',
      );

  String initializationFailed(Object error) => _text(
        zhCn: '初始化本地数据失败：$error',
        zhHant: '初始化本地資料失敗：$error',
        en: 'Failed to initialize local data: $error',
      );

  String get duplicateFeedAddress => _text(
        zhCn: '这个订阅地址已经存在',
        zhHant: '這個訂閱位址已經存在',
        en: 'This subscription URL already exists',
      );

  String get updatingFeedAddressInUse => _text(
        zhCn: '另一个订阅源已经在使用这个地址',
        zhHant: '另一個訂閱源已經在使用這個位址',
        en: 'Another source is already using this URL',
      );

  String get addingSubscription => _text(
        zhCn: '正在添加订阅源...',
        zhHant: '正在添加訂閱源...',
        en: 'Adding source...',
      );

  String addedFeed(String title) => _text(
        zhCn: '已添加订阅：$title',
        zhHant: '已添加訂閱：$title',
        en: 'Added source: $title',
      );

  String get updatingSubscription => _text(
        zhCn: '正在更新订阅源...',
        zhHant: '正在更新訂閱源...',
        en: 'Updating source...',
      );

  String updatedFeed(String title) => _text(
        zhCn: '已更新订阅：$title',
        zhHant: '已更新訂閱：$title',
        en: 'Updated source: $title',
      );

  String removedFeed(String title) => _text(
        zhCn: '已删除订阅：$title',
        zhHant: '已刪除訂閱：$title',
        en: 'Deleted source: $title',
      );

  String get noRefreshableFeeds => _text(
        zhCn: '还没有可刷新的订阅源',
        zhHant: '還沒有可重新整理的訂閱源',
        en: 'There are no sources to refresh yet',
      );

  String get refreshingAllFeeds => _text(
        zhCn: '正在刷新全部订阅...',
        zhHant: '正在重新整理全部訂閱...',
        en: 'Refreshing all sources...',
      );

  String refreshedAllFeeds(int count) => _text(
        zhCn: '刷新完成，共处理 $count 个订阅源',
        zhHant: '重新整理完成，共處理 $count 個訂閱源',
        en: 'Refresh complete. Processed $count source${count == 1 ? '' : 's'}.',
      );

  String refreshingFeed(String title) => _text(
        zhCn: '正在刷新 $title...',
        zhHant: '正在重新整理 $title...',
        en: 'Refreshing $title...',
      );

  String refreshedFeed(String title) => _text(
        zhCn: '已刷新 $title',
        zhHant: '已重新整理 $title',
        en: 'Refreshed $title',
      );

  String get unknownSource => _text(
        zhCn: '未知来源',
        zhHant: '未知來源',
        en: 'Unknown Source',
      );

  String get subscriptionAddressRequired => _text(
        zhCn: '订阅地址不能为空',
        zhHant: '訂閱位址不能為空',
        en: 'Subscription URL cannot be empty',
      );
  String get homeTab => _text(zhCn: '首页', zhHant: '首頁', en: 'Home');
  String get bookmarksTab => _text(zhCn: '收藏', zhHant: '收藏', en: 'Bookmarks');
  String get subscriptionsTab =>
      _text(zhCn: '订阅', zhHant: '訂閱', en: 'Subscriptions');
  String get settingsTab => _text(zhCn: '设置', zhHant: '設定', en: 'Settings');
  String get wideMobileNavigation => _text(
        zhCn: '宽屏移动端导航',
        zhHant: '寬屏移動端導覽',
        en: 'Wide Mobile Navigation',
      );
  String get wideMobileNavigationHint => _text(
        zhCn: '仅影响宽屏手机、横屏和 Pad；手机版窄屏固定使用底部导航。',
        zhHant: '僅影響寬屏手機、橫屏和 Pad；手機版窄屏固定使用底部導覽。',
        en: 'Only affects wide phones, landscape, and tablets. Narrow phone layouts always use bottom navigation.',
      );
  String get accountPageTitle => _text(
        zhCn: 'Resonance 账号',
        zhHant: 'Resonance 帳號',
        en: 'Resonance Account',
      );
  String get accountSignedOutHint => _text(
        zhCn: '先生成一个身份代码，或输入你已有的代码。现在先只保存在本机，后面会为云服务预留接口。',
        zhHant: '先產生一個身分代碼，或輸入你已有的代碼。現在先只保存在本機，後面會為雲服務預留介面。',
        en: 'Generate an identity code or enter one you already have. This version keeps everything local and reserves space for future cloud services.',
      );
  String get accountGenerateCode => _text(
        zhCn: '生成用户代码',
        zhHant: '產生使用者代碼',
        en: 'Generate My Code',
      );
  String get accountEnterCode => _text(
        zhCn: '输入我的代码',
        zhHant: '輸入我的代碼',
        en: 'Enter My Code',
      );
  String get accountApplyIdentityCode => _text(
        zhCn: '保存并应用',
        zhHant: '儲存並套用',
        en: 'Save and Apply',
      );
  String get accountIdentityCodeLabel => _text(
        zhCn: '身份代码',
        zhHant: '身分代碼',
        en: 'Identity Code',
      );
  String get accountIdentityCodeHint => _text(
        zhCn: '输入 14 位字母或数字',
        zhHant: '輸入 14 位字母或數字',
        en: 'Enter 14 letters or numbers',
      );
  String get accountIdentityCodeInvalid => _text(
        zhCn: '身份代码格式不对，需要正好 14 位字母或数字。',
        zhHant: '身分代碼格式不正確，需要剛好 14 位字母或數字。',
        en: 'The identity code must be exactly 14 letters or numbers.',
      );
  String get accountIdentityCodeCopied => _text(
        zhCn: '身份代码已复制',
        zhHant: '身分代碼已複製',
        en: 'Identity code copied',
      );
  String get accountCopyIdentityCode => _text(
        zhCn: '复制身份代码',
        zhHant: '複製身分代碼',
        en: 'Copy identity code',
      );
  String get accountUnnamedUser => _text(
        zhCn: '未命名用户',
        zhHant: '未命名使用者',
        en: 'Unnamed User',
      );
  String get accountGeneratedAndSignedIn => _text(
        zhCn: '用户代码已生成，已经切换到这个身份。',
        zhHant: '使用者代碼已產生，已經切換到這個身分。',
        en: 'Your identity code is ready and this profile is now active.',
      );
  String get accountSignedIn => _text(
        zhCn: '身份代码已应用。',
        zhHant: '身分代碼已套用。',
        en: 'Identity code applied.',
      );
  String get accountSignedOut => _text(
        zhCn: '已退出当前身份。',
        zhHant: '已退出目前身分。',
        en: 'Signed out of the current identity.',
      );
  String get accountDisplayNameLabel => _text(
        zhCn: '用户名',
        zhHant: '使用者名稱',
        en: 'User Name',
      );
  String get accountDisplayNameHint => _text(
        zhCn: '给这个身份起一个名字',
        zhHant: '替這個身分取一個名字',
        en: 'Name this identity',
      );
  String get accountEditDisplayName => _text(
        zhCn: '修改用户名',
        zhHant: '修改使用者名稱',
        en: 'Edit User Name',
      );
  String get accountDisplayNameUpdated => _text(
        zhCn: '用户名已更新。',
        zhHant: '使用者名稱已更新。',
        en: 'User name updated.',
      );
  String get accountAvatarLabel => _text(
        zhCn: '头像',
        zhHant: '頭像',
        en: 'Avatar',
      );
  String get accountAvatarHint => _text(
        zhCn: '选一张图片，会自动从中间裁成 1:1。',
        zhHant: '選一張圖片，會自動從中間裁成 1:1。',
        en: 'Choose an image and it will be auto-cropped to 1:1 from the center.',
      );
  String get accountChangeAvatar => _text(
        zhCn: '更换头像',
        zhHant: '更換頭像',
        en: 'Change Avatar',
      );
  String get accountAvatarUpdated => _text(
        zhCn: '头像已更新。',
        zhHant: '頭像已更新。',
        en: 'Avatar updated.',
      );
  String get accountAvatarUnsupported => _text(
        zhCn: '这张图片暂时没法处理，请换一张常见格式的图片。',
        zhHant: '這張圖片暫時無法處理，請換一張常見格式的圖片。',
        en: 'This image could not be processed. Please choose a common image format.',
      );
  String get accountPersonalInfoTitle => _text(
        zhCn: '个人信息',
        zhHant: '個人資訊',
        en: 'Personal Info',
      );
  String get accountPersonalInfoHint => _text(
        zhCn: '这里只管理你当前身份的用户名、头像和身份代码。',
        zhHant: '這裡只管理你目前身分的使用者名稱、頭像和身分代碼。',
        en: 'Manage the name, avatar, and identity code of the current profile here.',
      );
  String get accountCloudServiceTitle => _text(
        zhCn: '云服务',
        zhHant: '雲服務',
        en: 'Cloud Services',
      );
  String get accountCloudServiceHint => _text(
        zhCn: '这一块先预留给后续同步和远程能力。',
        zhHant: '這一塊先預留給後續同步和遠端能力。',
        en: 'This section is reserved for future sync and remote capabilities.',
      );
  String get accountCloudServiceReserved => _text(
        zhCn: '云服务接口暂未接入。这一版只管理本地身份档案，后续再把同步和远程能力接进来。',
        zhHant: '雲服務介面暫未接入。這一版只管理本地身分檔案，後續再把同步和遠端能力接進來。',
        en: 'Cloud services are not connected yet. This version manages a local identity profile and leaves room for future sync.',
      );
  String get accountSignOut => _text(
        zhCn: '退出当前身份',
        zhHant: '退出目前身分',
        en: 'Sign Out',
      );
  String get accountIdentityCodeGenerationFailed => _text(
        zhCn: '连续生成了多次都撞上已有代码，请再试一次。',
        zhHant: '連續產生多次都碰上已有代碼，請再試一次。',
        en: 'Several generated codes were already in use. Please try again.',
      );
  String get accountSignedOutHintCloud => _text(
        zhCn: '生成用户代码会直接注册到折纸云。输入已有代码时，会先到折纸云校验，存在才允许登录。',
        zhHant: '產生使用者代碼後會直接註冊到折紙雲。輸入已有代碼時，會先到折紙雲驗證，存在才允許登入。',
        en: 'Generating a code will register it with Origami Cloud. Entering an existing code first checks the cloud and only signs in if it exists.',
      );
  String get accountGeneratedAndSignedInCloud => _text(
        zhCn: '用户代码已创建并注册到折纸云，当前身份已登录。',
        zhHant: '使用者代碼已建立並註冊到折紙雲，目前身分已登入。',
        en: 'Your identity code was created, registered with Origami Cloud, and is now active.',
      );
  String get accountSignedInCloud => _text(
        zhCn: '身份代码校验通过，当前身份已登录。',
        zhHant: '身分代碼驗證通過，目前身分已登入。',
        en: 'Identity code verified. This profile is now active.',
      );
  String get accountDisplayNameUpdatedCloud => _text(
        zhCn: '用户名已更新并同步到折纸云。',
        zhHant: '使用者名稱已更新並同步到折紙雲。',
        en: 'User name updated and synced to Origami Cloud.',
      );
  String get accountCloudServiceHintOfficial => _text(
        zhCn: '这里只接官方折纸云。手动上传会用本地覆盖云端，手动下载会用云端覆盖本地。',
        zhHant: '這裡只接官方折紙雲。手動上傳會用本機覆蓋雲端，手動下載會用雲端覆蓋本機。',
        en: 'This section connects only to the official Origami Cloud. Upload overwrites the cloud with local data, and download overwrites local data with the cloud copy.',
      );
  String get accountCloudServiceBodyOfficial => _text(
        zhCn: '当前会显示连接状态、最近同步结果，以及手动上传和下载入口。',
        zhHant: '目前會顯示連線狀態、最近同步結果，以及手動上傳和下載入口。',
        en: 'This section shows the connection state, the latest sync result, and manual upload/download actions.',
      );
  String get accountIdentityCodeGenerationFailedCloud => _text(
        zhCn: '连续生成了多次都遇到已存在的身份代码，请再试一次。',
        zhHant: '連續產生多次都遇到已存在的身分代碼，請再試一次。',
        en: 'Several generated codes were already registered. Please try again.',
      );
  String get accountIdentityCodeNotFound => _text(
        zhCn: '这个身份代码在折纸云里不存在，暂时不能登录。',
        zhHant: '這個身分代碼在折紙雲裡不存在，暫時不能登入。',
        en: 'This identity code does not exist in Origami Cloud.',
      );
  String get accountCloudUnavailable => _text(
        zhCn: '当前构建还没有接入官方折纸云，请在打包时注入官方云地址。',
        zhHant: '目前這個建置還沒有接入官方折紙雲，請在打包時注入官方雲位址。',
        en: 'This build is not connected to the official Origami Cloud. Inject the cloud endpoint at build time.',
      );
  String get accountCloudConnectionFailed => _text(
        zhCn: '暂时连不上折纸云，请稍后再试。',
        zhHant: '暫時連不上折紙雲，請稍後再試。',
        en: 'The app could not reach Origami Cloud. Please try again later.',
      );
  String get accountUserNameSyncFailed => _text(
        zhCn: '用户名已经改到本地，但同步到折纸云失败了。',
        zhHant: '使用者名稱已改到本機，但同步到折紙雲失敗了。',
        en: 'The user name was updated locally, but syncing it to Origami Cloud failed.',
      );
  String get accountCloudUploadFailed => _text(
        zhCn: '上传到折纸云失败了，本地内容没有动。',
        zhHant: '上傳到折紙雲失敗了，本機內容沒有變動。',
        en: 'Uploading to Origami Cloud failed. Local data was left unchanged.',
      );
  String get accountCloudDownloadFailed => _text(
        zhCn: '从折纸云下载失败了，本地内容没有被覆盖。',
        zhHant: '從折紙雲下載失敗了，本機內容沒有被覆蓋。',
        en: 'Downloading from Origami Cloud failed. Local data was not overwritten.',
      );
  String get accountCloudRegistrationCompleted => _text(
        zhCn: '身份代码已经注册到折纸云。',
        zhHant: '身分代碼已經註冊到折紙雲。',
        en: 'The identity code has been registered with Origami Cloud.',
      );
  String get accountCloudLoginLoaded => _text(
        zhCn: '已从折纸云读取当前身份信息。',
        zhHant: '已從折紙雲讀取目前身分資料。',
        en: 'Loaded the current profile from Origami Cloud.',
      );
  String get accountCloudUploadCompleted => _text(
        zhCn: '当前订阅、文章和头像已上传到折纸云。',
        zhHant: '目前的訂閱、文章和頭像已上傳到折紙雲。',
        en: 'Subscriptions, articles, and avatar were uploaded to Origami Cloud.',
      );
  String get accountCloudDownloadCompleted => _text(
        zhCn: '折纸云里的内容已经下载到本地。',
        zhHant: '折紙雲裡的內容已經下載到本機。',
        en: 'Data from Origami Cloud was downloaded to this device.',
      );
  String get accountCloudOfficialName => _text(
        zhCn: '官方折纸云',
        zhHant: '官方折紙雲',
        en: 'Official Origami Cloud',
      );
  String accountCloudConnected(String endpoint) => _text(
        zhCn: '当前连接：$endpoint',
        zhHant: '目前連線：$endpoint',
        en: 'Connected to: $endpoint',
      );
  String get accountCloudUploadAction => _text(
        zhCn: '上传到折纸云',
        zhHant: '上傳到折紙雲',
        en: 'Upload to Origami Cloud',
      );
  String get accountCloudDownloadAction => _text(
        zhCn: '从折纸云下载',
        zhHant: '從折紙雲下載',
        en: 'Download from Origami Cloud',
      );
  String get accountCloudStatusIdle => _text(
        zhCn: '还没有执行过手动同步。',
        zhHant: '還沒有執行過手動同步。',
        en: 'No manual cloud sync has run yet.',
      );
  String get accountCloudStatusSynced => _text(
        zhCn: '最近一次云同步成功。',
        zhHant: '最近一次雲端同步成功。',
        en: 'The latest cloud sync completed successfully.',
      );
  String get accountCloudStatusFailed => _text(
        zhCn: '最近一次云同步没有成功。',
        zhHant: '最近一次雲端同步沒有成功。',
        en: 'The latest cloud sync did not finish successfully.',
      );
  String accountCloudLastSync(String time) => _text(
        zhCn: '最近同步：$time',
        zhHant: '最近同步：$time',
        en: 'Last sync: $time',
      );
  String get accountGeneratedOfflinePending => _text(
        zhCn: '当前离线，身份代码已经先保存在本地，联网后会自动注册到折纸云。',
        zhHant: '目前離線，身分代碼已先保存在本機，連網後會自動註冊到折紙雲。',
        en: 'You are offline. The identity code was saved locally and will register with Origami Cloud once the app is back online.',
      );
  String get accountCloudCreatePending => _text(
        zhCn: '这个身份还没有注册到折纸云，联网后会自动补传。',
        zhHant: '這個身分還沒有註冊到折紙雲，連網後會自動補傳。',
        en: 'This identity is not registered with Origami Cloud yet. It will sync automatically when the network is back.',
      );
  String get accountAvatarPendingSync => _text(
        zhCn: '头像已经更新到本地，联网后会自动同步到折纸云。',
        zhHant: '頭像已更新到本機，連網後會自動同步到折紙雲。',
        en: 'The avatar was updated locally and will sync to Origami Cloud automatically when online.',
      );
  String get accountCloudAutoSyncCompleted => _text(
        zhCn: '检测到联网，账号资料已经自动同步到折纸云。',
        zhHant: '偵測到連網後，帳號資料已自動同步到折紙雲。',
        en: 'The app is back online and account details were synced to Origami Cloud automatically.',
      );
  String get accountCloudAutoSyncPending => _text(
        zhCn: '账号资料还没同步完成，应用会在下次联网后继续补传。',
        zhHant: '帳號資料還沒同步完成，應用會在下次連網後繼續補傳。',
        en: 'Account details are still waiting to sync. The app will retry automatically the next time it can reach the cloud.',
      );
}

extension AppStringsBuildContextX on BuildContext {
  AppStrings get strings => AppStrings.of(this);
}
