class FeedSource {
  const FeedSource({
    required this.id,
    required this.title,
    required this.url,
    this.siteUrl,
    this.iconUrl,
    this.folderId,
    required this.enabled,
    this.lastFetchedAt,
  });

  final String id;
  final String title;
  final String url;
  final String? siteUrl;
  final String? iconUrl;
  final String? folderId;
  final bool enabled;
  final DateTime? lastFetchedAt;

  FeedSource copyWith({
    String? id,
    String? title,
    String? url,
    String? siteUrl,
    String? iconUrl,
    String? folderId,
    bool? enabled,
    DateTime? lastFetchedAt,
    bool clearSiteUrl = false,
    bool clearIconUrl = false,
    bool clearFolderId = false,
  }) {
    return FeedSource(
      id: id ?? this.id,
      title: title ?? this.title,
      url: url ?? this.url,
      siteUrl: clearSiteUrl ? null : (siteUrl ?? this.siteUrl),
      iconUrl: clearIconUrl ? null : (iconUrl ?? this.iconUrl),
      folderId: clearFolderId ? null : (folderId ?? this.folderId),
      enabled: enabled ?? this.enabled,
      lastFetchedAt: lastFetchedAt ?? this.lastFetchedAt,
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'id': id,
      'title': title,
      'url': url,
      'siteUrl': siteUrl,
      'iconUrl': iconUrl,
      'folderId': folderId,
      'enabled': enabled,
      'lastFetchedAt': lastFetchedAt?.toIso8601String(),
    };
  }

  factory FeedSource.fromJson(Map<String, dynamic> json) {
    return FeedSource(
      id: json['id'] as String,
      title: json['title'] as String? ?? '',
      url: json['url'] as String,
      siteUrl: json['siteUrl'] as String?,
      iconUrl: json['iconUrl'] as String?,
      folderId: json['folderId'] as String?,
      enabled: json['enabled'] as bool? ?? true,
      lastFetchedAt: _dateTimeOrNull(json['lastFetchedAt']),
    );
  }

  static DateTime? _dateTimeOrNull(dynamic raw) {
    if (raw is! String || raw.isEmpty) {
      return null;
    }
    return DateTime.tryParse(raw);
  }
}
