import 'dart:ui';

import 'package:flutter/foundation.dart';

import '../localization/app_language.dart';
import '../localization/app_strings.dart';
import '../models/app_route.dart';
import '../models/article.dart';
import '../models/auto_refresh.dart';
import '../models/feed_source.dart';
import '../models/reader_settings.dart';
import '../services/auto_refresh_engine.dart';
import '../services/json_store.dart';
import '../services/rss_service.dart';

class _SourceStats {
  const _SourceStats({
    required this.articleCount,
    required this.unreadCount,
  });

  final int articleCount;
  final int unreadCount;
}

class ReaderController extends ChangeNotifier {
  ReaderController({
    required JsonStore store,
    required RssService rssService,
  })  : _store = store,
        _rssService = rssService;

  final JsonStore _store;
  final RssService _rssService;
  late final AutoRefreshEngine _autoRefreshEngine = AutoRefreshEngine(
    store: _store,
    rssService: _rssService,
  );

  List<FeedSource> _feeds = <FeedSource>[];
  List<Article> _articles = <Article>[];
  List<FeedSource> _readonlyFeeds = const <FeedSource>[];
  List<Article> _readonlyArticles = const <Article>[];
  Map<String, FeedSource> _feedsById = <String, FeedSource>{};
  Map<String, Article> _articlesById = <String, Article>{};
  Set<String> _enabledFeedIds = <String>{};
  Map<String, _SourceStats> _sourceStatsById = <String, _SourceStats>{};
  int _totalUnreadCount = 0;
  int _feedsVersion = 0;
  int _articlesVersion = 0;
  bool _feedsDirty = false;
  bool _articlesDirty = false;
  bool _settingsDirty = false;
  String? _visibleArticlesCacheKey;
  List<Article> _visibleArticlesCache = const <Article>[];
  ReaderSettings _settings = ReaderSettings.defaults;
  AppRouteId _currentRoute = ReaderSettings.defaults.startupRoute;
  BookmarkFilter _bookmarkFilter = BookmarkFilter.starred;
  String? _activeSourceId;
  String? _selectedArticleId;
  bool _showOnlyUnread = false;
  bool _isReady = false;
  bool _isBusy = false;
  bool _compactReaderOpen = false;
  AppRouteId _lastWorkspaceRoute = AppRouteId.allArticles;
  double _articleListPaneWidth = 360;
  String? _errorMessage;
  String? _statusMessage;
  final Set<String> _refreshingFeedIds = <String>{};

  List<FeedSource> get feeds => _readonlyFeeds;
  List<Article> get articles => _readonlyArticles;
  ReaderSettings get settings => _settings;
  AppRouteId get currentRoute => _currentRoute;
  BookmarkFilter get bookmarkFilter => _bookmarkFilter;
  String? get activeSourceId => _activeSourceId;
  String? get selectedArticleId => _selectedArticleId;
  bool get showOnlyUnread => _showOnlyUnread;
  bool get isReady => _isReady;
  bool get isBusy => _isBusy;
  bool get compactReaderOpen => _compactReaderOpen;
  double get articleListPaneWidth => _articleListPaneWidth;
  String? get errorMessage => _errorMessage;
  String? get statusMessage => _statusMessage;
  Locale? get appLocale => _settings.appLanguageMode.explicitLocale;
  AppStrings get _strings =>
      AppStrings.fromLanguageMode(_settings.appLanguageMode,
          systemLocale: PlatformDispatcher.instance.locale);

  FeedSource? get activeSource => _feedById(_activeSourceId);
  Article? get selectedArticle => _articleById(_selectedArticleId);
  bool get shouldShowReadLaterDoneAction {
    final Article? article = selectedArticle;
    final bool readingFromBookmarks = _currentRoute == AppRouteId.bookmarks ||
        (_currentRoute == AppRouteId.readerDetail &&
            _lastWorkspaceRoute == AppRouteId.bookmarks);
    return readingFromBookmarks &&
        _bookmarkFilter == BookmarkFilter.savedForLater &&
        (article?.savedForLater ?? false);
  }

  bool get routeUsesReaderWorkspace {
    return _currentRoute == AppRouteId.allArticles ||
        _currentRoute == AppRouteId.bookmarks ||
        _currentRoute == AppRouteId.readerDetail;
  }

  int get totalUnreadCount => _totalUnreadCount;

  String get currentRouteTitle => _strings.routeTitle(
        _currentRoute,
        activeSourceTitle: activeSource?.title,
        selectedArticleTitle: selectedArticle?.title,
        bookmarkFilter: _bookmarkFilter,
      );

  String get startupSummary =>
      _strings.startupSummary(_settings.startupHomeMode);

  List<Article> get visibleArticles {
    final String cacheKey = _visibleArticlesCacheSignature();
    if (_visibleArticlesCacheKey == cacheKey) {
      return _visibleArticlesCache;
    }

    Iterable<Article> items = _articles;

    switch (_currentRoute) {
      case AppRouteId.allArticles:
      case AppRouteId.sources:
      case AppRouteId.sourceDetail:
        items = items.where((Article article) {
          if (!_enabledFeedIds.contains(article.sourceId)) {
            return false;
          }
          if (_activeSourceId == null) {
            return true;
          }
          return article.sourceId == _activeSourceId;
        });
        break;
      case AppRouteId.bookmarks:
        items = items.where((Article article) {
          if (_bookmarkFilter == BookmarkFilter.starred) {
            return article.starred;
          }
          return article.savedForLater;
        });
        if (_activeSourceId != null) {
          items = items
              .where((Article article) => article.sourceId == _activeSourceId);
        }
        break;
      case AppRouteId.readerDetail:
        items = _selectedArticleId == null
            ? const <Article>[]
            : items
                .where((Article article) => article.id == _selectedArticleId);
        break;
      case AppRouteId.discoverAddSource:
      case AppRouteId.settings:
        items = const <Article>[];
        break;
    }

    if (_showOnlyUnread) {
      items = items.where((Article article) => !article.isRead);
    }

    final List<Article> sorted = items.toList()
      ..sort((Article a, Article b) => b.publishedAt.compareTo(a.publishedAt));
    _visibleArticlesCacheKey = cacheKey;
    _visibleArticlesCache = List<Article>.unmodifiable(sorted);
    return _visibleArticlesCache;
  }

  Future<void> initialize() async {
    try {
      final PersistedReaderState persisted = await _store.load();
      _setFeeds(persisted.feeds, dirty: false);
      _setArticles(persisted.articles, dirty: false);
      _setSettings(persisted.settings, dirty: false);
      _clearDirtyFlags();
      _currentRoute = _settings.startupRoute;
      _lastWorkspaceRoute = _currentRoute;
      _activeSourceId = null;
    } catch (error) {
      _errorMessage = _strings.initializationFailed(error);
    } finally {
      _isReady = true;
      notifyListeners();
    }
  }

  void setCurrentRoute(AppRouteId route) {
    if (route == AppRouteId.sources || route == AppRouteId.sourceDetail) {
      route = AppRouteId.allArticles;
    }
    _currentRoute = route;
    _compactReaderOpen = false;
    if (route == AppRouteId.allArticles || route == AppRouteId.bookmarks) {
      _activeSourceId = null;
      _lastWorkspaceRoute = route;
    }
    if (route == AppRouteId.bookmarks) {
      _selectedArticleId = null;
    }
    notifyListeners();
  }

  void selectSource(FeedSource? source, {bool enterSourceDetail = false}) {
    _activeSourceId = source?.id;
    if (enterSourceDetail) {
      _currentRoute = AppRouteId.allArticles;
    }
    _compactReaderOpen = false;
    _selectedArticleId = null;
    notifyListeners();
  }

  void clearSourceFilter() {
    _activeSourceId = null;
    notifyListeners();
  }

  void selectBookmarkFilter(BookmarkFilter filter) {
    _bookmarkFilter = filter;
    if (_activeSourceId != null &&
        !_bookmarkFilterHasSource(filter, _activeSourceId!)) {
      _activeSourceId = null;
    }
    _selectedArticleId = null;
    notifyListeners();
  }

  /// 设计意图：
  /// Android 后台 Worker 可能在独立 isolate 中已经把订阅和文章写回本地。
  /// 应用恢复到前台时，需要从持久化状态重新对账，而不是继续使用过期内存。
  Future<void> reloadPersistedState({bool notify = true}) async {
    final PersistedReaderState persisted = await _store.load();
    _setFeeds(persisted.feeds, dirty: false);
    _setArticles(persisted.articles, dirty: false);
    _setSettings(persisted.settings, dirty: false);
    _clearDirtyFlags();

    if (_activeSourceId != null && _feedById(_activeSourceId) == null) {
      _activeSourceId = null;
    }
    if (_selectedArticleId != null &&
        _articleById(_selectedArticleId) == null) {
      _selectedArticleId = null;
    }

    if (_currentRoute == AppRouteId.readerDetail &&
        _selectedArticleId == null &&
        (_lastWorkspaceRoute == AppRouteId.allArticles ||
            _lastWorkspaceRoute == AppRouteId.bookmarks)) {
      _currentRoute = _lastWorkspaceRoute;
      _compactReaderOpen = false;
    }

    if (notify) {
      notifyListeners();
    }
  }

  bool _bookmarkFilterHasSource(BookmarkFilter filter, String sourceId) {
    return _articles.any((Article article) {
      if (article.sourceId != sourceId) {
        return false;
      }
      switch (filter) {
        case BookmarkFilter.starred:
          return article.starred;
        case BookmarkFilter.savedForLater:
          return article.savedForLater;
      }
    });
  }

  Future<void> selectArticle(Article article,
      {required bool openInReaderRoute}) async {
    _selectedArticleId = article.id;
    if (openInReaderRoute) {
      _lastWorkspaceRoute = _currentRoute;
      _currentRoute = AppRouteId.readerDetail;
    }
    _compactReaderOpen = openInReaderRoute;
    if (!article.isRead) {
      await _replaceArticle(article.copyWith(readState: ArticleReadState.read));
    } else {
      notifyListeners();
    }
  }

  void closeReaderRoute() {
    _compactReaderOpen = false;
    if (_currentRoute == AppRouteId.readerDetail) {
      _currentRoute = _lastWorkspaceRoute;
    }
    notifyListeners();
  }

  void closeCompactReader() {
    closeReaderRoute();
  }

  Future<void> toggleReadState(Article article) async {
    await _replaceArticle(
      article.copyWith(
        readState:
            article.isRead ? ArticleReadState.unread : ArticleReadState.read,
      ),
    );
  }

  Future<void> toggleStarred(Article article) async {
    await _replaceArticle(article.copyWith(starred: !article.starred));
  }

  Future<void> toggleSavedForLater(Article article) async {
    await _replaceArticle(
      article.copyWith(savedForLater: !article.savedForLater),
    );
  }

  Future<void> completeReadLaterArticle(Article article) async {
    if (!article.savedForLater) {
      return;
    }
    await _replaceArticle(article.copyWith(savedForLater: false));
  }

  Future<void> setShowOnlyUnread(bool value) async {
    _showOnlyUnread = value;
    notifyListeners();
  }

  Future<void> setDesktopSidebarCollapsed(bool value) async {
    _setSettings(_settings.copyWith(desktopSidebarCollapsed: value));
    await _persistSettings();
  }

  Future<void> setMobileSidebarMode(MobileSidebarMode mode) async {
    _setSettings(_settings.copyWith(mobileSidebarMode: mode));
    await _persistSettings();
  }

  Future<void> setMobileWorkspaceMode(MobileWorkspaceMode mode) async {
    _setSettings(_settings.copyWith(mobileWorkspaceMode: mode));

    // When compact mode switches to the desktop-like multi-pane workspace,
    // the reader should fold back into the main workspace instead of
    // lingering on the dedicated mobile detail route.
    if (mode == MobileWorkspaceMode.multiPane &&
        _currentRoute == AppRouteId.readerDetail &&
        (_lastWorkspaceRoute == AppRouteId.allArticles ||
            _lastWorkspaceRoute == AppRouteId.bookmarks)) {
      _currentRoute = _lastWorkspaceRoute;
      _compactReaderOpen = false;
    }

    await _persistSettings();
  }

  Future<void> setDesktopWorkspaceMode(DesktopWorkspaceMode mode) async {
    _setSettings(_settings.copyWith(desktopWorkspaceMode: mode));

    // If desktop switches back to the embedded three-pane reader while a
    // standalone reader page is open, fold back into the workspace so the
    // selected article appears in the restored right pane.
    if (mode == DesktopWorkspaceMode.threePane &&
        _currentRoute == AppRouteId.readerDetail &&
        (_lastWorkspaceRoute == AppRouteId.allArticles ||
            _lastWorkspaceRoute == AppRouteId.bookmarks)) {
      _currentRoute = _lastWorkspaceRoute;
      _compactReaderOpen = false;
    }

    await _persistSettings();
  }

  Future<void> setDesktopContentSurfaceMode(
    DesktopContentSurfaceMode mode,
  ) async {
    _setSettings(_settings.copyWith(desktopContentSurfaceMode: mode));
    await _persistSettings();
  }

  Future<void> setAutoRefreshEnabled(bool value) async {
    _setSettings(
      _settings.copyWith(
        autoRefreshMode: value
            ? (_settings.autoRefreshMode == AutoRefreshMode.allOn
                ? AutoRefreshMode.allOn
                : AutoRefreshMode.partial)
            : AutoRefreshMode.allOff,
      ),
    );
    await _persistSettings();
  }

  Future<void> setAutoRefreshMode(AutoRefreshMode mode) async {
    _setSettings(_settings.copyWith(autoRefreshMode: mode));
    await _persistSettings();
  }

  Future<void> setGlobalAutoRefreshIntervalMinutes(int minutes) async {
    _setSettings(
      _settings.copyWith(
        globalAutoRefreshIntervalMinutes: normalizeAutoRefreshInterval(minutes),
      ),
    );
    await _persistSettings();
  }

  Future<void> setStartupHomeMode(StartupHomeMode mode) async {
    _setSettings(_settings.copyWith(startupHomeMode: mode));
    await _persistSettings();
  }

  Future<void> setThemeId(String themeId) async {
    _setSettings(_settings.copyWith(themeId: themeId));
    await _persistSettings();
  }

  Future<void> setArticleListDensity(ArticleListDensity density) async {
    _setSettings(_settings.copyWith(articleListDensity: density));
    await _persistSettings();
  }

  Future<void> setArticleContentMode(ArticleContentMode mode) async {
    _setSettings(_settings.copyWith(articleContentMode: mode));
    await _persistSettings();
  }

  Future<void> setAppLanguageMode(AppLanguageMode mode) async {
    _setSettings(_settings.copyWith(appLanguageMode: mode));
    await _persistSettings();
  }

  void setArticleListPaneWidth(double width) {
    _articleListPaneWidth = width.clamp(280, 520);
    notifyListeners();
  }

  Future<void> addFeed({
    required String url,
    String? title,
    bool autoRefreshEnabled = false,
    int autoRefreshIntervalMinutes = kDefaultAutoRefreshIntervalMinutes,
  }) async {
    final String normalizedUrl = _normalizeInputUrl(url);
    final bool exists =
        _feeds.any((FeedSource source) => source.url == normalizedUrl);
    if (exists) {
      _errorMessage = _strings.duplicateFeedAddress;
      notifyListeners();
      return;
    }

    await _runBusy(
      _strings.addingSubscription,
      () async {
        final ParsedFeedResult parsed =
            await _rssService.fetchFeed(normalizedUrl);
        final FeedSource source = FeedSource(
          id: _makeId('feed'),
          title: (title?.trim().isNotEmpty ?? false)
              ? title!.trim()
              : parsed.title,
          url: normalizedUrl,
          siteUrl: parsed.siteUrl,
          iconUrl: parsed.iconUrl,
          enabled: true,
          autoRefreshEnabled: autoRefreshEnabled,
          autoRefreshIntervalMinutes: normalizeAutoRefreshInterval(
            autoRefreshIntervalMinutes,
          ),
          lastFetchedAt: DateTime.now(),
        );
        _setFeeds(<FeedSource>[source, ..._feeds]);
        _mergeArticlesForSource(source, parsed.articles);
        _activeSourceId = source.id;
        _currentRoute = AppRouteId.discoverAddSource;
        await _persistAll();
        _statusMessage = _strings.addedFeed(source.title);
      },
    );
  }

  Future<void> updateFeed({
    required FeedSource original,
    required String url,
    required String title,
    required bool autoRefreshEnabled,
    required int autoRefreshIntervalMinutes,
  }) async {
    final String normalizedUrl = _normalizeInputUrl(url);
    final bool exists = _feeds.any(
      (FeedSource source) =>
          source.id != original.id && source.url == normalizedUrl,
    );
    if (exists) {
      _errorMessage = _strings.updatingFeedAddressInUse;
      notifyListeners();
      return;
    }

    await _runBusy(
      _strings.updatingSubscription,
      () async {
        FeedSource nextSource = original.copyWith(
          title: title.trim().isEmpty ? original.title : title.trim(),
          url: normalizedUrl,
          autoRefreshEnabled: autoRefreshEnabled,
          autoRefreshIntervalMinutes: normalizeAutoRefreshInterval(
            autoRefreshIntervalMinutes,
          ),
        );

        if (normalizedUrl != original.url) {
          final ParsedFeedResult parsed =
              await _rssService.fetchFeed(normalizedUrl);
          nextSource = nextSource.copyWith(
            title: title.trim().isEmpty ? parsed.title : title.trim(),
            siteUrl: parsed.siteUrl,
            iconUrl: parsed.iconUrl,
            lastFetchedAt: DateTime.now(),
          );
          _mergeArticlesForSource(nextSource, parsed.articles);
        }

        _setFeeds(_feeds.map((FeedSource item) {
          return item.id == original.id ? nextSource : item;
        }).toList());
        await _persistAll();
        _statusMessage = _strings.updatedFeed(nextSource.title);
      },
    );
  }

  Future<void> removeFeed(String sourceId) async {
    final FeedSource? source = _feedById(sourceId);
    if (source == null) {
      return;
    }
    _setFeeds(
      _feeds.where((FeedSource item) => item.id != sourceId).toList(),
    );
    _setArticles(_articles
        .where((Article article) => article.sourceId != sourceId)
        .toList());
    if (_activeSourceId == sourceId) {
      _activeSourceId = _feeds.isNotEmpty ? _feeds.first.id : null;
    }
    if (_selectedArticleId != null &&
        _articleById(_selectedArticleId) == null) {
      _selectedArticleId = null;
    }
    await _persistAll();
    _statusMessage = _strings.removedFeed(source.title);
    notifyListeners();
  }

  Future<void> moveFeed(int oldIndex, int newIndex) async {
    if (oldIndex < 0 ||
        oldIndex >= _feeds.length ||
        newIndex < 0 ||
        newIndex > _feeds.length) {
      return;
    }

    if (oldIndex < newIndex) {
      newIndex -= 1;
    }
    if (oldIndex == newIndex) {
      return;
    }

    final List<FeedSource> nextFeeds = List<FeedSource>.from(_feeds);
    final FeedSource source = nextFeeds.removeAt(oldIndex);
    nextFeeds.insert(newIndex, source);
    _setFeeds(nextFeeds);
    await _persistAll();
  }

  Future<void> refreshAllFeeds() async {
    final List<FeedSource> candidates =
        _feeds.where((FeedSource source) => source.enabled).toList();
    if (candidates.isEmpty) {
      _errorMessage = _strings.noRefreshableFeeds;
      notifyListeners();
      return;
    }
    await _runBusy(
      _strings.refreshingAllFeeds,
      () async {
        for (final FeedSource source in candidates) {
          await _refreshFeed(source);
        }
        await _persistAll();
        _statusMessage = _strings.refreshedAllFeeds(candidates.length);
      },
    );
  }

  Future<void> refreshSource(String sourceId) async {
    final FeedSource? source = _feedById(sourceId);
    if (source == null) {
      return;
    }
    await _runBusy(
      _strings.refreshingFeed(source.title),
      () async {
        await _refreshFeed(source);
        await _persistAll();
        _statusMessage = _strings.refreshedFeed(source.title);
      },
    );
  }

  DateTime? nextAutoRefreshAt({DateTime? now}) {
    return _autoRefreshEngine.nextRefreshAt(
      settings: _settings,
      feeds: _feeds,
      now: now,
    );
  }

  List<FeedSource> dueAutoRefreshFeeds({DateTime? now}) {
    return _autoRefreshEngine.dueFeeds(
      settings: _settings,
      feeds: _feeds,
      now: now,
    );
  }

  Future<int> refreshDueAutoRefreshFeeds({DateTime? now}) async {
    if (_isBusy) {
      return 0;
    }

    final AutoRefreshRunResult result =
        await _autoRefreshEngine.refreshPersistedDueFeeds(now: now);
    if (result.attemptedCount == 0) {
      return 0;
    }

    await reloadPersistedState();
    return result.attemptedCount;
  }

  bool isFeedRefreshing(String sourceId) =>
      _refreshingFeedIds.contains(sourceId);

  bool isFeedEffectivelyAutoRefreshEnabled(FeedSource source) {
    switch (_settings.autoRefreshMode) {
      case AutoRefreshMode.allOff:
        return false;
      case AutoRefreshMode.partial:
        return source.enabled && source.autoRefreshEnabled;
      case AutoRefreshMode.allOn:
        return source.enabled;
    }
  }

  int effectiveAutoRefreshIntervalMinutesForFeed(FeedSource source) {
    if (_settings.autoRefreshMode == AutoRefreshMode.allOn) {
      return _settings.globalAutoRefreshIntervalMinutes;
    }
    return source.autoRefreshIntervalMinutes;
  }

  int unreadCountForSource(String? sourceId) {
    if (sourceId == null) {
      return _totalUnreadCount;
    }
    return _sourceStatsById[sourceId]?.unreadCount ?? 0;
  }

  int articleCountForSource(String? sourceId) {
    if (sourceId == null) {
      return _articles.length;
    }
    return _sourceStatsById[sourceId]?.articleCount ?? 0;
  }

  String sourceTitleForArticle(Article article) {
    return _feedById(article.sourceId)?.title ?? _strings.unknownSource;
  }

  String? sourceIconForArticle(Article article) {
    return _feedById(article.sourceId)?.iconUrl;
  }

  DateTime? lastSyncedAtForSource(String? sourceId) {
    if (sourceId == null) {
      final Iterable<DateTime> values = _feeds
          .map((FeedSource source) => source.lastFetchedAt)
          .whereType<DateTime>();
      if (values.isEmpty) {
        return null;
      }
      return values.reduce((DateTime a, DateTime b) => a.isAfter(b) ? a : b);
    }
    return _feedById(sourceId)?.lastFetchedAt;
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  void clearStatus() {
    _statusMessage = null;
    notifyListeners();
  }

  // Keep read-heavy indexes in sync at mutation boundaries so UI getters stay cheap.
  void _setFeeds(List<FeedSource> feeds, {bool dirty = true}) {
    _feeds = feeds;
    _feedsVersion += 1;
    _feedsDirty = _feedsDirty || dirty;
    _rebuildDerivedState();
  }

  void _setArticles(List<Article> articles, {bool dirty = true}) {
    _articles = articles;
    _articlesVersion += 1;
    _articlesDirty = _articlesDirty || dirty;
    _rebuildDerivedState();
  }

  void _setSettings(ReaderSettings settings, {bool dirty = true}) {
    _settings = settings;
    _settingsDirty = _settingsDirty || dirty;
  }

  void _clearDirtyFlags() {
    _feedsDirty = false;
    _articlesDirty = false;
    _settingsDirty = false;
  }

  void _rebuildDerivedState() {
    _readonlyFeeds = List<FeedSource>.unmodifiable(_feeds);
    _readonlyArticles = List<Article>.unmodifiable(_articles);
    _feedsById = Map<String, FeedSource>.unmodifiable(<String, FeedSource>{
      for (final FeedSource source in _feeds) source.id: source,
    });
    _enabledFeedIds = Set<String>.unmodifiable(<String>{
      for (final FeedSource source in _feeds)
        if (source.enabled) source.id,
    });
    _articlesById = Map<String, Article>.unmodifiable(<String, Article>{
      for (final Article article in _articles) article.id: article,
    });

    final Map<String, _SourceStats> stats = <String, _SourceStats>{
      for (final FeedSource source in _feeds)
        source.id: const _SourceStats(articleCount: 0, unreadCount: 0),
    };
    int totalUnreadCount = 0;
    for (final Article article in _articles) {
      final _SourceStats previous = stats[article.sourceId] ??
          const _SourceStats(articleCount: 0, unreadCount: 0);
      final int nextUnreadCount =
          previous.unreadCount + (article.isRead ? 0 : 1);
      stats[article.sourceId] = _SourceStats(
        articleCount: previous.articleCount + 1,
        unreadCount: nextUnreadCount,
      );
      if (!article.isRead) {
        totalUnreadCount += 1;
      }
    }
    _sourceStatsById = Map<String, _SourceStats>.unmodifiable(stats);
    _totalUnreadCount = totalUnreadCount;
    _visibleArticlesCacheKey = null;
    _visibleArticlesCache = const <Article>[];
  }

  String _visibleArticlesCacheSignature() {
    return '${_currentRoute.name}|${_bookmarkFilter.name}|'
        '${_activeSourceId ?? ''}|${_selectedArticleId ?? ''}|'
        '$_showOnlyUnread|$_feedsVersion|$_articlesVersion';
  }

  FeedSource? _feedById(String? id) {
    if (id == null) {
      return null;
    }
    return _feedsById[id];
  }

  Article? _articleById(String? id) {
    if (id == null) {
      return null;
    }
    return _articlesById[id];
  }

  Future<void> _replaceArticle(Article nextArticle) async {
    _setArticles(_articles.map((Article item) {
      return item.id == nextArticle.id ? nextArticle : item;
    }).toList()
      ..sort((Article a, Article b) => b.publishedAt.compareTo(a.publishedAt)));
    await _persistAll();
  }

  Future<void> _refreshFeed(FeedSource source) async {
    _refreshingFeedIds.add(source.id);
    notifyListeners();
    try {
      final ParsedFeedResult parsed = await _rssService.fetchFeed(source.url);
      final FeedSource updatedSource = source.copyWith(
        title: source.title.trim().isEmpty ? parsed.title : source.title,
        siteUrl: parsed.siteUrl,
        iconUrl: parsed.iconUrl,
        lastFetchedAt: DateTime.now(),
      );
      _setFeeds(_feeds.map((FeedSource item) {
        return item.id == source.id ? updatedSource : item;
      }).toList());
      _mergeArticlesForSource(updatedSource, parsed.articles);
    } finally {
      _refreshingFeedIds.remove(source.id);
      notifyListeners();
    }
  }

  void _mergeArticlesForSource(
    FeedSource source,
    List<ParsedArticleDraft> drafts,
  ) {
    final Map<String, Article> currentById = <String, Article>{
      for (final Article article in _articles) article.id: article,
    };
    final Map<String, Article> currentByUrl = <String, Article>{
      for (final Article article in _articles)
        if (article.sourceId == source.id && article.url.trim().isNotEmpty)
          article.url: article,
    };

    for (final ParsedArticleDraft draft in drafts) {
      final String draftUrl = draft.url.trim();
      final String candidateId = _rssService.stableArticleId(source.id, draft);
      final Article? existing =
          currentById[candidateId] ?? currentByUrl[draftUrl];
      final String articleId = existing?.id ?? candidateId;

      if (existing != null && existing.id != articleId) {
        currentById.remove(existing.id);
      }

      currentById[articleId] = Article(
        id: articleId,
        sourceId: source.id,
        title: draft.title,
        author: draft.author,
        publishedAt: draft.publishedAt,
        summary: draft.summary,
        summaryHtml: draft.summaryHtml,
        content: draft.content,
        contentHtml: draft.contentHtml,
        url: draft.url,
        readState: existing?.readState ?? ArticleReadState.unread,
        starred: existing?.starred ?? false,
        savedForLater: existing?.savedForLater ?? false,
      );

      if (draftUrl.isNotEmpty) {
        currentByUrl[draftUrl] = currentById[articleId]!;
      }
    }

    _setArticles(currentById.values.toList()
      ..sort((Article a, Article b) => b.publishedAt.compareTo(a.publishedAt)));
  }

  Future<void> _persistSettings() async {
    if (_settingsDirty) {
      await _store.saveSettings(_settings);
      _settingsDirty = false;
    }
    notifyListeners();
  }

  Future<void> _persistAll() async {
    if (_feedsDirty) {
      await _store.saveFeeds(_feeds);
      _feedsDirty = false;
    }
    if (_articlesDirty) {
      await _store.saveArticles(_articles);
      _articlesDirty = false;
    }
    if (_settingsDirty) {
      await _store.saveSettings(_settings);
      _settingsDirty = false;
    }
    notifyListeners();
  }

  Future<void> _runBusy(
    String status,
    Future<void> Function() action,
  ) async {
    _errorMessage = null;
    _statusMessage = status;
    _isBusy = true;
    notifyListeners();
    try {
      await action();
    } catch (error) {
      _errorMessage = error.toString();
    } finally {
      _isBusy = false;
      notifyListeners();
    }
  }

  String _normalizeInputUrl(String rawUrl) {
    final String trimmed = rawUrl.trim();
    if (trimmed.isEmpty) {
      throw FormatException(_strings.subscriptionAddressRequired);
    }
    if (trimmed.startsWith('http://') || trimmed.startsWith('https://')) {
      return trimmed;
    }
    return 'https://$trimmed';
  }

  String _makeId(String prefix) {
    final int micros = DateTime.now().microsecondsSinceEpoch;
    return '${prefix}_$micros';
  }
}
