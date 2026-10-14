import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rhythm_method_flashcards/app.dart';
import 'package:rhythm_method_flashcards/data/database.dart';
import 'package:rhythm_method_flashcards/data/library_repository.dart';

void main() {
  group('in memory', () {
    late LibraryDatabase database;
    late LibraryRepository repository;

    setUp(() {
      database = LibraryDatabase(NativeDatabase.memory());
      repository = LibraryRepository(database);
    });

    tearDown(() => database.close());

    testWidgets('renames a topic and rejects a blank name', (tester) async {
      await pumpApp(tester, repository);

      await addRootTopic(tester, 'Spanish', fromEmpty: true);
      expect(find.text('0 subtopics · 0 cards'), findsOneWidget);
      expect(find.byTooltip('Move up'), findsNothing);

      await openTopic(tester, 'Spanish');
      expect(find.text('Add a card to this topic.'), findsOneWidget);
      expect(find.byTooltip('Move up'), findsNothing);

      await renameTopic(tester, 'Castilian');
      await tester.tap(find.byTooltip('Rename topic'));
      await elapse(tester);
      await tester.enterText(find.byKey(const Key('name-field')), '   ');
      await tester.tap(find.text('Save'));
      await tester.pump();
      expect(find.byKey(const Key('name-field')), findsOneWidget);
      await tester.tap(find.text('Cancel'));
      await settle(tester);
      expect(appBarText('Castilian'), findsOneWidget);

      await goBack(tester);
      expect(find.text('Castilian'), findsOneWidget);
      expect(find.text('Spanish'), findsNothing);
    });

    testWidgets('moves a topic up', (tester) async {
      await pumpApp(tester, repository);

      await addRootTopic(tester, 'Alpha', fromEmpty: true);
      await addRootTopic(tester, 'Beta');

      expect(find.byTooltip('Move up'), findsNWidgets(2));
      expect(topOf('Alpha', tester), lessThan(topOf('Beta', tester)));
      expect(moveButton(tester, 'Alpha', 'Move up').onPressed, isNull);
      expect(moveButton(tester, 'Alpha', 'Move down').onPressed, isNotNull);
      expect(moveButton(tester, 'Beta', 'Move down').onPressed, isNull);

      await tester.tap(moveButtonFinder('Beta', 'Move up'));
      await settle(tester);

      expect(topOf('Beta', tester), lessThan(topOf('Alpha', tester)));
      expect(
        (await repository.listTopics()).map((topic) => topic.name).toList(),
        ['Beta', 'Alpha'],
      );
    });

    testWidgets('refuses to delete a topic that still has a subtopic', (
      tester,
    ) async {
      await pumpApp(tester, repository);

      await addRootTopic(tester, 'Languages', fromEmpty: true);
      await openTopic(tester, 'Languages');
      await addSubtopic(tester, 'Spanish');

      await tester.tap(find.byTooltip('Delete topic'));
      await settle(tester);
      await tester.tap(find.text('Delete'));
      await settle(tester);

      expect(find.textContaining('still has subtopics'), findsOneWidget);
      expect(appBarText('Languages'), findsOneWidget);
      expect(find.text('Spanish'), findsOneWidget);

      await goBack(tester);
      expect(find.text('Languages'), findsOneWidget);
    });

    testWidgets('refuses to delete a topic that still has a card', (
      tester,
    ) async {
      await pumpApp(tester, repository);

      await addRootTopic(tester, 'Temp', fromEmpty: true);
      await openTopic(tester, 'Temp');
      await addCard(tester, 'hola', 'hello');

      await tester.tap(find.byTooltip('Delete topic'));
      await settle(tester);
      await tester.tap(find.text('Delete'));
      await settle(tester);

      expect(find.textContaining('still has cards'), findsOneWidget);
      expect(appBarText('Temp'), findsOneWidget);
      expect(find.text('hola'), findsOneWidget);
    });

    testWidgets('deletes an empty topic', (tester) async {
      await pumpApp(tester, repository);

      await addRootTopic(tester, 'Empty', fromEmpty: true);
      await openTopic(tester, 'Empty');
      await tester.tap(find.byTooltip('Delete topic'));
      await settle(tester);
      await tester.tap(find.text('Delete'));
      await settle(tester);

      expect(find.text('Empty'), findsNothing);
      expect(find.text('Add a topic, then add a card.'), findsOneWidget);
    });

    testWidgets(
      'edits card text without changing the schedule and deletes it',
      (tester) async {
        await pumpApp(tester, repository);

        await addRootTopic(tester, 'Spanish', fromEmpty: true);
        await openTopic(tester, 'Spanish');

        await tester.tap(find.text('Add card'));
        await elapse(tester);
        await tester.tap(appBarText('Save'));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 400));
        expect(
          find.text('Enter a front and a back.').hitTestable(),
          findsOneWidget,
        );
        expect(appBarText('New card'), findsOneWidget);
        await tester.pump(const Duration(seconds: 5));
        await settle(tester);
        await goBack(tester);

        await addCard(tester, 'hola', 'hello');
        final before = (await repository.listCards()).single;

        await tester.tap(find.text('hola'));
        await elapse(tester);
        expect(appBarText('Edit card'), findsOneWidget);
        await tester.enterText(find.byKey(const Key('card-front')), 'buenas');
        await tester.tap(appBarText('Save'));
        await settle(tester);

        expect(find.text('buenas'), findsOneWidget);
        final after = await repository.card(before.id);
        expect(after.front, 'buenas');
        expect(after.back, 'hello');
        expect(after.intervalSeconds, before.intervalSeconds);
        expect(after.difficulty, before.difficulty);
        expect(after.learning, before.learning);
        expect(after.lastReview, before.lastReview);
        expect(after.createdAt, before.createdAt);

        await tester.tap(find.text('buenas'));
        await elapse(tester);
        await tester.tap(find.text('Delete card'));
        await settle(tester);
        await tester.tap(find.text('Delete'));
        await settle(tester);

        expect(find.text('buenas'), findsNothing);
        expect(find.text('Add a card to this topic.'), findsOneWidget);
        expect(await repository.listCards(), isEmpty);
      },
    );

    testWidgets('study shows the card front until it is flipped', (
      tester,
    ) async {
      await pumpApp(tester, repository);

      await addRootTopic(tester, 'Spanish', fromEmpty: true);
      await openTopic(tester, 'Spanish');
      await addCard(tester, 'hola', 'hello');
      await tester.tap(find.widgetWithText(FilledButton, 'Study'));
      await settle(tester);

      final face = find.byKey(const Key('card-face'));
      expect(
        find.descendant(of: face, matching: find.text('hola')),
        findsOneWidget,
      );
      expect(
        find.descendant(of: face, matching: find.text('hello')),
        findsNothing,
      );
      expect(find.text('Learning 1 of 10.'), findsOneWidget);
      expect(appBarText('Spanish'), findsOneWidget);

      await tester.tap(find.byKey(const Key('flip-button')));
      await settle(tester);
      expect(
        find.descendant(of: face, matching: find.text('hello')),
        findsOneWidget,
      );
    });
  });

  testWidgets('a topic, a subtopic, and cards survive closing the database', (
    tester,
  ) async {
    // Directory work uses real I/O. Widget tests run on a fake clock, so this
    // has to leave that clock or the future never completes.
    final temp = (await tester.runAsync(
      () => Directory.systemTemp.createTemp('rhythm-method-ui-'),
    ))!;
    addTearDown(() {
      if (temp.existsSync()) temp.deleteSync(recursive: true);
    });
    final path = '${temp.path}/library.sqlite';
    final fileDatabase = LibraryDatabase(NativeDatabase(File(path)));
    var fileClosed = false;
    addTearDown(() async {
      if (!fileClosed) await tester.runAsync(fileDatabase.close);
    });
    final fileRepository = LibraryRepository(fileDatabase);

    await pumpApp(tester, fileRepository);
    await addRootTopic(tester, 'Spanish', fromEmpty: true);
    await openTopic(tester, 'Spanish');
    await addCard(tester, 'hola', 'hello');
    await addCard(tester, 'adios', 'goodbye');
    await addSubtopic(tester, 'Verbs');
    await openTopic(tester, 'Verbs');
    await addCard(tester, 'ser', 'to be');
    await goBack(tester);

    expect(find.text('hola'), findsOneWidget);
    expect(find.text('adios'), findsOneWidget);
    expect(find.text('ser'), findsNothing);
    expect(find.text('0 subtopics · 1 card'), findsOneWidget);

    await goBack(tester);
    expect(find.text('1 subtopic · 2 cards'), findsOneWidget);

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
    await tester.runAsync(fileRepository.close);
    fileClosed = true;

    final reopenedDatabase = LibraryDatabase(NativeDatabase(File(path)));
    addTearDown(() async {
      await tester.runAsync(reopenedDatabase.close);
    });
    final reopened = LibraryRepository(reopenedDatabase);
    await pumpApp(tester, reopened);

    expect(find.text('Spanish'), findsOneWidget);
    expect(find.text('1 subtopic · 2 cards'), findsOneWidget);

    final topics = (await tester.runAsync(reopened.listTopics))!;
    final spanish = topics.singleWhere((topic) => topic.name == 'Spanish');
    final verbs = topics.singleWhere((topic) => topic.name == 'Verbs');
    expect(spanish.parentId, isNull);
    expect(verbs.parentId, spanish.id);

    await openTopic(tester, 'Spanish');
    expect(find.text('hola'), findsOneWidget);
    expect(find.text('hello'), findsOneWidget);
    expect(find.text('adios'), findsOneWidget);
    expect(find.text('goodbye'), findsOneWidget);
    expect(find.text('Verbs'), findsOneWidget);
    expect(find.text('ser'), findsNothing);

    await openTopic(tester, 'Verbs');
    expect(find.text('ser'), findsOneWidget);
    expect(find.text('to be'), findsOneWidget);

    final cards = (await tester.runAsync(reopened.listCards))!;
    expect(cards.map((card) => card.front).toSet(), {'hola', 'adios', 'ser'});
    expect(cards.singleWhere((card) => card.front == 'ser').topicId, verbs.id);
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

/// Pumps a route or dialog open without waiting for a focused field to idle.
Future<void> elapse(WidgetTester tester) async {
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 400));
}

/// Waits out route animations. A focused text field keeps scheduling frames,
/// so drop focus first and give up after a few seconds.
Future<void> settle(WidgetTester tester) async {
  FocusManager.instance.primaryFocus?.unfocus();
  await tester.pumpAndSettle(
    const Duration(milliseconds: 50),
    EnginePhase.sendSemanticsUpdate,
    const Duration(seconds: 3),
  );
}

Future<void> addRootTopic(
  WidgetTester tester,
  String name, {
  bool fromEmpty = false,
}) async {
  if (fromEmpty) {
    await tester.tap(find.widgetWithText(FilledButton, 'Add topic'));
  } else {
    await tester.tap(find.byTooltip('Add topic'));
  }
  await elapse(tester);
  await enterName(tester, name);
}

Future<void> enterName(WidgetTester tester, String name) async {
  await tester.enterText(find.byKey(const Key('name-field')), name);
  await tester.tap(find.text('Save'));
  await settle(tester);
}

Future<void> openTopic(WidgetTester tester, String name) async {
  await tester.tap(find.text(name).hitTestable());
  await settle(tester);
  expect(appBarText(name), findsOneWidget);
}

Future<void> addSubtopic(WidgetTester tester, String name) async {
  await tester.tap(find.text('Add subtopic'));
  await elapse(tester);
  await enterName(tester, name);
}

Future<void> addCard(WidgetTester tester, String front, String back) async {
  await tester.tap(find.text('Add card'));
  await elapse(tester);
  await tester.enterText(find.byKey(const Key('card-front')), front);
  await tester.enterText(find.byKey(const Key('card-back')), back);
  await tester.tap(appBarText('Save'));
  await settle(tester);
}

Future<void> renameTopic(WidgetTester tester, String name) async {
  await tester.tap(find.byTooltip('Rename topic'));
  await elapse(tester);
  await enterName(tester, name);
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

Finder appBarText(String text) {
  return find.descendant(
    of: find.byType(AppBar).last,
    matching: find.text(text),
  );
}

double topOf(String name, WidgetTester tester) {
  return tester.getTopLeft(find.text(name)).dy;
}

Finder moveButtonFinder(String name, String tooltip) {
  return find.ancestor(
    of: find.descendant(
      of: find.widgetWithText(ListTile, name),
      matching: find.byTooltip(tooltip),
    ),
    matching: find.byType(IconButton),
  );
}

IconButton moveButton(WidgetTester tester, String name, String tooltip) {
  return tester.widget<IconButton>(moveButtonFinder(name, tooltip));
}
