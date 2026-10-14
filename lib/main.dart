import 'package:flutter/material.dart';

import 'app.dart';
import 'data/library_repository.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final repository = await openLibraryRepository();
  runApp(RhythmMethodApp(repository: repository));
}
