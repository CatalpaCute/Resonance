import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:rsstool/src/models/article.dart';
import 'package:rsstool/src/models/feed_source.dart';
import 'package:rsstool/src/models/user_profile.dart';
import 'package:rsstool/src/services/cloud_service_router.dart';
import 'package:rsstool/src/services/json_store.dart';
import 'package:rsstool/src/services/rss_service.dart';
import 'package:rsstool/src/state/reader_controller.dart';

import 'test_support/fake_official_cloud_service.dart';

void main() {
  group('ReaderController user flows', () {
    late Directory documentsDir;
    late JsonStore store;
    late ReaderController controller;
    late FakeOfficialCloudService cloudService;

    setUp(() async {
      documentsDir =
          await Directory.systemTemp.createTemp('rsstool_controller_');
      store = JsonStore(
        documentsDirectoryResolver: () async => documentsDir,
      );
      cloudService = FakeOfficialCloudService();
      controller = ReaderController(
        store: store,
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

    test('generates a valid identity code and signs in after cloud create',
        () async {
      await controller.generateIdentityAndSignIn();

      expect(controller.isSignedIn, isTrue);
      expect(controller.currentIdentityCodeDisplay, hasLength(14));
      expect(
          controller.currentIdentityCodeDisplay, matches(r'^[A-Za-z0-9]{14}$'));
      expect(controller.currentUser, isNotNull);
      expect(
        cloudService.usersByIdentityCode[controller.currentIdentityCodeDisplay],
        isNotNull,
      );
    });

    test('rejects invalid identity code without persisting a session',
        () async {
      await controller.signInWithIdentityCode('bad-code');

      expect(controller.isSignedIn, isFalse);
      expect(controller.errorMessage, isNotNull);
      expect((await store.loadCurrentUserSession()).isSignedIn, isFalse);
    });

    test('does not sign in when the cloud does not know the identity code',
        () async {
      await controller.signInWithIdentityCode('AbCd1234EfGh56');

      expect(controller.isSignedIn, isFalse);
      expect(await store.loadUserProfile('AbCd1234EfGh56'), isNull);
    });

    test('loads a cloud-backed profile when the code exists', () async {
      cloudService.usersByIdentityCode['AbCd1234EfGh56'] = 'Cloud Catal';

      await controller.signInWithIdentityCode('AbCd1234EfGh56');

      expect(controller.isSignedIn, isTrue);
      expect(controller.currentUser?.identityCode, 'AbCd1234EfGh56');
      expect(await store.loadUserProfile('AbCd1234EfGh56'), isNotNull);
      expect(controller.currentUser?.displayName, 'Cloud Catal');
    });

    test('loads an existing profile and keeps display name changes', () async {
      cloudService.usersByIdentityCode['AbCd1234EfGh56'] = 'Cloud Catal';
      await controller.signInWithIdentityCode('AbCd1234EfGh56');
      await controller.updateUserDisplayName('Catal');

      final ReaderController reloaded = ReaderController(
        store: store,
        cloudServiceResolver: DefaultCloudServiceResolver(
          officialCloudService: cloudService,
        ),
        rssService: RssService(),
      );
      await reloaded.initialize();

      expect(reloaded.isSignedIn, isTrue);
      expect(reloaded.currentUser?.identityCode, 'AbCd1234EfGh56');
      expect(reloaded.currentUser?.displayName, 'Catal');
      expect(reloaded.currentUserDisplayName, 'Catal');
      expect(cloudService.usersByIdentityCode['AbCd1234EfGh56'], 'Catal');
    });

    test('retries when create hits a cloud conflict', () async {
      cloudService.createConflictCount = 1;

      await controller.generateIdentityAndSignIn();

      expect(controller.isSignedIn, isTrue);
      expect(cloudService.usersByIdentityCode, isNotEmpty);
    });

    test('does not keep a local identity when cloud create fails', () async {
      cloudService.configured = false;

      await controller.generateIdentityAndSignIn();

      expect(controller.isSignedIn, isFalse);
      expect(controller.currentUser, isNull);
    });

    test('offline create keeps a local user and auto-registers later',
        () async {
      cloudService.failCreateWithNetwork = true;

      await controller.generateIdentityAndSignIn();

      expect(controller.isSignedIn, isTrue);
      final String identityCode = controller.currentIdentityCodeDisplay;
      expect(identityCode, hasLength(14));
      expect(controller.currentUser?.pendingCloudCreate, isTrue);

      cloudService.failCreateWithNetwork = false;
      await controller.handleAppResumed();

      expect(cloudService.usersByIdentityCode[identityCode], isNotNull);
      expect(controller.currentUser?.pendingCloudCreate, isFalse);
      expect(controller.currentCloudSyncStatus, CloudSyncStatus.synced);
    });

    test('manual upload sends feeds before articles', () async {
      cloudService.usersByIdentityCode['AbCd1234EfGh56'] = 'Cloud Catal';
      await store.saveFeeds(<FeedSource>[
        FeedSource(
          id: 'feed_1',
          title: 'Feed One',
          url: 'https://example.com/rss.xml',
          enabled: true,
          autoRefreshEnabled: false,
          notificationEnabled: false,
          autoRefreshIntervalMinutes: 60,
        ),
      ]);
      await store.saveArticles(<Article>[
        Article(
          id: 'article_1',
          sourceId: 'feed_1',
          title: 'Article One',
          publishedAt: DateTime.parse('2026-05-18T12:00:00Z'),
          url: 'https://example.com/article-1',
          readState: ArticleReadState.unread,
          starred: false,
          savedForLater: false,
        ),
      ]);
      await controller.reloadPersistedState();
      await controller.signInWithIdentityCode('AbCd1234EfGh56');
      await controller.setCloudServiceEnabled(true);

      await controller.uploadCurrentUserToOfficialCloud();

      expect(cloudService.uploadLog.take(2).toList(), <String>[
        'feeds',
        'articles',
      ]);
      expect(
        cloudService.feedsByIdentityCode['AbCd1234EfGh56']?['feeds'],
        isA<List<dynamic>>(),
      );
      expect(
        cloudService.articlesByIdentityCode['AbCd1234EfGh56']?['articles'],
        isA<List<dynamic>>(),
      );
    });

    test('failed user-name sync is retried automatically when cloud is back',
        () async {
      cloudService.usersByIdentityCode['AbCd1234EfGh56'] = 'Cloud Catal';
      await controller.signInWithIdentityCode('AbCd1234EfGh56');

      cloudService.failUpdateUserWithNetwork = true;
      await controller.updateUserDisplayName('Offline Rename');
      expect(controller.currentUser?.pendingCloudProfileSync, isTrue);

      cloudService.failUpdateUserWithNetwork = false;
      await controller.handleAppResumed();

      expect(
        cloudService.usersByIdentityCode['AbCd1234EfGh56'],
        'Offline Rename',
      );
      expect(controller.currentUser?.pendingCloudProfileSync, isFalse);
      expect(controller.currentCloudSyncStatus, CloudSyncStatus.synced);
    });

    test('manual download replaces local feeds and articles', () async {
      cloudService.usersByIdentityCode['AbCd1234EfGh56'] = 'Cloud Catal';
      cloudService.feedsByIdentityCode['AbCd1234EfGh56'] = <String, dynamic>{
        'identityCode': 'AbCd1234EfGh56',
        'updatedAt': '2026-05-18T12:00:00Z',
        'feeds': <Map<String, dynamic>>[
          <String, dynamic>{
            'id': 'feed_cloud',
            'title': 'Cloud Feed',
            'url': 'https://example.com/cloud.xml',
            'enabled': true,
            'autoRefreshEnabled': false,
            'notificationEnabled': false,
            'autoRefreshIntervalMinutes': 60,
          },
        ],
      };
      cloudService.articlesByIdentityCode['AbCd1234EfGh56'] = <String, dynamic>{
        'identityCode': 'AbCd1234EfGh56',
        'updatedAt': '2026-05-18T12:00:00Z',
        'articles': <Map<String, dynamic>>[
          <String, dynamic>{
            'id': 'article_cloud',
            'sourceId': 'feed_cloud',
            'title': 'Cloud Article',
            'publishedAt': '2026-05-18T12:00:00Z',
            'url': 'https://example.com/cloud-article',
            'readState': 'unread',
            'starred': false,
            'savedForLater': false,
          },
        ],
      };
      await controller.signInWithIdentityCode('AbCd1234EfGh56');
      await controller.setCloudServiceEnabled(true);

      await controller.downloadCurrentUserFromOfficialCloud();

      expect(controller.feeds, hasLength(1));
      expect(controller.feeds.first.title, 'Cloud Feed');
      expect(controller.articles, hasLength(1));
      expect(controller.articles.first.title, 'Cloud Article');
      final PersistedReaderState persisted = await store.load();
      expect(persisted.feeds.first.id, 'feed_cloud');
      expect(persisted.articles.first.id, 'article_cloud');
    });
  });
}
