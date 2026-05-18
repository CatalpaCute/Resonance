import 'dart:math';

const int kIdentityCodeLength = 14;
const String kIdentityCodeAlphabet =
    'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789';

final RegExp _identityCodePattern = RegExp(r'^[A-Za-z0-9]{14}$');

enum CloudSyncStatus {
  idle,
  synced,
  failed,
}

String cloudSyncStatusToJson(CloudSyncStatus status) {
  return status.name;
}

CloudSyncStatus cloudSyncStatusFromJson(String? raw) {
  for (final CloudSyncStatus status in CloudSyncStatus.values) {
    if (status.name == raw) {
      return status;
    }
  }
  return CloudSyncStatus.idle;
}

bool isValidIdentityCode(String value) {
  return _identityCodePattern.hasMatch(value);
}

String generateIdentityCode([Random? random]) {
  final Random generator = random ?? Random.secure();
  final StringBuffer buffer = StringBuffer();

  for (int index = 0; index < kIdentityCodeLength; index += 1) {
    final int charIndex = generator.nextInt(kIdentityCodeAlphabet.length);
    buffer.write(kIdentityCodeAlphabet[charIndex]);
  }

  return buffer.toString();
}

class UserProfile {
  const UserProfile({
    required this.identityCode,
    required this.displayName,
    required this.avatarPath,
    required this.createdAt,
    required this.updatedAt,
    required this.lastCloudSyncAt,
    required this.lastCloudSyncStatus,
    required this.lastCloudSyncMessage,
    required this.pendingCloudCreate,
    required this.pendingCloudProfileSync,
    required this.pendingCloudAvatarSync,
  });

  final String identityCode;
  final String displayName;
  final String? avatarPath;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? lastCloudSyncAt;
  final CloudSyncStatus lastCloudSyncStatus;
  final String? lastCloudSyncMessage;
  final bool pendingCloudCreate;
  final bool pendingCloudProfileSync;
  final bool pendingCloudAvatarSync;

  bool get hasPendingAccountSync =>
      pendingCloudCreate || pendingCloudProfileSync || pendingCloudAvatarSync;

  bool get hasAvatar => avatarPath?.trim().isNotEmpty ?? false;

  UserProfile copyWith({
    String? identityCode,
    String? displayName,
    String? avatarPath,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? lastCloudSyncAt,
    CloudSyncStatus? lastCloudSyncStatus,
    String? lastCloudSyncMessage,
    bool? pendingCloudCreate,
    bool? pendingCloudProfileSync,
    bool? pendingCloudAvatarSync,
    bool clearLastCloudSyncAt = false,
    bool clearLastCloudSyncMessage = false,
    bool clearAvatarPath = false,
  }) {
    return UserProfile(
      identityCode: identityCode ?? this.identityCode,
      displayName: displayName ?? this.displayName,
      avatarPath: clearAvatarPath ? null : (avatarPath ?? this.avatarPath),
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      lastCloudSyncAt: clearLastCloudSyncAt
          ? null
          : (lastCloudSyncAt ?? this.lastCloudSyncAt),
      lastCloudSyncStatus: lastCloudSyncStatus ?? this.lastCloudSyncStatus,
      lastCloudSyncMessage: clearLastCloudSyncMessage
          ? null
          : (lastCloudSyncMessage ?? this.lastCloudSyncMessage),
      pendingCloudCreate: pendingCloudCreate ?? this.pendingCloudCreate,
      pendingCloudProfileSync:
          pendingCloudProfileSync ?? this.pendingCloudProfileSync,
      pendingCloudAvatarSync:
          pendingCloudAvatarSync ?? this.pendingCloudAvatarSync,
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'identityCode': identityCode,
      'displayName': displayName,
      'avatarPath': avatarPath,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'lastCloudSyncAt': lastCloudSyncAt?.toIso8601String(),
      'lastCloudSyncStatus': cloudSyncStatusToJson(lastCloudSyncStatus),
      'lastCloudSyncMessage': lastCloudSyncMessage,
      'pendingCloudCreate': pendingCloudCreate,
      'pendingCloudProfileSync': pendingCloudProfileSync,
      'pendingCloudAvatarSync': pendingCloudAvatarSync,
    };
  }

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    final DateTime now = DateTime.now();
    return UserProfile(
      identityCode: json['identityCode'] as String? ?? '',
      displayName: json['displayName'] as String? ?? '',
      avatarPath: json['avatarPath'] as String?,
      createdAt: DateTime.tryParse(json['createdAt'] as String? ?? '') ?? now,
      updatedAt: DateTime.tryParse(json['updatedAt'] as String? ?? '') ?? now,
      lastCloudSyncAt:
          DateTime.tryParse(json['lastCloudSyncAt'] as String? ?? ''),
      lastCloudSyncStatus: cloudSyncStatusFromJson(
        json['lastCloudSyncStatus'] as String?,
      ),
      lastCloudSyncMessage: json['lastCloudSyncMessage'] as String?,
      pendingCloudCreate: json['pendingCloudCreate'] as bool? ?? false,
      pendingCloudProfileSync:
          json['pendingCloudProfileSync'] as bool? ?? false,
      pendingCloudAvatarSync: json['pendingCloudAvatarSync'] as bool? ?? false,
    );
  }

  factory UserProfile.createEmpty(String identityCode, {DateTime? now}) {
    final DateTime createdAt = now ?? DateTime.now();
    return UserProfile(
      identityCode: identityCode,
      displayName: '',
      avatarPath: null,
      createdAt: createdAt,
      updatedAt: createdAt,
      lastCloudSyncAt: null,
      lastCloudSyncStatus: CloudSyncStatus.idle,
      lastCloudSyncMessage: null,
      pendingCloudCreate: false,
      pendingCloudProfileSync: false,
      pendingCloudAvatarSync: false,
    );
  }
}

class CurrentUserSession {
  const CurrentUserSession({
    required this.identityCode,
  });

  const CurrentUserSession.signedOut() : identityCode = null;

  final String? identityCode;

  bool get isSignedIn => identityCode?.isNotEmpty ?? false;

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'identityCode': identityCode,
    };
  }

  factory CurrentUserSession.fromJson(Map<String, dynamic> json) {
    final String? identityCode = json['identityCode'] as String?;
    return CurrentUserSession(
      identityCode: identityCode?.isEmpty ?? true ? null : identityCode,
    );
  }
}
