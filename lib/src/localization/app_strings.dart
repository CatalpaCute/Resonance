import 'package:flutter/widgets.dart';

import '../models/app_route.dart';
import '../models/article.dart';
import '../models/reader_settings.dart';
import 'app_language.dart';

class AppBrand {
  static const String mark = 'R';
  static const String nameZhCn = '回声';
  static const String nameZhHant = '回聲';
  static const String nameEn = 'Resonance';
  static const String fullName = 'Resonance';
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
        return addSubscription;
      case AppRouteId.settings:
        return settings;
      case AppRouteId.readerDetail:
        return selectedArticleTitle ?? readerDetail;
    }
  }

  String routeSubtitle(AppRouteId route, {required bool compact}) {
    switch (route) {
      case AppRouteId.allArticles:
        return compact
            ? _text(
                zhCn: '先扫一遍时间流，再点进文章阅读。',
                zhHant: '先掃一遍時間流，再點進文章閱讀。',
                en: 'Scan the timeline first, then open an article.',
              )
            : _text(
                zhCn: '把订阅内容摊开在一张画布里，方便连贯浏览。',
                zhHant: '把訂閱內容攤開在一張畫布裡，方便連貫瀏覽。',
                en: 'Keep the reading flow on one calm canvas.',
              );
      case AppRouteId.sources:
      case AppRouteId.sourceDetail:
        return compact
            ? _text(
                zhCn: '先看订阅源，再进入文章。',
                zhHant: '先看訂閱源，再進入文章。',
                en: 'Manage sources first, then open articles.',
              )
            : _text(
                zhCn: '左边筛来源，中间扫列表，右边进正文。',
                zhHant: '左邊篩來源，中間掃列表，右邊進正文。',
                en: 'Filter on the left, skim in the middle, read on the right.',
              );
      case AppRouteId.bookmarks:
        return _text(
          zhCn: '把收藏和稍后读收拢到同一个长期阅读箱里。',
          zhHant: '把收藏和稍後讀收攏到同一個長期閱讀箱裡。',
          en: 'Keep starred and later items in one long-term queue.',
        );
      case AppRouteId.discoverAddSource:
        return _text(
          zhCn: '先把订阅源补齐，本地阅读流才会顺起来。',
          zhHant: '先把訂閱源補齊，本地閱讀流才會順起來。',
          en: 'Fill in your sources first so the reader can get moving.',
        );
      case AppRouteId.settings:
        return _text(
          zhCn: '这里管理启动页、主题、语言和移动端导航。',
          zhHant: '這裡管理啟動頁、主題、語言和移動端導航。',
          en: 'Manage startup behavior, theme, language, and mobile navigation.',
        );
      case AppRouteId.readerDetail:
        return _text(
          zhCn: '正文阅读优先保留干净版面和就近操作。',
          zhHant: '正文閱讀優先保留乾淨版面和就近操作。',
          en: 'Keep the reading view clean and the actions close at hand.',
        );
    }
  }

  String startupSummary(StartupHomeMode mode) {
    switch (mode) {
      case StartupHomeMode.allArticles:
        return _text(
          zhCn: '启动后优先进入全部文章',
          zhHant: '啟動後優先進入全部文章',
          en: 'Open All Articles on startup',
        );
      case StartupHomeMode.sources:
        return _text(
          zhCn: '启动后优先进入订阅源',
          zhHant: '啟動後優先進入訂閱源',
          en: 'Open Sources on startup',
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
        return allArticles;
      case StartupHomeMode.sources:
        return sources;
      case StartupHomeMode.bookmarks:
        return bookmarksAndLater;
    }
  }

  String startupDesc(StartupHomeMode mode) {
    switch (mode) {
      case StartupHomeMode.allArticles:
        return _text(
          zhCn: '适合快速扫一遍时间流。',
          zhHant: '適合快速掃一遍時間流。',
          en: 'Best for sweeping through the timeline quickly.',
        );
      case StartupHomeMode.sources:
        return _text(
          zhCn: '适合先按站点整理，再进入文章。',
          zhHant: '適合先按站點整理，再進入文章。',
          en: 'Best when you prefer to organize sites first.',
        );
      case StartupHomeMode.bookmarks:
        return _text(
          zhCn: '适合把阅读器当成长期收藏箱。',
          zhHant: '適合把閱讀器當成長期收藏箱。',
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
        return _text(zhCn: '窄轨常驻', zhHant: '窄軌常駐', en: 'Rail');
    }
  }

  String mobileSidebarDesc(MobileSidebarMode mode) {
    switch (mode) {
      case MobileSidebarMode.adaptive:
        return _text(
          zhCn: '小屏抽屉，大屏窄轨，默认最稳。',
          zhHant: '小屏抽屜，大屏窄軌，預設最穩。',
          en: 'Drawer on small screens and rail on wider screens.',
        );
      case MobileSidebarMode.drawer:
        return _text(
          zhCn: '始终通过抽屉打开左侧栏。',
          zhHant: '始終透過抽屜打開左側欄。',
          en: 'Always open navigation as a drawer.',
        );
      case MobileSidebarMode.rail:
        return _text(
          zhCn: '始终保留一条窄轨，布局更统一。',
          zhHant: '始終保留一條窄軌，佈局更統一。',
          en: 'Always keep a slim rail visible.',
        );
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

  String get allArticles =>
      _text(zhCn: '全部文章', zhHant: '全部文章', en: 'All Articles');
  String get sources =>
      _text(zhCn: '订阅源', zhHant: '訂閱源', en: 'Sources');
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
  String get settings =>
      _text(zhCn: '设置', zhHant: '設定', en: 'Settings');
  String get readerDetail =>
      _text(zhCn: '阅读详情', zhHant: '閱讀詳情', en: 'Reader Detail');
  String get starred =>
      _text(zhCn: '收藏', zhHant: '收藏', en: 'Starred');
  String get savedForLater =>
      _text(zhCn: '稍后读', zhHant: '稍後讀', en: 'Read Later');
  String get home => _text(zhCn: '首页', zhHant: '首頁', en: 'Home');
  String get unlocked =>
      _text(zhCn: '未锁定', zhHant: '未鎖定', en: 'Unlocked');
  String get localReader => _text(
        zhCn: '本地阅读器',
        zhHant: '本地閱讀器',
        en: 'Local Reader',
      );
  String get settingsIntro => _text(
        zhCn: '这里先收好启动页、主题、语言和侧栏行为，后面再接同步层。',
        zhHant: '這裡先收好啟動頁、主題、語言和側欄行為，後面再接同步層。',
        en: 'Tune startup, theme, language, and navigation before sync comes online.',
      );
  String get startupPage =>
      _text(zhCn: '启动页', zhHant: '啟動頁', en: 'Startup Page');
  String get visualTheme =>
      _text(zhCn: '视觉主题', zhHant: '視覺主題', en: 'Theme');
  String get mobileSidebar =>
      _text(zhCn: '移动端左侧栏', zhHant: '移動端左側欄', en: 'Mobile Sidebar');
  String get readingDensity =>
      _text(zhCn: '阅读密度', zhHant: '閱讀密度', en: 'Reading Density');
  String get interfaceLanguage =>
      _text(zhCn: '界面语言', zhHant: '介面語言', en: 'Interface Language');
  String get interfaceLanguageHint => _text(
        zhCn: '切换后立即生效。跟随系统时，会在简体中文、繁体中文和 English 之间自动匹配。',
        zhHant: '切換後立即生效。跟隨系統時，會在簡體中文、繁體中文和 English 之間自動匹配。',
        en: 'Changes apply immediately. Follow System automatically picks Simplified Chinese, Traditional Chinese, or English.',
      );
  String get desktopSidebarCollapsedTitle => _text(
        zhCn: '桌面端默认折叠侧栏',
        zhHant: '桌面端預設折疊側欄',
        en: 'Collapse Desktop Sidebar by Default',
      );
  String get desktopSidebarCollapsedHint => _text(
        zhCn: '给文章列表和阅读区让出更多空间。',
        zhHant: '給文章列表和閱讀區讓出更多空間。',
        en: 'Leave more room for the list and reader.',
      );

  String visibleArticleCount(int count) => _text(
        zhCn: '$count 篇可见文章',
        zhHant: '$count 篇可見文章',
        en: '$count visible article${count == 1 ? '' : 's'}',
      );

  String feedCountStat(int count) => _text(
        zhCn: '$count 个订阅',
        zhHant: '$count 個訂閱',
        en: '$count source${count == 1 ? '' : 's'}',
      );

  String unreadCountStat(int count) => _text(
        zhCn: '$count 未读',
        zhHant: '$count 未讀',
        en: '$count unread',
      );

  String get refreshCurrentView => _text(
        zhCn: '刷新当前视图',
        zhHant: '刷新目前視圖',
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
        zhHant: '先添加訂閱源，或者放寬目前篩選條件。',
        en: 'Add a subscription first, or loosen the current filters.',
      );

  String starAction(bool starred) => starred
      ? _text(zhCn: '取消收藏', zhHant: '取消收藏', en: 'Remove Star')
      : _text(zhCn: '收藏', zhHant: '收藏', en: 'Star');

  String readLaterAction(bool saved) => saved
      ? _text(zhCn: '取消稍后读', zhHant: '取消稍後讀', en: 'Remove from Later')
      : _text(zhCn: '稍后读', zhHant: '稍後讀', en: 'Read Later');

  String readStateAction(bool isRead) => isRead
      ? _text(zhCn: '标为未读', zhHant: '標為未讀', en: 'Mark Unread')
      : _text(zhCn: '标为已读', zhHant: '標為已讀', en: 'Mark Read');

  String get openOriginal =>
      _text(zhCn: '打开原文', zhHant: '打開原文', en: 'Open Original');
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
  String get emptyReaderBody => _text(
        zhCn: '正文、来源、阅读动作和原文跳转都会收在同一块版面里。',
        zhHant: '正文、來源、閱讀動作和原文跳轉都會收在同一塊版面裡。',
        en: 'Body text, source info, actions, and the original link stay together here.',
      );
  String get addSourceTitle =>
      _text(zhCn: '添加订阅源', zhHant: '添加訂閱源', en: 'Add Source');
  String get addSourceIntro => _text(
        zhCn: '先把本地 RSS 流跑通。首版只做手动添加，不接 OPML，也不做自动发现。',
        zhHant: '先把本地 RSS 流跑通。首版只做手動添加，不接 OPML，也不做自動發現。',
        en: 'Get the local RSS flow working first. This version only supports manual entry.',
      );
  String get feedUrlLabel =>
      _text(zhCn: 'RSS / Atom 地址', zhHant: 'RSS / Atom 位址', en: 'RSS / Atom URL');
  String get feedUrlHint => 'https://example.com/feed.xml';
  String get enterFeedAddress => _text(
        zhCn: '请输入订阅地址',
        zhHant: '請輸入訂閱地址',
        en: 'Enter a subscription URL',
      );
  String get displayName =>
      _text(zhCn: '显示名称', zhHant: '顯示名稱', en: 'Display Name');
  String get displayNameHint => _text(
        zhCn: '留空时自动使用订阅标题',
        zhHant: '留空時自動使用訂閱標題',
        en: 'Leave empty to use the feed title automatically',
      );
  String get addNow =>
      _text(zhCn: '立即添加', zhHant: '立即添加', en: 'Add Now');
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
  String get sourceManagementHintTitle => _text(
        zhCn: '把订阅源收成一列，管理起来会更稳。',
        zhHant: '把訂閱源收成一列，管理起來會更穩。',
        en: 'Keeping sources in one column makes them easier to manage.',
      );
  String get sourceManagementHintBody => _text(
        zhCn: '这里负责站点管理、刷新和编辑。',
        zhHant: '這裡負責站點管理、刷新和編輯。',
        en: 'This area handles source management, refresh, and editing.',
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
      _text(zhCn: '刷新全部', zhHant: '刷新全部', en: 'Refresh All');
  String get unreadOnly =>
      _text(zhCn: '仅未读', zhHant: '僅未讀', en: 'Unread Only');
  String get allSources =>
      _text(zhCn: '全部来源', zhHant: '全部來源', en: 'All Sources');
  String get editSource =>
      _text(zhCn: '编辑订阅源', zhHant: '編輯訂閱源', en: 'Edit Source');
  String get update =>
      _text(zhCn: '更新', zhHant: '更新', en: 'Update');
  String get deleteSource =>
      _text(zhCn: '删除订阅源', zhHant: '刪除訂閱源', en: 'Delete Source');

  String deleteSourceConfirm(String title) => _text(
        zhCn: '确认删除 $title 吗？对应文章缓存也会一起移除。',
        zhHant: '確認刪除 $title 嗎？對應文章快取也會一起移除。',
        en: 'Delete $title? Its cached articles will be removed as well.',
      );

  String get refresh =>
      _text(zhCn: '刷新', zhHant: '刷新', en: 'Refresh');
  String get edit =>
      _text(zhCn: '编辑', zhHant: '編輯', en: 'Edit');
  String get delete =>
      _text(zhCn: '删除', zhHant: '刪除', en: 'Delete');
  String get cancel =>
      _text(zhCn: '取消', zhHant: '取消', en: 'Cancel');
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
        zhHant: '先添加一個訂閱源，文章列表才會開始長出內容。',
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

  String initializationFailed(Object error) => _text(
        zhCn: '初始化本地数据失败：$error',
        zhHant: '初始化本地資料失敗：$error',
        en: 'Failed to initialize local data: $error',
      );

  String get duplicateFeedAddress => _text(
        zhCn: '这个订阅地址已经存在',
        zhHant: '這個訂閱地址已經存在',
        en: 'This subscription URL already exists',
      );

  String get updatingFeedAddressInUse => _text(
        zhCn: '另一个订阅源已经在使用这个地址',
        zhHant: '另一個訂閱源已經在使用這個地址',
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
        zhHant: '還沒有可刷新的訂閱源',
        en: 'There are no sources to refresh yet',
      );

  String get refreshingAllFeeds => _text(
        zhCn: '正在刷新全部订阅...',
        zhHant: '正在刷新全部訂閱...',
        en: 'Refreshing all sources...',
      );

  String refreshedAllFeeds(int count) => _text(
        zhCn: '刷新完成，共处理 $count 个订阅源',
        zhHant: '刷新完成，共處理 $count 個訂閱源',
        en: 'Refresh complete. Processed $count source${count == 1 ? '' : 's'}.',
      );

  String refreshingFeed(String title) => _text(
        zhCn: '正在刷新 $title...',
        zhHant: '正在刷新 $title...',
        en: 'Refreshing $title...',
      );

  String refreshedFeed(String title) => _text(
        zhCn: '已刷新 $title',
        zhHant: '已刷新 $title',
        en: 'Refreshed $title',
      );

  String get unknownSource => _text(
        zhCn: '未知来源',
        zhHant: '未知來源',
        en: 'Unknown Source',
      );

  String get subscriptionAddressRequired => _text(
        zhCn: '订阅地址不能为空',
        zhHant: '訂閱地址不能為空',
        en: 'Subscription URL cannot be empty',
      );
}

extension AppStringsBuildContextX on BuildContext {
  AppStrings get strings => AppStrings.of(this);
}
