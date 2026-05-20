import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:rsstool/src/models/article.dart';
import 'package:rsstool/src/models/feed_source.dart';
import 'package:rsstool/src/services/official_cloud_service.dart';
import 'package:rsstool/src/services/private_webdav_service.dart';

void main() {
  group('PrivateWebDav services', () {
    late _FakeWebDavClient fakeHttpClient;
    late WebDavCloudClient client;
    late PrivateWebDavIdentitySyncService identityService;
    late PrivateWebDavContentSyncService contentService;

    setUp(() {
      fakeHttpClient = _FakeWebDavClient();
      client = WebDavCloudClient(
        baseUrl: 'https://dav.example.com',
        basePath: '/resonance/',
        username: 'catal',
        password: 'secret',
        client: fakeHttpClient,
      );
      identityService = PrivateWebDavIdentitySyncService(client: client);
      contentService = PrivateWebDavContentSyncService(
        client: client,
        identityService: identityService,
      );
    });

    test('creates and updates users through users.json', () async {
      final CloudCreateUserResult created = await identityService.createUser(
        'AbCd1234EfGh56',
        'Catal',
      );

      expect(created.identityCode, 'AbCd1234EfGh56');
      expect(created.userName, 'Catal');

      final CloudUserLookupResult lookedUp =
          await identityService.getUser('AbCd1234EfGh56');
      expect(lookedUp.exists, isTrue);
      expect(lookedUp.userName, 'Catal');

      await identityService.updateUser('AbCd1234EfGh56', 'Catal Updated');

      final Map<String, dynamic> usersIndex = jsonDecode(
        utf8.decode(fakeHttpClient.files['/resonance/users.json']!),
      ) as Map<String, dynamic>;
      expect(
        (usersIndex['AbCd1234EfGh56'] as Map<String, dynamic>)['userName'],
        'Catal Updated',
      );
      expect(
        fakeHttpClient.files.containsKey(
          '/resonance/users/AbCd1234EfGh56/profile.json',
        ),
        isTrue,
      );
    });

    test('uploads and downloads feeds, articles, and avatar', () async {
      const String identityCode = 'AbCd1234EfGh56';
      final Map<String, dynamic> feedsPayload = buildPrivateCloudFeedsPayload(
        identityCode,
        <FeedSource>[
          FeedSource(
            id: 'feed_1',
            title: 'Tech',
            url: 'https://example.com/rss.xml',
            enabled: true,
            autoRefreshEnabled: false,
            notificationEnabled: false,
            autoRefreshIntervalMinutes: 60,
          ),
        ],
      );
      final Map<String, dynamic> articlesPayload =
          buildPrivateCloudArticlesPayload(
        identityCode,
        <Article>[
          Article(
            id: 'article_1',
            sourceId: 'feed_1',
            title: 'Example',
            publishedAt: DateTime.parse('2026-05-20T12:00:00Z'),
            url: 'https://example.com/article',
            readState: ArticleReadState.unread,
            starred: false,
            savedForLater: false,
          ),
        ],
      );

      await contentService.uploadFeeds(identityCode, feedsPayload);
      await contentService.uploadArticles(identityCode, articlesPayload);
      await contentService.uploadAvatar(
        identityCode,
        Uint8List.fromList(<int>[1, 2, 3]),
        'image/jpeg',
      );

      final Map<String, dynamic> downloadedFeeds =
          await contentService.downloadFeeds(identityCode);
      final Map<String, dynamic> downloadedArticles =
          await contentService.downloadArticles(identityCode);
      final Uint8List? downloadedAvatar =
          await contentService.downloadAvatar(identityCode);

      expect((downloadedFeeds['feeds'] as List<dynamic>).length, 1);
      expect((downloadedArticles['articles'] as List<dynamic>).length, 1);
      expect(downloadedAvatar, isNotNull);
      expect(
        fakeHttpClient.files.containsKey(
          '/resonance/users/AbCd1234EfGh56/avatar.jpg',
        ),
        isTrue,
      );
    });
  });
}

class _FakeWebDavClient extends http.BaseClient {
  final Map<String, Uint8List> files = <String, Uint8List>{};
  final Set<String> directories = <String>{'/resonance'};

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    final String path = request.url.path.replaceAll(RegExp(r'/+$'), '');

    switch (request.method) {
      case 'PROPFIND':
        return _response(
          directories.contains(path) || files.containsKey(path) ? 207 : 404,
        );
      case 'MKCOL':
        directories.add(path);
        return _response(201);
      case 'GET':
        final Uint8List? file = files[path];
        if (file == null) {
          return _response(404);
        }
        return _response(200, body: file);
      case 'PUT':
        final String? parent = _parentDirectory(path);
        if (parent != null && !directories.contains(parent)) {
          return _response(409);
        }
        files[path] = await request.finalize().toBytes();
        return _response(201);
      case 'DELETE':
        files.remove(path);
        return _response(204);
      default:
        return _response(405);
    }
  }

  String? _parentDirectory(String path) {
    final int slashIndex = path.lastIndexOf('/');
    if (slashIndex <= 0) {
      return null;
    }
    return path.substring(0, slashIndex);
  }

  http.StreamedResponse _response(
    int statusCode, {
    Uint8List? body,
  }) {
    final Stream<List<int>> stream =
        Stream<List<int>>.value(body ?? Uint8List(0));
    return http.StreamedResponse(stream, statusCode);
  }
}
