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
- CSV and TSV import onto one topic, from that topic's screen. It is not backup restore. A preview counts the cards to add, the rows to skip, and the tag names to create. Anki plain text uses the same parser. New cards start at 10 minutes and difficulty 1. A duplicate front and back in that topic is skipped.

## Next

These milestones run in order. Each one is a single slice of work. The five settings remain the only scheduler knobs. Difficulty still only rises on a wrong answer, and the card list does not present it as mastery.

Still outside this sequence: images, audio, rich text, accounts, notifications, widgets, an iPad split view, and store packaging.

### 1. Sync

This library can be the same library on more than one of this person's devices. Topics, cards, tags, the five settings, and the review rows that undo needs all travel. A card keeps the schedule this app gave it. Sync does not copy intervals from other apps, and it does not replace the library the way backup import does.

Grades made on two devices before they meet must both survive. The rule for that meeting is part of this milestone and is written down before the sync code. The way the bytes move is chosen here. Accounts, a server, and store packaging stay later.

### 2. XLSX import

Same destination topic, preview, duplicate rule, new-card rule, and tag rule as CSV import. Read the first sheet only, with a pure-Dart reader and no new native plugin. Read cached cell values. Skip a row whose front or back is empty. Ignore formulas with no cached value, images, and later sheets.

Imported cards from other apps keep the front, the back, and any tags, and they start as new cards at the usual initial interval and difficulty.

### 3. Other apps, from a sample file

Parsers for other products start from a real export. Layouts are not guessed.

- SmartCards+ has no published export schema.
- AnkiApp is a different product from Anki desktop.
- An Anki `.apkg` or `.colpkg` is its own milestone after a sample. Deck names become topics, with `::` as the tree. HTML becomes plain text. Tags are kept. Schedule and media are left out. When a note has more than two fields, the preview asks which field is the front and which is the back.

## Later

After the sequence above:

- Images, then audio, then rich text. Each one changes the card model and needs a migration.
- Accounts.
- An iPad layout, Android polish, macOS and Windows release builds, notifications, and home-screen widgets.
- Store submission.

Cards stay in the order they were created. Reordering is for topics and tags.
