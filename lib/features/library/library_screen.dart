import 'package:flutter/material.dart';

import '../../domain/scheduler.dart';
import 'ids.dart';
import 'library_scope.dart';
import 'name_dialog.dart';
import 'tags_screen.dart';
import 'topic_screen.dart';
import 'topic_tile.dart';

/// Root topics. Opening one pushes its topic screen over the tab bar.
class LibraryScreen extends StatefulWidget {
  const LibraryScreen({super.key});

  @override
  State<LibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryScreenState extends State<LibraryScreen> {
  List<Topic> _topics = [];
  List<FlashCard> _cards = [];
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
    final repository = LibraryScope.of(context);
    final topics = await repository.listTopics();
    final cards = await repository.listCards();
    if (!mounted || generation != _generation) return;
    setState(() {
      _topics = topics;
      _cards = cards;
      _loaded = true;
    });
  }

  List<Topic> get _roots =>
      _topics.where((topic) => topic.parentId == null).toList();

  String _subtitle(String topicId) {
    final subtopics = _topics
        .where((topic) => topic.parentId == topicId)
        .length;
    final cards = _cards.where((card) => card.topicId == topicId).length;
    return topicCountLabel(subtopics: subtopics, cards: cards);
  }

  Future<void> _addTopic() async {
    final name = await showNameDialog(context, title: 'Add topic');
    if (!mounted || name == null) return;
    await LibraryScope.of(context).insertTopic(id: newId(), name: name);
    if (!mounted) return;
    await _load();
  }

  Future<void> _open(Topic topic) async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (context) => TopicScreen(topicId: topic.id),
      ),
    );
    if (!mounted) return;
    await _load();
  }

  Future<void> _move(List<Topic> siblings, int index, int delta) async {
    final target = index + delta;
    if (target < 0 || target >= siblings.length) return;
    final ids = [for (final topic in siblings) topic.id];
    final id = ids.removeAt(index);
    ids.insert(target, id);
    await LibraryScope.of(context).reorderTopics(ids);
    if (!mounted) return;
    await _load();
  }

  @override
  Widget build(BuildContext context) {
    final roots = _roots;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Library'),
        actions: [
          IconButton(
            key: const Key('tags-button'),
            tooltip: 'Tags',
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (context) => const TagsScreen(),
                ),
              );
            },
            icon: const Icon(Icons.label_outline),
          ),
          IconButton(
            tooltip: 'Add topic',
            onPressed: _addTopic,
            icon: const Icon(Icons.add),
          ),
        ],
      ),
      body: !_loaded
          ? const SizedBox.shrink()
          : roots.isEmpty
          ? _EmptyLibrary(onAdd: _addTopic)
          : ListView.builder(
              itemCount: roots.length,
              itemBuilder: (context, index) {
                final topic = roots[index];
                return TopicTile(
                  key: ValueKey(topic.id),
                  topic: topic,
                  subtitle: _subtitle(topic.id),
                  onTap: () => _open(topic),
                  reorderable: roots.length > 1,
                  onMoveUp: index == 0 ? null : () => _move(roots, index, -1),
                  onMoveDown: index == roots.length - 1
                      ? null
                      : () => _move(roots, index, 1),
                );
              },
            ),
    );
  }
}

class _EmptyLibrary extends StatelessWidget {
  const _EmptyLibrary({required this.onAdd});

  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Add a topic, then add a card.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            const SizedBox(height: 16),
            FilledButton(onPressed: onAdd, child: const Text('Add topic')),
          ],
        ),
      ),
    );
  }
}
