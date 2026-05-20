import 'dart:async';
import 'dart:io';
import 'dart:math';
import 'dart:ui';

import 'package:file_selector/file_selector.dart';
import 'package:flutter/foundation.dart';
import 'package:image/image.dart' as img;

import '../localization/app_language.dart';
import '../localization/app_strings.dart';
import '../models/app_route.dart';
import '../models/article.dart';
import '../models/auto_refresh.dart';
import '../models/feed_source.dart';
import '../models/reader_settings.dart';
import '../models/user_profile.dart';
import '../services/auto_refresh_engine.dart';
import '../services/cloud_service_router.dart';
import '../services/json_store.dart';
import '../services/official_cloud_service.dart';
import '../services/private_webdav_service.dart';
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
    required CloudServiceResolver cloudServiceResolver,
    required RssService rssService,
  })  : _store = store,
        _cloudServiceResolver = cloudServiceResolver,
        _rssService = rssService;

  final JsonStore _store;
  final CloudServiceResolver _cloudServiceResolver;
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
  CurrentUserSession _currentUserSession = const CurrentUserSession.signedOut();
  UserProfile? _currentUser;
  String? _errorMessage;
  String? _statusMessage;
  final Set<String> _refreshingFeedIds = <String>{};
  bool _syncingPendingAccountState = false;

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
  bool get isSignedIn => _currentUserSession.isSignedIn;
  UserProfile? get currentUser => _currentUser;
  String get currentIdentityCodeDisplay =>
      _currentUser?.identityCode ?? _currentUserSession.identityCode ?? '';
  String get currentUserDisplayName {
    final String displayName = _currentUser?.displayName.trim() ?? '';
    if (displayName.isNotEmpty) {
      return displayName;
    }
    return _strings.accountUnnamedUser;
  }

  CloudServiceBundle get _cloudServices =>
      _cloudServiceResolver.resolve(_settings);
  IdentitySyncService get _identitySyncService =>
      _cloudServices.identityService;
  ContentSyncService get _contentSyncService => _cloudServices.contentService;

  bool get isOfficialCloudConfigured => _identitySyncService.isConfigured;
  bool get isIdentityCloudConfigured => _identitySyncService.isConfigured;
  String? get officialCloudBaseUrl => _identitySyncService.baseUrl;
  String? get officialCloudHost {
    final String? baseUrl = officialCloudBaseUrl;
    if (baseUrl == null || baseUrl.isEmpty) {
      return null;
    }
    return Uri.tryParse(baseUrl)?.host;
  }

  bool get isContentCloudConfigured => _contentSyncService.isConfigured;
  String? get contentCloudBaseUrl => _contentSyncService.baseUrl;
  String? get contentCloudHost {
    final String? baseUrl = contentCloudBaseUrl;
    if (baseUrl == null || baseUrl.isEmpty) {
      return null;
    }
    return Uri.tryParse(baseUrl)?.host;
  }

  bool get privateCloudEnabled => _settings.privateCloudEnabled;
  bool get advancedCloudModeEnabled => _settings.advancedCloudModeEnabled;
  CloudIdentityMode get cloudIdentityMode => _settings.cloudIdentityMode;
  CloudContentMode get cloudContentMode => _settings.cloudContentMode;
  PrivateCloudProtocol get privateCloudProtocol =>
      _settings.privateCloudProtocol;
  bool get cloudServiceEnabled => _settings.cloudServiceEnabled;
  String get privateCloudBaseUrl => _settings.privateCloudBaseUrl;
  String get privateCloudUsername => _settings.privateCloudUsername;
  String get privateCloudPassword => _settings.privateCloudPassword;
  String get privateCloudBasePath => _settings.privateCloudBasePath;
  bool get usesPrivateIdentityCloud =>
      _settings.cloudIdentityMode == CloudIdentityMode.privateCloud;
  bool get usesPrivateContentCloud =>
      _settings.cloudContentMode == CloudContentMode.privateCloud;

  CloudSyncStatus get currentCloudSyncStatus =>
      _currentUser?.lastCloudSyncStatus ?? CloudSyncStatus.idle;
  DateTime? get currentCloudSyncAt => _currentUser?.lastCloudSyncAt;
  String? get currentCloudSyncMessage => _currentUser?.lastCloudSyncMessage;

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

    final List<Article> sorted = articlesForRoute(_currentRoute);
    _visibleArticlesCacheKey = cacheKey;
    _visibleArticlesCache = List<Article>.unmodifiable(sorted);
    return _visibleArticlesCache;
  }

  List<Article> articlesForRoute(AppRouteId route) {
    Iterable<Article> items = _articles;

    switch (route) {
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

    return items.toList()
      ..sort((Article a, Article b) => b.publishedAt.compareTo(a.publishedAt));
  }

  Future<void> initialize() async {
    try {
      final PersistedReaderState persisted = await _store.load();
      _setFeeds(persisted.feeds, dirty: false);
      _setArticles(persisted.articles, dirty: false);
      _setSettings(persisted.settings, dirty: false);
      _clearDirtyFlags();
      await _loadUserState();
      await _syncPendingAccountStateIfNeeded();
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
    await _loadUserState();

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

  Future<void> setSubscriptionNotificationMode(
    SubscriptionNotificationMode mode,
  ) async {
    _setSettings(_settings.copyWith(subscriptionNotificationMode: mode));
    await _persistSettings();
  }

  Future<void> dismissSourceFilterHint() async {
    if (_settings.sourceFilterHintDismissed) {
      return;
    }
    _setSettings(_settings.copyWith(sourceFilterHintDismissed: true));
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

  Future<void> setAppearanceMode(AppearanceMode mode) async {
    _setSettings(_settings.copyWith(appearanceMode: mode));
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

  Future<void> setBlurEffectsEnabled(bool value) async {
    _setSettings(_settings.copyWith(blurEffectsEnabled: value));
    await _persistSettings();
  }

  Future<void> setCloudServiceEnabled(bool value) async {
    _setSettings(_settings.copyWith(cloudServiceEnabled: value));
    await _persistSettings();
  }

  Future<void> setCloudContentModeSelection(CloudContentMode mode) async {
    _setSettings(
      _settings.copyWith(
        cloudContentMode: mode,
        privateCloudEnabled: mode == CloudContentMode.privateCloud,
        advancedCloudModeEnabled: mode == CloudContentMode.privateCloud
            ? _settings.advancedCloudModeEnabled
            : false,
        cloudIdentityMode: mode == CloudContentMode.privateCloud &&
                _settings.advancedCloudModeEnabled
            ? CloudIdentityMode.privateCloud
            : CloudIdentityMode.official,
      ),
    );
    await _persistSettings();
  }

  Future<void> setPrivateCloudProtocol(PrivateCloudProtocol protocol) async {
    _setSettings(_settings.copyWith(privateCloudProtocol: protocol));
    await _persistSettings();
  }

  Future<void> setPrivateCloudServerConfig({
    required String baseUrl,
    required String username,
    required String password,
    required String basePath,
  }) async {
    _setSettings(
      _settings.copyWith(
        privateCloudBaseUrl: normalizePrivateCloudBaseUrl(baseUrl),
        privateCloudUsername: username.trim(),
        privateCloudPassword: password,
        privateCloudBasePath: normalizePrivateCloudBasePath(basePath),
      ),
    );
    await _persistSettings();
    _triggerPendingAccountSyncIfPossible();
  }

  Future<void> setAdvancedCloudModeEnabled(bool value) async {
    _setSettings(
      _settings.copyWith(
        advancedCloudModeEnabled: value,
        cloudIdentityMode: value && _settings.privateCloudEnabled
            ? CloudIdentityMode.privateCloud
            : CloudIdentityMode.official,
      ),
    );
    await _persistSettings();
    _triggerPendingAccountSyncIfPossible();
  }

  Future<void> setAppLanguageMode(AppLanguageMode mode) async {
    _setSettings(_settings.copyWith(appLanguageMode: mode));
    await _persistSettings();
  }

  Future<void> generateIdentityAndSignIn() async {
    if (!_canCreateIdentityCode()) {
      return;
    }

    await _runUserBusyTask(() async {
      final String initialUserName = _defaultCloudUserName;
      CloudCreateUserResult? createdUser;
      String? offlineCandidateIdentityCode;

      for (int attempt = 0; attempt < 20; attempt += 1) {
        final String identityCode = generateIdentityCode();
        final UserProfile? localProfile = await _store.loadUserProfile(
          identityCode,
        );
        if (localProfile != null) {
          continue;
        }
        try {
          createdUser = await _identitySyncService.createUser(
            identityCode,
            initialUserName,
          );
          break;
        } on CloudServiceException catch (error) {
          if (error.kind == CloudServiceErrorKind.conflict) {
            continue;
          }
          if (_canFallbackToOfflineCreate(error)) {
            offlineCandidateIdentityCode = identityCode;
            break;
          }
          rethrow;
        }
      }

      if (createdUser == null) {
        final UserProfile offlineProfile = await _createOfflinePendingUser(
          identityCode: offlineCandidateIdentityCode ?? generateIdentityCode(),
          initialUserName: initialUserName,
        );
        await _activateUserSession(
          offlineProfile,
          statusMessage: _accountGeneratedOfflinePendingMessage,
        );
        return;
      }

      final UserProfile profile = await _upsertCloudUserProfile(
        identityCode: createdUser.identityCode,
        userName: createdUser.userName,
        syncStatus: CloudSyncStatus.synced,
        syncMessage: _accountRegistrationCompletedMessage,
      );
      await _activateUserSession(
        profile,
        statusMessage: _accountGeneratedAndSignedInMessage,
      );
    });
  }

  Future<void> signInWithIdentityCode(String rawCode) async {
    final String identityCode = rawCode.trim();
    if (!isValidIdentityCode(identityCode)) {
      _errorMessage = _strings.accountIdentityCodeInvalid;
      notifyListeners();
      return;
    }

    if (!_ensureIdentitySyncConfigured()) {
      return;
    }

    await _runUserBusyTask(() async {
      final CloudUserLookupResult result =
          await _identitySyncService.getUser(identityCode);
      if (!result.exists) {
        _errorMessage = _identityCodeNotFoundMessage;
        return;
      }

      final UserProfile profile = await _upsertCloudUserProfile(
        identityCode: identityCode,
        userName: result.userName ?? _defaultCloudUserName,
        syncStatus: CloudSyncStatus.synced,
        syncMessage: _accountLoginLoadedMessage,
      );
      await _activateUserSession(
        profile,
        statusMessage: _accountSignedInMessage,
      );
    });
  }

  Future<void> signOutUser() async {
    _errorMessage = null;
    try {
      _currentUserSession = const CurrentUserSession.signedOut();
      _currentUser = null;
      await _store.clearCurrentUserSession();
      _statusMessage = _strings.accountSignedOut;
    } catch (error) {
      _errorMessage = '$error';
    }
    notifyListeners();
  }

  Future<void> updateUserDisplayName(String value) async {
    final UserProfile? profile = _currentUser;
    if (profile == null) {
      return;
    }
    if (!_ensureIdentitySyncConfigured()) {
      return;
    }

    await _runUserBusyTask(() async {
      final String normalizedUserName = _normalizeCloudUserName(value);
      UserProfile nextProfile = profile.copyWith(
        displayName: normalizedUserName,
        updatedAt: DateTime.now(),
      );
      await _store.saveUserProfile(nextProfile);
      _currentUser = nextProfile;
      notifyListeners();

      try {
        await _identitySyncService.updateUser(
          profile.identityCode,
          normalizedUserName,
        );
        nextProfile = await _persistUserProfile(
          nextProfile.copyWith(
            lastCloudSyncAt: DateTime.now(),
            lastCloudSyncStatus: CloudSyncStatus.synced,
            lastCloudSyncMessage: _accountDisplayNameUpdatedMessage,
            pendingCloudCreate: false,
            pendingCloudProfileSync: false,
          ),
        );
        _currentUser = nextProfile;
        _statusMessage = _accountDisplayNameUpdatedMessage;
      } on CloudServiceException catch (error) {
        nextProfile = await _persistUserProfile(
          nextProfile.copyWith(
            lastCloudSyncStatus: CloudSyncStatus.failed,
            lastCloudSyncMessage: _accountUserNameSyncFailedMessage,
            pendingCloudProfileSync: true,
          ),
        );
        _currentUser = nextProfile;
        _errorMessage = _cloudOperationMessage(
          error,
          fallback: _accountUserNameSyncFailedMessage,
        );
      }
    });
  }

  /// 设计意图：
  /// 账号资料自动补传只挂在“重新回到前台”这个自然事件上，
  /// 不做后台低频轮询，避免长期驻留重试。
  Future<void> handleAppResumed() async {
    await _syncPendingAccountStateIfNeeded();
  }

  Future<void> pickAndSaveUserAvatar() async {
    final UserProfile? profile = _currentUser;
    if (profile == null) {
      return;
    }
    if (kIsWeb) {
      _errorMessage = _strings.accountAvatarUnsupported;
      notifyListeners();
      return;
    }

    _errorMessage = null;
    try {
      final XFile? pickedFile = await openFile(
        acceptedTypeGroups: <XTypeGroup>[
          const XTypeGroup(
            label: 'images',
            extensions: <String>[
              'jpg',
              'jpeg',
              'png',
              'webp',
              'bmp',
              'gif',
            ],
          ),
        ],
      );
      if (pickedFile == null) {
        return;
      }

      final Uint8List avatarBytes =
          _buildCenteredSquareAvatar(await pickedFile.readAsBytes());
      final String avatarPath = await _store.saveUserAvatar(
        profile.identityCode,
        avatarBytes,
      );
      final UserProfile nextProfile = await _persistUserProfile(
        profile.copyWith(
          avatarPath: avatarPath,
          updatedAt: DateTime.now(),
          pendingCloudAvatarSync: true,
          lastCloudSyncStatus: CloudSyncStatus.failed,
          lastCloudSyncMessage: _accountAvatarPendingSyncMessage,
        ),
      );
      _currentUser = nextProfile;
      _statusMessage = _strings.accountAvatarUpdated;
      _triggerPendingAccountSyncIfPossible();
    } on FormatException catch (_) {
      _errorMessage = _strings.accountAvatarUnsupported;
    } catch (error) {
      _errorMessage = '$error';
    }
    notifyListeners();
  }

  Future<void> uploadCurrentUserToCloud() async {
    final UserProfile? profile = _currentUser;
    if (profile == null) {
      return;
    }
    if (!cloudServiceEnabled) {
      return;
    }
    if (!_ensureContentSyncConfigured()) {
      return;
    }

    await _runUserBusyTask(() async {
      if (usesPrivateIdentityCloud) {
        final CloudUserLookupResult userLookup =
            await _identitySyncService.getUser(profile.identityCode);
        if (!userLookup.exists) {
          await _identitySyncService.createUser(
            profile.identityCode,
            _normalizeCloudUserName(profile.displayName),
          );
        } else {
          await _identitySyncService.updateUser(
            profile.identityCode,
            _normalizeCloudUserName(profile.displayName),
          );
        }
      }
      await _contentSyncService.uploadFeeds(
        profile.identityCode,
        buildCloudFeedsPayload(profile.identityCode, _feeds),
      );
      await _contentSyncService.uploadArticles(
        profile.identityCode,
        buildCloudArticlesPayload(profile.identityCode, _articles),
      );
      if (profile.hasAvatar) {
        final File avatarFile = File(profile.avatarPath!);
        if (await avatarFile.exists()) {
          await _contentSyncService.uploadAvatar(
            profile.identityCode,
            await avatarFile.readAsBytes(),
            'image/jpeg',
          );
        }
      }
      _currentUser = await _persistUserProfile(profile.copyWith(
        lastCloudSyncAt: DateTime.now(),
        lastCloudSyncStatus: CloudSyncStatus.synced,
        lastCloudSyncMessage: _cloudUploadCompletedMessage,
        pendingCloudCreate: false,
        pendingCloudProfileSync: false,
        pendingCloudAvatarSync: false,
        updatedAt: DateTime.now(),
      ));
      _statusMessage = _cloudUploadCompletedMessage;
    }, onCloudErrorFallback: _cloudUploadFailedMessage);
  }

  Future<void> uploadCurrentUserToOfficialCloud() {
    return uploadCurrentUserToCloud();
  }

  Future<void> downloadCurrentUserFromCloud() async {
    final UserProfile? profile = _currentUser;
    if (profile == null) {
      return;
    }
    if (!cloudServiceEnabled) {
      return;
    }
    if (!_ensureContentSyncConfigured()) {
      return;
    }

    await _runUserBusyTask(() async {
      CloudUserLookupResult? identityResult;
      if (usesPrivateIdentityCloud) {
        identityResult =
            await _identitySyncService.getUser(profile.identityCode);
        if (!identityResult.exists) {
          throw const CloudServiceException(CloudServiceErrorKind.notFound);
        }
      }
      final Map<String, dynamic> feedsPayload =
          await _contentSyncService.downloadFeeds(profile.identityCode);
      final Map<String, dynamic> articlesPayload =
          await _contentSyncService.downloadArticles(profile.identityCode);
      final Uint8List? avatarBytes =
          await _contentSyncService.downloadAvatar(profile.identityCode);

      final List<FeedSource> downloadedFeeds =
          _decodeCloudFeedsPayload(feedsPayload);
      final List<Article> downloadedArticles =
          _decodeCloudArticlesPayload(articlesPayload);
      final UserProfile refreshedProfile =
          await _buildProfileWithDownloadedAvatar(
        profile,
        avatarBytes,
      );

      _setFeeds(downloadedFeeds);
      _setArticles(downloadedArticles);
      await _persistAll();
      _currentUser = await _persistUserProfile(refreshedProfile.copyWith(
        displayName: identityResult?.userName == null
            ? refreshedProfile.displayName
            : _normalizeCloudUserName(identityResult!.userName!),
        lastCloudSyncAt: DateTime.now(),
        lastCloudSyncStatus: CloudSyncStatus.synced,
        lastCloudSyncMessage: _cloudDownloadCompletedMessage,
        pendingCloudCreate: false,
        pendingCloudProfileSync: false,
        pendingCloudAvatarSync: false,
        updatedAt: DateTime.now(),
      ));
      _statusMessage = _cloudDownloadCompletedMessage;
    }, onCloudErrorFallback: _cloudDownloadFailedMessage);
  }

  Future<void> downloadCurrentUserFromOfficialCloud() {
    return downloadCurrentUserFromCloud();
  }

  void setArticleListPaneWidth(double width) {
    _articleListPaneWidth = width.clamp(280, 520);
    notifyListeners();
  }

  Future<void> addFeed({
    required String url,
    String? title,
    bool autoRefreshEnabled = false,
    bool notificationEnabled = false,
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
          notificationEnabled: notificationEnabled,
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
    required bool notificationEnabled,
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
          notificationEnabled: notificationEnabled,
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
          _refreshingFeedIds.add(source.id);
        }
        notifyListeners();

        try {
          final List<Future<_ControllerFeedFetchResult?>> fetchFutures =
              candidates.map((FeedSource source) async {
            try {
              final ParsedFeedResult parsed =
                  await _rssService.fetchFeed(source.url);
              return _ControllerFeedFetchResult(
                source: source,
                parsedResult: parsed,
              );
            } catch (error) {
              return null;
            } finally {
              _refreshingFeedIds.remove(source.id);
              notifyListeners();
            }
          }).toList();

          final List<_ControllerFeedFetchResult?> fetchResults =
              await Future.wait(fetchFutures);
          final List<_ControllerFeedFetchResult> successfulResults =
              fetchResults.whereType<_ControllerFeedFetchResult>().toList();

          final List<FeedSource> updatedSources = <FeedSource>[];
          final List<List<ParsedArticleDraft>> draftsPerSource =
              <List<ParsedArticleDraft>>[];

          final Map<String, FeedSource> updatedFeedsMap = <String, FeedSource>{
            for (final FeedSource f in _feeds) f.id: f,
          };

          for (final _ControllerFeedFetchResult result in successfulResults) {
            final FeedSource original = result.source;
            final ParsedFeedResult parsed = result.parsedResult;
            final FeedSource refreshedSource = original.copyWith(
              title: original.title.trim().isEmpty ? parsed.title : original.title,
              siteUrl: parsed.siteUrl,
              iconUrl: parsed.iconUrl,
              lastFetchedAt: DateTime.now(),
            );
            updatedFeedsMap[original.id] = refreshedSource;
            updatedSources.add(refreshedSource);
            draftsPerSource.add(parsed.articles);
          }

          if (successfulResults.isNotEmpty) {
            _setFeeds(updatedFeedsMap.values.toList(), dirty: true);
            _mergeArticlesForSources(updatedSources, draftsPerSource);
          }

          await _persistAll();
          _statusMessage = _strings.refreshedAllFeeds(candidates.length);
        } finally {
          for (final FeedSource source in candidates) {
            _refreshingFeedIds.remove(source.id);
          }
          notifyListeners();
        }
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

  Future<AutoRefreshRunResult> refreshDueAutoRefreshFeeds(
      {DateTime? now}) async {
    if (_isBusy) {
      return const AutoRefreshRunResult(
        attemptedCount: 0,
        refreshedCount: 0,
        sourceUpdates: <AutoRefreshSourceUpdate>[],
      );
    }

    final AutoRefreshRunResult result =
        await _autoRefreshEngine.refreshPersistedDueFeeds(now: now);
    if (result.attemptedCount == 0) {
      return result;
    }

    await reloadPersistedState();
    return result;
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

  bool isFeedNotificationConfigurable(FeedSource source) {
    if (_settings.autoRefreshMode == AutoRefreshMode.allOn) {
      return source.enabled;
    }
    return source.enabled && source.autoRefreshEnabled;
  }

  bool isFeedEffectivelyNotificationEnabled(FeedSource source) {
    return isFeedNotificationConfigurable(source) && source.notificationEnabled;
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

  Article? articleForId(String articleId) => _articleById(articleId);

  FeedSource? feedForId(String feedId) => _feedById(feedId);

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

  Future<void> navigateToHomeFromNotification() async {
    _currentRoute = AppRouteId.allArticles;
    _lastWorkspaceRoute = AppRouteId.allArticles;
    _activeSourceId = null;
    _selectedArticleId = null;
    _compactReaderOpen = false;
    notifyListeners();
  }

  Future<void> navigateToSourceFromNotification(String sourceId) async {
    final FeedSource? source = _feedById(sourceId);
    if (source == null) {
      await navigateToHomeFromNotification();
      return;
    }
    _currentRoute = AppRouteId.allArticles;
    _lastWorkspaceRoute = AppRouteId.allArticles;
    _activeSourceId = source.id;
    _selectedArticleId = null;
    _compactReaderOpen = false;
    notifyListeners();
  }

  Future<void> navigateToArticleFromNotification(String articleId) async {
    final Article? article = _articleById(articleId);
    if (article == null) {
      await navigateToHomeFromNotification();
      return;
    }
    _currentRoute = AppRouteId.allArticles;
    _lastWorkspaceRoute = AppRouteId.allArticles;
    final FeedSource? source = _feedById(article.sourceId);
    if (source != null) {
      _activeSourceId = source.id;
    }
    await selectArticle(article, openInReaderRoute: true);
  }

  Future<void> _loadUserState() async {
    _currentUserSession = await _store.loadCurrentUserSession();
    final String? identityCode = _currentUserSession.identityCode;
    if (identityCode == null || identityCode.isEmpty) {
      _currentUser = null;
      return;
    }

    _currentUser = await _store.loadUserProfile(identityCode) ??
        await _createLocalUserProfile(identityCode);
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
    _mergeArticlesForSources(
      <FeedSource>[source],
      <List<ParsedArticleDraft>>[drafts],
    );
  }

  void _mergeArticlesForSources(
    List<FeedSource> sources,
    List<List<ParsedArticleDraft>> draftsPerSource,
  ) {
    final Map<String, Article> currentById = <String, Article>{
      for (final Article article in _articles) article.id: article,
    };
    final Map<String, Map<String, Article>> currentBySourceAndUrl =
        <String, Map<String, Article>>{};
    for (final Article article in _articles) {
      if (article.url.trim().isNotEmpty) {
        currentBySourceAndUrl
            .putIfAbsent(article.sourceId, () => <String, Article>{})
            [article.url] = article;
      }
    }

    for (int i = 0; i < sources.length; i++) {
      final FeedSource source = sources[i];
      final List<ParsedArticleDraft> drafts = draftsPerSource[i];
      final Map<String, Article> sourceUrlMap =
          currentBySourceAndUrl[source.id] ?? const <String, Article>{};

      for (final ParsedArticleDraft draft in drafts) {
        final String draftUrl = draft.url.trim();
        final String candidateId = _rssService.stableArticleId(source.id, draft);
        final Article? existing =
            currentById[candidateId] ?? sourceUrlMap[draftUrl];
        final String articleId = existing?.id ?? candidateId;

        if (existing != null && existing.id != articleId) {
          currentById.remove(existing.id);
        }

        final Article nextArticle = Article(
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
        currentById[articleId] = nextArticle;

        if (draftUrl.isNotEmpty) {
          currentBySourceAndUrl
              .putIfAbsent(source.id, () => <String, Article>{})
              [draftUrl] = nextArticle;
        }
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

  Future<void> _activateUserSession(
    UserProfile profile, {
    required String statusMessage,
  }) async {
    _errorMessage = null;
    final CurrentUserSession session = CurrentUserSession(
      identityCode: profile.identityCode,
    );
    await _store.saveCurrentUserSession(session);
    _currentUserSession = session;
    _currentUser = profile;
    _statusMessage = statusMessage;
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

  Future<void> _runUserBusyTask(
    Future<void> Function() action, {
    String? onCloudErrorFallback,
  }) async {
    _errorMessage = null;
    _isBusy = true;
    notifyListeners();
    try {
      await action();
    } on CloudServiceException catch (error) {
      _errorMessage = _cloudOperationMessage(
        error,
        fallback: onCloudErrorFallback ?? _strings.accountCloudUnavailable,
      );
    } catch (error) {
      _errorMessage = '$error';
    } finally {
      _isBusy = false;
      notifyListeners();
    }
  }

  bool _canCreateIdentityCode() {
    if (_identitySyncService.isConfigured) {
      return true;
    }
    _errorMessage = _identityCloudUnavailableMessage;
    notifyListeners();
    return false;
  }

  bool _ensureIdentitySyncConfigured() {
    if (_identitySyncService.isConfigured) {
      return true;
    }
    _errorMessage = _identityCloudUnavailableMessage;
    notifyListeners();
    return false;
  }

  bool _ensureContentSyncConfigured() {
    if (_contentSyncService.isConfigured) {
      return true;
    }
    _errorMessage = _contentCloudUnavailableMessage;
    notifyListeners();
    return false;
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

  Future<UserProfile> _createLocalUserProfile(String identityCode) async {
    final UserProfile profile = UserProfile.createEmpty(identityCode);
    await _store.saveUserProfile(profile);
    return profile;
  }

  Future<UserProfile> _createOfflinePendingUser({
    required String identityCode,
    required String initialUserName,
  }) async {
    final DateTime now = DateTime.now();
    final UserProfile profile = UserProfile.createEmpty(
      identityCode,
      now: now,
    ).copyWith(
      displayName: _normalizeCloudUserName(initialUserName),
      updatedAt: now,
      lastCloudSyncStatus: CloudSyncStatus.failed,
      lastCloudSyncMessage: _accountCloudCreatePendingMessage,
      pendingCloudCreate: true,
    );
    return _persistUserProfile(profile);
  }

  Future<UserProfile> _persistUserProfile(UserProfile profile) async {
    await _store.saveUserProfile(profile);
    return profile;
  }

  Future<UserProfile> _upsertCloudUserProfile({
    required String identityCode,
    required String userName,
    required CloudSyncStatus syncStatus,
    required String syncMessage,
  }) async {
    final DateTime now = DateTime.now();
    final UserProfile baseProfile =
        await _store.loadUserProfile(identityCode) ??
            UserProfile.createEmpty(identityCode, now: now);
    final UserProfile nextProfile = baseProfile.copyWith(
      displayName: _normalizeCloudUserName(userName),
      updatedAt: now,
      lastCloudSyncAt: now,
      lastCloudSyncStatus: syncStatus,
      lastCloudSyncMessage: syncMessage,
      pendingCloudCreate: false,
      pendingCloudProfileSync: false,
    );
    return _persistUserProfile(nextProfile);
  }

  String get _defaultCloudUserName => _strings.accountUnnamedUser;

  String _normalizeCloudUserName(String rawValue) {
    final String trimmed = rawValue.trim();
    final String normalized = trimmed.isEmpty ? _defaultCloudUserName : trimmed;
    if (normalized.length <= 64) {
      return normalized;
    }
    return normalized.substring(0, 64);
  }

  String _localizedCloudText({
    required String zhHans,
    String? zhHant,
    required String en,
  }) {
    final Locale locale = _settings.appLanguageMode.explicitLocale ??
        PlatformDispatcher.instance.locale;
    if (locale.languageCode == 'zh') {
      final bool traditional =
          locale.scriptCode == 'Hant' || locale.countryCode == 'TW';
      return traditional ? (zhHant ?? zhHans) : zhHans;
    }
    return en;
  }

  String get _identityCloudUnavailableMessage {
    if (usesPrivateIdentityCloud) {
      return _localizedCloudText(
        zhHans: '个人云服务器尚未配置。',
        zhHant: '個人雲伺服器尚未設定。',
        en: 'The personal cloud server is not configured yet.',
      );
    }
    return _strings.accountCloudUnavailable;
  }

  String get _contentCloudUnavailableMessage {
    if (usesPrivateContentCloud) {
      return _localizedCloudText(
        zhHans: '个人云服务器尚未配置。',
        zhHant: '個人雲伺服器尚未設定。',
        en: 'The personal cloud server is not configured yet.',
      );
    }
    return _strings.accountCloudUnavailable;
  }

  String get _cloudConnectionFailedMessage {
    if (usesPrivateIdentityCloud || usesPrivateContentCloud) {
      return _localizedCloudText(
        zhHans: '无法连接个人云服务器。',
        zhHant: '無法連線到個人雲伺服器。',
        en: 'The app could not connect to the personal cloud server.',
      );
    }
    return _strings.accountCloudConnectionFailed;
  }

  String get _identityCodeNotFoundMessage {
    if (usesPrivateIdentityCloud) {
      return _localizedCloudText(
        zhHans: '该身份代码不存在于个人云。',
        zhHant: '此身分代碼不存在於個人雲。',
        en: 'This identity code does not exist in the personal cloud.',
      );
    }
    return _strings.accountIdentityCodeNotFound;
  }

  String get _accountRegistrationCompletedMessage {
    if (usesPrivateIdentityCloud) {
      return _localizedCloudText(
        zhHans: '身份代码已注册到个人云。',
        zhHant: '身分代碼已註冊到個人雲。',
        en: 'The identity code has been registered with the personal cloud.',
      );
    }
    return _strings.accountCloudRegistrationCompleted;
  }

  String get _accountGeneratedAndSignedInMessage {
    if (usesPrivateIdentityCloud) {
      return _localizedCloudText(
        zhHans: '身份代码已创建并连接到个人云，当前身份已启用。',
        zhHant: '身分代碼已建立並連線到個人雲，目前身分已啟用。',
        en: 'The identity code was created in the personal cloud and is now active.',
      );
    }
    return _strings.accountGeneratedAndSignedInCloud;
  }

  String get _accountGeneratedOfflinePendingMessage {
    if (usesPrivateIdentityCloud) {
      return _localizedCloudText(
        zhHans: '身份代码已先保存在本地，恢复联网后会自动注册到个人云。',
        zhHant: '身分代碼已先儲存在本機，恢復連線後會自動註冊到個人雲。',
        en: 'The identity code was saved locally and will register with the personal cloud when the app is back online.',
      );
    }
    return _strings.accountGeneratedOfflinePending;
  }

  String get _accountLoginLoadedMessage {
    if (usesPrivateIdentityCloud) {
      return _localizedCloudText(
        zhHans: '已从个人云加载当前身份资料。',
        zhHant: '已從個人雲載入目前身分資料。',
        en: 'Loaded the current profile from the personal cloud.',
      );
    }
    return _strings.accountCloudLoginLoaded;
  }

  String get _accountSignedInMessage {
    if (usesPrivateIdentityCloud) {
      return _localizedCloudText(
        zhHans: '已通过个人云登录。',
        zhHant: '已透過個人雲登入。',
        en: 'Signed in through the personal cloud.',
      );
    }
    return _strings.accountSignedInCloud;
  }

  String get _accountDisplayNameUpdatedMessage {
    if (usesPrivateIdentityCloud) {
      return _localizedCloudText(
        zhHans: '用户名已更新并同步到个人云。',
        zhHant: '使用者名稱已更新並同步到個人雲。',
        en: 'The user name was updated and synced to the personal cloud.',
      );
    }
    return _strings.accountDisplayNameUpdatedCloud;
  }

  String get _accountUserNameSyncFailedMessage {
    if (usesPrivateIdentityCloud) {
      return _localizedCloudText(
        zhHans: '用户名已保存在本地，但同步到个人云失败了。',
        zhHant: '使用者名稱已儲存在本機，但同步到個人雲失敗了。',
        en: 'The user name was updated locally, but syncing it to the personal cloud failed.',
      );
    }
    return _strings.accountUserNameSyncFailed;
  }

  String get _accountAvatarPendingSyncMessage {
    if (usesPrivateContentCloud || usesPrivateIdentityCloud) {
      return _localizedCloudText(
        zhHans: '头像已更新，本地保存后会自动同步到个人云。',
        zhHant: '頭像已更新，本機儲存後會自動同步到個人雲。',
        en: 'The avatar was updated locally and will sync to the personal cloud automatically.',
      );
    }
    return _strings.accountAvatarPendingSync;
  }

  String get _accountCloudCreatePendingMessage {
    if (usesPrivateIdentityCloud) {
      return _localizedCloudText(
        zhHans: '该身份代码已保存在本地，恢复联网后会注册到个人云。',
        zhHant: '此身分代碼已儲存在本機，恢復連線後會註冊到個人雲。',
        en: 'This identity code was saved locally and will register with the personal cloud once the app is back online.',
      );
    }
    return _strings.accountCloudCreatePending;
  }

  String get _accountCloudAutoSyncPendingMessage {
    if (usesPrivateIdentityCloud || usesPrivateContentCloud) {
      return _localizedCloudText(
        zhHans: '个人云还有待同步的资料，应用恢复联网后会继续补传。',
        zhHant: '個人雲仍有待同步資料，應用恢復連線後會繼續補傳。',
        en: 'Some personal cloud data is still pending and will sync after the app is back online.',
      );
    }
    return _strings.accountCloudAutoSyncPending;
  }

  String get _accountCloudAutoSyncCompletedMessage {
    if (usesPrivateIdentityCloud || usesPrivateContentCloud) {
      return _localizedCloudText(
        zhHans: '应用恢复联网后，个人云资料已自动同步完成。',
        zhHant: '應用恢復連線後，個人雲資料已自動同步完成。',
        en: 'The app is back online and personal cloud data finished syncing automatically.',
      );
    }
    return _strings.accountCloudAutoSyncCompleted;
  }

  String get _cloudUploadCompletedMessage {
    if (usesPrivateContentCloud && usesPrivateIdentityCloud) {
      return _localizedCloudText(
        zhHans: '账号信息与内容已同步到个人云。',
        zhHant: '帳號資訊與內容已同步到個人雲。',
        en: 'Account details and content were synced to the personal cloud.',
      );
    }
    if (usesPrivateContentCloud) {
      return _localizedCloudText(
        zhHans: '订阅、文章和头像已同步到个人云。',
        zhHant: '訂閱、文章與頭像已同步到個人雲。',
        en: 'Subscriptions, articles, and avatar were synced to the personal cloud.',
      );
    }
    return _strings.accountCloudUploadCompleted;
  }

  String get _cloudUploadFailedMessage {
    if (usesPrivateContentCloud) {
      return _localizedCloudText(
        zhHans: '上传到个人云失败了，本地数据没有被改动。',
        zhHant: '上傳到個人雲失敗了，本機資料沒有被改動。',
        en: 'Uploading to the personal cloud failed. Local data was left unchanged.',
      );
    }
    return _strings.accountCloudUploadFailed;
  }

  String get _cloudDownloadCompletedMessage {
    if (usesPrivateContentCloud && usesPrivateIdentityCloud) {
      return _localizedCloudText(
        zhHans: '账号信息与内容已从个人云下载到本机。',
        zhHant: '帳號資訊與內容已從個人雲下載到本機。',
        en: 'Account details and content were downloaded from the personal cloud.',
      );
    }
    if (usesPrivateContentCloud) {
      return _localizedCloudText(
        zhHans: '个人云中的订阅、文章和头像已下载到本机。',
        zhHant: '個人雲中的訂閱、文章與頭像已下載到本機。',
        en: 'Subscriptions, articles, and avatar were downloaded from the personal cloud.',
      );
    }
    return _strings.accountCloudDownloadCompleted;
  }

  String get _cloudDownloadFailedMessage {
    if (usesPrivateContentCloud) {
      return _localizedCloudText(
        zhHans: '从个人云下载失败了，本地数据没有被覆盖。',
        zhHant: '從個人雲下載失敗了，本機資料沒有被覆蓋。',
        en: 'Downloading from the personal cloud failed. Local data was not overwritten.',
      );
    }
    return _strings.accountCloudDownloadFailed;
  }

  String _cloudOperationMessage(
    CloudServiceException error, {
    required String fallback,
  }) {
    switch (error.kind) {
      case CloudServiceErrorKind.notConfigured:
        return usesPrivateIdentityCloud || usesPrivateContentCloud
            ? _contentCloudUnavailableMessage
            : _strings.accountCloudUnavailable;
      case CloudServiceErrorKind.network:
        return _cloudConnectionFailedMessage;
      case CloudServiceErrorKind.notFound:
        return _identityCodeNotFoundMessage;
      case CloudServiceErrorKind.conflict:
      case CloudServiceErrorKind.invalidResponse:
      case CloudServiceErrorKind.rejected:
        return fallback;
    }
  }

  bool _canFallbackToOfflineCreate(CloudServiceException error) {
    return error.kind == CloudServiceErrorKind.network;
  }

  bool _shouldAutoSyncPendingAccountState() {
    final UserProfile? profile = _currentUser;
    if (profile == null || !profile.hasPendingAccountSync) {
      return false;
    }
    final bool needsIdentitySync =
        profile.pendingCloudCreate || profile.pendingCloudProfileSync;
    final bool needsContentSync = profile.pendingCloudAvatarSync;
    return (needsIdentitySync && _identitySyncService.isConfigured) ||
        (needsContentSync && _contentSyncService.isConfigured);
  }

  void _triggerPendingAccountSyncIfPossible() {
    if (!_shouldAutoSyncPendingAccountState()) {
      return;
    }
    unawaited(_syncPendingAccountStateIfNeeded());
  }

  Future<void> _syncPendingAccountStateIfNeeded() async {
    if (_syncingPendingAccountState || !_shouldAutoSyncPendingAccountState()) {
      return;
    }
    final UserProfile? currentProfile = _currentUser;
    if (currentProfile == null) {
      return;
    }

    _syncingPendingAccountState = true;
    try {
      UserProfile profile = currentProfile;
      final String normalizedUserName =
          _normalizeCloudUserName(profile.displayName);

      if (profile.pendingCloudCreate && _identitySyncService.isConfigured) {
        try {
          await _identitySyncService.createUser(
            profile.identityCode,
            normalizedUserName,
          );
        } on CloudServiceException catch (error) {
          if (error.kind != CloudServiceErrorKind.conflict) {
            rethrow;
          }
        }
        profile = await _persistUserProfile(profile.copyWith(
          pendingCloudCreate: false,
          pendingCloudProfileSync: true,
          lastCloudSyncStatus: CloudSyncStatus.failed,
          lastCloudSyncMessage: _accountCloudCreatePendingMessage,
        ));
      }

      if (profile.pendingCloudProfileSync &&
          _identitySyncService.isConfigured) {
        await _identitySyncService.updateUser(
          profile.identityCode,
          normalizedUserName,
        );
        profile = await _persistUserProfile(profile.copyWith(
          pendingCloudProfileSync: false,
        ));
      }

      if (_contentSyncService.isConfigured &&
          profile.pendingCloudAvatarSync &&
          profile.hasAvatar &&
          profile.avatarPath != null) {
        final File avatarFile = File(profile.avatarPath!);
        if (await avatarFile.exists()) {
          await _contentSyncService.uploadAvatar(
            profile.identityCode,
            await avatarFile.readAsBytes(),
            'image/jpeg',
          );
        }
        profile = await _persistUserProfile(profile.copyWith(
          pendingCloudAvatarSync: false,
        ));
      }

      final bool hasRemainingPending = profile.hasPendingAccountSync;
      profile = await _persistUserProfile(profile.copyWith(
        lastCloudSyncAt: DateTime.now(),
        lastCloudSyncStatus: hasRemainingPending
            ? CloudSyncStatus.failed
            : CloudSyncStatus.synced,
        lastCloudSyncMessage: hasRemainingPending
            ? _accountCloudAutoSyncPendingMessage
            : _accountCloudAutoSyncCompletedMessage,
      ));
      _currentUser = profile;
    } on CloudServiceException catch (error) {
      final UserProfile? latest = _currentUser;
      if (latest != null) {
        _currentUser = await _persistUserProfile(latest.copyWith(
          lastCloudSyncStatus: CloudSyncStatus.failed,
          lastCloudSyncMessage: _cloudOperationMessage(
            error,
            fallback: _accountCloudAutoSyncPendingMessage,
          ),
        ));
      }
    } finally {
      _syncingPendingAccountState = false;
      notifyListeners();
    }
  }

  List<FeedSource> _decodeCloudFeedsPayload(Map<String, dynamic> payload) {
    final Object? rawFeeds = payload['feeds'];
    if (rawFeeds is! List<dynamic>) {
      return <FeedSource>[];
    }
    return rawFeeds
        .whereType<Map<dynamic, dynamic>>()
        .map((Map<dynamic, dynamic> json) {
      return FeedSource.fromJson(Map<String, dynamic>.from(json));
    }).toList();
  }

  List<Article> _decodeCloudArticlesPayload(Map<String, dynamic> payload) {
    final Object? rawArticles = payload['articles'];
    if (rawArticles is! List<dynamic>) {
      return <Article>[];
    }
    return rawArticles
        .whereType<Map<dynamic, dynamic>>()
        .map((Map<dynamic, dynamic> json) {
      return Article.fromJson(Map<String, dynamic>.from(json));
    }).toList()
      ..sort((Article a, Article b) => b.publishedAt.compareTo(a.publishedAt));
  }

  Future<UserProfile> _buildProfileWithDownloadedAvatar(
    UserProfile profile,
    Uint8List? avatarBytes,
  ) async {
    if (avatarBytes == null) {
      await _store.deleteUserAvatar(profile.identityCode);
      return profile.copyWith(
        clearAvatarPath: true,
      );
    }

    final Uint8List normalizedAvatar = _normalizeAvatarBytesAsJpg(avatarBytes);
    final String avatarPath = await _store.saveUserAvatar(
      profile.identityCode,
      normalizedAvatar,
    );
    return profile.copyWith(
      avatarPath: avatarPath,
    );
  }

  Uint8List _buildCenteredSquareAvatar(Uint8List sourceBytes) {
    final img.Image? decoded = img.decodeImage(sourceBytes);
    if (decoded == null) {
      throw FormatException(_strings.accountAvatarUnsupported);
    }

    final int squareSize = min(decoded.width, decoded.height);
    final int cropX = ((decoded.width - squareSize) / 2).round();
    final int cropY = ((decoded.height - squareSize) / 2).round();
    final img.Image cropped = img.copyCrop(
      decoded,
      x: cropX,
      y: cropY,
      width: squareSize,
      height: squareSize,
    );
    final img.Image resized = squareSize > 512
        ? img.copyResize(cropped, width: 512, height: 512)
        : cropped;
    return Uint8List.fromList(img.encodeJpg(resized, quality: 88));
  }

  Uint8List _normalizeAvatarBytesAsJpg(Uint8List sourceBytes) {
    final img.Image? decoded = img.decodeImage(sourceBytes);
    if (decoded == null) {
      throw FormatException(_strings.accountAvatarUnsupported);
    }
    final img.Image resized = decoded.width > 512 || decoded.height > 512
        ? img.copyResize(decoded,
            width: decoded.width >= decoded.height ? 512 : null,
            height: decoded.height > decoded.width ? 512 : null)
        : decoded;
    return Uint8List.fromList(img.encodeJpg(resized, quality: 88));
  }
}

class _ControllerFeedFetchResult {
  const _ControllerFeedFetchResult({
    required this.source,
    required this.parsedResult,
  });

  final FeedSource source;
  final ParsedFeedResult parsedResult;
}

