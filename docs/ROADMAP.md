# Roadmap

What is already built, and the work approved after it. The first build, milestone by milestone, is the record in [implementation-plan.md](implementation-plan.md). Scheduling rules stay in [algorithm.md](algorithm.md). This roadmap changes that spec only where a milestone below says so.

## Done

The local plain-text app is in place:

- Topics, subtopics, and cards. A topic with children or cards cannot be deleted.
- Study on one topic plus its descendants, or on the whole library.
- The five library-wide settings.
- Grades, admissions, and undo stored in SQLite as they happen.
- JSON export of topics, cards, and settings, and import that replaces the library.
- An iPhone pass for safe areas, Dynamic Type, VoiceOver, and a haptic tick after a successful grade.
- A compact topic list. Each card is one line of the front, with New, Learning, or Learned, the interval, and Due when a learned card is due. With the reverse drill on, the row has Forward and Reverse columns.
- The study card turns on its Y axis. Flip can be used again before grading. Wrong and Correct wait until the answer has been seen, then stay available on the prompt. A swipe grades only on the answer side.
- A per-topic reverse drill. Every card in that topic has a reverse face with its own schedule, starting at 10 minutes and difficulty 1.0. The reverse stays new until its own front is learned, then waits ahead of cards not yet started. Schema version 2 and backup version 2. Backup version 1 still imports.
- Library-wide tags. A card can have several. The topic screen can filter by tags or by Untagged, and that filter also limits study of the topic and its descendants. The tags screen can rename, reorder, delete, and study the selected tags across the library. Study all stays unfiltered. Schema version 3 and backup version 3. Older backups still import, with no tags.

## Next

These milestones run in order. Each one is a single slice of work. The five settings remain the only scheduler knobs. Difficulty still only rises on a wrong answer, and the card list does not present it as mastery.

Imported cards from other apps keep the front, the back, and any tags, and they start as new cards at the usual initial interval and difficulty.

Still outside this sequence: images, audio, rich text, sync, accounts, notifications, widgets, an iPad split view, and store packaging.

### 1. CSV and TSV import

Import adds cards to one existing topic. It is separate from backup restore, and it does not use the backup buttons. The topic screen offers Import cards.

The file is UTF-8 `.csv` or `.tsv` with a header row. `front` and `back` are required, matched without case sensitivity. An optional `tags` column is kept. Other columns are ignored. An Anki plain-text export uses the same parser: honor `#separator:` and `#html:`, take the first two content fields as front and back, keep a tags column, strip HTML to plain text, and ignore the deck. The preview says when extra fields were dropped.

The preview shows how many cards will be added, how many rows will be skipped, and which tag names will be created. Confirming inserts them in one transaction. A file that does not parse, or an insert that fails, leaves the library unchanged.

Each inserted card is new. A row is skipped when its trimmed front and trimmed back match a card already in the destination topic, or an earlier row in the same file. The result reports how many were skipped. Tags in a cell split on comma or semicolon when those characters are present, and otherwise on whitespace. Blank pieces are dropped. Tag names create library tags when needed and attach to the new cards.

### 2. XLSX import

Same destination topic, preview, duplicate rule, new-card rule, and tag rule as CSV import. Read the first sheet only, with a pure-Dart reader and no new native plugin. Read cached cell values. Skip a row whose front or back is empty. Ignore formulas with no cached value, images, and later sheets.

### 3. Other apps, from a sample file

Parsers for other products start from a real export. Layouts are not guessed.

- SmartCards+ has no published export schema.
- AnkiApp is a different product from Anki desktop.
- An Anki `.apkg` or `.colpkg` is its own milestone after a sample. Deck names become topics, with `::` as the tree. HTML becomes plain text. Tags are kept. Schedule and media are left out. When a note has more than two fields, the preview asks which field is the front and which is the back.

## Later

After the sequence above:

- Images, then audio, then rich text. Each one changes the card model and needs a migration.
- Sync and accounts.
- An iPad layout, Android polish, macOS and Windows release builds, notifications, and home-screen widgets.
- Store submission.

Cards stay in the order they were created. Reordering is for topics and tags.
