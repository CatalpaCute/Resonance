import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:window_manager/window_manager.dart';

import '../models/reader_settings.dart';
import '../state/reader_controller.dart';
import 'auto_refresh_engine.dart';

const String _kNotificationChannelId = 'subscription_updates';
const String _kNotificationChannelName =
    '\u8ba2\u9605\u66f4\u65b0\u901a\u77e5';
const String _kNotificationChannelDescription =
    '\u81ea\u52a8\u66f4\u65b0\u8ba2\u9605\u65f6\u63d0\u9192\u65b0\u6587\u7ae0';
const String _kWindowsNotificationGuid = '6b2a1b35-8e72-41a2-bc4c-6e5cb62a4c09';

/// 设计意图：
/// 统一用系统原生通知通道承接“自动更新带来新文章”的提醒，避免把通知逻辑散落到
/// Windows 托盘调度器和 Android Worker 里。Windows 和 Android 只负责告诉它：
/// “这轮自动更新新增了什么”，通知服务再决定是否提醒、提醒成什么样、点开后去哪。
class SubscriptionNotificationService with WidgetsBindingObserver {
  SubscriptionNotificationService._({ReaderController? controller})
      : _controller = controller;

  static final SubscriptionNotificationService instance =
      SubscriptionNotificationService._();

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  ReaderController? _controller;
  bool _initialized = false;
  bool _observerAttached = false;
  String? _pendingPayload;
  AppLifecycleState _lifecycleState = AppLifecycleState.resumed;
  int _notificationSequence = 0;

  static bool get _isSupportedNativePlatform =>
      !kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.android ||
          defaultTargetPlatform == TargetPlatform.iOS ||
          defaultTargetPlatform == TargetPlatform.macOS ||
          defaultTargetPlatform == TargetPlatform.linux ||
          defaultTargetPlatform == TargetPlatform.windows);

  Future<void> initialize({
    required ReaderController controller,
  }) async {
    if (!_isSupportedNativePlatform) {
      return;
    }
    _controller = controller;
    await _ensureInitialized(readLaunchDetails: true);
    _attachObserverIfNeeded();
    await _applyPendingPayloadIfAny();
  }

  Future<void> ensureNotificationPermissionRequested() async {
    if (!_isSupportedNativePlatform) {
      return;
    }
    await _ensureInitialized();
    await _requestPermissions();
  }

  Future<void> notifyAutoRefreshResult({
    required ReaderSettings settings,
    required AutoRefreshRunResult result,
    bool allowWhenForeground = false,
  }) async {
    if (!_isSupportedNativePlatform || result.sourceUpdates.isEmpty) {
      return;
    }
    if (!allowWhenForeground && await _isAppInForeground()) {
      return;
    }
    await _ensureInitialized();
    await _dispatchNotifications(
      settings: settings,
      result: result,
    );
  }

  static Future<void> showBackgroundAutoRefreshNotifications({
    required ReaderSettings settings,
    required AutoRefreshRunResult result,
  }) async {
    if (!_isSupportedNativePlatform || result.sourceUpdates.isEmpty) {
      return;
    }
    final SubscriptionNotificationService service =
        SubscriptionNotificationService._();
    await service._ensureInitialized();
    await service._dispatchNotifications(
      settings: settings,
      result: result,
    );
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _lifecycleState = state;
    if (state == AppLifecycleState.resumed) {
      unawaited(_applyPendingPayloadIfAny());
    }
  }

  Future<void> _ensureInitialized({bool readLaunchDetails = false}) async {
    if (_initialized) {
      return;
    }

    final InitializationSettings settings = InitializationSettings(
      android: const AndroidInitializationSettings('notification_icon'),
      iOS: const DarwinInitializationSettings(),
      macOS: const DarwinInitializationSettings(),
      linux: const LinuxInitializationSettings(
        defaultActionName: '\u6253\u5f00',
      ),
      windows: const WindowsInitializationSettings(
        appName: 'Resonance',
        appUserModelId: 'work.czzzz.reader',
        guid: _kWindowsNotificationGuid,
      ),
    );

    await _plugin.initialize(
      settings,
      onDidReceiveNotificationResponse: _handleNotificationResponse,
    );

    await _configurePlatformNotificationPrimitives();

    if (readLaunchDetails) {
      final NotificationAppLaunchDetails? launchDetails =
          await _plugin.getNotificationAppLaunchDetails();
      if (launchDetails?.didNotificationLaunchApp ?? false) {
        _pendingPayload = launchDetails?.notificationResponse?.payload;
      }
    }

    _initialized = true;
  }

  Future<void> _configurePlatformNotificationPrimitives() async {
    if (defaultTargetPlatform != TargetPlatform.android) {
      return;
    }

    final AndroidFlutterLocalNotificationsPlugin? androidPlugin = _plugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();
    if (androidPlugin == null) {
      return;
    }

    const AndroidNotificationChannel channel = AndroidNotificationChannel(
      _kNotificationChannelId,
      _kNotificationChannelName,
      description: _kNotificationChannelDescription,
      importance: Importance.high,
    );
    await androidPlugin.createNotificationChannel(channel);
  }

  void _attachObserverIfNeeded() {
    if (_observerAttached) {
      return;
    }
    WidgetsBinding.instance.addObserver(this);
    _observerAttached = true;
  }

  Future<void> _requestPermissions() async {
    if (defaultTargetPlatform == TargetPlatform.android) {
      await _plugin
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>()
          ?.requestNotificationsPermission();
      return;
    }
    if (defaultTargetPlatform == TargetPlatform.iOS) {
      await _plugin
          .resolvePlatformSpecificImplementation<
              IOSFlutterLocalNotificationsPlugin>()
          ?.requestPermissions(
            alert: true,
            badge: true,
            sound: true,
          );
      return;
    }
    if (defaultTargetPlatform == TargetPlatform.macOS) {
      await _plugin
          .resolvePlatformSpecificImplementation<
              MacOSFlutterLocalNotificationsPlugin>()
          ?.requestPermissions(
            alert: true,
            badge: true,
            sound: true,
          );
    }
  }

  Future<void> _dispatchNotifications({
    required ReaderSettings settings,
    required AutoRefreshRunResult result,
  }) async {
    final List<AutoRefreshSourceUpdate> enabledUpdates = result.sourceUpdates
        .where(
          (AutoRefreshSourceUpdate update) =>
              update.notificationEnabled && update.newArticles.isNotEmpty,
        )
        .toList(growable: false);
    if (enabledUpdates.isEmpty) {
      return;
    }

    switch (settings.subscriptionNotificationMode) {
      case SubscriptionNotificationMode.sourceSummary:
        for (final AutoRefreshSourceUpdate update in enabledUpdates) {
          final List<String> titles = update.newArticles
              .take(3)
              .map((AutoRefreshNewArticle article) => article.title)
              .toList(growable: false);
          await _plugin.show(
            _nextNotificationId(),
            update.sourceTitle,
            _buildSourceSummaryBody(
              articleCount: update.newArticles.length,
              titles: titles,
            ),
            _details(
              title: update.sourceTitle,
              body: _buildSourceSummaryBody(
                articleCount: update.newArticles.length,
                titles: titles,
              ),
              subtitle: '\u8ba2\u9605\u6709\u65b0\u6587\u7ae0',
            ),
            payload: _payload(
              type: _NotificationPayloadType.source,
              sourceId: update.sourceId,
            ),
          );
        }
        return;
      case SubscriptionNotificationMode.perArticle:
        for (final AutoRefreshSourceUpdate update in enabledUpdates) {
          for (final AutoRefreshNewArticle article in update.newArticles) {
            await _plugin.show(
              _nextNotificationId(),
              article.title,
              update.sourceTitle,
              _details(
                title: article.title,
                body: update.sourceTitle,
                subtitle: '\u8ba2\u9605\u6709\u65b0\u6587\u7ae0',
              ),
              payload: _payload(
                type: _NotificationPayloadType.article,
                sourceId: article.sourceId,
                articleId: article.articleId,
              ),
            );
          }
        }
        return;
      case SubscriptionNotificationMode.minimal:
        for (final AutoRefreshSourceUpdate update in enabledUpdates) {
          await _plugin.show(
            _nextNotificationId(),
            '${update.sourceTitle} \u6709\u65b0\u6587\u7ae0',
            '\u81ea\u52a8\u66f4\u65b0\u521a\u5e26\u56de ${update.newArticles.length} \u7bc7\u65b0\u5185\u5bb9',
            _details(
              title: '${update.sourceTitle} \u6709\u65b0\u6587\u7ae0',
              body:
                  '\u81ea\u52a8\u66f4\u65b0\u521a\u5e26\u56de ${update.newArticles.length} \u7bc7\u65b0\u5185\u5bb9',
              subtitle: '\u70b9\u51fb\u6253\u5f00\u9996\u9875',
            ),
            payload: _payload(type: _NotificationPayloadType.home),
          );
        }
        return;
    }
  }

  NotificationDetails _details({
    required String title,
    required String body,
    String? subtitle,
  }) {
    return NotificationDetails(
      android: AndroidNotificationDetails(
        _kNotificationChannelId,
        _kNotificationChannelName,
        channelDescription: _kNotificationChannelDescription,
        icon: 'notification_icon',
        importance: Importance.high,
        priority: Priority.high,
        styleInformation: BigTextStyleInformation(body),
      ),
      iOS: DarwinNotificationDetails(
        subtitle: subtitle,
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      ),
      macOS: DarwinNotificationDetails(
        subtitle: subtitle,
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      ),
      linux: LinuxNotificationDetails(
      ),
      windows: WindowsNotificationDetails(
      ),
    );
  }

  String _buildSourceSummaryBody({
    required int articleCount,
    required List<String> titles,
  }) {
    final String countPart =
        '\u65b0\u589e $articleCount \u7bc7\u6587\u7ae0';
    if (titles.isEmpty) {
      return countPart;
    }
    return '$countPart\uff1a${titles.join('\u3001')}';
  }

  Future<bool> _isAppInForeground() async {
    if (kIsWeb) {
      return false;
    }
    if (defaultTargetPlatform == TargetPlatform.windows) {
      try {
        return await windowManager.isVisible();
      } catch (_) {
        return false;
      }
    }
    return _lifecycleState == AppLifecycleState.resumed;
  }

  int _nextNotificationId() {
    _notificationSequence += 1;
    return DateTime.now().millisecondsSinceEpoch.remainder(1 << 30) +
        _notificationSequence;
  }

  String _payload({
    required _NotificationPayloadType type,
    String? sourceId,
    String? articleId,
  }) {
    return jsonEncode(<String, String>{
      'type': type.name,
      if (sourceId != null) 'sourceId': sourceId,
      if (articleId != null) 'articleId': articleId,
    });
  }

  Future<void> _handleNotificationResponse(
    NotificationResponse response,
  ) async {
    if (response.payload == null || response.payload!.isEmpty) {
      return;
    }
    _pendingPayload = response.payload;
    await _applyPendingPayloadIfAny();
  }

  Future<void> _applyPendingPayloadIfAny() async {
    final ReaderController? controller = _controller;
    final String? payload = _pendingPayload;
    if (controller == null || payload == null || payload.isEmpty) {
      return;
    }

    _pendingPayload = null;

    try {
      final Map<String, dynamic> data =
          jsonDecode(payload) as Map<String, dynamic>;
      final _NotificationPayloadType type = _NotificationPayloadType.values
          .firstWhere(
            (_NotificationPayloadType value) => value.name == data['type'],
            orElse: () => _NotificationPayloadType.home,
          );

      switch (type) {
        case _NotificationPayloadType.home:
          await controller.navigateToHomeFromNotification();
          return;
        case _NotificationPayloadType.source:
          await controller.navigateToSourceFromNotification(
            data['sourceId'] as String? ?? '',
          );
          return;
        case _NotificationPayloadType.article:
          await controller.navigateToArticleFromNotification(
            data['articleId'] as String? ?? '',
          );
          return;
      }
    } catch (_) {
      await controller.navigateToHomeFromNotification();
    }
  }
}

enum _NotificationPayloadType {
  home,
  source,
  article,
}
