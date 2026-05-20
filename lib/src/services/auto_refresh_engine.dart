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
    required this.sourceUpdates,
  });

  final int attemptedCount;
  final int refreshedCount;
  final List<AutoRefreshSourceUpdate> sourceUpdates;
}

class AutoRefreshSourceUpdate {
  const AutoRefreshSourceUpdate({
    required this.sourceId,
    required this.sourceTitle,
    required this.notificationEnabled,
    required this.newArticles,
  });

  final String sourceId;
  final String sourceTitle;
  final bool notificationEnabled;
  final List<AutoRefreshNewArticle> newArticles;
}

class AutoRefreshNewArticle {
  const AutoRefreshNewArticle({
    required this.articleId,
    required this.sourceId,
    required this.sourceTitle,
    required this.title,
    required this.publishedAt,
  });

  final String articleId;
  final String sourceId;
  final String sourceTitle;
  final String title;
  final DateTime publishedAt;
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
    final int intervalMinutes = settings.autoRefreshMode == AutoRefreshMode.allOn
        ? settings.globalAutoRefreshIntervalMinutes
        : source.autoRefreshIntervalMinutes;
    final DateTime currentBoundary = alignedRefreshBoundaryAtOrBefore(
      cursor,
      intervalMinutes,
    );
    final DateTime? baseTime = latestAutoRefreshBaseTime(source);
    if (baseTime == null || baseTime.isBefore(currentBoundary)) {
      return currentBoundary;
    }

    return nextAlignedRefreshBoundaryAfter(
      cursor,
      intervalMinutes,
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

  /// 设计意图：
  /// 统一把自动更新对齐到“现实时间边界”，而不是从上次刷新时间往后漂移。
  /// 例如 15 分钟永远落在 :00 / :15 / :30 / :45，1 小时永远落在整点。
  /// 这样 Windows 前台、Windows 托盘和 Android 的后台调度都共享同一节奏。
  DateTime alignedRefreshBoundaryAtOrBefore(
    DateTime time,
    int intervalMinutes,
  ) {
    final int normalizedInterval = intervalMinutes <= 0 ? 1 : intervalMinutes;

    if (normalizedInterval < 1440) {
      final DateTime dayStart = _dayStart(time);
      final int minutesSinceDayStart = time.difference(dayStart).inMinutes;
      final int alignedMinutes =
          (minutesSinceDayStart ~/ normalizedInterval) * normalizedInterval;
      return dayStart.add(Duration(minutes: alignedMinutes));
    }

    final DateTime dayStart = _dayStart(time);
    final int intervalDays = normalizedInterval ~/ 1440;
    final DateTime epochDayStart = _zonedDateTime(
      year: 1970,
      month: 1,
      day: 1,
      sample: time,
    );
    final int daysSinceEpoch = dayStart.difference(epochDayStart).inDays;
    final int alignedDays = (daysSinceEpoch ~/ intervalDays) * intervalDays;
    return epochDayStart.add(Duration(days: alignedDays));
  }

  DateTime nextAlignedRefreshBoundaryAfter(
    DateTime time,
    int intervalMinutes,
  ) {
    final DateTime currentBoundary = alignedRefreshBoundaryAtOrBefore(
      time,
      intervalMinutes,
    );
    return currentBoundary.add(Duration(minutes: intervalMinutes));
  }

  DateTime _dayStart(DateTime time) => _zonedDateTime(
        year: time.year,
        month: time.month,
        day: time.day,
        sample: time,
      );

  DateTime _zonedDateTime({
    required int year,
    required int month,
    required int day,
    required DateTime sample,
  }) {
    if (sample.isUtc) {
      return DateTime.utc(year, month, day);
    }
    return DateTime(year, month, day);
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
        sourceUpdates: <AutoRefreshSourceUpdate>[],
      );
    }

    final List<FeedSource> feeds = List<FeedSource>.from(state.feeds);
    List<Article> articles = List<Article>.from(state.articles);
    final List<AutoRefreshSourceUpdate> sourceUpdates =
        <AutoRefreshSourceUpdate>[];

    // 1. Identify valid due feeds and mark attempt timestamps
    final List<_DueFeedAttempt> attempts = <_DueFeedAttempt>[];
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

      final DateTime attemptAt = DateTime.now();
      final FeedSource attemptMarked = current.copyWith(
        lastAutoRefreshAttemptAt: attemptAt,
      );
      feeds[index] = attemptMarked;
      attempts.add(_DueFeedAttempt(index: index, attemptMarked: attemptMarked));
    }

    if (attempts.isEmpty) {
      return const AutoRefreshRunResult(
        attemptedCount: 0,
        refreshedCount: 0,
        sourceUpdates: <AutoRefreshSourceUpdate>[],
      );
    }

    // 2. Persist attempt timestamps once before starting I/O
    await _store.saveFeeds(feeds);

    // 3. Fetch all due feeds concurrently
    final List<Future<_FeedFetchResult?>> fetchFutures =
        attempts.map((_DueFeedAttempt attempt) async {
      try {
        final ParsedFeedResult parsed =
            await _rssService.fetchFeed(attempt.attemptMarked.url);
        return _FeedFetchResult(
          attempt: attempt,
          parsedResult: parsed,
        );
      } catch (error, stackTrace) {
        developer.log(
          'Automatic refresh failed for ${attempt.attemptMarked.url}',
          name: 'AutoRefreshEngine',
          error: error,
          stackTrace: stackTrace,
        );
        return null;
      }
    }).toList();

    final List<_FeedFetchResult?> fetchResults =
        await Future.wait(fetchFutures);
    final List<_FeedFetchResult> successfulResults =
        fetchResults.whereType<_FeedFetchResult>().toList();

    // 4. Update metadata of successfully fetched feeds
    final List<FeedSource> updatedSources = <FeedSource>[];
    final List<List<ParsedArticleDraft>> draftsPerSource =
        <List<ParsedArticleDraft>>[];

    for (final _FeedFetchResult result in successfulResults) {
      final FeedSource original = result.attempt.attemptMarked;
      final ParsedFeedResult parsed = result.parsedResult;
      final FeedSource refreshedSource = original.copyWith(
        title: original.title.trim().isEmpty ? parsed.title : original.title,
        siteUrl: parsed.siteUrl,
        iconUrl: parsed.iconUrl,
        lastFetchedAt: DateTime.now(),
      );
      feeds[result.attempt.index] = refreshedSource;
      updatedSources.add(refreshedSource);
      draftsPerSource.add(parsed.articles);
    }

    // 5. Bulk merge new articles in a single pass
    if (updatedSources.isNotEmpty) {
      final _MergeArticlesResult mergeResult = _mergeArticlesForSources(
        sources: updatedSources,
        draftsPerSource: draftsPerSource,
        currentArticles: articles,
      );
      articles = mergeResult.articles;

      // Group new articles by source to build updates
      final Map<String, List<Article>> newArticlesBySource =
          <String, List<Article>>{};
      for (final Article article in mergeResult.newArticles) {
        newArticlesBySource
            .putIfAbsent(article.sourceId, () => <Article>[])
            .add(article);
      }

      for (final _FeedFetchResult result in successfulResults) {
        final FeedSource refreshedSource = feeds[result.attempt.index];
        final List<Article> sourceNewArticles =
            newArticlesBySource[refreshedSource.id] ?? const <Article>[];
        if (sourceNewArticles.isNotEmpty) {
          sourceUpdates.add(
            AutoRefreshSourceUpdate(
              sourceId: refreshedSource.id,
              sourceTitle: refreshedSource.title,
              notificationEnabled: refreshedSource.notificationEnabled,
              newArticles: sourceNewArticles
                  .map(
                    (Article article) => AutoRefreshNewArticle(
                      articleId: article.id,
                      sourceId: article.sourceId,
                      sourceTitle: refreshedSource.title,
                      title: article.title,
                      publishedAt: article.publishedAt,
                    ),
                  )
                  .toList(growable: false),
            ),
          );
        }
      }
    }

    // 6. Save all final state to disk once
    await _store.saveFeeds(feeds);
    await _store.saveArticles(articles);
    await _store.saveSettings(state.settings);

    return AutoRefreshRunResult(
      attemptedCount: attempts.length,
      refreshedCount: successfulResults.length,
      sourceUpdates: List<AutoRefreshSourceUpdate>.unmodifiable(sourceUpdates),
    );
  }

  _MergeArticlesResult _mergeArticlesForSource({
    required FeedSource source,
    required List<ParsedArticleDraft> drafts,
    required List<Article> currentArticles,
  }) {
    return _mergeArticlesForSources(
      sources: <FeedSource>[source],
      draftsPerSource: <List<ParsedArticleDraft>>[drafts],
      currentArticles: currentArticles,
    );
  }

  _MergeArticlesResult _mergeArticlesForSources({
    required List<FeedSource> sources,
    required List<List<ParsedArticleDraft>> draftsPerSource,
    required List<Article> currentArticles,
  }) {
    final Map<String, Article> currentById = <String, Article>{
      for (final Article article in currentArticles) article.id: article,
    };
    final Map<String, Map<String, Article>> currentBySourceAndUrl =
        <String, Map<String, Article>>{};
    for (final Article article in currentArticles) {
      if (article.url.trim().isNotEmpty) {
        currentBySourceAndUrl
            .putIfAbsent(article.sourceId, () => <String, Article>{})
            [article.url] = article;
      }
    }

    final List<Article> newArticles = <Article>[];

    for (int i = 0; i < sources.length; i++) {
      final FeedSource source = sources[i];
      final List<ParsedArticleDraft> drafts = draftsPerSource[i];
      final Map<String, Article> sourceUrlMap =
          currentBySourceAndUrl[source.id] ?? const <String, Article>{};

      for (final ParsedArticleDraft draft in drafts) {
        final String draftUrl = draft.url.trim();
        final String candidateId = _rssService.stableArticleId(source.id, draft);
        final Article? existing =
            currentById[candidateId] ?? sourceUrlMap[draftUrl];
        final String articleId = existing?.id ?? candidateId;

        if (existing != null && existing.id != articleId) {
          currentById.remove(existing.id);
        }

        final Article nextArticle = Article(
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
        currentById[articleId] = nextArticle;
        if (existing == null) {
          newArticles.add(nextArticle);
        }

        if (draftUrl.isNotEmpty) {
          currentBySourceAndUrl
              .putIfAbsent(source.id, () => <String, Article>{})
              [draftUrl] = nextArticle;
        }
      }
    }

    final List<Article> merged = currentById.values.toList()
      ..sort((Article a, Article b) => b.publishedAt.compareTo(a.publishedAt));
    newArticles
        .sort((Article a, Article b) => b.publishedAt.compareTo(a.publishedAt));
    return _MergeArticlesResult(
      articles: merged,
      newArticles: List<Article>.unmodifiable(newArticles),
    );
  }
}

class _DueFeedAttempt {
  const _DueFeedAttempt({
    required this.index,
    required this.attemptMarked,
  });

  final int index;
  final FeedSource attemptMarked;
}

class _FeedFetchResult {
  const _FeedFetchResult({
    required this.attempt,
    required this.parsedResult,
  });

  final _DueFeedAttempt attempt;
  final ParsedFeedResult parsedResult;
}


class _MergeArticlesResult {
  const _MergeArticlesResult({
    required this.articles,
    required this.newArticles,
  });

  final List<Article> articles;
  final List<Article> newArticles;
}
