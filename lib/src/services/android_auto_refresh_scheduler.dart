import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:workmanager/workmanager.dart';

import '../models/feed_source.dart';
import '../models/reader_settings.dart';
import 'auto_refresh_engine.dart';
import 'subscription_notification_service.dart';

const String kAndroidAutoRefreshUniqueWorkName =
    'resonance_auto_refresh_once';
const String kAndroidAutoRefreshTaskName = 'resonance_auto_refresh_due_feeds';

@pragma('vm:entry-point')
void resonanceAutoRefreshCallbackDispatcher() {
  Workmanager().executeTask((String task, Map<String, dynamic>? inputData) async {
    WidgetsFlutterBinding.ensureInitialized();
    DartPluginRegistrant.ensureInitialized();

    if (task != kAndroidAutoRefreshTaskName) {
      return true;
    }

    final AutoRefreshEngine engine = AutoRefreshEngine.defaultInstance();

    try {
      final AutoRefreshRunResult result =
          await engine.refreshPersistedDueFeeds();
      final persistedState = await engine.loadPersistedState();
      await SubscriptionNotificationService.showBackgroundAutoRefreshNotifications(
        settings: persistedState.settings,
        result: result,
      );
    } catch (error, stackTrace) {
      debugPrint('Auto-refresh worker failed: $error\n$stackTrace');
    }

    try {
      await AndroidAutoRefreshScheduler.syncFromPersistedState(engine: engine);
    } catch (error, stackTrace) {
      debugPrint('Auto-refresh worker reschedule failed: $error\n$stackTrace');
    }

    return true;
  });
}

class AndroidAutoRefreshScheduler {
  const AndroidAutoRefreshScheduler._();

  static bool get isSupported =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.android;

  static Future<void> initialize() async {
    if (!isSupported) {
      return;
    }
    await Workmanager().initialize(
      resonanceAutoRefreshCallbackDispatcher,
    );
  }

  static Future<void> cancelSchedule() async {
    if (!isSupported) {
      return;
    }
    await Workmanager().cancelByUniqueName(kAndroidAutoRefreshUniqueWorkName);
  }

  static Future<void> syncFromPersistedState({
    required AutoRefreshEngine engine,
  }) async {
    if (!isSupported) {
      return;
    }

    final state = await engine.loadPersistedState();
    await syncFromSnapshot(
      settings: state.settings,
      feeds: state.feeds,
      engine: engine,
    );
  }

  static Future<void> syncFromSnapshot({
    required ReaderSettings settings,
    required List<FeedSource> feeds,
    required AutoRefreshEngine engine,
  }) async {
    if (!isSupported) {
      return;
    }

    if (!settings.autoRefreshEnabled) {
      await cancelSchedule();
      return;
    }

    final DateTime? nextAt = engine.nextRefreshAt(
      settings: settings,
      feeds: feeds,
    );
    if (nextAt == null) {
      await cancelSchedule();
      return;
    }

    final Duration delay = nextAt.difference(DateTime.now());
    await Workmanager().registerOneOffTask(
      kAndroidAutoRefreshUniqueWorkName,
      kAndroidAutoRefreshTaskName,
      existingWorkPolicy: ExistingWorkPolicy.replace,
      initialDelay: delay.isNegative ? Duration.zero : delay,
      constraints: Constraints(
        networkType: NetworkType.connected,
      ),
    );
  }
}
