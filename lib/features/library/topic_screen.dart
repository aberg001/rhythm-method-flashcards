import 'package:flutter/material.dart';

import '../../domain/scheduler.dart';
import '../study/study_session_screen.dart';
import 'card_editor_screen.dart';
import 'ids.dart';
import 'library_scope.dart';
import 'name_dialog.dart';
import 'topic_tile.dart';

/// One topic: its subtopics, its own cards, and a study session for this scope.
class TopicScreen extends StatefulWidget {
  const TopicScreen({super.key, required this.topicId});

  final String topicId;

  @override
  State<TopicScreen> createState() => _TopicScreenState();
}

class _TopicScreenState extends State<TopicScreen> {
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

  Topic? get _topic =>
      _topics.where((topic) => topic.id == widget.topicId).firstOrNull;

  List<Topic> get _children =>
      _topics.where((topic) => topic.parentId == widget.topicId).toList();

  List<FlashCard> get _ownCards =>
      _cards.where((card) => card.topicId == widget.topicId).toList();

  String _subtitle(String topicId) {
    final subtopics = _topics
        .where((topic) => topic.parentId == topicId)
        .length;
    final cards = _cards.where((card) => card.topicId == topicId).length;
    return topicCountLabel(subtopics: subtopics, cards: cards);
  }

  Future<void> _rename(Topic topic) async {
    final name = await showNameDialog(
      context,
      title: 'Rename topic',
      initial: topic.name,
    );
    if (!mounted || name == null) return;
    await LibraryScope.of(context).renameTopic(topic.id, name);
    if (!mounted) return;
    await _load();
  }

  Future<void> _delete(Topic topic) async {
    final confirmed = await showConfirmDialog(
      context,
      title: 'Delete topic?',
      message: 'Delete ${topic.name}?',
      confirmLabel: 'Delete',
    );
    if (!confirmed || !mounted) return;
    try {
      await LibraryScope.of(context).deleteTopic(topic.id);
    } on StateError catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error.message.toString())));
      return;
    }
    if (!mounted) return;
    Navigator.of(context).pop();
  }

  Future<void> _addSubtopic() async {
    final name = await showNameDialog(context, title: 'Add subtopic');
    if (!mounted || name == null) return;
    await LibraryScope.of(
      context,
    ).insertTopic(id: newId(), name: name, parentId: widget.topicId);
    if (!mounted) return;
    await _load();
  }

  Future<void> _openChild(Topic child) async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (context) => TopicScreen(topicId: child.id),
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

  Future<void> _addCard() async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (context) => CardEditorScreen(topicId: widget.topicId),
      ),
    );
    if (!mounted) return;
    await _load();
  }

  Future<void> _openCard(FlashCard card) async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (context) =>
            CardEditorScreen(topicId: card.topicId, card: card),
      ),
    );
    if (!mounted) return;
    await _load();
  }

  void _study(Topic topic) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (context) =>
            StudySessionScreen(title: topic.name, scopeTopicId: topic.id),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final topic = _topic;
    if (!_loaded || topic == null) {
      return Scaffold(
        appBar: AppBar(title: Text(topic?.name ?? '')),
        body: const SizedBox.shrink(),
      );
    }
    final children = _children;
    final cards = _ownCards;
    final bottom = MediaQuery.paddingOf(context).bottom;
    return Scaffold(
      appBar: AppBar(
        title: Text(topic.name, overflow: TextOverflow.ellipsis),
        actions: [
          IconButton(
            tooltip: 'Rename topic',
            onPressed: () => _rename(topic),
            icon: const Icon(Icons.edit_outlined),
          ),
          IconButton(
            tooltip: 'Delete topic',
            onPressed: () => _delete(topic),
            icon: const Icon(Icons.delete_outlined),
          ),
        ],
      ),
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: FilledButton(
                onPressed: () => _study(topic),
                child: const Text('Study'),
              ),
            ),
          ),
          const SliverToBoxAdapter(child: _SectionHeader('Subtopics')),
          SliverList.builder(
            itemCount: children.length,
            itemBuilder: (context, index) {
              final child = children[index];
              return TopicTile(
                key: ValueKey(child.id),
                topic: child,
                subtitle: _subtitle(child.id),
                onTap: () => _openChild(child),
                reorderable: children.length > 1,
                onMoveUp: index == 0 ? null : () => _move(children, index, -1),
                onMoveDown: index == children.length - 1
                    ? null
                    : () => _move(children, index, 1),
              );
            },
          ),
          SliverToBoxAdapter(
            child: Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                onPressed: _addSubtopic,
                icon: const Icon(Icons.add),
                label: const Text('Add subtopic'),
              ),
            ),
          ),
          const SliverToBoxAdapter(child: _SectionHeader('Cards')),
          if (cards.isEmpty)
            const SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.fromLTRB(16, 0, 16, 8),
                child: Text('Add a card to this topic.'),
              ),
            ),
          SliverList.builder(
            itemCount: cards.length,
            itemBuilder: (context, index) {
              final card = cards[index];
              return ListTile(
                title: Text(
                  card.front,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                subtitle: Text(
                  card.back,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                onTap: () => _openCard(card),
              );
            },
          ),
          SliverToBoxAdapter(
            child: Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                onPressed: _addCard,
                icon: const Icon(Icons.add),
                label: const Text('Add card'),
              ),
            ),
          ),
          SliverPadding(padding: EdgeInsets.only(bottom: bottom + 16)),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Text(text, style: Theme.of(context).textTheme.titleMedium),
    );
  }
}
