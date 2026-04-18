import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:xml/xml.dart';

class ParsedArticleDraft {
  const ParsedArticleDraft({
    required this.title,
    required this.url,
    required this.publishedAt,
    this.author,
    this.summary,
    this.content,
  });

  final String title;
  final String url;
  final DateTime publishedAt;
  final String? author;
  final String? summary;
  final String? content;
}

class ParsedFeedResult {
  const ParsedFeedResult({
    required this.title,
    required this.url,
    this.siteUrl,
    this.iconUrl,
    required this.articles,
  });

  final String title;
  final String url;
  final String? siteUrl;
  final String? iconUrl;
  final List<ParsedArticleDraft> articles;
}

class RssService {
  Future<ParsedFeedResult> fetchFeed(String rawUrl) async {
    final Uri uri = _normalizeUri(rawUrl);
    final http.Response response = await http.get(uri, headers: <String, String>{
      HttpHeaders.userAgentHeader: 'RssTool/0.1',
      HttpHeaders.acceptHeader: 'application/rss+xml, application/atom+xml, application/xml, text/xml;q=0.9, */*;q=0.8',
    });
    if (response.statusCode >= 400) {
      throw HttpException('拉取订阅失败，状态码 ${response.statusCode}', uri: uri);
    }
    return parseFeedXml(response.body, sourceUrl: uri.toString());
  }

  ParsedFeedResult parseFeedXml(String xmlText, {required String sourceUrl}) {
    final XmlDocument document = XmlDocument.parse(xmlText);
    final XmlElement root = document.rootElement;
    final String rootName = root.name.local.toLowerCase();
    if (rootName == 'rss') {
      return _parseRss(root, sourceUrl: sourceUrl);
    }
    if (rootName == 'feed') {
      return _parseAtom(root, sourceUrl: sourceUrl);
    }
    throw const FormatException('暂不支持该订阅格式');
  }

  ParsedFeedResult _parseRss(XmlElement root, {required String sourceUrl}) {
    final XmlElement? channel = _firstChild(root, <String>{'channel'});
    if (channel == null) {
      throw const FormatException('RSS 缺少 channel 节点');
    }

    final String title = _textOf(channel, <String>{'title'}) ?? _hostLabel(sourceUrl);
    final String? siteUrl = _textOf(channel, <String>{'link'});
    final String? iconUrl = _rssIcon(channel, sourceUrl: sourceUrl, siteUrl: siteUrl);

    final List<ParsedArticleDraft> articles = channel.children
        .whereType<XmlElement>()
        .where((XmlElement element) => element.name.local == 'item')
        .map((XmlElement item) => _rssItemToDraft(item, sourceUrl: sourceUrl))
        .whereType<ParsedArticleDraft>()
        .toList();

    return ParsedFeedResult(
      title: title,
      url: sourceUrl,
      siteUrl: siteUrl,
      iconUrl: iconUrl,
      articles: articles,
    );
  }

  ParsedFeedResult _parseAtom(XmlElement root, {required String sourceUrl}) {
    final String title = _textOf(root, <String>{'title'}) ?? _hostLabel(sourceUrl);
    final String siteUrl = _atomSiteUrl(root) ?? sourceUrl;
    final String? iconUrl = _textOf(root, <String>{'icon', 'logo'}) ?? _faviconFromUrl(siteUrl);

    final List<ParsedArticleDraft> articles = root.children
        .whereType<XmlElement>()
        .where((XmlElement element) => element.name.local == 'entry')
        .map((XmlElement entry) => _atomEntryToDraft(entry, sourceUrl: sourceUrl))
        .whereType<ParsedArticleDraft>()
        .toList();

    return ParsedFeedResult(
      title: title,
      url: sourceUrl,
      siteUrl: siteUrl,
      iconUrl: iconUrl,
      articles: articles,
    );
  }

  ParsedArticleDraft? _rssItemToDraft(XmlElement item, {required String sourceUrl}) {
    final String? link = _textOf(item, <String>{'link'}) ?? _guidLink(item);
    if (link == null || link.trim().isEmpty) {
      return null;
    }
    final String title = (_textOf(item, <String>{'title'}) ?? '未命名文章').trim();
    final String? summary = _sanitizeHtml(_textOf(item, <String>{'description'}));
    final String? content = _sanitizeHtml(_textOf(item, <String>{'encoded', 'content'}));
    final String? author = _textOf(item, <String>{'author', 'creator'});
    final DateTime publishedAt = _parseDate(
          _textOf(item, <String>{'pubDate', 'published', 'updated'}),
        ) ??
        DateTime.now();

    return ParsedArticleDraft(
      title: title.isEmpty ? '未命名文章' : title,
      url: _resolveUrl(sourceUrl, link),
      publishedAt: publishedAt,
      author: author?.trim().isEmpty ?? true ? null : author?.trim(),
      summary: summary,
      content: content,
    );
  }

  ParsedArticleDraft? _atomEntryToDraft(XmlElement entry, {required String sourceUrl}) {
    final String? link = _atomEntryUrl(entry);
    if (link == null || link.trim().isEmpty) {
      return null;
    }
    final String title = (_textOf(entry, <String>{'title'}) ?? '未命名文章').trim();
    final String? summary = _sanitizeHtml(_textOf(entry, <String>{'summary'}));
    final String? content = _sanitizeHtml(_textOf(entry, <String>{'content'}));
    final XmlElement? authorElement = _firstChild(entry, <String>{'author'});
    final String? author = authorElement == null ? null : _textOf(authorElement, <String>{'name'});
    final DateTime publishedAt = _parseDate(
          _textOf(entry, <String>{'updated', 'published'}),
        ) ??
        DateTime.now();

    return ParsedArticleDraft(
      title: title.isEmpty ? '未命名文章' : title,
      url: _resolveUrl(sourceUrl, link),
      publishedAt: publishedAt,
      author: author?.trim().isEmpty ?? true ? null : author?.trim(),
      summary: summary,
      content: content,
    );
  }

  Uri _normalizeUri(String rawUrl) {
    final String trimmed = rawUrl.trim();
    if (trimmed.isEmpty) {
      throw const FormatException('订阅地址不能为空');
    }
    final String candidate = trimmed.startsWith('http://') || trimmed.startsWith('https://')
        ? trimmed
        : 'https://$trimmed';
    final Uri? uri = Uri.tryParse(candidate);
    if (uri == null || (!uri.hasScheme || uri.host.isEmpty)) {
      throw const FormatException('请输入有效的订阅地址');
    }
    return uri;
  }

  XmlElement? _firstChild(XmlElement parent, Set<String> localNames) {
    for (final XmlNode node in parent.children) {
      if (node is XmlElement && localNames.contains(node.name.local)) {
        return node;
      }
    }
    return null;
  }

  String? _textOf(XmlElement parent, Set<String> localNames) {
    final XmlElement? match = _firstChild(parent, localNames);
    if (match == null) {
      return null;
    }
    final String text = match.innerText.trim();
    return text.isEmpty ? null : text;
  }

  String? _guidLink(XmlElement item) {
    final XmlElement? guid = _firstChild(item, <String>{'guid'});
    if (guid == null) {
      return null;
    }
    final String text = guid.innerText.trim();
    if (text.startsWith('http://') || text.startsWith('https://')) {
      return text;
    }
    return null;
  }

  String? _atomSiteUrl(XmlElement root) {
    for (final XmlNode node in root.children) {
      if (node is! XmlElement || node.name.local != 'link') {
        continue;
      }
      final String rel = node.getAttribute('rel') ?? '';
      final String? href = node.getAttribute('href');
      if (href == null || href.isEmpty) {
        continue;
      }
      if (rel.isEmpty || rel == 'alternate') {
        return href;
      }
    }
    return null;
  }

  String? _atomEntryUrl(XmlElement entry) {
    for (final XmlNode node in entry.children) {
      if (node is! XmlElement || node.name.local != 'link') {
        continue;
      }
      final String rel = node.getAttribute('rel') ?? '';
      final String? href = node.getAttribute('href');
      if (href == null || href.isEmpty) {
        continue;
      }
      if (rel.isEmpty || rel == 'alternate') {
        return href;
      }
    }
    return null;
  }

  String? _rssIcon(XmlElement channel, {required String sourceUrl, String? siteUrl}) {
    final XmlElement? image = _firstChild(channel, <String>{'image'});
    final String? directUrl = image == null ? null : _textOf(image, <String>{'url'});
    return directUrl ?? _faviconFromUrl(siteUrl ?? sourceUrl);
  }

  String? _faviconFromUrl(String? rawUrl) {
    if (rawUrl == null || rawUrl.isEmpty) {
      return null;
    }
    final Uri? uri = Uri.tryParse(rawUrl);
    if (uri == null || uri.host.isEmpty) {
      return null;
    }
    return '${uri.scheme.isEmpty ? 'https' : uri.scheme}://$uri.host/favicon.ico';
  }

  String _resolveUrl(String sourceUrl, String relativeOrAbsolute) {
    final Uri base = Uri.parse(sourceUrl);
    return base.resolve(relativeOrAbsolute).toString();
  }

  DateTime? _parseDate(String? raw) {
    if (raw == null || raw.trim().isEmpty) {
      return null;
    }
    final String value = raw.trim();
    final DateTime? iso = DateTime.tryParse(value);
    if (iso != null) {
      return iso.toLocal();
    }
    try {
      return HttpDate.parse(value).toLocal();
    } on FormatException {
      return null;
    }
  }

  String? _sanitizeHtml(String? raw) {
    if (raw == null || raw.trim().isEmpty) {
      return null;
    }
    final String withoutTags = raw
        .replaceAll(RegExp(r'<script[\s\S]*?</script>', caseSensitive: false), ' ')
        .replaceAll(RegExp(r'<style[\s\S]*?</style>', caseSensitive: false), ' ')
        .replaceAll(RegExp(r'<[^>]+>'), ' ')
        .replaceAll('&nbsp;', ' ')
        .replaceAll('&amp;', '&')
        .replaceAll('&lt;', '<')
        .replaceAll('&gt;', '>')
        .replaceAll('&quot;', '"')
        .replaceAll('&#39;', "'")
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
    return withoutTags.isEmpty ? null : withoutTags;
  }

  String _hostLabel(String sourceUrl) {
    final Uri? uri = Uri.tryParse(sourceUrl);
    if (uri == null || uri.host.isEmpty) {
      return '未命名订阅';
    }
    return uri.host;
  }

  String stableArticleId(String sourceId, ParsedArticleDraft article) {
    final String rawKey = '$sourceId::${article.url}::${article.title}';
    return '${sourceId}_${_hash(rawKey)}';
  }

  int _hash(String input) {
    int hash = 2166136261;
    for (final int unit in input.codeUnits) {
      hash ^= unit;
      hash = (hash * 16777619) & 0x7fffffff;
    }
    return hash;
  }
}
