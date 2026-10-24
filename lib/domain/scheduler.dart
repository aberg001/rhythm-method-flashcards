import 'dart:math' as math;

/// Fixed bounds from the scheduling spec. These are not user settings.
abstract final class SchedulerConstants {
  static const initialInterval = Duration(minutes: 10);
  static const minimumInterval = Duration(minutes: 1);
  static const initialDifficulty = 1.0;
  static const minimumGrowth = 1.15;
  static const difficultyCap = 10.0;

  static const initialIntervalSeconds = 600;
  static const minimumIntervalSeconds = 60;
}

/// The five user-tunable scheduler parameters.
final class SchedulerParameters {
  SchedulerParameters({
    required this.correctFactor,
    required this.wrongFactor,
    required this.difficultyFactor,
    required this.learningWindowSize,
    required this.learnedThreshold,
  }) {
    validate();
  }

  factory SchedulerParameters.defaults() {
    return SchedulerParameters(
      correctFactor: 1.5,
      wrongFactor: 0.5,
      difficultyFactor: 0.01,
      learningWindowSize: 10,
      learnedThreshold: const Duration(hours: 1),
    );
  }

  final double correctFactor;
  final double wrongFactor;
  final double difficultyFactor;
  final int learningWindowSize;
  final Duration learnedThreshold;

  void validate() {
    if (!(correctFactor > 1)) {
      throw ArgumentError.value(
        correctFactor,
        'correctFactor',
        'must be greater than 1',
      );
    }
    if (!(wrongFactor > 0 && wrongFactor < 1)) {
      throw ArgumentError.value(
        wrongFactor,
        'wrongFactor',
        'must be greater than 0 and less than 1',
      );
    }
    if (!(difficultyFactor >= 0)) {
      throw ArgumentError.value(
        difficultyFactor,
        'difficultyFactor',
        'must be zero or greater',
      );
    }
    if (learningWindowSize < 1) {
      throw ArgumentError.value(
        learningWindowSize,
        'learningWindowSize',
        'must be an integer of at least 1',
      );
    }
    if (!(learnedThreshold > Duration.zero)) {
      throw ArgumentError.value(
        learnedThreshold,
        'learnedThreshold',
        'must be greater than zero',
      );
    }
  }
}

/// A topic in the library tree. A topic may contain child topics and cards.
final class Topic {
  const Topic({
    required this.id,
    required this.name,
    this.parentId,
    this.position = 0,
    this.reverseDrill = false,
  });

  final String id;
  final String name;
  final String? parentId;

  /// Order among topics that share a parent. The scheduler does not use this.
  final int position;

  /// When true, this topic's own cards can grow a reverse face. Subtopics
  /// do not inherit it. A card follows the switch on its own topic.
  final bool reverseDrill;
}

enum GradeOutcome { correct, wrong }

/// Which side of a card a grade or a selection refers to.
///
/// [forward] prompts with the front. [reverse] prompts with the back.
enum StudyFace { forward, reverse }

/// One card. Schedule fields change only through [gradeCard] and [selectCard].
///
/// The fields above [createdAt] are the forward face. A null [reverseQueuedAt]
/// means there is no reverse face. The reverse schedule is not a copy of the
/// forward one.
final class FlashCard {
  const FlashCard({
    required this.id,
    required this.topicId,
    required this.front,
    required this.back,
    required this.learning,
    required this.lastReview,
    required this.intervalSeconds,
    required this.difficulty,
    required this.createdAt,
    this.reverseLearning = false,
    this.reverseLastReview,
    this.reverseIntervalSeconds,
    this.reverseDifficulty,
    this.reverseQueuedAt,
  });

  factory FlashCard.fresh({
    required String id,
    required String topicId,
    required String front,
    required String back,
    required DateTime createdAt,
  }) {
    return FlashCard(
      id: id,
      topicId: topicId,
      front: front,
      back: back,
      learning: false,
      lastReview: null,
      intervalSeconds: SchedulerConstants.initialIntervalSeconds,
      difficulty: SchedulerConstants.initialDifficulty,
      createdAt: createdAt,
    );
  }

  final String id;
  final String topicId;
  final String front;
  final String back;
  final bool learning;
  final DateTime? lastReview;
  final int intervalSeconds;
  final double difficulty;
  final DateTime createdAt;

  /// Reverse-face schedule. Ignored unless [hasReverse] is true.
  final bool reverseLearning;
  final DateTime? reverseLastReview;
  final int? reverseIntervalSeconds;
  final double? reverseDifficulty;

  /// When the reverse face joined the new-face line. Null means no reverse.
  final DateTime? reverseQueuedAt;

  bool get isNew => !learning && lastReview == null;

  bool get hasReverse => reverseQueuedAt != null;

  FlashCard copyWith({
    bool? learning,
    Object? lastReview = _keep,
    int? intervalSeconds,
    double? difficulty,
    bool? reverseLearning,
    Object? reverseLastReview = _keep,
    Object? reverseIntervalSeconds = _keep,
    Object? reverseDifficulty = _keep,
    Object? reverseQueuedAt = _keep,
  }) {
    return FlashCard(
      id: id,
      topicId: topicId,
      front: front,
      back: back,
      learning: learning ?? this.learning,
      lastReview: lastReview == _keep
          ? this.lastReview
          : lastReview as DateTime?,
      intervalSeconds: intervalSeconds ?? this.intervalSeconds,
      difficulty: difficulty ?? this.difficulty,
      createdAt: createdAt,
      reverseLearning: reverseLearning ?? this.reverseLearning,
      reverseLastReview: reverseLastReview == _keep
          ? this.reverseLastReview
          : reverseLastReview as DateTime?,
      reverseIntervalSeconds: reverseIntervalSeconds == _keep
          ? this.reverseIntervalSeconds
          : reverseIntervalSeconds as int?,
      reverseDifficulty: reverseDifficulty == _keep
          ? this.reverseDifficulty
          : reverseDifficulty as double?,
      reverseQueuedAt: reverseQueuedAt == _keep
          ? this.reverseQueuedAt
          : reverseQueuedAt as DateTime?,
    );
  }

  @override
  bool operator ==(Object other) {
    return other is FlashCard &&
        other.id == id &&
        other.topicId == topicId &&
        other.front == front &&
        other.back == back &&
        other.learning == learning &&
        other.lastReview == lastReview &&
        other.intervalSeconds == intervalSeconds &&
        other.difficulty == difficulty &&
        other.createdAt == createdAt &&
        other.reverseLearning == reverseLearning &&
        other.reverseLastReview == reverseLastReview &&
        other.reverseIntervalSeconds == reverseIntervalSeconds &&
        other.reverseDifficulty == reverseDifficulty &&
        other.reverseQueuedAt == reverseQueuedAt;
  }

  @override
  int get hashCode => Object.hash(
    id,
    topicId,
    front,
    back,
    learning,
    lastReview,
    intervalSeconds,
    difficulty,
    createdAt,
    reverseLearning,
    reverseLastReview,
    reverseIntervalSeconds,
    reverseDifficulty,
    reverseQueuedAt,
  );
}

const _keep = Object();

/// A stored review, including the schedule fields from before and after the grade.
final class ReviewRecord {
  const ReviewRecord({
    required this.cardId,
    required this.reviewedAt,
    required this.outcome,
    required this.intervalBefore,
    required this.intervalAfter,
    required this.difficultyBefore,
    required this.difficultyAfter,
    required this.learningBefore,
    required this.learningAfter,
    this.face = StudyFace.forward,
  });

  final String cardId;
  final DateTime reviewedAt;
  final GradeOutcome outcome;
  final int intervalBefore;
  final int intervalAfter;
  final double difficultyBefore;
  final double difficultyAfter;
  final bool learningBefore;
  final bool learningAfter;

  /// The face this review graded. Undo shows this face again.
  final StudyFace face;
}

/// The card before and after one grade. [before] is the undo snapshot.
final class GradeResult {
  const GradeResult({
    required this.before,
    required this.after,
    required this.review,
  });

  final FlashCard before;
  final FlashCard after;
  final ReviewRecord review;
}

/// Newest grade at the end. [undo] restores that grade's snapshot.
final class GradeUndoStack {
  final List<GradeResult> _grades = [];

  int get length => _grades.length;

  void push(GradeResult result) => _grades.add(result);

  /// Restores the card from the newest grade, or returns null when empty.
  FlashCard? undo() {
    if (_grades.isEmpty) return null;
    return _grades.removeLast().before;
  }
}

/// What [selectCard] chose. [admitted] is true only when this call moved a
/// new card into the learning window.
sealed class Selection {
  const Selection();
}

final class CardSelected extends Selection {
  const CardSelected(
    this.card, {
    this.face = StudyFace.forward,
    required this.admitted,
  });

  final FlashCard card;
  final StudyFace face;
  final bool admitted;
}

final class SessionClear extends Selection {
  const SessionClear();
}

/// Uniform integer in `0 .. total - 1`. [selectCard] calls this only when
/// [total] is positive.
typedef WeightDraw = int Function(int total);

/// A draw for production. Tests pass their own [WeightDraw] instead.
int randomWeightDraw(int total, [math.Random? random]) {
  return (random ?? math.Random()).nextInt(total);
}

/// Updates one face of [card] for one Correct or Wrong answer at [now].
///
/// The other face is left as it was. A reverse grade requires [card.hasReverse].
GradeResult gradeCard({
  required FlashCard card,
  required GradeOutcome outcome,
  required DateTime now,
  required SchedulerParameters parameters,
  StudyFace face = StudyFace.forward,
}) {
  parameters.validate();
  if (face == StudyFace.reverse && !card.hasReverse) {
    throw StateError('Card ${card.id} has no reverse face');
  }
  final graded = switch (face) {
    StudyFace.forward => switch (outcome) {
      GradeOutcome.correct => _gradeCorrect(card, parameters),
      GradeOutcome.wrong => _gradeWrong(card, parameters),
    },
    StudyFace.reverse => _gradeReverse(card, outcome, parameters),
  };
  final after = face == StudyFace.forward
      ? graded.copyWith(lastReview: now)
      : graded.copyWith(reverseLastReview: now);
  return GradeResult(
    before: card,
    after: after,
    review: ReviewRecord(
      cardId: card.id,
      reviewedAt: now,
      outcome: outcome,
      face: face,
      intervalBefore: scheduledInterval(card, face),
      intervalAfter: scheduledInterval(after, face),
      difficultyBefore: scheduledDifficulty(card, face),
      difficultyAfter: scheduledDifficulty(after, face),
      learningBefore: scheduledLearning(card, face),
      learningAfter: scheduledLearning(after, face),
    ),
  );
}

/// True when this correct answer is the one that cleared the forward face.
bool forwardJustGraduated({
  required FlashCard before,
  required FlashCard after,
  required SchedulerParameters parameters,
}) {
  return before.learning && cardIsLearned(after, parameters);
}

/// Attaches a new reverse face at the initial interval and difficulty.
///
/// [queuedAt] is the place in the new-face line. A later timestamp is closer
/// to the front. Throws when the card already has a reverse face.
FlashCard spawnReverseFace(FlashCard card, {required DateTime queuedAt}) {
  if (card.hasReverse) {
    throw StateError('Card ${card.id} already has a reverse face');
  }
  return card.copyWith(
    reverseLearning: false,
    reverseLastReview: null,
    reverseIntervalSeconds: SchedulerConstants.initialIntervalSeconds,
    reverseDifficulty: SchedulerConstants.initialDifficulty,
    reverseQueuedAt: queuedAt,
  );
}

/// Queue time for a reverse just created by a graduation.
///
/// It is a whole UTC second strictly after [now] and strictly after every
/// existing queue time, so the new face is the head of the waiting-reverse
/// line. Whole seconds are required because SQLite stores these timestamps
/// at second resolution.
DateTime nextReverseQueuedAt(Iterable<DateTime?> existing, DateTime now) {
  var head = _wholeUtcSecond(now);
  for (final queued in existing) {
    if (queued == null) continue;
    final secs = _wholeUtcSecond(queued);
    if (!secs.isBefore(head)) head = secs;
  }
  return head.add(const Duration(seconds: 1));
}

/// Exclusive upper bound for reverses created when a topic switch turns on.
///
/// Every assigned timestamp is a whole UTC second before this and before
/// every existing queue time, so a later graduation still cuts in front of
/// the backfill.
DateTime reverseBackfillCeiling(Iterable<DateTime?> existing, DateTime now) {
  var ceiling = _wholeUtcSecond(now);
  for (final queued in existing) {
    if (queued == null) continue;
    final secs = _wholeUtcSecond(queued);
    if (secs.isBefore(ceiling)) ceiling = secs;
  }
  return ceiling;
}

DateTime _wholeUtcSecond(DateTime value) {
  final utc = value.toUtc();
  return DateTime.utc(
    utc.year,
    utc.month,
    utc.day,
    utc.hour,
    utc.minute,
    utc.second,
  );
}

/// Orders [learnedWithoutReverse] so the card known longest is closest to
/// [ceiling], then gives each one a fresh reverse face.
///
/// [ceiling] comes from [reverseBackfillCeiling]. Cards are not mutated.
List<FlashCard> queueReverseBackfill(
  List<FlashCard> learnedWithoutReverse, {
  required DateTime ceiling,
}) {
  final ordered = [...learnedWithoutReverse]
    ..sort((a, b) {
      final byReview = a.lastReview!.compareTo(b.lastReview!);
      if (byReview != 0) return byReview;
      return a.id.compareTo(b.id);
    });
  final queued = <FlashCard>[];
  var cursor = _wholeUtcSecond(ceiling);
  for (final card in ordered) {
    cursor = cursor.subtract(const Duration(seconds: 1));
    queued.add(spawnReverseFace(card, queuedAt: cursor));
  }
  return queued;
}

bool scheduledLearning(FlashCard card, StudyFace face) {
  return face == StudyFace.forward ? card.learning : card.reverseLearning;
}

DateTime? scheduledLastReview(FlashCard card, StudyFace face) {
  return face == StudyFace.forward ? card.lastReview : card.reverseLastReview;
}

int scheduledInterval(FlashCard card, StudyFace face) {
  return face == StudyFace.forward
      ? card.intervalSeconds
      : card.reverseIntervalSeconds!;
}

double scheduledDifficulty(FlashCard card, StudyFace face) {
  return face == StudyFace.forward ? card.difficulty : card.reverseDifficulty!;
}

/// Faces that take a window seat or can be selected.
///
/// The reverse face is included only when the card's own topic has the
/// switch on and the face exists.
List<StudyFace> facesInPlay(FlashCard card, {required bool reverseDrill}) {
  if (reverseDrill && card.hasReverse) {
    return const [StudyFace.forward, StudyFace.reverse];
  }
  return const [StudyFace.forward];
}

FlashCard _gradeCorrect(FlashCard card, SchedulerParameters parameters) {
  final growth = _growth(parameters, card.difficulty);
  final interval = _advance(card.intervalSeconds, growth);
  final graduated = Duration(seconds: interval) > parameters.learnedThreshold;
  return card.copyWith(intervalSeconds: interval, learning: !graduated);
}

FlashCard _gradeWrong(FlashCard card, SchedulerParameters parameters) {
  final interval = _shrink(card.intervalSeconds, parameters.wrongFactor);
  final difficulty = math.min(
    SchedulerConstants.difficultyCap,
    card.difficulty + parameters.difficultyFactor,
  );
  return card.copyWith(
    intervalSeconds: interval,
    difficulty: difficulty,
    learning: true,
  );
}

/// Applies the forward grade math to the reverse schedule only.
FlashCard _gradeReverse(
  FlashCard card,
  GradeOutcome outcome,
  SchedulerParameters parameters,
) {
  final projected = FlashCard(
    id: card.id,
    topicId: card.topicId,
    front: card.front,
    back: card.back,
    learning: card.reverseLearning,
    lastReview: card.reverseLastReview,
    intervalSeconds: card.reverseIntervalSeconds!,
    difficulty: card.reverseDifficulty!,
    createdAt: card.createdAt,
  );
  final graded = switch (outcome) {
    GradeOutcome.correct => _gradeCorrect(projected, parameters),
    GradeOutcome.wrong => _gradeWrong(projected, parameters),
  };
  return card.copyWith(
    reverseLearning: graded.learning,
    reverseIntervalSeconds: graded.intervalSeconds,
    reverseDifficulty: graded.difficulty,
  );
}

double _growth(SchedulerParameters parameters, double difficulty) {
  final raw = parameters.correctFactor / difficulty;
  final lower = math.min(
    parameters.correctFactor,
    SchedulerConstants.minimumGrowth,
  );
  return raw.clamp(lower, parameters.correctFactor).toDouble();
}

int _advance(int intervalSeconds, double factor) {
  var next = (intervalSeconds * factor).round();
  if (factor > 1 && next <= intervalSeconds) {
    next = intervalSeconds + 1;
  }
  return math.max(next, SchedulerConstants.minimumIntervalSeconds);
}

int _shrink(int intervalSeconds, double factor) {
  final next = (intervalSeconds * factor).round();
  return math.max(next, SchedulerConstants.minimumIntervalSeconds);
}

/// Chooses the next face in [scopeTopicId], or the whole library when that
/// is null. Does not read a clock or a random source itself.
///
/// When the result is [CardSelected] with `admitted` true, the returned card
/// has that face's learning flag set and must replace the caller's copy
/// before the next select. Otherwise the same new face would be admitted again.
///
/// With no reverse faces in play this is the same choice as a card-only draw.
Selection selectCard({
  required List<Topic> topics,
  required List<FlashCard> cards,
  required String? scopeTopicId,
  required DateTime now,
  required SchedulerParameters parameters,
  required WeightDraw draw,
}) {
  parameters.validate();
  final scope = topicIdsInScope(topics, scopeTopicId);
  final topicById = {for (final topic in topics) topic.id: topic};
  final faces = <_Face>[
    for (final card in cards)
      if (scope.contains(card.topicId))
        ..._facesOf(card, topicById[card.topicId]),
  ];

  final dueLearned = [
    for (final face in faces)
      if (face.isLearned(parameters) && face.isDue(now)) face,
  ]..sort((a, b) => _compareDueFaces(a, b, now));
  if (dueLearned.isNotEmpty) {
    final chosen = dueLearned.first;
    return CardSelected(chosen.card, face: chosen.direction, admitted: false);
  }

  final learning = [
    for (final face in faces)
      if (face.learning) face,
  ]..sort(_compareLearningFaces);
  final nextNew = _nextNewFace(faces);

  final learningCount = learning.length;
  final includeNew =
      learningCount < parameters.learningWindowSize && nextNew != null;

  if (learningCount == 0) {
    if (!includeNew) return const SessionClear();
    final fresh = nextNew;
    return CardSelected(_admit(fresh), face: fresh.direction, admitted: true);
  }

  final candidates = <_Candidate>[
    for (var rank = 0; rank < learning.length; rank++)
      _Candidate(learning[rank], rank),
  ];
  if (includeNew) {
    candidates.add(_Candidate(nextNew, learningCount, admit: true));
  }

  final total = candidates.fold<int>(
    0,
    (sum, candidate) => sum + candidate.weight,
  );
  if (total == 0) {
    final only = learning.single;
    return CardSelected(only.card, face: only.direction, admitted: false);
  }

  final picked = draw(total);
  if (picked < 0 || picked >= total) {
    throw RangeError.range(picked, 0, total - 1, 'draw');
  }
  var cumulative = 0;
  for (final candidate in candidates) {
    cumulative += candidate.weight;
    if (cumulative > picked) {
      final face = candidate.face;
      final card = candidate.admit ? _admit(face) : face.card;
      return CardSelected(
        card,
        face: face.direction,
        admitted: candidate.admit,
      );
    }
  }
  throw StateError('weight draw missed every candidate');
}

final class _Candidate {
  const _Candidate(this.face, this.weight, {this.admit = false});

  final _Face face;
  final int weight;
  final bool admit;
}

final class _Face {
  const _Face(this.card, this.direction);

  final FlashCard card;
  final StudyFace direction;

  bool get learning => scheduledLearning(card, direction);

  DateTime? get lastReview => scheduledLastReview(card, direction);

  int get intervalSeconds => scheduledInterval(card, direction);

  bool get isNew => !learning && lastReview == null;

  bool isLearned(SchedulerParameters parameters) {
    return !learning &&
        lastReview != null &&
        Duration(seconds: intervalSeconds) > parameters.learnedThreshold;
  }

  bool isDue(DateTime now) {
    final reviewed = lastReview;
    if (reviewed == null) return false;
    final dueAt = reviewed.add(Duration(seconds: intervalSeconds));
    return !dueAt.isAfter(now);
  }
}

List<_Face> _facesOf(FlashCard card, Topic? topic) {
  return [
    for (final direction in facesInPlay(
      card,
      reverseDrill: topic?.reverseDrill ?? false,
    ))
      _Face(card, direction),
  ];
}

FlashCard _admit(_Face face) {
  return face.direction == StudyFace.forward
      ? face.card.copyWith(learning: true)
      : face.card.copyWith(reverseLearning: true);
}

/// The one new face that may join the draw: the head waiting reverse, or
/// the oldest never-started card when no reverse is waiting.
_Face? _nextNewFace(List<_Face> faces) {
  final reverses = [
    for (final face in faces)
      if (face.direction == StudyFace.reverse && face.isNew) face,
  ]..sort(_compareWaitingReverses);
  if (reverses.isNotEmpty) return reverses.first;
  final fresh = [
    for (final face in faces)
      if (face.direction == StudyFace.forward && face.isNew) face,
  ]..sort(_compareNewFaces);
  if (fresh.isEmpty) return null;
  return fresh.first;
}

/// Topic ids in [scopeTopicId] plus descendants. Null means every topic passed in.
Set<String> topicIdsInScope(List<Topic> topics, String? scopeTopicId) {
  if (scopeTopicId == null) {
    return {for (final topic in topics) topic.id};
  }
  final children = <String, List<String>>{};
  for (final topic in topics) {
    final parentId = topic.parentId;
    if (parentId != null) {
      children.putIfAbsent(parentId, () => []).add(topic.id);
    }
  }
  final scope = <String>{};
  void walk(String id) {
    if (!scope.add(id)) return;
    for (final childId in children[id] ?? const <String>[]) {
      walk(childId);
    }
  }

  walk(scopeTopicId);
  return scope;
}

/// Learned means not in the window, reviewed at least once, and interval strictly above the threshold.
bool cardIsLearned(FlashCard card, SchedulerParameters parameters) {
  return faceIsLearned(card, StudyFace.forward, parameters);
}

/// Due when the review time plus the interval is at or before [now].
bool cardIsDue(FlashCard card, DateTime now) {
  return faceIsDue(card, StudyFace.forward, now);
}

bool faceIsLearned(
  FlashCard card,
  StudyFace face,
  SchedulerParameters parameters,
) {
  return _Face(card, face).isLearned(parameters);
}

bool faceIsDue(FlashCard card, StudyFace face, DateTime now) {
  return _Face(card, face).isDue(now);
}

int _compareDueFaces(_Face a, _Face b, DateTime now) {
  final byRatio = _overdueRatio(b, now).compareTo(_overdueRatio(a, now));
  if (byRatio != 0) return byRatio;
  final byLateness = _absoluteLateness(
    b,
    now,
  ).compareTo(_absoluteLateness(a, now));
  if (byLateness != 0) return byLateness;
  final byCreated = a.card.createdAt.compareTo(b.card.createdAt);
  if (byCreated != 0) return byCreated;
  final byId = a.card.id.compareTo(b.card.id);
  if (byId != 0) return byId;
  return a.direction.index.compareTo(b.direction.index);
}

double _overdueRatio(_Face face, DateTime now) {
  final elapsed = now.difference(face.lastReview!).inMicroseconds;
  final interval = Duration(seconds: face.intervalSeconds).inMicroseconds;
  return elapsed / interval;
}

int _absoluteLateness(_Face face, DateTime now) {
  final dueAt = face.lastReview!.add(Duration(seconds: face.intervalSeconds));
  return now.difference(dueAt).inMicroseconds;
}

/// Negative when [a] was reviewed more recently than [b].
int _compareLearningFaces(_Face a, _Face b) {
  final aReview = a.lastReview;
  final bReview = b.lastReview;
  if (aReview == null && bReview != null) return 1;
  if (aReview != null && bReview == null) return -1;
  if (aReview != null && bReview != null) {
    final byReview = bReview.compareTo(aReview);
    if (byReview != 0) return byReview;
  }
  final byCreated = b.card.createdAt.compareTo(a.card.createdAt);
  if (byCreated != 0) return byCreated;
  final byId = b.card.id.compareTo(a.card.id);
  if (byId != 0) return byId;
  return a.direction.index.compareTo(b.direction.index);
}

int _compareNewFaces(_Face a, _Face b) {
  final byCreated = a.card.createdAt.compareTo(b.card.createdAt);
  if (byCreated != 0) return byCreated;
  return a.card.id.compareTo(b.card.id);
}

/// Later queue time first. That is the reverse a graduation just created.
int _compareWaitingReverses(_Face a, _Face b) {
  final byQueue = b.card.reverseQueuedAt!.compareTo(a.card.reverseQueuedAt!);
  if (byQueue != 0) return byQueue;
  return a.card.id.compareTo(b.card.id);
}
