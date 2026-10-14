import 'package:file_selector/file_selector.dart';

const _jsonType = XTypeGroup(
  label: 'JSON',
  extensions: ['json'],
  mimeTypes: ['application/json'],
  uniformTypeIdentifiers: ['public.json'],
);

/// Opens the platform file picker and returns the chosen backup text.
///
/// Returns null when the user cancels.
Future<String?> pickLibraryBackupJson() async {
  final file = await openFile(acceptedTypeGroups: const [_jsonType]);
  if (file == null) return null;
  return file.readAsString();
}
