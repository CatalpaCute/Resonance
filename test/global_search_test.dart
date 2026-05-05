import 'package:flutter_test/flutter_test.dart';
import 'package:rsstool/src/models/article.dart';
import 'package:rsstool/src/models/feed_source.dart';
import 'package:rsstool/src/utils/global_search.dart';

void main() {
  group('searchGlobalContent', () {
    test('returns idle result for empty query', () {
      final GlobalSearchResultSet result = searchGlobalContent(
        feeds: <FeedSource>[_source(id: 'it', title: 'IT Home')],
        articles: <Article>[_article(id: 'a1', sourceId: 'it')],
        query: '   ',
        sourceTitleForArticle: (_) => 'IT Home',
      );

      expect(result.isIdle, isTrue);
      expect(result.sourceResult, isNull);
      expect(result.articleResults, isEmpty);
    });

    test('returns matched source and recent articles from that source', () {
      final List<FeedSource> feeds = <FeedSource>[
        _source(id: 'it', title: 'IT Home - News'),
        _source(id: 'design', title: 'Design Daily'),
      ];
      final Article newer = _article(
        id: 'newer',
        sourceId: 'it',
        title: 'Recent article',
        publishedAt: DateTime.utc(2026, 5, 1, 17),
      );
      final Article older = _article(
        id: 'older',
        sourceId: 'it',
        title: 'Older article',
        publishedAt: DateTime.utc(2026, 5, 1, 16),
      );
      final Article unrelated = _article(
        id: 'other',
        sourceId: 'design',
        title: 'Unrelated article',
      );

      final GlobalSearchResultSet result = searchGlobalContent(
        feeds: feeds,
        articles: <Article>[older, unrelated, newer],
        query: 'IT Home',
        sourceTitleForArticle: _sourceTitleFor(feeds),
      );

      expect(result.sourceResult?.source.id, 'it');
      expect(result.sourceResults.map((GlobalSearchSourceResult item) {
        return item.source.id;
      }), <String>['it']);
      expect(
        result.articleResults.map((GlobalSearchArticleResult item) {
          return item.article.id;
        }),
        <String>['newer', 'older'],
      );
    });

    test('returns multiple matched sources ordered by score and limit', () {
      final List<FeedSource> feeds = <FeedSource>[
        _source(id: 'partial_a', title: 'Tech Alpha'),
        _source(id: 'exact', title: 'Tech'),
        _source(id: 'partial_b', title: 'Daily Tech'),
        _source(id: 'url', title: 'General News'),
      ];

      final GlobalSearchResultSet result = searchGlobalContent(
        feeds: feeds,
        articles: <Article>[],
        query: 'tech',
        sourceTitleForArticle: _sourceTitleFor(feeds),
        sourceLimit: 2,
      );

      expect(
        result.sourceResults.map((GlobalSearchSourceResult item) {
          return item.source.id;
        }),
        <String>['exact', 'partial_b'],
      );
    });

    test('matches article title and body text', () {
      final List<FeedSource> feeds = <FeedSource>[
        _source(id: 'tech', title: 'Tech Source'),
      ];
      final Article titleHit = _article(
        id: 'title',
        sourceId: 'tech',
        title: 'Messaging app publishes rumor report',
      );
      final Article bodyHit = _article(
        id: 'body',
        sourceId: 'tech',
        title: 'Another article',
        content: 'The body mentions global sales and delivery data.',
      );

      final GlobalSearchResultSet titleResult = searchGlobalContent(
        feeds: feeds,
        articles: <Article>[titleHit, bodyHit],
        query: 'rumor report',
        sourceTitleForArticle: _sourceTitleFor(feeds),
      );
      final GlobalSearchResultSet bodyResult = searchGlobalContent(
        feeds: feeds,
        articles: <Article>[titleHit, bodyHit],
        query: 'global sales',
        sourceTitleForArticle: _sourceTitleFor(feeds),
      );

      expect(titleResult.articleResults.single.article.id, 'title');
      expect(bodyResult.articleResults.single.article.id, 'body');
    });

    test('deduplicates article matched by source and content', () {
      final List<FeedSource> feeds = <FeedSource>[
        _source(id: 'it', title: 'IT Home'),
      ];
      final Article article = _article(
        id: 'same',
        sourceId: 'it',
        title: 'Milestone report',
        content: 'IT Home covered the vehicle sales result.',
      );

      final GlobalSearchResultSet result = searchGlobalContent(
        feeds: feeds,
        articles: <Article>[article],
        query: 'IT Home',
        sourceTitleForArticle: _sourceTitleFor(feeds),
      );

      expect(result.sourceResult?.source.id, 'it');
      expect(result.articleResults, hasLength(1));
      expect(result.articleResults.single.article.id, 'same');
    });
  });
}

FeedSource _source({
  required String id,
  required String title,
}) {
  return FeedSource(
    id: id,
    title: title,
    url: 'https://example.com/$id.xml',
    siteUrl: 'https://example.com/$id',
    enabled: true,
    autoRefreshEnabled: false,
    notificationEnabled: false,
    autoRefreshIntervalMinutes: 1440,
  );
}

Article _article({
  required String id,
  required String sourceId,
  String title = 'Default article',
  String? content,
  DateTime? publishedAt,
}) {
  return Article(
    id: id,
    sourceId: sourceId,
    title: title,
    publishedAt: publishedAt ?? DateTime.utc(2026, 5, 1),
    summary: 'Summary',
    content: content,
    url: 'https://example.com/articles/$id',
    readState: ArticleReadState.unread,
    starred: false,
    savedForLater: false,
  );
}

String Function(Article article) _sourceTitleFor(List<FeedSource> feeds) {
  final Map<String, String> titles = <String, String>{
    for (final FeedSource feed in feeds) feed.id: feed.title,
  };
  return (Article article) => titles[article.sourceId] ?? 'Unknown source';
}
