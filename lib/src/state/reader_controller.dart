import 'dart:ui';

import 'package:flutter/foundation.dart';

import '../localization/app_language.dart';
import '../localization/app_strings.dart';
import '../models/app_route.dart';
import '../models/article.dart';
import '../models/feed_source.dart';
import '../models/reader_settings.dart';
import '../services/json_store.dart';
import '../services/rss_service.dart';

class ReaderController extends ChangeNotifier {
  ReaderController({
    required JsonStore store,
    required RssService rssService,
  })  : _store = store,
        _rssService = rssService;

  final JsonStore _store;
  final RssService _rssService;

  List<FeedSource> _feeds = <FeedSource>[];
  List<Article> _articles = <Article>[];
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

  List<FeedSource> get feeds => List<FeedSource>.unmodifiable(_feeds);
  List<Article> get articles => List<Article>.unmodifiable(_articles);
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

  bool get routeUsesReaderWorkspace {
    return _currentRoute == AppRouteId.allArticles ||
        _currentRoute == AppRouteId.bookmarks ||
        _currentRoute == AppRouteId.readerDetail;
  }

  int get totalUnreadCount =>
      _articles.where((Article item) => !item.isRead).length;

  String get currentRouteTitle => _strings.routeTitle(
        _currentRoute,
        activeSourceTitle: activeSource?.title,
        selectedArticleTitle: selectedArticle?.title,
        bookmarkFilter: _bookmarkFilter,
      );

  String get startupSummary =>
      _strings.startupSummary(_settings.startupHomeMode);

  List<Article> get visibleArticles {
    Iterable<Article> items = _articles;

    switch (_currentRoute) {
      case AppRouteId.allArticles:
      case AppRouteId.sources:
      case AppRouteId.sourceDetail:
        items = items.where((Article article) {
          if (!_feedEnabled(article.sourceId)) {
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
    return sorted;
  }

  Future<void> initialize() async {
    try {
      final PersistedReaderState persisted = await _store.load();
      _feeds = persisted.feeds;
      _articles = persisted.articles;
      _settings = persisted.settings;
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
    _selectedArticleId = null;
    notifyListeners();
  }

  Future<void> selectArticle(Article article,
      {required bool compactMode}) async {
    _selectedArticleId = article.id;
    if (compactMode) {
      _lastWorkspaceRoute = _currentRoute;
      _currentRoute = AppRouteId.readerDetail;
    }
    _compactReaderOpen = compactMode;
    if (!article.isRead) {
      await _replaceArticle(article.copyWith(readState: ArticleReadState.read));
    } else {
      notifyListeners();
    }
  }

  void closeCompactReader() {
    _compactReaderOpen = false;
    if (_currentRoute == AppRouteId.readerDetail) {
      _currentRoute = _lastWorkspaceRoute;
    }
    notifyListeners();
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
        article.copyWith(savedForLater: !article.savedForLater));
  }

  Future<void> setShowOnlyUnread(bool value) async {
    _showOnlyUnread = value;
    notifyListeners();
  }

  Future<void> setDesktopSidebarCollapsed(bool value) async {
    _settings = _settings.copyWith(desktopSidebarCollapsed: value);
    await _persistSettings();
  }

  Future<void> setMobileSidebarMode(MobileSidebarMode mode) async {
    _settings = _settings.copyWith(mobileSidebarMode: mode);
    await _persistSettings();
  }

  Future<void> setStartupHomeMode(StartupHomeMode mode) async {
    _settings = _settings.copyWith(startupHomeMode: mode);
    await _persistSettings();
  }

  Future<void> setThemeId(String themeId) async {
    _settings = _settings.copyWith(themeId: themeId);
    await _persistSettings();
  }

  Future<void> setArticleListDensity(ArticleListDensity density) async {
    _settings = _settings.copyWith(articleListDensity: density);
    await _persistSettings();
  }

  Future<void> setAppLanguageMode(AppLanguageMode mode) async {
    _settings = _settings.copyWith(appLanguageMode: mode);
    await _persistSettings();
  }

  void setArticleListPaneWidth(double width) {
    _articleListPaneWidth = width.clamp(280, 520);
    notifyListeners();
  }

  Future<void> addFeed({
    required String url,
    String? title,
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
          lastFetchedAt: DateTime.now(),
        );
        _feeds = <FeedSource>[source, ..._feeds];
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
        final ParsedFeedResult parsed =
            await _rssService.fetchFeed(normalizedUrl);
        final FeedSource nextSource = original.copyWith(
          title: title.trim().isEmpty ? parsed.title : title.trim(),
          url: normalizedUrl,
          siteUrl: parsed.siteUrl,
          iconUrl: parsed.iconUrl,
          lastFetchedAt: DateTime.now(),
        );
        _feeds = _feeds.map((FeedSource item) {
          return item.id == original.id ? nextSource : item;
        }).toList();
        _mergeArticlesForSource(nextSource, parsed.articles);
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
    _feeds = _feeds.where((FeedSource item) => item.id != sourceId).toList();
    _articles = _articles
        .where((Article article) => article.sourceId != sourceId)
        .toList();
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
    _feeds = nextFeeds;
    await _store.saveFeeds(_feeds);
    notifyListeners();
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

  bool isFeedRefreshing(String sourceId) =>
      _refreshingFeedIds.contains(sourceId);

  int unreadCountForSource(String? sourceId) {
    return _articles.where((Article article) {
      final bool matchesSource =
          sourceId == null ? true : article.sourceId == sourceId;
      return matchesSource && !article.isRead;
    }).length;
  }

  int articleCountForSource(String? sourceId) {
    return _articles.where((Article article) {
      return sourceId == null ? true : article.sourceId == sourceId;
    }).length;
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

  FeedSource? _feedById(String? id) {
    if (id == null) {
      return null;
    }
    for (final FeedSource source in _feeds) {
      if (source.id == id) {
        return source;
      }
    }
    return null;
  }

  Article? _articleById(String? id) {
    if (id == null) {
      return null;
    }
    for (final Article article in _articles) {
      if (article.id == id) {
        return article;
      }
    }
    return null;
  }

  bool _feedEnabled(String sourceId) {
    return _feedById(sourceId)?.enabled ?? false;
  }

  Future<void> _replaceArticle(Article nextArticle) async {
    _articles = _articles.map((Article item) {
      return item.id == nextArticle.id ? nextArticle : item;
    }).toList()
      ..sort((Article a, Article b) => b.publishedAt.compareTo(a.publishedAt));
    await _store.saveArticles(_articles);
    notifyListeners();
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
      _feeds = _feeds.map((FeedSource item) {
        return item.id == source.id ? updatedSource : item;
      }).toList();
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

    _articles = currentById.values.toList()
      ..sort((Article a, Article b) => b.publishedAt.compareTo(a.publishedAt));
  }

  Future<void> _persistSettings() async {
    await _store.saveSettings(_settings);
    notifyListeners();
  }

  Future<void> _persistAll() async {
    await _store.saveFeeds(_feeds);
    await _store.saveArticles(_articles);
    await _store.saveSettings(_settings);
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
