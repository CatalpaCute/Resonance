import 'dart:developer' as developer;

import '../models/article.dart';
import '../models/feed_source.dart';
import '../models/reader_settings.dart';
import 'json_store.dart';
import 'rss_service.dart';

class AutoRefreshRunResult {
  const AutoRefreshRunResult({
    required this.attemptedCount,
    required this.refreshedCount,
  });

  final int attemptedCount;
  final int refreshedCount;
}

/// 设计意图：
/// 把“自动刷新订阅”的到期判断、后台执行和落盘逻辑抽离出 UI 控制器。
/// 这样 Windows 托盘调度与 Android WorkManager 可以共享同一套核心，
/// 避免两端对刷新时机、失败节流和文章合并策略出现漂移。
class AutoRefreshEngine {
  AutoRefreshEngine({
    required JsonStore store,
    required RssService rssService,
  })  : _store = store,
        _rssService = rssService;

  final JsonStore _store;
  final RssService _rssService;

  factory AutoRefreshEngine.defaultInstance() {
    return AutoRefreshEngine(
      store: JsonStore(),
      rssService: RssService(),
    );
  }

  Future<PersistedReaderState> loadPersistedState() {
    return _store.load();
  }

  DateTime? nextRefreshAt({
    required ReaderSettings settings,
    required List<FeedSource> feeds,
    DateTime? now,
  }) {
    if (!settings.autoRefreshEnabled) {
      return null;
    }

    final DateTime cursor = now ?? DateTime.now();
    DateTime? earliest;
    for (final FeedSource source in feeds) {
      final DateTime? nextAt = nextRefreshTimeForSource(
        settings: settings,
        source: source,
        now: cursor,
      );
      if (nextAt == null) {
        continue;
      }
      if (earliest == null || nextAt.isBefore(earliest)) {
        earliest = nextAt;
      }
    }
    return earliest;
  }

  List<FeedSource> dueFeeds({
    required ReaderSettings settings,
    required List<FeedSource> feeds,
    DateTime? now,
  }) {
    if (!settings.autoRefreshEnabled) {
      return const <FeedSource>[];
    }

    final DateTime cursor = now ?? DateTime.now();
    return feeds.where((FeedSource source) {
      final DateTime? nextAt = nextRefreshTimeForSource(
        settings: settings,
        source: source,
        now: cursor,
      );
      return nextAt != null && !nextAt.isAfter(cursor);
    }).toList();
  }

  DateTime? nextRefreshTimeForSource({
    required ReaderSettings settings,
    required FeedSource source,
    DateTime? now,
  }) {
    if (!source.enabled) {
      return null;
    }

    switch (settings.autoRefreshMode) {
      case AutoRefreshMode.allOff:
        return null;
      case AutoRefreshMode.partial:
        if (!source.autoRefreshEnabled) {
          return null;
        }
        break;
      case AutoRefreshMode.allOn:
        break;
    }

    final DateTime cursor = now ?? DateTime.now();
    final DateTime? baseTime = latestAutoRefreshBaseTime(source);
    if (baseTime == null) {
      return cursor;
    }

    return baseTime.add(
      Duration(
        minutes: settings.autoRefreshMode == AutoRefreshMode.allOn
            ? settings.globalAutoRefreshIntervalMinutes
            : source.autoRefreshIntervalMinutes,
      ),
    );
  }

  DateTime? latestAutoRefreshBaseTime(FeedSource source) {
    final DateTime? fetchedAt = source.lastFetchedAt;
    final DateTime? attemptedAt = source.lastAutoRefreshAttemptAt;
    if (fetchedAt == null) {
      return attemptedAt;
    }
    if (attemptedAt == null) {
      return fetchedAt;
    }
    return fetchedAt.isAfter(attemptedAt) ? fetchedAt : attemptedAt;
  }

  Future<AutoRefreshRunResult> refreshPersistedDueFeeds({
    DateTime? now,
  }) async {
    final PersistedReaderState state = await _store.load();
    final DateTime cursor = now ?? DateTime.now();
    final List<FeedSource> due = dueFeeds(
      settings: state.settings,
      feeds: state.feeds,
      now: cursor,
    );
    if (due.isEmpty) {
      return const AutoRefreshRunResult(
        attemptedCount: 0,
        refreshedCount: 0,
      );
    }

    final List<FeedSource> feeds = List<FeedSource>.from(state.feeds);
    List<Article> articles = List<Article>.from(state.articles);
    int attemptedCount = 0;
    int refreshedCount = 0;

    for (final FeedSource original in due) {
      final int index = feeds.indexWhere((FeedSource item) => item.id == original.id);
      if (index < 0) {
        continue;
      }

      final FeedSource current = feeds[index];
      if (nextRefreshTimeForSource(
            settings: state.settings,
            source: current,
            now: cursor,
          ) ==
          null) {
        continue;
      }

      attemptedCount += 1;

      final DateTime attemptAt = DateTime.now();
      final FeedSource attemptMarked = current.copyWith(
        lastAutoRefreshAttemptAt: attemptAt,
      );
      feeds[index] = attemptMarked;
      await _store.saveFeeds(feeds);

      try {
        final ParsedFeedResult parsed = await _rssService.fetchFeed(current.url);
        final FeedSource refreshedSource = attemptMarked.copyWith(
          title: current.title.trim().isEmpty ? parsed.title : current.title,
          siteUrl: parsed.siteUrl,
          iconUrl: parsed.iconUrl,
          lastFetchedAt: DateTime.now(),
        );
        feeds[index] = refreshedSource;
        articles = _mergeArticlesForSource(
          source: refreshedSource,
          drafts: parsed.articles,
          currentArticles: articles,
        );
        refreshedCount += 1;
      } catch (error, stackTrace) {
        developer.log(
          'Automatic refresh failed for ${current.url}',
          name: 'AutoRefreshEngine',
          error: error,
          stackTrace: stackTrace,
        );
      }
    }

    await _store.saveFeeds(feeds);
    await _store.saveArticles(articles);
    await _store.saveSettings(state.settings);

    return AutoRefreshRunResult(
      attemptedCount: attemptedCount,
      refreshedCount: refreshedCount,
    );
  }

  List<Article> _mergeArticlesForSource({
    required FeedSource source,
    required List<ParsedArticleDraft> drafts,
    required List<Article> currentArticles,
  }) {
    final Map<String, Article> currentById = <String, Article>{
      for (final Article article in currentArticles) article.id: article,
    };
    final Map<String, Article> currentByUrl = <String, Article>{
      for (final Article article in currentArticles)
        if (article.sourceId == source.id && article.url.trim().isNotEmpty)
          article.url: article,
    };

    for (final ParsedArticleDraft draft in drafts) {
      final String draftUrl = draft.url.trim();
      final String candidateId = _rssService.stableArticleId(source.id, draft);
      final Article? existing =
          currentById[candidateId] ?? currentByUrl[draftUrl];
      final String articleId = existing?.id ?? candidateId;

      if (existing != null && existing.id != articleId) {
        currentById.remove(existing.id);
      }

      currentById[articleId] = Article(
        id: articleId,
        sourceId: source.id,
        title: draft.title,
        author: draft.author,
        publishedAt: draft.publishedAt,
        summary: draft.summary,
        summaryHtml: draft.summaryHtml,
        content: draft.content,
        contentHtml: draft.contentHtml,
        url: draft.url,
        readState: existing?.readState ?? ArticleReadState.unread,
        starred: existing?.starred ?? false,
        savedForLater: existing?.savedForLater ?? false,
      );

      if (draftUrl.isNotEmpty) {
        currentByUrl[draftUrl] = currentById[articleId]!;
      }
    }

    final List<Article> merged = currentById.values.toList()
      ..sort((Article a, Article b) => b.publishedAt.compareTo(a.publishedAt));
    return merged;
  }
}
