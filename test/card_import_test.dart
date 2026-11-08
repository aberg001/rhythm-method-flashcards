import 'package:flutter_test/flutter_test.dart';
import 'package:rhythm_method_flashcards/data/card_import.dart';

void main() {
  ParsedCardImport parse(String source, {String fileName = 'cards.csv'}) {
    return parseCardImport(source, fileName: fileName);
  }

  CardImportPlan plan(
    String source, {
    String fileName = 'cards.csv',
    List<({String front, String back})> cards = const [],
    List<String> tags = const [],
  }) {
    return planCardImport(
      parsed: parse(source, fileName: fileName),
      existingCards: cards,
      existingTags: [for (final name in tags) (name: name)],
    );
  }

  test('a csv keeps front, back, and tags, and drops other columns', () {
    final parsed = parse(
      'Front,Back,Tags,Note\n'
      ' hola ,hello,"verb, noun",aside\n'
      'adios,goodbye,adj; extra,\n'
      ',blank,,\n'
      'hola,hello,verb,\n',
    );
    expect(parsed.skippedEmpty, 1);
    expect(parsed.droppedExtraFields, isTrue);
    expect(parsed.rows.map((row) => row.front), ['hola', 'adios', 'hola']);
    expect(parsed.rows.first.tagNames, ['verb', 'noun']);
    expect(parsed.rows[1].tagNames, ['adj', 'extra']);

    final preview = plan(
      'Front,Back,Tags,Note\n'
      'hola,hello,verb,aside\n'
      'adios,goodbye,noun,\n'
      'hola,hello,verb,\n',
      cards: [(front: 'hola', back: 'hello')],
      tags: ['Verb'],
    );
    expect(preview.added, 1);
    expect(preview.skipped, 2);
    expect(preview.cards.single.front, 'adios');
    expect(preview.cards.single.tagNames, ['noun']);
    expect(preview.tagsToCreate, ['noun']);
    expect(cardImportPreviewText(preview), '''
1 card will be added.
2 rows will be skipped.
New tags: noun.
Extra fields were dropped.''');
  });

  test('quotes keep commas and line breaks inside a field', () {
    final parsed = parse('front,back\n"ho,la","hello\nthere"\n');
    expect(parsed.rows.single.front, 'ho,la');
    expect(parsed.rows.single.back, 'hello\nthere');
  });

  test('a tsv file is tab separated and a txt file is too', () {
    const table = 'front\tback\ttags\nhola\thello\tverb noun\n';
    expect(parse(table, fileName: 'cards.tsv').rows.single.tagNames, [
      'verb',
      'noun',
    ]);
    expect(parse(table, fileName: 'notes.txt').rows.single.front, 'hola');
  });

  test('an anki text export uses the first two content fields', () {
    final parsed = parse(
      '#separator:tab\n'
      '#html:true\n'
      '#deck column:1\n'
      '#tags column:4\n'
      '# a comment\n'
      'Spanish::Verbs\t<b>hola</b>\thello<br>there\tverb noun\n'
      'Spanish::Verbs\tadios\tgoodbye\t\n'
      'Spanish::Verbs\t<script>nope</script>si\t&amp; mas\textra\n',
      fileName: 'spanish.txt',
    );
    expect(parsed.rows[0].front, 'hola');
    expect(parsed.rows[0].back, 'hello\nthere');
    expect(parsed.rows[0].tagNames, ['verb', 'noun']);
    expect(parsed.rows[1].front, 'adios');
    expect(parsed.rows[1].tagNames, isEmpty);
    expect(parsed.rows[2].front, 'si');
    expect(parsed.rows[2].back, '& mas');
    expect(parsed.droppedExtraFields, isFalse);
    expect(
      parsed.rows.map((row) => row.front),
      isNot(contains('Spanish::Verbs')),
    );
  });

  test('html stays text when the anki header says false', () {
    final parsed = parse(
      '#separator:comma\n'
      '#html:false\n'
      'front,back\n'
      '<b>hola</b>,hello\n',
    );
    expect(parsed.rows.single.front, '<b>hola</b>');
  });

  test('a tags header is added to every row', () {
    final parsed = parse(
      '#separator:tab\n'
      '#tags:shared other\n'
      'hola\thello\n'
      'adios\tgoodbye\n',
      fileName: 'cards.txt',
    );
    expect(parsed.rows[0].tagNames, ['shared', 'other']);
    expect(parsed.rows[1].tagNames, ['shared', 'other']);
  });

  test('a tag on a skipped row is not created', () {
    final preview = plan(
      'front,back,tags\n'
      'hola,hello,verb\n'
      'adios,goodbye,noun\n'
      'adios,goodbye,adj\n',
      cards: [(front: 'hola', back: 'hello')],
      tags: ['verb'],
    );
    expect(preview.added, 1);
    expect(preview.skipped, 2);
    expect(preview.tagsToCreate, ['noun']);
    expect(preview.cards.single.tagNames, ['noun']);
  });

  test('the same tag spelling is kept once, ignoring case', () {
    final preview = plan(
      'front,back,tags\n'
      'hola,hello, Verb \n'
      'adios,goodbye,verb\n',
    );
    expect(preview.tagsToCreate, ['Verb']);
    expect(preview.cards[0].tagNames, ['Verb']);
    expect(preview.cards[1].tagNames, ['Verb']);
  });

  test('a row is added when the topic has no matching card', () {
    final preview = plan('front,back\nhola,hello\n');
    expect(preview.added, 1);
    expect(preview.tagsToCreate, isEmpty);
    expect(cardImportPreviewText(preview), '''
1 card will be added.
0 rows will be skipped.
No new tags.''');
  });

  test('a file that cannot be read as a card table is rejected', () {
    expect(() => parse('question,answer\nhola,hello\n'), throwsFormatException);
    expect(
      () => parse('#separator:slash\nfront,back\nhola,hello\n'),
      throwsFormatException,
    );
    expect(() => parse('front,back\n"hola,hello\n'), throwsFormatException);
    expect(() => parse('front,back\n'), throwsFormatException);
    expect(parse('\uFEFFfront,back\nhola,hello\n').rows.single.front, 'hola');
  });
}
