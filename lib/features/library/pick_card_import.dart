import 'package:file_selector/file_selector.dart';

import '../../data/card_import.dart';

const _tableType = XTypeGroup(
  label: 'Card table',
  extensions: ['csv', 'tsv', 'txt'],
  mimeTypes: ['text/csv', 'text/tab-separated-values', 'text/plain'],
  uniformTypeIdentifiers: [
    'public.comma-separated-values-text',
    'public.tab-separated-values-text',
    'public.plain-text',
  ],
);

/// Opens the platform file picker and returns the chosen table.
///
/// Returns null when the user cancels. The text is UTF-8.
Future<CardImportFile?> pickCardImport() async {
  final file = await openFile(acceptedTypeGroups: const [_tableType]);
  if (file == null) return null;
  return CardImportFile(text: await file.readAsString(), name: file.name);
}
