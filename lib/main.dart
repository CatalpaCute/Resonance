import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:window_manager/window_manager.dart';

import 'src/services/cloud_service_router.dart';
import 'src/services/json_store.dart';
import 'src/services/official_cloud_service.dart';
import 'src/services/rss_service.dart';
import 'src/services/android_auto_refresh_scheduler.dart';
import 'src/services/android_auto_refresh_service.dart';
import 'src/services/linux_auto_refresh_service.dart';
import 'src/services/subscription_notification_service.dart';
import 'src/services/windows_auto_refresh_service.dart';
import 'src/state/reader_controller.dart';
import 'src/ui/reader_app.dart';

WindowsAutoRefreshService? _windowsAutoRefreshService;
AndroidAutoRefreshService? _androidAutoRefreshService;
LinuxAutoRefreshService? _linuxAutoRefreshService;

Future<void> _initializePlatformServices(ReaderController controller) async {
  await SubscriptionNotificationService.instance.initialize(
    controller: controller,
  );

  if (!kIsWeb && defaultTargetPlatform == TargetPlatform.windows) {
    _windowsAutoRefreshService = WindowsAutoRefreshService(
      controller: controller,
    );
    await _windowsAutoRefreshService!.initialize();
    return;
  }

  if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
    _androidAutoRefreshService = AndroidAutoRefreshService(
      controller: controller,
    );
    await _androidAutoRefreshService!.initialize();
    return;
  }

  if (!kIsWeb && defaultTargetPlatform == TargetPlatform.linux) {
    _linuxAutoRefreshService = LinuxAutoRefreshService(
      controller: controller,
    );
    await _linuxAutoRefreshService!.initialize();
  }
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  if (defaultTargetPlatform == TargetPlatform.android) {
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    await AndroidAutoRefreshScheduler.initialize();
  }

  if (!kIsWeb && defaultTargetPlatform == TargetPlatform.windows) {
    await windowManager.ensureInitialized();
    const WindowOptions options = WindowOptions(
      size: Size(1360, 860),
      minimumSize: Size(980, 640),
      center: true,
      title: 'Resonance',
      titleBarStyle: TitleBarStyle.hidden,
      windowButtonVisibility: false,
      backgroundColor: Color(0xFFF7F4EE),
    );
    await windowManager.waitUntilReadyToShow(
      options,
      () async {
        await windowManager.show();
        await windowManager.focus();
      },
    );
  }

  final controller = ReaderController(
    store: JsonStore(),
    cloudServiceResolver: DefaultCloudServiceResolver(
      officialCloudService: HttpOfficialCloudService(),
    ),
    rssService: RssService(),
  );
  await controller.initialize();

  runApp(ReaderApp(controller: controller));

  WidgetsBinding.instance.addPostFrameCallback((_) {
    _initializePlatformServices(controller);
  });
}
