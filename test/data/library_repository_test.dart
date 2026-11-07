import 'dart:io';

import 'package:drift/drift.dart' hide isNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
// sqlite3 is already locked through Drift. The migration test writes a
// version 1 file before Drift opens it.
// ignore: depend_on_referenced_packages
import 'package:sqlite3/sqlite3.dart';
import 'package:rhythm_method_flashcards/data/database.dart';
import 'package:rhythm_method_flashcards/data/library_backup.dart';
import 'package:rhythm_method_flashcards/data/library_repository.dart';
import 'package:rhythm_method_flashcards/domain/scheduler.dart';

void main() {
  late Directory temp;
  late String path;
  late LibraryDatabase database;
  late LibraryRepository repository;
  var databaseClosed = false;

  setUp(() async {
    temp = await Directory.systemTemp.createTemp('rhythm-method-');
    path = '${temp.path}/library.sqlite';
    database = LibraryDatabase(NativeDatabase(File(path)));
    databaseClosed = false;
    repository = LibraryRepository(database);
  });

  tearDown(() async {
    if (!databaseClosed) {
      await database.close();
    }
    if (temp.existsSync()) {
      await temp.delete(recursive: true);
    }
  });

  test('a new database stores the default settings', () async {
    final settings = await repository.loadSettings();
    expect(settings.correctFactor, 1.5);
    expect(settings.wrongFactor, 0.5);
    expect(settings.difficultyFactor, 0.01);
    expect(settings.learningWindowSize, 10);
    expect(settings.learnedThreshold, const Duration(hours: 1));
  });

  test('admission and a grade survive reopening the file', () async {
    final created = DateTime.utc(2026, 3, 1);
    final reviewed = DateTime.utc(2026, 6, 1, 12);
    await repository.insertTopic(
      id: 'spanish',
      name: 'Spanish',
      createdAt: created,
    );
    await repository.insertCard(
      FlashCard.fresh(
        id: 'hola',
        topicId: 'spanish',
        front: 'hola',
        back: 'hello',
        createdAt: created,
      ),
    );

    final admitted = await repository.admit('hola');
    expect(admitted.learning, isTrue);
    expect(admitted.lastReview, isNull);

    final graded = await repository.grade(
      cardId: 'hola',
      outcome: GradeOutcome.wrong,
      now: reviewed,
    );

    await database.close();
    databaseClosed = true;
    final reopened = LibraryDatabase(NativeDatabase(File(path)));
    final again = LibraryRepository(reopened);
    addTearDown(reopened.close);

    final card = await again.card('hola');
    expect(card.intervalSeconds, graded.result.after.intervalSeconds);
    expect(card.difficulty, graded.result.after.difficulty);
    expect(card.learning, graded.result.after.learning);
    expect(card.lastReview, reviewed);
    expect(card.front, 'hola');
    expect(card.back, 'hello');

    final reviews = await again.reviewsFor('hola');
    expect(reviews, hasLength(1));
    expect(reviews.single.id, graded.reviewId);
    expect(reviews.single.record.outcome, GradeOutcome.wrong);
    expect(reviews.single.record.intervalBefore, 600);
    expect(reviews.single.record.intervalAfter, card.intervalSeconds);
    expect(reviews.single.record.difficultyBefore, 1);
    expect(reviews.single.record.difficultyAfter, card.difficulty);
    expect(reviews.single.record.learningBefore, isTrue);
    expect(reviews.single.record.learningAfter, isTrue);
    expect(reviews.single.record.reviewedAt, reviewed);
    expect(reviews.single.lastReviewBefore, isNull);
  });

  test('undo restores the card and removes the review row', () async {
    final created = DateTime.utc(2026, 3, 1);
    await repository.insertTopic(
      id: 'spanish',
      name: 'Spanish',
      createdAt: created,
    );
    await repository.insertCard(
      FlashCard.fresh(
        id: 'hola',
        topicId: 'spanish',
        front: 'hola',
        back: 'hello',
        createdAt: created,
      ),
    );
    await repository.admit('hola');
    final graded = await repository.grade(
      cardId: 'hola',
      outcome: GradeOutcome.correct,
      now: DateTime.utc(2026, 6, 1, 12),
    );

    final restored = await repository.undo(graded);
    expect(restored.learning, isTrue);
    expect(restored.lastReview, isNull);
    expect(restored.intervalSeconds, admittedInterval);
    expect(await repository.reviewsFor('hola'), isEmpty);

    final stored = await repository.card('hola');
    expect(stored, restored);
  });

  test('editing card text does not change the schedule', () async {
    final created = DateTime.utc(2026, 3, 1);
    await repository.insertTopic(
      id: 'spanish',
      name: 'Spanish',
      createdAt: created,
    );
    await repository.insertCard(
      FlashCard.fresh(
        id: 'hola',
        topicId: 'spanish',
        front: 'hola',
        back: 'hello',
        createdAt: created,
      ),
    );
    await repository.admit('hola');
    await repository.updateCardContent('hola', front: 'hola!', back: 'hi');

    final card = await repository.card('hola');
    expect(card.front, 'hola!');
    expect(card.back, 'hi');
    expect(card.learning, isTrue);
    expect(card.intervalSeconds, admittedInterval);
  });

  test('a topic with a card or a subtopic cannot be deleted', () async {
    await repository.insertTopic(id: 'parent', name: 'Parent');
    await repository.insertTopic(
      id: 'child',
      name: 'Child',
      parentId: 'parent',
    );
    expect(
      () => repository.deleteTopic('parent'),
      throwsA(
        isA<StateError>().having(
          (error) => error.message,
          'message',
          contains('subtopics'),
        ),
      ),
    );

    await repository.insertCard(
      FlashCard.fresh(
        id: 'card',
        topicId: 'child',
        front: 'front',
        back: 'back',
        createdAt: DateTime.utc(2026, 3, 2),
      ),
    );
    expect(
      () => repository.deleteTopic('child'),
      throwsA(
        isA<StateError>().having(
          (error) => error.message,
          'message',
          contains('cards'),
        ),
      ),
    );
    expect(await repository.listTopics(), hasLength(2));
  });

  test(
    'graduating the forward face queues a new reverse at the front',
    () async {
      final now = DateTime.utc(2026, 6, 1, 12);
      await repository.insertTopic(id: 'spanish', name: 'Spanish');
      await repository.setReverseDrill('spanish', enabled: true, now: now);
      await repository.insertCard(
        FlashCard(
          id: 'hola',
          topicId: 'spanish',
          front: 'hola',
          back: 'hello',
          learning: true,
          lastReview: now.subtract(const Duration(minutes: 10)),
          intervalSeconds: 4000,
          difficulty: 2.5,
          createdAt: DateTime.utc(2026, 1, 1),
        ),
      );

      final before = await repository.card('hola');
      expect(before.hasReverse, isTrue);
      expect(before.reverseLearning, isFalse);
      expect(before.reverseLastReview, isNull);

      final graded = await repository.grade(
        cardId: 'hola',
        outcome: GradeOutcome.correct,
        now: now,
      );
      final card = graded.result.after;
      expect(card.learning, isFalse);
      expect(card.difficulty, 2.5);
      expect(card.hasReverse, isTrue);
      expect(card.reverseLearning, isFalse);
      expect(card.reverseLastReview, isNull);
      expect(card.reverseIntervalSeconds, 600);
      expect(card.reverseDifficulty, 1);
      expect(card.reverseQueuedAt!.isAfter(before.reverseQueuedAt!), isTrue);
      expect(
        (await repository.reviewsFor('hola')).single.record.face,
        StudyFace.forward,
      );

      final restored = await repository.undo(graded);
      expect(restored.hasReverse, isTrue);
      expect(restored.learning, isTrue);
      expect(restored.reverseQueuedAt, before.reverseQueuedAt);
      expect(restored.reverseIntervalSeconds, 600);
      expect(
        (await repository.card('hola')).reverseQueuedAt,
        before.reverseQueuedAt,
      );
    },
  );

  test(
    'turning the switch on backfills learned cards and off keeps them',
    () async {
      final now = DateTime.utc(2026, 6, 1, 12);
      await repository.insertTopic(id: 'parent', name: 'Parent');
      await repository.insertTopic(
        id: 'child',
        name: 'Child',
        parentId: 'parent',
      );
      await repository.insertCard(
        FlashCard(
          id: 'older',
          topicId: 'parent',
          front: 'older',
          back: 'old-back',
          learning: false,
          lastReview: DateTime.utc(2020, 1, 1),
          intervalSeconds: 7200,
          difficulty: 1,
          createdAt: DateTime.utc(2020, 1, 1),
        ),
      );
      await repository.insertCard(
        FlashCard(
          id: 'newer',
          topicId: 'parent',
          front: 'newer',
          back: 'new-back',
          learning: false,
          lastReview: DateTime.utc(2025, 1, 1),
          intervalSeconds: 7200,
          difficulty: 3,
          createdAt: DateTime.utc(2025, 1, 1),
        ),
      );
      await repository.insertCard(
        FlashCard.fresh(
          id: 'fresh',
          topicId: 'parent',
          front: 'fresh',
          back: 'fresh-back',
          createdAt: DateTime.utc(2026, 1, 1),
        ),
      );
      await repository.insertCard(
        FlashCard(
          id: 'child-learned',
          topicId: 'child',
          front: 'child',
          back: 'child-back',
          learning: false,
          lastReview: DateTime.utc(2019, 1, 1),
          intervalSeconds: 7200,
          difficulty: 1,
          createdAt: DateTime.utc(2019, 1, 1),
        ),
      );

      await repository.setReverseDrill('parent', enabled: true, now: now);
      final older = await repository.card('older');
      final newer = await repository.card('newer');
      final fresh = await repository.card('fresh');
      final child = await repository.card('child-learned');
      expect(older.reverseQueuedAt!.isAfter(newer.reverseQueuedAt!), isTrue);
      expect(older.reverseDifficulty, 1);
      expect(newer.reverseDifficulty, 1);
      expect(fresh.hasReverse, isTrue);
      expect(fresh.reverseLearning, isFalse);
      expect(fresh.reverseLastReview, isNull);
      expect(fresh.reverseQueuedAt!.isBefore(newer.reverseQueuedAt!), isTrue);
      expect(child.hasReverse, isFalse);
      expect(
        (await repository.listTopics())
            .singleWhere((t) => t.id == 'child')
            .reverseDrill,
        isFalse,
      );

      await repository.setReverseDrill('parent', enabled: false, now: now);
      expect((await repository.card('older')).hasReverse, isTrue);
      expect(
        (await repository.listTopics())
            .singleWhere((t) => t.id == 'parent')
            .reverseDrill,
        isFalse,
      );

      await repository.setReverseDrill(
        'parent',
        enabled: true,
        now: now.add(const Duration(days: 1)),
      );
      final resumed = await repository.card('older');
      expect(resumed.reverseQueuedAt, older.reverseQueuedAt);
    },
  );

  test(
    'a topic already switched on gains the reverses it was missing',
    () async {
      final now = DateTime.utc(2026, 6, 1, 12);
      await repository.insertTopic(id: 'spanish', name: 'Spanish');
      await repository.insertCard(
        FlashCard.fresh(
          id: 'fresh',
          topicId: 'spanish',
          front: 'fresh',
          back: 'fresh-back',
          createdAt: DateTime.utc(2026, 1, 2),
        ),
      );
      await repository.insertCard(
        FlashCard(
          id: 'known',
          topicId: 'spanish',
          front: 'known',
          back: 'known-back',
          learning: false,
          lastReview: DateTime.utc(2024, 1, 1),
          intervalSeconds: 7200,
          difficulty: 2,
          createdAt: DateTime.utc(2024, 1, 1),
        ),
      );
      await (database.update(database.topics)
            ..where((row) => row.id.equals('spanish')))
          .write(const TopicsCompanion(reverseDrill: Value(true)));
      expect((await repository.card('fresh')).hasReverse, isFalse);

      await repository.ensureReverseFaces('spanish', now: now);
      final fresh = await repository.card('fresh');
      final known = await repository.card('known');
      expect(fresh.hasReverse, isTrue);
      expect(fresh.reverseLastReview, isNull);
      expect(known.hasReverse, isTrue);
      expect(known.reverseDifficulty, 1);
      expect(known.reverseQueuedAt!.isAfter(fresh.reverseQueuedAt!), isTrue);

      await repository.ensureReverseFaces(
        'spanish',
        now: now.add(const Duration(days: 1)),
      );
      expect(
        (await repository.card('known')).reverseQueuedAt,
        known.reverseQueuedAt,
      );
      expect(
        (await repository.card('fresh')).reverseQueuedAt,
        fresh.reverseQueuedAt,
      );
    },
  );

  test(
    'a wrong reverse grade stores the direction and leaves the front',
    () async {
      final now = DateTime.utc(2026, 6, 1, 12);
      await repository.insertTopic(id: 'spanish', name: 'Spanish');
      await repository.setReverseDrill('spanish', enabled: true, now: now);
      await repository.insertCard(
        FlashCard(
          id: 'hola',
          topicId: 'spanish',
          front: 'hola',
          back: 'hello',
          learning: false,
          lastReview: DateTime.utc(2024, 1, 1),
          intervalSeconds: 7200,
          difficulty: 1.5,
          createdAt: DateTime.utc(2024, 1, 1),
        ),
      );
      await repository.setReverseDrill('spanish', enabled: true, now: now);
      final before = await repository.card('hola');
      final graded = await repository.grade(
        cardId: 'hola',
        outcome: GradeOutcome.wrong,
        now: now,
        face: StudyFace.reverse,
      );
      final after = graded.result.after;
      expect(after.intervalSeconds, before.intervalSeconds);
      expect(after.difficulty, before.difficulty);
      expect(after.reverseIntervalSeconds, 300);
      expect(graded.result.review.face, StudyFace.reverse);
      expect(
        (await repository.reviewsFor('hola')).single.record.face,
        StudyFace.reverse,
      );
      expect(
        (await repository.reviewsFor('hola')).single.lastReviewBefore,
        isNull,
      );
    },
  );

  test('tags keep their spelling, and deleting one leaves the card', () async {
    await repository.insertTopic(id: 'spanish', name: 'Spanish');
    await repository.insertCard(
      FlashCard.fresh(
        id: 'hola',
        topicId: 'spanish',
        front: 'hola',
        back: 'hello',
        createdAt: DateTime.utc(2026, 1, 1),
      ),
    );
    await repository.insertTag(id: 'verb', name: ' Verb ');
    await repository.insertTag(id: 'noun', name: 'Noun');
    expect(
      () => repository.insertTag(id: 'again', name: 'verb'),
      throwsStateError,
    );
    expect(
      () => repository.insertTag(id: 'blank', name: ' '),
      throwsStateError,
    );

    await repository.renameTag('verb', 'Verbs');
    expect((await repository.listTags()).map((tag) => tag.name), [
      'Verbs',
      'Noun',
    ]);
    await repository.reorderTags(['noun', 'verb']);
    expect((await repository.listTags()).map((tag) => tag.id), [
      'noun',
      'verb',
    ]);

    await repository.setCardTags('hola', {'verb', 'noun'});
    expect(await repository.tagIdsFor('hola'), ['noun', 'verb']);
    await repository.deleteTag('verb');
    expect(await repository.tagIdsFor('hola'), ['noun']);
    expect((await repository.card('hola')).front, 'hola');

    final restored = parseLibraryBackup(await repository.backupJson());
    expect(restored.tags.single.name, 'Noun');
    expect(restored.cardTagIds['hola'], ['noun']);
  });

  test('a version 1 database keeps its rows and gains empty reverse columns', () async {
    await database.close();
    databaseClosed = true;
    final legacyPath = '${temp.path}/legacy.sqlite';
    final created = DateTime.utc(2026, 3, 1);
    final reviewed = DateTime.utc(2026, 6, 1, 12);
    final legacy = sqlite3.open(legacyPath);
    legacy
      ..execute('PRAGMA user_version = 1')
      ..execute('''
        CREATE TABLE topics (
          id TEXT NOT NULL PRIMARY KEY,
          parent_id TEXT NULL REFERENCES topics(id) ON DELETE RESTRICT,
          name TEXT NOT NULL,
          position INTEGER NOT NULL,
          created_at INTEGER NOT NULL
        )
      ''')
      ..execute('''
        CREATE TABLE cards (
          id TEXT NOT NULL PRIMARY KEY,
          topic_id TEXT NOT NULL REFERENCES topics(id) ON DELETE RESTRICT,
          front TEXT NOT NULL,
          back TEXT NOT NULL,
          learning INTEGER NOT NULL,
          last_review INTEGER NULL,
          interval_seconds INTEGER NOT NULL,
          difficulty REAL NOT NULL,
          created_at INTEGER NOT NULL
        )
      ''')
      ..execute('''
        CREATE TABLE reviews (
          id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
          card_id TEXT NOT NULL REFERENCES cards(id) ON DELETE CASCADE,
          reviewed_at INTEGER NOT NULL,
          outcome TEXT NOT NULL,
          interval_before INTEGER NOT NULL,
          interval_after INTEGER NOT NULL,
          difficulty_before REAL NOT NULL,
          difficulty_after REAL NOT NULL,
          learning_before INTEGER NOT NULL,
          learning_after INTEGER NOT NULL,
          last_review_before INTEGER NULL
        )
      ''')
      ..execute('''
        CREATE TABLE settings (
          id INTEGER NOT NULL PRIMARY KEY,
          correct_factor REAL NOT NULL,
          wrong_factor REAL NOT NULL,
          difficulty_factor REAL NOT NULL,
          learning_window_size INTEGER NOT NULL,
          learned_threshold_seconds INTEGER NOT NULL
        )
      ''');
    final topicCreated = created.millisecondsSinceEpoch ~/ 1000;
    final reviewSeconds = reviewed.millisecondsSinceEpoch ~/ 1000;
    legacy.execute(
      'INSERT INTO topics (id, parent_id, name, position, created_at) VALUES (?, NULL, ?, 0, ?)',
      ['spanish', 'Spanish', topicCreated],
    );
    legacy.execute(
      'INSERT INTO cards (id, topic_id, front, back, learning, last_review, interval_seconds, difficulty, created_at) VALUES (?, ?, ?, ?, 1, ?, 300, 1.25, ?)',
      ['hola', 'spanish', 'hola', 'hello', reviewSeconds, topicCreated],
    );
    legacy.execute(
      'INSERT INTO reviews (card_id, reviewed_at, outcome, interval_before, interval_after, difficulty_before, difficulty_after, learning_before, learning_after, last_review_before) VALUES (?, ?, ?, 600, 300, 1, 1.25, 1, 1, NULL)',
      ['hola', reviewSeconds, 'wrong'],
    );
    legacy.execute(
      'INSERT INTO settings (id, correct_factor, wrong_factor, difficulty_factor, learning_window_size, learned_threshold_seconds) VALUES (1, 1.5, 0.5, 0.01, 10, 3600)',
    );
    legacy.dispose();

    final opened = LibraryDatabase(NativeDatabase(File(legacyPath)));
    addTearDown(opened.close);
    final migrated = LibraryRepository(opened);
    final topic = (await migrated.listTopics()).single;
    expect(topic.name, 'Spanish');
    expect(topic.reverseDrill, isFalse);
    final card = await migrated.card('hola');
    expect(card.front, 'hola');
    expect(card.learning, isTrue);
    expect(card.intervalSeconds, 300);
    expect(card.difficulty, 1.25);
    expect(card.lastReview, reviewed);
    expect(card.hasReverse, isFalse);
    final review = (await migrated.reviewsFor('hola')).single;
    expect(review.record.face, StudyFace.forward);
    expect(review.record.outcome, GradeOutcome.wrong);
    expect(await migrated.listTags(), isEmpty);
  });
}

const admittedInterval = SchedulerConstants.initialIntervalSeconds;
