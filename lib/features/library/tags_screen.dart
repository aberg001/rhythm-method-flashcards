import 'package:flutter/material.dart';

import '../../domain/tag.dart';
import '../study/study_session_screen.dart';
import 'ids.dart';
import 'library_scope.dart';
import 'name_dialog.dart';

/// The library's tags. Rename, reorder, delete, and start a focused review.
class TagsScreen extends StatefulWidget {
  const TagsScreen({super.key});

  @override
  State<TagsScreen> createState() => _TagsScreenState();
}

class _TagsScreenState extends State<TagsScreen> {
  List<Tag> _tags = [];
  final Set<String> _checked = {};
  var _loaded = false;
  var _generation = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _load();
    });
  }

  Future<void> _load() async {
    final generation = ++_generation;
    final tags = await LibraryScope.of(context).listTags();
    if (!mounted || generation != _generation) return;
    setState(() {
      _tags = tags;
      _checked.removeWhere((id) => !tags.any((tag) => tag.id == id));
      _loaded = true;
    });
  }

  Future<void> _add() async {
    final name = await showNameDialog(context, title: 'Add tag');
    if (!mounted || name == null) return;
    try {
      await LibraryScope.of(context).insertTag(id: newId(), name: name);
    } on StateError catch (error) {
      if (!mounted) return;
      _showError(error.message);
      return;
    }
    if (!mounted) return;
    await _load();
  }

  Future<void> _rename(Tag tag) async {
    final name = await showNameDialog(
      context,
      title: 'Rename tag',
      initial: tag.name,
    );
    if (!mounted || name == null || name == tag.name) return;
    try {
      await LibraryScope.of(context).renameTag(tag.id, name);
    } on StateError catch (error) {
      if (!mounted) return;
      _showError(error.message);
      return;
    }
    if (!mounted) return;
    await _load();
  }

  Future<void> _delete(Tag tag) async {
    final confirmed = await showConfirmDialog(
      context,
      title: 'Delete tag?',
      message: 'Delete ${tag.name}? Cards keep their text.',
      confirmLabel: 'Delete',
    );
    if (!confirmed || !mounted) return;
    await LibraryScope.of(context).deleteTag(tag.id);
    if (!mounted) return;
    await _load();
  }

  Future<void> _move(int index, int delta) async {
    final target = index + delta;
    if (target < 0 || target >= _tags.length) return;
    final ids = [for (final tag in _tags) tag.id];
    final id = ids.removeAt(index);
    ids.insert(target, id);
    await LibraryScope.of(context).reorderTags(ids);
    if (!mounted) return;
    await _load();
  }

  Future<void> _study() async {
    final selected = [
      for (final tag in _tags)
        if (_checked.contains(tag.id)) tag,
    ];
    if (selected.isEmpty) return;
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (context) => StudySessionScreen(
          title: selected.map((tag) => tag.name).join(', '),
          tagIds: {for (final tag in selected) tag.id},
        ),
      ),
    );
  }

  void _showError(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.paddingOf(context).bottom;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Tags'),
        actions: [
          IconButton(
            tooltip: 'Add tag',
            onPressed: _add,
            icon: const Icon(Icons.add),
          ),
        ],
      ),
      body: !_loaded
          ? const SizedBox.shrink()
          : ListView(
              padding: EdgeInsets.only(bottom: bottom + 16),
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                  child: FilledButton(
                    key: const Key('study-tags-button'),
                    onPressed: _checked.isEmpty ? null : _study,
                    child: const Text('Study'),
                  ),
                ),
                if (_tags.isEmpty)
                  const Padding(
                    padding: EdgeInsets.fromLTRB(16, 0, 16, 8),
                    child: Text('Add a tag to label cards.'),
                  ),
                for (var index = 0; index < _tags.length; index++)
                  Builder(
                    builder: (context) {
                      final tag = _tags[index];
                      return _TagRow(
                        tag: tag,
                        checked: _checked.contains(tag.id),
                        onChecked: (value) {
                          setState(() {
                            if (value) {
                              _checked.add(tag.id);
                            } else {
                              _checked.remove(tag.id);
                            }
                          });
                        },
                        onRename: () => _rename(tag),
                        onDelete: () => _delete(tag),
                        onMoveUp: index == 0 ? null : () => _move(index, -1),
                        onMoveDown: index == _tags.length - 1
                            ? null
                            : () => _move(index, 1),
                        reorderable: _tags.length > 1,
                      );
                    },
                  ),
              ],
            ),
    );
  }
}

class _TagRow extends StatelessWidget {
  const _TagRow({
    required this.tag,
    required this.checked,
    required this.onChecked,
    required this.onRename,
    required this.onDelete,
    required this.onMoveUp,
    required this.onMoveDown,
    required this.reorderable,
  });

  final Tag tag;
  final bool checked;
  final ValueChanged<bool> onChecked;
  final VoidCallback onRename;
  final VoidCallback onDelete;
  final VoidCallback? onMoveUp;
  final VoidCallback? onMoveDown;
  final bool reorderable;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Checkbox(
        key: Key('tag-check-${tag.id}'),
        value: checked,
        onChanged: (value) => onChecked(value ?? false),
      ),
      title: Text(tag.name, maxLines: 1, overflow: TextOverflow.ellipsis),
      onTap: onRename,
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (reorderable) ...[
            IconButton(
              tooltip: 'Move up',
              onPressed: onMoveUp,
              icon: const Icon(Icons.arrow_upward),
              visualDensity: VisualDensity.compact,
            ),
            IconButton(
              tooltip: 'Move down',
              onPressed: onMoveDown,
              icon: const Icon(Icons.arrow_downward),
              visualDensity: VisualDensity.compact,
            ),
          ],
          IconButton(
            tooltip: 'Delete tag',
            onPressed: onDelete,
            icon: const Icon(Icons.delete_outlined),
            visualDensity: VisualDensity.compact,
          ),
        ],
      ),
    );
  }
}
