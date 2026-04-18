import 'package:flutter/material.dart';

import 'src/services/json_store.dart';
import 'src/services/rss_service.dart';
import 'src/state/reader_controller.dart';
import 'src/ui/reader_app.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final controller = ReaderController(
    store: JsonStore(),
    rssService: RssService(),
  );
  await controller.initialize();

  runApp(ReaderApp(controller: controller));
}
