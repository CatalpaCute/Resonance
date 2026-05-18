import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:rsstool/src/models/user_profile.dart';
import 'package:rsstool/src/services/json_store.dart';

void main() {
  group('JsonStore user persistence', () {
    late Directory documentsDir;
    late JsonStore store;

    setUp(() async {
      documentsDir = await Directory.systemTemp.createTemp('rsstool_store_');
      store = JsonStore(
        documentsDirectoryResolver: () async => documentsDir,
      );
    });

    tearDown(() async {
      if (await documentsDir.exists()) {
        await documentsDir.delete(recursive: true);
      }
    });

    test('creates user profile and current session files', () async {
      final UserProfile profile = UserProfile.createEmpty('AbCd1234EfGh56');

      await store.saveUserProfile(profile);
      await store.saveCurrentUserSession(
        const CurrentUserSession(identityCode: 'AbCd1234EfGh56'),
      );

      final UserProfile? restored = await store.loadUserProfile(
        'AbCd1234EfGh56',
      );
      final CurrentUserSession session = await store.loadCurrentUserSession();
      final String rootPath = p.join(documentsDir.path, 'rsstool');

      expect(
        File(p.join(rootPath, 'current_user.json')).existsSync(),
        isTrue,
      );
      expect(
        File(
          p.join(rootPath, 'users', 'AbCd1234EfGh56', 'profile.json'),
        ).existsSync(),
        isTrue,
      );
      expect(restored?.identityCode, 'AbCd1234EfGh56');
      expect(session.identityCode, 'AbCd1234EfGh56');
    });

    test('signing out clears only the current session file', () async {
      final UserProfile profile = UserProfile.createEmpty('AbCd1234EfGh56');

      await store.saveUserProfile(profile);
      await store.saveCurrentUserSession(
        const CurrentUserSession(identityCode: 'AbCd1234EfGh56'),
      );
      await store.clearCurrentUserSession();

      final String rootPath = p.join(documentsDir.path, 'rsstool');
      expect(
        File(p.join(rootPath, 'current_user.json')).existsSync(),
        isFalse,
      );
      expect(
        File(
          p.join(rootPath, 'users', 'AbCd1234EfGh56', 'profile.json'),
        ).existsSync(),
        isTrue,
      );
    });

    test('saving avatar overwrites the fixed avatar path', () async {
      final UserProfile profile = UserProfile.createEmpty('AbCd1234EfGh56');

      await store.saveUserProfile(profile);
      final String firstPath = await store.saveUserAvatar(
        profile.identityCode,
        Uint8List.fromList(<int>[1, 2, 3]),
      );
      final String secondPath = await store.saveUserAvatar(
        profile.identityCode,
        Uint8List.fromList(<int>[4, 5]),
      );

      expect(firstPath, secondPath);
      expect(File(secondPath).readAsBytesSync(), <int>[4, 5]);
    });

    test('deleting avatar removes the local avatar file only', () async {
      final UserProfile profile = UserProfile.createEmpty('AbCd1234EfGh56');

      await store.saveUserProfile(profile);
      final String avatarPath = await store.saveUserAvatar(
        profile.identityCode,
        Uint8List.fromList(<int>[1, 2, 3]),
      );

      await store.deleteUserAvatar(profile.identityCode);

      expect(File(avatarPath).existsSync(), isFalse);
      expect(await store.loadUserProfile(profile.identityCode), isNotNull);
    });
  });
}
