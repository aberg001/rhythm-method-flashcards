import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rhythm_method_flashcards/data/card_import.dart';
import 'package:rhythm_method_flashcards/data/database.dart';
import 'package:rhythm_method_flashcards/data/library_repository.dart';
import 'package:rhythm_method_flashcards/domain/scheduler.dart';
import 'package:rhythm_method_flashcards/features/library/library_scope.dart';
import 'package:rhythm_method_flashcards/features/library/topic_screen.dart';

void main() {
  late LibraryDatabase database;
  late LibraryRepository repository;

  setUp(() {
    database = LibraryDatabase(NativeDatabase.memory());
    repository = LibraryRepository(database);
  });

  tearDown(() => database.close());

  testWidgets('import shows a preview and adds the new cards', (tester) async {
    await repository.insertTopic(id: 'spanish', name: 'Spanish');
    await repository.insertCard(
      FlashCard.fresh(
        id: 'known',
        topicId: 'spanish',
        front: 'hola',
        back: 'hello',
        createdAt: DateTime.utc(2026, 1, 1),
      ),
    );
    await repository.insertTag(id: 'verb', name: 'verb');

    await pumpTopic(tester, repository, () async {
      return const CardImportFile(
        name: 'cards.csv',
        text:
            'front,back,tags,note\n'
            'hola,hello,verb,aside\n'
            'adios,goodbye,noun,y\n',
      );
    });

    await tester.tap(find.byKey(const Key('import-cards-button')));
    await settle(tester);
    expect(find.textContaining('1 card will be added.'), findsOneWidget);
    expect(find.textContaining('1 row will be skipped.'), findsOneWidget);
    expect(find.textContaining('New tags: noun.'), findsOneWidget);
    expect(find.textContaining('Extra fields were dropped.'), findsOneWidget);

    await tester.tap(find.widgetWithText(TextButton, 'Import'));
    await settle(tester);
    expect(find.text('Added 1 card. Skipped 1 row.'), findsOneWidget);
    expect(find.text('adios'), findsOneWidget);
    expect(find.text('hola'), findsOneWidget);

    final added = (await repository.listCards()).singleWhere(
      (card) => card.front == 'adios',
    );
    expect(added.intervalSeconds, 600);
    expect(added.difficulty, 1);
    expect(added.learning, isFalse);
    final names = {
      for (final tag in await repository.listTags()) tag.id: tag.name,
    };
    expect(
      [for (final id in await repository.tagIdsFor(added.id)) names[id]],
      ['noun'],
    );
  });

  testWidgets('a file without front and back is not imported', (tester) async {
    await repository.insertTopic(id: 'spanish', name: 'Spanish');
    await pumpTopic(tester, repository, () async {
      return const CardImportFile(
        name: 'cards.csv',
        text: 'question,answer\nhola,hello\n',
      );
    });

    await tester.tap(find.byKey(const Key('import-cards-button')));
    await settle(tester);
    expect(
      find.text('The file needs a front column and a back column.'),
      findsOneWidget,
    );
    expect(find.text('Import'), findsNothing);
    expect(await repository.listCards(), isEmpty);
  });
}

Future<void> pumpTopic(
  WidgetTester tester,
  LibraryRepository repository,
  Future<CardImportFile?> Function() pick,
) async {
  tester.view.physicalSize = const Size(390, 844);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  await tester.pumpWidget(
    LibraryScope(
      repository: repository,
      child: MaterialApp(
        home: TopicScreen(topicId: 'spanish', pickImport: () => pick()),
      ),
    ),
  );
  await tester.pump();
  await settle(tester);
}

Future<void> settle(WidgetTester tester) async {
  FocusManager.instance.primaryFocus?.unfocus();
  await tester.pumpAndSettle(
    const Duration(milliseconds: 50),
    EnginePhase.sendSemanticsUpdate,
    const Duration(seconds: 3),
  );
}
