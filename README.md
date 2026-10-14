# Rhythm Method Flashcards

Rhythm Method Flashcards is a spaced-repetition app for a large pile of material. Vocabulary, scripture, and names and dates are the cases it is built for. A big import should become a small set of cards in active study, not a queue of everything at once.

The first target is iPhone. The Flutter project also includes Android, macOS, and Windows. The library stays on the device. Cards are plain text.

The app can create topics and cards, run a study session, tune the five scheduler settings, and replace the library from a JSON backup. How that is put together is in [docs/ARCHITECTURE.md](docs/ARCHITECTURE.md). The scheduling rules are in [docs/algorithm.md](docs/algorithm.md). What comes next is in [docs/ROADMAP.md](docs/ROADMAP.md). The first build sequence is in [docs/implementation-plan.md](docs/implementation-plan.md).

## Development

Flutter 3.41.7 and Dart 3.11.5. From this directory:

```sh
flutter test
```

GitHub Actions runs the same suite on every push and pull request.

## License

BSD 2-Clause. Copyright 2026 Andrew Berg. See [LICENSE](LICENSE).
