import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:rhythm_method_flashcards/domain/scheduler.dart';

void main() {
  final parameters = SchedulerParameters.defaults();
  final now = DateTime.utc(2026, 6, 1, 12);

  group('parameters', () {
    test('defaults match the spec', () {
      expect(parameters.correctFactor, 1.5);
      expect(parameters.wrongFactor, 0.5);
      expect(parameters.difficultyFactor, 0.01);
      expect(parameters.learningWindowSize, 10);
      expect(parameters.learnedThreshold, const Duration(hours: 1));
    });

    test('rejects values outside the spec', () {
      expect(() => parameters.rebuild(correctFactor: 1), throwsArgumentError);
      expect(() => parameters.rebuild(correctFactor: 0.5), throwsArgumentError);
      expect(() => parameters.rebuild(wrongFactor: 0), throwsArgumentError);
      expect(() => parameters.rebuild(wrongFactor: 1), throwsArgumentError);
      expect(
        () => parameters.rebuild(difficultyFactor: -0.01),
        throwsArgumentError,
      );
      expect(
        () => parameters.rebuild(learningWindowSize: 0),
        throwsArgumentError,
      );
      expect(
        () => parameters.rebuild(learnedThreshold: Duration.zero),
        throwsArgumentError,
      );
    });
  });

  group('invariant 1', () {
    test(
      'a wrong grade sets learning even when the interval stays above the threshold',
      () {
        final card = learnedCard(
          id: 'lapse',
          interval: const Duration(hours: 4),
          lastReview: now.subtract(const Duration(hours: 5)),
        );

        final result = gradeCard(
          card: card,
          outcome: GradeOutcome.wrong,
          now: now,
          parameters: parameters,
        );

        expect(result.after.learning, isTrue);
        expect(
          result.after.intervalSeconds,
          const Duration(hours: 2).inSeconds,
        );
        expect(
          Duration(seconds: result.after.intervalSeconds) >
              parameters.learnedThreshold,
          isTrue,
        );
      },
    );
  });

  group('invariant 2', () {
    test(
      'a correct grade clears learning only when the interval is above the threshold',
      () {
        final stillLearning = freshCard().copyWith(
          learning: true,
          intervalSeconds: const Duration(minutes: 30).inSeconds,
        );
        final stays = gradeCard(
          card: stillLearning,
          outcome: GradeOutcome.correct,
          now: now,
          parameters: parameters,
        );
        expect(stays.after.learning, isTrue);
        expect(
          Duration(seconds: stays.after.intervalSeconds) >
              parameters.learnedThreshold,
          isFalse,
        );

        final ready = freshCard().copyWith(
          learning: true,
          intervalSeconds: const Duration(minutes: 50).inSeconds,
        );
        final graduates = gradeCard(
          card: ready,
          outcome: GradeOutcome.correct,
          now: now,
          parameters: parameters,
        );
        expect(graduates.after.learning, isFalse);
        expect(
          Duration(seconds: graduates.after.intervalSeconds) >
              parameters.learnedThreshold,
          isTrue,
        );
      },
    );
  });

  group('invariant 3', () {
    test(
      'correct leaves difficulty unchanged and wrong adds the factor, capped at 10',
      () {
        final card = freshCard(difficulty: 1);
        final correct = gradeCard(
          card: card,
          outcome: GradeOutcome.correct,
          now: now,
          parameters: parameters,
        );
        expect(correct.after.difficulty, card.difficulty);

        final wrong = gradeCard(
          card: card,
          outcome: GradeOutcome.wrong,
          now: now,
          parameters: parameters,
        );
        expect(
          wrong.after.difficulty,
          card.difficulty + parameters.difficultyFactor,
        );

        final capped = gradeCard(
          card: freshCard(difficulty: SchedulerConstants.difficultyCap),
          outcome: GradeOutcome.wrong,
          now: now,
          parameters: parameters,
        );
        expect(capped.after.difficulty, SchedulerConstants.difficultyCap);

        final almostCapped = gradeCard(
          card: freshCard(difficulty: 9.995),
          outcome: GradeOutcome.wrong,
          now: now,
          parameters: parameters,
        );
        expect(almostCapped.after.difficulty, SchedulerConstants.difficultyCap);
      },
    );
  });

  group('invariant 4', () {
    test(
      'a correct grade never shortens the interval, and no grade stores one below the floor',
      () {
        final card = freshCard(difficulty: SchedulerConstants.difficultyCap);
        final correct = gradeCard(
          card: card,
          outcome: GradeOutcome.correct,
          now: now,
          parameters: parameters,
        );
        expect(
          correct.after.intervalSeconds,
          greaterThanOrEqualTo(card.intervalSeconds),
        );

        final tiny = freshCard().copyWith(intervalSeconds: 1);
        final wrong = gradeCard(
          card: tiny,
          outcome: GradeOutcome.wrong,
          now: now,
          parameters: parameters,
        );
        expect(
          wrong.after.intervalSeconds,
          greaterThanOrEqualTo(SchedulerConstants.minimumIntervalSeconds),
        );
        expect(
          correct.after.intervalSeconds,
          greaterThanOrEqualTo(SchedulerConstants.minimumIntervalSeconds),
        );
      },
    );

    test(
      'growth stays at the correct factor when that factor is below the minimum growth',
      () {
        final gentle = parameters.rebuild(correctFactor: 1.1);
        final card = freshCard(difficulty: SchedulerConstants.difficultyCap);
        final result = gradeCard(
          card: card,
          outcome: GradeOutcome.correct,
          now: now,
          parameters: gentle,
        );
        expect(result.after.intervalSeconds, (600 * 1.1).round());
      },
    );
  });

  group('invariant 5', () {
    test('five default corrects graduate a fresh card and four do not', () {
      final afterFour = applyCorrects(freshCard(), 4, now);
      expect(afterFour.intervalSeconds, lessThanOrEqualTo(3600));
      expect(afterFour.learning, isTrue);

      final afterFive = applyCorrects(freshCard(), 5, now);
      expect(afterFive.intervalSeconds, greaterThan(3600));
      expect(afterFive.learning, isFalse);
    });
  });

  group('invariant 6', () {
    test(
      'one wrong on a fresh card is 5 minutes and 1.01, then seven corrects graduate it',
      () {
        final wrong = gradeCard(
          card: freshCard(),
          outcome: GradeOutcome.wrong,
          now: now,
          parameters: parameters,
        );
        expect(
          wrong.after.intervalSeconds,
          const Duration(minutes: 5).inSeconds,
        );
        expect(wrong.after.difficulty, 1.01);
        expect(wrong.after.learning, isTrue);

        final afterSix = applyCorrects(wrong.after, 6, now);
        expect(afterSix.intervalSeconds, lessThanOrEqualTo(3600));
        expect(afterSix.learning, isTrue);

        final afterSeven = applyCorrects(wrong.after, 7, now);
        expect(afterSeven.intervalSeconds, greaterThan(3600));
        expect(afterSeven.learning, isFalse);
      },
    );
  });

  group('invariant 7', () {
    test('a due learned card is chosen before learning and new cards', () {
      final due = learnedCard(
        id: 'due',
        interval: const Duration(hours: 2),
        lastReview: now.subtract(const Duration(hours: 3)),
      );
      final learning = freshCard(id: 'learning').copyWith(
        learning: true,
        lastReview: now.subtract(const Duration(minutes: 1)),
      );
      final waiting = freshCard(
        id: 'new',
        createdAt: now.subtract(const Duration(days: 1)),
      );

      final selection = selectCard(
        topics: [topic()],
        cards: [waiting, learning, due],
        scopeTopicId: null,
        now: now,
        parameters: parameters,
        draw: (_) => fail('due learned cards do not use the draw'),
      );

      expect(selection, isA<CardSelected>());
      expect((selection as CardSelected).card.id, due.id);
      expect(selection.admitted, isFalse);
    });
  });

  group('invariant 8', () {
    test('a full window admits no new card', () {
      final window = parameters.rebuild(learningWindowSize: 3);
      final cards = [
        for (var i = 0; i < 3; i++)
          freshCard(id: 'l$i').copyWith(
            learning: true,
            lastReview: now.subtract(Duration(minutes: 10 - i)),
          ),
        freshCard(id: 'new'),
      ];

      final chosen = tally(cards: cards, parameters: window, now: now);
      expect(chosen.containsKey('new'), isFalse);
      expect(chosen.keys, isNotEmpty);
      for (final id in chosen.keys) {
        expect(id, startsWith('l'));
      }
    });
  });

  group('invariant 9', () {
    test('new-card share is 2/(L+1) and admission follows created_at', () {
      final older = freshCard(
        id: 'older',
        createdAt: now.subtract(const Duration(days: 2)),
      );
      final newer = freshCard(
        id: 'newer',
        createdAt: now.subtract(const Duration(days: 1)),
      );
      final sameTimeLowerId = freshCard(
        id: 'a',
        createdAt: now.subtract(const Duration(days: 3)),
      );
      final sameTimeHigherId = freshCard(
        id: 'b',
        createdAt: sameTimeLowerId.createdAt,
      );

      for (final learningCount in [2, 3, 5, 9]) {
        final cards = [...learningCards(learningCount, now), older, newer];
        final chosen = tally(cards: cards, now: now);
        final total = chosen.values.fold<int>(0, (sum, count) => sum + count);
        expect(chosen['older'], total * 2 ~/ (learningCount + 1));
        expect(chosen.containsKey('newer'), isFalse);
      }

      final tied = tally(
        cards: [...learningCards(2, now), sameTimeHigherId, sameTimeLowerId],
        now: now,
      );
      expect(tied.containsKey('a'), isTrue);
      expect(tied.containsKey('b'), isFalse);
    });

    test('L of 0 or 1 always admits the oldest new card', () {
      final first = freshCard(
        id: 'first',
        createdAt: now.subtract(const Duration(days: 2)),
      );
      final second = freshCard(
        id: 'second',
        createdAt: now.subtract(const Duration(days: 1)),
      );

      final fromEmpty =
          selectCard(
                topics: [topic()],
                cards: [second, first],
                scopeTopicId: null,
                now: now,
                parameters: parameters,
                draw: (_) => fail('an empty window does not draw'),
              )
              as CardSelected;
      expect(fromEmpty.card.id, 'first');
      expect(fromEmpty.admitted, isTrue);

      final fromOne = tally(
        cards: [
          freshCard(id: 'learning').copyWith(
            learning: true,
            lastReview: now.subtract(const Duration(minutes: 1)),
          ),
          second,
          first,
        ],
        now: now,
      );
      expect(fromOne, {'first': 1});
    });
  });

  group('invariant 10', () {
    test(
      'a full window gives the most recent card probability 0 and the least recent 2/W',
      () {
        const window = 10;
        final cards = [
          for (var rank = 0; rank < window; rank++)
            freshCard(id: 'r$rank').copyWith(
              learning: true,
              // Higher rank was reviewed longer ago, so it is least recent.
              lastReview: now.subtract(Duration(minutes: rank + 1)),
            ),
        ];

        final chosen = tally(
          cards: cards,
          parameters: parameters.rebuild(learningWindowSize: window),
          now: now,
        );
        final total = chosen.values.fold<int>(0, (sum, count) => sum + count);
        expect(chosen['r0'] ?? 0, 0);
        expect(chosen['r${window - 1}'], total * 2 ~/ window);
        for (var rank = 0; rank < window; rank++) {
          expect(chosen['r$rank'] ?? 0, rank);
        }
      },
    );
  });

  group('invariant 11', () {
    test(
      'one learning card is repeated when nothing new is waiting, and yields when a new card is',
      () {
        final only = freshCard(id: 'only').copyWith(
          learning: true,
          lastReview: now.subtract(const Duration(minutes: 1)),
        );
        final alone =
            selectCard(
                  topics: [topic()],
                  cards: [only],
                  scopeTopicId: null,
                  now: now,
                  parameters: parameters,
                  draw: (_) => fail('a zero total does not draw'),
                )
                as CardSelected;
        expect(alone.card.id, only.id);
        expect(alone.admitted, isFalse);

        final withNew = tally(
          cards: [
            only,
            freshCard(id: 'new'),
          ],
          now: now,
        );
        expect(withNew, {'new': 1});
      },
    );
  });

  group('invariant 12', () {
    test('the higher overdue ratio wins over a larger absolute lateness', () {
      final higherRatio = learnedCard(
        id: 'ratio',
        interval: const Duration(hours: 2),
        lastReview: now.subtract(const Duration(hours: 4)),
      );
      final moreLate = learnedCard(
        id: 'late',
        interval: const Duration(hours: 20),
        lastReview: now.subtract(const Duration(hours: 30)),
      );

      final selection = selectOnly([higherRatio, moreLate], now: now);
      expect(selection.card.id, 'ratio');
    });

    test('ties fall through absolute lateness, then created time, then id', () {
      final shorter = learnedCard(
        id: 'short',
        interval: const Duration(hours: 2),
        lastReview: now.subtract(const Duration(hours: 4)),
        createdAt: now.subtract(const Duration(days: 1)),
      );
      final longer = learnedCard(
        id: 'long',
        interval: const Duration(hours: 3),
        lastReview: now.subtract(const Duration(hours: 6)),
        createdAt: now.subtract(const Duration(days: 5)),
      );
      expect(selectOnly([shorter, longer], now: now).card.id, 'long');

      final created = now.subtract(const Duration(days: 4));
      final older = learnedCard(
        id: 'older',
        interval: const Duration(hours: 2),
        lastReview: now.subtract(const Duration(hours: 4)),
        createdAt: created.subtract(const Duration(days: 1)),
      );
      final younger = learnedCard(
        id: 'younger',
        interval: const Duration(hours: 2),
        lastReview: older.lastReview!,
        createdAt: created,
      );
      expect(selectOnly([younger, older], now: now).card.id, 'older');

      final lowerId = learnedCard(
        id: 'a',
        interval: const Duration(hours: 2),
        lastReview: now.subtract(const Duration(hours: 4)),
        createdAt: created,
      );
      final higherId = learnedCard(
        id: 'b',
        interval: const Duration(hours: 2),
        lastReview: lowerId.lastReview!,
        createdAt: created,
      );
      expect(selectOnly([higherId, lowerId], now: now).card.id, 'a');
    });
  });

  group('invariant 13', () {
    test('scope includes descendants and excludes siblings', () {
      final topics = [
        topic(id: 'parent'),
        topic(id: 'child', parentId: 'parent'),
        topic(id: 'sibling'),
      ];
      final day = DateTime.utc(2026, 1, 1);
      // The sibling is the oldest card in the library, so a scope leak would
      // show up as selecting it.
      final siblingCard = freshCard(
        id: 'sibling-card',
        topicId: 'sibling',
        createdAt: day,
      );
      final childCard = freshCard(
        id: 'child-card',
        topicId: 'child',
        createdAt: day.add(const Duration(days: 1)),
      );
      final parentCard = freshCard(
        id: 'parent-card',
        topicId: 'parent',
        createdAt: day.add(const Duration(days: 2)),
      );

      CardSelected pick(String? scope, List<FlashCard> cards) {
        return selectCard(
              topics: topics,
              cards: cards,
              scopeTopicId: scope,
              now: now,
              parameters: parameters,
              draw: (_) => fail('the first new card does not draw'),
            )
            as CardSelected;
      }

      final all = [siblingCard, childCard, parentCard];
      expect(pick('parent', all).card.id, 'child-card');
      expect(pick('child', all).card.id, 'child-card');
      expect(pick('sibling', all).card.id, 'sibling-card');
      expect(pick(null, all).card.id, 'sibling-card');
      expect(pick('parent', [parentCard, siblingCard]).card.id, 'parent-card');
    });

    test(
      'a full parent scope does not admit, and an empty sibling scope still can',
      () {
        final topics = [
          topic(id: 'parent'),
          topic(id: 'child', parentId: 'parent'),
          topic(id: 'sibling'),
        ];
        final window = parameters.rebuild(learningWindowSize: 2);
        final cards = [
          freshCard(id: 'c0', topicId: 'child').copyWith(
            learning: true,
            lastReview: now.subtract(const Duration(minutes: 2)),
          ),
          freshCard(id: 'c1', topicId: 'child').copyWith(
            learning: true,
            lastReview: now.subtract(const Duration(minutes: 1)),
          ),
          freshCard(id: 'parent-new', topicId: 'parent'),
          freshCard(id: 'sibling-new', topicId: 'sibling'),
        ];

        final parentPick = tally(
          topics: topics,
          cards: cards,
          scopeTopicId: 'parent',
          parameters: window,
          now: now,
        );
        expect(parentPick.containsKey('parent-new'), isFalse);

        final siblingPick =
            selectCard(
                  topics: topics,
                  cards: cards,
                  scopeTopicId: 'sibling',
                  now: now,
                  parameters: window,
                  draw: (_) => fail('the sibling window is empty'),
                )
                as CardSelected;
        expect(siblingPick.card.id, 'sibling-new');
        expect(siblingPick.admitted, isTrue);
      },
    );
  });

  group('invariant 14', () {
    test('undo restores the pre-grade schedule fields, newest grade first', () {
      final original = freshCard();
      final first = gradeCard(
        card: original,
        outcome: GradeOutcome.wrong,
        now: now,
        parameters: parameters,
      );
      final second = gradeCard(
        card: first.after,
        outcome: GradeOutcome.correct,
        now: now.add(const Duration(minutes: 1)),
        parameters: parameters,
      );

      expect(first.before.intervalSeconds, original.intervalSeconds);
      expect(first.before.difficulty, original.difficulty);
      expect(first.before.learning, original.learning);
      expect(first.before.lastReview, original.lastReview);

      final stack = GradeUndoStack()
        ..push(first)
        ..push(second);
      expect(stack.undo(), first.after);
      expect(stack.undo(), original);
      expect(stack.undo(), isNull);
    });

    test('undo of the first grade does not un-admit the card', () {
      final admitted = freshCard().copyWith(learning: true);
      final graded = gradeCard(
        card: admitted,
        outcome: GradeOutcome.correct,
        now: now,
        parameters: parameters,
      );
      expect(graded.before.learning, isTrue);
      expect(graded.before.lastReview, isNull);
      expect(graded.after.lastReview, now);
    });
  });

  group('invariant 15', () {
    test(
      'admission sets learning before the grade, and a second select does not admit that card again',
      () {
        final card = freshCard(id: 'only');
        final first =
            selectCard(
                  topics: [topic()],
                  cards: [card],
                  scopeTopicId: null,
                  now: now,
                  parameters: parameters,
                  draw: (_) => fail('the only new card does not draw'),
                )
                as CardSelected;

        expect(first.admitted, isTrue);
        expect(first.card.learning, isTrue);
        expect(first.card.lastReview, isNull);
        expect(first.card.intervalSeconds, card.intervalSeconds);

        final second =
            selectCard(
                  topics: [topic()],
                  cards: [first.card],
                  scopeTopicId: null,
                  now: now,
                  parameters: parameters,
                  draw: (_) => fail('the sole learning card does not draw'),
                )
                as CardSelected;
        expect(second.admitted, isFalse);
        expect(second.card.id, card.id);
        expect(second.card.learning, isTrue);
      },
    );
  });

  group('spec examples', () {
    test('a learning card is eligible before its interval has elapsed', () {
      final card = freshCard().copyWith(
        learning: true,
        intervalSeconds: const Duration(hours: 2).inSeconds,
        lastReview: now.subtract(const Duration(minutes: 1)),
      );
      final selection = selectOnly([card], now: now);
      expect(selection.card.id, card.id);
    });

    test('one correct after a long lapse graduates the card again', () {
      final lapsed = gradeCard(
        card: learnedCard(
          interval: const Duration(hours: 4),
          lastReview: now.subtract(const Duration(days: 1)),
        ),
        outcome: GradeOutcome.wrong,
        now: now,
        parameters: parameters,
      );
      final recalled = gradeCard(
        card: lapsed.after,
        outcome: GradeOutcome.correct,
        now: now.add(const Duration(minutes: 1)),
        parameters: parameters,
      );
      expect(lapsed.after.learning, isTrue);
      expect(recalled.after.learning, isFalse);
      expect(recalled.after.intervalSeconds, greaterThan(3600));
    });

    test('nothing due, learning, or new clears the session', () {
      final waiting = learnedCard(
        interval: const Duration(days: 2),
        lastReview: now.subtract(const Duration(hours: 1)),
      );
      final selection = selectCard(
        topics: [topic()],
        cards: [waiting],
        scopeTopicId: null,
        now: now,
        parameters: parameters,
        draw: (_) => fail('a clear session does not draw'),
      );
      expect(selection, isA<SessionClear>());
    });

    test('the published window table holds', () {
      final expectedNew = <int, int>{0: 1, 1: 1, 2: 2, 3: 3, 5: 5, 9: 9};
      for (final entry in expectedNew.entries) {
        final learningCount = entry.key;
        final cards = [
          ...learningCards(learningCount, now),
          freshCard(id: 'new'),
        ];
        if (learningCount == 0) {
          final selected =
              selectCard(
                    topics: [topic()],
                    cards: cards,
                    scopeTopicId: null,
                    now: now,
                    parameters: parameters,
                    draw: (_) => fail('L = 0 does not draw'),
                  )
                  as CardSelected;
          expect(selected.card.id, 'new');
          continue;
        }
        final chosen = tally(cards: cards, now: now);
        expect(chosen['new'], entry.value);
      }

      // l0 was reviewed longest ago, so it is least recent. l9 is most recent.
      final full = tally(cards: learningCards(10, now), now: now);
      final fullTotal = full.values.fold<int>(0, (sum, n) => sum + n);
      expect(full['l9'] ?? 0, 0);
      expect(full['l0'], fullTotal ~/ 5);
    });
  });

  group('reverse faces', () {
    test('a grade on one face leaves the other face alone', () {
      final card = spawnReverseFace(
        learnedCard(
          id: 'both',
          interval: const Duration(hours: 4),
          lastReview: now.subtract(const Duration(days: 1)),
        ).copyWith(difficulty: 2),
        queuedAt: now,
      );

      final wrong = gradeCard(
        card: card,
        outcome: GradeOutcome.wrong,
        now: now,
        parameters: parameters,
        face: StudyFace.reverse,
      );

      expect(wrong.after.intervalSeconds, card.intervalSeconds);
      expect(wrong.after.difficulty, card.difficulty);
      expect(wrong.after.learning, card.learning);
      expect(wrong.after.lastReview, card.lastReview);
      expect(wrong.after.reverseIntervalSeconds, 300);
      expect(wrong.after.reverseDifficulty, 1.01);
      expect(wrong.after.reverseLearning, isTrue);
      expect(wrong.after.reverseLastReview, now);
      expect(wrong.review.face, StudyFace.reverse);
      expect(wrong.review.intervalBefore, 600);

      final forward = gradeCard(
        card: card,
        outcome: GradeOutcome.correct,
        now: now,
        parameters: parameters,
      );
      expect(forward.after.reverseIntervalSeconds, 600);
      expect(forward.after.reverseDifficulty, 1);
      expect(forward.after.reverseLearning, isFalse);
      expect(forward.after.reverseLastReview, isNull);
      expect(forward.review.face, StudyFace.forward);
    });

    test('a new reverse starts at ten minutes and difficulty 1', () {
      final forward = learnedCard(
        interval: const Duration(hours: 6),
        lastReview: now,
      ).copyWith(difficulty: 4);
      final spawned = spawnReverseFace(forward, queuedAt: now);
      expect(spawned.reverseLearning, isFalse);
      expect(spawned.reverseLastReview, isNull);
      expect(spawned.reverseIntervalSeconds, 600);
      expect(spawned.reverseDifficulty, 1);
      expect(spawned.difficulty, 4);
      expect(() => spawnReverseFace(spawned, queuedAt: now), throwsStateError);
    });

    test('graduations cut in front of a longest-known-first backfill', () {
      final first = nextReverseQueuedAt(const [], now);
      final second = nextReverseQueuedAt([first], now);
      expect(second.isAfter(first), isTrue);
      expect(second.difference(first), const Duration(seconds: 1));

      final older = learnedCard(
        id: 'older',
        interval: const Duration(hours: 2),
        lastReview: DateTime.utc(2020, 1, 1),
      );
      final newer = learnedCard(
        id: 'newer',
        interval: const Duration(hours: 2),
        lastReview: DateTime.utc(2025, 1, 1),
      );
      final ceiling = reverseBackfillCeiling([first, second], now);
      final backfill = queueReverseBackfill([newer, older], ceiling: ceiling);
      final olderAt = backfill
          .singleWhere((card) => card.id == 'older')
          .reverseQueuedAt!;
      final newerAt = backfill
          .singleWhere((card) => card.id == 'newer')
          .reverseQueuedAt!;
      expect(olderAt.isAfter(newerAt), isTrue);
      expect(olderAt.isBefore(first), isTrue);
      expect(newerAt.isBefore(first), isTrue);

      final later = nextReverseQueuedAt([first, second, olderAt, newerAt], now);
      expect(later.isAfter(second), isTrue);
      expect(later.isAfter(olderAt), isTrue);
    });

    test('a waiting reverse is admitted ahead of a never-started card', () {
      final topics = [topic(reverse: true)];
      final waiting = spawnReverseFace(
        learnedCard(
          id: 'known',
          interval: const Duration(days: 2),
          lastReview: now,
        ),
        queuedAt: DateTime.utc(2026, 5, 1),
      );
      final fresh = freshCard(id: 'plain', createdAt: DateTime.utc(2020, 1, 1));
      final selected =
          selectCard(
                topics: topics,
                cards: [fresh, waiting],
                scopeTopicId: null,
                now: now,
                parameters: parameters,
                draw: (_) => fail('an empty window does not draw'),
              )
              as CardSelected;

      expect(selected.face, StudyFace.reverse);
      expect(selected.admitted, isTrue);
      expect(selected.card.id, 'known');
      expect(selected.card.reverseLearning, isTrue);
      expect(selected.card.learning, isFalse);
      expect(waiting.reverseLearning, isFalse);
    });

    test('the newest waiting reverse stays ahead of an older one', () {
      final topics = [topic(reverse: true)];
      final older = spawnReverseFace(
        learnedCard(
          id: 'older',
          interval: const Duration(days: 2),
          lastReview: now,
        ),
        queuedAt: DateTime.utc(2026, 4, 1),
      );
      final newer = spawnReverseFace(
        learnedCard(
          id: 'newer',
          interval: const Duration(days: 2),
          lastReview: now,
        ),
        queuedAt: DateTime.utc(2026, 5, 1),
      );
      final fresh = freshCard(id: 'plain');
      final first =
          selectCard(
                topics: topics,
                cards: [older, fresh, newer],
                scopeTopicId: null,
                now: now,
                parameters: parameters,
                draw: (_) => fail('an empty window does not draw'),
              )
              as CardSelected;
      expect(first.card.id, 'newer');
      expect(first.face, StudyFace.reverse);

      final admitted = first.card;
      final second =
          selectCard(
                topics: topics,
                cards: [older, fresh, admitted],
                scopeTopicId: null,
                now: now,
                parameters: parameters,
                draw: (total) {
                  expect(total, 1);
                  return 0;
                },
              )
              as CardSelected;
      expect(second.card.id, 'older');
      expect(second.face, StudyFace.reverse);
      expect(second.admitted, isTrue);
    });

    test('the switch off leaves a reverse out of the draw and the window', () {
      final hidden = spawnReverseFace(
        learnedCard(
          id: 'known',
          interval: const Duration(days: 2),
          lastReview: now,
        ),
        queuedAt: now,
      ).copyWith(reverseLearning: true, reverseLastReview: now);
      final fresh = freshCard(id: 'plain');
      final selected =
          selectCard(
                topics: [topic()],
                cards: [hidden, fresh],
                scopeTopicId: null,
                now: now,
                parameters: parameters,
                draw: (_) => fail('an empty window does not draw'),
              )
              as CardSelected;
      expect(selected.card.id, 'plain');
      expect(selected.face, StudyFace.forward);
    });

    test('a due learned face outranks a waiting reverse', () {
      final due = learnedCard(
        id: 'due',
        interval: const Duration(hours: 2),
        lastReview: now.subtract(const Duration(hours: 3)),
      );
      final waiting = spawnReverseFace(
        learnedCard(
          id: 'known',
          interval: const Duration(days: 4),
          lastReview: now,
        ),
        queuedAt: now,
      );
      final selected =
          selectCard(
                topics: [topic(reverse: true)],
                cards: [waiting, due],
                scopeTopicId: null,
                now: now,
                parameters: parameters,
                draw: (_) => fail('a due card does not draw'),
              )
              as CardSelected;
      expect(selected.card.id, 'due');
      expect(selected.face, StudyFace.forward);
      expect(selected.admitted, isFalse);
    });

    test('a due reverse outranks a learning forward face', () {
      final learning = freshCard(
        id: 'drill',
      ).copyWith(learning: true, lastReview: now);
      final reverseDue =
          spawnReverseFace(
            learnedCard(
              id: 'known',
              interval: const Duration(days: 4),
              lastReview: now,
            ),
            queuedAt: now.subtract(const Duration(days: 2)),
          ).copyWith(
            reverseLearning: false,
            reverseLastReview: now.subtract(const Duration(hours: 3)),
            reverseIntervalSeconds: const Duration(hours: 2).inSeconds,
          );
      final selected =
          selectCard(
                topics: [topic(reverse: true)],
                cards: [learning, reverseDue],
                scopeTopicId: null,
                now: now,
                parameters: parameters,
                draw: (_) => fail('a due face does not draw'),
              )
              as CardSelected;
      expect(selected.card.id, 'known');
      expect(selected.face, StudyFace.reverse);
    });

    test('a full window admits no reverse, and two faces take two seats', () {
      final doubled =
          spawnReverseFace(
            freshCard(id: 'both').copyWith(
              learning: true,
              lastReview: now.subtract(const Duration(minutes: 5)),
            ),
            queuedAt: now,
          ).copyWith(
            reverseLearning: true,
            reverseLastReview: now.subtract(const Duration(minutes: 1)),
          );
      final fresh = freshCard(id: 'plain');
      final window = parameters.rebuild(learningWindowSize: 2);
      final blocked =
          selectCard(
                topics: [topic(reverse: true)],
                cards: [doubled, fresh],
                scopeTopicId: null,
                now: now,
                parameters: window,
                draw: (total) {
                  expect(total, 1);
                  return 0;
                },
              )
              as CardSelected;
      expect(blocked.admitted, isFalse);
      expect(blocked.card.id, 'both');

      final open = parameters.rebuild(learningWindowSize: 3);
      final admitted =
          selectCard(
                topics: [topic(reverse: true)],
                cards: [doubled, fresh],
                scopeTopicId: null,
                now: now,
                parameters: open,
                draw: (total) {
                  expect(total, 3);
                  return 2;
                },
              )
              as CardSelected;
      expect(admitted.admitted, isTrue);
      expect(admitted.card.id, 'plain');
      expect(admitted.face, StudyFace.forward);
    });

    test('a card follows the switch on its own topic', () {
      final parent = Topic(id: 'parent', name: 'parent', reverseDrill: true);
      final child = Topic(id: 'child', name: 'child', parentId: 'parent');
      final parentReverse = spawnReverseFace(
        learnedCard(
          id: 'parent-card',
          topicId: 'parent',
          interval: const Duration(days: 2),
          lastReview: now,
        ),
        queuedAt: now,
      );
      final childNew = freshCard(
        id: 'child-card',
        topicId: 'child',
        createdAt: DateTime.utc(2020, 1, 1),
      );
      final childReverse = spawnReverseFace(
        learnedCard(
          id: 'child-known',
          topicId: 'child',
          interval: const Duration(days: 2),
          lastReview: now,
        ),
        queuedAt: now.add(const Duration(days: 1)),
      );

      final inParent =
          selectCard(
                topics: [parent, child],
                cards: [childNew, childReverse, parentReverse],
                scopeTopicId: 'parent',
                now: now,
                parameters: parameters,
                draw: (_) => fail('an empty window does not draw'),
              )
              as CardSelected;
      expect(inParent.card.id, 'parent-card');
      expect(inParent.face, StudyFace.reverse);

      final inChild =
          selectCard(
                topics: [parent, child],
                cards: [childNew, childReverse],
                scopeTopicId: 'child',
                now: now,
                parameters: parameters,
                draw: (_) => fail('an empty window does not draw'),
              )
              as CardSelected;
      expect(inChild.card.id, 'child-card');
      expect(inChild.face, StudyFace.forward);
    });

    test('forward graduation is the correct answer that clears learning', () {
      final learning = freshCard().copyWith(
        learning: true,
        intervalSeconds: const Duration(minutes: 50).inSeconds,
      );
      final graduated = gradeCard(
        card: learning,
        outcome: GradeOutcome.correct,
        now: now,
        parameters: parameters,
      );
      expect(
        forwardJustGraduated(
          before: graduated.before,
          after: graduated.after,
          parameters: parameters,
        ),
        isTrue,
      );

      final already = learnedCard(
        interval: const Duration(hours: 2),
        lastReview: now.subtract(const Duration(hours: 1)),
      );
      final again = gradeCard(
        card: already,
        outcome: GradeOutcome.correct,
        now: now,
        parameters: parameters,
      );
      expect(
        forwardJustGraduated(
          before: again.before,
          after: again.after,
          parameters: parameters,
        ),
        isFalse,
      );
    });
  });

  test('domain does not import Flutter', () {
    final files = Directory('lib/domain').listSync(recursive: true);
    expect(files, isNotEmpty);
    for (final entity in files) {
      if (entity is! File || !entity.path.endsWith('.dart')) continue;
      final source = entity.readAsStringSync();
      expect(source.contains('package:flutter'), isFalse, reason: entity.path);
      expect(source.contains('dart:ui'), isFalse, reason: entity.path);
    }
  });
}

FlashCard freshCard({
  String id = 'card',
  String topicId = 'topic',
  DateTime? createdAt,
  double difficulty = SchedulerConstants.initialDifficulty,
}) {
  return FlashCard.fresh(
    id: id,
    topicId: topicId,
    front: 'front $id',
    back: 'back $id',
    createdAt: createdAt ?? DateTime.utc(2026, 1, 1),
  ).copyWith(difficulty: difficulty);
}

FlashCard learnedCard({
  String id = 'learned',
  String topicId = 'topic',
  required Duration interval,
  required DateTime lastReview,
  DateTime? createdAt,
}) {
  return freshCard(id: id, topicId: topicId, createdAt: createdAt).copyWith(
    learning: false,
    lastReview: lastReview,
    intervalSeconds: interval.inSeconds,
  );
}

Topic topic({String id = 'topic', String? parentId, bool reverse = false}) {
  return Topic(id: id, name: id, parentId: parentId, reverseDrill: reverse);
}

List<FlashCard> learningCards(int count, DateTime now) {
  return [
    for (var i = 0; i < count; i++)
      freshCard(id: 'l$i').copyWith(
        learning: true,
        lastReview: now.subtract(Duration(minutes: count - i)),
      ),
  ];
}

FlashCard applyCorrects(FlashCard card, int count, DateTime start) {
  var current = card;
  for (var i = 0; i < count; i++) {
    current = gradeCard(
      card: current,
      outcome: GradeOutcome.correct,
      now: start.add(Duration(minutes: i)),
      parameters: SchedulerParameters.defaults(),
    ).after;
  }
  return current;
}

CardSelected selectOnly(
  List<FlashCard> cards, {
  required DateTime now,
  SchedulerParameters? parameters,
}) {
  return selectCard(
        topics: [topic()],
        cards: cards,
        scopeTopicId: null,
        now: now,
        parameters: parameters ?? SchedulerParameters.defaults(),
        draw: (total) => 0,
      )
      as CardSelected;
}

Map<String, int> tally({
  required List<FlashCard> cards,
  List<Topic>? topics,
  String? scopeTopicId,
  required DateTime now,
  SchedulerParameters? parameters,
}) {
  final used = parameters ?? SchedulerParameters.defaults();
  int? total;
  selectCard(
    topics: topics ?? [topic()],
    cards: cards,
    scopeTopicId: scopeTopicId,
    now: now,
    parameters: used,
    draw: (requested) {
      total = requested;
      return 0;
    },
  );
  final counts = <String, int>{};
  for (var pick = 0; pick < (total ?? 0); pick++) {
    final selected =
        selectCard(
              topics: topics ?? [topic()],
              cards: cards,
              scopeTopicId: scopeTopicId,
              now: now,
              parameters: used,
              draw: (requested) {
                expect(requested, total);
                return pick;
              },
            )
            as CardSelected;
    counts.update(selected.card.id, (count) => count + 1, ifAbsent: () => 1);
  }
  return counts;
}

extension on SchedulerParameters {
  SchedulerParameters rebuild({
    double? correctFactor,
    double? wrongFactor,
    double? difficultyFactor,
    int? learningWindowSize,
    Duration? learnedThreshold,
  }) {
    return SchedulerParameters(
      correctFactor: correctFactor ?? this.correctFactor,
      wrongFactor: wrongFactor ?? this.wrongFactor,
      difficultyFactor: difficultyFactor ?? this.difficultyFactor,
      learningWindowSize: learningWindowSize ?? this.learningWindowSize,
      learnedThreshold: learnedThreshold ?? this.learnedThreshold,
    );
  }
}
