import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rsstool/src/localization/app_language.dart';
import 'package:rsstool/src/models/reader_settings.dart';
import 'package:rsstool/src/services/cloud_service_router.dart';
import 'package:rsstool/src/services/json_store.dart';
import 'package:rsstool/src/services/rss_service.dart';
import 'package:rsstool/src/state/reader_controller.dart';
import 'package:rsstool/src/theme/app_theme.dart';
import 'package:rsstool/src/ui/views/account_settings_view.dart';

import 'test_support/fake_official_cloud_service.dart';

void main() {
  group('AccountSettingsView', () {
    late Directory documentsDir;
    late ReaderController controller;
    late FakeOfficialCloudService cloudService;

    setUp(() async {
      documentsDir = await Directory.systemTemp.createTemp('rsstool_account_');
      cloudService = FakeOfficialCloudService();
      controller = ReaderController(
        store: JsonStore(
          documentsDirectoryResolver: () async => documentsDir,
        ),
        cloudServiceResolver: DefaultCloudServiceResolver(
          officialCloudService: cloudService,
        ),
        rssService: RssService(),
      );
      await controller.initialize();
    });

    tearDown(() async {
      if (await documentsDir.exists()) {
        await documentsDir.delete(recursive: true);
      }
    });

    testWidgets('shows the two sign-in actions while signed out', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(_buildHarness(controller: controller));

      expect(find.text('Generate My Code'), findsOneWidget);
      expect(find.text('Enter My Code'), findsOneWidget);
    });

    testWidgets('disables apply button for invalid identity code', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(_buildHarness(controller: controller));

      await tester.tap(find.text('Enter My Code'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField), 'bad');
      await tester.pump();

      final FilledButton button = tester.widget<FilledButton>(
        find.widgetWithText(FilledButton, 'Save and Apply'),
      );

      expect(button.onPressed, isNull);
      expect(
        find.text(
          'The identity code must be exactly 14 letters or numbers.',
        ),
        findsOneWidget,
      );
    });

    testWidgets('shows profile and cloud cards after signing in', (
      WidgetTester tester,
    ) async {
      cloudService.usersByIdentityCode['AbCd1234EfGh56'] = 'Cloud Catal';
      await tester.runAsync(() async {
        await controller.signInWithIdentityCode('AbCd1234EfGh56');
      });

      await tester.pumpWidget(_buildHarness(controller: controller));
      await tester.pump();

      expect(find.text('Resonance Account'), findsOneWidget);
      expect(find.text('Personal Info'), findsOneWidget);
      expect(find.text('Cloud Services'), findsOneWidget);
      expect(find.text('Auto Sync'), findsOneWidget);
      expect(find.text('Sign Out'), findsOneWidget);
      expect(find.text('AbCd1234EfGh56'), findsAtLeastNWidgets(1));
      expect(
        find.text(
          'This section only manages the user name, avatar, and identity code for your current identity.',
        ),
        findsNothing,
      );
      expect(find.text('Upload to Origami Cloud'), findsNothing);
      expect(find.text('Download from Origami Cloud'), findsNothing);
      expect(find.text('Current connection: Origami Cloud'), findsOneWidget);
    });

    testWidgets(
        'shows upload and download actions after enabling cloud service',
        (WidgetTester tester) async {
      cloudService.usersByIdentityCode['AbCd1234EfGh56'] = 'Cloud Catal';
      await tester.runAsync(() async {
        await controller.signInWithIdentityCode('AbCd1234EfGh56');
      });

      await tester.pumpWidget(_buildHarness(controller: controller));
      await tester.pump();

      await tester.runAsync(() async {
        await controller.setCloudServiceEnabled(true);
      });
      await tester.pumpWidget(_buildHarness(controller: controller));
      await tester.pump();

      expect(find.text('Upload to Origami Cloud'), findsOneWidget);
      expect(find.text('Download from Origami Cloud'), findsOneWidget);
      expect(find.text('Auto Sync'), findsOneWidget);
      expect(find.text('Current connection: Origami Cloud'), findsOneWidget);
      expect(find.textContaining('provided by CzWorks'), findsNothing);
    });

    test('switches the cloud type label and persists the selection', () async {
      cloudService.usersByIdentityCode['AbCd1234EfGh56'] = 'Cloud Catal';
      await controller.signInWithIdentityCode('AbCd1234EfGh56');

      await controller.setCloudContentModeSelection(
        CloudContentMode.privateCloud,
      );

      expect(controller.cloudContentMode, CloudContentMode.privateCloud);

      final JsonStore reloadedStore = JsonStore(
        documentsDirectoryResolver: () async => documentsDir,
      );
      final persisted = await reloadedStore.load();
      expect(
          persisted.settings.cloudContentMode, CloudContentMode.privateCloud);
    });

    testWidgets(
        'shows server row and personal-cloud actions after switching to personal cloud',
        (WidgetTester tester) async {
      cloudService.usersByIdentityCode['AbCd1234EfGh56'] = 'Cloud Catal';
      await tester.runAsync(() async {
        await controller.signInWithIdentityCode('AbCd1234EfGh56');
        await controller.setCloudContentModeSelection(
          CloudContentMode.privateCloud,
        );
        await controller.setPrivateCloudServerConfig(
          baseUrl: 'https://dav.example.com',
          username: 'catal',
          password: 'secret',
          basePath: '/resonance/',
        );
        await controller.setCloudServiceEnabled(true);
      });

      await tester.pumpWidget(_buildHarness(controller: controller));
      await tester.pump();

      expect(find.text('Current connection: Personal Cloud'), findsOneWidget);
      expect(find.text('Server'), findsOneWidget);
      expect(find.textContaining('WebDAV'), findsOneWidget);
      expect(find.text('Upload to Personal Cloud'), findsOneWidget);
      expect(find.text('Download from Personal Cloud'), findsOneWidget);
    });

    testWidgets('disables cloud sign-in actions when endpoint is not injected',
        (WidgetTester tester) async {
      cloudService.configured = false;

      await tester.pumpWidget(_buildHarness(controller: controller));

      final FilledButton generateButton = tester.widget<FilledButton>(
        find.widgetWithText(FilledButton, 'Generate My Code'),
      );
      expect(generateButton.onPressed, isNull);
      expect(
        find.text(
          'This build is not connected to the official Origami Cloud. Inject the cloud endpoint at build time.',
        ),
        findsOneWidget,
      );
    });
  });
}

Widget _buildHarness({
  required ReaderController controller,
}) {
  return MaterialApp(
    locale: const Locale('en'),
    supportedLocales: supportedAppLocales,
    localizationsDelegates: GlobalMaterialLocalizations.delegates,
    theme: AppTheme.themeFor(
      'warm_default',
      brightness: Brightness.light,
    ),
    home: Scaffold(
      body: SingleChildScrollView(
        child: AccountSettingsView(
          controller: controller,
          wideLayout: false,
        ),
      ),
    ),
  );
}
