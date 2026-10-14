import 'package:flutter/material.dart';

import 'data/library_repository.dart';
import 'features/library/library_scope.dart';
import 'features/library/library_screen.dart';
import 'features/settings/settings_screen.dart';
import 'features/study/study_screen.dart';

/// Root widget. Material 3, following the platform light or dark setting.
class RhythmMethodApp extends StatelessWidget {
  const RhythmMethodApp({super.key, required this.repository});

  final LibraryRepository repository;

  static const _seed = Color(0xFF1F4B4A);

  @override
  Widget build(BuildContext context) {
    return LibraryScope(
      repository: repository,
      child: MaterialApp(
        title: 'Rhythm Method Flashcards',
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: _seed),
          useMaterial3: true,
        ),
        darkTheme: ThemeData(
          colorScheme: ColorScheme.fromSeed(
            seedColor: _seed,
            brightness: Brightness.dark,
          ),
          useMaterial3: true,
        ),
        home: const AppShell(),
      ),
    );
  }
}

/// Library, Study, and Settings. The first screen is the library.
///
/// The shell has no app bar of its own. Each tab's scaffold takes the status
/// bar padding. An extra [SafeArea] here would leave a gap above that bar.
class AppShell extends StatefulWidget {
  const AppShell({super.key});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _Destination {
  const _Destination({
    required this.label,
    required this.icon,
    required this.selectedIcon,
    required this.screen,
  });

  final String label;
  final IconData icon;
  final IconData selectedIcon;
  final Widget screen;
}

class _AppShellState extends State<AppShell> {
  static const _destinations = [
    _Destination(
      label: 'Library',
      icon: Icons.library_books_outlined,
      selectedIcon: Icons.library_books,
      screen: LibraryScreen(),
    ),
    _Destination(
      label: 'Study',
      icon: Icons.style_outlined,
      selectedIcon: Icons.style,
      screen: StudyScreen(),
    ),
    _Destination(
      label: 'Settings',
      icon: Icons.settings_outlined,
      selectedIcon: Icons.settings,
      screen: SettingsScreen(),
    ),
  ];

  int _index = 0;

  @override
  Widget build(BuildContext context) {
    final destination = _destinations[_index];
    return Scaffold(
      body: destination.screen,
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (index) => setState(() => _index = index),
        destinations: [
          for (final destination in _destinations)
            NavigationDestination(
              icon: Icon(destination.icon),
              selectedIcon: Icon(destination.selectedIcon),
              label: destination.label,
            ),
        ],
      ),
    );
  }
}
