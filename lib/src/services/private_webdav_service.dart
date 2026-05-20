import 'dart:convert';
import 'dart:typed_data';

import 'package:http/http.dart' as http;

import '../models/article.dart';
import '../models/feed_source.dart';
import 'cloud_service_router.dart';
import 'official_cloud_service.dart';

class WebDavCloudClient {
  WebDavCloudClient({
    required this.baseUrl,
    required this.basePath,
    required this.username,
    required this.password,
    http.Client? client,
  }) : _client = client ?? http.Client();

  final String baseUrl;
  final String basePath;
  final String username;
  final String password;
  final http.Client _client;

  bool get isConfigured => baseUrl.trim().isNotEmpty;

  Future<bool> exists(String relativePath) async {
    final http.Response response = await _send(
      method: 'PROPFIND',
      relativePath: relativePath,
      headers: <String, String>{
        'Depth': '0',
      },
      allowNotFound: true,
      acceptedStatusCodes: const <int>{200, 207, 301, 302},
    );
    return response.statusCode != 404;
  }

  Future<void> ensureDirectory(String relativePath) async {
    final List<String> segments = _pathSegments(relativePath);
    String current = '';
    for (final String segment in segments) {
      current = current.isEmpty ? segment : '$current/$segment';
      await _send(
        method: 'MKCOL',
        relativePath: current,
        acceptedStatusCodes: const <int>{201, 301, 302, 405},
      );
    }
  }

  Future<Map<String, dynamic>?> getJsonMap(
    String relativePath, {
    bool allowNotFound = false,
  }) async {
    final Object? decoded = await getJson(
      relativePath,
      allowNotFound: allowNotFound,
    );
    if (decoded == null) {
      return null;
    }
    if (decoded is! Map<String, dynamic>) {
      throw const CloudServiceException(CloudServiceErrorKind.invalidResponse);
    }
    return decoded;
  }

  Future<Object?> getJson(
    String relativePath, {
    bool allowNotFound = false,
  }) async {
    final http.Response response = await _send(
      method: 'GET',
      relativePath: relativePath,
      headers: <String, String>{
        'accept': 'application/json',
      },
      allowNotFound: allowNotFound,
    );
    if (response.statusCode == 404) {
      return null;
    }
    if (response.body.trim().isEmpty) {
      return <String, dynamic>{};
    }
    return jsonDecode(response.body);
  }

  Future<Uint8List?> getBytes(
    String relativePath, {
    bool allowNotFound = false,
  }) async {
    final http.Response response = await _send(
      method: 'GET',
      relativePath: relativePath,
      allowNotFound: allowNotFound,
    );
    if (response.statusCode == 404) {
      return null;
    }
    return response.bodyBytes;
  }

  Future<void> putJson(String relativePath, Object payload) async {
    await _ensureParentDirectory(relativePath);
    await _send(
      method: 'PUT',
      relativePath: relativePath,
      headers: <String, String>{
        'content-type': 'application/json; charset=utf-8',
        'accept': 'application/json',
      },
      body: utf8.encode(jsonEncode(payload)),
    );
  }

  Future<void> putBytes(
    String relativePath,
    Uint8List bytes, {
    required String contentType,
  }) async {
    await _ensureParentDirectory(relativePath);
    await _send(
      method: 'PUT',
      relativePath: relativePath,
      headers: <String, String>{
        'content-type': contentType,
      },
      body: bytes,
    );
  }

  Future<void> delete(String relativePath) async {
    await _send(
      method: 'DELETE',
      relativePath: relativePath,
      allowNotFound: true,
    );
  }

  Future<void> _ensureParentDirectory(String relativePath) async {
    final List<String> segments = _pathSegments(relativePath);
    if (segments.length <= 1) {
      return;
    }
    await ensureDirectory(segments.take(segments.length - 1).join('/'));
  }

  Future<http.Response> _send({
    required String method,
    required String relativePath,
    Map<String, String>? headers,
    List<int>? body,
    bool allowNotFound = false,
    Set<int> acceptedStatusCodes = const <int>{200, 201, 204},
  }) async {
    if (!isConfigured) {
      throw const CloudServiceException(CloudServiceErrorKind.notConfigured);
    }

    final Uri uri = _buildUri(relativePath);
    final http.Request request = http.Request(method, uri);
    request.headers.addAll(_buildHeaders(headers));
    if (body != null) {
      request.bodyBytes = body;
    }

    try {
      final http.StreamedResponse streamed = await _client.send(request);
      final http.Response response = await http.Response.fromStream(streamed);
      if (acceptedStatusCodes.contains(response.statusCode) ||
          (allowNotFound && response.statusCode == 404)) {
        return response;
      }
      throw _exceptionFromResponse(response);
    } on CloudServiceException {
      rethrow;
    } on http.ClientException catch (error) {
      throw CloudServiceException(
        CloudServiceErrorKind.network,
        message: error.message,
      );
    } on FormatException catch (error) {
      throw CloudServiceException(
        CloudServiceErrorKind.invalidResponse,
        message: error.message,
      );
    } catch (error) {
      throw CloudServiceException(
        CloudServiceErrorKind.network,
        message: error.toString(),
      );
    }
  }

  Uri _buildUri(String relativePath) {
    final Uri rootUri = Uri.parse(baseUrl);
    final List<String> segments = <String>[
      ..._pathSegments(rootUri.path),
      ..._pathSegments(basePath),
      ..._pathSegments(relativePath),
    ];
    return rootUri.replace(path: '/${segments.join('/')}');
  }

  Map<String, String> _buildHeaders(Map<String, String>? headers) {
    final Map<String, String> merged = <String, String>{
      if (username.trim().isNotEmpty || password.isNotEmpty)
        'authorization':
            'Basic ${base64Encode(utf8.encode('${username.trim()}:$password'))}',
      ...?headers,
    };
    return merged;
  }

  List<String> _pathSegments(String rawPath) {
    return rawPath
        .split('/')
        .map((String part) => part.trim())
        .where((String part) => part.isNotEmpty)
        .toList();
  }

  CloudServiceException _exceptionFromResponse(http.Response response) {
    final String? message = _extractErrorMessage(response.body);
    switch (response.statusCode) {
      case 401:
      case 403:
        return CloudServiceException(
          CloudServiceErrorKind.rejected,
          message: message,
          statusCode: response.statusCode,
        );
      case 404:
        return CloudServiceException(
          CloudServiceErrorKind.notFound,
          message: message,
          statusCode: response.statusCode,
        );
      case 405:
      case 409:
        return CloudServiceException(
          CloudServiceErrorKind.conflict,
          message: message,
          statusCode: response.statusCode,
        );
      default:
        return CloudServiceException(
          CloudServiceErrorKind.invalidResponse,
          message: message,
          statusCode: response.statusCode,
        );
    }
  }

  static String? _extractErrorMessage(String body) {
    if (body.trim().isEmpty) {
      return null;
    }
    try {
      final Object? decoded = jsonDecode(body);
      if (decoded is Map<String, dynamic>) {
        final Object? error = decoded['error'] ?? decoded['message'];
        if (error is String && error.trim().isNotEmpty) {
          return error.trim();
        }
      }
    } catch (_) {
      return null;
    }
    return null;
  }
}

class PrivateWebDavIdentitySyncService implements IdentitySyncService {
  PrivateWebDavIdentitySyncService({
    required WebDavCloudClient client,
  }) : _client = client;

  final WebDavCloudClient _client;

  @override
  bool get isConfigured => _client.isConfigured;

  @override
  String? get baseUrl => _client.baseUrl;

  @override
  Future<CloudCreateUserResult> createUser(
    String identityCode,
    String userName,
  ) async {
    final Map<String, dynamic> usersIndex = await _loadUsersIndex();
    if (usersIndex.containsKey(identityCode)) {
      throw const CloudServiceException(CloudServiceErrorKind.conflict);
    }

    final DateTime now = DateTime.now();
    usersIndex[identityCode] =
        _buildUserRecord(userName, now, avatarVersion: 0);
    await _client.putJson(_usersIndexPath, usersIndex);
    await _client.putJson(
      _profilePath(identityCode),
      _buildProfileDocument(
        identityCode: identityCode,
        userName: userName,
        now: now,
        avatarVersion: 0,
      ),
    );
    return CloudCreateUserResult(
        identityCode: identityCode, userName: userName);
  }

  @override
  Future<CloudUserLookupResult> getUser(String identityCode) async {
    final Map<String, dynamic> usersIndex = await _loadUsersIndex();
    final Object? rawUser = usersIndex[identityCode];
    if (rawUser is! Map<String, dynamic>) {
      return const CloudUserLookupResult(exists: false);
    }
    return CloudUserLookupResult(
      exists: true,
      userName: _extractUserName(rawUser),
    );
  }

  @override
  Future<void> updateUser(String identityCode, String userName) async {
    final Map<String, dynamic> usersIndex = await _loadUsersIndex();
    final Object? rawUser = usersIndex[identityCode];
    if (rawUser is! Map<String, dynamic>) {
      throw const CloudServiceException(CloudServiceErrorKind.notFound);
    }

    final DateTime now = DateTime.now();
    final int avatarVersion = _extractAvatarVersion(rawUser);
    usersIndex[identityCode] =
        _buildUserRecord(userName, now, avatarVersion: avatarVersion);
    await _client.putJson(_usersIndexPath, usersIndex);
    await _client.putJson(
      _profilePath(identityCode),
      _buildProfileDocument(
        identityCode: identityCode,
        userName: userName,
        now: now,
        avatarVersion: avatarVersion,
      ),
    );
  }

  Future<void> updateAvatarMetadata(String identityCode) async {
    final Map<String, dynamic> usersIndex = await _loadUsersIndex();
    final Object? rawUser = usersIndex[identityCode];
    if (rawUser is! Map<String, dynamic>) {
      return;
    }

    final DateTime now = DateTime.now();
    final String userName = _extractUserName(rawUser) ?? '';
    final int nextAvatarVersion = _extractAvatarVersion(rawUser) + 1;
    usersIndex[identityCode] =
        _buildUserRecord(userName, now, avatarVersion: nextAvatarVersion);
    await _client.putJson(_usersIndexPath, usersIndex);
    await _client.putJson(
      _profilePath(identityCode),
      _buildProfileDocument(
        identityCode: identityCode,
        userName: userName,
        now: now,
        avatarVersion: nextAvatarVersion,
      ),
    );
  }

  Future<Map<String, dynamic>> _loadUsersIndex() async {
    return await _client.getJsonMap(_usersIndexPath, allowNotFound: true) ??
        <String, dynamic>{};
  }
}

class PrivateWebDavContentSyncService implements ContentSyncService {
  PrivateWebDavContentSyncService({
    required WebDavCloudClient client,
    PrivateWebDavIdentitySyncService? identityService,
  })  : _client = client,
        _identityService = identityService;

  final WebDavCloudClient _client;
  final PrivateWebDavIdentitySyncService? _identityService;

  @override
  bool get isConfigured => _client.isConfigured;

  @override
  String? get baseUrl => _client.baseUrl;

  @override
  Future<Map<String, dynamic>> downloadArticles(String identityCode) async {
    final Object? decoded = await _client.getJson(
      _articlesPath(identityCode),
      allowNotFound: true,
    );
    if (decoded == null) {
      return _emptyCollectionPayload(identityCode, 'articles');
    }
    if (decoded is List<dynamic>) {
      return <String, dynamic>{
        'identityCode': identityCode,
        'updatedAt': DateTime.now().toIso8601String(),
        'articles': decoded,
      };
    }
    if (decoded is! Map<String, dynamic>) {
      throw const CloudServiceException(CloudServiceErrorKind.invalidResponse);
    }
    return decoded;
  }

  @override
  Future<void> uploadArticles(String identityCode, Object payload) async {
    await _client.putJson(_articlesPath(identityCode), payload);
  }

  @override
  Future<Map<String, dynamic>> downloadFeeds(String identityCode) async {
    final Object? decoded = await _client.getJson(
      _feedsPath(identityCode),
      allowNotFound: true,
    );
    if (decoded == null) {
      return _emptyCollectionPayload(identityCode, 'feeds');
    }
    if (decoded is List<dynamic>) {
      return <String, dynamic>{
        'identityCode': identityCode,
        'updatedAt': DateTime.now().toIso8601String(),
        'feeds': decoded,
      };
    }
    if (decoded is! Map<String, dynamic>) {
      throw const CloudServiceException(CloudServiceErrorKind.invalidResponse);
    }
    return decoded;
  }

  @override
  Future<void> uploadFeeds(String identityCode, Object payload) async {
    await _client.putJson(_feedsPath(identityCode), payload);
  }

  @override
  Future<Uint8List?> downloadAvatar(String identityCode) {
    return _client.getBytes(_avatarPath(identityCode), allowNotFound: true);
  }

  @override
  Future<void> uploadAvatar(
    String identityCode,
    Uint8List bytes,
    String contentType,
  ) async {
    await _client.putBytes(
      _avatarPath(identityCode),
      bytes,
      contentType: contentType,
    );
    if (_identityService != null) {
      await _identityService.updateAvatarMetadata(identityCode);
    }
  }
}

Map<String, dynamic> _emptyCollectionPayload(
  String identityCode,
  String key,
) {
  return <String, dynamic>{
    'identityCode': identityCode,
    'updatedAt': DateTime.now().toIso8601String(),
    key: <Object>[],
  };
}

Map<String, dynamic> _buildUserRecord(
  String userName,
  DateTime now, {
  required int avatarVersion,
}) {
  return <String, dynamic>{
    'userName': userName,
    'updatedAt': now.toIso8601String(),
    'avatarVersion': avatarVersion,
  };
}

Map<String, dynamic> _buildProfileDocument({
  required String identityCode,
  required String userName,
  required DateTime now,
  required int avatarVersion,
}) {
  return <String, dynamic>{
    'identityCode': identityCode,
    'userName': userName,
    'updatedAt': now.toIso8601String(),
    'avatarVersion': avatarVersion,
    'avatarFile': 'avatar.jpg',
  };
}

String? _extractUserName(Map<String, dynamic> record) {
  final Object? rawUserName = record['userName'];
  if (rawUserName is! String) {
    return null;
  }
  final String trimmed = rawUserName.trim();
  return trimmed.isEmpty ? null : trimmed;
}

int _extractAvatarVersion(Map<String, dynamic> record) {
  final Object? rawVersion = record['avatarVersion'];
  if (rawVersion is int) {
    return rawVersion;
  }
  if (rawVersion is num) {
    return rawVersion.toInt();
  }
  return 0;
}

String get _usersIndexPath => 'users.json';

String _profilePath(String identityCode) => 'users/$identityCode/profile.json';

String _feedsPath(String identityCode) => 'users/$identityCode/feeds.json';

String _articlesPath(String identityCode) =>
    'users/$identityCode/articles.json';

String _avatarPath(String identityCode) => 'users/$identityCode/avatar.jpg';

String normalizePrivateCloudBaseUrl(String rawValue) {
  final String trimmed = rawValue.trim();
  if (trimmed.isEmpty) {
    return '';
  }
  if (trimmed.startsWith('http://') || trimmed.startsWith('https://')) {
    return trimmed.replaceAll(RegExp(r'/+$'), '');
  }
  return 'https://${trimmed.replaceAll(RegExp(r'/+$'), '')}';
}

String normalizePrivateCloudBasePath(String rawValue) {
  final String trimmed = rawValue.trim();
  if (trimmed.isEmpty) {
    return '/resonance/';
  }
  final String normalized = '/${trimmed.replaceAll(RegExp(r'^/+|/+$'), '')}/';
  return normalized == '//' ? '/resonance/' : normalized;
}

Map<String, dynamic> buildPrivateCloudArticlesPayload(
  String identityCode,
  List<Article> articles,
) {
  return <String, dynamic>{
    'identityCode': identityCode,
    'updatedAt': DateTime.now().toIso8601String(),
    'articles': articles.map((Article article) => article.toJson()).toList(),
  };
}

Map<String, dynamic> buildPrivateCloudFeedsPayload(
  String identityCode,
  List<FeedSource> feeds,
) {
  return <String, dynamic>{
    'identityCode': identityCode,
    'updatedAt': DateTime.now().toIso8601String(),
    'feeds': feeds.map((FeedSource feed) => feed.toJson()).toList(),
  };
}
