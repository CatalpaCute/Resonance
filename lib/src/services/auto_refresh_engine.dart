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
    int attemptedCount = 0;
    int refreshedCount = 0;
    final List<AutoRefreshSourceUpdate> sourceUpdates =
        <AutoRefreshSourceUpdate>[];

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
        final _MergeArticlesResult mergeResult = _mergeArticlesForSource(
          source: refreshedSource,
          drafts: parsed.articles,
          currentArticles: articles,
        );
        articles = mergeResult.articles;
        if (mergeResult.newArticles.isNotEmpty) {
          sourceUpdates.add(
            AutoRefreshSourceUpdate(
              sourceId: refreshedSource.id,
              sourceTitle: refreshedSource.title,
              notificationEnabled: refreshedSource.notificationEnabled,
              newArticles: mergeResult.newArticles
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
      sourceUpdates: List<AutoRefreshSourceUpdate>.unmodifiable(sourceUpdates),
    );
  }

  _MergeArticlesResult _mergeArticlesForSource({
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

    final List<Article> newArticles = <Article>[];

    for (final ParsedArticleDraft draft in drafts) {
      final String draftUrl = draft.url.trim();
      final String candidateId = _rssService.stableArticleId(source.id, draft);
      final Article? existing =
          currentById[candidateId] ?? currentByUrl[draftUrl];
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
        currentByUrl[draftUrl] = currentById[articleId]!;
      }
    }

    final List<Article> merged = currentById.values.toList()
      ..sort((Article a, Article b) => b.publishedAt.compareTo(a.publishedAt));
    newArticles.sort((Article a, Article b) => b.publishedAt.compareTo(a.publishedAt));
    return _MergeArticlesResult(
      articles: merged,
      newArticles: List<Article>.unmodifiable(newArticles),
    );
  }
}

class _MergeArticlesResult {
  const _MergeArticlesResult({
    required this.articles,
    required this.newArticles,
  });

  final List<Article> articles;
  final List<Article> newArticles;
}
