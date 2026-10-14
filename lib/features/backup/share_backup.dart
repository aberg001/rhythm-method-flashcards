import 'dart:io';
import 'dart:ui';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

const _backupFileName = 'rhythm-method-backup.json';

/// Writes [json] to a temporary file and opens the platform share sheet.
///
/// [origin] is the export button's rectangle in global coordinates. iOS
/// rejects a zero rectangle, so a missing size is replaced with a small one.
Future<void> shareLibraryBackup(String json, Rect origin) async {
  final directory = await getTemporaryDirectory();
  final file = File(p.join(directory.path, _backupFileName));
  await file.writeAsString(json);
  final shareOrigin = origin.width <= 0 || origin.height <= 0
      ? const Rect.fromLTWH(0, 0, 2, 2)
      : origin;
  await SharePlus.instance.share(
    ShareParams(
      files: [
        XFile(file.path, mimeType: 'application/json', name: _backupFileName),
      ],
      fileNameOverrides: const [_backupFileName],
      subject: 'Rhythm Method Flashcards',
      sharePositionOrigin: shareOrigin,
    ),
  );
}
