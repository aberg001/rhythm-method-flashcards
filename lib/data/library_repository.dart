import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../domain/scheduler.dart';
import 'database.dart';
import 'library_backup.dart';

/// Opens the on-device library database.
Future<LibraryRepository> openLibraryRepository() async {
  final directory = await getApplicationSupportDirectory();
  final file = File(p.join(directory.path, 'rhythm_method.sqlite'));
  final database = LibraryDatabase(NativeDatabase.createInBackground(file));
  return LibraryRepository(database);
}

/// A grade that has been written, including the review row to delete on undo.
final class StoredGrade {
  const StoredGrade({required this.result, required this.reviewId});

  final GradeResult result;
  final int reviewId;
}

/// One persisted review row.
final class StoredReview {
  const StoredReview({
    required this.id,
    required this.record,
    required this.lastReviewBefore,
  });

  final int id;
  final ReviewRecord record;
  final DateTime? lastReviewBefore;
}

/// Topics, cards, reviews, and the five scheduler settings.
class LibraryRepository {
  LibraryRepository(this._db);

  final LibraryDatabase _db;

  Future<void> close() => _db.close();

  Future<List<Topic>> listTopics() async {
    final rows =
        await (_db.select(_db.topics)..orderBy([
              (topic) => OrderingTerm(expression: topic.position),
              (topic) => OrderingTerm(expression: topic.id),
            ]))
            .get();
    return rows.map(_topic).toList();
  }

  Future<void> insertTopic({
    required String id,
    required String name,
    String? parentId,
    DateTime? createdAt,
  }) {
    return _db.transaction(() async {
      if (parentId != null) {
        final parent = await (_db.select(
          _db.topics,
        )..where((topic) => topic.id.equals(parentId))).getSingleOrNull();
        if (parent == null) {
          throw StateError('Parent topic $parentId does not exist');
        }
      }
      final siblings =
          await (_db.select(_db.topics)..where(
                (topic) => parentId == null
                    ? topic.parentId.isNull()
                    : topic.parentId.equals(parentId),
              ))
              .get();
      final position = siblings.isEmpty
          ? 0
          : siblings
                    .map((topic) => topic.position)
                    .reduce((a, b) => a > b ? a : b) +
                1;
      await _db
          .into(_db.topics)
          .insert(
            TopicsCompanion.insert(
              id: id,
              name: name,
              parentId: Value(parentId),
              position: position,
              createdAt: createdAt ?? DateTime.now().toUtc(),
            ),
          );
    });
  }

  Future<void> renameTopic(String id, String name) async {
    final updated =
        await (_db.update(_db.topics)..where((topic) => topic.id.equals(id)))
            .write(TopicsCompanion(name: Value(name)));
    if (updated == 0) {
      throw StateError('Topic $id does not exist');
    }
  }

  /// Sets positions to the order of [orderedIds] among one parent's children.
  Future<void> reorderTopics(List<String> orderedIds) {
    return _db.transaction(() async {
      for (var index = 0; index < orderedIds.length; index++) {
        await (_db.update(_db.topics)
              ..where((topic) => topic.id.equals(orderedIds[index])))
            .write(TopicsCompanion(position: Value(index)));
      }
    });
  }

  /// Refuses when the topic still has subtopics or cards.
  Future<void> deleteTopic(String id) {
    return _db.transaction(() async {
      final children = await (_db.select(
        _db.topics,
      )..where((topic) => topic.parentId.equals(id))).get();
      if (children.isNotEmpty) {
        throw StateError('Topic $id still has subtopics');
      }
      final cards = await (_db.select(
        _db.cards,
      )..where((card) => card.topicId.equals(id))).get();
      if (cards.isNotEmpty) {
        throw StateError('Topic $id still has cards');
      }
      final removed = await (_db.delete(
        _db.topics,
      )..where((topic) => topic.id.equals(id))).go();
      if (removed == 0) {
        throw StateError('Topic $id does not exist');
      }
    });
  }

  Future<List<FlashCard>> listCards({String? topicId}) async {
    final query = _db.select(_db.cards)
      ..orderBy([
        (card) => OrderingTerm(expression: card.createdAt),
        (card) => OrderingTerm(expression: card.id),
      ]);
    if (topicId != null) {
      query.where((card) => card.topicId.equals(topicId));
    }
    final rows = await query.get();
    return rows.map(_card).toList();
  }

  Future<FlashCard> card(String id) => _requireCard(id);

  Future<void> insertCard(FlashCard card) {
    return _db.transaction(() async {
      await _db.into(_db.cards).insert(_cardCompanion(card));
    });
  }

  /// Changes the text only. Schedule fields stay as they are.
  Future<void> updateCardContent(
    String id, {
    required String front,
    required String back,
  }) async {
    final updated =
        await (_db.update(_db.cards)..where((card) => card.id.equals(id)))
            .write(CardsCompanion(front: Value(front), back: Value(back)));
    if (updated == 0) {
      throw StateError('Card $id does not exist');
    }
  }

  Future<void> deleteCard(String id) {
    return _db.transaction(() async {
      await (_db.delete(
        _db.reviews,
      )..where((review) => review.cardId.equals(id))).go();
      final removed = await (_db.delete(
        _db.cards,
      )..where((card) => card.id.equals(id))).go();
      if (removed == 0) {
        throw StateError('Card $id does not exist');
      }
    });
  }

  Future<SchedulerParameters> loadSettings() async {
    final row = await _db.select(_db.settings).getSingle();
    return SchedulerParameters(
      correctFactor: row.correctFactor,
      wrongFactor: row.wrongFactor,
      difficultyFactor: row.difficultyFactor,
      learningWindowSize: row.learningWindowSize,
      learnedThreshold: Duration(seconds: row.learnedThresholdSeconds),
    );
  }

  Future<void> saveSettings(SchedulerParameters parameters) {
    parameters.validate();
    return _db.transaction(() async {
      await _db
          .update(_db.settings)
          .replace(
            SettingRow(
              id: 1,
              correctFactor: parameters.correctFactor,
              wrongFactor: parameters.wrongFactor,
              difficultyFactor: parameters.difficultyFactor,
              learningWindowSize: parameters.learningWindowSize,
              learnedThresholdSeconds: parameters.learnedThreshold.inSeconds,
            ),
          );
    });
  }

  /// Topics, cards, and settings as version 2 JSON. Review rows are omitted.
  ///
  /// Topic creation times come from the stored rows. The domain [Topic] does
  /// not carry them, and a later import needs them to keep new-card order.
  Future<String> backupJson() async {
    final topicRows =
        await (_db.select(_db.topics)..orderBy([
              (topic) => OrderingTerm(expression: topic.position),
              (topic) => OrderingTerm(expression: topic.id),
            ]))
            .get();
    final topics = [
      for (final row in topicRows)
        BackupTopic(
          id: row.id,
          name: row.name,
          parentId: row.parentId,
          position: row.position,
          createdAt: _utc(row.createdAt)!,
          reverseDrill: row.reverseDrill,
        ),
    ];
    return libraryBackupJson(
      topics: topics,
      cards: await listCards(),
      settings: await loadSettings(),
    );
  }

  /// Replaces topics, cards, and settings with [backup].
  ///
  /// Review rows are removed. The file does not contain them, and the old
  /// rows would point at cards that no longer exist. Parents are inserted
  /// before their children, whatever order the file used.
  Future<void> restoreBackup(LibraryBackup backup) {
    backup.settings.validate();
    return _db.transaction(() async {
      await _db.delete(_db.reviews).go();
      await _db.delete(_db.cards).go();
      await _db
          .update(_db.topics)
          .write(const TopicsCompanion(parentId: Value(null)));
      await _db.delete(_db.topics).go();

      final pending = [...backup.topics];
      final inserted = <String>{};
      while (pending.isNotEmpty) {
        final index = pending.indexWhere(
          (topic) =>
              topic.parentId == null || inserted.contains(topic.parentId),
        );
        if (index == -1) {
          throw StateError('Backup topics contain a cycle');
        }
        final topic = pending.removeAt(index);
        await _db
            .into(_db.topics)
            .insert(
              TopicsCompanion.insert(
                id: topic.id,
                name: topic.name,
                parentId: Value(topic.parentId),
                position: topic.position,
                createdAt: topic.createdAt,
                reverseDrill: Value(topic.reverseDrill),
              ),
            );
        inserted.add(topic.id);
      }

      for (final card in backup.cards) {
        await _db.into(_db.cards).insert(_cardCompanion(card));
      }
      await _db
          .update(_db.settings)
          .replace(
            SettingRow(
              id: 1,
              correctFactor: backup.settings.correctFactor,
              wrongFactor: backup.settings.wrongFactor,
              difficultyFactor: backup.settings.difficultyFactor,
              learningWindowSize: backup.settings.learningWindowSize,
              learnedThresholdSeconds:
                  backup.settings.learnedThreshold.inSeconds,
            ),
          );
    });
  }

  /// Marks an existing new face as learning. The seat is taken before a grade.
  Future<FlashCard> admit(String cardId, {StudyFace face = StudyFace.forward}) {
    return _db.transaction(() async {
      final card = await _requireCard(cardId);
      if (face == StudyFace.reverse && !card.hasReverse) {
        throw StateError('Card $cardId has no reverse face');
      }
      final isNew = face == StudyFace.forward
          ? card.isNew
          : !card.reverseLearning && card.reverseLastReview == null;
      if (!isNew) {
        throw StateError('Card $cardId is not a new card');
      }
      final admitted = face == StudyFace.forward
          ? card.copyWith(learning: true)
          : card.copyWith(reverseLearning: true);
      await _writeCard(admitted);
      return admitted;
    });
  }

  /// Turns the reverse drill on or off for this topic only.
  ///
  /// Turning it on gives a reverse face to every learned card in the topic
  /// that does not have one yet. Cards known longest are queued ahead of
  /// cards learned more recently, and behind reverses that are already
  /// waiting. Turning it off leaves the stored faces in place.
  Future<void> setReverseDrill(
    String topicId, {
    required bool enabled,
    required DateTime now,
  }) {
    return _db.transaction(() async {
      final topic = await (_db.select(
        _db.topics,
      )..where((row) => row.id.equals(topicId))).getSingleOrNull();
      if (topic == null) {
        throw StateError('Topic $topicId does not exist');
      }
      await (_db.update(_db.topics)..where((row) => row.id.equals(topicId)))
          .write(TopicsCompanion(reverseDrill: Value(enabled)));
      if (!enabled) return;

      final parameters = await loadSettings();
      final rows = await _db.select(_db.cards).get();
      final cards = rows.map(_card).toList();
      final ceiling = reverseBackfillCeiling(
        cards.map((card) => card.reverseQueuedAt),
        now,
      );
      final needing = [
        for (final card in cards)
          if (card.topicId == topicId &&
              !card.hasReverse &&
              cardIsLearned(card, parameters))
            card,
      ];
      final queued = queueReverseBackfill(needing, ceiling: ceiling);
      for (final card in queued) {
        await _writeCard(card);
      }
    });
  }

  /// Grades the stored card and appends its review row.
  Future<StoredGrade> grade({
    required String cardId,
    required GradeOutcome outcome,
    required DateTime now,
    StudyFace face = StudyFace.forward,
  }) {
    return _db.transaction(() async {
      final card = await _requireCard(cardId);
      final parameters = await loadSettings();
      final graded = gradeCard(
        card: card,
        outcome: outcome,
        now: now,
        parameters: parameters,
        face: face,
      );
      var after = graded.after;
      if (face == StudyFace.forward &&
          forwardJustGraduated(
            before: graded.before,
            after: after,
            parameters: parameters,
          )) {
        final topic = await (_db.select(
          _db.topics,
        )..where((row) => row.id.equals(card.topicId))).getSingle();
        if (topic.reverseDrill && !after.hasReverse) {
          final queued = await _db.select(_db.cards).get();
          after = spawnReverseFace(
            after,
            queuedAt: nextReverseQueuedAt(
              queued.map((row) => row.reverseQueuedAt),
              now,
            ),
          );
        }
      }
      final result = GradeResult(
        before: graded.before,
        after: after,
        review: graded.review,
      );
      await _writeCard(result.after);
      final reviewId = await _db
          .into(_db.reviews)
          .insert(
            ReviewsCompanion.insert(
              cardId: card.id,
              reviewedAt: now,
              outcome: outcome.name,
              intervalBefore: result.review.intervalBefore,
              intervalAfter: result.review.intervalAfter,
              difficultyBefore: result.review.difficultyBefore,
              difficultyAfter: result.review.difficultyAfter,
              learningBefore: result.review.learningBefore,
              learningAfter: result.review.learningAfter,
              lastReviewBefore: Value(
                face == StudyFace.forward
                    ? card.lastReview
                    : card.reverseLastReview,
              ),
              direction: Value(face.name),
            ),
          );
      return StoredGrade(result: result, reviewId: reviewId);
    });
  }

  /// Writes the pre-grade card back and deletes its review row.
  Future<FlashCard> undo(StoredGrade grade) {
    return _db.transaction(() async {
      await _writeCard(grade.result.before);
      final removed = await (_db.delete(
        _db.reviews,
      )..where((review) => review.id.equals(grade.reviewId))).go();
      if (removed != 1) {
        throw StateError('Review ${grade.reviewId} was not removed');
      }
      return grade.result.before;
    });
  }

  Future<List<StoredReview>> reviewsFor(String cardId) async {
    final rows =
        await (_db.select(_db.reviews)
              ..where((review) => review.cardId.equals(cardId))
              ..orderBy([(review) => OrderingTerm(expression: review.id)]))
            .get();
    return rows.map(_review).toList();
  }

  Future<FlashCard> _requireCard(String id) async {
    final row = await (_db.select(
      _db.cards,
    )..where((card) => card.id.equals(id))).getSingleOrNull();
    if (row == null) {
      throw StateError('Card $id does not exist');
    }
    return _card(row);
  }

  Future<void> _writeCard(FlashCard card) {
    return _db.update(_db.cards).replace(_cardRow(card));
  }
}

Topic _topic(TopicRow row) {
  return Topic(
    id: row.id,
    name: row.name,
    parentId: row.parentId,
    position: row.position,
    reverseDrill: row.reverseDrill,
  );
}

FlashCard _card(CardRow row) {
  return FlashCard(
    id: row.id,
    topicId: row.topicId,
    front: row.front,
    back: row.back,
    learning: row.learning,
    lastReview: _utc(row.lastReview),
    intervalSeconds: row.intervalSeconds,
    difficulty: row.difficulty,
    createdAt: _utc(row.createdAt)!,
    reverseLearning: row.reverseLearning,
    reverseLastReview: _utc(row.reverseLastReview),
    reverseIntervalSeconds: row.reverseIntervalSeconds,
    reverseDifficulty: row.reverseDifficulty,
    reverseQueuedAt: _utc(row.reverseQueuedAt),
  );
}

CardRow _cardRow(FlashCard card) {
  return CardRow(
    id: card.id,
    topicId: card.topicId,
    front: card.front,
    back: card.back,
    learning: card.learning,
    lastReview: card.lastReview,
    intervalSeconds: card.intervalSeconds,
    difficulty: card.difficulty,
    createdAt: card.createdAt,
    reverseLearning: card.reverseLearning,
    reverseLastReview: card.reverseLastReview,
    reverseIntervalSeconds: card.reverseIntervalSeconds,
    reverseDifficulty: card.reverseDifficulty,
    reverseQueuedAt: card.reverseQueuedAt,
  );
}

CardsCompanion _cardCompanion(FlashCard card) {
  return CardsCompanion.insert(
    id: card.id,
    topicId: card.topicId,
    front: card.front,
    back: card.back,
    learning: card.learning,
    lastReview: Value(card.lastReview),
    intervalSeconds: card.intervalSeconds,
    difficulty: card.difficulty,
    createdAt: card.createdAt,
    reverseLearning: Value(card.reverseLearning),
    reverseLastReview: Value(card.reverseLastReview),
    reverseIntervalSeconds: Value(card.reverseIntervalSeconds),
    reverseDifficulty: Value(card.reverseDifficulty),
    reverseQueuedAt: Value(card.reverseQueuedAt),
  );
}

StoredReview _review(ReviewRow row) {
  return StoredReview(
    id: row.id,
    lastReviewBefore: _utc(row.lastReviewBefore),
    record: ReviewRecord(
      cardId: row.cardId,
      reviewedAt: _utc(row.reviewedAt)!,
      outcome: GradeOutcome.values.byName(row.outcome),
      intervalBefore: row.intervalBefore,
      intervalAfter: row.intervalAfter,
      difficultyBefore: row.difficultyBefore,
      difficultyAfter: row.difficultyAfter,
      learningBefore: row.learningBefore,
      learningAfter: row.learningAfter,
      face: StudyFace.values.byName(row.direction),
    ),
  );
}

DateTime? _utc(DateTime? value) => value?.toUtc();
