import 'package:flutter/material.dart';

import '../../data/card_import.dart';

/// Shows what an import will add. Cancel, a tap outside, and a file with
/// nothing to add all return false.
Future<bool> showCardImportPreview(
  BuildContext context,
  CardImportPlan plan,
) async {
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (context) {
      return AlertDialog(
        title: const Text('Import cards?'),
        content: SingleChildScrollView(
          child: Text(cardImportPreviewText(plan)),
        ),
        actions: [
          if (plan.added == 0)
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Close'),
            )
          else ...[
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Import'),
            ),
          ],
        ],
      );
    },
  );
  return confirmed ?? false;
}
