import 'package:flutter_test/flutter_test.dart';
import 'package:rsstool/src/models/user_profile.dart';

void main() {
  group('UserProfile', () {
    test('serializes and restores profile fields', () {
      final UserProfile profile = UserProfile(
        identityCode: 'Abc123Xyz789Qw',
        displayName: 'Catal',
        avatarPath: '/tmp/avatar.jpg',
        createdAt: DateTime.parse('2026-05-17T12:00:00Z'),
        updatedAt: DateTime.parse('2026-05-17T13:00:00Z'),
        lastCloudSyncAt: DateTime.parse('2026-05-17T13:05:00Z'),
        lastCloudSyncStatus: CloudSyncStatus.synced,
        lastCloudSyncMessage: 'Synced',
        pendingCloudCreate: false,
        pendingCloudProfileSync: true,
        pendingCloudAvatarSync: false,
      );

      final UserProfile restored = UserProfile.fromJson(profile.toJson());

      expect(restored.identityCode, 'Abc123Xyz789Qw');
      expect(restored.displayName, 'Catal');
      expect(restored.avatarPath, '/tmp/avatar.jpg');
      expect(
        restored.createdAt.toUtc(),
        DateTime.parse('2026-05-17T12:00:00Z'),
      );
      expect(
        restored.updatedAt.toUtc(),
        DateTime.parse('2026-05-17T13:00:00Z'),
      );
      expect(
        restored.lastCloudSyncAt?.toUtc(),
        DateTime.parse('2026-05-17T13:05:00Z'),
      );
      expect(restored.lastCloudSyncStatus, CloudSyncStatus.synced);
      expect(restored.lastCloudSyncMessage, 'Synced');
      expect(restored.pendingCloudCreate, isFalse);
      expect(restored.pendingCloudProfileSync, isTrue);
      expect(restored.pendingCloudAvatarSync, isFalse);
    });

    test('creates an empty local profile with timestamps', () {
      final DateTime now = DateTime.parse('2026-05-17T18:00:00Z');
      final UserProfile profile = UserProfile.createEmpty(
        'A1b2C3d4E5f6G7',
        now: now,
      );

      expect(profile.identityCode, 'A1b2C3d4E5f6G7');
      expect(profile.displayName, isEmpty);
      expect(profile.avatarPath, isNull);
      expect(profile.createdAt, now);
      expect(profile.updatedAt, now);
      expect(profile.lastCloudSyncAt, isNull);
      expect(profile.lastCloudSyncStatus, CloudSyncStatus.idle);
      expect(profile.lastCloudSyncMessage, isNull);
      expect(profile.pendingCloudCreate, isFalse);
      expect(profile.pendingCloudProfileSync, isFalse);
      expect(profile.pendingCloudAvatarSync, isFalse);
    });
  });

  group('CurrentUserSession', () {
    test('round-trips signed-in and signed-out states', () {
      final CurrentUserSession signedIn = CurrentUserSession(
        identityCode: 'AbCd1234EfGh56',
      );
      const CurrentUserSession signedOut = CurrentUserSession.signedOut();

      expect(
        CurrentUserSession.fromJson(signedIn.toJson()).identityCode,
        'AbCd1234EfGh56',
      );
      expect(
        CurrentUserSession.fromJson(signedOut.toJson()).isSignedIn,
        isFalse,
      );
    });
  });

  group('identity code helpers', () {
    test('accepts only 14 letters or numbers', () {
      expect(isValidIdentityCode('AbCd1234EfGh56'), isTrue);
      expect(isValidIdentityCode('short123'), isFalse);
      expect(isValidIdentityCode('bad-code-12345'), isFalse);
    });

    test('generated identity code always matches the expected shape', () {
      final String code = generateIdentityCode();

      expect(code, hasLength(kIdentityCodeLength));
      expect(isValidIdentityCode(code), isTrue);
    });
  });
}
