import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

import '../models/feed_source.dart';
import '../state/reader_controller.dart';
import 'subscription_notification_service.dart';

/// 设计意图：
/// Linux 端先补齐“应用运行时”的自动更新与系统通知链路，
/// 只复用现有的到期计算、刷新和通知服务，不额外引入托盘、
/// 关闭拦截或平台特有的后台常驻逻辑，尽量保持实现轻量。
class LinuxAutoRefreshService with WidgetsBindingObserver {
  LinuxAutoRefreshService({
    required this.controller,
  });

  final ReaderController controller;

  Timer? _timer;
  bool _disposed = false;
  bool _isHandlingDueFeeds = false;
  String _lastSchedulingSignature = '';

  bool get _isSupported =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.linux;

  Future<void> initialize() async {
    if (!_isSupported) {
      return;
    }

    WidgetsBinding.instance.addObserver(this);
    controller.addListener(_handleControllerChanged);
    await _syncFromController(force: true);
  }

  Future<void> dispose() async {
    if (_disposed || !_isSupported) {
      return;
    }
    _disposed = true;
    _timer?.cancel();
    controller.removeListener(_handleControllerChanged);
    WidgetsBinding.instance.removeObserver(this);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      unawaited(_rescheduleAutoRefresh());
    }
  }

  void _handleControllerChanged() {
    unawaited(_syncFromController());
  }

  Future<void> _syncFromController({bool force = false}) async {
    if (_disposed || !_isSupported) {
      return;
    }

    final String schedulingSignature = _buildSchedulingSignature();
    if (!force && schedulingSignature == _lastSchedulingSignature) {
      return;
    }
    _lastSchedulingSignature = schedulingSignature;

    if (!controller.settings.autoRefreshEnabled) {
      _timer?.cancel();
      _timer = null;
      return;
    }

    await _rescheduleAutoRefresh();
  }

  Future<void> _rescheduleAutoRefresh() async {
    if (_disposed || !_isSupported) {
      return;
    }

    _timer?.cancel();
    _timer = null;

    if (!controller.settings.autoRefreshEnabled || _isHandlingDueFeeds) {
      return;
    }

    if (controller.isBusy) {
      _timer = Timer(
        const Duration(seconds: 45),
        () => unawaited(_rescheduleAutoRefresh()),
      );
      return;
    }

    final List<FeedSource> dueFeeds = controller.dueAutoRefreshFeeds();
    if (dueFeeds.isNotEmpty) {
      unawaited(_runDueAutoRefreshes());
      return;
    }

    final DateTime? nextAt = controller.nextAutoRefreshAt();
    if (nextAt == null) {
      return;
    }

    final Duration delay = nextAt.difference(DateTime.now());
    _timer = Timer(
      delay.isNegative ? Duration.zero : delay,
      () => unawaited(_runDueAutoRefreshes()),
    );
  }

  Future<void> _runDueAutoRefreshes() async {
    if (_disposed ||
        !controller.settings.autoRefreshEnabled ||
        _isHandlingDueFeeds) {
      return;
    }

    _isHandlingDueFeeds = true;
    _timer?.cancel();
    _timer = null;

    try {
      final result = await controller.refreshDueAutoRefreshFeeds();
      await SubscriptionNotificationService.instance.notifyAutoRefreshResult(
        settings: controller.settings,
        result: result,
        allowWhenForeground: true,
      );
    } finally {
      _isHandlingDueFeeds = false;
      if (!_disposed) {
        await _rescheduleAutoRefresh();
      }
    }
  }

  String _buildSchedulingSignature() {
    final StringBuffer buffer = StringBuffer()
      ..write(controller.settings.autoRefreshMode.name)
      ..write(':')
      ..write(controller.settings.globalAutoRefreshIntervalMinutes)
      ..write('|')
      ..write(controller.isBusy);
    for (final FeedSource source in controller.feeds) {
      buffer
        ..write('|')
        ..write(source.id)
        ..write(':')
        ..write(source.enabled)
        ..write(':')
        ..write(source.autoRefreshEnabled)
        ..write(':')
        ..write(source.autoRefreshIntervalMinutes)
        ..write(':')
        ..write(source.lastFetchedAt?.millisecondsSinceEpoch ?? 0)
        ..write(':')
        ..write(source.lastAutoRefreshAttemptAt?.millisecondsSinceEpoch ?? 0);
    }
    return buffer.toString();
  }
}
