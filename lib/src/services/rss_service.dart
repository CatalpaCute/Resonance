import 'dart:convert';
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
    this.summaryHtml,
    this.content,
    this.contentHtml,
  });

  final String title;
  final String url;
  final DateTime publishedAt;
  final String? author;
  final String? summary;
  final String? summaryHtml;
  final String? content;
  final String? contentHtml;
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

class _FetchedResponse {
  const _FetchedResponse({
    required this.statusCode,
    required this.headers,
    required this.bodyBytes,
  });

  final int statusCode;
  final Map<String, String> headers;
  final List<int> bodyBytes;
}

class RssService {
  Future<ParsedFeedResult> fetchFeed(String rawUrl) async {
    final Uri uri = _normalizeUri(rawUrl);
    final _FetchedResponse response = await _fetchResponse(uri);
    if (response.statusCode >= 400) {
      throw HttpException('拉取订阅失败，状态码 ${response.statusCode}', uri: uri);
    }
    return parseFeedBytes(
      response.bodyBytes,
      sourceUrl: uri.toString(),
      contentTypeHeader: response.headers[HttpHeaders.contentTypeHeader],
    );
  }

  Future<_FetchedResponse> _fetchResponse(
    Uri uri, {
    int redirectCount = 0,
  }) async {
    if (redirectCount > 5) {
      throw HttpException('订阅请求重定向次数过多', uri: uri);
    }

    final Map<String, String> headers = <String, String>{
      HttpHeaders.userAgentHeader: 'Resonance/0.3',
      HttpHeaders.acceptHeader:
          'application/rss+xml, application/atom+xml, application/xml, text/xml;q=0.9, */*;q=0.8',
      HttpHeaders.acceptEncodingHeader: 'identity',
    };

    try {
      final http.Response response = await http.get(uri, headers: headers);
      return _followRedirectIfNeeded(
        _FetchedResponse(
          statusCode: response.statusCode,
          headers: response.headers,
          bodyBytes: response.bodyBytes,
        ),
        uri,
        redirectCount,
      );
    } catch (error) {
      if (!_shouldRetryWithLooseHttp(error)) {
        rethrow;
      }
      final _FetchedResponse response = await _fetchResponseViaRawSocket(
        uri,
        headers: headers,
      );
      return _followRedirectIfNeeded(response, uri, redirectCount);
    }
  }

  Future<_FetchedResponse> _followRedirectIfNeeded(
    _FetchedResponse response,
    Uri uri,
    int redirectCount,
  ) async {
    if (response.statusCode < 300 || response.statusCode >= 400) {
      return response;
    }
    final String? location = response.headers['location'];
    if (location == null || location.trim().isEmpty) {
      return response;
    }
    return _fetchResponse(
      uri.resolve(location.trim()),
      redirectCount: redirectCount + 1,
    );
  }

  bool _shouldRetryWithLooseHttp(Object error) {
    final String message = error.toString().toLowerCase();
    return message.contains('invalid http date') ||
        message.contains('invalid header') ||
        message.contains('http parser');
  }

  Future<_FetchedResponse> _fetchResponseViaRawSocket(
    Uri uri, {
    required Map<String, String> headers,
  }) async {
    final String host = uri.host;
    final int port = uri.hasPort
        ? uri.port
        : (uri.scheme == 'https' ? 443 : 80);
    final String path = uri.path.isEmpty ? '/' : uri.path;
    final String requestTarget =
        uri.hasQuery ? '$path?${uri.query}' : path;

    final Socket socket = uri.scheme == 'https'
        ? await SecureSocket.connect(
            host,
            port,
            timeout: const Duration(seconds: 15),
          )
        : await Socket.connect(
            host,
            port,
            timeout: const Duration(seconds: 15),
          );

    try {
      final StringBuffer request = StringBuffer()
        ..write('GET $requestTarget HTTP/1.1\r\n')
        ..write('Host: $host\r\n')
        ..write('Connection: close\r\n');
      headers.forEach((String key, String value) {
        request.write('$key: $value\r\n');
      });
      request.write('\r\n');

      socket.add(ascii.encode(request.toString()));
      await socket.flush();

      final List<int> bytes = await _collectSocketBytes(socket);
      return _parseRawHttpResponse(bytes);
    } finally {
      await socket.close();
    }
  }

  Future<List<int>> _collectSocketBytes(Socket socket) async {
    final List<int> bytes = <int>[];
    await for (final List<int> chunk in socket) {
      bytes.addAll(chunk);
    }
    return bytes;
  }

  _FetchedResponse _parseRawHttpResponse(List<int> bytes) {
    final int headerEnd = _indexOfSublist(bytes, const <int>[13, 10, 13, 10]);
    if (headerEnd == -1) {
      throw const FormatException('未找到 HTTP 响应头');
    }

    final String headerText = latin1.decode(bytes.sublist(0, headerEnd));
    final List<String> lines = headerText.split('\r\n');
    if (lines.isEmpty) {
      throw const FormatException('HTTP 响应头为空');
    }

    final List<String> statusParts = lines.first.split(' ');
    if (statusParts.length < 2) {
      throw FormatException('无法解析 HTTP 状态行: ${lines.first}');
    }
    final int statusCode = int.tryParse(statusParts[1]) ?? 0;

    final Map<String, String> headers = <String, String>{};
    for (final String line in lines.skip(1)) {
      final int separator = line.indexOf(':');
      if (separator <= 0) {
        continue;
      }
      final String key = line.substring(0, separator).trim().toLowerCase();
      final String value = line.substring(separator + 1).trim();
      headers[key] = value;
    }

    List<int> body = bytes.sublist(headerEnd + 4);
    final String transferEncoding =
        headers[HttpHeaders.transferEncodingHeader]?.toLowerCase() ?? '';
    if (transferEncoding.contains('chunked')) {
      body = _decodeChunkedBody(body);
    } else {
      final int? contentLength = int.tryParse(
        headers[HttpHeaders.contentLengthHeader] ?? '',
      );
      if (contentLength != null &&
          contentLength >= 0 &&
          body.length > contentLength) {
        body = body.sublist(0, contentLength);
      }
    }

    return _FetchedResponse(
      statusCode: statusCode,
      headers: headers,
      bodyBytes: body,
    );
  }

  List<int> _decodeChunkedBody(List<int> body) {
    final List<int> decoded = <int>[];
    int index = 0;

    while (index < body.length) {
      final int lineEnd =
          _indexOfSublist(body, const <int>[13, 10], start: index);
      if (lineEnd == -1) {
        break;
      }
      final String lengthLine =
          ascii.decode(body.sublist(index, lineEnd)).split(';').first.trim();
      final int chunkLength = int.tryParse(lengthLine, radix: 16) ?? 0;
      index = lineEnd + 2;
      if (chunkLength == 0) {
        break;
      }
      final int nextIndex = index + chunkLength;
      if (nextIndex > body.length) {
        throw const FormatException('Chunked HTTP body 不完整');
      }
      decoded.addAll(body.sublist(index, nextIndex));
      index = nextIndex + 2;
    }

    return decoded;
  }

  int _indexOfSublist(
    List<int> source,
    List<int> pattern, {
    int start = 0,
  }) {
    if (pattern.isEmpty || source.length < pattern.length) {
      return -1;
    }
    for (int i = start; i <= source.length - pattern.length; i += 1) {
      bool matched = true;
      for (int j = 0; j < pattern.length; j += 1) {
        if (source[i + j] != pattern[j]) {
          matched = false;
          break;
        }
      }
      if (matched) {
        return i;
      }
    }
    return -1;
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

  ParsedFeedResult parseFeedBytes(
    List<int> bytes, {
    required String sourceUrl,
    String? contentTypeHeader,
  }) {
    final String xmlText =
        _decodeFeedPayload(bytes, contentTypeHeader: contentTypeHeader);
    return parseFeedXml(xmlText, sourceUrl: sourceUrl);
  }

  ParsedFeedResult _parseRss(XmlElement root, {required String sourceUrl}) {
    final XmlElement? channel = _firstChild(root, <String>{'channel'});
    if (channel == null) {
      throw const FormatException('RSS 缺少 channel 节点');
    }

    final String title =
        _textOf(channel, <String>{'title'}) ?? _hostLabel(sourceUrl);
    final String? siteUrl = _textOf(channel, <String>{'link'});
    final String? iconUrl =
        _rssIcon(channel, sourceUrl: sourceUrl, siteUrl: siteUrl);

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
    final String title =
        _textOf(root, <String>{'title'}) ?? _hostLabel(sourceUrl);
    final String siteUrl = _atomSiteUrl(root) ?? sourceUrl;
    final String? iconUrl =
        _textOf(root, <String>{'icon', 'logo'}) ?? _faviconFromUrl(siteUrl);

    final List<ParsedArticleDraft> articles = root.children
        .whereType<XmlElement>()
        .where((XmlElement element) => element.name.local == 'entry')
        .map((XmlElement entry) =>
            _atomEntryToDraft(entry, sourceUrl: sourceUrl))
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

  ParsedArticleDraft? _rssItemToDraft(
    XmlElement item, {
    required String sourceUrl,
  }) {
    final String? link = _textOf(item, <String>{'link'}) ?? _guidLink(item);
    if (link == null || link.trim().isEmpty) {
      return null;
    }

    final String resolvedUrl = _resolveUrl(sourceUrl, link);
    final String title = (_textOf(item, <String>{'title'}) ?? '未命名文章').trim();
    final String? summaryHtml = _sanitizeHtmlFragment(
      _textOf(item, <String>{'description'}),
      baseUrl: resolvedUrl,
    );
    final String? contentHtml = _sanitizeHtmlFragment(
      _textOf(item, <String>{'encoded', 'content'}),
      baseUrl: resolvedUrl,
    );
    final String? summary = _extractReadableText(summaryHtml);
    final String? content = _extractReadableText(contentHtml);
    final String? author = _textOf(item, <String>{'author', 'creator'});
    final DateTime publishedAt = _parseDate(
          _textOf(item, <String>{'pubDate', 'published', 'updated'}),
        ) ??
        DateTime.now();

    return ParsedArticleDraft(
      title: title.isEmpty ? '未命名文章' : title,
      url: resolvedUrl,
      publishedAt: publishedAt,
      author: author?.trim().isEmpty ?? true ? null : author?.trim(),
      summary: summary,
      summaryHtml: summaryHtml,
      content: content,
      contentHtml: contentHtml,
    );
  }

  ParsedArticleDraft? _atomEntryToDraft(
    XmlElement entry, {
    required String sourceUrl,
  }) {
    final String? link = _atomEntryUrl(entry);
    if (link == null || link.trim().isEmpty) {
      return null;
    }

    final String resolvedUrl = _resolveUrl(sourceUrl, link);
    final String title = (_textOf(entry, <String>{'title'}) ?? '未命名文章').trim();
    final String? summaryHtml = _sanitizeHtmlFragment(
      _textOf(entry, <String>{'summary'}),
      baseUrl: resolvedUrl,
    );
    final String? contentHtml = _sanitizeHtmlFragment(
      _textOf(entry, <String>{'content'}),
      baseUrl: resolvedUrl,
    );
    final String? summary = _extractReadableText(summaryHtml);
    final String? content = _extractReadableText(contentHtml);
    final XmlElement? authorElement = _firstChild(entry, <String>{'author'});
    final String? author =
        authorElement == null ? null : _textOf(authorElement, <String>{'name'});
    final DateTime publishedAt = _parseDate(
          _textOf(entry, <String>{'updated', 'published'}),
        ) ??
        DateTime.now();

    return ParsedArticleDraft(
      title: title.isEmpty ? '未命名文章' : title,
      url: resolvedUrl,
      publishedAt: publishedAt,
      author: author?.trim().isEmpty ?? true ? null : author?.trim(),
      summary: summary,
      summaryHtml: summaryHtml,
      content: content,
      contentHtml: contentHtml,
    );
  }

  Uri _normalizeUri(String rawUrl) {
    final String trimmed = rawUrl.trim();
    if (trimmed.isEmpty) {
      throw const FormatException('订阅地址不能为空');
    }
    final String candidate =
        trimmed.startsWith('http://') || trimmed.startsWith('https://')
            ? trimmed
            : 'https://$trimmed';
    final Uri? uri = Uri.tryParse(candidate);
    if (uri == null || (!uri.hasScheme || uri.host.isEmpty)) {
      throw const FormatException('请输入有效的订阅地址');
    }
    return uri;
  }

  // 设计意图：优先从 BOM、HTTP 头和 XML 声明恢复真实编码，
  // 避免订阅源没显式声明 charset 时被错误解码。
  String _decodeFeedPayload(List<int> bytes, {String? contentTypeHeader}) {
    if (bytes.isEmpty) {
      return '';
    }

    final String? bomEncoding = _detectBomEncoding(bytes);
    final String? headerEncoding = _charsetFromContentType(contentTypeHeader);
    final String? xmlEncoding = _xmlDeclaredEncoding(bytes);
    final List<String> candidates = <String>[
      if (bomEncoding != null) bomEncoding,
      if (headerEncoding != null && headerEncoding != bomEncoding)
        headerEncoding,
      if (xmlEncoding != null &&
          xmlEncoding != bomEncoding &&
          xmlEncoding != headerEncoding)
        xmlEncoding,
      'utf-8',
      'latin1',
    ];

    Object? lastError;
    for (final String candidate in candidates) {
      try {
        return _decodeWithEncoding(bytes, candidate);
      } catch (error) {
        lastError = error;
      }
    }

    throw FormatException(
      '无法识别订阅源编码${lastError == null ? '' : '：$lastError'}',
    );
  }

  String? _detectBomEncoding(List<int> bytes) {
    if (bytes.length >= 3 &&
        bytes[0] == 0xEF &&
        bytes[1] == 0xBB &&
        bytes[2] == 0xBF) {
      return 'utf-8';
    }
    if (bytes.length >= 2 && bytes[0] == 0xFF && bytes[1] == 0xFE) {
      return 'utf-16le';
    }
    if (bytes.length >= 2 && bytes[0] == 0xFE && bytes[1] == 0xFF) {
      return 'utf-16be';
    }
    return null;
  }

  String? _charsetFromContentType(String? contentTypeHeader) {
    if (contentTypeHeader == null || contentTypeHeader.isEmpty) {
      return null;
    }
    final RegExpMatch? match =
        RegExp(r'''charset\s*=\s*["']?([^;"'\s]+)''', caseSensitive: false)
            .firstMatch(contentTypeHeader);
    return match == null ? null : _normalizeEncodingName(match.group(1)!);
  }

  String? _xmlDeclaredEncoding(List<int> bytes) {
    final int sampleLength = bytes.length > 256 ? 256 : bytes.length;
    final String sample = latin1.decode(bytes.take(sampleLength).toList());
    final RegExpMatch? match =
        RegExp(r'''encoding\s*=\s*["']([^"']+)["']''', caseSensitive: false)
            .firstMatch(sample);
    return match == null ? null : _normalizeEncodingName(match.group(1)!);
  }

  String _decodeWithEncoding(List<int> bytes, String encodingName) {
    final String normalized = _normalizeEncodingName(encodingName);
    switch (normalized) {
      case 'utf-8':
      case 'utf8':
        return utf8.decode(bytes);
      case 'latin1':
      case 'iso-8859-1':
      case 'iso8859-1':
        return latin1.decode(bytes);
      case 'ascii':
      case 'us-ascii':
        return ascii.decode(bytes);
      case 'utf-16':
      case 'utf-16le':
        return _decodeUtf16(bytes, littleEndian: true);
      case 'utf-16be':
        return _decodeUtf16(bytes, littleEndian: false);
      default:
        throw UnsupportedError('暂不支持编码 $encodingName');
    }
  }

  String _decodeUtf16(List<int> bytes, {required bool littleEndian}) {
    int start = 0;
    if (bytes.length >= 2) {
      final bool hasLittleEndianBom = bytes[0] == 0xFF && bytes[1] == 0xFE;
      final bool hasBigEndianBom = bytes[0] == 0xFE && bytes[1] == 0xFF;
      if (hasLittleEndianBom || hasBigEndianBom) {
        start = 2;
      }
    }

    final List<int> codeUnits = <int>[];
    for (int index = start; index + 1 < bytes.length; index += 2) {
      final int codeUnit = littleEndian
          ? bytes[index] | (bytes[index + 1] << 8)
          : (bytes[index] << 8) | bytes[index + 1];
      codeUnits.add(codeUnit);
    }
    return String.fromCharCodes(codeUnits);
  }

  String _normalizeEncodingName(String raw) {
    return raw.trim().toLowerCase().replaceAll('_', '-');
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

  String? _rssIcon(
    XmlElement channel, {
    required String sourceUrl,
    String? siteUrl,
  }) {
    final XmlElement? image = _firstChild(channel, <String>{'image'});
    final String? directUrl =
        image == null ? null : _textOf(image, <String>{'url'});
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

  String? _sanitizeHtmlFragment(String? raw, {required String baseUrl}) {
    if (raw == null || raw.trim().isEmpty) {
      return null;
    }

    String html = raw.trim();
    html = html
        .replaceAll(RegExp(r'<!--[\s\S]*?-->'), '')
        .replaceAll(
          RegExp(r'<script[\s\S]*?</script>', caseSensitive: false),
          '',
        )
        .replaceAll(
          RegExp(r'<style[\s\S]*?</style>', caseSensitive: false),
          '',
        );

    // Normalize lazy media markup before further HTML rewriting so the reader
    // can handle common blog-engine patterns consistently.
    html = _normalizeLazyMediaAttributes(html);
    html = _replaceMediaEmbedWithLink(html, tagName: 'iframe');
    html = _replaceMediaEmbedWithLink(html, tagName: 'video');
    html = _resolveHtmlAssetUrls(html, baseUrl: baseUrl);
    html = html.trim();
    return html.isEmpty ? null : html;
  }

  String? _extractReadableText(String? rawHtml) {
    if (rawHtml == null || rawHtml.trim().isEmpty) {
      return null;
    }

    final String normalized = rawHtml
        .replaceAll(RegExp(r'<br\s*/?>', caseSensitive: false), '\n')
        .replaceAll(RegExp(r'</p\s*>', caseSensitive: false), '\n\n')
        .replaceAll(RegExp(r'</div\s*>', caseSensitive: false), '\n\n')
        .replaceAll(RegExp(r'</h[1-6]\s*>', caseSensitive: false), '\n\n')
        .replaceAll(RegExp(r'</blockquote\s*>', caseSensitive: false), '\n\n')
        .replaceAll(RegExp(r'</li\s*>', caseSensitive: false), '\n')
        .replaceAll(RegExp(r'<li[^>]*>', caseSensitive: false), '• ')
        .replaceAll(RegExp(r'<[^>]+>'), ' ');

    final String withoutEntities = _decodeBasicHtmlEntities(normalized)
        .replaceAll(RegExp(r'[ \t]+\n'), '\n')
        .replaceAll(RegExp(r'\n[ \t]+'), '\n')
        .replaceAll(RegExp(r'[ \t]{2,}'), ' ')
        .replaceAll(RegExp(r'\n{3,}'), '\n\n')
        .trim();

    return withoutEntities.isEmpty ? null : withoutEntities;
  }

  String _replaceMediaEmbedWithLink(String html, {required String tagName}) {
    final RegExp pair = RegExp(
      '<$tagName\\b([^>]*)>([\\s\\S]*?)</$tagName>',
      caseSensitive: false,
    );
    final RegExp selfClosing = RegExp(
      '<$tagName\\b([^>]*)/?>',
      caseSensitive: false,
    );

    String replaceMatch(Match match) {
      final String attrs = match.group(1) ?? '';
      final String innerHtml = match.groupCount >= 2 ? (match.group(2) ?? '') : '';
      final String? src = _mediaSourceUrl(
        tagName: tagName,
        attributes: attrs,
        innerHtml: innerHtml,
      );
      if (src == null || src.isEmpty) {
        return '';
      }
      final String label =
          tagName.toLowerCase() == 'video' ? '打开视频内容' : '打开内嵌内容';
      return '''
<div class="resonance-media-placeholder">
  <p><a href="$src" target="_blank" rel="noopener noreferrer">$label</a></p>
</div>
''';
    }

    return html.replaceAllMapped(pair, replaceMatch).replaceAllMapped(
          selfClosing,
          replaceMatch,
        );
  }

  String _normalizeLazyMediaAttributes(String html) {
    return html.replaceAllMapped(
      RegExp(r'<(img|source)\b([^>]*)>', caseSensitive: false),
      (Match match) {
        final String tagName = match.group(1) ?? '';
        String attributes = match.group(2) ?? '';

        final String? normalizedSrc = _firstAttributeValue(
          attributes,
          <String>[
            'data-src',
            'data-original',
            'data-lazy-src',
            'data-lazyload',
            'data-url',
            'src',
          ],
        );
        final String? normalizedSrcSet = _firstAttributeValue(
          attributes,
          <String>[
            'data-srcset',
            'data-original-srcset',
            'srcset',
          ],
        );

        if (normalizedSrc != null && normalizedSrc.isNotEmpty) {
          attributes = _upsertAttribute(attributes, 'src', normalizedSrc);
        }
        if (normalizedSrcSet != null && normalizedSrcSet.isNotEmpty) {
          attributes = _upsertAttribute(attributes, 'srcset', normalizedSrcSet);
        }

        attributes = _removeBooleanAttribute(attributes, 'lazyload');
        return '<$tagName$attributes>';
      },
    );
  }

  String? _mediaSourceUrl({
    required String tagName,
    required String attributes,
    required String innerHtml,
  }) {
    final String? directSrc = _firstAttributeValue(
      attributes,
      <String>['src', 'data-src', 'poster'],
    );
    if (directSrc != null && directSrc.isNotEmpty) {
      return directSrc;
    }

    if (tagName.toLowerCase() == 'video') {
      final RegExpMatch? nestedSource = RegExp(
        r"""<source\b[^>]*\bsrc\s*=\s*["']([^"']+)["']""",
        caseSensitive: false,
      ).firstMatch(innerHtml);
      if (nestedSource != null) {
        return nestedSource.group(1);
      }
    }

    return null;
  }

  String _resolveHtmlAssetUrls(String html, {required String baseUrl}) {
    final Uri base = Uri.parse(baseUrl);
    return html.replaceAllMapped(
      RegExp(
        r'''(src|href|poster)\s*=\s*["']([^"']+)["']''',
        caseSensitive: false,
      ),
      (Match match) {
        final String attribute = match.group(1)!;
        final String rawValue = match.group(2)!;
        if (rawValue.startsWith('data:') ||
            rawValue.startsWith('javascript:') ||
            rawValue.startsWith('mailto:') ||
            rawValue.startsWith('#')) {
          return match.group(0)!;
        }
        final String resolved = base.resolve(rawValue).toString();
        return '$attribute="$resolved"';
      },
    );
  }

  String? _attributeValue(String attributes, String name) {
    final RegExpMatch? match = RegExp(
      '$name\\s*=\\s*["\']([^"\']+)["\']',
      caseSensitive: false,
    ).firstMatch(attributes);
    return match?.group(1);
  }

  String? _firstAttributeValue(String attributes, List<String> names) {
    for (final String name in names) {
      final String? value = _attributeValue(attributes, name);
      if (value != null && value.trim().isNotEmpty) {
        return value.trim();
      }
    }
    return null;
  }

  String _upsertAttribute(String attributes, String name, String value) {
    final RegExp pattern = RegExp(
      '$name\\s*=\\s*["\'][^"\']*["\']',
      caseSensitive: false,
    );
    if (pattern.hasMatch(attributes)) {
      return attributes.replaceFirst(pattern, '$name="$value"');
    }
    return '$attributes $name="$value"';
  }

  String _removeBooleanAttribute(String attributes, String name) {
    return attributes.replaceAll(
      RegExp(
        '(?:^|\\s)${RegExp.escape(name)}(?:\\s|\$)',
        caseSensitive: false,
      ),
      ' ',
    );
  }

  String _decodeBasicHtmlEntities(String value) {
    return value
        .replaceAll('&nbsp;', ' ')
        .replaceAll('&amp;', '&')
        .replaceAll('&lt;', '<')
        .replaceAll('&gt;', '>')
        .replaceAll('&quot;', '"')
        .replaceAll('&#39;', "'")
        .replaceAll('&#x27;', "'")
        .replaceAll('&#x2F;', '/');
  }

  String _hostLabel(String sourceUrl) {
    final Uri? uri = Uri.tryParse(sourceUrl);
    if (uri == null || uri.host.isEmpty) {
      return '未命名订阅';
    }
    return uri.host;
  }

  String stableArticleId(String sourceId, ParsedArticleDraft article) {
    final String rawKey = article.url.trim().isNotEmpty
        ? '$sourceId::${article.url}'
        : '$sourceId::${article.title}::${article.publishedAt.toIso8601String()}';
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
