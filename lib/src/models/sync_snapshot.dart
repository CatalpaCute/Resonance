class SyncSnapshot {
  const SyncSnapshot({
    required this.exportedAt,
    required this.feedSources,
    required this.articleStates,
    required this.readerSettings,
  });

  final DateTime exportedAt;
  final List<Map<String, dynamic>> feedSources;
  final List<Map<String, dynamic>> articleStates;
  final Map<String, dynamic> readerSettings;

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'exportedAt': exportedAt.toIso8601String(),
      'feedSources': feedSources,
      'articleStates': articleStates,
      'readerSettings': readerSettings,
    };
  }
}
