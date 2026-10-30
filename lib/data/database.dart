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

  /// Back-to-front drills for this topic's own cards. Not inherited.
  BoolColumn get reverseDrill => boolean().withDefault(const Constant(false))();

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

  /// Null [reverseQueuedAt] means there is no reverse face. The other reverse
  /// columns are null in that case, except [reverseLearning], which stays false.
  BoolColumn get reverseLearning =>
      boolean().withDefault(const Constant(false))();
  DateTimeColumn get reverseLastReview => dateTime().nullable()();
  IntColumn get reverseIntervalSeconds => integer().nullable()();
  RealColumn get reverseDifficulty => real().nullable()();
  DateTimeColumn get reverseQueuedAt => dateTime().nullable()();

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

  /// `forward` or `reverse`. Undo shows this face again.
  TextColumn get direction => text().withDefault(const Constant('forward'))();
}

@DataClassName('TagRow')
class Tags extends Table {
  TextColumn get id => text()();
  TextColumn get name => text()();
  IntColumn get position => integer()();

  @override
  Set<Column> get primaryKey => {id};
}

@DataClassName('CardTagRow')
class CardTags extends Table {
  TextColumn get cardId =>
      text().references(Cards, #id, onDelete: KeyAction.cascade)();
  TextColumn get tagId =>
      text().references(Tags, #id, onDelete: KeyAction.cascade)();

  @override
  Set<Column> get primaryKey => {cardId, tagId};
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

@DriftDatabase(tables: [Topics, Cards, Reviews, Settings, Tags, CardTags])
class LibraryDatabase extends _$LibraryDatabase {
  LibraryDatabase(super.executor);

  @override
  int get schemaVersion => 3;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onUpgrade: (migrator, from, to) async {
      if (from < 2) {
        await migrator.addColumn(topics, topics.reverseDrill);
        await migrator.addColumn(cards, cards.reverseLearning);
        await migrator.addColumn(cards, cards.reverseLastReview);
        await migrator.addColumn(cards, cards.reverseIntervalSeconds);
        await migrator.addColumn(cards, cards.reverseDifficulty);
        await migrator.addColumn(cards, cards.reverseQueuedAt);
        await migrator.addColumn(reviews, reviews.direction);
      }
      if (from < 3) {
        await migrator.createTable(tags);
        await migrator.createTable(cardTags);
      }
    },
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
