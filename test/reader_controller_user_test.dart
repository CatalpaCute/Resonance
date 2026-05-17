import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:rsstool/src/services/json_store.dart';
import 'package:rsstool/src/services/rss_service.dart';
import 'package:rsstool/src/state/reader_controller.dart';

void main() {
  group('ReaderController user flows', () {
    late Directory documentsDir;
    late JsonStore store;
    late ReaderController controller;

    setUp(() async {
      documentsDir =
          await Directory.systemTemp.createTemp('rsstool_controller_');
      store = JsonStore(
        documentsDirectoryResolver: () async => documentsDir,
      );
      controller = ReaderController(
        store: store,
        rssService: RssService(),
      );
      await controller.initialize();
    });

    tearDown(() async {
      if (await documentsDir.exists()) {
        await documentsDir.delete(recursive: true);
      }
    });

    test('generates a valid identity code and signs in immediately', () async {
      await controller.generateIdentityAndSignIn();

      expect(controller.isSignedIn, isTrue);
      expect(controller.currentIdentityCodeDisplay, hasLength(14));
      expect(
          controller.currentIdentityCodeDisplay, matches(r'^[A-Za-z0-9]{14}$'));
      expect(controller.currentUser, isNotNull);
    });

    test('rejects invalid identity code without persisting a session',
        () async {
      await controller.signInWithIdentityCode('bad-code');

      expect(controller.isSignedIn, isFalse);
      expect(controller.errorMessage, isNotNull);
      expect((await store.loadCurrentUserSession()).isSignedIn, isFalse);
    });

    test('creates a missing local profile when code is valid', () async {
      await controller.signInWithIdentityCode('AbCd1234EfGh56');

      expect(controller.isSignedIn, isTrue);
      expect(controller.currentUser?.identityCode, 'AbCd1234EfGh56');
      expect(await store.loadUserProfile('AbCd1234EfGh56'), isNotNull);
    });

    test('loads an existing profile and keeps display name changes', () async {
      await controller.signInWithIdentityCode('AbCd1234EfGh56');
      await controller.updateUserDisplayName('Catal');

      final ReaderController reloaded = ReaderController(
        store: store,
        rssService: RssService(),
      );
      await reloaded.initialize();

      expect(reloaded.isSignedIn, isTrue);
      expect(reloaded.currentUser?.identityCode, 'AbCd1234EfGh56');
      expect(reloaded.currentUser?.displayName, 'Catal');
      expect(reloaded.currentUserDisplayName, 'Catal');
    });
  });
}
