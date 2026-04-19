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
    await file.writeAsString(_prettyJson(payload), flush: true);
  }

  Future<void> saveArticles(List<Article> articles) async {
    final Directory root = await _ensureRoot();
    final File file = File(_path(root, _articlesFileName));
    final List<Map<String, dynamic>> payload =
        articles.map((Article item) => item.toJson()).toList();
    await file.writeAsString(_prettyJson(payload), flush: true);
  }

  Future<void> saveSettings(ReaderSettings settings) async {
    final Directory root = await _ensureRoot();
    final File file = File(_path(root, _settingsFileName));
    await file.writeAsString(_prettyJson(settings.toJson()), flush: true);
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

  String _prettyJson(Object value) {
    return const JsonEncoder.withIndent('  ').convert(value);
  }
}
