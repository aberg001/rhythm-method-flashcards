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

## Next

These six milestones run in order. Each one is a single slice of work. The five settings remain the only scheduler knobs. Difficulty still only rises on a wrong answer, and the card list does not present it as mastery.

Imported cards from other apps keep the front, the back, and any tags, and they start as new cards at the usual initial interval and difficulty.

Still outside this sequence: images, audio, rich text, sync, accounts, notifications, widgets, an iPad split view, and store packaging.

### 1. Visual pass

No schema change and no scheduler change.

Keep Material 3 and the current seed color. Tighten the lists and the study card.

On a topic, each card row is one ellipsized line of the front. The back stays in the editor and on the study card. A short trailing cluster uses words:

- New, when the card has never been reviewed. The stored 10-minute interval stays hidden.
- Learning, while the interval is still at or under the threshold, such as `Learning · 34m / 1h`. The fraction is progress toward graduating.
- Learning, with the interval alone, such as `Learning · 2h`, when a lapsed card is already past the threshold and the next correct answer graduates it.
- Learned, with the interval as its strength, such as `Learned · 6h`. Add Due only when that card is due.

Intervals under an hour render in minutes, under a day in hours, and then in days. Subtopic rows and the editor stay as they are. Tapping a row still opens the editor.

The study card turns on its Y axis for about 300ms, with perspective. The text swaps at the midpoint and is counter-rotated so it is never mirrored. A border marks the visible side and changes at that same midpoint. The prompt side uses the theme outline. The answer side uses a warm accent, neither green nor red. If the platform has animations disabled, the side changes instantly.

Flip is a toggle. The Flip button and a tap on the card may turn it any number of times before Wrong or Correct. Wrong, Correct, and horizontal swipes do nothing until the answer has been seen once, and they do nothing while a turn is still running. After that first reveal, flipping back to the prompt leaves the buttons available. Swipes grade only while the answer side is showing. Undo lands on the answer, ready to grade, without replaying the animation.

VoiceOver reads the visible side. Flip stays available after the first reveal. The grade haptic, edit flow, and scroll-or-fill card stay.

### 2. Reverse drill

A topic can drill a card back to front after the normal direction is learned. This is a second face on the same card, with its own learning flag, last review, interval, and difficulty. A miss on one face leaves the other face alone. Both faces use the same five settings and the same constants. The reverse face starts at 10 minutes and difficulty 1.0. It does not copy the forward face.

The switch is off by default and is stored on that topic only. It does not pass to subtopics. A card follows the switch on its own topic, including in a parent-topic session or a whole-library session.

Turning the switch on creates a reverse face for every card in that topic that is already learned and does not have one yet. After that, a reverse face is created the first time the forward face graduates, when the switch is on and no reverse exists yet. Turning the switch on confirms when at least one learned card would gain a reverse, and says that those drills wait ahead of cards not yet started.

Turning the switch off stops creating reverse faces and stops selecting them. They leave the window count. Their stored state remains, and turning the switch back on resumes them.

Selection order is unchanged, applied to faces: due learned faces, then faces already in the window, then new faces. A waiting reverse does not skip the window and does not outrank a due learned face. Among new faces, every waiting reverse comes before every card that has never been started. The weights do not change. The next new face is the reverse at the head of that line, or the oldest ordinary new card when no reverse is waiting. A full window admits nobody. The window counts faces, so one card can hold two seats when the forward face lapses while the reverse face is learning.

Among waiting reverses:

- A reverse just created by a graduation goes to the front.
- When the switch is first turned on, cards known the longest go ahead of cards learned more recently. A later graduation still cuts in front of that backfill.

A run of graduations keeps putting the newest reverse at the front. Older waiting reverses sit behind those newer ones. Ordinary new cards wait behind every waiting reverse.

In study, the reverse prompt is the original back and the answer is the original front. The border still means prompt versus answer. The card shows a small Reverse label. Flip works the same way. Review rows record the direction so undo restores the face that was graded.

Status numbers count faces. A waiting reverse counts as a new card. The sentence format in the algorithm spec stays. One card can contribute to two counts.

Storage becomes schema version 2, with a Drift migration from version 1. Topics gain the switch. Cards gain the reverse schedule and a queue timestamp. A null queue timestamp means there is no reverse face. Reviews gain a direction. Regenerate `database.g.dart` with the pinned Drift 2.31.0 generator. Backup JSON becomes version 2 and still accepts version 1. A version 1 file imports with the switch off and no reverse faces. Export writes the new fields. Restore remains a full-library replace. This milestone updates [algorithm.md](algorithm.md) with the face rules, the queue order, and the session loop.

### 3. Tags

Tags are labels. They are not scheduler settings.

One library-wide list. A tag has an id, a display name, and a position. Blank names are rejected. Uniqueness is case-insensitive after trimming, and the stored spelling is kept. Cards and tags are many-to-many. Renaming a tag updates it everywhere. Deleting a tag detaches it and leaves the cards. Reorder uses the same up and down controls as topics.

Schema version 3, migrated from version 2. Backup becomes version 3 and still accepts versions 1 and 2. Missing tags mean no tags. Export writes the tags and each card's tag ids.

The card editor can attach and detach tags. A library tags screen can rename, reorder, and delete tags, and can start a focused review.

The topic screen can filter its own cards by one or more tags, or by Untagged. Several tags match a card that has any of them. Untagged is its own filter and is not combined with named tags. With no filter, every card is shown. The filter belongs to that screen. Study all on the Study tab stays unfiltered.

Study from a topic still includes that topic and its descendants. An active tag filter also limits the session to matching cards, including matches in subtopics. Study from the tags screen covers the whole library and the selected tags. The learning window is the scope being studied. Two tag sessions, studied separately, can put more than the window size into learning across the library. Study all then counts every learning face.

### 4. CSV and TSV import

Import adds cards to one existing topic. It is separate from backup restore, and it does not use the backup buttons. The topic screen offers Import cards.

The file is UTF-8 `.csv` or `.tsv` with a header row. `front` and `back` are required, matched without case sensitivity. An optional `tags` column is kept. Other columns are ignored. An Anki plain-text export uses the same parser: honor `#separator:` and `#html:`, take the first two content fields as front and back, keep a tags column, strip HTML to plain text, and ignore the deck. The preview says when extra fields were dropped.

The preview shows how many cards will be added, how many rows will be skipped, and which tag names will be created. Confirming inserts them in one transaction. A file that does not parse, or an insert that fails, leaves the library unchanged.

Each inserted card is new. A row is skipped when its trimmed front and trimmed back match a card already in the destination topic, or an earlier row in the same file. The result reports how many were skipped. Tags in a cell split on comma or semicolon when those characters are present, and otherwise on whitespace. Blank pieces are dropped. Tag names create library tags when needed and attach to the new cards.

### 5. XLSX import

Same destination topic, preview, duplicate rule, new-card rule, and tag rule as CSV import. Read the first sheet only, with a pure-Dart reader and no new native plugin. Read cached cell values. Skip a row whose front or back is empty. Ignore formulas with no cached value, images, and later sheets.

### 6. Other apps, from a sample file

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

Cards stay in the order they were created. Reordering is for topics and, once they exist, for tags.
