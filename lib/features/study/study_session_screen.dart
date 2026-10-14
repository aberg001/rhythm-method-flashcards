import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';

import '../../data/library_repository.dart';
import '../../domain/scheduler.dart';
import '../library/card_editor_screen.dart';
import '../library/library_scope.dart';
import 'study_status.dart';

/// Distance or speed, in logical pixels, that counts as a grade swipe.
const _swipeDistance = 80.0;
const _swipeSpeed = 200.0;

/// One study session. Admissions and grades are written as they happen.
///
/// [now] and [draw] are test seams. A session uses the clock and a random
/// draw unless a test passes its own.
class StudySessionScreen extends StatefulWidget {
  const StudySessionScreen({
    super.key,
    required this.title,
    this.scopeTopicId,
    this.now,
    this.draw,
  });

  final String title;

  /// Topic plus descendants. Null studies every topic in the library.
  final String? scopeTopicId;

  final DateTime Function()? now;
  final WeightDraw? draw;

  @override
  State<StudySessionScreen> createState() => _StudySessionScreenState();
}

class _StudySessionScreenState extends State<StudySessionScreen> {
  List<Topic> _topics = [];
  List<FlashCard> _cards = [];
  SchedulerParameters? _parameters;
  FlashCard? _current;
  final List<StoredGrade> _grades = [];
  var _flipped = false;
  var _loaded = false;
  var _busy = false;
  var _generation = 0;
  var _dragDx = 0.0;

  DateTime _clock() => (widget.now ?? _utcNow)();

  WeightDraw get _draw => widget.draw ?? randomWeightDraw;

  bool get _canGrade => _loaded && _flipped && !_busy && _current != null;

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
    });
    await _selectNext(generation);
  }

  /// Selects the next card. An admission is stored before this returns, and
  /// the local list is updated so the next select cannot admit it again.
  ///
  /// Settings are read again here, so a change applies to this choice and
  /// not to review rows already stored.
  Future<void> _selectNext(int generation) async {
    final parameters = await LibraryScope.of(context).loadSettings();
    if (!mounted || generation != _generation) return;
    _parameters = parameters;
    final selection = selectCard(
      topics: _topics,
      cards: _cards,
      scopeTopicId: widget.scopeTopicId,
      now: _clock(),
      parameters: parameters,
      draw: _draw,
    );
    if (!mounted || generation != _generation) return;
    switch (selection) {
      case SessionClear():
        setState(() {
          _current = null;
          _flipped = false;
          _loaded = true;
          _busy = false;
        });
      case CardSelected(:final card, :final admitted):
        var shown = card;
        if (admitted) {
          shown = await LibraryScope.of(context).admit(card.id);
          if (!mounted || generation != _generation) return;
          _replace(shown);
        }
        setState(() {
          _current = shown;
          _flipped = false;
          _loaded = true;
          _busy = false;
        });
    }
  }

  void _replace(FlashCard card) {
    final index = _cards.indexWhere((item) => item.id == card.id);
    if (index == -1) {
      _cards.add(card);
    } else {
      _cards[index] = card;
    }
  }

  void _flip() {
    if (_current == null || _flipped || _busy) return;
    setState(() => _flipped = true);
  }

  void _onDragStart(DragStartDetails details) {
    _dragDx = 0;
  }

  void _onDragUpdate(DragUpdateDetails details) {
    _dragDx += details.delta.dx;
  }

  void _onDragEnd(DragEndDetails details) {
    final distance = _dragDx;
    _dragDx = 0;
    if (!_canGrade) return;
    final velocity = details.primaryVelocity ?? 0;
    final moved =
        distance.abs() >= _swipeDistance || velocity.abs() >= _swipeSpeed;
    if (!moved) return;
    final direction = velocity.abs() >= _swipeSpeed ? velocity : distance;
    if (direction < 0) {
      _grade(GradeOutcome.wrong);
    } else if (direction > 0) {
      _grade(GradeOutcome.correct);
    }
  }

  Future<void> _grade(GradeOutcome outcome) async {
    final card = _current;
    if (card == null || !_canGrade) return;
    final generation = ++_generation;
    final repository = LibraryScope.of(context);
    setState(() => _busy = true);
    final stored = await repository.grade(
      cardId: card.id,
      outcome: outcome,
      now: _clock(),
    );
    if (!mounted || generation != _generation) return;
    unawaited(HapticFeedback.selectionClick());
    _grades.add(stored);
    _replace(stored.result.after);
    await _selectNext(generation);
  }

  /// Pops the newest grade in this session and shows that card, already flipped.
  /// Does not select a different card and does not un-admit.
  Future<void> _undoGrade() async {
    if (_grades.isEmpty || _busy) return;
    final generation = ++_generation;
    final repository = LibraryScope.of(context);
    final stored = _grades.last;
    setState(() => _busy = true);
    final restored = await repository.undo(stored);
    if (!mounted || generation != _generation) return;
    _grades.removeLast();
    _replace(restored);
    setState(() {
      _current = restored;
      _flipped = true;
      _loaded = true;
      _busy = false;
    });
  }

  Future<void> _edit() async {
    final card = _current;
    if (card == null || _busy) return;
    final repository = LibraryScope.of(context);
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (context) =>
            CardEditorScreen(topicId: card.topicId, card: card),
      ),
    );
    if (!mounted) return;
    final generation = ++_generation;
    setState(() => _busy = true);
    try {
      final updated = await repository.card(card.id);
      if (!mounted || generation != _generation) return;
      _replace(updated);
      setState(() {
        _current = updated;
        _busy = false;
      });
    } on StateError {
      if (!mounted || generation != _generation) return;
      _cards.removeWhere((item) => item.id == card.id);
      _grades.removeWhere((grade) => grade.result.before.id == card.id);
      await _selectNext(generation);
    }
  }

  @override
  Widget build(BuildContext context) {
    final card = _current;
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title, overflow: TextOverflow.ellipsis),
        actions: [
          if (card != null)
            IconButton(
              key: const Key('edit-button'),
              tooltip: 'Edit',
              onPressed: _busy ? null : _edit,
              icon: const Icon(Icons.edit_outlined),
            ),
          IconButton(
            key: const Key('undo-button'),
            tooltip: 'Undo',
            onPressed: _grades.isEmpty || _busy ? null : _undoGrade,
            icon: const Icon(Icons.undo),
          ),
        ],
      ),
      body: !_loaded
          ? const SizedBox.shrink()
          : SafeArea(
              top: false,
              child: card == null
                  ? _clearBody(context)
                  : _cardBody(context, card),
            ),
    );
  }

  Widget _clearBody(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Center(
        child: Text(
          'Nothing is due.',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodyLarge,
        ),
      ),
    );
  }

  Widget _cardBody(BuildContext context, FlashCard card) {
    final parameters = _parameters!;
    final counts = countStudy(
      topics: _topics,
      cards: _cards,
      scopeTopicId: widget.scopeTopicId,
      now: _clock(),
      parameters: parameters,
    );
    final status = studyStatusLine(
      learning: counts.learning,
      window: parameters.learningWindowSize,
      newWaiting: counts.newWaiting,
      learnedDue: counts.learnedDue,
    );
    final canFlip = !_flipped && !_busy;
    final spoken = _flipped ? '${card.front}\n${card.back}' : card.front;
    final cardFace = GestureDetector(
      behavior: HitTestBehavior.opaque,
      onHorizontalDragStart: _onDragStart,
      onHorizontalDragUpdate: _onDragUpdate,
      onHorizontalDragEnd: _onDragEnd,
      child: Semantics(
        label: spoken,
        child: ExcludeSemantics(
          child: Card(
            key: const Key('card-face'),
            margin: EdgeInsets.zero,
            clipBehavior: Clip.antiAlias,
            child: InkWell(
              onTap: canFlip ? _flip : null,
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      card.front,
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    if (_flipped) ...[
                      const SizedBox(height: 24),
                      Text(
                        card.back,
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final minHeight = constraints.maxHeight.isFinite
                    ? constraints.maxHeight
                    : 0.0;
                return SingleChildScrollView(
                  child: _StudyColumn(
                    minHeight: minHeight,
                    status: Text(status, textAlign: TextAlign.center),
                    card: cardFace,
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _LabeledButton(
                  label: 'Wrong',
                  onPressed: _canGrade
                      ? () => _grade(GradeOutcome.wrong)
                      : null,
                  child: OutlinedButton(
                    key: const Key('wrong-button'),
                    onPressed: _canGrade
                        ? () => _grade(GradeOutcome.wrong)
                        : null,
                    child: const FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text('Wrong'),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _LabeledButton(
                  label: 'Flip',
                  onPressed: canFlip ? _flip : null,
                  child: FilledButton.tonal(
                    key: const Key('flip-button'),
                    onPressed: canFlip ? _flip : null,
                    child: const FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text('Flip'),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _LabeledButton(
                  label: 'Correct',
                  onPressed: _canGrade
                      ? () => _grade(GradeOutcome.correct)
                      : null,
                  child: FilledButton(
                    key: const Key('correct-button'),
                    onPressed: _canGrade
                        ? () => _grade(GradeOutcome.correct)
                        : null,
                    child: const FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text('Correct'),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Status and card in one scroll. The card grows with its text, and still
/// fills the space above the grade buttons when the text is short.
class _StudyColumn extends MultiChildRenderObjectWidget {
  _StudyColumn({
    required this.minHeight,
    required Widget status,
    required Widget card,
  }) : super(children: [status, card]);

  final double minHeight;

  @override
  RenderObject createRenderObject(BuildContext context) {
    return _RenderStudyColumn(minHeight: minHeight);
  }

  @override
  void updateRenderObject(
    BuildContext context,
    _RenderStudyColumn renderObject,
  ) {
    renderObject.minHeight = minHeight;
  }
}

class _StudyColumnParentData extends ContainerBoxParentData<RenderBox> {}

class _RenderStudyColumn extends RenderBox
    with
        ContainerRenderObjectMixin<RenderBox, _StudyColumnParentData>,
        RenderBoxContainerDefaultsMixin<RenderBox, _StudyColumnParentData> {
  _RenderStudyColumn({required double minHeight}) : _minHeight = minHeight;

  static const _gap = 16.0;

  double _minHeight;

  set minHeight(double value) {
    if (_minHeight == value) return;
    _minHeight = value;
    markNeedsLayout();
  }

  @override
  void setupParentData(RenderBox child) {
    if (child.parentData is! _StudyColumnParentData) {
      child.parentData = _StudyColumnParentData();
    }
  }

  @override
  void performLayout() {
    final status = firstChild!;
    final card = childAfter(status)!;
    final width = constraints.hasBoundedWidth ? constraints.maxWidth : 0.0;
    final childConstraints = BoxConstraints.tightFor(width: width);

    status.layout(childConstraints, parentUsesSize: true);
    card.layout(childConstraints, parentUsesSize: true);

    final natural = status.size.height + _gap + card.size.height;
    final height = natural > _minHeight ? natural : _minHeight;
    final cardHeight = height - status.size.height - _gap;
    if (cardHeight > card.size.height) {
      card.layout(
        BoxConstraints.tightFor(width: width, height: cardHeight),
        parentUsesSize: true,
      );
    }

    size = constraints.constrain(Size(width, height));
    (status.parentData! as _StudyColumnParentData).offset = Offset.zero;
    (card.parentData! as _StudyColumnParentData).offset = Offset(
      0,
      status.size.height + _gap,
    );
  }

  @override
  void paint(PaintingContext context, Offset offset) {
    defaultPaint(context, offset);
  }

  @override
  bool hitTestChildren(BoxHitTestResult result, {required Offset position}) {
    return defaultHitTestChildren(result, position: position);
  }

  @override
  void applyPaintTransform(RenderObject child, Matrix4 transform) {
    final parentData = child.parentData! as _StudyColumnParentData;
    transform.translateByDouble(
      parentData.offset.dx,
      parentData.offset.dy,
      0,
      1,
    );
  }
}

/// One spoken name for VoiceOver. The visible control keeps its own key.
class _LabeledButton extends StatelessWidget {
  const _LabeledButton({
    required this.label,
    required this.onPressed,
    required this.child,
  });

  final String label;
  final VoidCallback? onPressed;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      enabled: onPressed != null,
      label: label,
      onTap: onPressed,
      child: ExcludeSemantics(child: child),
    );
  }
}

DateTime _utcNow() => DateTime.now().toUtc();
