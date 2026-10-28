import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rhythm_method_flashcards/app.dart';
import 'package:rhythm_method_flashcards/data/database.dart';
import 'package:rhythm_method_flashcards/data/library_repository.dart';
import 'package:rhythm_method_flashcards/domain/scheduler.dart';

void main() {
  late LibraryDatabase database;
  late LibraryRepository repository;

  setUp(() {
    database = LibraryDatabase(NativeDatabase.memory());
    repository = LibraryRepository(database);
  });

  tearDown(() => database.close());

  testWidgets('opens on the README defaults', (tester) async {
    await pumpApp(tester, repository);
    await openSettings(tester);

    expect(fieldText(tester, 'correct-factor'), '1.5');
    expect(fieldText(tester, 'wrong-factor'), '0.5');
    expect(fieldText(tester, 'difficulty-factor'), '0.01');
    expect(fieldText(tester, 'learning-window'), '10');
    expect(fieldText(tester, 'learned-threshold'), '1');
  });

  testWidgets('a correct factor of 1 or below is rejected', (tester) async {
    await pumpApp(tester, repository);
    await openSettings(tester);

    for (final value in ['1', '1.0', '0.5']) {
      await saveField(tester, 'correct-factor', value);
      expect(find.text('Must be greater than 1.'), findsOneWidget);
      expect((await repository.loadSettings()).correctFactor, 1.5);
    }

    await saveField(tester, 'correct-factor', '1.5');
    expect(find.text('Must be greater than 1.'), findsNothing);
    expect((await repository.loadSettings()).correctFactor, 1.5);
  });

  testWidgets('the other four constraints are rejected in the form', (
    tester,
  ) async {
    await pumpApp(tester, repository);
    await openSettings(tester);

    await saveField(tester, 'wrong-factor', '1');
    expect(
      find.text('Must be greater than 0 and less than 1.'),
      findsOneWidget,
    );
    await saveField(tester, 'wrong-factor', '0');
    expect(
      find.text('Must be greater than 0 and less than 1.'),
      findsOneWidget,
    );
    await saveField(tester, 'wrong-factor', '0.5');

    await saveField(tester, 'difficulty-factor', '-0.01');
    expect(find.text('Must be zero or greater.'), findsOneWidget);
    await saveField(tester, 'difficulty-factor', '0.01');

    await saveField(tester, 'learning-window', '0');
    expect(find.text('Must be a whole number of at least 1.'), findsOneWidget);
    await saveField(tester, 'learning-window', '10.5');
    expect(find.text('Enter a whole number.'), findsOneWidget);
    await saveField(tester, 'learning-window', '10');

    await saveField(tester, 'learned-threshold', '0');
    expect(find.text('Must be greater than 0.'), findsOneWidget);
    await saveField(tester, 'learned-threshold', '1');

    final settings = await repository.loadSettings();
    expect(settings.wrongFactor, 0.5);
    expect(settings.difficultyFactor, 0.01);
    expect(settings.learningWindowSize, 10);
    expect(settings.learnedThreshold, const Duration(hours: 1));
  });

  testWidgets('saved values survive leaving the settings tab', (tester) async {
    await pumpApp(tester, repository);
    await openSettings(tester);
    await saveField(tester, 'correct-factor', '2');
    await saveField(tester, 'wrong-factor', '0.25');
    await saveField(tester, 'difficulty-factor', '0');
    await saveField(tester, 'learning-window', '3');
    await saveField(tester, 'learned-threshold', '2');

    await tester.tap(
      find.descendant(
        of: find.byType(NavigationBar),
        matching: find.text('Library'),
      ),
    );
    await settle(tester);
    await openSettings(tester);

    expect(fieldText(tester, 'correct-factor'), '2');
    expect(fieldText(tester, 'wrong-factor'), '0.25');
    expect(fieldText(tester, 'difficulty-factor'), '0');
    expect(fieldText(tester, 'learning-window'), '3');
    expect(fieldText(tester, 'learned-threshold'), '2');
    final settings = await repository.loadSettings();
    expect(settings.correctFactor, 2);
    expect(settings.wrongFactor, 0.25);
    expect(settings.difficultyFactor, 0);
    expect(settings.learningWindowSize, 3);
    expect(settings.learnedThreshold, const Duration(hours: 2));
  });

  testWidgets('a window of 1 drills one card until it graduates', (
    tester,
  ) async {
    await repository.insertTopic(id: 'topic', name: 'Spanish');
    await repository.insertCard(
      FlashCard.fresh(
        id: 'first',
        topicId: 'topic',
        front: 'hola',
        back: 'hello',
        createdAt: DateTime.utc(2026, 1, 1),
      ),
    );
    await repository.insertCard(
      FlashCard.fresh(
        id: 'second',
        topicId: 'topic',
        front: 'adios',
        back: 'goodbye',
        createdAt: DateTime.utc(2026, 1, 2),
      ),
    );
    await pumpApp(tester, repository);
    await openSettings(tester);
    await saveField(tester, 'learning-window', '1');
    expect((await repository.loadSettings()).learningWindowSize, 1);

    await openStudyAll(tester);
    expect(faceText('hola'), findsOneWidget);
    expect(find.text('adios'), findsNothing);
    expect(
      find.text(
        'Learning 1 of 1. 1 new card is waiting until one of these graduates.',
      ),
      findsOneWidget,
    );
    expect((await repository.card('second')).isNew, isTrue);

    for (var i = 0; i < 4; i++) {
      await flip(tester);
      await press(tester, 'correct-button');
      expect(faceText('hola'), findsOneWidget);
      expect(find.text('adios'), findsNothing);
      expect((await repository.card('second')).isNew, isTrue);
    }
    expect((await repository.card('first')).intervalSeconds, 3038);
    expect((await repository.card('first')).learning, isTrue);

    await flip(tester);
    await press(tester, 'correct-button');
    expect(faceText('adios'), findsOneWidget);
    expect(find.text('hola'), findsNothing);
    expect((await repository.card('first')).learning, isFalse);
    expect((await repository.card('first')).intervalSeconds, 4557);
    expect((await repository.card('second')).learning, isTrue);
    expect(find.text('Learning 1 of 1.'), findsOneWidget);
  });

  testWidgets('a new correct factor applies to the next grade only', (
    tester,
  ) async {
    await repository.insertTopic(id: 'topic', name: 'Spanish');
    await repository.insertCard(
      FlashCard.fresh(
        id: 'c',
        topicId: 'topic',
        front: 'hola',
        back: 'hello',
        createdAt: DateTime.utc(2026, 1, 1),
      ),
    );
    await pumpApp(tester, repository);
    await openStudyAll(tester);
    await flip(tester);
    await press(tester, 'correct-button');
    expect((await repository.card('c')).intervalSeconds, 900);
    expect((await repository.reviewsFor('c')).single.record.intervalAfter, 900);

    await goBack(tester);
    await openSettings(tester);
    await saveField(tester, 'correct-factor', '2');

    final past = await repository.reviewsFor('c');
    expect(past, hasLength(1));
    expect(past.single.record.intervalAfter, 900);
    expect(past.single.record.intervalBefore, 600);

    await openStudyAll(tester);
    await flip(tester);
    await press(tester, 'correct-button');
    expect((await repository.card('c')).intervalSeconds, 1800);

    final reviews = await repository.reviewsFor('c');
    expect(reviews, hasLength(2));
    expect(reviews.first.record.intervalAfter, 900);
    expect(reviews.last.record.intervalAfter, 1800);
  });
}

Future<void> pumpApp(WidgetTester tester, LibraryRepository repository) async {
  tester.view.physicalSize = const Size(390, 844);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  await tester.pumpWidget(RhythmMethodApp(repository: repository));
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

Future<void> openSettings(WidgetTester tester) async {
  await tester.tap(
    find.descendant(
      of: find.byType(NavigationBar),
      matching: find.text('Settings'),
    ),
  );
  await settle(tester);
}

Future<void> openStudyAll(WidgetTester tester) async {
  await tester.tap(
    find.descendant(
      of: find.byType(NavigationBar),
      matching: find.text('Study'),
    ),
  );
  await settle(tester);
  await tester.tap(find.widgetWithText(FilledButton, 'Study all'));
  await settle(tester);
}

Future<void> saveField(WidgetTester tester, String key, String value) async {
  await tester.enterText(find.byKey(Key(key)), value);
  await tester.tap(find.byKey(const Key('save-settings')));
  await elapse(tester);
  await settle(tester);
}

Future<void> flip(WidgetTester tester) async {
  await tester.tap(find.byKey(const Key('flip-button')));
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 400));
}

Future<void> press(WidgetTester tester, String key) async {
  await tester.tap(find.byKey(Key(key)));
  await tester.pump();
  await settle(tester);
}

Future<void> goBack(WidgetTester tester) async {
  await tester.tap(
    find.descendant(
      of: find.byType(AppBar).last,
      matching: find.byTooltip('Back'),
    ),
  );
  await settle(tester);
}

String fieldText(WidgetTester tester, String key) {
  return tester.widget<TextField>(find.byKey(Key(key))).controller!.text;
}

Finder faceText(String text) {
  return find.descendant(
    of: find.byKey(const Key('card-face')),
    matching: find.text(text),
  );
}
