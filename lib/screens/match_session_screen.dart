// ignore_for_file: prefer_const_constructors_in_immutables

import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../models/match_session.dart';
import '../services/haptic_service.dart';
import '../services/match_service.dart';
import '../services/recall_progress_service.dart';
import '../services/sound_effects_service.dart';
import '../theme/interface_theme.dart';
import '../theme/motion_preferences.dart';
import 'match_result_screen.dart';

class MatchSessionScreen extends StatefulWidget {
  MatchSessionScreen({
    required this.session,
    required this.matchService,
    required this.progressService,
    required this.onPlayAgain,
    required this.onFinished,
    this.elapsedTime,
    SoundEffectsService? soundEffectsService,
    super.key,
  }) : soundEffectsService =
           soundEffectsService ?? SoundEffectsService.instance;

  final MatchSession session;
  final MatchService matchService;
  final RecallProgressService progressService;
  final Future<MatchSession> Function(Set<String>) onPlayAgain;
  final Future<void> Function() onFinished;
  final MatchElapsedTime? elapsedTime;
  final SoundEffectsService soundEffectsService;

  @override
  State<MatchSessionScreen> createState() => _MatchSessionScreenState();
}

class _MatchSessionScreenState extends State<MatchSessionScreen> {
  static const _correctColor = Color(0xFF55B96A);
  static const _incorrectColor = Color(0xFFD65B52);
  final Stopwatch _stopwatch = Stopwatch();
  late final MatchElapsedTime _elapsedTime;
  Timer? _timer;
  String? _selectedId;
  Set<String> _feedbackIds = {};
  Set<String> _resolvedIds = {};
  bool _feedbackIsCorrect = false;
  bool _isResolving = false;
  String? _penaltyFeedbackCardId;
  int _penaltyFeedbackSequence = 0;
  bool _isCompleting = false;

  bool get _reduceAnimations => reduceAnimationsOf(context);

  bool get _hapticsEnabled =>
      InterfaceThemeScope.maybeControllerOf(
        context,
      )?.settings.hapticFeedbackEnabled ??
      true;

  double _cardExtent(BuildContext context, double gridWidth) {
    const crossAxisSpacing = 10.0;
    const horizontalCardPadding = 28.0;
    const verticalCardPadding = 28.0;
    final cardWidth = (gridWidth - crossAxisSpacing) / 2;
    final contentWidth = math.max(1.0, cardWidth - horizontalCardPadding);
    final textScaler = MediaQuery.textScalerOf(context);
    final textDirection = Directionality.of(context);
    var tallestText = 0.0;
    for (final card in widget.session.cards) {
      final painter = TextPainter(
        text: TextSpan(
          text: card.text,
          style: TextStyle(
            fontFamily: card.type == MatchCardType.word
                ? 'NotoSerifJP'
                : 'Figtree',
            fontSize: card.type == MatchCardType.word ? 19 : 13,
            fontWeight: FontWeight.w300,
            height: 1.35,
          ),
        ),
        textDirection: textDirection,
        textScaler: textScaler,
      )..layout(maxWidth: contentWidth);
      tallestText = math.max(tallestText, painter.height);
    }
    return math.max(140.0, tallestText + verticalCardPadding + 2);
  }

  @override
  void initState() {
    super.initState();
    _elapsedTime =
        widget.elapsedTime ??
        MatchElapsedTime(
          rawElapsedMilliseconds: () => _stopwatch.elapsedMilliseconds,
        );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _stopwatch.start();
      _timer = Timer.periodic(Duration(milliseconds: 100), (_) {
        if (mounted) setState(() {});
      });
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _stopwatch.stop();
    super.dispose();
  }

  Future<void> _tapCard(MatchCard card) async {
    if (_isResolving || _resolvedIds.contains(card.id)) return;
    final selectedId = _selectedId;
    if (selectedId == null) {
      setState(() => _selectedId = card.id);
      unawaited(widget.soundEffectsService.play(SoundEffect.matchCardSelected));
      return;
    }
    if (selectedId == card.id) {
      setState(() => _selectedId = null);
      return;
    }
    final selected = widget.session.cards.firstWhere(
      (candidate) => candidate.id == selectedId,
    );
    if (selected.type == card.type) {
      setState(() => _selectedId = card.id);
      return;
    }

    final isCorrect = selected.matches(card);
    final isFinalPair =
        isCorrect && _resolvedIds.length + 2 == widget.session.cards.length;
    if (!isCorrect) {
      _elapsedTime.addIncorrectMatchPenalty();
      _penaltyFeedbackSequence++;
      _penaltyFeedbackCardId = card.id;
      unawaited(_clearPenaltyFeedback(_penaltyFeedbackSequence));
    }
    setState(() {
      _isResolving = true;
      _feedbackIsCorrect = isCorrect;
      _feedbackIds = {selected.id, card.id};
    });
    if (isCorrect) {
      HapticService.success(enabled: _hapticsEnabled);
      if (!isFinalPair) {
        unawaited(widget.soundEffectsService.play(SoundEffect.answerCorrect));
      }
    } else {
      HapticService.error(enabled: _hapticsEnabled);
      unawaited(widget.soundEffectsService.play(SoundEffect.answerIncorrect));
    }
    if (isCorrect) {
      try {
        await widget.progressService.markRecalled(card.subjectId);
      } catch (error) {
        debugPrint('Error saving Match progress: $error');
      }
    }
    if (!_reduceAnimations) {
      await Future<void>.delayed(Duration(milliseconds: isCorrect ? 180 : 140));
    }
    if (!mounted) return;
    if (isCorrect) {
      _resolvedIds = {..._resolvedIds, selected.id, card.id};
    }
    setState(() {
      _selectedId = null;
      _feedbackIds = {};
      _isResolving = false;
    });
    if (isCorrect && _resolvedIds.length == widget.session.cards.length) {
      await _complete();
    }
  }

  Future<void> _clearPenaltyFeedback(int sequence) async {
    await Future<void>.delayed(
      Duration(milliseconds: _reduceAnimations ? 180 : 480),
    );
    if (!mounted || sequence != _penaltyFeedbackSequence) return;
    setState(() => _penaltyFeedbackCardId = null);
  }

  Future<void> _complete() async {
    if (_isCompleting) return;
    _isCompleting = true;
    _stopwatch.stop();
    _timer?.cancel();
    final elapsed = _elapsedTime.elapsedMilliseconds.clamp(1, 1 << 31);
    final completion = await widget.matchService.complete(elapsed);
    if (!mounted) return;
    HapticService.confirmation(enabled: _hapticsEnabled);
    unawaited(
      widget.soundEffectsService.play(
        completion.isNewBest
            ? SoundEffect.personalBest
            : SoundEffect.sessionCompleted,
      ),
    );
    await Navigator.of(context).pushReplacement(
      MaterialPageRoute<void>(
        builder: (context) => MatchResultScreen(
          completion: completion,
          previousSubjectIds: widget.session.subjectIds,
          matchService: widget.matchService,
          progressService: widget.progressService,
          onPlayAgain: widget.onPlayAgain,
          onFinished: widget.onFinished,
          soundEffectsService: widget.soundEffectsService,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final palette = InterfaceThemeScope.maybePaletteOf(context);
    final duration = _reduceAnimations
        ? Duration.zero
        : Duration(milliseconds: 140);
    return Scaffold(
      backgroundColor: palette.background,
      body: InterfaceSafeArea(
        child: Padding(
          padding: EdgeInsets.fromLTRB(18, 12, 18, 20),
          child: Column(
            children: [
              Row(
                children: [
                  IconButton(
                    tooltip: 'Exit Match',
                    onPressed: () => Navigator.of(context).pop(),
                    icon: Icon(
                      CupertinoIcons.back,
                      color: palette.primary,
                      size: 26,
                    ),
                  ),
                  Expanded(
                    child: Text(
                      'Match',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: palette.primary,
                        fontFamily: 'NotoSerifJP',
                        fontSize: 20,
                      ),
                    ),
                  ),
                  ConstrainedBox(
                    constraints: BoxConstraints(minWidth: 56),
                    child: Text(
                      formatMatchTimer(_elapsedTime.elapsedMilliseconds),
                      key: Key('match-timer'),
                      textAlign: TextAlign.right,
                      style: TextStyle(
                        color: palette.primary.withValues(alpha: 0.72),
                        fontFamily: 'Figtree',
                        fontSize: 14,
                        fontWeight: FontWeight.w300,
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 18),
              Expanded(
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final cardExtent = _cardExtent(
                      context,
                      constraints.maxWidth,
                    );
                    return GridView.builder(
                      key: Key('match-card-grid'),
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        crossAxisSpacing: 10,
                        mainAxisSpacing: 10,
                        mainAxisExtent: cardExtent,
                      ),
                      itemCount: widget.session.cards.length,
                      itemBuilder: (context, index) {
                        final card = widget.session.cards[index];
                        final isResolved = _resolvedIds.contains(card.id);
                        return AnimatedOpacity(
                          key: Key('match-card-${card.id}'),
                          duration: duration,
                          opacity: isResolved ? 0 : 1,
                          child: IgnorePointer(
                            ignoring: isResolved,
                            child: _MatchCardTile(
                              card: card,
                              isSelected: _selectedId == card.id,
                              feedback: _feedbackIds.contains(card.id)
                                  ? (_feedbackIsCorrect
                                        ? _MatchFeedback.correct
                                        : _MatchFeedback.incorrect)
                                  : _MatchFeedback.none,
                              duration: duration,
                              showPenalty: _penaltyFeedbackCardId == card.id,
                              penaltyFeedbackSequence: _penaltyFeedbackSequence,
                              reduceAnimations: _reduceAnimations,
                              onTap: () => _tapCard(card),
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

enum _MatchFeedback { none, correct, incorrect }

class _MatchCardTile extends StatelessWidget {
  const _MatchCardTile({
    required this.card,
    required this.isSelected,
    required this.feedback,
    required this.duration,
    required this.showPenalty,
    required this.penaltyFeedbackSequence,
    required this.reduceAnimations,
    required this.onTap,
  });

  final MatchCard card;
  final bool isSelected;
  final _MatchFeedback feedback;
  final Duration duration;
  final bool showPenalty;
  final int penaltyFeedbackSequence;
  final bool reduceAnimations;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final palette = InterfaceThemeScope.maybePaletteOf(context);
    final borderColor = switch (feedback) {
      _MatchFeedback.correct => _MatchSessionScreenState._correctColor,
      _MatchFeedback.incorrect => _MatchSessionScreenState._incorrectColor,
      _MatchFeedback.none when isSelected => palette.accent,
      _ => palette.divider,
    };
    return Stack(
      fit: StackFit.expand,
      clipBehavior: Clip.none,
      children: [
        Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            enableFeedback: false,
            borderRadius: BorderRadius.circular(9),
            child: AnimatedContainer(
              duration: duration,
              padding: EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: isSelected
                    ? palette.accent.withValues(alpha: 0.09)
                    : palette.surface,
                borderRadius: BorderRadius.circular(9),
                border: Border.all(color: borderColor, width: 1.2),
              ),
              alignment: card.type == MatchCardType.word
                  ? Alignment.center
                  : Alignment.centerLeft,
              child: Text(
                card.text,
                textAlign: card.type == MatchCardType.word
                    ? TextAlign.center
                    : TextAlign.left,
                style: TextStyle(
                  color: palette.primary,
                  fontFamily: card.type == MatchCardType.word
                      ? 'NotoSerifJP'
                      : 'Figtree',
                  fontSize: card.type == MatchCardType.word ? 19 : 13,
                  fontWeight: FontWeight.w300,
                  height: 1.35,
                ),
              ),
            ),
          ),
        ),
        if (showPenalty)
          Positioned(
            top: 8,
            right: 10,
            child: reduceAnimations
                ? _PenaltyLabel(key: Key('match-penalty-feedback'))
                : TweenAnimationBuilder<double>(
                    key: ValueKey('match-penalty-$penaltyFeedbackSequence'),
                    tween: Tween(begin: 0, end: 1),
                    duration: Duration(milliseconds: 460),
                    builder: (context, progress, child) => Opacity(
                      opacity: math.sin(math.pi * progress),
                      child: Transform.translate(
                        offset: Offset(0, -12 * progress),
                        child: child,
                      ),
                    ),
                    child: _PenaltyLabel(key: Key('match-penalty-feedback')),
                  ),
          ),
      ],
    );
  }
}

class _PenaltyLabel extends StatelessWidget {
  const _PenaltyLabel({super.key});

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Text(
        '+1 sec',
        style: TextStyle(
          color: _MatchSessionScreenState._incorrectColor,
          fontFamily: 'Figtree',
          fontSize: 12,
          fontWeight: FontWeight.w400,
        ),
      ),
    );
  }
}
