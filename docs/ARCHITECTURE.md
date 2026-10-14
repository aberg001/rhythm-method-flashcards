# Architecture

How the running app is shaped. Grade and select arithmetic, the weighted draw, and the invariants live in [algorithm.md](algorithm.md). Where this overview and that spec differ, the spec wins.

## Purpose

The app is for dumping a large set of cards in at once and learning them gradually. Study always prefers cards in this order:

1. Strengthen cards already learned, once they are due.
2. Drill cards that are still in the learning window.
3. Admit a new card when the window has room.

A wrong answer puts a card back into learning even when its interval is already long. A card is learned only when a correct answer leaves its interval strictly above the learned threshold.

## Library

Topics form a tree. A topic may contain subtopics and cards at the same time. A card belongs to one topic and has a front and a back. Today both sides are plain text. Images, audio, and rich text are later work, described in [ROADMAP.md](ROADMAP.md).

Deleting a topic that still has subtopics or cards is refused. Nothing is cascade-deleted silently.

A study scope is one topic plus its descendants, or the whole library. The learning window is counted inside that scope. Studying two topics separately can put more than the window size into learning across the library. Studying everything then sees that larger set.

## Study session

A session shows one card at a time. The prompt is the front. Flip, by tap or the Flip button, reveals the back. Swipe left or Wrong marks it wrong. Swipe right or Correct marks it right. Edit and Undo sit at the top. Wrong, Flip, and Correct sit at the bottom.

Wrong, Correct, and the swipes do nothing until the card has been flipped. Undo returns the previous card already showing its back, and does not take away a seat in the window. Edit changes the words and leaves the schedule alone. Leaving the session keeps the grades already saved.

The screen states how many learning seats are filled, how many new cards are waiting, and how many learned cards are due. When nothing is due it says so.

## Scheduler settings

Five settings, stored once for the whole library. The settings screen exposes these and no others.

| Setting | Default | Role |
| --- | --- | --- |
| Correct factor | 1.5 | Grows the interval after a correct answer. Must be greater than 1. |
| Wrong factor | 0.5 | Shrinks the interval after a wrong answer. Must be greater than 0 and less than 1. |
| Difficulty factor | 0.01 | Added to difficulty on every wrong answer. Must be zero or greater. |
| Learning window | 10 | Maximum number of cards in learning inside the current scope. Whole number, at least 1. |
| Learned threshold | 1 hour | Interval above which a correct answer counts as learned. Must be greater than 0. |

Each card also stores:

| Field | Meaning |
| --- | --- |
| Learning | Whether the card holds a seat in the window. |
| Last review | When it was last graded. Empty until the first grade. |
| Interval | Starts at 10 minutes. While the card is learning, this is progress toward the threshold. After it is learned, it is the wait until the card is due. |
| Difficulty | Starts at 1.0. Rises by the difficulty factor on a wrong answer and never falls. It slows later growth. It is not a mastery score. |

Named constants, not settings, keep a session comparable from build to build: minimum interval 1 minute, minimum growth 1.15, difficulty cap 10. The formulas and the draw are in [algorithm.md](algorithm.md).

Changing a setting affects the next grade and the next card selection. Past review rows stay as they were.

## Code layout

Flutter, Material 3, one interface for every platform. The seed color is `#1F4B4A`. There is no second Cupertino-only interface and no state-management package. Library, Study, and Settings are tabs. A study session is its own route.

```text
lib/
  main.dart                 opens the database and starts the app
  app.dart                  Material app and the three tabs
  domain/scheduler.dart     grade, select, and undo snapshots
  data/                     Drift database, repository, backup JSON
  features/
    library/                topics, cards, and the editor
    study/                  session and the status line
    settings/               the five settings
    backup/                 share and pick a backup file
test/
  domain/                   scheduler invariants, no Flutter
```

`lib/domain/scheduler.dart` does not import Flutter or the database. The repository calls it. Card and topic ids are stable strings from `lib/features/library/ids.dart`. Admission, a grade, and an undo each persist on their own, so leaving the app keeps them.

## Storage

SQLite through Drift, schema version 1. One file, `rhythm_method.sqlite`, in application support.

- Topics: id, parent, name, position, created time.
- Cards: the scheduler fields above, plus topic, front, back, and created time.
- Reviews: one row per grade, including the before and after schedule, so undo can restore it.
- Settings: one row of the five parameters.

Generated database code is `lib/data/database.g.dart`. Drift stays on 2.31.0 so it matches this Flutter SDK. Regenerate that file only when the schema changes.

## Backup

Export writes topics, cards, and settings to `rhythm-method-backup.json` and hands it to the system share sheet. Review history is not in the file. Timestamps are UTC.

Import parses the file before it touches the database. A file this app exported replaces the whole library. If the device already has a topic or a card, the user confirms first. Restoring clears review rows on the device. A file that does not parse leaves the library as it was. Version 1 is the only backup version the app reads and writes today.
