class ReaderProgressEstimate {
  const ReaderProgressEstimate({
    required this.currentCharacters,
    required this.totalCharacters,
    required this.percent,
    required this.ratio,
  });

  final int currentCharacters;
  final int totalCharacters;
  final int percent;
  final double ratio;

  @override
  bool operator ==(Object other) {
    return other is ReaderProgressEstimate &&
        other.currentCharacters == currentCharacters &&
        other.totalCharacters == totalCharacters &&
        other.percent == percent &&
        other.ratio == ratio;
  }

  @override
  int get hashCode => Object.hash(
        currentCharacters,
        totalCharacters,
        percent,
        ratio,
      );
}

/// Design intent:
/// Reader progress should be stable and explainable rather than exact per word.
/// The desktop reader maps scroll ratio to readable characters, and treats
/// non-scrollable short articles as fully visible.
ReaderProgressEstimate estimateReaderProgress({
  required int totalCharacters,
  required double scrollOffset,
  required double maxScrollExtent,
}) {
  final int safeTotal = totalCharacters < 0 ? 0 : totalCharacters;
  if (safeTotal == 0) {
    return const ReaderProgressEstimate(
      currentCharacters: 0,
      totalCharacters: 0,
      percent: 0,
      ratio: 0,
    );
  }

  final double safeOffset = scrollOffset.isFinite ? scrollOffset : 0;
  final double safeMaxExtent =
      maxScrollExtent.isFinite ? maxScrollExtent : 0;
  final double ratio = safeMaxExtent <= 0
      ? 1.0
      : (safeOffset / safeMaxExtent).clamp(0.0, 1.0).toDouble();
  final int current =
      (safeTotal * ratio).round().clamp(0, safeTotal).toInt();

  return ReaderProgressEstimate(
    currentCharacters: current,
    totalCharacters: safeTotal,
    percent: (ratio * 100).round().clamp(0, 100).toInt(),
    ratio: ratio,
  );
}
