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
    this.content,
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
  final String? content;
  final String url;
  final ArticleReadState readState;
  final bool starred;
  final bool savedForLater;

  bool get isRead => readState == ArticleReadState.read;

  String get readerText {
    final text = (content?.trim().isNotEmpty ?? false) ? content!.trim() : (summary?.trim() ?? '');
    return text;
  }

  Article copyWith({
    String? id,
    String? sourceId,
    String? title,
    String? author,
    DateTime? publishedAt,
    String? summary,
    String? content,
    String? url,
    ArticleReadState? readState,
    bool? starred,
    bool? savedForLater,
    bool clearAuthor = false,
    bool clearSummary = false,
    bool clearContent = false,
  }) {
    return Article(
      id: id ?? this.id,
      sourceId: sourceId ?? this.sourceId,
      title: title ?? this.title,
      author: clearAuthor ? null : (author ?? this.author),
      publishedAt: publishedAt ?? this.publishedAt,
      summary: clearSummary ? null : (summary ?? this.summary),
      content: clearContent ? null : (content ?? this.content),
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
      'content': content,
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
      publishedAt: DateTime.tryParse(json['publishedAt'] as String? ?? '') ?? DateTime.now(),
      summary: json['summary'] as String?,
      content: json['content'] as String?,
      url: json['url'] as String? ?? '',
      readState: ArticleReadState.values.firstWhere(
        (ArticleReadState state) => state.name == json['readState'],
        orElse: () => ArticleReadState.unread,
      ),
      starred: json['starred'] as bool? ?? false,
      savedForLater: json['savedForLater'] as bool? ?? false,
    );
  }
}
