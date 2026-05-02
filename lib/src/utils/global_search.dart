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
    required this.sourceResult,
    required this.articleResults,
  });

  final String query;
  final GlobalSearchSourceResult? sourceResult;
  final List<GlobalSearchArticleResult> articleResults;

  bool get isIdle => query.isEmpty;
  bool get isEmpty => sourceResult == null && articleResults.isEmpty;
  int get itemCount => articleResults.length + (sourceResult == null ? 0 : 1);
}

GlobalSearchResultSet searchGlobalContent({
  required List<FeedSource> feeds,
  required List<Article> articles,
  required String query,
  required String Function(Article article) sourceTitleForArticle,
  int articleLimit = 20,
}) {
  final String normalizedQuery = _normalize(query);
  if (normalizedQuery.isEmpty) {
    return const GlobalSearchResultSet(
      query: '',
      sourceResult: null,
      articleResults: <GlobalSearchArticleResult>[],
    );
  }

  GlobalSearchSourceResult? bestSource;
  for (final FeedSource source in feeds) {
    final int score = _sourceScore(source, normalizedQuery);
    if (score <= 0) {
      continue;
    }
    if (bestSource == null || score > bestSource.score) {
      bestSource = GlobalSearchSourceResult(source: source, score: score);
    }
  }

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

  if (bestSource != null) {
    for (final Article article in articles) {
      if (article.sourceId != bestSource.source.id) {
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
    sourceResult: bestSource,
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
