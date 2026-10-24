import 'package:flutter_test/flutter_test.dart';
import 'package:rhythm_method_flashcards/domain/scheduler.dart';
import 'package:rhythm_method_flashcards/features/study/study_status.dart';

void main() {
  final parameters = SchedulerParameters.defaults();
  final now = DateTime.utc(2026, 6, 1, 12);

  test('full window sentence matches the spec', () {
    expect(
      studyStatusLine(learning: 10, window: 10, newWaiting: 490, learnedDue: 3),
      'Learning 10 of 10. 490 new cards are waiting until one of these graduates. 3 learned cards are due.',
    );
  });

  test('singular waiting and due sentences', () {
    expect(
      studyStatusLine(learning: 10, window: 10, newWaiting: 1, learnedDue: 1),
      'Learning 10 of 10. 1 new card is waiting until one of these graduates. 1 learned card is due.',
    );
  });

  test('an open seat does not say new cards are waiting', () {
    expect(
      studyStatusLine(learning: 2, window: 10, newWaiting: 40, learnedDue: 0),
      'Learning 2 of 10.',
    );
    expect(
      studyStatusLine(learning: 9, window: 10, newWaiting: 5, learnedDue: 2),
      'Learning 9 of 10. 2 learned cards are due.',
    );
  });

  test(
    'counts follow the study scope and skip learned cards that are not due',
    () {
      final topics = [
        const Topic(id: 'parent', name: 'Parent'),
        const Topic(id: 'child', name: 'Child', parentId: 'parent'),
        const Topic(id: 'other', name: 'Other'),
      ];
      final cards = [
        FlashCard(
          id: 'learning',
          topicId: 'child',
          front: 'learning',
          back: 'back',
          learning: true,
          lastReview: now.subtract(const Duration(hours: 2)),
          intervalSeconds: 600,
          difficulty: 1,
          createdAt: DateTime.utc(2026, 1, 1),
        ),
        FlashCard(
          id: 'lapsed',
          topicId: 'child',
          front: 'lapsed',
          back: 'back',
          learning: true,
          lastReview: now.subtract(const Duration(days: 2)),
          intervalSeconds: 7200,
          difficulty: 1.2,
          createdAt: DateTime.utc(2026, 1, 2),
        ),
        FlashCard.fresh(
          id: 'fresh',
          topicId: 'parent',
          front: 'fresh',
          back: 'back',
          createdAt: DateTime.utc(2026, 1, 3),
        ),
        FlashCard(
          id: 'due',
          topicId: 'parent',
          front: 'due',
          back: 'back',
          learning: false,
          lastReview: now.subtract(const Duration(hours: 4)),
          intervalSeconds: 7200,
          difficulty: 1,
          createdAt: DateTime.utc(2026, 1, 4),
        ),
        FlashCard(
          id: 'waiting-out',
          topicId: 'parent',
          front: 'waiting',
          back: 'back',
          learning: false,
          lastReview: now,
          intervalSeconds: 7200,
          difficulty: 1,
          createdAt: DateTime.utc(2026, 1, 5),
        ),
        FlashCard.fresh(
          id: 'elsewhere',
          topicId: 'other',
          front: 'elsewhere',
          back: 'back',
          createdAt: DateTime.utc(2026, 1, 6),
        ),
      ];

      final parent = countStudy(
        topics: topics,
        cards: cards,
        scopeTopicId: 'parent',
        now: now,
        parameters: parameters,
      );
      expect(parent.learning, 2);
      expect(parent.newWaiting, 1);
      expect(parent.learnedDue, 1);

      final library = countStudy(
        topics: topics,
        cards: cards,
        scopeTopicId: null,
        now: now,
        parameters: parameters,
      );
      expect(library.learning, 2);
      expect(library.newWaiting, 2);
      expect(library.learnedDue, 1);
    },
  );

  test('a waiting reverse counts as new, and two faces can both count', () {
    final topics = [
      const Topic(id: 'on', name: 'On', reverseDrill: true),
      const Topic(id: 'off', name: 'Off'),
    ];
    final reversed = spawnReverseFace(
      FlashCard(
        id: 'both',
        topicId: 'on',
        front: 'front',
        back: 'back',
        learning: true,
        lastReview: now,
        intervalSeconds: 600,
        difficulty: 1,
        createdAt: DateTime.utc(2026, 1, 1),
      ),
      queuedAt: now,
    );
    final hidden = spawnReverseFace(
      FlashCard.fresh(
        id: 'hidden',
        topicId: 'off',
        front: 'front',
        back: 'back',
        createdAt: DateTime.utc(2026, 1, 2),
      ),
      queuedAt: now,
    ).copyWith(reverseLearning: true, reverseLastReview: now);

    final counts = countStudy(
      topics: topics,
      cards: [reversed, hidden],
      scopeTopicId: null,
      now: now,
      parameters: parameters,
    );
    expect(counts.learning, 1);
    expect(counts.newWaiting, 2);
    expect(counts.learnedDue, 0);
  });
}
