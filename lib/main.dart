import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:window_manager/window_manager.dart';

import 'src/services/json_store.dart';
import 'src/services/rss_service.dart';
import 'src/state/reader_controller.dart';
import 'src/ui/reader_app.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  if (defaultTargetPlatform == TargetPlatform.android) {
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
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
    rssService: RssService(),
  );
  await controller.initialize();

  runApp(ReaderApp(controller: controller));
}
