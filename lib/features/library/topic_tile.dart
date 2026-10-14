import 'package:flutter/material.dart';

import '../../domain/scheduler.dart';

/// "1 subtopic" / "N subtopics" and "1 card" / "N cards", joined with a dot.
String topicCountLabel({required int subtopics, required int cards}) {
  final subtopicLabel = subtopics == 1 ? '1 subtopic' : '$subtopics subtopics';
  final cardLabel = cards == 1 ? '1 card' : '$cards cards';
  return '$subtopicLabel · $cardLabel';
}

/// One topic row. Move buttons are hidden when it has no siblings.
class TopicTile extends StatelessWidget {
  const TopicTile({
    super.key,
    required this.topic,
    required this.subtitle,
    required this.onTap,
    required this.reorderable,
    required this.onMoveUp,
    required this.onMoveDown,
  });

  final Topic topic;
  final String subtitle;
  final VoidCallback onTap;
  final bool reorderable;
  final VoidCallback? onMoveUp;
  final VoidCallback? onMoveDown;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: Text(topic.name),
      subtitle: Text(subtitle),
      onTap: onTap,
      trailing: reorderable
          ? SizedBox(
              width: 96,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  _MoveButton(
                    tooltip: 'Move up',
                    icon: Icons.arrow_upward,
                    onPressed: onMoveUp,
                  ),
                  _MoveButton(
                    tooltip: 'Move down',
                    icon: Icons.arrow_downward,
                    onPressed: onMoveDown,
                  ),
                ],
              ),
            )
          : null,
    );
  }
}

class _MoveButton extends StatelessWidget {
  const _MoveButton({
    required this.tooltip,
    required this.icon,
    required this.onPressed,
  });

  final String tooltip;
  final IconData icon;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: tooltip,
      onPressed: onPressed,
      icon: Icon(icon),
      visualDensity: VisualDensity.compact,
      padding: EdgeInsets.zero,
      constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
    );
  }
}
