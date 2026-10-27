import '../../domain/scheduler.dart';

/// Learning seats, new cards still waiting, and learned cards that are due.
class StudyCounts {
  const StudyCounts({
    required this.learning,
    required this.newWaiting,
    required this.learnedDue,
  });

  final int learning;
  final int newWaiting;
  final int learnedDue;
}

/// Counts faces in the same scope [selectCard] uses, including the one on screen.
///
/// A waiting reverse counts as a new card. A reverse whose own front is not
/// yet learned does not. One card can add to two counts when both faces are
/// in play. The sentence in [studyStatusLine] still says "cards".
StudyCounts countStudy({
  required List<Topic> topics,
  required List<FlashCard> cards,
  required String? scopeTopicId,
  required DateTime now,
  required SchedulerParameters parameters,
}) {
  final scope = topicIdsInScope(topics, scopeTopicId);
  final topicById = {for (final topic in topics) topic.id: topic};
  var learning = 0;
  var newWaiting = 0;
  var learnedDue = 0;
  for (final card in cards) {
    if (!scope.contains(card.topicId)) continue;
    final reverseDrill = topicById[card.topicId]?.reverseDrill ?? false;
    for (final face in facesInPlay(
      card,
      reverseDrill: reverseDrill,
      parameters: parameters,
    )) {
      if (scheduledLearning(card, face)) {
        learning++;
      } else if (scheduledLastReview(card, face) == null) {
        newWaiting++;
      } else if (faceIsLearned(card, face, parameters) &&
          faceIsDue(card, face, now)) {
        learnedDue++;
      }
    }
  }
  return StudyCounts(
    learning: learning,
    newWaiting: newWaiting,
    learnedDue: learnedDue,
  );
}

/// Status while a card is showing. The clear screen has its own sentence.
///
/// New cards are described as waiting only when the window is full. An open
/// seat is not a wait.
String studyStatusLine({
  required int learning,
  required int window,
  required int newWaiting,
  required int learnedDue,
}) {
  final parts = <String>['Learning $learning of $window.'];
  if (newWaiting > 0 && learning >= window) {
    final waiting = newWaiting == 1
        ? '1 new card is'
        : '$newWaiting new cards are';
    parts.add('$waiting waiting until one of these graduates.');
  }
  if (learnedDue > 0) {
    final due = learnedDue == 1
        ? '1 learned card is'
        : '$learnedDue learned cards are';
    parts.add('$due due.');
  }
  return parts.join(' ');
}
