import 'dart:typed_data';

import 'package:rsstool/src/services/official_cloud_service.dart';

class FakeOfficialCloudService implements OfficialCloudService {
  FakeOfficialCloudService({
    this.configured = true,
    this.baseUrlValue = 'https://origami.example.com',
  });

  bool configured;
  String? baseUrlValue;
  int createConflictCount = 0;
  bool failCreateWithNetwork = false;
  bool failUpdateUserWithNetwork = false;
  bool failUploadWithNetwork = false;
  bool failDownloadWithNetwork = false;
  final Map<String, String> usersByIdentityCode = <String, String>{};
  final Map<String, Map<String, dynamic>> feedsByIdentityCode =
      <String, Map<String, dynamic>>{};
  final Map<String, Map<String, dynamic>> articlesByIdentityCode =
      <String, Map<String, dynamic>>{};
  final Map<String, Uint8List> avatarsByIdentityCode = <String, Uint8List>{};
  final List<String> uploadLog = <String>[];

  @override
  bool get isConfigured => configured;

  @override
  String? get baseUrl => configured ? baseUrlValue : null;

  @override
  Future<CloudCreateUserResult> createUser(
    String identityCode,
    String userName,
  ) async {
    _requireConfigured();
    if (failCreateWithNetwork) {
      throw const CloudServiceException(CloudServiceErrorKind.network);
    }
    if (createConflictCount > 0) {
      createConflictCount -= 1;
      throw const CloudServiceException(CloudServiceErrorKind.conflict);
    }
    usersByIdentityCode[identityCode] = userName;
    return CloudCreateUserResult(
      identityCode: identityCode,
      userName: userName,
    );
  }

  @override
  Future<CloudUserLookupResult> getUser(String identityCode) async {
    _requireConfigured();
    if (failDownloadWithNetwork) {
      throw const CloudServiceException(CloudServiceErrorKind.network);
    }
    final String? userName = usersByIdentityCode[identityCode];
    return CloudUserLookupResult(
      exists: userName != null,
      userName: userName,
    );
  }

  @override
  Future<void> updateUser(String identityCode, String userName) async {
    _requireConfigured();
    if (failUpdateUserWithNetwork) {
      throw const CloudServiceException(CloudServiceErrorKind.network);
    }
    if (!usersByIdentityCode.containsKey(identityCode)) {
      throw const CloudServiceException(CloudServiceErrorKind.notFound);
    }
    usersByIdentityCode[identityCode] = userName;
  }

  @override
  Future<Map<String, dynamic>> downloadArticles(String identityCode) async {
    _requireConfigured();
    if (failDownloadWithNetwork) {
      throw const CloudServiceException(CloudServiceErrorKind.network);
    }
    return articlesByIdentityCode[identityCode] ??
        <String, dynamic>{
          'identityCode': identityCode,
          'updatedAt': DateTime.now().toIso8601String(),
          'articles': <Object>[],
        };
  }

  @override
  Future<Map<String, dynamic>> downloadFeeds(String identityCode) async {
    _requireConfigured();
    if (failDownloadWithNetwork) {
      throw const CloudServiceException(CloudServiceErrorKind.network);
    }
    return feedsByIdentityCode[identityCode] ??
        <String, dynamic>{
          'identityCode': identityCode,
          'updatedAt': DateTime.now().toIso8601String(),
          'feeds': <Object>[],
        };
  }

  @override
  Future<Uint8List?> downloadAvatar(String identityCode) async {
    _requireConfigured();
    if (failDownloadWithNetwork) {
      throw const CloudServiceException(CloudServiceErrorKind.network);
    }
    return avatarsByIdentityCode[identityCode];
  }

  @override
  Future<void> uploadArticles(String identityCode, Object payload) async {
    _requireConfigured();
    if (failUploadWithNetwork) {
      throw const CloudServiceException(CloudServiceErrorKind.network);
    }
    uploadLog.add('articles');
    articlesByIdentityCode[identityCode] = Map<String, dynamic>.from(
      payload as Map,
    );
  }

  @override
  Future<void> uploadFeeds(String identityCode, Object payload) async {
    _requireConfigured();
    if (failUploadWithNetwork) {
      throw const CloudServiceException(CloudServiceErrorKind.network);
    }
    uploadLog.add('feeds');
    feedsByIdentityCode[identityCode] = Map<String, dynamic>.from(
      payload as Map,
    );
  }

  @override
  Future<void> uploadAvatar(
    String identityCode,
    Uint8List bytes,
    String contentType,
  ) async {
    _requireConfigured();
    if (failUploadWithNetwork) {
      throw const CloudServiceException(CloudServiceErrorKind.network);
    }
    uploadLog.add('avatar:$contentType');
    avatarsByIdentityCode[identityCode] = bytes;
  }

  void _requireConfigured() {
    if (!isConfigured) {
      throw const CloudServiceException(CloudServiceErrorKind.notConfigured);
    }
  }
}
