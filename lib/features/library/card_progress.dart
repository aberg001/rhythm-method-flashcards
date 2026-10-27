import '../../domain/scheduler.dart';

const _secondsPerHour = Duration.secondsPerMinute * Duration.minutesPerHour;
const _secondsPerDay = _secondsPerHour * Duration.hoursPerDay;

/// A short strength label: `34m`, `6h`, or `4d`.
///
/// Under an hour uses minutes. Under a day uses hours. After that, days.
String formatStudyInterval(Duration duration) {
  final seconds = duration.inSeconds.abs();
  if (seconds < _secondsPerHour) {
    var minutes = (seconds / Duration.secondsPerMinute).round();
    if (minutes < 1 && seconds > 0) minutes = 1;
    return '${minutes}m';
  }
  if (seconds < _secondsPerDay) {
    var hours = (seconds / _secondsPerHour).round();
    if (hours < 1) hours = 1;
    return '${hours}h';
  }
  var days = (seconds / _secondsPerDay).round();
  if (days < 1) days = 1;
  return '${days}d';
}

/// New, learning, or learned, for the forward face in the topic list.
///
/// The interval is the graduation meter while the face is not learned, and
/// the wait afterward. Due is separate, and only learned faces get it.
/// Difficulty is left out: it only rises, so it is not a mastery score.
String cardProgressLabel({
  required FlashCard card,
  required SchedulerParameters parameters,
  required DateTime now,
}) {
  return faceProgressLabel(
    card: card,
    face: StudyFace.forward,
    parameters: parameters,
    now: now,
  );
}

/// The same label as [cardProgressLabel], for one face.
///
/// A reverse that has not been created yet reads as New.
String faceProgressLabel({
  required FlashCard card,
  required StudyFace face,
  required SchedulerParameters parameters,
  required DateTime now,
}) {
  if (face == StudyFace.reverse && !card.hasReverse) return 'New';
  final learning = scheduledLearning(card, face);
  final reviewed = scheduledLastReview(card, face);
  if (!learning && reviewed == null) return 'New';
  final interval = Duration(seconds: scheduledInterval(card, face));
  if (!faceIsLearned(card, face, parameters)) {
    final shown = formatStudyInterval(interval);
    if (interval > parameters.learnedThreshold) {
      return 'Learning · $shown';
    }
    final threshold = formatStudyInterval(parameters.learnedThreshold);
    return 'Learning · $shown / $threshold';
  }
  final label = 'Learned · ${formatStudyInterval(interval)}';
  if (faceIsDue(card, face, now)) return '$label · Due';
  return label;
}
