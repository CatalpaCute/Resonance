enum AppRouteId {
  allArticles,
  sources,
  sourceDetail,
  bookmarks,
  discoverAddSource,
  settings,
  readerDetail,
}

extension AppRouteIdX on AppRouteId {
  String get storageValue {
    switch (this) {
      case AppRouteId.allArticles:
        return 'all_articles';
      case AppRouteId.sources:
        return 'sources';
      case AppRouteId.sourceDetail:
        return 'source_detail';
      case AppRouteId.bookmarks:
        return 'bookmarks';
      case AppRouteId.discoverAddSource:
        return 'discover_add_source';
      case AppRouteId.settings:
        return 'settings';
      case AppRouteId.readerDetail:
        return 'reader_detail';
    }
  }

  String get label {
    switch (this) {
      case AppRouteId.allArticles:
        return '全部文章';
      case AppRouteId.sources:
        return '订阅源';
      case AppRouteId.sourceDetail:
        return '来源文章';
      case AppRouteId.bookmarks:
        return '收藏与稍后读';
      case AppRouteId.discoverAddSource:
        return '添加订阅';
      case AppRouteId.settings:
        return '设置';
      case AppRouteId.readerDetail:
        return '阅读详情';
    }
  }
}
