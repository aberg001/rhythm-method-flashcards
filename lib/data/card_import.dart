import '../domain/tag.dart';

/// A chosen table file. [name] decides the separator when the file has none.
final class CardImportFile {
  const CardImportFile({required this.text, required this.name});

  final String text;
  final String name;
}

/// One row that can become a card. Tag spellings are trimmed, not yet matched
/// to the library.
final class ParsedCardRow {
  const ParsedCardRow({
    required this.front,
    required this.back,
    required this.tagNames,
  });

  final String front;
  final String back;
  final List<String> tagNames;
}

/// The rows of a table, before the topic's existing cards are considered.
final class ParsedCardImport {
  const ParsedCardImport({
    required this.rows,
    required this.skippedEmpty,
    required this.droppedExtraFields,
  });

  final List<ParsedCardRow> rows;

  /// Rows whose front or back was empty after trimming.
  final int skippedEmpty;

  /// A content field other than the front, the back, and tags was ignored.
  final bool droppedExtraFields;
}

/// A card the import will insert, with the tag spellings to attach.
final class PlannedCard {
  const PlannedCard({
    required this.front,
    required this.back,
    required this.tagNames,
  });

  final String front;
  final String back;
  final List<String> tagNames;
}

/// What confirming an import will do.
final class CardImportPlan {
  const CardImportPlan({
    required this.cards,
    required this.skipped,
    required this.tagsToCreate,
    required this.droppedExtraFields,
  });

  final List<PlannedCard> cards;
  final int skipped;
  final List<String> tagsToCreate;
  final bool droppedExtraFields;

  int get added => cards.length;
}

/// How many cards were inserted, and how many rows were left out.
final class CardImportResult {
  const CardImportResult({required this.added, required this.skipped});

  final int added;
  final int skipped;
}

/// Reads a UTF-8 card table.
///
/// A `.csv` file is comma-separated and a `.tsv` or `.txt` file is
/// tab-separated, unless a `#separator:` line says otherwise. The header
/// must name `front` and `back` unless Anki directives identify the columns.
/// An optional `tags` column is kept. Other content fields are dropped.
///
/// Anki plain text is the same table. `#html:true` strips markup.
/// `#deck column:`, `#guid column:`, and `#notetype column:` are ignored.
/// `#tags:` is added to every row. `#tags column:` picks the tags column.
ParsedCardImport parseCardImport(String source, {required String fileName}) {
  var text = source;
  if (text.startsWith('\uFEFF')) text = text.substring(1);
  final preamble = _splitPreamble(text);
  final header = _readDirectives(preamble.directives);
  final separator = header.separator ?? _separatorForName(fileName);
  final columns = header.columnsLine?.split(separator);
  final records = _splitTable(preamble.body, separator);
  if (records.isEmpty) {
    throw const FormatException('The file has no cards.');
  }

  final named = _namedColumns(header, records, columns: columns);
  final data = named.consumedHeader ? records.sublist(1) : records;
  if (data.isEmpty) {
    throw const FormatException('The file has no cards.');
  }

  final rows = <ParsedCardRow>[];
  var skippedEmpty = 0;
  var droppedExtraFields = named.droppedExtraFields;
  for (final record in data) {
    final front = _side(_cell(record, named.front), html: header.html);
    final back = _side(_cell(record, named.back), html: header.html);
    if (front.isEmpty || back.isEmpty) {
      skippedEmpty += 1;
      continue;
    }
    if (_extraCells(record, named).any((cell) => cell.trim().isNotEmpty)) {
      droppedExtraFields = true;
    }
    final tags = <String>[
      ...header.fileTags,
      if (named.tags != null) ..._splitTagCell(_cell(record, named.tags!)),
    ];
    rows.add(
      ParsedCardRow(front: front, back: back, tagNames: _uniqueTagNames(tags)),
    );
  }
  return ParsedCardImport(
    rows: rows,
    skippedEmpty: skippedEmpty,
    droppedExtraFields: droppedExtraFields,
  );
}

/// Decides which rows are new cards. A row is skipped when its trimmed front
/// and back match a card already in [existingCards], or an earlier row.
///
/// [existingCards] are the destination topic only. Tag names match tags that
/// already exist, ignoring case. Only tags on cards that will be added are
/// created. The stored spelling of an existing tag is kept.
CardImportPlan planCardImport({
  required ParsedCardImport parsed,
  required List<({String front, String back})> existingCards,
  required List<({String name})> existingTags,
}) {
  final seen = <_Pair>{
    for (final card in existingCards) _Pair(card.front, card.back),
  };
  final known = [for (final tag in existingTags) tag.name];
  final creating = <String>[];
  final cards = <PlannedCard>[];
  var skipped = parsed.skippedEmpty;

  for (final row in parsed.rows) {
    final pair = _Pair(row.front, row.back);
    if (!seen.add(pair)) {
      skipped += 1;
      continue;
    }
    final names = <String>[];
    for (final raw in row.tagNames) {
      final existing = known.where((name) => tagNamesMatch(name, raw));
      if (existing.isNotEmpty) {
        names.add(existing.first);
        continue;
      }
      final created = creating.where((name) => tagNamesMatch(name, raw));
      if (created.isEmpty) creating.add(raw);
      names.add(created.isEmpty ? raw : created.first);
    }
    cards.add(PlannedCard(front: row.front, back: row.back, tagNames: names));
  }

  return CardImportPlan(
    cards: cards,
    skipped: skipped,
    tagsToCreate: creating,
    droppedExtraFields: parsed.droppedExtraFields,
  );
}

/// The preview sentences. One fact per line.
String cardImportPreviewText(CardImportPlan plan) {
  final lines = <String>[
    _cardsWillBeAdded(plan.added),
    _rowsWillBeSkipped(plan.skipped),
    plan.tagsToCreate.isEmpty
        ? 'No new tags.'
        : 'New tags: ${plan.tagsToCreate.join(', ')}.',
  ];
  if (plan.droppedExtraFields) lines.add('Extra fields were dropped.');
  return lines.join('\n');
}

/// The snackbar after a confirmed import.
String cardImportResultText(CardImportResult result) {
  final added = result.added == 1
      ? 'Added 1 card.'
      : 'Added ${result.added} cards.';
  if (result.skipped == 0) return added;
  final skipped = result.skipped == 1
      ? 'Skipped 1 row.'
      : 'Skipped ${result.skipped} rows.';
  return '$added $skipped';
}

String _cardsWillBeAdded(int count) {
  if (count == 0) return 'No cards will be added.';
  if (count == 1) return '1 card will be added.';
  return '$count cards will be added.';
}

String _rowsWillBeSkipped(int count) {
  if (count == 1) return '1 row will be skipped.';
  return '$count rows will be skipped.';
}

/// Pieces of a tags cell. Commas or semicolons win over whitespace.
List<String> _splitTagCell(String cell) {
  final trimmed = cell.trim();
  if (trimmed.isEmpty) return const [];
  final pattern = trimmed.contains(',') || trimmed.contains(';')
      ? RegExp(r'[,;]')
      : RegExp(r'\s+');
  return [
    for (final piece in trimmed.split(pattern))
      if (canonicalTagName(piece).isNotEmpty) canonicalTagName(piece),
  ];
}

List<String> _uniqueTagNames(List<String> names) {
  final kept = <String>[];
  for (final name in names) {
    if (kept.any((existing) => tagNamesMatch(existing, name))) continue;
    kept.add(name);
  }
  return kept;
}

String _separatorForName(String fileName) {
  final lower = fileName.toLowerCase();
  if (lower.endsWith('.tsv') || lower.endsWith('.txt')) return '\t';
  return ',';
}

final class _Pair {
  const _Pair(this.front, this.back);

  final String front;
  final String back;

  @override
  bool operator ==(Object other) {
    return other is _Pair && other.front == front && other.back == back;
  }

  @override
  int get hashCode => Object.hash(front, back);
}

final class _Directives {
  String? separator;
  var html = false;
  var sawAnki = false;
  final List<String> fileTags = [];
  String? columnsLine;
  int? tagsColumn;
  int? deckColumn;
  int? guidColumn;
  int? notetypeColumn;
}

({List<String> directives, String body}) _splitPreamble(String source) {
  final directives = <String>[];
  var index = 0;
  while (index < source.length) {
    final start = index;
    while (index < source.length &&
        source[index] != '\n' &&
        source[index] != '\r') {
      index += 1;
    }
    final line = source.substring(start, index).trim();
    if (index < source.length && source[index] == '\r') index += 1;
    if (index < source.length && source[index] == '\n') index += 1;
    if (line.isEmpty || line.startsWith('#')) {
      if (line.isNotEmpty) directives.add(line);
      continue;
    }
    return (directives: directives, body: source.substring(start));
  }
  return (directives: directives, body: '');
}

_Directives _readDirectives(List<String> lines) {
  final header = _Directives();
  for (final line in lines) {
    final text = line.substring(1).trim();
    final colon = text.indexOf(':');
    if (colon <= 0) continue;
    final key = text.substring(0, colon).trim().toLowerCase();
    final value = text.substring(colon + 1).trim();
    switch (key) {
      case 'separator':
        final separator = _separatorNamed(value);
        if (separator == null) {
          throw FormatException('The separator "$value" is not supported.');
        }
        header.separator = separator;
        header.sawAnki = true;
      case 'html':
        final html = value.toLowerCase();
        if (html != 'true' && html != 'false') {
          throw const FormatException('The html header is invalid.');
        }
        header.html = html == 'true';
        header.sawAnki = true;
      case 'tags':
        header.fileTags.addAll(_splitTagCell(value));
        header.sawAnki = true;
      case 'columns':
        header.columnsLine = value;
        header.sawAnki = true;
      case 'tags column':
        header.tagsColumn = _columnNumber(value);
        header.sawAnki = true;
      case 'deck column':
        header.deckColumn = _columnNumber(value);
        header.sawAnki = true;
      case 'guid column':
        header.guidColumn = _columnNumber(value);
        header.sawAnki = true;
      case 'notetype column':
        header.notetypeColumn = _columnNumber(value);
        header.sawAnki = true;
      default:
        break;
    }
  }
  return header;
}

String? _separatorNamed(String value) {
  switch (value.trim().toLowerCase()) {
    case 'comma':
    case ',':
      return ',';
    case 'semicolon':
    case ';':
      return ';';
    case 'tab':
    case r'\t':
    case '\t':
      return '\t';
    case 'space':
    case ' ':
      return ' ';
    case 'pipe':
    case '|':
      return '|';
    case 'colon':
    case ':':
      return ':';
    default:
      return null;
  }
}

int _columnNumber(String value) {
  final number = int.tryParse(value.trim());
  if (number == null || number < 1) {
    throw const FormatException('A column number is invalid.');
  }
  return number;
}

final class _Columns {
  const _Columns({
    required this.front,
    required this.back,
    required this.tags,
    required this.extraIndexes,
    required this.consumedHeader,
    required this.droppedExtraFields,
  });

  final int front;
  final int back;
  final int? tags;
  final Set<int> extraIndexes;
  final bool consumedHeader;
  final bool droppedExtraFields;
}

_Columns _namedColumns(
  _Directives header,
  List<List<String>> records, {
  required List<String>? columns,
}) {
  final special = <int>{
    if (header.tagsColumn != null) header.tagsColumn! - 1,
    if (header.deckColumn != null) header.deckColumn! - 1,
    if (header.guidColumn != null) header.guidColumn! - 1,
    if (header.notetypeColumn != null) header.notetypeColumn! - 1,
  };

  final positioned =
      header.tagsColumn != null ||
      header.deckColumn != null ||
      header.guidColumn != null ||
      header.notetypeColumn != null;
  List<String>? names = columns != null && _looksLikeHeader(columns)
      ? columns
      : null;
  var consumedHeader = false;
  if (names == null && !positioned && _looksLikeHeader(records.first)) {
    names = records.first;
    consumedHeader = true;
  }

  if (names != null && _looksLikeHeader(names)) {
    final front = _oneColumn(names, 'front');
    final back = _oneColumn(names, 'back');
    if (front == null || back == null) {
      throw const FormatException(
        'The file needs a front column and a back column.',
      );
    }
    if (special.contains(front) || special.contains(back)) {
      throw const FormatException(
        'The file needs a front column and a back column.',
      );
    }
    final tags = header.tagsColumn == null
        ? _oneColumn(names, 'tags')
        : header.tagsColumn! - 1;
    final extra = <int>{};
    for (var index = 0; index < names.length; index++) {
      if (index == front || index == back || index == tags) continue;
      if (special.contains(index)) continue;
      extra.add(index);
    }
    return _Columns(
      front: front,
      back: back,
      tags: tags,
      extraIndexes: extra,
      consumedHeader: consumedHeader,
      droppedExtraFields: extra.isNotEmpty,
    );
  }

  if (!header.sawAnki) {
    throw const FormatException(
      'The file needs a front column and a back column.',
    );
  }

  final width = records
      .map((row) => row.length)
      .reduce((a, b) => a > b ? a : b);
  final content = <int>[
    for (var index = 0; index < width; index++)
      if (!special.contains(index)) index,
  ];
  if (content.length < 2) {
    throw const FormatException(
      'The file needs a front column and a back column.',
    );
  }
  return _Columns(
    front: content[0],
    back: content[1],
    tags: header.tagsColumn == null ? null : header.tagsColumn! - 1,
    extraIndexes: content.skip(2).toSet(),
    consumedHeader: false,
    droppedExtraFields: content.length > 2,
  );
}

bool _looksLikeHeader(List<String> cells) {
  final names = cells.map((cell) => cell.trim().toLowerCase()).toSet();
  return names.contains('front') && names.contains('back');
}

int? _oneColumn(List<String> names, String want) {
  int? found;
  for (var index = 0; index < names.length; index++) {
    if (names[index].trim().toLowerCase() != want) continue;
    if (found != null) {
      throw FormatException('The file has more than one $want column.');
    }
    found = index;
  }
  return found;
}

String _cell(List<String> row, int index) {
  if (index < 0 || index >= row.length) return '';
  return row[index];
}

Iterable<String> _extraCells(List<String> row, _Columns columns) sync* {
  for (final index in columns.extraIndexes) {
    yield _cell(row, index);
  }
  final used = <int>{
    columns.front,
    columns.back,
    if (columns.tags != null) columns.tags!,
    ...columns.extraIndexes,
  };
  final highest = used.fold<int>(0, (max, index) => index > max ? index : max);
  for (var index = highest + 1; index < row.length; index++) {
    yield row[index];
  }
}

List<List<String>> _splitTable(String input, String separator) {
  if (separator.length != 1) {
    throw const FormatException('The separator is not supported.');
  }
  final mark = separator.codeUnitAt(0);
  final rows = <List<String>>[];
  final row = <String>[];
  final field = StringBuffer();
  var inQuotes = false;

  void endField() {
    row.add(field.toString());
    field.clear();
  }

  void endRow() {
    endField();
    if (row.any((cell) => cell.trim().isNotEmpty)) {
      rows.add(List<String>.of(row));
    }
    row.clear();
  }

  final units = input.codeUnits;
  var index = 0;
  while (index < units.length) {
    final unit = units[index];
    if (inQuotes) {
      if (unit == 0x22) {
        if (index + 1 < units.length && units[index + 1] == 0x22) {
          field.writeCharCode(0x22);
          index += 2;
          continue;
        }
        inQuotes = false;
        index += 1;
        continue;
      }
      field.writeCharCode(unit);
      index += 1;
      continue;
    }
    if (unit == 0x22 && field.toString().trim().isEmpty) {
      field.clear();
      inQuotes = true;
      index += 1;
      continue;
    }
    if (unit == mark) {
      endField();
      index += 1;
      continue;
    }
    if (unit == 0x0a || unit == 0x0d) {
      if (unit == 0x0d &&
          index + 1 < units.length &&
          units[index + 1] == 0x0a) {
        index += 1;
      }
      endRow();
      index += 1;
      continue;
    }
    field.writeCharCode(unit);
    index += 1;
  }
  if (inQuotes) {
    throw const FormatException('A quoted field is missing its end.');
  }
  if (field.isNotEmpty || row.isNotEmpty) endRow();
  return rows;
}

String _side(String value, {required bool html}) {
  final text = html ? _plainText(value) : value;
  return text.trim();
}

String _plainText(String html) {
  var text = html;
  text = text.replaceAll(
    RegExp(
      r'<\s*(script|style)\b[^>]*>.*?<\s*/\s*\1\s*>',
      caseSensitive: false,
      dotAll: true,
    ),
    '',
  );
  text = text.replaceAll(
    RegExp(r'<\s*br\s*/?\s*>', caseSensitive: false),
    '\n',
  );
  text = text.replaceAll(
    RegExp(r'</\s*(p|div|li|h[1-6]|tr)\s*>', caseSensitive: false),
    '\n',
  );
  text = text.replaceAll(
    RegExp(r'<\s*hr\s*/?\s*>', caseSensitive: false),
    '\n',
  );
  text = text.replaceAll(RegExp(r'<[^>]*>'), '');
  text = text.replaceAllMapped(RegExp(r'&(#x[0-9a-fA-F]+|#\d+|[a-zA-Z]+);'), (
    match,
  ) {
    final token = match[1]!;
    if (token.startsWith('#x') || token.startsWith('#X')) {
      final code = int.tryParse(token.substring(2), radix: 16);
      return code == null ? match[0]! : String.fromCharCode(code);
    }
    if (token.startsWith('#')) {
      final code = int.tryParse(token.substring(1));
      return code == null ? match[0]! : String.fromCharCode(code);
    }
    const named = {
      'amp': '&',
      'lt': '<',
      'gt': '>',
      'quot': '"',
      'apos': "'",
      'nbsp': ' ',
    };
    return named[token.toLowerCase()] ?? match[0]!;
  });
  return text.trim();
}
