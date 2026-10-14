# Implementation plan

Build record for the first version of the iPhone-first Flutter app. The scheduling rules live in [algorithm.md](algorithm.md). Work after this version is in [ROADMAP.md](ROADMAP.md). Each milestone below was one reviewable chunk, and later milestones assumed the earlier ones were in place.

v1 is a local, plain-text flashcard app whose study loop follows that spec. Android, macOS, and Windows folders are created with the project. Release work for those platforms is not part of v1.

## v1 scope

In scope:

- Create, rename, reorder, and delete topics and subtopics. Deleting a topic that still has cards or child topics is refused. Nothing is cascade-deleted silently.
- Create, edit, and delete plain-text cards on a topic.
- Start a study session on a topic, including its descendants, or on the whole library.
- The review screen: flip, swipe left for wrong and right for correct, and Edit, Undo, Wrong, Flip, and Correct.
- The five settings from the spec, with the spec's validation.
- A local database. Killing the app after a grade does not lose it.
- On-screen counts so a full learning window does not look like a bug.

Out of scope: accounts, sync, Anki or CSV import, images, audio, rich text, notifications, home-screen widgets, per-topic parameters, an iPad split view, and store submission. JSON export of topics, cards, and settings is in the last milestone, so a lost device is not fatal. Import of that same file waits until the export has been used for real.

## Stack

- Current stable Flutter, with the iOS, Android, macOS, and Windows platform folders.
- Material 3. One UI for every platform, with iPhone-safe gestures and safe areas. A second, Cupertino-only UI is not part of this plan.
- The scheduler is pure Dart. `grade` and `select` do not import Flutter or the database. The UI and the database call them.
- Drift (SQLite) for storage.
- No state-management package in v1. A small controller over the pure scheduler is enough. Add one later only if a milestone is getting tangled.
- Navigator is enough for Library, Study, and Settings. Add a router when there is a deep link to support.

Suggested layout, adjusted to Flutter's defaults where they already fit:

```text
lib/
  main.dart
  app.dart
  domain/          pure Dart: model, grade, select
  data/            database and repositories
  features/
    library/
    study/
    settings/
test/
  domain/
```

## Milestone 1 — Flutter scaffold and shell

Create the Flutter project in this repo. Keep the existing README, license, and `docs/`. Add a Material 3 shell with placeholders for Library, Study, and Settings. Confirm `flutter test` and an iOS simulator build run.

Done when the app launches on the iOS simulator to a placeholder library screen.

## Milestone 2 — Scheduler library and tests

Implement topics, cards, parameters, `grade`, `select`, and undo snapshots in `lib/domain` with no Flutter imports. Cover every invariant in [algorithm.md](algorithm.md). Add a GitHub Action that runs `flutter test` on push and on pull request, on a stable Flutter version.

Done when those tests pass locally and in CI, and no file under `lib/domain` imports Flutter.

## Milestone 3 — Local storage

Add Drift and a repository the UI can call.

- `topics`: id, parent id, name, position, created time.
- `cards`: the card fields in the spec.
- `reviews`: the undo and audit row from the spec.
- `settings`: a single row of the five parameters.

Persist a grade, an admission (`learning` set true), and an undo in their own transactions. Card and topic ids are stable strings, so a later export does not renumber them.

Done when a repository test can admit a card, grade it, reopen the database from the file, and read back the same interval, difficulty, learning flag, and review row.

## Milestone 4 — Library UI

Topic tree, topic screen, and plain-text card editor. Add, rename, reorder, and delete. The study action can open an empty session until Milestone 5. An empty library tells the user to add a topic and a card.

Done when a topic, a subtopic, and a few cards survive leaving the app on the iOS simulator.

## Milestone 5 — Study session

Wire the session loop to `select` and `grade`. Front, flip, back, swipe and buttons, edit, and multi-step undo. Grading stays disabled until the card is flipped. Show learning seats, new cards waiting, and learned cards due. Show a clear state when select returns nothing. Admission and grades persist as they happen, not when the session ends.

Done when a manual pass on the simulator matches the spec:

- A due learned card appears before any learning card.
- With a full window, no new card appears.
- After enough corrects, a card leaves the window and does not return until its interval has elapsed.
- Undo puts the previous card back with its previous interval.

## Milestone 6 — Settings

A settings screen for the five parameters. Enforce the constraints in the form and again inside `grade` and `select`. Defaults are the spec defaults. Changing a parameter affects the next grade and the next select, not past review rows.

Done when a window of 1 drills a single card until it graduates, and a correct factor of 1 or below is rejected.

## Milestone 7 — iPhone pass and backup export

Safe areas, Dynamic Type that does not clip the card, VoiceOver labels for Flip, Wrong, Correct, Undo, and Edit, and a short haptic tick on grade. JSON export of topics, cards, and settings to the iOS share sheet. No import yet.

Done when the study loop is usable one-handed on a phone-sized simulator, VoiceOver can flip and grade a card, and the exported file contains every card field the scheduler needs.

## Later

Left unscheduled when this plan was written. [ROADMAP.md](ROADMAP.md) is the current list, and JSON import of this backup has since shipped. At the time, the following were intentionally not part of v1:

- Images, then audio, then richer text. Each one changes the content model and needs a migration.
- Import of the v1 JSON export.
- Anki import, as its own design. The schedulers do not match.
- Sync and accounts.
- An iPad layout, Android polish, macOS and Windows release builds, and notifications.

## Risks

- The defaults are untested in real study. 1.5, 0.5, 0.01, 10, and 1 hour are the opening guesses. Milestone 6 keeps them changeable. No other magic numbers belong in the UI.
- A full window can feel stuck. The counts in Milestone 5 are part of the behavior. Without them the app looks broken on the case it is for.
- Horizontal swipes grade, and vertical movement must not. Grade gestures stay off until the card is flipped, which also cuts accidental grades.
- Rich text, images, and sound are easy to pull forward. They stay out of the scheduler milestones so the slow start can be tried on real material as plain text.
