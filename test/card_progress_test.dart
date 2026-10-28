import 'package:flutter_test/flutter_test.dart';
import 'package:rhythm_method_flashcards/domain/scheduler.dart';
import 'package:rhythm_method_flashcards/features/library/card_progress.dart';

void main() {
  final now = DateTime.utc(2026, 6, 1, 12);
  final parameters = SchedulerParameters.defaults();

  FlashCard card({
    required bool learning,
    DateTime? lastReview,
    required int intervalSeconds,
  }) {
    return FlashCard(
      id: 'c',
      topicId: 'topic',
      front: 'front',
      back: 'back',
      learning: learning,
      lastReview: lastReview,
      intervalSeconds: intervalSeconds,
      difficulty: 1,
      createdAt: DateTime.utc(2026, 1, 1),
    );
  }

  test('formats minutes, hours, and days', () {
    expect(formatStudyInterval(const Duration(minutes: 34)), '34m');
    expect(formatStudyInterval(const Duration(hours: 1)), '1h');
    expect(formatStudyInterval(const Duration(minutes: 90)), '2h');
    expect(formatStudyInterval(const Duration(hours: 6)), '6h');
    expect(formatStudyInterval(const Duration(days: 4)), '4d');
  });

  test('labels new, learning, lapsed, learned, and due', () {
    expect(
      cardProgressLabel(
        card: card(learning: false, intervalSeconds: 600),
        parameters: parameters,
        now: now,
      ),
      'New',
    );
    expect(
      cardProgressLabel(
        card: card(learning: true, lastReview: now, intervalSeconds: 34 * 60),
        parameters: parameters,
        now: now,
      ),
      'Learning · 34m / 1h',
    );
    expect(
      cardProgressLabel(
        card: card(learning: true, lastReview: now, intervalSeconds: 2 * 3600),
        parameters: parameters,
        now: now,
      ),
      'Learning · 2h',
    );
    expect(
      cardProgressLabel(
        card: card(learning: false, lastReview: now, intervalSeconds: 6 * 3600),
        parameters: parameters,
        now: now,
      ),
      'Learned · 6h',
    );
    expect(
      cardProgressLabel(
        card: card(
          learning: false,
          lastReview: now.subtract(const Duration(hours: 7)),
          intervalSeconds: 6 * 3600,
        ),
        parameters: parameters,
        now: now,
      ),
      'Learned · 6h · Due',
    );
  });
}
