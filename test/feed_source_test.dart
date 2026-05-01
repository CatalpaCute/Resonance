import 'package:flutter_test/flutter_test.dart';
import 'package:rsstool/src/models/feed_source.dart';

void main() {
  group('FeedSource', () {
    test('serializes and restores auto refresh fields', () {
      final FeedSource source = FeedSource(
        id: 'feed_1',
        title: 'Example',
        url: 'https://example.com/feed.xml',
        siteUrl: 'https://example.com',
        iconUrl: 'https://example.com/icon.png',
        folderId: null,
        enabled: true,
        autoRefreshEnabled: true,
        notificationEnabled: true,
        autoRefreshIntervalMinutes: 180,
        lastAutoRefreshAttemptAt: DateTime.parse('2026-04-30T12:00:00Z'),
        lastFetchedAt: DateTime.parse('2026-04-30T09:00:00Z'),
      );

      final FeedSource restored = FeedSource.fromJson(source.toJson());

      expect(restored.autoRefreshEnabled, isTrue);
      expect(restored.notificationEnabled, isTrue);
      expect(restored.autoRefreshIntervalMinutes, 180);
      expect(
        restored.lastAutoRefreshAttemptAt?.toUtc(),
        DateTime.parse('2026-04-30T12:00:00Z'),
      );
    });

    test('falls back to disabled auto refresh defaults', () {
      final FeedSource restored = FeedSource.fromJson(<String, dynamic>{
        'id': 'feed_2',
        'title': 'Fallback',
        'url': 'https://example.com/fallback.xml',
        'enabled': true,
      });

      expect(restored.autoRefreshEnabled, isFalse);
      expect(restored.notificationEnabled, isFalse);
      expect(restored.autoRefreshIntervalMinutes, 1440);
      expect(restored.lastAutoRefreshAttemptAt, isNull);
    });
  });
}
