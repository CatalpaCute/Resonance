import 'dart:convert';
import 'dart:typed_data';

import 'package:http/http.dart' as http;

import '../models/article.dart';
import '../models/feed_source.dart';

const String kOfficialCloudBaseUrl = String.fromEnvironment(
  'OFFICIAL_CLOUD_BASE_URL',
  defaultValue: '',
);

enum CloudServiceErrorKind {
  notConfigured,
  network,
  invalidResponse,
  notFound,
  conflict,
  rejected,
}

class CloudServiceException implements Exception {
  const CloudServiceException(
    this.kind, {
    this.message,
    this.statusCode,
  });

  final CloudServiceErrorKind kind;
  final String? message;
  final int? statusCode;

  @override
  String toString() {
    if (message == null || message!.isEmpty) {
      return 'CloudServiceException(${kind.name})';
    }
    return 'CloudServiceException(${kind.name}): $message';
  }
}

class CloudUserLookupResult {
  const CloudUserLookupResult({
    required this.exists,
    this.userName,
  });

  final bool exists;
  final String? userName;
}

class CloudCreateUserResult {
  const CloudCreateUserResult({
    required this.identityCode,
    required this.userName,
  });

  final String identityCode;
  final String userName;
}

abstract class OfficialCloudService {
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

class HttpOfficialCloudService implements OfficialCloudService {
  HttpOfficialCloudService({
    http.Client? client,
    String? baseUrl,
  })  : _client = client ?? http.Client(),
        _baseUrl = _normalizeBaseUrl(baseUrl ?? kOfficialCloudBaseUrl);

  final http.Client _client;
  final String? _baseUrl;

  @override
  bool get isConfigured => _baseUrl != null;

  @override
  String? get baseUrl => _baseUrl;

  @override
  Future<CloudUserLookupResult> getUser(String identityCode) async {
    final Uri uri = _buildUri(
      '/user',
      queryParameters: <String, String>{
        'identityCode': identityCode,
      },
    );
    final http.Response response = await _send(
      () => _client.get(
        uri,
        headers: <String, String>{
          'accept': 'application/json',
        },
      ),
    );
    final Map<String, dynamic> payload = _decodeJsonMap(response);
    final bool exists = payload['exists'] == true;
    final String? userName = _normalizeString(payload['userName']);
    return CloudUserLookupResult(
      exists: exists,
      userName: userName,
    );
  }

  @override
  Future<CloudCreateUserResult> createUser(
    String identityCode,
    String userName,
  ) async {
    final http.Response response = await _send(
      () => _client.post(
        _buildUri('/user/create'),
        headers: _jsonHeaders,
        body: jsonEncode(<String, dynamic>{
          'identityCode': identityCode,
          'userName': userName,
        }),
      ),
    );
    final Map<String, dynamic> payload = _decodeJsonMap(response);
    return CloudCreateUserResult(
      identityCode: _normalizeString(payload['identityCode']) ?? identityCode,
      userName: _normalizeString(payload['userName']) ?? userName,
    );
  }

  @override
  Future<void> updateUser(
    String identityCode,
    String userName,
  ) async {
    await _send(
      () => _client.put(
        _buildUri('/user'),
        headers: _jsonHeaders,
        body: jsonEncode(<String, dynamic>{
          'identityCode': identityCode,
          'userName': userName,
        }),
      ),
    );
  }

  @override
  Future<Map<String, dynamic>> downloadArticles(String identityCode) async {
    return _downloadCollection(
      identityCode,
      assetType: 'articles',
      itemKey: 'articles',
    );
  }

  @override
  Future<void> uploadArticles(
    String identityCode,
    Object payload,
  ) async {
    await _uploadCollection(identityCode, 'articles', payload);
  }

  @override
  Future<Map<String, dynamic>> downloadFeeds(String identityCode) async {
    return _downloadCollection(
      identityCode,
      assetType: 'feeds',
      itemKey: 'feeds',
    );
  }

  @override
  Future<void> uploadFeeds(
    String identityCode,
    Object payload,
  ) async {
    await _uploadCollection(identityCode, 'feeds', payload);
  }

  @override
  Future<Uint8List?> downloadAvatar(String identityCode) async {
    final List<String> extensions = <String>['jpg', 'png'];
    for (final String extension in extensions) {
      final http.Response response = await _send(
        () => _client.get(
          _buildUri('/users/$identityCode/avatar.$extension'),
        ),
        allowNotFound: true,
      );
      if (response.statusCode == 404) {
        continue;
      }
      return response.bodyBytes;
    }
    return null;
  }

  @override
  Future<void> uploadAvatar(
    String identityCode,
    Uint8List bytes,
    String contentType,
  ) async {
    await _send(
      () => _client.post(
        _buildUri('/users/$identityCode/avatar'),
        headers: <String, String>{
          'content-type': contentType,
        },
        body: bytes,
      ),
    );
  }

  Future<Map<String, dynamic>> _downloadCollection(
    String identityCode, {
    required String assetType,
    required String itemKey,
  }) async {
    final http.Response response = await _send(
      () => _client.get(
        _buildUri('/users/$identityCode/$assetType.json'),
        headers: <String, String>{
          'accept': 'application/json',
        },
      ),
      allowNotFound: true,
    );
    if (response.statusCode == 404) {
      return <String, dynamic>{
        'identityCode': identityCode,
        'updatedAt': DateTime.now().toIso8601String(),
        itemKey: <Object>[],
      };
    }

    final Object? decoded = _decodeJson(response);
    if (decoded is List<dynamic>) {
      return <String, dynamic>{
        'identityCode': identityCode,
        'updatedAt': DateTime.now().toIso8601String(),
        itemKey: decoded,
      };
    }
    if (decoded is! Map<String, dynamic>) {
      throw const CloudServiceException(CloudServiceErrorKind.invalidResponse);
    }
    return decoded;
  }

  Future<void> _uploadCollection(
    String identityCode,
    String assetType,
    Object payload,
  ) async {
    await _send(
      () => _client.put(
        _buildUri('/users/$identityCode/$assetType'),
        headers: _jsonHeaders,
        body: jsonEncode(payload),
      ),
    );
  }

  Future<http.Response> _send(
    Future<http.Response> Function() action, {
    bool allowNotFound = false,
  }) async {
    _ensureConfigured();
    try {
      final http.Response response = await action();
      if (_isSuccessfulStatus(response.statusCode) ||
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

  void _ensureConfigured() {
    if (!isConfigured) {
      throw const CloudServiceException(CloudServiceErrorKind.notConfigured);
    }
  }

  Uri _buildUri(
    String path, {
    Map<String, String>? queryParameters,
  }) {
    final String base = _baseUrl!;
    final Uri rootUri = Uri.parse(base);
    final String normalizedPath = path.startsWith('/') ? path : '/$path';
    return rootUri.replace(
      path: '${rootUri.path.replaceAll(RegExp(r'/+$'), '')}$normalizedPath',
      queryParameters: queryParameters,
    );
  }

  Map<String, dynamic> _decodeJsonMap(http.Response response) {
    final Object? decoded = _decodeJson(response);
    if (decoded is! Map<String, dynamic>) {
      throw const CloudServiceException(CloudServiceErrorKind.invalidResponse);
    }
    return decoded;
  }

  Object? _decodeJson(http.Response response) {
    if (response.body.trim().isEmpty) {
      return <String, dynamic>{};
    }
    return jsonDecode(response.body);
  }

  CloudServiceException _exceptionFromResponse(http.Response response) {
    final String? message = _extractErrorMessage(response.body);
    switch (response.statusCode) {
      case 404:
        return CloudServiceException(
          CloudServiceErrorKind.notFound,
          message: message,
          statusCode: response.statusCode,
        );
      case 409:
        return CloudServiceException(
          CloudServiceErrorKind.conflict,
          message: message,
          statusCode: response.statusCode,
        );
      case 400:
      case 413:
      case 507:
        return CloudServiceException(
          CloudServiceErrorKind.rejected,
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
        return _normalizeString(decoded['error']) ??
            _normalizeString(decoded['message']);
      }
    } catch (_) {
      return null;
    }
    return null;
  }

  static String? _normalizeBaseUrl(String raw) {
    final String trimmed = raw.trim();
    if (trimmed.isEmpty) {
      return null;
    }
    return trimmed.replaceAll(RegExp(r'/+$'), '');
  }

  static String? _normalizeString(Object? value) {
    if (value is! String) {
      return null;
    }
    final String trimmed = value.trim();
    return trimmed.isEmpty ? null : trimmed;
  }

  static bool _isSuccessfulStatus(int statusCode) {
    return statusCode >= 200 && statusCode < 300;
  }

  static Map<String, String> get _jsonHeaders => <String, String>{
        'content-type': 'application/json; charset=utf-8',
        'accept': 'application/json',
      };
}

Map<String, dynamic> buildCloudArticlesPayload(
  String identityCode,
  List<Article> articles,
) {
  return <String, dynamic>{
    'identityCode': identityCode,
    'updatedAt': DateTime.now().toIso8601String(),
    'articles': articles.map((Article article) => article.toJson()).toList(),
  };
}

Map<String, dynamic> buildCloudFeedsPayload(
  String identityCode,
  List<FeedSource> feeds,
) {
  return <String, dynamic>{
    'identityCode': identityCode,
    'updatedAt': DateTime.now().toIso8601String(),
    'feeds': feeds.map((FeedSource feed) => feed.toJson()).toList(),
  };
}
