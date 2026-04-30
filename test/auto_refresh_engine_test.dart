import 'package:flutter_test/flutter_test.dart';
import 'package:rsstool/src/models/feed_source.dart';
import 'package:rsstool/src/models/reader_settings.dart';
import 'package:rsstool/src/services/auto_refresh_engine.dart';

void main() {
  group('AutoRefreshEngine', () {
    final AutoRefreshEngine engine = AutoRefreshEngine.defaultInstance();

    test('computes earliest next refresh time per source independently', () {
      final DateTime now = DateTime.parse('2026-04-30T12:00:00Z');
      final ReaderSettings settings = ReaderSettings.defaults.copyWith(
        autoRefreshMode: AutoRefreshMode.partial,
      );
      final List<FeedSource> feeds = <FeedSource>[
        FeedSource(
          id: 'a',
          title: 'A',
          url: 'https://example.com/a.xml',
          enabled: true,
          autoRefreshEnabled: true,
          autoRefreshIntervalMinutes: 15,
          lastFetchedAt: DateTime.parse('2026-04-30T11:50:00Z'),
        ),
        FeedSource(
          id: 'b',
          title: 'B',
          url: 'https://example.com/b.xml',
          enabled: true,
          autoRefreshEnabled: true,
          autoRefreshIntervalMinutes: 180,
          lastFetchedAt: DateTime.parse('2026-04-30T10:00:00Z'),
        ),
        FeedSource(
          id: 'c',
          title: 'C',
          url: 'https://example.com/c.xml',
          enabled: true,
          autoRefreshEnabled: true,
          autoRefreshIntervalMinutes: 1440,
          lastFetchedAt: DateTime.parse('2026-04-29T12:05:00Z'),
        ),
      ];

      final DateTime? nextAt = engine.nextRefreshAt(
        settings: settings,
        feeds: feeds,
        now: now,
      );
      final List<FeedSource> dueFeeds = engine.dueFeeds(
        settings: settings,
        feeds: feeds,
        now: now,
      );

      expect(nextAt?.toUtc(), DateTime.parse('2026-04-30T12:05:00Z'));
      expect(dueFeeds, isEmpty);
    });

    test('treats first-time enabled source as immediately due', () {
      final DateTime now = DateTime.parse('2026-04-30T12:00:00Z');
      final ReaderSettings settings = ReaderSettings.defaults.copyWith(
        autoRefreshMode: AutoRefreshMode.partial,
      );
      final FeedSource firstRunFeed = FeedSource(
        id: 'fresh',
        title: 'Fresh',
        url: 'https://example.com/fresh.xml',
        enabled: true,
        autoRefreshEnabled: true,
        autoRefreshIntervalMinutes: 60,
      );

      final DateTime? nextAt = engine.nextRefreshTimeForSource(
        settings: settings,
        source: firstRunFeed,
        now: now,
      );

      expect(nextAt, now);
    });

    test('all-on mode uses global interval without overriding per-source values', () {
      final DateTime now = DateTime.parse('2026-04-30T12:00:00Z');
      final ReaderSettings settings = ReaderSettings.defaults.copyWith(
        autoRefreshMode: AutoRefreshMode.allOn,
        globalAutoRefreshIntervalMinutes: 60,
      );
      final FeedSource feed = FeedSource(
        id: 'locked',
        title: 'Locked',
        url: 'https://example.com/locked.xml',
        enabled: true,
        autoRefreshEnabled: false,
        autoRefreshIntervalMinutes: 4320,
        lastFetchedAt: DateTime.parse('2026-04-30T11:30:00Z'),
      );

      final DateTime? nextAt = engine.nextRefreshTimeForSource(
        settings: settings,
        source: feed,
        now: now,
      );

      expect(nextAt?.toUtc(), DateTime.parse('2026-04-30T12:30:00Z'));
      expect(feed.autoRefreshIntervalMinutes, 4320);
    });
  });
}
