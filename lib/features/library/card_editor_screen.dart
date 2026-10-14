import 'package:flutter/material.dart';

import '../../domain/scheduler.dart';
import 'ids.dart';
import 'library_scope.dart';
import 'name_dialog.dart';

/// Creates a card or edits its front and back. Schedule fields stay put.
class CardEditorScreen extends StatefulWidget {
  const CardEditorScreen({super.key, required this.topicId, this.card});

  final String topicId;
  final FlashCard? card;

  @override
  State<CardEditorScreen> createState() => _CardEditorScreenState();
}

class _CardEditorScreenState extends State<CardEditorScreen> {
  late final TextEditingController _front;
  late final TextEditingController _back;
  var _busy = false;

  bool get _editing => widget.card != null;

  @override
  void initState() {
    super.initState();
    _front = TextEditingController(text: widget.card?.front ?? '');
    _back = TextEditingController(text: widget.card?.back ?? '');
  }

  @override
  void dispose() {
    _front.dispose();
    _back.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_busy) return;
    final front = _front.text.trim();
    final back = _back.text.trim();
    if (front.isEmpty || back.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter a front and a back.')),
      );
      return;
    }
    setState(() => _busy = true);
    final repository = LibraryScope.of(context);
    final existing = widget.card;
    if (existing == null) {
      await repository.insertCard(
        FlashCard.fresh(
          id: newId(),
          topicId: widget.topicId,
          front: front,
          back: back,
          createdAt: DateTime.now().toUtc(),
        ),
      );
    } else {
      await repository.updateCardContent(existing.id, front: front, back: back);
    }
    if (!mounted) return;
    Navigator.of(context).pop();
  }

  Future<void> _delete() async {
    if (_busy) return;
    final card = widget.card;
    if (card == null) return;
    final confirmed = await showConfirmDialog(
      context,
      title: 'Delete card?',
      message: 'Delete this card?',
      confirmLabel: 'Delete',
    );
    if (!confirmed || !mounted) return;
    setState(() => _busy = true);
    await LibraryScope.of(context).deleteCard(card.id);
    if (!mounted) return;
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.paddingOf(context).bottom;
    return Scaffold(
      appBar: AppBar(
        title: Text(_editing ? 'Edit card' : 'New card'),
        actions: [
          TextButton(
            onPressed: _busy ? null : _save,
            child: const Text('Save'),
          ),
        ],
      ),
      body: ListView(
        padding: EdgeInsets.fromLTRB(16, 16, 16, 16 + bottom),
        children: [
          TextField(
            key: const Key('card-front'),
            controller: _front,
            decoration: const InputDecoration(labelText: 'Front'),
            textCapitalization: TextCapitalization.sentences,
            minLines: 2,
            maxLines: 6,
          ),
          const SizedBox(height: 16),
          TextField(
            key: const Key('card-back'),
            controller: _back,
            decoration: const InputDecoration(labelText: 'Back'),
            textCapitalization: TextCapitalization.sentences,
            minLines: 4,
            maxLines: 8,
          ),
          if (_editing) ...[
            const SizedBox(height: 24),
            TextButton(
              onPressed: _busy ? null : _delete,
              style: TextButton.styleFrom(
                foregroundColor: Theme.of(context).colorScheme.error,
              ),
              child: const Text('Delete card'),
            ),
          ],
        ],
      ),
    );
  }
}
