# Rhythm Method Flashcards

Flashcard app that uses a slow start to help learn large dumps of information

This is a spaced repetition flashcard app, much like many others already available, that is optimized for dumping a large amount of information into it and gradually learning it.

Use cases:
- Learning vocabulary for a new language.
- Memorizing Scripture or other texts.
- Learning names/dates of historical people or events.

The app is organized with user-defined topics, which may include sub-topics.  Topics and sub-topics contain cards, which are "front"/"back" pairs of rich text, images, or maybe sounds.

The appearance of the review process is familiar to other flashcard apps:  Cards are presented sequentially.  Tap to flip the card to review the other side, swipe left if wrong, swipe right if correct.  "Edit" and "Undo" buttons at the top of the screen, "Wrong", "Flip" and "Correct" buttons at the bottom.

What is different is how cards are selected.  The priority is always:
1. Strengthen cards already learned.
2. Review weak cards.
3. Learn new cards.

To do this we will have a few tunable parameters:
- **Correct Factor**: This is a multiplier applied to a card's time interval when the user gets it right.  Perhaps 1.5 is a good initial default, but we'll want to refine this with testing/use.
- **Wrong Factor**: This is a multiplier applied to a card's time interval when the user gets it wrong.  Perhaps 0.5 is a good initial default.
- **Difficulty Factor**: This is a value added to a card's difficulty every time it is reported as "wrong".  Perhaps 0.01 is a good initial value.
- **Learning Window Size**: This is the max number of cards allowed to be in the "learning" state.  Any wrong reply sets a card into "learning" regardless of it's time interval.  Perhaps 10 is a good starting value.
- **Learned Threshold**: This is a time interval where once a card's time interval gets above, that card is considered learned.  Perhaps 1 hour is a good starting point.

Per card internal data:
- **Learning**: This card is currently being "learned".  Boolean.
- **Last Review**: The last time this card was reviewed.  Timestamp.
- **Time Interval**: The ideal window before this card will be reviewed again.  Time interval.  Defaults to 10 minutes.
- **Difficulty**: This is a multiplier applied to the correct/wrong factor when it is reported as "correct".  Defaults to 1.0, increases by the difficulty factor every time it is wrong.  Number.

The review process is a simple, repetitive loop.  Card selection first picks from learned cards that are due before now (last review + time interval is in the past).  If those are all completed, it picks from the learning cards by recency weight: the most recently reviewed has weight 0, and the least recently reviewed has the highest weight.  If fewer than the learning window size are in that set, the next new card joins the same draw.  The weights, the grading arithmetic, and the build sequence are in [docs/algorithm.md](docs/algorithm.md) and [docs/implementation-plan.md](docs/implementation-plan.md).
