import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:path_provider/path_provider.dart';

import '../models/article.dart';
import '../models/feed_source.dart';
import '../models/reader_settings.dart';
import '../models/user_profile.dart';

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
  JsonStore({
    Future<Directory> Function()? documentsDirectoryResolver,
  }) : _documentsDirectoryResolver =
            documentsDirectoryResolver ?? getApplicationDocumentsDirectory;

  static const String _appFolderName = 'rsstool';
  static const String _usersFolderName = 'users';
  static const String _feedsFileName = 'feeds.json';
  static const String _articlesFileName = 'articles.json';
  static const String _settingsFileName = 'reader_settings.json';
  static const String _currentUserFileName = 'current_user.json';
  static const String _profileFileName = 'profile.json';
  static const String _avatarFileName = 'avatar.jpg';

  final Future<Directory> Function() _documentsDirectoryResolver;

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

  Future<CurrentUserSession> loadCurrentUserSession() async {
    final Directory root = await _ensureRoot();
    final File file = File(_path(root, _currentUserFileName));
    if (!await file.exists()) {
      return const CurrentUserSession.signedOut();
    }
    final String content = await file.readAsString();
    if (content.trim().isEmpty) {
      return const CurrentUserSession.signedOut();
    }
    final Object? raw = jsonDecode(content);
    if (raw is! Map<String, dynamic>) {
      return const CurrentUserSession.signedOut();
    }
    return CurrentUserSession.fromJson(raw);
  }

  Future<void> saveCurrentUserSession(CurrentUserSession session) async {
    final Directory root = await _ensureRoot();
    final File file = File(_path(root, _currentUserFileName));
    await _writeAtomically(file, _prettyJson(session.toJson()));
  }

  Future<void> clearCurrentUserSession() async {
    final Directory root = await _ensureRoot();
    final File file = File(_path(root, _currentUserFileName));
    if (await file.exists()) {
      await file.delete();
    }
  }

  Future<UserProfile?> loadUserProfile(String identityCode) async {
    final Directory root = await _ensureRoot();
    final File file =
        File(_path(_userDirectory(root, identityCode), _profileFileName));
    if (!await file.exists()) {
      return null;
    }
    final String content = await file.readAsString();
    if (content.trim().isEmpty) {
      return null;
    }
    final Object? raw = jsonDecode(content);
    if (raw is! Map<String, dynamic>) {
      return null;
    }
    return UserProfile.fromJson(raw);
  }

  Future<void> saveUserProfile(UserProfile profile) async {
    final Directory root = await _ensureRoot();
    final Directory userDirectory = _userDirectory(root, profile.identityCode);
    if (!userDirectory.existsSync()) {
      await userDirectory.create(recursive: true);
    }
    final File file = File(_path(userDirectory, _profileFileName));
    await _writeAtomically(file, _prettyJson(profile.toJson()));
  }

  Future<String> saveUserAvatar(
    String identityCode,
    Uint8List bytes,
  ) async {
    final Directory root = await _ensureRoot();
    final Directory userDirectory = _userDirectory(root, identityCode);
    if (!userDirectory.existsSync()) {
      await userDirectory.create(recursive: true);
    }
    final File file = File(_path(userDirectory, _avatarFileName));
    await _writeBytesAtomically(file, bytes);
    return file.path;
  }

  Future<void> deleteUserAvatar(String identityCode) async {
    final Directory root = await _ensureRoot();
    final File file =
        File(_path(_userDirectory(root, identityCode), _avatarFileName));
    if (await file.exists()) {
      await file.delete();
    }
  }

  Future<int> estimateCurrentUserContentSyncBytes(String identityCode) async {
    final Directory root = await _ensureRoot();
    final File feedsFile = File(_path(root, _feedsFileName));
    final File articlesFile = File(_path(root, _articlesFileName));
    final File avatarFile =
        File(_path(_userDirectory(root, identityCode), _avatarFileName));

    return await _safeFileLength(feedsFile) +
        await _safeFileLength(articlesFile) +
        await _safeFileLength(avatarFile);
  }

  Future<Directory> _ensureRoot() async {
    final Directory documentsDir = await _documentsDirectoryResolver();
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

  Directory _userDirectory(Directory root, String identityCode) {
    return Directory(
      _path(
        Directory(_path(root, _usersFolderName)),
        identityCode,
      ),
    );
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

  Future<void> _writeBytesAtomically(File file, List<int> bytes) async {
    final File tempFile = File('${file.path}.tmp');
    await tempFile.writeAsBytes(bytes, flush: true);

    if (await file.exists()) {
      await file.delete();
    }
    await tempFile.rename(file.path);
  }

  String _prettyJson(Object value) {
    return const JsonEncoder.withIndent('  ').convert(value);
  }

  Future<int> _safeFileLength(File file) async {
    if (!await file.exists()) {
      return 0;
    }
    return file.length();
  }
}
