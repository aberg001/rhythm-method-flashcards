import 'package:flutter/widgets.dart';

import '../../data/library_repository.dart';

/// The open library database, above [MaterialApp] so routes and dialogs see it.
class LibraryScope extends InheritedWidget {
  const LibraryScope({
    super.key,
    required this.repository,
    required super.child,
  });

  final LibraryRepository repository;

  static LibraryRepository of(BuildContext context) {
    final scope = context.getInheritedWidgetOfExactType<LibraryScope>();
    if (scope == null) {
      throw StateError('LibraryScope is not in this context');
    }
    return scope.repository;
  }

  @override
  bool updateShouldNotify(LibraryScope oldWidget) =>
      repository != oldWidget.repository;
}
