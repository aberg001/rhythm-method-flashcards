import 'package:flutter/material.dart';

import 'study_session_screen.dart';

/// Study tab. A topic in the library starts a scoped session. Study all
/// covers every topic and sits above the tab bar.
class StudyScreen extends StatelessWidget {
  const StudyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Study')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'A study session will start from a topic in the library.',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyLarge,
              ),
              const SizedBox(height: 24),
              FilledButton(
                onPressed: () {
                  Navigator.of(context, rootNavigator: true).push(
                    MaterialPageRoute<void>(
                      builder: (context) =>
                          const StudySessionScreen(title: 'All topics'),
                    ),
                  );
                },
                child: const Text('Study all'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
