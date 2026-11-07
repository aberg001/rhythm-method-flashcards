import 'dart:convert';

import '../domain/scheduler.dart';
import '../domain/tag.dart';

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

/// A tag row in a backup. Position is the library order.
final class BackupTag {
  const BackupTag({
    required this.id,
    required this.name,
    required this.position,
  });

  final String id;
  final String name;
  final int position;
}

/// One backup. Review rows are not part of the file.
///
/// Version 3 is what this app writes. Versions 1 and 2 are still accepted.
/// A version 1 file has the reverse switch off and no reverse faces. A file
/// older than version 3 has no tags.
final class LibraryBackup {
  const LibraryBackup({
    required this.topics,
    required this.cards,
    required this.settings,
    this.tags = const [],
    this.cardTagIds = const {},
  });

  final List<BackupTopic> topics;
  final List<BackupTag> tags;
  final List<FlashCard> cards;

  /// Tag ids for each card, in backup order. Cards with no tags are absent.
  final Map<String, List<String>> cardTagIds;
  final SchedulerParameters settings;
}

/// Version 3 backup of topics, tags, cards, and the five settings.
///
/// Review rows are left out. [parseLibraryBackup] reads this file back,
/// including a version 1 or version 2 file.
String libraryBackupJson({
  required List<BackupTopic> topics,
  required List<FlashCard> cards,
  required SchedulerParameters settings,
  List<BackupTag> tags = const [],
  Map<String, List<String>> cardTagIds = const {},
}) {
  final payload = <String, Object?>{
    'version': 3,
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
    'tags': [
      for (final tag in tags)
        <String, Object?>{
          'id': tag.id,
          'name': tag.name,
          'position': tag.position,
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
          'tag_ids': cardTagIds[card.id] ?? const <String>[],
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

/// Reads a version 1, 2, or 3 backup. Throws [FormatException] when the
/// file cannot be restored without changing the scheduler's meaning.
///
/// A version 1 file has the reverse switch off and no reverse faces.
/// A file older than version 3 has no tags.
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
  if (version is! num || (version != 1 && version != 2 && version != 3)) {
    throw const FormatException('Backup version is not supported.');
  }
  final includeReverse = version != 1;
  final includeTags = version == 3;

  final topics = _topicsFrom(json['topics'], includeReverse: includeReverse);
  final topicIds = {for (final topic in topics) topic.id};
  _rejectTopicCycles(topics);
  final tags = includeTags ? _tagsFrom(json['tags']) : const <BackupTag>[];
  final parsed = _cardsFrom(
    json['cards'],
    topicIds,
    includeReverse: includeReverse,
    tagIds: {for (final tag in tags) tag.id},
    includeTags: includeTags,
  );
  return LibraryBackup(
    topics: topics,
    tags: tags,
    cards: parsed.cards,
    cardTagIds: parsed.tagIds,
    settings: _settingsFrom(json['settings']),
  );
}

List<BackupTag> _tagsFrom(Object? value) {
  if (value is! List) {
    throw const FormatException('Backup is missing tags.');
  }
  final tags = <BackupTag>[];
  final seenIds = <String>{};
  final seenNames = <String>{};
  for (final item in value) {
    if (item is! Map) {
      throw const FormatException('A tag is missing an id.');
    }
    final json = Map<String, Object?>.from(item);
    final id = json['id'];
    if (id is! String || id.isEmpty) {
      throw const FormatException('A tag is missing an id.');
    }
    if (!seenIds.add(id)) {
      throw FormatException('Tag $id appears more than once.');
    }
    final name = json['name'];
    if (name is! String || canonicalTagName(name).isEmpty) {
      throw FormatException('Tag $id is missing a name.');
    }
    final stored = canonicalTagName(name);
    if (!seenNames.add(stored.toLowerCase())) {
      throw FormatException('Tag $stored appears more than once.');
    }
    final position = _asInt(json['position']);
    if (position == null || position < 0) {
      throw FormatException('Tag $id has an invalid position.');
    }
    tags.add(BackupTag(id: id, name: stored, position: position));
  }
  return tags;
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

({List<FlashCard> cards, Map<String, List<String>> tagIds}) _cardsFrom(
  Object? value,
  Set<String> topicIds, {
  required bool includeReverse,
  required bool includeTags,
  required Set<String> tagIds,
}) {
  if (value is! List) {
    throw const FormatException('Backup is missing cards.');
  }
  final cards = <FlashCard>[];
  final cardTagIds = <String, List<String>>{};
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
    if (includeTags) {
      final ids = _cardTagIdsFrom(id, json['tag_ids'], tagIds);
      if (ids.isNotEmpty) cardTagIds[id] = ids;
    }
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
  return (cards: cards, tagIds: cardTagIds);
}

List<String> _cardTagIdsFrom(String id, Object? value, Set<String> known) {
  if (value is! List) {
    throw FormatException('Card $id is missing tags.');
  }
  final ids = <String>[];
  final seen = <String>{};
  for (final item in value) {
    if (item is! String || item.isEmpty) {
      throw FormatException('Card $id has an invalid tag.');
    }
    if (!seen.add(item)) {
      throw FormatException('Card $id lists tag $item more than once.');
    }
    if (!known.contains(item)) {
      throw FormatException('Card $id has a tag that is not in the backup.');
    }
    ids.add(item);
  }
  return ids;
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
