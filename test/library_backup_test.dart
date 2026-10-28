import 'dart:convert';

import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rhythm_method_flashcards/data/database.dart';
import 'package:rhythm_method_flashcards/data/library_backup.dart';
import 'package:rhythm_method_flashcards/data/library_repository.dart';
import 'package:rhythm_method_flashcards/domain/scheduler.dart';
import 'package:rhythm_method_flashcards/features/library/library_scope.dart';
import 'package:rhythm_method_flashcards/features/settings/settings_screen.dart';

void main() {
  test('backup json contains topics, scheduler card fields, and settings', () {
    final created = DateTime.utc(2026, 3, 1, 15, 30);
    final reviewed = DateTime.utc(2026, 6, 1, 12);
    final json = libraryBackupJson(
      topics: [
        BackupTopic(
          id: 'parent',
          name: 'Parent',
          parentId: null,
          position: 0,
          createdAt: created,
        ),
        BackupTopic(
          id: 'child',
          name: 'Child',
          parentId: 'parent',
          position: 1,
          createdAt: created.add(const Duration(days: 1)),
        ),
      ],
      cards: [
        FlashCard.fresh(
          id: 'new',
          topicId: 'child',
          front: 'hola',
          back: 'hello',
          createdAt: created,
        ),
        FlashCard(
          id: 'old',
          topicId: 'parent',
          front: 'adios',
          back: 'goodbye',
          learning: true,
          lastReview: reviewed,
          intervalSeconds: 300,
          difficulty: 1.25,
          createdAt: created.add(const Duration(hours: 1)),
        ),
      ],
      settings: SchedulerParameters(
        correctFactor: 2,
        wrongFactor: 0.25,
        difficultyFactor: 0,
        learningWindowSize: 3,
        learnedThreshold: const Duration(hours: 2),
      ),
    );

    expect(json, startsWith('{\n  "version": 2'));
    final decoded = jsonDecode(json) as Map<String, Object?>;
    expect(decoded.keys.toList(), ['version', 'topics', 'cards', 'settings']);

    final topics = (decoded['topics']! as List<Object?>)
        .cast<Map<String, Object?>>();
    expect(topics[0]['parent_id'], isNull);
    expect(topics[0]['reverse_drill'], isFalse);
    expect(topics[0]['created_at'], '2026-03-01T15:30:00.000Z');
    expect(topics[1]['id'], 'child');
    expect(topics[1]['parent_id'], 'parent');
    expect(topics[1]['position'], 1);
    expect(topics[1]['created_at'], '2026-03-02T15:30:00.000Z');

    final cards = (decoded['cards']! as List<Object?>)
        .cast<Map<String, Object?>>();
    expect(cards[0].keys.toList(), [
      'id',
      'topic_id',
      'front',
      'back',
      'learning',
      'last_review',
      'interval',
      'difficulty',
      'created_at',
      'reverse',
    ]);
    expect(cards[0]['front'], 'hola');
    expect(cards[0]['back'], 'hello');
    expect(cards[0]['topic_id'], 'child');
    expect(cards[0]['learning'], isFalse);
    expect(cards[0]['last_review'], isNull);
    expect(cards[0]['interval'], 600);
    expect(cards[0]['difficulty'], 1);
    expect(cards[0]['created_at'], '2026-03-01T15:30:00.000Z');
    expect(cards[0]['reverse'], isNull);

    expect(cards[1]['front'], 'adios');
    expect(cards[1]['learning'], isTrue);
    expect(cards[1]['last_review'], '2026-06-01T12:00:00.000Z');
    expect(cards[1]['interval'], 300);
    expect(cards[1]['difficulty'], 1.25);

    expect(decoded['settings'], {
      'correct_factor': 2,
      'wrong_factor': 0.25,
      'difficulty_factor': 0,
      'learning_window_size': 3,
      'learned_threshold': 7200,
    });
  });

  test(
    'a stored library exports topic creation times and omits reviews',
    () async {
      final database = LibraryDatabase(NativeDatabase.memory());
      final repository = LibraryRepository(database);
      addTearDown(database.close);

      final parentCreated = DateTime.utc(2026, 3, 1, 15, 30);
      final childCreated = DateTime.utc(2026, 3, 2, 15, 30);
      final later = DateTime.utc(2026, 4, 1);
      final reviewed = DateTime.utc(2026, 6, 1, 12);
      await repository.insertTopic(
        id: 'alpha',
        name: 'Alpha',
        createdAt: parentCreated,
      );
      await repository.insertTopic(
        id: 'child',
        name: 'Child',
        parentId: 'alpha',
        createdAt: childCreated,
      );
      await repository.insertTopic(id: 'beta', name: 'Beta', createdAt: later);
      await repository.insertCard(
        FlashCard.fresh(
          id: 'hola',
          topicId: 'alpha',
          front: 'hola',
          back: 'hello',
          createdAt: parentCreated,
        ),
      );
      await repository.insertCard(
        FlashCard.fresh(
          id: 'adios',
          topicId: 'beta',
          front: 'adios',
          back: 'goodbye',
          createdAt: later,
        ),
      );
      await repository.admit('hola');
      await repository.grade(
        cardId: 'hola',
        outcome: GradeOutcome.wrong,
        now: reviewed,
      );
      await repository.saveSettings(
        SchedulerParameters(
          correctFactor: 2,
          wrongFactor: 0.25,
          difficultyFactor: 0,
          learningWindowSize: 3,
          learnedThreshold: const Duration(hours: 2),
        ),
      );

      expect(await repository.reviewsFor('hola'), isNotEmpty);
      final json = await repository.backupJson();
      final decoded = jsonDecode(json) as Map<String, Object?>;
      expect(decoded.containsKey('reviews'), isFalse);
      expect(json.contains('interval_before'), isFalse);

      final topics = (decoded['topics']! as List<Object?>)
          .cast<Map<String, Object?>>();
      expect(topics.map((topic) => topic['id']).toList(), [
        'alpha',
        'child',
        'beta',
      ]);
      expect(topics[0]['created_at'], '2026-03-01T15:30:00.000Z');
      expect(topics[0]['position'], 0);
      expect(topics[1]['parent_id'], 'alpha');
      expect(topics[1]['created_at'], '2026-03-02T15:30:00.000Z');
      expect(topics[2]['parent_id'], isNull);
      expect(topics[2]['position'], 1);

      final cards = (decoded['cards']! as List<Object?>)
          .cast<Map<String, Object?>>();
      expect(cards.map((card) => card['id']).toList(), ['hola', 'adios']);
      final stored = await repository.card('hola');
      expect(cards[0]['learning'], isTrue);
      expect(cards[0]['last_review'], '2026-06-01T12:00:00.000Z');
      expect(cards[0]['interval'], stored.intervalSeconds);
      expect(cards[0]['difficulty'], stored.difficulty);
      expect(cards[0]['front'], 'hola');
      expect(cards[0]['back'], 'hello');
      expect(cards[0]['topic_id'], 'alpha');
      expect(cards[0]['created_at'], '2026-03-01T15:30:00.000Z');
      expect(cards[1]['last_review'], isNull);
      expect(cards[1]['learning'], isFalse);
      expect(cards[1]['interval'], 600);
      expect(cards[1]['difficulty'], 1);

      expect(decoded['settings'], {
        'correct_factor': 2,
        'wrong_factor': 0.25,
        'difficulty_factor': 0,
        'learning_window_size': 3,
        'learned_threshold': 7200,
      });
    },
  );

  testWidgets('export backup hands the library json to the share callback', (
    tester,
  ) async {
    final database = LibraryDatabase(NativeDatabase.memory());
    final repository = LibraryRepository(database);
    addTearDown(database.close);
    usePhoneSurface(tester);

    await repository.insertTopic(
      id: 'spanish',
      name: 'Spanish',
      createdAt: DateTime.utc(2026, 3, 1),
    );
    await repository.insertCard(
      FlashCard.fresh(
        id: 'hola',
        topicId: 'spanish',
        front: 'hola',
        back: 'hello',
        createdAt: DateTime.utc(2026, 3, 1),
      ),
    );

    String? sent;
    Rect? origin;
    await pumpSettings(
      tester,
      repository,
      shareBackup: (json, rect) async {
        sent = json;
        origin = rect;
      },
    );

    expect(find.byKey(const Key('save-settings')), findsOneWidget);
    expect(find.text('Correct factor'), findsOneWidget);
    expect(
      find.text('Topics, cards, and settings, as a JSON file.'),
      findsOneWidget,
    );

    await tester.tap(find.byKey(const Key('export-backup')));
    await tester.pump();
    await settle(tester);

    final decoded = jsonDecode(sent!) as Map<String, Object?>;
    final cards = (decoded['cards']! as List<Object?>)
        .cast<Map<String, Object?>>();
    expect(cards.single['front'], 'hola');
    expect(cards.single['back'], 'hello');
    expect(cards.single['topic_id'], 'spanish');
    expect(cards.single['learning'], isFalse);
    expect(cards.single['last_review'], isNull);
    expect(cards.single['interval'], 600);
    expect(cards.single['difficulty'], 1);
    expect(cards.single['created_at'], '2026-03-01T00:00:00.000Z');
    expect((decoded['topics']! as List<Object?>).length, 1);
    expect(decoded['settings'], isA<Map<String, Object?>>());
    expect(origin!.width, greaterThan(0));
    expect(origin!.height, greaterThan(0));
    expect(tester.takeException(), isNull);
  });

  testWidgets('a failed export shows a snackbar and can be tried again', (
    tester,
  ) async {
    final database = LibraryDatabase(NativeDatabase.memory());
    final repository = LibraryRepository(database);
    addTearDown(database.close);
    usePhoneSurface(tester);

    await pumpSettings(
      tester,
      repository,
      shareBackup: (json, rect) async => throw Exception('sheet failed'),
    );

    await tester.tap(find.byKey(const Key('export-backup')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    expect(find.text('Could not export the backup.'), findsOneWidget);
    expect(
      tester
          .widget<OutlinedButton>(find.byKey(const Key('export-backup')))
          .onPressed,
      isNotNull,
    );
    expect(
      tester
          .widget<TextButton>(find.byKey(const Key('save-settings')))
          .onPressed,
      isNotNull,
    );
  });

  test('a backup parses back into the same topics, cards, and settings', () {
    final backup = sampleBackup();
    final parsed = parseLibraryBackup(
      libraryBackupJson(
        topics: backup.topics,
        cards: backup.cards,
        settings: backup.settings,
      ),
    );

    expect(parsed.topics.map((topic) => topic.id).toList(), [
      'child',
      'parent',
    ]);
    expect(parsed.topics.first.parentId, 'parent');
    expect(parsed.topics.first.createdAt, DateTime.utc(2026, 3, 2, 8));
    expect(parsed.cards.single.front, 'hola');
    expect(parsed.cards.single.back, 'hello');
    expect(parsed.cards.single.topicId, 'child');
    expect(parsed.cards.single.learning, isTrue);
    expect(parsed.cards.single.lastReview, DateTime.utc(2026, 6, 1, 12));
    expect(parsed.cards.single.intervalSeconds, 300);
    expect(parsed.cards.single.difficulty, 1.25);
    expect(parsed.cards.single.createdAt, DateTime.utc(2026, 3, 1, 15, 30));
    expect(parsed.settings.correctFactor, 2);
    expect(parsed.settings.wrongFactor, 0.25);
    expect(parsed.settings.difficultyFactor, 0);
    expect(parsed.settings.learningWindowSize, 3);
    expect(parsed.settings.learnedThreshold, const Duration(hours: 2));
    expect(parsed.cards.single.hasReverse, isFalse);
    expect(parsed.topics.every((topic) => topic.reverseDrill == false), isTrue);
  });

  test(
    'a version 1 backup imports with the switch off and no reverse faces',
    () {
      final parsed = parseLibraryBackup(
        '{"version":1,"topics":[{"id":"a","name":"A","parent_id":null,'
        '"position":0,"created_at":"2026-03-01T00:00:00.000Z"}],'
        '"cards":[{"id":"c","topic_id":"a","front":"hola","back":"hello",'
        '"learning":false,"last_review":null,"interval":600,"difficulty":1,'
        '"created_at":"2026-03-01T00:00:00.000Z"}],'
        '"settings":{"correct_factor":1.5,"wrong_factor":0.5,'
        '"difficulty_factor":0.01,"learning_window_size":10,'
        '"learned_threshold":3600}}',
      );
      expect(parsed.topics.single.reverseDrill, isFalse);
      expect(parsed.cards.single.hasReverse, isFalse);
      expect(parsed.cards.single.front, 'hola');
    },
  );

  test('a version 2 backup keeps a reverse face', () {
    final queued = DateTime.utc(2026, 6, 2, 8);
    final card = spawnReverseFace(
      FlashCard(
        id: 'c',
        topicId: 'a',
        front: 'hola',
        back: 'hello',
        learning: false,
        lastReview: DateTime.utc(2026, 1, 1),
        intervalSeconds: 7200,
        difficulty: 2,
        createdAt: DateTime.utc(2026, 1, 1),
      ),
      queuedAt: queued,
    );
    final parsed = parseLibraryBackup(
      libraryBackupJson(
        topics: [
          BackupTopic(
            id: 'a',
            name: 'A',
            parentId: null,
            position: 0,
            createdAt: DateTime.utc(2026, 1, 1),
            reverseDrill: true,
          ),
        ],
        cards: [card],
        settings: SchedulerParameters.defaults(),
      ),
    );
    expect(parsed.topics.single.reverseDrill, isTrue);
    final restored = parsed.cards.single;
    expect(restored.reverseQueuedAt, queued);
    expect(restored.reverseIntervalSeconds, 600);
    expect(restored.reverseDifficulty, 1);
    expect(restored.reverseLearning, isFalse);
    expect(restored.reverseLastReview, isNull);
    expect(restored.difficulty, 2);
  });

  test('a backup that cannot be restored is rejected', () {
    final json = libraryBackupJson(
      topics: sampleBackup().topics,
      cards: sampleBackup().cards,
      settings: sampleBackup().settings,
    );

    expect(() => parseLibraryBackup('not json'), throwsFormatException);
    expect(
      () => parseLibraryBackup(
        '{"version":3,"topics":[],"cards":[],"settings":{}}',
      ),
      throwsBackupMessage('Backup version is not supported.'),
    );
    expect(
      () => parseLibraryBackup(
        '{"version":1,"topics":['
        '{"id":"a","name":"A","parent_id":"b","position":0,'
        '"created_at":"2026-03-01T00:00:00.000Z"},'
        '{"id":"b","name":"B","parent_id":"a","position":0,'
        '"created_at":"2026-03-01T00:00:00.000Z"}'
        '],"cards":[],"settings":{"correct_factor":1.5,"wrong_factor":0.5,'
        '"difficulty_factor":0.01,"learning_window_size":10,'
        '"learned_threshold":3600}}',
      ),
      throwsBackupMessage('Topics contain a cycle.'),
    );
    expect(
      () => parseLibraryBackup(
        json.replaceFirst('"interval": 300', '"interval": 30'),
      ),
      throwsBackupMessage('Card hola has an invalid interval.'),
    );
    expect(
      () => parseLibraryBackup(
        json.replaceFirst('"correct_factor": 2.0', '"correct_factor": 1'),
      ),
      throwsBackupMessage('Backup settings are not valid.'),
    );
  });

  test('restore replaces the library and drops review rows', () async {
    final database = LibraryDatabase(NativeDatabase.memory());
    final repository = LibraryRepository(database);
    addTearDown(database.close);

    await repository.insertTopic(
      id: 'old',
      name: 'Old',
      createdAt: DateTime.utc(2026, 1, 1),
    );
    await repository.insertCard(
      FlashCard.fresh(
        id: 'old-card',
        topicId: 'old',
        front: 'old',
        back: 'old-back',
        createdAt: DateTime.utc(2026, 1, 2),
      ),
    );
    await repository.admit('old-card');
    await repository.grade(
      cardId: 'old-card',
      outcome: GradeOutcome.wrong,
      now: DateTime.utc(2026, 2, 1),
    );
    expect(await repository.reviewsFor('old-card'), isNotEmpty);

    final backup = sampleBackup();
    await repository.restoreBackup(backup);

    final topics = await repository.listTopics();
    expect(topics.map((topic) => topic.id).toList(), ['child', 'parent']);
    expect(topics.first.parentId, 'parent');
    expect(topics.last.position, 1);
    final card = await repository.card('hola');
    expect(card.front, 'hola');
    expect(card.learning, isTrue);
    expect(card.lastReview, DateTime.utc(2026, 6, 1, 12));
    expect(card.intervalSeconds, 300);
    expect(card.difficulty, 1.25);
    expect(card.createdAt, DateTime.utc(2026, 3, 1, 15, 30));
    expect(await repository.reviewsFor('hola'), isEmpty);
    expect(await repository.reviewsFor('old-card'), isEmpty);
    await expectLater(repository.card('old-card'), throwsStateError);
    final settings = await repository.loadSettings();
    expect(settings.correctFactor, backup.settings.correctFactor);
    expect(settings.learningWindowSize, 3);
    expect(settings.learnedThreshold, const Duration(hours: 2));

    final again = await repository.backupJson();
    final roundTrip = parseLibraryBackup(again);
    expect(roundTrip.cards.single.id, 'hola');
    expect(roundTrip.topics.map((topic) => topic.id), ['child', 'parent']);
    expect(roundTrip.topics.first.createdAt, DateTime.utc(2026, 3, 2, 8));
    expect(roundTrip.topics.last.createdAt, DateTime.utc(2026, 3, 1, 15, 30));
    expect(roundTrip.topics.first.parentId, 'parent');
  });

  testWidgets('an empty library imports a backup without asking', (
    tester,
  ) async {
    final database = LibraryDatabase(NativeDatabase.memory());
    final repository = LibraryRepository(database);
    addTearDown(database.close);
    usePhoneSurface(tester);

    await pumpSettings(
      tester,
      repository,
      shareBackup: (json, rect) async {},
      pickBackup: () async => libraryBackupJson(
        topics: sampleBackup().topics,
        cards: sampleBackup().cards,
        settings: sampleBackup().settings,
      ),
    );

    await tester.ensureVisible(find.byKey(const Key('import-backup')));
    await tester.tap(find.byKey(const Key('import-backup')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    expect(find.text('Replace the library?'), findsNothing);
    expect(find.text('Backup imported.'), findsOneWidget);
    expect(fieldText(tester, 'correct-factor'), '2');
    expect(fieldText(tester, 'learning-window'), '3');
    expect(fieldText(tester, 'learned-threshold'), '2');
    expect((await repository.listTopics()).map((topic) => topic.name), [
      'Child',
      'Parent',
    ]);
    expect((await repository.card('hola')).back, 'hello');
  });

  testWidgets('import asks before replacing a library that already has cards', (
    tester,
  ) async {
    final database = LibraryDatabase(NativeDatabase.memory());
    final repository = LibraryRepository(database);
    addTearDown(database.close);
    usePhoneSurface(tester);
    await repository.insertTopic(
      id: 'old',
      name: 'Old',
      createdAt: DateTime.utc(2026, 1, 1),
    );
    await repository.insertCard(
      FlashCard.fresh(
        id: 'old-card',
        topicId: 'old',
        front: 'keep-me',
        back: 'keep-back',
        createdAt: DateTime.utc(2026, 1, 2),
      ),
    );

    await pumpSettings(
      tester,
      repository,
      shareBackup: (json, rect) async {},
      pickBackup: () async => libraryBackupJson(
        topics: sampleBackup().topics,
        cards: sampleBackup().cards,
        settings: sampleBackup().settings,
      ),
    );

    await tester.ensureVisible(find.byKey(const Key('import-backup')));
    await tester.tap(find.byKey(const Key('import-backup')));
    await tester.pump();
    await settle(tester);

    expect(find.text('Replace the library?'), findsOneWidget);
    await tester.tap(find.text('Cancel'));
    await settle(tester);

    expect(find.text('Backup imported.'), findsNothing);
    expect((await repository.card('old-card')).front, 'keep-me');

    await tester.ensureVisible(find.byKey(const Key('import-backup')));
    await tester.tap(find.byKey(const Key('import-backup')));
    await tester.pump();
    await settle(tester);
    await tester.tap(find.text('Replace'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    expect(find.text('Backup imported.'), findsOneWidget);
    expect(fieldText(tester, 'correct-factor'), '2');
    await expectLater(repository.card('old-card'), throwsStateError);
    expect((await repository.card('hola')).front, 'hola');
    expect(await repository.reviewsFor('old-card'), isEmpty);
  });

  testWidgets('an invalid backup does not change the library', (tester) async {
    final database = LibraryDatabase(NativeDatabase.memory());
    final repository = LibraryRepository(database);
    addTearDown(database.close);
    usePhoneSurface(tester);
    await repository.insertTopic(
      id: 'old',
      name: 'Old',
      createdAt: DateTime.utc(2026, 1, 1),
    );

    await pumpSettings(
      tester,
      repository,
      shareBackup: (json, rect) async {},
      pickBackup: () async => '{',
    );

    await tester.ensureVisible(find.byKey(const Key('import-backup')));
    await tester.tap(find.byKey(const Key('import-backup')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    expect(find.text('Could not import the backup.'), findsOneWidget);
    expect(find.text('Replace the library?'), findsNothing);
    expect((await repository.listTopics()).single.name, 'Old');
    expect(fieldText(tester, 'correct-factor'), '1.5');
  });

  testWidgets('cancelling the file picker leaves the library alone', (
    tester,
  ) async {
    final database = LibraryDatabase(NativeDatabase.memory());
    final repository = LibraryRepository(database);
    addTearDown(database.close);
    usePhoneSurface(tester);

    await pumpSettings(
      tester,
      repository,
      shareBackup: (json, rect) async {},
      pickBackup: () async => null,
    );

    await tester.ensureVisible(find.byKey(const Key('import-backup')));
    await tester.tap(find.byKey(const Key('import-backup')));
    await tester.pump();
    await settle(tester);

    expect(find.text('Backup imported.'), findsNothing);
    expect(find.text('Could not import the backup.'), findsNothing);
    expect(await repository.listTopics(), isEmpty);
    expect(await repository.listCards(), isEmpty);
  });
}

void usePhoneSurface(WidgetTester tester) {
  tester.view.physicalSize = const Size(390, 844);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}

Future<void> pumpSettings(
  WidgetTester tester,
  LibraryRepository repository, {
  required Future<void> Function(String json, Rect origin) shareBackup,
  Future<String?> Function()? pickBackup,
}) async {
  await tester.pumpWidget(
    LibraryScope(
      repository: repository,
      child: MaterialApp(
        home: SettingsScreen(shareBackup: shareBackup, pickBackup: pickBackup),
      ),
    ),
  );
  await tester.pump();
  await settle(tester);
}

LibraryBackup sampleBackup() {
  return LibraryBackup(
    topics: [
      BackupTopic(
        id: 'child',
        name: 'Child',
        parentId: 'parent',
        position: 0,
        createdAt: DateTime.utc(2026, 3, 2, 8),
      ),
      BackupTopic(
        id: 'parent',
        name: 'Parent',
        parentId: null,
        position: 1,
        createdAt: DateTime.utc(2026, 3, 1, 15, 30),
      ),
    ],
    cards: [
      FlashCard(
        id: 'hola',
        topicId: 'child',
        front: 'hola',
        back: 'hello',
        learning: true,
        lastReview: DateTime.utc(2026, 6, 1, 12),
        intervalSeconds: 300,
        difficulty: 1.25,
        createdAt: DateTime.utc(2026, 3, 1, 15, 30),
      ),
    ],
    settings: SchedulerParameters(
      correctFactor: 2,
      wrongFactor: 0.25,
      difficultyFactor: 0,
      learningWindowSize: 3,
      learnedThreshold: const Duration(hours: 2),
    ),
  );
}

Matcher throwsBackupMessage(String message) {
  return throwsA(
    isA<FormatException>().having((error) => error.message, 'message', message),
  );
}

String fieldText(WidgetTester tester, String key) {
  return tester.widget<TextField>(find.byKey(Key(key))).controller!.text;
}

Future<void> settle(WidgetTester tester) async {
  FocusManager.instance.primaryFocus?.unfocus();
  await tester.pumpAndSettle(
    const Duration(milliseconds: 50),
    EnginePhase.sendSemanticsUpdate,
    const Duration(seconds: 3),
  );
}
