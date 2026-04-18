import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:rsstool/src/services/rss_service.dart';

void main() {
  group('RssService.parseFeedXml', () {
    test('parses rss feed items', () {
      const String xml = '''
      <rss version="2.0">
        <channel>
          <title>Example Feed</title>
          <link>https://example.com</link>
          <item>
            <title>First Post</title>
            <link>https://example.com/1</link>
            <description><![CDATA[<p>Hello world</p>]]></description>
            <pubDate>Wed, 02 Oct 2002 13:00:00 GMT</pubDate>
          </item>
        </channel>
      </rss>
      ''';

      final ParsedFeedResult parsed = RssService().parseFeedXml(
        xml,
        sourceUrl: 'https://example.com/feed.xml',
      );

      expect(parsed.title, 'Example Feed');
      expect(parsed.siteUrl, 'https://example.com');
      expect(parsed.articles, hasLength(1));
      expect(parsed.articles.first.title, 'First Post');
      expect(parsed.articles.first.summary, 'Hello world');
      expect(parsed.articles.first.url, 'https://example.com/1');
    });

    test('parses atom entries', () {
      const String xml = '''
      <feed xmlns="http://www.w3.org/2005/Atom">
        <title>Atom Example</title>
        <link href="https://atom.example.com" rel="alternate" />
        <entry>
          <title>Atom Entry</title>
          <link href="https://atom.example.com/entry" />
          <updated>2024-06-18T12:00:00Z</updated>
          <summary>Short summary</summary>
          <author>
            <name>Editor</name>
          </author>
        </entry>
      </feed>
      ''';

      final ParsedFeedResult parsed = RssService().parseFeedXml(
        xml,
        sourceUrl: 'https://atom.example.com/feed',
      );

      expect(parsed.title, 'Atom Example');
      expect(parsed.siteUrl, 'https://atom.example.com');
      expect(parsed.articles, hasLength(1));
      expect(parsed.articles.first.author, 'Editor');
      expect(parsed.articles.first.summary, 'Short summary');
      expect(parsed.articles.first.url, 'https://atom.example.com/entry');
    });

    test('decodes utf8 bytes when charset is omitted but xml declares encoding', () {
      const String xml = '''
      <?xml version="1.0" encoding="utf-8"?>
      <feed xmlns="http://www.w3.org/2005/Atom">
        <title>Cz`s Blog</title>
        <link href="https://me.czzzz.work" rel="alternate" />
        <entry>
          <title>中文标题</title>
          <link href="https://me.czzzz.work/post" />
          <updated>2026-03-09T19:17:00Z</updated>
          <summary>这是一段中文摘要。</summary>
        </entry>
      </feed>
      ''';

      final ParsedFeedResult parsed = RssService().parseFeedBytes(
        utf8.encode(xml),
        sourceUrl: 'https://me.czzzz.work/atom.xml',
        contentTypeHeader: 'application/xml',
      );

      expect(parsed.title, 'Cz`s Blog');
      expect(parsed.articles, hasLength(1));
      expect(parsed.articles.first.title, '中文标题');
      expect(parsed.articles.first.summary, '这是一段中文摘要。');
    });
  });
}
