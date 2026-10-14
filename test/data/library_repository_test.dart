import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rhythm_method_flashcards/data/database.dart';
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
}

const admittedInterval = SchedulerConstants.initialIntervalSeconds;
