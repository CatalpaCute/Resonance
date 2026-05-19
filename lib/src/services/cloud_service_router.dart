import 'dart:typed_data';

import '../models/reader_settings.dart';
import 'official_cloud_service.dart';

abstract class IdentitySyncService {
  bool get isConfigured;
  String? get baseUrl;

  Future<CloudUserLookupResult> getUser(String identityCode);

  Future<CloudCreateUserResult> createUser(
    String identityCode,
    String userName,
  );

  Future<void> updateUser(
    String identityCode,
    String userName,
  );
}

abstract class ContentSyncService {
  bool get isConfigured;
  String? get baseUrl;

  Future<Map<String, dynamic>> downloadArticles(String identityCode);

  Future<void> uploadArticles(
    String identityCode,
    Object payload,
  );

  Future<Map<String, dynamic>> downloadFeeds(String identityCode);

  Future<void> uploadFeeds(
    String identityCode,
    Object payload,
  );

  Future<Uint8List?> downloadAvatar(String identityCode);

  Future<void> uploadAvatar(
    String identityCode,
    Uint8List bytes,
    String contentType,
  );
}

class CloudServiceBundle {
  const CloudServiceBundle({
    required this.identityService,
    required this.contentService,
    required this.identityMode,
    required this.contentMode,
  });

  final IdentitySyncService identityService;
  final ContentSyncService contentService;
  final CloudIdentityMode identityMode;
  final CloudContentMode contentMode;
}

abstract class CloudServiceResolver {
  CloudServiceBundle resolve(ReaderSettings settings);
}

class DefaultCloudServiceResolver implements CloudServiceResolver {
  DefaultCloudServiceResolver({
    required OfficialCloudService officialCloudService,
  })  : _officialIdentityService =
            OfficialIdentitySyncService(officialCloudService),
        _officialContentService =
            OfficialContentSyncService(officialCloudService);

  final OfficialIdentitySyncService _officialIdentityService;
  final OfficialContentSyncService _officialContentService;

  @override
  CloudServiceBundle resolve(ReaderSettings settings) {
    final IdentitySyncService identityService =
        settings.cloudIdentityMode == CloudIdentityMode.privateCloud
            ? UnsupportedPrivateIdentitySyncService(
                baseUrl: settings.privateCloudBaseUrl,
              )
            : _officialIdentityService;
    final ContentSyncService contentService =
        settings.cloudContentMode == CloudContentMode.privateCloud
            ? UnsupportedPrivateContentSyncService(
                baseUrl: settings.privateCloudBaseUrl,
              )
            : _officialContentService;
    return CloudServiceBundle(
      identityService: identityService,
      contentService: contentService,
      identityMode: settings.cloudIdentityMode,
      contentMode: settings.cloudContentMode,
    );
  }
}

class OfficialIdentitySyncService implements IdentitySyncService {
  const OfficialIdentitySyncService(this._officialCloudService);

  final OfficialCloudService _officialCloudService;

  @override
  bool get isConfigured => _officialCloudService.isConfigured;

  @override
  String? get baseUrl => _officialCloudService.baseUrl;

  @override
  Future<CloudCreateUserResult> createUser(
    String identityCode,
    String userName,
  ) {
    return _officialCloudService.createUser(identityCode, userName);
  }

  @override
  Future<CloudUserLookupResult> getUser(String identityCode) {
    return _officialCloudService.getUser(identityCode);
  }

  @override
  Future<void> updateUser(String identityCode, String userName) {
    return _officialCloudService.updateUser(identityCode, userName);
  }
}

class OfficialContentSyncService implements ContentSyncService {
  const OfficialContentSyncService(this._officialCloudService);

  final OfficialCloudService _officialCloudService;

  @override
  bool get isConfigured => _officialCloudService.isConfigured;

  @override
  String? get baseUrl => _officialCloudService.baseUrl;

  @override
  Future<Uint8List?> downloadAvatar(String identityCode) {
    return _officialCloudService.downloadAvatar(identityCode);
  }

  @override
  Future<Map<String, dynamic>> downloadArticles(String identityCode) {
    return _officialCloudService.downloadArticles(identityCode);
  }

  @override
  Future<Map<String, dynamic>> downloadFeeds(String identityCode) {
    return _officialCloudService.downloadFeeds(identityCode);
  }

  @override
  Future<void> uploadAvatar(
    String identityCode,
    Uint8List bytes,
    String contentType,
  ) {
    return _officialCloudService.uploadAvatar(identityCode, bytes, contentType);
  }

  @override
  Future<void> uploadArticles(String identityCode, Object payload) {
    return _officialCloudService.uploadArticles(identityCode, payload);
  }

  @override
  Future<void> uploadFeeds(String identityCode, Object payload) {
    return _officialCloudService.uploadFeeds(identityCode, payload);
  }
}

class UnsupportedPrivateIdentitySyncService implements IdentitySyncService {
  const UnsupportedPrivateIdentitySyncService({
    required this.baseUrl,
  });

  @override
  final String? baseUrl;

  @override
  bool get isConfigured => false;

  @override
  Future<CloudCreateUserResult> createUser(
    String identityCode,
    String userName,
  ) =>
      _throwUnavailable();

  @override
  Future<CloudUserLookupResult> getUser(String identityCode) =>
      _throwUnavailable();

  @override
  Future<void> updateUser(String identityCode, String userName) =>
      _throwUnavailable();

  Never _throwUnavailable() {
    throw const CloudServiceException(
      CloudServiceErrorKind.notConfigured,
      message: 'Private-cloud identity sync is reserved but not implemented.',
    );
  }
}

class UnsupportedPrivateContentSyncService implements ContentSyncService {
  const UnsupportedPrivateContentSyncService({
    required this.baseUrl,
  });

  @override
  final String? baseUrl;

  @override
  bool get isConfigured => false;

  @override
  Future<Uint8List?> downloadAvatar(String identityCode) => _throwUnavailable();

  @override
  Future<Map<String, dynamic>> downloadArticles(String identityCode) =>
      _throwUnavailable();

  @override
  Future<Map<String, dynamic>> downloadFeeds(String identityCode) =>
      _throwUnavailable();

  @override
  Future<void> uploadAvatar(
    String identityCode,
    Uint8List bytes,
    String contentType,
  ) =>
      _throwUnavailable();

  @override
  Future<void> uploadArticles(String identityCode, Object payload) =>
      _throwUnavailable();

  @override
  Future<void> uploadFeeds(String identityCode, Object payload) =>
      _throwUnavailable();

  Never _throwUnavailable() {
    throw const CloudServiceException(
      CloudServiceErrorKind.notConfigured,
      message: 'Private-cloud content sync is reserved but not implemented.',
    );
  }
}
