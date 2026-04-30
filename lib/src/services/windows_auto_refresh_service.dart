import 'dart:async';
import 'dart:io';
import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:path/path.dart' as path;
import 'package:tray_manager/tray_manager.dart';
import 'package:window_manager/window_manager.dart';

import '../localization/app_strings.dart';
import '../models/feed_source.dart';
import '../state/reader_controller.dart';

class WindowsAutoRefreshService
    with TrayListener, WindowListener, WidgetsBindingObserver {
  WindowsAutoRefreshService({
    required this.controller,
  });

  final ReaderController controller;

  Timer? _timer;
  bool _trayReady = false;
  bool _disposed = false;
  bool _isHandlingDueFeeds = false;
  bool _isExiting = false;
  String _lastSchedulingSignature = '';
  String _lastPresentationSignature = '';

  bool get _isSupported =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.windows;

  AppStrings get _strings => AppStrings.fromLanguageMode(
        controller.settings.appLanguageMode,
        systemLocale: PlatformDispatcher.instance.locale,
      );

  Future<void> initialize() async {
    if (!_isSupported) {
      return;
    }

    WidgetsBinding.instance.addObserver(this);
    trayManager.addListener(this);
    windowManager.addListener(this);
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
    windowManager.removeListener(this);
    trayManager.removeListener(this);
    WidgetsBinding.instance.removeObserver(this);
    if (_trayReady) {
      await trayManager.destroy();
      _trayReady = false;
    }
    await windowManager.setPreventClose(false);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      unawaited(_rescheduleAutoRefresh());
    }
  }

  @override
  void onWindowClose() async {
    if (!_shouldRunInTray || _isExiting) {
      return;
    }
    if (await windowManager.isPreventClose()) {
      await _hideToTray();
    }
  }

  @override
  void onWindowFocus() {
    unawaited(_rescheduleAutoRefresh());
  }

  @override
  void onWindowRestore() {
    unawaited(_rescheduleAutoRefresh());
  }

  @override
  void onTrayIconMouseDown() {
    unawaited(_showWindow());
  }

  @override
  void onTrayIconRightMouseDown() {
    unawaited(trayManager.popUpContextMenu());
  }

  @override
  void onTrayMenuItemClick(MenuItem menuItem) {
    switch (menuItem.key) {
      case 'show_window':
        unawaited(_showWindow());
        return;
      case 'refresh_due':
        unawaited(_runDueAutoRefreshes());
        return;
      case 'exit_app':
        unawaited(_exitApplication());
        return;
    }
  }

  bool get _shouldRunInTray => controller.settings.autoRefreshEnabled;

  void _handleControllerChanged() {
    unawaited(_syncFromController());
  }

  Future<void> _syncFromController({bool force = false}) async {
    if (_disposed || !_isSupported) {
      return;
    }

    final String schedulingSignature = _buildSchedulingSignature();
    final String presentationSignature = _buildPresentationSignature();

    if (!force &&
        schedulingSignature == _lastSchedulingSignature &&
        presentationSignature == _lastPresentationSignature) {
      return;
    }

    _lastSchedulingSignature = schedulingSignature;
    _lastPresentationSignature = presentationSignature;

    if (_shouldRunInTray) {
      await _ensureTrayReady();
      await windowManager.setPreventClose(true);
      await _updateTrayPresentation();
      await _rescheduleAutoRefresh();
      return;
    }

    _timer?.cancel();
    _timer = null;
    await windowManager.setPreventClose(false);
    if (_trayReady) {
      await trayManager.destroy();
      _trayReady = false;
    }
  }

  Future<void> _ensureTrayReady() async {
    if (_trayReady) {
      return;
    }

    await trayManager.setIcon(_resolveTrayIconPath());
    await trayManager.setToolTip(_strings.appFullName);
    _trayReady = true;
  }

  Future<void> _updateTrayPresentation() async {
    if (!_trayReady) {
      return;
    }

    await trayManager.setToolTip(_strings.appFullName);
    await trayManager.setContextMenu(
      Menu(
        items: <MenuItem>[
          MenuItem(
            key: 'show_window',
            label: _strings.trayShowWindow,
          ),
          MenuItem(
            key: 'refresh_due',
            label: _strings.trayRefreshDueFeeds,
          ),
          MenuItem.separator(),
          MenuItem(
            key: 'exit_app',
            label: _strings.trayExitApp,
          ),
        ],
      ),
    );
  }

  Future<void> _rescheduleAutoRefresh() async {
    if (_disposed || !_isSupported) {
      return;
    }

    _timer?.cancel();
    _timer = null;

    if (!_shouldRunInTray || _isHandlingDueFeeds) {
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
    if (_disposed || !_shouldRunInTray || _isHandlingDueFeeds) {
      return;
    }

    _isHandlingDueFeeds = true;
    _timer?.cancel();
    _timer = null;

    try {
      await controller.refreshDueAutoRefreshFeeds();
    } finally {
      _isHandlingDueFeeds = false;
      if (!_disposed) {
        await _rescheduleAutoRefresh();
      }
    }
  }

  Future<void> _showWindow() async {
    if (!_isSupported) {
      return;
    }
    await windowManager.setSkipTaskbar(false);
    await windowManager.show();
    await windowManager.restore();
    await windowManager.focus();
  }

  Future<void> _hideToTray() async {
    if (!_trayReady) {
      return;
    }
    await windowManager.setSkipTaskbar(true);
    await windowManager.hide();
  }

  Future<void> _exitApplication() async {
    _isExiting = true;
    _timer?.cancel();
    _timer = null;
    if (_trayReady) {
      await trayManager.destroy();
      _trayReady = false;
    }
    await windowManager.setPreventClose(false);
    await windowManager.close();
  }

  String _resolveTrayIconPath() {
    final String executableDir = path.dirname(Platform.resolvedExecutable);
    return path.join(
      executableDir,
      'data',
      'flutter_assets',
      'assets',
      'app_icon.ico',
    );
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

  String _buildPresentationSignature() {
    return '${controller.settings.appLanguageMode.name}|'
        '${controller.settings.autoRefreshMode.name}|'
        '${controller.settings.globalAutoRefreshIntervalMinutes}';
  }
}
