import 'package:flutter/widgets.dart';

import '../models/feed_source.dart';
import '../state/reader_controller.dart';
import 'android_auto_refresh_scheduler.dart';
import 'auto_refresh_engine.dart';

class AndroidAutoRefreshService with WidgetsBindingObserver {
  AndroidAutoRefreshService({
    required this.controller,
  }) : _engine = AutoRefreshEngine.defaultInstance();

  final ReaderController controller;
  final AutoRefreshEngine _engine;

  bool _disposed = false;
  bool _isHandlingForegroundRefresh = false;
  bool _isHandlingResume = false;
  String _lastSchedulingSignature = '';

  bool get _isSupported => AndroidAutoRefreshScheduler.isSupported;

  Future<void> initialize() async {
    if (!_isSupported) {
      return;
    }

    WidgetsBinding.instance.addObserver(this);
    controller.addListener(_handleControllerChanged);
    await _syncFromController(
      force: true,
      allowForegroundRefresh: false,
    );
  }

  Future<void> dispose() async {
    if (_disposed || !_isSupported) {
      return;
    }

    _disposed = true;
    controller.removeListener(_handleControllerChanged);
    WidgetsBinding.instance.removeObserver(this);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _handleAppResumed();
    }
  }

  void _handleControllerChanged() {
    _syncFromController();
  }

  Future<void> _handleAppResumed() async {
    if (_disposed || !_isSupported || _isHandlingResume) {
      return;
    }

    _isHandlingResume = true;
    try {
      await controller.reloadPersistedState();
      await _syncFromController(force: true);

      final List<FeedSource> dueFeeds = controller.dueAutoRefreshFeeds();
      if (dueFeeds.isNotEmpty && !controller.isBusy) {
        await _runForegroundDueRefreshes();
      }
    } finally {
      _isHandlingResume = false;
    }
  }

  Future<void> _syncFromController({
    bool force = false,
    bool allowForegroundRefresh = true,
  }) async {
    if (_disposed || !_isSupported) {
      return;
    }

    final String schedulingSignature = _buildSchedulingSignature();
    if (!force && schedulingSignature == _lastSchedulingSignature) {
      return;
    }
    _lastSchedulingSignature = schedulingSignature;

    if (!controller.settings.autoRefreshEnabled) {
      await AndroidAutoRefreshScheduler.cancelSchedule();
      return;
    }

    if (controller.isBusy || _isHandlingForegroundRefresh) {
      return;
    }

    final bool isForeground =
        WidgetsBinding.instance.lifecycleState == AppLifecycleState.resumed;
    if (allowForegroundRefresh &&
        isForeground &&
        controller.dueAutoRefreshFeeds().isNotEmpty) {
      await _runForegroundDueRefreshes();
      return;
    }

    await AndroidAutoRefreshScheduler.syncFromSnapshot(
      settings: controller.settings,
      feeds: controller.feeds,
      engine: _engine,
    );
  }

  Future<void> _runForegroundDueRefreshes() async {
    if (_isHandlingForegroundRefresh) {
      return;
    }

    _isHandlingForegroundRefresh = true;
    try {
      await controller.refreshDueAutoRefreshFeeds();
    } finally {
      _isHandlingForegroundRefresh = false;
      if (!_disposed) {
        await _syncFromController(force: true);
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
