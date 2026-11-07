import 'package:flutter/material.dart';

import '../../domain/scheduler.dart';
import '../../domain/tag.dart';
import '../study/study_session_screen.dart';
import 'card_editor_screen.dart';
import 'card_progress.dart';
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
  List<Tag> _tags = [];
  Map<String, Set<String>> _cardTagIds = {};
  final Set<String> _filterTagIds = {};
  var _filterUntagged = false;
  SchedulerParameters _parameters = SchedulerParameters.defaults();
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
    var cards = await repository.listCards();
    final tags = await repository.listTags();
    final links = await repository.cardTagIds();
    final parameters = await repository.loadSettings();
    final topic = topics.where((item) => item.id == widget.topicId).firstOrNull;
    if (topic != null && topic.reverseDrill) {
      await repository.ensureReverseFaces(
        topic.id,
        now: DateTime.now().toUtc(),
      );
      if (!mounted || generation != _generation) return;
      cards = await repository.listCards();
    }
    if (!mounted || generation != _generation) return;
    setState(() {
      _topics = topics;
      _cards = cards;
      _tags = tags;
      _cardTagIds = {
        for (final entry in links.entries) entry.key: entry.value.toSet(),
      };
      _filterTagIds.removeWhere((id) => !tags.any((tag) => tag.id == id));
      _parameters = parameters;
      _loaded = true;
    });
  }

  Topic? get _topic =>
      _topics.where((topic) => topic.id == widget.topicId).firstOrNull;

  List<Topic> get _children =>
      _topics.where((topic) => topic.parentId == widget.topicId).toList();

  List<FlashCard> get _ownCards =>
      _cards.where((card) => card.topicId == widget.topicId).toList();

  List<FlashCard> get _visibleOwnCards => cardsMatchingTags(
    cards: _ownCards,
    tagsByCard: _cardTagIds,
    tagIds: _filterTagIds,
    untagged: _filterUntagged,
  );

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

  Future<void> _setReverseDrill(bool enabled) async {
    final topic = _topic;
    if (topic == null || topic.reverseDrill == enabled) return;
    if (enabled) {
      final count = _ownCards
          .where((card) => !card.hasReverse && cardIsLearned(card, _parameters))
          .length;
      if (count > 0) {
        final learned = count == 1
            ? '1 learned card will gain a back-to-front drill.'
            : '$count learned cards will gain a back-to-front drill.';
        final confirmed = await showConfirmDialog(
          context,
          title: 'Drill these backs?',
          message: '$learned Those drills wait ahead of cards not yet started.',
          confirmLabel: 'Turn on',
        );
        if (!confirmed || !mounted) return;
      }
    }
    await LibraryScope.of(
      context,
    ).setReverseDrill(topic.id, enabled: enabled, now: DateTime.now().toUtc());
    if (!mounted) return;
    await _load();
  }

  Future<void> _study(Topic topic) async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (context) => StudySessionScreen(
          title: topic.name,
          scopeTopicId: topic.id,
          tagIds: _filterUntagged || _filterTagIds.isEmpty
              ? null
              : Set<String>.of(_filterTagIds),
          untagged: _filterUntagged,
        ),
      ),
    );
    if (!mounted) return;
    await _load();
  }

  void _toggleTagFilter(String id) {
    setState(() {
      _filterUntagged = false;
      if (!_filterTagIds.add(id)) _filterTagIds.remove(id);
    });
  }

  void _toggleUntagged() {
    setState(() {
      _filterUntagged = !_filterUntagged;
      if (_filterUntagged) _filterTagIds.clear();
    });
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
    final cards = _visibleOwnCards;
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
          SliverToBoxAdapter(
            child: SwitchListTile(
              key: const Key('reverse-drill-switch'),
              title: const Text('Reverse drill'),
              subtitle: const Text(
                'Every card also has a back-to-front drill. It waits until the front is learned, then comes before cards not yet started.',
              ),
              value: topic.reverseDrill,
              onChanged: _setReverseDrill,
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
          if (_tags.isNotEmpty)
            SliverToBoxAdapter(
              child: _TagFilter(
                tags: _tags,
                selected: _filterTagIds,
                untagged: _filterUntagged,
                onTag: _toggleTagFilter,
                onUntagged: _toggleUntagged,
              ),
            ),
          if (topic.reverseDrill && cards.isNotEmpty)
            const SliverToBoxAdapter(child: _FaceColumnHeader()),
          if (_ownCards.isEmpty)
            const SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.fromLTRB(16, 0, 16, 8),
                child: Text('Add a card to this topic.'),
              ),
            )
          else if (cards.isEmpty)
            const SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.fromLTRB(16, 0, 16, 8),
                child: Text('No cards match this filter.'),
              ),
            ),
          SliverList.builder(
            itemCount: cards.length,
            itemBuilder: (context, index) {
              final card = cards[index];
              final now = DateTime.now().toUtc();
              if (!topic.reverseDrill) {
                return ListTile(
                  visualDensity: VisualDensity.compact,
                  title: Text(
                    card.front,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  trailing: Text(
                    cardProgressLabel(
                      card: card,
                      parameters: _parameters,
                      now: now,
                    ),
                    maxLines: 1,
                  ),
                  onTap: () => _openCard(card),
                );
              }
              return ListTile(
                visualDensity: VisualDensity.compact,
                title: _FaceColumns(
                  front: card.front,
                  forward: faceProgressLabel(
                    card: card,
                    face: StudyFace.forward,
                    parameters: _parameters,
                    now: now,
                  ),
                  reverse: faceProgressLabel(
                    card: card,
                    face: StudyFace.reverse,
                    parameters: _parameters,
                    now: now,
                  ),
                  forwardKey: Key('forward-progress-${card.id}'),
                  reverseKey: Key('reverse-progress-${card.id}'),
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

const _statusColumnWidth = 128.0;

class _FaceColumnHeader extends StatelessWidget {
  const _FaceColumnHeader();

  @override
  Widget build(BuildContext context) {
    final style = Theme.of(context).textTheme.labelLarge;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 4),
      child: Row(
        children: [
          const Spacer(),
          SizedBox(
            width: _statusColumnWidth,
            child: Text(
              'Forward',
              key: const Key('forward-column'),
              textAlign: TextAlign.end,
              style: style,
            ),
          ),
          const SizedBox(width: 8),
          SizedBox(
            width: _statusColumnWidth,
            child: Text(
              'Reverse',
              key: const Key('reverse-column'),
              textAlign: TextAlign.end,
              style: style,
            ),
          ),
        ],
      ),
    );
  }
}

class _FaceColumns extends StatelessWidget {
  const _FaceColumns({
    required this.front,
    required this.forward,
    required this.reverse,
    required this.forwardKey,
    required this.reverseKey,
  });

  final String front;
  final String forward;
  final String reverse;
  final Key forwardKey;
  final Key reverseKey;

  @override
  Widget build(BuildContext context) {
    final style = Theme.of(context).textTheme.bodyMedium;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Text(front, maxLines: 1, overflow: TextOverflow.ellipsis),
        ),
        SizedBox(
          width: _statusColumnWidth,
          child: Text(
            forward,
            key: forwardKey,
            textAlign: TextAlign.end,
            style: style,
          ),
        ),
        const SizedBox(width: 8),
        SizedBox(
          width: _statusColumnWidth,
          child: Text(
            reverse,
            key: reverseKey,
            textAlign: TextAlign.end,
            style: style,
          ),
        ),
      ],
    );
  }
}

class _TagFilter extends StatelessWidget {
  const _TagFilter({
    required this.tags,
    required this.selected,
    required this.untagged,
    required this.onTag,
    required this.onUntagged,
  });

  final List<Tag> tags;
  final Set<String> selected;
  final bool untagged;
  final ValueChanged<String> onTag;
  final VoidCallback onUntagged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          for (final tag in tags)
            FilterChip(
              key: Key('tag-filter-${tag.id}'),
              label: Text(tag.name),
              selected: selected.contains(tag.id),
              onSelected: (_) => onTag(tag.id),
            ),
          FilterChip(
            key: const Key('tag-filter-untagged'),
            label: const Text('Untagged'),
            selected: untagged,
            onSelected: (_) => onUntagged(),
          ),
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
