import 'package:flutter_test/flutter_test.dart';
import 'package:rhythm_method_flashcards/domain/scheduler.dart';
import 'package:rhythm_method_flashcards/domain/tag.dart';

void main() {
  FlashCard card(String id) {
    return FlashCard.fresh(
      id: id,
      topicId: 'topic',
      front: id,
      back: 'back',
      createdAt: DateTime.utc(2026, 1, 1),
    );
  }

  final cards = [card('a'), card('b'), card('c')];
  final tags = {
    'a': {'verb'},
    'b': {'noun', 'verb'},
  };

  test('a named filter is a union and untagged is separate', () {
    expect(tagNamesMatch(' Verb ', 'verb'), isTrue);
    expect(
      cardsMatchingTags(
        cards: cards,
        tagsByCard: tags,
        tagIds: {'verb'},
      ).map((card) => card.id),
      ['a', 'b'],
    );
    expect(
      cardsMatchingTags(
        cards: cards,
        tagsByCard: tags,
        tagIds: {'noun'},
      ).map((card) => card.id),
      ['b'],
    );
    expect(
      cardsMatchingTags(
        cards: cards,
        tagsByCard: tags,
        untagged: true,
        tagIds: {'verb'},
      ).map((card) => card.id),
      ['c'],
    );
    expect(
      cardsMatchingTags(
        cards: cards,
        tagsByCard: tags,
        tagIds: {},
      ).map((card) => card.id),
      ['a', 'b', 'c'],
    );
  });
}
