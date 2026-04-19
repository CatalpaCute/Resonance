enum ArticleReadState {
  unread,
  read,
}

enum BookmarkFilter {
  starred,
  savedForLater,
}

class Article {
  const Article({
    required this.id,
    required this.sourceId,
    required this.title,
    this.author,
    required this.publishedAt,
    this.summary,
    this.summaryHtml,
    this.content,
    this.contentHtml,
    required this.url,
    required this.readState,
    required this.starred,
    required this.savedForLater,
  });

  final String id;
  final String sourceId;
  final String title;
  final String? author;
  final DateTime publishedAt;
  final String? summary;
  final String? summaryHtml;
  final String? content;
  final String? contentHtml;
  final String url;
  final ArticleReadState readState;
  final bool starred;
  final bool savedForLater;

  bool get isRead => readState == ArticleReadState.read;

  String get readerText {
    final String text = (content?.trim().isNotEmpty ?? false)
        ? content!.trim()
        : (summary?.trim() ?? '');
    return text;
  }

  String get readerHtml {
    final String html = (contentHtml?.trim().isNotEmpty ?? false)
        ? contentHtml!.trim()
        : (summaryHtml?.trim() ?? '');
    return html;
  }

  Article copyWith({
    String? id,
    String? sourceId,
    String? title,
    String? author,
    DateTime? publishedAt,
    String? summary,
    String? summaryHtml,
    String? content,
    String? contentHtml,
    String? url,
    ArticleReadState? readState,
    bool? starred,
    bool? savedForLater,
    bool clearAuthor = false,
    bool clearSummary = false,
    bool clearSummaryHtml = false,
    bool clearContent = false,
    bool clearContentHtml = false,
  }) {
    return Article(
      id: id ?? this.id,
      sourceId: sourceId ?? this.sourceId,
      title: title ?? this.title,
      author: clearAuthor ? null : (author ?? this.author),
      publishedAt: publishedAt ?? this.publishedAt,
      summary: clearSummary ? null : (summary ?? this.summary),
      summaryHtml: clearSummaryHtml ? null : (summaryHtml ?? this.summaryHtml),
      content: clearContent ? null : (content ?? this.content),
      contentHtml: clearContentHtml ? null : (contentHtml ?? this.contentHtml),
      url: url ?? this.url,
      readState: readState ?? this.readState,
      starred: starred ?? this.starred,
      savedForLater: savedForLater ?? this.savedForLater,
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'id': id,
      'sourceId': sourceId,
      'title': title,
      'author': author,
      'publishedAt': publishedAt.toIso8601String(),
      'summary': summary,
      'summaryHtml': summaryHtml,
      'content': content,
      'contentHtml': contentHtml,
      'url': url,
      'readState': readState.name,
      'starred': starred,
      'savedForLater': savedForLater,
    };
  }

  factory Article.fromJson(Map<String, dynamic> json) {
    return Article(
      id: json['id'] as String,
      sourceId: json['sourceId'] as String,
      title: json['title'] as String? ?? '未命名文章',
      author: json['author'] as String?,
      publishedAt: DateTime.tryParse(json['publishedAt'] as String? ?? '') ??
          DateTime.now(),
      summary: json['summary'] as String?,
      summaryHtml: json['summaryHtml'] as String? ??
          _legacyHtmlFromText(json['summary'] as String?),
      content: json['content'] as String?,
      contentHtml: json['contentHtml'] as String? ??
          _legacyHtmlFromText(json['content'] as String?),
      url: json['url'] as String? ?? '',
      readState: ArticleReadState.values.firstWhere(
        (ArticleReadState state) => state.name == json['readState'],
        orElse: () => ArticleReadState.unread,
      ),
      starred: json['starred'] as bool? ?? false,
      savedForLater: json['savedForLater'] as bool? ?? false,
    );
  }

  static String? _legacyHtmlFromText(String? text) {
    if (text == null || text.trim().isEmpty) {
      return null;
    }
    final List<String> paragraphs = text
        .trim()
        .split(RegExp(r'\n{2,}'))
        .map((String item) => item.trim())
        .where((String item) => item.isNotEmpty)
        .toList();
    if (paragraphs.isEmpty) {
      return null;
    }
    return paragraphs
        .map(
          (String item) => '<p>${_escapeHtml(item).replaceAll('\n', '<br />')}</p>',
        )
        .join();
  }

  static String _escapeHtml(String value) {
    return value
        .replaceAll('&', '&amp;')
        .replaceAll('<', '&lt;')
        .replaceAll('>', '&gt;')
        .replaceAll('"', '&quot;')
        .replaceAll("'", '&#39;');
  }
}
