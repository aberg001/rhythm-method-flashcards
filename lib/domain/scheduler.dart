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
  });

  final String id;
  final String name;
  final String? parentId;

  /// Order among topics that share a parent. The scheduler does not use this.
  final int position;
}

enum GradeOutcome { correct, wrong }

/// One card. Schedule fields change only through [gradeCard] and [selectCard].
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

  bool get isNew => !learning && lastReview == null;

  FlashCard copyWith({
    bool? learning,
    Object? lastReview = _keep,
    int? intervalSeconds,
    double? difficulty,
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
        other.createdAt == createdAt;
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
  const CardSelected(this.card, {required this.admitted});

  final FlashCard card;
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

/// Updates [card] for one Correct or Wrong answer at [now].
GradeResult gradeCard({
  required FlashCard card,
  required GradeOutcome outcome,
  required DateTime now,
  required SchedulerParameters parameters,
}) {
  parameters.validate();
  final next = switch (outcome) {
    GradeOutcome.correct => _gradeCorrect(card, parameters),
    GradeOutcome.wrong => _gradeWrong(card, parameters),
  };
  final after = next.copyWith(lastReview: now);
  return GradeResult(
    before: card,
    after: after,
    review: ReviewRecord(
      cardId: card.id,
      reviewedAt: now,
      outcome: outcome,
      intervalBefore: card.intervalSeconds,
      intervalAfter: after.intervalSeconds,
      difficultyBefore: card.difficulty,
      difficultyAfter: after.difficulty,
      learningBefore: card.learning,
      learningAfter: after.learning,
    ),
  );
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

/// Chooses the next card in [scopeTopicId], or the whole library when that
/// is null. Does not read a clock or a random source itself.
///
/// When the result is [CardSelected] with `admitted` true, the returned card
/// has `learning` set and must replace the caller's copy before the next
/// select. Otherwise the same new card would be admitted again.
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
  final inScope = [
    for (final card in cards)
      if (scope.contains(card.topicId)) card,
  ];

  final dueLearned = [
    for (final card in inScope)
      if (cardIsLearned(card, parameters) && cardIsDue(card, now)) card,
  ]..sort((a, b) => _compareDue(a, b, now));
  if (dueLearned.isNotEmpty) {
    return CardSelected(dueLearned.first, admitted: false);
  }

  final learning = [
    for (final card in inScope)
      if (card.learning) card,
  ]..sort(_compareMostRecentFirst);
  final fresh = [
    for (final card in inScope)
      if (card.isNew) card,
  ]..sort(_compareNewCards);

  final learningCount = learning.length;
  final includeNew =
      learningCount < parameters.learningWindowSize && fresh.isNotEmpty;

  if (learningCount == 0) {
    if (!includeNew) return const SessionClear();
    return CardSelected(fresh.first.copyWith(learning: true), admitted: true);
  }

  final candidates = <_Candidate>[
    for (var rank = 0; rank < learning.length; rank++)
      _Candidate(learning[rank], rank),
  ];
  if (includeNew) {
    candidates.add(_Candidate(fresh.first, learningCount, admit: true));
  }

  final total = candidates.fold<int>(
    0,
    (sum, candidate) => sum + candidate.weight,
  );
  if (total == 0) {
    return CardSelected(learning.single, admitted: false);
  }

  final picked = draw(total);
  if (picked < 0 || picked >= total) {
    throw RangeError.range(picked, 0, total - 1, 'draw');
  }
  var cumulative = 0;
  for (final candidate in candidates) {
    cumulative += candidate.weight;
    if (cumulative > picked) {
      final card = candidate.admit
          ? candidate.card.copyWith(learning: true)
          : candidate.card;
      return CardSelected(card, admitted: candidate.admit);
    }
  }
  throw StateError('weight draw missed every candidate');
}

final class _Candidate {
  const _Candidate(this.card, this.weight, {this.admit = false});

  final FlashCard card;
  final int weight;
  final bool admit;
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
  return !card.learning &&
      card.lastReview != null &&
      Duration(seconds: card.intervalSeconds) > parameters.learnedThreshold;
}

/// Due when the review time plus the interval is at or before [now].
bool cardIsDue(FlashCard card, DateTime now) {
  final reviewed = card.lastReview;
  if (reviewed == null) return false;
  final dueAt = reviewed.add(Duration(seconds: card.intervalSeconds));
  return !dueAt.isAfter(now);
}

int _compareDue(FlashCard a, FlashCard b, DateTime now) {
  final byRatio = _overdueRatio(b, now).compareTo(_overdueRatio(a, now));
  if (byRatio != 0) return byRatio;
  final byLateness = _absoluteLateness(
    b,
    now,
  ).compareTo(_absoluteLateness(a, now));
  if (byLateness != 0) return byLateness;
  final byCreated = a.createdAt.compareTo(b.createdAt);
  if (byCreated != 0) return byCreated;
  return a.id.compareTo(b.id);
}

double _overdueRatio(FlashCard card, DateTime now) {
  final elapsed = now.difference(card.lastReview!).inMicroseconds;
  final interval = Duration(seconds: card.intervalSeconds).inMicroseconds;
  return elapsed / interval;
}

int _absoluteLateness(FlashCard card, DateTime now) {
  final dueAt = card.lastReview!.add(Duration(seconds: card.intervalSeconds));
  return now.difference(dueAt).inMicroseconds;
}

/// Negative when [a] was reviewed more recently than [b].
int _compareMostRecentFirst(FlashCard a, FlashCard b) {
  final aReview = a.lastReview;
  final bReview = b.lastReview;
  if (aReview == null && bReview != null) return 1;
  if (aReview != null && bReview == null) return -1;
  if (aReview != null && bReview != null) {
    final byReview = bReview.compareTo(aReview);
    if (byReview != 0) return byReview;
  }
  final byCreated = b.createdAt.compareTo(a.createdAt);
  if (byCreated != 0) return byCreated;
  return b.id.compareTo(a.id);
}

int _compareNewCards(FlashCard a, FlashCard b) {
  final byCreated = a.createdAt.compareTo(b.createdAt);
  if (byCreated != 0) return byCreated;
  return a.id.compareTo(b.id);
}
