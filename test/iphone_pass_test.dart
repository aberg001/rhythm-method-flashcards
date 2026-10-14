import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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

  testWidgets('grade buttons sit above the home indicator', (tester) async {
    await repository.insertTopic(
      id: 'topic',
      name: 'Topic',
      createdAt: DateTime.utc(2026, 1, 1),
    );
    await repository.insertCard(
      FlashCard.fresh(
        id: 'c',
        topicId: 'topic',
        front: 'hola',
        back: 'hello',
        createdAt: DateTime.utc(2026, 2, 1),
      ),
    );

    const height = 844.0;
    const bottomInset = 34.0;
    tester.view.physicalSize = const Size(390, height);
    tester.view.devicePixelRatio = 1;
    tester.view.viewPadding = const FakeViewPadding(
      top: 59,
      bottom: bottomInset,
    );
    tester.view.padding = const FakeViewPadding(top: 59, bottom: bottomInset);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetViewPadding);
    addTearDown(tester.view.resetPadding);

    await pumpSession(tester, repository);

    final correct = tester.getRect(find.byKey(const Key('correct-button')));
    final wrong = tester.getRect(find.byKey(const Key('wrong-button')));
    final flip = tester.getRect(find.byKey(const Key('flip-button')));
    expect(correct.bottom, lessThanOrEqualTo(height - bottomInset));
    expect(wrong.bottom, lessThanOrEqualTo(height - bottomInset));
    expect(flip.bottom, lessThanOrEqualTo(height - bottomInset));
    expect(correct.top, greaterThan(height / 2));
    expect(correct.right, lessThanOrEqualTo(390));
    expect(wrong.left, greaterThanOrEqualTo(0));
    expect(tester.takeException(), isNull);
  });

  testWidgets('large text scrolls inside the card instead of clipping', (
    tester,
  ) async {
    final front = 'alpha ${'word ' * 80}omega';
    final back = 'beta ${'word ' * 80}omega';
    await repository.insertTopic(
      id: 'topic',
      name: 'Topic',
      createdAt: DateTime.utc(2026, 1, 1),
    );
    await repository.insertCard(
      FlashCard.fresh(
        id: 'c',
        topicId: 'topic',
        front: front,
        back: back,
        createdAt: DateTime.utc(2026, 2, 1),
      ),
    );

    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    tester.platformDispatcher.textScaleFactorTestValue = 3;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);

    await pumpSession(tester, repository);
    expect(tester.getRect(find.text(front)).height, greaterThan(844));
    expect(tester.takeException(), isNull);

    await tester.tap(find.byKey(const Key('flip-button')));
    await tester.pump();

    expect(tester.getRect(find.text(back)).height, greaterThan(844));
    await Scrollable.ensureVisible(
      tester.element(find.text(back)),
      alignment: 1,
    );
    await tester.pump();

    final backRect = tester.getRect(find.text(back));
    final scrollRect = tester.getRect(find.byType(SingleChildScrollView));
    expect(backRect.bottom, closeTo(scrollRect.bottom, 8));
    expect(backRect.bottom, greaterThan(scrollRect.top));

    final correct = tester.getRect(find.byKey(const Key('correct-button')));
    expect(correct.bottom, lessThanOrEqualTo(844));
    expect(correct.top, greaterThanOrEqualTo(0));
    expect(tester.takeException(), isNull);
  });

  testWidgets('VoiceOver can flip and then grade, with a tick only on grade', (
    tester,
  ) async {
    final haptics = <String>[];
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.platform,
      (call) async {
        if (call.method == 'HapticFeedback.vibrate') {
          haptics.add('${call.arguments}');
        }
        return null;
      },
    );
    addTearDown(() {
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        null,
      );
    });

    await repository.insertTopic(
      id: 'topic',
      name: 'Topic',
      createdAt: DateTime.utc(2026, 1, 1),
    );
    await repository.insertCard(
      FlashCard.fresh(
        id: 'c',
        topicId: 'topic',
        front: 'hola',
        back: 'hello',
        createdAt: DateTime.utc(2026, 2, 1),
      ),
    );

    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final semantics = tester.ensureSemantics();
    try {
      await pumpSession(tester, repository);

      expect(find.semantics.byLabel('Flip'), findsOneWidget);
      expect(find.semantics.byLabel('Wrong'), findsOneWidget);
      expect(find.semantics.byLabel('Correct'), findsOneWidget);
      expectSpoken(tester, 'edit-button', 'Edit');
      expectSpoken(tester, 'undo-button', 'Undo');

      expect(disabledSemanticsTap(tester, 'Correct'), throwsA(isNotGraded));
      expect(disabledSemanticsTap(tester, 'Wrong'), throwsA(isNotGraded));
      expect(await repository.reviewsFor('c'), isEmpty);
      expect(haptics, isEmpty);

      tester.semantics.tap(find.semantics.byLabel('Flip'));
      await tester.pump();
      expect(find.text('hello'), findsOneWidget);
      expect(haptics, isEmpty);
      expect(disabledSemanticsTap(tester, 'Flip'), throwsA(isNotGraded));

      tester.semantics.tap(find.semantics.byLabel('Correct'));
      await tester.pump();
      await settle(tester);

      final card = await repository.card('c');
      expect(card.intervalSeconds, 900);
      expect(card.lastReview, isNotNull);
      expect(haptics, ['HapticFeedbackType.selectionClick']);
      expect(tester.takeException(), isNull);
    } finally {
      semantics.dispose();
    }
  });
}

/// Invokes the semantics tap. A disabled grade button has no tap action.
void Function() disabledSemanticsTap(WidgetTester tester, String label) {
  return () => tester.semantics.tap(find.semantics.byLabel(label));
}

final isNotGraded = isA<StateError>().having(
  (error) => error.toString(),
  'message',
  contains('does not support'),
);

void expectSpoken(WidgetTester tester, String key, String spoken) {
  final data = tester.getSemantics(find.byKey(Key(key))).getSemanticsData();
  final voiceOver = [
    if (data.label.trim().isNotEmpty) data.label.trim(),
    if (data.tooltip.trim().isNotEmpty) data.tooltip.trim(),
  ].join(' ');
  expect(voiceOver, spoken);
}

Future<void> pumpSession(
  WidgetTester tester,
  LibraryRepository repository,
) async {
  await tester.pumpWidget(
    LibraryScope(
      repository: repository,
      child: MaterialApp(
        home: StudySessionScreen(
          key: UniqueKey(),
          title: 'Topic',
          scopeTopicId: 'topic',
          now: () => DateTime.utc(2026, 6, 1, 12),
        ),
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
