import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rhythm_method_flashcards/data/database.dart';
import 'package:rhythm_method_flashcards/data/library_repository.dart';
import 'package:rhythm_method_flashcards/domain/scheduler.dart';
import 'package:rhythm_method_flashcards/features/library/library_scope.dart';
import 'package:rhythm_method_flashcards/features/study/study_session_screen.dart';

void main() {
  late LibraryDatabase database;
  late LibraryRepository repository;

  setUp(() {
    database = LibraryDatabase(NativeDatabase.memory());
    repository = LibraryRepository(database);
  });

  tearDown(() => database.close());

  testWidgets('a due learned card appears before a learning card', (
    tester,
  ) async {
    await insertTopic(repository, 'topic');
    await repository.insertCard(
      _card(
        id: 'due',
        front: 'overdue',
        back: 'overdue-back',
        learning: false,
        lastReview: DateTime.utc(2026, 1, 1),
        intervalSeconds: 7200,
        createdAt: DateTime.utc(2025, 1, 1),
      ),
    );
    await repository.insertCard(
      _card(
        id: 'learning',
        front: 'drilling',
        back: 'drilling-back',
        learning: true,
        lastReview: DateTime.utc(2026, 1, 2),
        intervalSeconds: 600,
        createdAt: DateTime.utc(2025, 6, 1),
      ),
    );
    await repository.insertCard(
      FlashCard.fresh(
        id: 'fresh',
        topicId: 'topic',
        front: 'fresh-front',
        back: 'fresh-back',
        createdAt: DateTime.utc(2025, 7, 1),
      ),
    );

    await pumpSession(
      tester,
      repository,
      title: 'Topic',
      scopeTopicId: 'topic',
      now: () => DateTime.utc(2026, 1, 3),
      draw: neverDraw,
    );

    expect(faceText('overdue'), findsOneWidget);
    expect(faceText('overdue-back'), findsNothing);
    expect(find.text('drilling'), findsNothing);
    expect(find.text('fresh-front'), findsNothing);
    expect(
      find.text('Learning 1 of 10. 1 learned card is due.'),
      findsOneWidget,
    );
    expect(find.textContaining('waiting until'), findsNothing);
    expect((await repository.card('fresh')).learning, isFalse);
    expect(await repository.reviewsFor('due'), isEmpty);
  });

  testWidgets('a full window draws among learning cards and hides the new card', (
    tester,
  ) async {
    await insertTopic(repository, 'topic');
    final reviewed = DateTime.utc(2026, 1, 1);
    for (var i = 0; i < 10; i++) {
      await repository.insertCard(
        _card(
          id: 'c$i',
          front: 'card-$i',
          back: 'back-$i',
          learning: true,
          lastReview: reviewed.add(Duration(hours: i)),
          intervalSeconds: 600,
          createdAt: DateTime.utc(2025, 1, 1).add(Duration(minutes: i)),
        ),
      );
    }
    await repository.insertCard(
      FlashCard.fresh(
        id: 'new',
        topicId: 'topic',
        front: 'brand-new',
        back: 'brand-back',
        createdAt: DateTime.utc(2025, 6, 1),
      ),
    );
    final totals = <int>[];

    await pumpSession(
      tester,
      repository,
      title: 'Topic',
      scopeTopicId: 'topic',
      now: () => reviewed.add(const Duration(hours: 10)),
      draw: (total) {
        totals.add(total);
        return 0;
      },
    );

    expect(totals, [45]);
    expect(faceText('card-8'), findsOneWidget);
    expect(faceText('back-8'), findsNothing);
    expect(find.text('card-9'), findsNothing);
    expect(find.text('card-0'), findsNothing);
    expect(find.text('brand-new'), findsNothing);
    expect(
      find.text(
        'Learning 10 of 10. 1 new card is waiting until one of these graduates.',
      ),
      findsOneWidget,
    );
    expect((await repository.card('new')).learning, isFalse);
  });

  testWidgets('five corrects graduate a new card until its interval elapses', (
    tester,
  ) async {
    final t0 = DateTime.utc(2026, 3, 1, 8);
    await insertTopic(repository, 'topic');
    await repository.insertCard(
      FlashCard.fresh(
        id: 'c',
        topicId: 'topic',
        front: 'hola',
        back: 'hello',
        createdAt: DateTime.utc(2026, 2, 1),
      ),
    );

    await pumpSession(
      tester,
      repository,
      title: 'Topic',
      scopeTopicId: 'topic',
      now: () => t0,
      draw: neverDraw,
    );
    for (var i = 0; i < 5; i++) {
      await flip(tester);
      await press(tester, 'correct-button');
    }

    expect(find.text('Nothing is due.'), findsOneWidget);
    expect(find.byKey(const Key('wrong-button')), findsNothing);
    expect(find.byKey(const Key('edit-button')), findsNothing);
    expect(undoButton(tester).onPressed, isNotNull);
    final graduated = await repository.card('c');
    expect(graduated.intervalSeconds, 4557);
    expect(graduated.learning, isFalse);

    await pumpSession(
      tester,
      repository,
      title: 'Topic',
      scopeTopicId: 'topic',
      now: () => t0.add(const Duration(seconds: 4556)),
      draw: neverDraw,
    );
    expect(find.text('Nothing is due.'), findsOneWidget);
    expect(find.text('hola'), findsNothing);

    await pumpSession(
      tester,
      repository,
      title: 'Topic',
      scopeTopicId: 'topic',
      now: () => t0.add(const Duration(seconds: 4557)),
      draw: neverDraw,
    );
    expect(faceText('hola'), findsOneWidget);
    expect(faceText('hello'), findsNothing);
    expect(
      find.text('Learning 0 of 10. 1 learned card is due.'),
      findsOneWidget,
    );
  });

  testWidgets(
    'undo after graduation shows the card with its previous interval',
    (tester) async {
      final t0 = DateTime.utc(2026, 3, 1, 8);
      await insertTopic(repository, 'topic');
      await repository.insertCard(
        FlashCard.fresh(
          id: 'c',
          topicId: 'topic',
          front: 'hola',
          back: 'hello',
          createdAt: DateTime.utc(2026, 2, 1),
        ),
      );
      await pumpSession(
        tester,
        repository,
        title: 'Topic',
        scopeTopicId: 'topic',
        now: () => t0,
        draw: neverDraw,
      );
      for (var i = 0; i < 5; i++) {
        await flip(tester);
        await press(tester, 'correct-button');
      }

      await tester.tap(find.byKey(const Key('undo-button')));
      await tester.pump();
      await settle(tester);

      expect(find.text('Nothing is due.'), findsNothing);
      expect(faceText('hola'), findsNothing);
      expect(faceText('hello'), findsOneWidget);
      expect(flipButton(tester).onPressed, isNotNull);
      expect(correctButton(tester).onPressed, isNotNull);
      final restored = await repository.card('c');
      expect(restored.intervalSeconds, 3038);
      expect(restored.learning, isTrue);
      expect(restored.lastReview, t0);
      expect(await repository.reviewsFor('c'), hasLength(4));
    },
  );

  testWidgets('undo restores the previous card and its previous interval', (
    tester,
  ) async {
    final reviewed = DateTime.utc(2026, 1, 1);
    final now = DateTime.utc(2026, 1, 3);
    await insertTopic(repository, 'topic');
    await repository.insertCard(
      _card(
        id: 'due',
        front: 'overdue',
        back: 'overdue-back',
        learning: false,
        lastReview: reviewed,
        intervalSeconds: 7200,
        createdAt: DateTime.utc(2025, 1, 1),
      ),
    );
    await repository.insertCard(
      _card(
        id: 'learning',
        front: 'drilling',
        back: 'drilling-back',
        learning: true,
        lastReview: DateTime.utc(2026, 1, 2),
        intervalSeconds: 600,
        createdAt: DateTime.utc(2025, 6, 1),
      ),
    );

    await pumpSession(
      tester,
      repository,
      title: 'Topic',
      scopeTopicId: 'topic',
      now: () => now,
      draw: neverDraw,
    );
    await flip(tester);
    await press(tester, 'correct-button');

    expect(faceText('drilling'), findsOneWidget);
    expect(faceText('drilling-back'), findsNothing);
    expect(find.text('overdue'), findsNothing);
    expect((await repository.card('due')).intervalSeconds, 10800);

    await tester.tap(find.byKey(const Key('undo-button')));
    await tester.pump();
    await settle(tester);

    expect(faceText('overdue'), findsNothing);
    expect(faceText('overdue-back'), findsOneWidget);
    expect(find.text('drilling'), findsNothing);
    final restored = await repository.card('due');
    expect(restored.intervalSeconds, 7200);
    expect(restored.learning, isFalse);
    expect(restored.lastReview, reviewed);
    expect((await repository.card('learning')).intervalSeconds, 600);
    expect(await repository.reviewsFor('due'), isEmpty);
  });

  testWidgets('one correct then undo restores the admitted card', (
    tester,
  ) async {
    await insertTopic(repository, 'topic');
    await repository.insertCard(
      FlashCard.fresh(
        id: 'c',
        topicId: 'topic',
        front: 'hola',
        back: 'hello',
        createdAt: DateTime.utc(2026, 2, 1),
      ),
    );
    await pumpSession(
      tester,
      repository,
      title: 'Topic',
      scopeTopicId: 'topic',
      draw: neverDraw,
    );

    final admitted = await repository.card('c');
    expect(admitted.learning, isTrue);
    expect(admitted.intervalSeconds, 600);
    expect(admitted.lastReview, isNull);
    expect(await repository.reviewsFor('c'), isEmpty);
    expect(faceText('hola'), findsOneWidget);
    expect(faceText('hello'), findsNothing);

    final actions = tester.widget<AppBar>(find.byType(AppBar)).actions!;
    expect(actions.map((action) => action.key), [
      const Key('edit-button'),
      const Key('undo-button'),
    ]);
    expect(undoButton(tester).onPressed, isNull);

    await flip(tester);
    await press(tester, 'correct-button');
    expect(faceText('hello'), findsNothing);
    expect((await repository.card('c')).intervalSeconds, 900);
    expect(await repository.reviewsFor('c'), hasLength(1));

    await tester.tap(find.byKey(const Key('undo-button')));
    await tester.pump();
    await settle(tester);

    expect(faceText('hello'), findsOneWidget);
    final restored = await repository.card('c');
    expect(restored.intervalSeconds, 600);
    expect(restored.lastReview, isNull);
    expect(restored.learning, isTrue);
    expect(await repository.reviewsFor('c'), isEmpty);
    expect(undoButton(tester).onPressed, isNull);
  });

  testWidgets('two corrects then two undos walk the interval back', (
    tester,
  ) async {
    await insertTopic(repository, 'topic');
    await repository.insertCard(
      FlashCard.fresh(
        id: 'c',
        topicId: 'topic',
        front: 'hola',
        back: 'hello',
        createdAt: DateTime.utc(2026, 2, 1),
      ),
    );
    await pumpSession(
      tester,
      repository,
      title: 'Topic',
      scopeTopicId: 'topic',
      draw: neverDraw,
    );
    await flip(tester);
    await press(tester, 'correct-button');
    await flip(tester);
    await press(tester, 'correct-button');
    expect((await repository.card('c')).intervalSeconds, 1350);

    await tester.tap(find.byKey(const Key('undo-button')));
    await tester.pump();
    await settle(tester);
    expect(faceText('hello'), findsOneWidget);
    expect((await repository.card('c')).intervalSeconds, 900);

    await tester.tap(find.byKey(const Key('undo-button')));
    await tester.pump();
    await settle(tester);
    expect(faceText('hello'), findsOneWidget);
    expect((await repository.card('c')).intervalSeconds, 600);
    expect((await repository.card('c')).lastReview, isNull);
    expect(undoButton(tester).onPressed, isNull);
  });

  testWidgets('grading does nothing until the card is flipped', (tester) async {
    await insertTopic(repository, 'topic');
    await repository.insertCard(
      FlashCard.fresh(
        id: 'c',
        topicId: 'topic',
        front: 'hola',
        back: 'hello',
        createdAt: DateTime.utc(2026, 2, 1),
      ),
    );
    await pumpSession(
      tester,
      repository,
      title: 'Topic',
      scopeTopicId: 'topic',
      draw: neverDraw,
    );

    expect(correctButton(tester).onPressed, isNull);
    expect(wrongButton(tester).onPressed, isNull);
    expect(flipButton(tester).onPressed, isNotNull);
    await tester.tap(find.byKey(const Key('correct-button')));
    await tester.pump();
    await flingCard(tester, const Offset(400, 0));
    expect((await repository.card('c')).intervalSeconds, 600);
    expect(faceText('hello'), findsNothing);

    await tester.tap(find.byKey(const Key('card-face')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    expect(faceText('hello'), findsOneWidget);
    expect(faceText('hola'), findsNothing);
    expect(flipButton(tester).onPressed, isNotNull);
    expect(correctButton(tester).onPressed, isNotNull);

    await press(tester, 'correct-button');
    expect((await repository.card('c')).intervalSeconds, 900);
    expect(faceText('hello'), findsNothing);
  });

  testWidgets('flip toggles, and grading waits for one look at the answer', (
    tester,
  ) async {
    await insertTopic(repository, 'topic');
    await repository.insertCard(
      FlashCard.fresh(
        id: 'c',
        topicId: 'topic',
        front: 'hola',
        back: 'hello',
        createdAt: DateTime.utc(2026, 2, 1),
      ),
    );
    await pumpSession(
      tester,
      repository,
      title: 'Topic',
      scopeTopicId: 'topic',
      draw: neverDraw,
    );

    await flip(tester);
    expect(faceText('hello'), findsOneWidget);
    expect(sideColor(tester), const Color(0xFFB5683A));
    await flip(tester);
    expect(faceText('hola'), findsOneWidget);
    expect(faceText('hello'), findsNothing);
    expect(sideColor(tester), isNot(const Color(0xFFB5683A)));
    await flip(tester);
    expect(faceText('hello'), findsOneWidget);
    await flip(tester);
    expect(faceText('hola'), findsOneWidget);
    expect(correctButton(tester).onPressed, isNotNull);

    await flingCard(tester, const Offset(400, 0));
    expect((await repository.card('c')).intervalSeconds, 600);

    await press(tester, 'correct-button');
    expect((await repository.card('c')).intervalSeconds, 900);
  });

  testWidgets(
    'grade buttons enable after a flip that is still turning at the midpoint',
    (tester) async {
      await insertTopic(repository, 'topic');
      await repository.insertCard(
        FlashCard.fresh(
          id: 'c',
          topicId: 'topic',
          front: 'hola',
          back: 'hello',
          createdAt: DateTime.utc(2026, 2, 1),
        ),
      );
      await pumpSession(
        tester,
        repository,
        title: 'Topic',
        scopeTopicId: 'topic',
        draw: neverDraw,
      );

      await tester.tap(find.byKey(const Key('flip-button')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 160));
      expect(faceText('hello'), findsOneWidget);
      expect(faceText('hola'), findsNothing);
      expect(correctButton(tester).onPressed, isNull);
      expect(wrongButton(tester).onPressed, isNull);

      await tester.pump(const Duration(milliseconds: 200));
      expect(correctButton(tester).onPressed, isNotNull);
      expect(wrongButton(tester).onPressed, isNotNull);
      expect(flipButton(tester).onPressed, isNotNull);

      await press(tester, 'correct-button');
      expect((await repository.card('c')).intervalSeconds, 900);
    },
  );

  testWidgets(
    'a reverse face prompts with the back and grades only that face',
    (tester) async {
      final now = DateTime.utc(2026, 6, 1, 12);
      await insertTopic(repository, 'topic');
      await repository.setReverseDrill('topic', enabled: true, now: now);
      await repository.insertCard(
        _card(
          id: 'learned',
          front: 'hola',
          back: 'hello',
          learning: false,
          lastReview: now,
          intervalSeconds: 7200,
          createdAt: DateTime.utc(2024, 1, 1),
          difficulty: 1.4,
        ),
      );
      await repository.setReverseDrill('topic', enabled: true, now: now);
      await pumpSession(
        tester,
        repository,
        title: 'Topic',
        scopeTopicId: 'topic',
        now: () => now,
        draw: neverDraw,
      );

      expect(find.text('Reverse'), findsOneWidget);
      expect(faceText('hello'), findsOneWidget);
      expect(faceText('hola'), findsNothing);
      expect(correctButton(tester).onPressed, isNull);

      await flip(tester);
      expect(faceText('hola'), findsOneWidget);
      expect(faceText('hello'), findsNothing);
      expect(sideColor(tester), const Color(0xFFB5683A));
      expect(correctButton(tester).onPressed, isNotNull);

      await press(tester, 'wrong-button');
      final graded = await repository.card('learned');
      expect(graded.intervalSeconds, 7200);
      expect(graded.difficulty, 1.4);
      expect(graded.reverseIntervalSeconds, 300);
      expect(graded.reverseDifficulty, 1.01);
      expect(graded.reverseLearning, isTrue);

      await tester.tap(find.byKey(const Key('undo-button')));
      await tester.pump();
      await settle(tester);
      expect(find.text('Reverse'), findsOneWidget);
      expect(faceText('hola'), findsOneWidget);
      expect(faceText('hello'), findsNothing);
      expect(correctButton(tester).onPressed, isNotNull);
      final restored = await repository.card('learned');
      expect(restored.reverseIntervalSeconds, 600);
      expect(restored.reverseDifficulty, 1);
      expect(restored.reverseLearning, isTrue);
      expect(restored.reverseLastReview, isNull);
      expect(restored.intervalSeconds, 7200);
    },
  );

  testWidgets('a right swipe grades correct and shows the next front', (
    tester,
  ) async {
    await insertTopic(repository, 'topic');
    await repository.insertCard(
      FlashCard.fresh(
        id: 'right',
        topicId: 'topic',
        front: 'right-front',
        back: 'right-back',
        createdAt: DateTime.utc(2026, 2, 1),
      ),
    );
    await pumpSession(
      tester,
      repository,
      title: 'Topic',
      scopeTopicId: 'topic',
      draw: neverDraw,
    );
    await flip(tester);
    await flingCard(tester, const Offset(400, 0));

    expect(faceText('right-back'), findsNothing);
    expect(faceText('right-front'), findsOneWidget);
    expect((await repository.card('right')).intervalSeconds, 900);
    expect((await repository.card('right')).learning, isTrue);
  });

  testWidgets('a left swipe grades wrong and shows the next front', (
    tester,
  ) async {
    await insertTopic(repository, 'topic');
    await repository.insertCard(
      FlashCard.fresh(
        id: 'left',
        topicId: 'topic',
        front: 'left-front',
        back: 'left-back',
        createdAt: DateTime.utc(2026, 2, 1),
      ),
    );
    await pumpSession(
      tester,
      repository,
      title: 'Topic',
      scopeTopicId: 'topic',
      draw: neverDraw,
    );
    await flip(tester);
    await flingCard(tester, const Offset(-400, 0));

    expect(faceText('left-back'), findsNothing);
    expect(faceText('left-front'), findsOneWidget);
    final wrong = await repository.card('left');
    expect(wrong.intervalSeconds, 300);
    expect(wrong.difficulty, 1.01);
    expect(wrong.learning, isTrue);
  });

  testWidgets(
    'a parent scope includes a child card and a sibling scope does not',
    (tester) async {
      await insertTopic(repository, 'parent');
      await insertTopic(repository, 'child', parentId: 'parent');
      await insertTopic(repository, 'sibling', parentId: 'parent');
      await repository.insertCard(
        FlashCard.fresh(
          id: 'child-card',
          topicId: 'child',
          front: 'child-front',
          back: 'child-back',
          createdAt: DateTime.utc(2026, 2, 1),
        ),
      );

      await pumpSession(
        tester,
        repository,
        title: 'Parent',
        scopeTopicId: 'parent',
        draw: neverDraw,
      );
      expect(faceText('child-front'), findsOneWidget);
      expect((await repository.card('child-card')).learning, isTrue);

      await pumpSession(
        tester,
        repository,
        title: 'Sibling',
        scopeTopicId: 'sibling',
        draw: neverDraw,
      );
      expect(find.text('Nothing is due.'), findsOneWidget);
      expect(find.text('child-front'), findsNothing);
    },
  );

  testWidgets(
    'a tag filter keeps a matching card in a subtopic and drops the rest',
    (tester) async {
      await insertTopic(repository, 'parent');
      await insertTopic(repository, 'child', parentId: 'parent');
      await repository.insertTag(id: 'verb', name: 'Verb');
      await repository.insertCard(
        FlashCard.fresh(
          id: 'parent-card',
          topicId: 'parent',
          front: 'parent-front',
          back: 'parent-back',
          createdAt: DateTime.utc(2026, 1, 1),
        ),
      );
      await repository.insertCard(
        FlashCard.fresh(
          id: 'child-card',
          topicId: 'child',
          front: 'child-front',
          back: 'child-back',
          createdAt: DateTime.utc(2026, 2, 1),
        ),
      );
      await repository.setCardTags('child-card', {'verb'});

      await pumpSession(
        tester,
        repository,
        title: 'Parent',
        scopeTopicId: 'parent',
        draw: neverDraw,
      );
      expect(faceText('parent-front'), findsOneWidget);
      expect(faceText('child-front'), findsNothing);

      await pumpSession(
        tester,
        repository,
        title: 'Verb',
        scopeTopicId: 'parent',
        tagIds: {'verb'},
        draw: neverDraw,
      );
      expect(faceText('child-front'), findsOneWidget);
      expect(faceText('parent-front'), findsNothing);
    },
  );

  testWidgets('a whole-library tag filter leaves untagged cards out', (
    tester,
  ) async {
    await insertTopic(repository, 'parent');
    await insertTopic(repository, 'child', parentId: 'parent');
    await repository.insertTag(id: 'verb', name: 'Verb');
    await repository.insertCard(
      FlashCard.fresh(
        id: 'parent-card',
        topicId: 'parent',
        front: 'parent-front',
        back: 'parent-back',
        createdAt: DateTime.utc(2026, 1, 1),
      ),
    );
    await repository.insertCard(
      FlashCard.fresh(
        id: 'child-card',
        topicId: 'child',
        front: 'child-front',
        back: 'child-back',
        createdAt: DateTime.utc(2026, 2, 1),
      ),
    );
    await repository.setCardTags('child-card', {'verb'});

    await pumpSession(
      tester,
      repository,
      title: 'Verb',
      tagIds: {'verb'},
      draw: neverDraw,
    );
    expect(faceText('child-front'), findsOneWidget);
    expect(find.text('parent-front'), findsNothing);
  });

  testWidgets('edit changes the front and keeps the schedule and the flip', (
    tester,
  ) async {
    await insertTopic(repository, 'topic');
    await repository.insertCard(
      FlashCard.fresh(
        id: 'c',
        topicId: 'topic',
        front: 'hola',
        back: 'hello',
        createdAt: DateTime.utc(2026, 2, 1),
      ),
    );
    await pumpSession(
      tester,
      repository,
      title: 'Topic',
      scopeTopicId: 'topic',
      draw: neverDraw,
    );
    await flip(tester);
    expect(faceText('hello'), findsOneWidget);

    await tester.tap(find.byKey(const Key('edit-button')));
    await elapse(tester);
    await tester.enterText(find.byKey(const Key('card-front')), 'buenas');
    await tester.tap(appBarText('Save'));
    await settle(tester);

    expect(faceText('buenas'), findsNothing);
    expect(faceText('hello'), findsOneWidget);
    final edited = await repository.card('c');
    expect(edited.front, 'buenas');
    expect(edited.back, 'hello');
    expect(edited.intervalSeconds, 600);
    expect(edited.learning, isTrue);
    expect(edited.lastReview, isNull);
    expect(await repository.reviewsFor('c'), isEmpty);
  });

  testWidgets('deleting the card drops it and its undo entries', (
    tester,
  ) async {
    await insertTopic(repository, 'topic');
    await repository.insertCard(
      FlashCard.fresh(
        id: 'c',
        topicId: 'topic',
        front: 'hola',
        back: 'hello',
        createdAt: DateTime.utc(2026, 2, 1),
      ),
    );
    await pumpSession(
      tester,
      repository,
      title: 'Topic',
      scopeTopicId: 'topic',
      draw: neverDraw,
    );
    await flip(tester);
    await press(tester, 'correct-button');
    expect(undoButton(tester).onPressed, isNotNull);

    await tester.tap(find.byKey(const Key('edit-button')));
    await elapse(tester);
    await tester.tap(find.text('Delete card'));
    await elapse(tester);
    await tester.tap(find.text('Delete'));
    await settle(tester);

    expect(find.text('Nothing is due.'), findsOneWidget);
    expect(undoButton(tester).onPressed, isNull);
    expect(await repository.listCards(), isEmpty);
  });
}

int neverDraw(int total) => throw StateError('draw was called with $total');

FlashCard _card({
  required String id,
  required String front,
  required String back,
  required bool learning,
  required DateTime lastReview,
  required int intervalSeconds,
  required DateTime createdAt,
  double difficulty = 1,
}) {
  return FlashCard(
    id: id,
    topicId: 'topic',
    front: front,
    back: back,
    learning: learning,
    lastReview: lastReview,
    intervalSeconds: intervalSeconds,
    difficulty: difficulty,
    createdAt: createdAt,
  );
}

Future<void> insertTopic(
  LibraryRepository repository,
  String id, {
  String? parentId,
}) {
  return repository.insertTopic(
    id: id,
    name: id,
    parentId: parentId,
    createdAt: DateTime.utc(2024, 1, 1),
  );
}

Future<void> pumpSession(
  WidgetTester tester,
  LibraryRepository repository, {
  required String title,
  String? scopeTopicId,
  Set<String>? tagIds,
  bool untagged = false,
  DateTime Function()? now,
  WeightDraw? draw,
}) async {
  tester.view.physicalSize = const Size(390, 844);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  await tester.pumpWidget(
    LibraryScope(
      repository: repository,
      child: MaterialApp(
        home: StudySessionScreen(
          key: UniqueKey(),
          title: title,
          scopeTopicId: scopeTopicId,
          tagIds: tagIds,
          untagged: untagged,
          now: now,
          draw: draw,
        ),
      ),
    ),
  );
  await tester.pump();
  await settle(tester);
}

Future<void> elapse(WidgetTester tester) async {
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 400));
}

Future<void> settle(WidgetTester tester) async {
  FocusManager.instance.primaryFocus?.unfocus();
  await tester.pumpAndSettle(
    const Duration(milliseconds: 50),
    EnginePhase.sendSemanticsUpdate,
    const Duration(seconds: 3),
  );
}

Future<void> flip(WidgetTester tester) async {
  await tester.tap(find.byKey(const Key('flip-button')));
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 400));
}

Color sideColor(WidgetTester tester) {
  final card = tester.widget<Card>(find.byKey(const Key('card-face')));
  return (card.shape! as RoundedRectangleBorder).side.color;
}

Future<void> press(WidgetTester tester, String key) async {
  await tester.tap(find.byKey(Key(key)));
  await tester.pump();
  await settle(tester);
}

Future<void> flingCard(WidgetTester tester, Offset offset) async {
  await tester.fling(find.byKey(const Key('card-face')), offset, 1200);
  await tester.pump();
  await settle(tester);
}

Finder faceText(String text) {
  return find.descendant(
    of: find.byKey(const Key('card-face')),
    matching: find.text(text),
  );
}

Finder appBarText(String text) {
  return find.descendant(
    of: find.byType(AppBar).last,
    matching: find.text(text),
  );
}

IconButton undoButton(WidgetTester tester) {
  return tester.widget<IconButton>(find.byKey(const Key('undo-button')));
}

ButtonStyleButton flipButton(WidgetTester tester) {
  return tester.widget<ButtonStyleButton>(find.byKey(const Key('flip-button')));
}

ButtonStyleButton correctButton(WidgetTester tester) {
  return tester.widget<ButtonStyleButton>(
    find.byKey(const Key('correct-button')),
  );
}

ButtonStyleButton wrongButton(WidgetTester tester) {
  return tester.widget<ButtonStyleButton>(
    find.byKey(const Key('wrong-button')),
  );
}
