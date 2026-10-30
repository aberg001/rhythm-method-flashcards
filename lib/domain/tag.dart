import 'scheduler.dart';

/// A library-wide label. Tags are not scheduler settings.
final class Tag {
  const Tag({required this.id, required this.name, required this.position});

  final String id;
  final String name;
  final int position;
}

/// The spelling that is stored. Blank after this trim is rejected.
String canonicalTagName(String name) => name.trim();

/// Uniqueness ignores case after trimming. The stored spelling is kept.
bool tagNamesMatch(String a, String b) {
  return canonicalTagName(a).toLowerCase() == canonicalTagName(b).toLowerCase();
}

/// Cards a session may see.
///
/// No filter returns [cards]. [untagged] keeps cards with no tags.
/// [tagIds] keeps cards that have any of those tags. The two filters are
/// not combined: [untagged] wins when it is set.
List<FlashCard> cardsMatchingTags({
  required List<FlashCard> cards,
  required Map<String, Set<String>> tagsByCard,
  Set<String>? tagIds,
  bool untagged = false,
}) {
  if (untagged) {
    return [
      for (final card in cards)
        if ((tagsByCard[card.id] ?? const <String>{}).isEmpty) card,
    ];
  }
  if (tagIds == null || tagIds.isEmpty) return cards;
  return [
    for (final card in cards)
      if ((tagsByCard[card.id] ?? const <String>{}).any(tagIds.contains)) card,
  ];
}
