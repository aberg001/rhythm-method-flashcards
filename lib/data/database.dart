import 'package:drift/drift.dart';

import '../domain/scheduler.dart';

part 'database.g.dart';

@DataClassName('TopicRow')
class Topics extends Table {
  TextColumn get id => text()();
  TextColumn get parentId =>
      text().nullable().references(Topics, #id, onDelete: KeyAction.restrict)();
  TextColumn get name => text()();
  IntColumn get position => integer()();
  DateTimeColumn get createdAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}

@DataClassName('CardRow')
class Cards extends Table {
  TextColumn get id => text()();
  TextColumn get topicId =>
      text().references(Topics, #id, onDelete: KeyAction.restrict)();
  TextColumn get front => text()();
  TextColumn get back => text()();
  BoolColumn get learning => boolean()();
  DateTimeColumn get lastReview => dateTime().nullable()();
  IntColumn get intervalSeconds => integer()();
  RealColumn get difficulty => real()();
  DateTimeColumn get createdAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}

@DataClassName('ReviewRow')
class Reviews extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get cardId =>
      text().references(Cards, #id, onDelete: KeyAction.cascade)();
  DateTimeColumn get reviewedAt => dateTime()();
  TextColumn get outcome => text()();
  IntColumn get intervalBefore => integer()();
  IntColumn get intervalAfter => integer()();
  RealColumn get difficultyBefore => real()();
  RealColumn get difficultyAfter => real()();
  BoolColumn get learningBefore => boolean()();
  BoolColumn get learningAfter => boolean()();

  /// Not part of the grade arithmetic. Stored so a persisted undo can put
  /// [FlashCard.lastReview] back.
  DateTimeColumn get lastReviewBefore => dateTime().nullable()();
}

@DataClassName('SettingRow')
class Settings extends Table {
  IntColumn get id => integer()();
  RealColumn get correctFactor => real()();
  RealColumn get wrongFactor => real()();
  RealColumn get difficultyFactor => real()();
  IntColumn get learningWindowSize => integer()();
  IntColumn get learnedThresholdSeconds => integer()();

  @override
  Set<Column> get primaryKey => {id};
}

@DriftDatabase(tables: [Topics, Cards, Reviews, Settings])
class LibraryDatabase extends _$LibraryDatabase {
  LibraryDatabase(super.executor);

  @override
  int get schemaVersion => 1;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    beforeOpen: (details) async {
      await customStatement('PRAGMA foreign_keys = ON');
      final existing = await select(settings).getSingleOrNull();
      if (existing != null) return;
      final defaults = SchedulerParameters.defaults();
      await into(settings).insert(
        SettingsCompanion.insert(
          id: const Value(1),
          correctFactor: defaults.correctFactor,
          wrongFactor: defaults.wrongFactor,
          difficultyFactor: defaults.difficultyFactor,
          learningWindowSize: defaults.learningWindowSize,
          learnedThresholdSeconds: defaults.learnedThreshold.inSeconds,
        ),
      );
    },
  );
}
