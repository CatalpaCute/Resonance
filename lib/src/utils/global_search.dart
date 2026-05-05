import '../models/article.dart';
import '../models/feed_source.dart';

class GlobalSearchSourceResult {
  const GlobalSearchSourceResult({
    required this.source,
    required this.score,
  });

  final FeedSource source;
  final int score;
}

class GlobalSearchArticleResult {
  const GlobalSearchArticleResult({
    required this.article,
    required this.sourceTitle,
    required this.score,
  });

  final Article article;
  final String sourceTitle;
  final int score;
}

class GlobalSearchResultSet {
  const GlobalSearchResultSet({
    required this.query,
    required this.sourceResults,
    required this.articleResults,
  });

  final String query;
  final List<GlobalSearchSourceResult> sourceResults;
  final List<GlobalSearchArticleResult> articleResults;

  GlobalSearchSourceResult? get sourceResult =>
      sourceResults.isEmpty ? null : sourceResults.first;
  bool get isIdle => query.isEmpty;
  bool get isEmpty => sourceResults.isEmpty && articleResults.isEmpty;
  int get itemCount => articleResults.length + sourceResults.length;
}

GlobalSearchResultSet searchGlobalContent({
  required List<FeedSource> feeds,
  required List<Article> articles,
  required String query,
  required String Function(Article article) sourceTitleForArticle,
  int articleLimit = 20,
  int sourceLimit = 3,
}) {
  final String normalizedQuery = _normalize(query);
  if (normalizedQuery.isEmpty) {
    return const GlobalSearchResultSet(
      query: '',
      sourceResults: <GlobalSearchSourceResult>[],
      articleResults: <GlobalSearchArticleResult>[],
    );
  }

  final List<GlobalSearchSourceResult> sourceResults =
      <GlobalSearchSourceResult>[];
  for (final FeedSource source in feeds) {
    final int score = _sourceScore(source, normalizedQuery);
    if (score <= 0) {
      continue;
    }
    sourceResults.add(GlobalSearchSourceResult(source: source, score: score));
  }
  sourceResults.sort((GlobalSearchSourceResult a, GlobalSearchSourceResult b) {
    final int scoreOrder = b.score.compareTo(a.score);
    if (scoreOrder != 0) {
      return scoreOrder;
    }
    return a.source.title.compareTo(b.source.title);
  });
  final List<GlobalSearchSourceResult> limitedSources =
      sourceResults.take(sourceLimit).toList(growable: false);

  final Map<String, GlobalSearchArticleResult> articleResults =
      <String, GlobalSearchArticleResult>{};
  for (final Article article in articles) {
    final String sourceTitle = sourceTitleForArticle(article);
    final int score = _articleScore(article, sourceTitle, normalizedQuery);
    if (score <= 0) {
      continue;
    }
    articleResults[article.id] = GlobalSearchArticleResult(
      article: article,
      sourceTitle: sourceTitle,
      score: score,
    );
  }

  for (final GlobalSearchSourceResult sourceResult in limitedSources) {
    for (final Article article in articles) {
      if (article.sourceId != sourceResult.source.id) {
        continue;
      }
      final String sourceTitle = sourceTitleForArticle(article);
      final GlobalSearchArticleResult candidate = GlobalSearchArticleResult(
        article: article,
        sourceTitle: sourceTitle,
        score: 20,
      );
      final GlobalSearchArticleResult? existing = articleResults[article.id];
      if (existing == null || candidate.score > existing.score) {
        articleResults[article.id] = candidate;
      }
    }
  }

  final List<GlobalSearchArticleResult> sorted = articleResults.values.toList()
    ..sort((GlobalSearchArticleResult a, GlobalSearchArticleResult b) {
      final int scoreOrder = b.score.compareTo(a.score);
      if (scoreOrder != 0) {
        return scoreOrder;
      }
      return b.article.publishedAt.compareTo(a.article.publishedAt);
    });

  return GlobalSearchResultSet(
    query: normalizedQuery,
    sourceResults: List<GlobalSearchSourceResult>.unmodifiable(limitedSources),
    articleResults: List<GlobalSearchArticleResult>.unmodifiable(
      sorted.take(articleLimit),
    ),
  );
}

int _sourceScore(FeedSource source, String query) {
  final String title = _normalize(source.title);
  final String url = _normalize(source.url);
  final String siteUrl = _normalize(source.siteUrl ?? '');
  if (title == query) {
    return 120;
  }
  if (title.contains(query)) {
    return 90;
  }
  if (url.contains(query) || siteUrl.contains(query)) {
    return 45;
  }
  return 0;
}

int _articleScore(Article article, String sourceTitle, String query) {
  int score = 0;
  final String title = _normalize(article.title);
  final String author = _normalize(article.author ?? '');
  final String source = _normalize(sourceTitle);
  final String summary = _normalize(article.summary ?? '');
  final String content = _normalize(article.content ?? article.readerText);

  if (title == query) {
    score += 110;
  } else if (title.contains(query)) {
    score += 80;
  }
  if (source.contains(query)) {
    score += 35;
  }
  if (author.contains(query)) {
    score += 25;
  }
  if (summary.contains(query)) {
    score += 18;
  }
  if (content.contains(query)) {
    score += 12;
  }
  return score;
}

String _normalize(String value) {
  return value.trim().toLowerCase();
}
