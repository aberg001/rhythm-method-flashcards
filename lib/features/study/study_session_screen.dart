import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';

import '../../data/library_repository.dart';
import '../../domain/scheduler.dart';
import '../../domain/tag.dart';
import '../library/card_editor_screen.dart';
import '../library/library_scope.dart';
import 'study_status.dart';

/// Distance or speed, in logical pixels, that counts as a grade swipe.
const _swipeDistance = 80.0;
const _swipeSpeed = 200.0;

/// How long one Y-axis turn takes. The text swaps at the midpoint.
const _flipDuration = Duration(milliseconds: 300);

/// Answer-side border. A warm accent, neither green nor red.
const _answerSideColor = Color(0xFFB5683A);

/// One study session. Admissions and grades are written as they happen.
///
/// [now] and [draw] are test seams. A session uses the clock and a random
/// draw unless a test passes its own.
class StudySessionScreen extends StatefulWidget {
  const StudySessionScreen({
    super.key,
    required this.title,
    this.scopeTopicId,
    this.tagIds,
    this.untagged = false,
    this.now,
    this.draw,
  });

  final String title;

  /// Topic plus descendants. Null studies every topic in the library.
  final String? scopeTopicId;

  /// Cards that have any of these tags. Null studies every card in scope.
  /// Ignored when [untagged] is set. Not combined with [untagged].
  final Set<String>? tagIds;

  /// Cards with no tags. Not combined with [tagIds].
  final bool untagged;

  final DateTime Function()? now;
  final WeightDraw? draw;

  @override
  State<StudySessionScreen> createState() => _StudySessionScreenState();
}

class _StudySessionScreenState extends State<StudySessionScreen>
    with TickerProviderStateMixin {
  List<Topic> _topics = [];
  List<FlashCard> _cards = [];
  SchedulerParameters? _parameters;
  FlashCard? _current;
  var _face = StudyFace.forward;
  final List<StoredGrade> _grades = [];
  var _showAnswer = false;
  var _answerSeen = false;
  var _swappedThisTurn = false;
  var _loaded = false;
  var _busy = false;
  var _generation = 0;
  var _dragDx = 0.0;
  late final AnimationController _turn;

  DateTime _clock() => (widget.now ?? _utcNow)();

  WeightDraw get _draw => widget.draw ?? randomWeightDraw;

  bool get _canGrade =>
      _loaded &&
      _answerSeen &&
      !_turn.isAnimating &&
      !_busy &&
      _current != null;

  bool get _canSwipe => _canGrade && _showAnswer;

  bool get _canFlip => _current != null && !_busy && !_turn.isAnimating;

  @override
  void initState() {
    super.initState();
    _turn = AnimationController(vsync: this, duration: _flipDuration);
    _turn.addListener(_onTurnTick);
    _turn.addStatusListener(_onTurnStatus);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _load();
    });
  }

  @override
  void dispose() {
    _turn.removeStatusListener(_onTurnStatus);
    _turn.removeListener(_onTurnTick);
    _turn.dispose();
    super.dispose();
  }

  void _onTurnTick() {
    if (!mounted || _swappedThisTurn || _turn.value < 0.5) return;
    _swappedThisTurn = true;
    setState(() {
      _showAnswer = !_showAnswer;
      if (_showAnswer) _answerSeen = true;
    });
  }

  /// The midpoint swap happens while the turn is still running, and that is
  /// the build that would otherwise leave Wrong and Correct disabled. The
  /// ticker does not ask for another build when it stops.
  void _onTurnStatus(AnimationStatus status) {
    if (!mounted) return;
    if (status == AnimationStatus.completed ||
        status == AnimationStatus.dismissed) {
      setState(() {});
    }
  }

  /// Puts the card on the prompt or the answer with no turn in progress.
  void _resetFace({required bool answer}) {
    _turn.stop();
    _swappedThisTurn = false;
    _turn.value = 0;
    _showAnswer = answer;
    _answerSeen = answer;
  }

  Future<void> _load() async {
    final generation = ++_generation;
    final repository = LibraryScope.of(context);
    final topics = await repository.listTopics();
    final inScope = topicIdsInScope(topics, widget.scopeTopicId);
    for (final topic in topics) {
      if (!topic.reverseDrill || !inScope.contains(topic.id)) continue;
      await repository.ensureReverseFaces(topic.id, now: _clock());
      if (!mounted || generation != _generation) return;
    }
    final links = await repository.cardTagIds();
    final cards = cardsMatchingTags(
      cards: await repository.listCards(),
      tagsByCard: {
        for (final entry in links.entries) entry.key: entry.value.toSet(),
      },
      tagIds: widget.tagIds,
      untagged: widget.untagged,
    );
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
        _resetFace(answer: false);
        setState(() {
          _current = null;
          _face = StudyFace.forward;
          _loaded = true;
          _busy = false;
        });
      case CardSelected(:final card, :final admitted, :final face):
        var shown = card;
        if (admitted) {
          shown = await LibraryScope.of(context).admit(card.id, face: face);
          if (!mounted || generation != _generation) return;
          _replace(shown);
        }
        _resetFace(answer: false);
        setState(() {
          _current = shown;
          _face = face;
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
    if (!_canFlip) return;
    if (MediaQuery.disableAnimationsOf(context)) {
      setState(() {
        _showAnswer = !_showAnswer;
        if (_showAnswer) _answerSeen = true;
      });
      return;
    }
    _swappedThisTurn = false;
    _turn.forward(from: 0);
    // A real turn spends its first frames still animating. Rebuild now so
    // Wrong and Correct stay off until the status listener turns them back on.
    setState(() {});
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
    if (!_canSwipe) return;
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
      face: _face,
    );
    if (!mounted || generation != _generation) return;
    unawaited(HapticFeedback.selectionClick());
    _grades.add(stored);
    _replace(stored.result.after);
    await _selectNext(generation);
  }

  /// Pops the newest grade in this session and shows that card on the answer.
  /// Does not select a different card, replay the turn, or un-admit.
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
    _resetFace(answer: true);
    setState(() {
      _current = restored;
      _face = stored.result.review.face;
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
    final prompt = _face == StudyFace.reverse ? card.back : card.front;
    final answer = _face == StudyFace.reverse ? card.front : card.back;
    final side = _showAnswer ? answer : prompt;
    final spoken = _face == StudyFace.reverse ? 'Reverse. $side' : side;
    final borderColor = _showAnswer
        ? _answerSideColor
        : Theme.of(context).colorScheme.outline;
    final cardFace = GestureDetector(
      behavior: HitTestBehavior.opaque,
      onHorizontalDragStart: _onDragStart,
      onHorizontalDragUpdate: _onDragUpdate,
      onHorizontalDragEnd: _onDragEnd,
      child: Semantics(
        label: spoken,
        child: ExcludeSemantics(
          child: AnimatedBuilder(
            animation: _turn,
            builder: (context, child) {
              final t = _turn.value;
              var angle = t * math.pi;
              if (t >= 0.5) angle -= math.pi;
              return Transform(
                alignment: Alignment.center,
                transform: Matrix4.identity()
                  ..setEntry(3, 2, 0.001)
                  ..rotateY(angle),
                child: child,
              );
            },
            child: Card(
              key: const Key('card-face'),
              margin: EdgeInsets.zero,
              clipBehavior: Clip.antiAlias,
              shape: RoundedRectangleBorder(
                borderRadius: const BorderRadius.all(Radius.circular(12)),
                side: BorderSide(color: borderColor, width: 2),
              ),
              child: InkWell(
                onTap: _canFlip ? _flip : null,
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      if (_face == StudyFace.reverse)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: Text(
                            'Reverse',
                            key: const Key('reverse-label'),
                            textAlign: TextAlign.center,
                            style: Theme.of(context).textTheme.labelLarge,
                          ),
                        ),
                      Text(
                        side,
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                    ],
                  ),
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
                  onPressed: _canFlip ? _flip : null,
                  child: FilledButton.tonal(
                    key: const Key('flip-button'),
                    onPressed: _canFlip ? _flip : null,
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
