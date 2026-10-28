import 'dart:convert';

import '../domain/scheduler.dart';

/// A topic row in a backup, including the creation time the scheduler uses
/// when it picks the oldest new card.
final class BackupTopic {
  const BackupTopic({
    required this.id,
    required this.name,
    required this.parentId,
    required this.position,
    required this.createdAt,
    this.reverseDrill = false,
  });

  final String id;
  final String name;
  final String? parentId;
  final int position;
  final DateTime createdAt;
  final bool reverseDrill;
}

/// One backup. Review rows are not part of the file.
///
/// Version 2 is what this app writes. Version 1 is still accepted, and it
/// imports with every reverse switch off and no reverse faces.
final class LibraryBackup {
  const LibraryBackup({
    required this.topics,
    required this.cards,
    required this.settings,
  });

  final List<BackupTopic> topics;
  final List<FlashCard> cards;
  final SchedulerParameters settings;
}

/// Version 2 backup of topics, cards, and the five settings.
///
/// Review rows are left out. [parseLibraryBackup] reads this file back,
/// including a version 1 file.
String libraryBackupJson({
  required List<BackupTopic> topics,
  required List<FlashCard> cards,
  required SchedulerParameters settings,
}) {
  final payload = <String, Object?>{
    'version': 2,
    'topics': [
      for (final topic in topics)
        <String, Object?>{
          'id': topic.id,
          'name': topic.name,
          'parent_id': topic.parentId,
          'position': topic.position,
          'created_at': _timestamp(topic.createdAt),
          'reverse_drill': topic.reverseDrill,
        },
    ],
    'cards': [
      for (final card in cards)
        <String, Object?>{
          'id': card.id,
          'topic_id': card.topicId,
          'front': card.front,
          'back': card.back,
          'learning': card.learning,
          'last_review': card.lastReview == null
              ? null
              : _timestamp(card.lastReview!),
          'interval': card.intervalSeconds,
          'difficulty': card.difficulty,
          'created_at': _timestamp(card.createdAt),
          'reverse': _reverseJson(card),
        },
    ],
    'settings': <String, Object?>{
      'correct_factor': settings.correctFactor,
      'wrong_factor': settings.wrongFactor,
      'difficulty_factor': settings.difficultyFactor,
      'learning_window_size': settings.learningWindowSize,
      'learned_threshold': settings.learnedThreshold.inSeconds,
    },
  };
  return const JsonEncoder.withIndent('  ').convert(payload);
}

String _timestamp(DateTime value) => value.toUtc().toIso8601String();

Map<String, Object?>? _reverseJson(FlashCard card) {
  if (!card.hasReverse) return null;
  return <String, Object?>{
    'learning': card.reverseLearning,
    'last_review': card.reverseLastReview == null
        ? null
        : _timestamp(card.reverseLastReview!),
    'interval': card.reverseIntervalSeconds,
    'difficulty': card.reverseDifficulty,
    'queued_at': _timestamp(card.reverseQueuedAt!),
  };
}

/// Reads a version 1 or version 2 backup. Throws [FormatException] when the
/// file cannot be restored without changing the scheduler's meaning.
///
/// A version 1 file has the reverse switch off and no reverse faces.
LibraryBackup parseLibraryBackup(String source) {
  final Object? decoded;
  try {
    decoded = jsonDecode(source);
  } on FormatException {
    throw const FormatException('Backup must be a JSON object.');
  }
  if (decoded is! Map) {
    throw const FormatException('Backup must be a JSON object.');
  }
  final json = Map<String, Object?>.from(decoded);
  final version = json['version'];
  if (version is! num || (version != 1 && version != 2)) {
    throw const FormatException('Backup version is not supported.');
  }
  final includeReverse = version == 2;

  final topics = _topicsFrom(json['topics'], includeReverse: includeReverse);
  final topicIds = {for (final topic in topics) topic.id};
  _rejectTopicCycles(topics);
  return LibraryBackup(
    topics: topics,
    cards: _cardsFrom(json['cards'], topicIds, includeReverse: includeReverse),
    settings: _settingsFrom(json['settings']),
  );
}

List<BackupTopic> _topicsFrom(Object? value, {required bool includeReverse}) {
  if (value is! List) {
    throw const FormatException('Backup is missing topics.');
  }
  final topics = <BackupTopic>[];
  final seen = <String>{};
  for (final item in value) {
    if (item is! Map) {
      throw const FormatException('A topic is missing an id.');
    }
    final json = Map<String, Object?>.from(item);
    final id = json['id'];
    if (id is! String || id.isEmpty) {
      throw const FormatException('A topic is missing an id.');
    }
    if (!seen.add(id)) {
      throw FormatException('Topic $id appears more than once.');
    }
    final name = json['name'];
    if (name is! String || name.trim().isEmpty) {
      throw FormatException('Topic $id is missing a name.');
    }
    if (!json.containsKey('parent_id')) {
      throw FormatException('Topic $id is missing a parent.');
    }
    final parentId = json['parent_id'];
    if (parentId != null && (parentId is! String || parentId.isEmpty)) {
      throw FormatException('Topic $id has an invalid parent.');
    }
    final position = _asInt(json['position']);
    if (position == null || position < 0) {
      throw FormatException('Topic $id has an invalid position.');
    }
    final createdAt = _asTime(json['created_at']);
    if (createdAt == null) {
      throw FormatException('Topic $id has an invalid created_at.');
    }
    final reverseDrill = includeReverse
        ? _asBool(json['reverse_drill'])
        : false;
    if (reverseDrill == null) {
      throw FormatException('Topic $id has an invalid reverse drill switch.');
    }
    topics.add(
      BackupTopic(
        id: id,
        name: name,
        parentId: parentId as String?,
        position: position,
        createdAt: createdAt,
        reverseDrill: reverseDrill,
      ),
    );
  }
  final ids = {for (final topic in topics) topic.id};
  for (final topic in topics) {
    final parentId = topic.parentId;
    if (parentId == null) continue;
    if (parentId == topic.id) {
      throw FormatException('Topic ${topic.id} is its own parent.');
    }
    if (!ids.contains(parentId)) {
      throw FormatException(
        'Topic ${topic.id} has a parent that is not in the backup.',
      );
    }
  }
  return topics;
}

void _rejectTopicCycles(List<BackupTopic> topics) {
  final byId = {for (final topic in topics) topic.id: topic};
  final state = <String, int>{};
  var cyclic = false;

  bool visit(String id) {
    final mark = state[id] ?? 0;
    if (mark == 1) return true;
    if (mark == 2) return false;
    state[id] = 1;
    final parentId = byId[id]!.parentId;
    if (parentId != null && visit(parentId)) return true;
    state[id] = 2;
    return false;
  }

  for (final topic in topics) {
    if (visit(topic.id)) cyclic = true;
  }
  if (cyclic) {
    throw const FormatException('Topics contain a cycle.');
  }
}

List<FlashCard> _cardsFrom(
  Object? value,
  Set<String> topicIds, {
  required bool includeReverse,
}) {
  if (value is! List) {
    throw const FormatException('Backup is missing cards.');
  }
  final cards = <FlashCard>[];
  final seen = <String>{};
  for (final item in value) {
    if (item is! Map) {
      throw const FormatException('A card is missing an id.');
    }
    final json = Map<String, Object?>.from(item);
    final id = json['id'];
    if (id is! String || id.isEmpty) {
      throw const FormatException('A card is missing an id.');
    }
    if (!seen.add(id)) {
      throw FormatException('Card $id appears more than once.');
    }
    final topicId = json['topic_id'];
    if (topicId is! String || !topicIds.contains(topicId)) {
      throw FormatException('Card $id has a topic that is not in the backup.');
    }
    final front = json['front'];
    if (front is! String || front.trim().isEmpty) {
      throw FormatException('Card $id is missing a front.');
    }
    final back = json['back'];
    if (back is! String || back.trim().isEmpty) {
      throw FormatException('Card $id is missing a back.');
    }
    final learning = json['learning'];
    if (learning is! bool) {
      throw FormatException('Card $id has an invalid learning flag.');
    }
    if (!json.containsKey('last_review')) {
      throw FormatException('Card $id has an invalid last_review.');
    }
    final rawReview = json['last_review'];
    DateTime? lastReview;
    if (rawReview != null) {
      lastReview = _asTime(rawReview);
      if (lastReview == null) {
        throw FormatException('Card $id has an invalid last_review.');
      }
    }
    final interval = _asInt(json['interval']);
    if (interval == null ||
        interval < SchedulerConstants.minimumIntervalSeconds) {
      throw FormatException('Card $id has an invalid interval.');
    }
    final difficulty = _asDouble(json['difficulty']);
    if (difficulty == null ||
        !(difficulty > 0) ||
        difficulty > SchedulerConstants.difficultyCap) {
      throw FormatException('Card $id has an invalid difficulty.');
    }
    final createdAt = _asTime(json['created_at']);
    if (createdAt == null) {
      throw FormatException('Card $id has an invalid created_at.');
    }
    if (includeReverse && !json.containsKey('reverse')) {
      throw FormatException('Card $id is missing a reverse face.');
    }
    final reverse = _reverseFrom(id, json['reverse'], includeReverse);
    cards.add(
      FlashCard(
        id: id,
        topicId: topicId,
        front: front,
        back: back,
        learning: learning,
        lastReview: lastReview,
        intervalSeconds: interval,
        difficulty: difficulty,
        createdAt: createdAt,
        reverseLearning: reverse.learning,
        reverseLastReview: reverse.lastReview,
        reverseIntervalSeconds: reverse.intervalSeconds,
        reverseDifficulty: reverse.difficulty,
        reverseQueuedAt: reverse.queuedAt,
      ),
    );
  }
  return cards;
}

final class _ReverseFields {
  const _ReverseFields({
    required this.learning,
    required this.lastReview,
    required this.intervalSeconds,
    required this.difficulty,
    required this.queuedAt,
  });

  final bool learning;
  final DateTime? lastReview;
  final int? intervalSeconds;
  final double? difficulty;
  final DateTime? queuedAt;

  static const none = _ReverseFields(
    learning: false,
    lastReview: null,
    intervalSeconds: null,
    difficulty: null,
    queuedAt: null,
  );
}

_ReverseFields _reverseFrom(String id, Object? value, bool includeReverse) {
  if (!includeReverse) return _ReverseFields.none;
  if (value == null) return _ReverseFields.none;
  if (value is! Map) {
    throw FormatException('Card $id has an invalid reverse face.');
  }
  final json = Map<String, Object?>.from(value);
  final learning = _asBool(json['learning']);
  if (learning == null) {
    throw FormatException('Card $id has an invalid reverse face.');
  }
  if (!json.containsKey('last_review')) {
    throw FormatException('Card $id has an invalid reverse face.');
  }
  final rawReview = json['last_review'];
  DateTime? lastReview;
  if (rawReview != null) {
    lastReview = _asTime(rawReview);
    if (lastReview == null) {
      throw FormatException('Card $id has an invalid reverse face.');
    }
  }
  final interval = _asInt(json['interval']);
  if (interval == null ||
      interval < SchedulerConstants.minimumIntervalSeconds) {
    throw FormatException('Card $id has an invalid reverse face.');
  }
  final difficulty = _asDouble(json['difficulty']);
  if (difficulty == null ||
      !(difficulty > 0) ||
      difficulty > SchedulerConstants.difficultyCap) {
    throw FormatException('Card $id has an invalid reverse face.');
  }
  final queuedAt = _asTime(json['queued_at']);
  if (queuedAt == null) {
    throw FormatException('Card $id has an invalid reverse face.');
  }
  return _ReverseFields(
    learning: learning,
    lastReview: lastReview,
    intervalSeconds: interval,
    difficulty: difficulty,
    queuedAt: queuedAt,
  );
}

SchedulerParameters _settingsFrom(Object? value) {
  if (value is! Map) {
    throw const FormatException('Backup is missing settings.');
  }
  final json = Map<String, Object?>.from(value);
  final correct = _asDouble(json['correct_factor']);
  final wrong = _asDouble(json['wrong_factor']);
  final difficulty = _asDouble(json['difficulty_factor']);
  final window = _asInt(json['learning_window_size']);
  final threshold = _asInt(json['learned_threshold']);
  if (correct == null ||
      wrong == null ||
      difficulty == null ||
      window == null ||
      threshold == null) {
    throw const FormatException('Backup settings are not valid.');
  }
  try {
    return SchedulerParameters(
      correctFactor: correct,
      wrongFactor: wrong,
      difficultyFactor: difficulty,
      learningWindowSize: window,
      learnedThreshold: Duration(seconds: threshold),
    );
  } on ArgumentError {
    throw const FormatException('Backup settings are not valid.');
  }
}

bool? _asBool(Object? value) {
  if (value is bool) return value;
  return null;
}

int? _asInt(Object? value) {
  if (value is int) return value;
  if (value is double && value.isFinite && value == value.truncateToDouble()) {
    return value.toInt();
  }
  return null;
}

double? _asDouble(Object? value) {
  if (value is num && value.isFinite) return value.toDouble();
  return null;
}

DateTime? _asTime(Object? value) {
  if (value is! String || value.isEmpty) return null;
  return DateTime.tryParse(value)?.toUtc();
}
