import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rhythm_method_flashcards/app.dart';
import 'package:rhythm_method_flashcards/data/database.dart';
import 'package:rhythm_method_flashcards/data/library_repository.dart';

void main() {
  late LibraryDatabase database;
  late LibraryRepository repository;

  setUp(() {
    database = LibraryDatabase(NativeDatabase.memory());
    repository = LibraryRepository(database);
  });

  tearDown(() => database.close());

  testWidgets('opens on an empty library', (tester) async {
    await pumpApp(tester, repository);

    expect(find.text('Library'), findsWidgets);
    expect(find.text('Add a topic, then add a card.'), findsOneWidget);
    expect(find.widgetWithText(FilledButton, 'Add topic'), findsOneWidget);
  });

  testWidgets('switches to study and settings', (tester) async {
    await pumpApp(tester, repository);

    await tester.tap(
      find.descendant(
        of: find.byType(NavigationBar),
        matching: find.text('Study'),
      ),
    );
    await tester.pumpAndSettle();
    expect(
      find.text('A study session will start from a topic in the library.'),
      findsOneWidget,
    );

    await tester.tap(
      find.descendant(
        of: find.byType(NavigationBar),
        matching: find.text('Settings'),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Correct factor'), findsOneWidget);
    expect(find.text('Learning window'), findsOneWidget);
    expect(find.byKey(const Key('save-settings')), findsOneWidget);
  });

  testWidgets('study all opens a clear session', (tester) async {
    await pumpApp(tester, repository);

    await tester.tap(
      find.descendant(
        of: find.byType(NavigationBar),
        matching: find.text('Study'),
      ),
    );
    await tester.pumpAndSettle();
    expect(
      find.text('A study session will start from a topic in the library.'),
      findsOneWidget,
    );

    await tester.tap(find.widgetWithText(FilledButton, 'Study all'));
    await tester.pumpAndSettle();
    expect(find.text('Nothing is due.'), findsOneWidget);
    expect(find.text('All topics'), findsOneWidget);
  });
}

Future<void> pumpApp(WidgetTester tester, LibraryRepository repository) async {
  tester.view.physicalSize = const Size(390, 844);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  await tester.pumpWidget(RhythmMethodApp(repository: repository));
  await tester.pump();
  await tester.pumpAndSettle();
}
