import 'dart:convert';
import 'dart:io';

import 'package:path_provider/path_provider.dart';

import '../models/article.dart';
import '../models/feed_source.dart';
import '../models/reader_settings.dart';

class PersistedReaderState {
  const PersistedReaderState({
    required this.feeds,
    required this.articles,
    required this.settings,
  });

  final List<FeedSource> feeds;
  final List<Article> articles;
  final ReaderSettings settings;
}

class JsonStore {
  static const String _appFolderName = 'rsstool';
  static const String _feedsFileName = 'feeds.json';
  static const String _articlesFileName = 'articles.json';
  static const String _settingsFileName = 'reader_settings.json';

  Future<PersistedReaderState> load() async {
    final Directory root = await _ensureRoot();
    final List<FeedSource> feeds = await _readListFile<FeedSource>(
      File(_path(root, _feedsFileName)),
      (Map<String, dynamic> json) => FeedSource.fromJson(json),
    );
    final List<Article> articles = await _readListFile<Article>(
      File(_path(root, _articlesFileName)),
      (Map<String, dynamic> json) => Article.fromJson(json),
    );
    final ReaderSettings settings =
        await _readSettings(File(_path(root, _settingsFileName)));
    return PersistedReaderState(
      feeds: feeds,
      articles: articles,
      settings: settings,
    );
  }

  Future<void> saveFeeds(List<FeedSource> feeds) async {
    final Directory root = await _ensureRoot();
    final File file = File(_path(root, _feedsFileName));
    final List<Map<String, dynamic>> payload =
        feeds.map((FeedSource item) => item.toJson()).toList();
    await _writeAtomically(file, _prettyJson(payload));
  }

  Future<void> saveArticles(List<Article> articles) async {
    final Directory root = await _ensureRoot();
    final File file = File(_path(root, _articlesFileName));
    final List<Map<String, dynamic>> payload =
        articles.map((Article item) => item.toJson()).toList();
    await _writeAtomically(file, _prettyJson(payload));
  }

  Future<void> saveSettings(ReaderSettings settings) async {
    final Directory root = await _ensureRoot();
    final File file = File(_path(root, _settingsFileName));
    await _writeAtomically(file, _prettyJson(settings.toJson()));
  }

  Future<Directory> _ensureRoot() async {
    final Directory documentsDir = await getApplicationDocumentsDirectory();
    final Directory appRoot = Directory(_path(documentsDir, _appFolderName));
    if (!appRoot.existsSync()) {
      await appRoot.create(recursive: true);
    }
    return appRoot;
  }

  Future<List<T>> _readListFile<T>(
    File file,
    T Function(Map<String, dynamic> json) factory,
  ) async {
    if (!await file.exists()) {
      return <T>[];
    }
    final String content = await file.readAsString();
    if (content.trim().isEmpty) {
      return <T>[];
    }
    final Object? raw = jsonDecode(content);
    if (raw is! List<dynamic>) {
      return <T>[];
    }
    return raw.whereType<Map<String, dynamic>>().map(factory).toList();
  }

  Future<ReaderSettings> _readSettings(File file) async {
    if (!await file.exists()) {
      return ReaderSettings.defaults;
    }
    final String content = await file.readAsString();
    if (content.trim().isEmpty) {
      return ReaderSettings.defaults;
    }
    final Object? raw = jsonDecode(content);
    if (raw is! Map<String, dynamic>) {
      return ReaderSettings.defaults;
    }
    return ReaderSettings.fromJson(raw);
  }

  String _path(Directory directory, String name) {
    return '${directory.path}${Platform.pathSeparator}$name';
  }

  Future<void> _writeAtomically(File file, String content) async {
    // 设计意图：
    // Android 后台 Worker 和前台恢复流程会共享同一套 JSON 存储。
    // 直接覆盖正式文件时，前台有机会读到半截内容，进而在恢复阶段卡住。
    // 这里统一改成“先写临时文件，再原子替换正式文件”，把半写状态隔离掉。
    final File tempFile = File('${file.path}.tmp');
    await tempFile.writeAsString(content, flush: true);

    if (await file.exists()) {
      await file.delete();
    }
    await tempFile.rename(file.path);
  }

  String _prettyJson(Object value) {
    return const JsonEncoder.withIndent('  ').convert(value);
  }
}
