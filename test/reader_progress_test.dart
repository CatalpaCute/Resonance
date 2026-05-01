import 'package:flutter_test/flutter_test.dart';
import 'package:rsstool/src/utils/reader_progress.dart';

void main() {
  group('estimateReaderProgress', () {
    test('returns safe zero progress for empty content', () {
      final ReaderProgressEstimate progress = estimateReaderProgress(
        totalCharacters: 0,
        scrollOffset: 40,
        maxScrollExtent: 120,
      );

      expect(progress.currentCharacters, 0);
      expect(progress.totalCharacters, 0);
      expect(progress.percent, 0);
      expect(progress.ratio, 0);
    });

    test('treats non-scrollable short content as fully visible', () {
      final ReaderProgressEstimate progress = estimateReaderProgress(
        totalCharacters: 120,
        scrollOffset: 0,
        maxScrollExtent: 0,
      );

      expect(progress.currentCharacters, 120);
      expect(progress.percent, 100);
      expect(progress.ratio, 1);
    });

    test('estimates middle scroll position from readable characters', () {
      final ReaderProgressEstimate progress = estimateReaderProgress(
        totalCharacters: 1000,
        scrollOffset: 50,
        maxScrollExtent: 100,
      );

      expect(progress.currentCharacters, 500);
      expect(progress.totalCharacters, 1000);
      expect(progress.percent, 50);
      expect(progress.ratio, 0.5);
    });

    test('clamps progress outside the scroll range', () {
      final ReaderProgressEstimate beforeStart = estimateReaderProgress(
        totalCharacters: 1000,
        scrollOffset: -20,
        maxScrollExtent: 100,
      );
      final ReaderProgressEstimate afterEnd = estimateReaderProgress(
        totalCharacters: 1000,
        scrollOffset: 180,
        maxScrollExtent: 100,
      );

      expect(beforeStart.currentCharacters, 0);
      expect(beforeStart.percent, 0);
      expect(afterEnd.currentCharacters, 1000);
      expect(afterEnd.percent, 100);
    });

    test('handles non-finite scroll values safely', () {
      final ReaderProgressEstimate unknownOffset = estimateReaderProgress(
        totalCharacters: 1000,
        scrollOffset: double.nan,
        maxScrollExtent: 100,
      );
      final ReaderProgressEstimate unknownRange = estimateReaderProgress(
        totalCharacters: 1000,
        scrollOffset: 40,
        maxScrollExtent: double.infinity,
      );

      expect(unknownOffset.currentCharacters, 0);
      expect(unknownOffset.percent, 0);
      expect(unknownRange.currentCharacters, 1000);
      expect(unknownRange.percent, 100);
    });
  });
}
