// ignore_for_file: prefer_const_constructors_in_immutables

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../models/daily_publication.dart';
import '../models/recall_question.dart';
import '../services/endless_recall_service.dart';
import '../services/haptic_service.dart';
import '../services/recall_progress_service.dart';
import '../theme/interface_theme.dart';
import 'endless_recall_result_screen.dart';

class EndlessRecallSessionScreen extends StatefulWidget {
  EndlessRecallSessionScreen({
    required this.archive,
    required this.generator,
    required this.progressService,
    required this.endlessService,
    required this.onFinished,
    super.key,
  });

  final List<DailyPublication> archive;
  final RecallSessionGenerator generator;
  final RecallProgressService progressService;
  final EndlessRecallService endlessService;
  final Future<void> Function() onFinished;

  @override
  State<EndlessRecallSessionScreen> createState() =>
      _EndlessRecallSessionScreenState();
}

class _EndlessRecallSessionScreenState
    extends State<EndlessRecallSessionScreen> {
  late final EndlessRecallQuestionCycle _cycle;
  late RecallQuestion _question;
  int _score = 0;
  int _questionNumber = 1;
  String? _selectedAnswer;
  bool _answerWasCorrect = false;

  @override
  void initState() {
    super.initState();
    _cycle = EndlessRecallQuestionCycle(
      publications: widget.archive,
      generator: widget.generator,
    );
    _question = _cycle.next()!;
  }

  Future<void> _selectAnswer(String answer) async {
    if (_selectedAnswer != null) return;
    final isCorrect = answer == _question.correctAnswer;
    setState(() {
      _selectedAnswer = answer;
      _answerWasCorrect = isCorrect;
      if (isCorrect) _score++;
    });
    final hapticsEnabled =
        InterfaceThemeScope.maybeControllerOf(
          context,
        )?.settings.hapticFeedbackEnabled ??
        true;
    if (isCorrect) {
      HapticService.success(enabled: hapticsEnabled);
    } else {
      HapticService.error(enabled: hapticsEnabled);
    }
    try {
      await widget.progressService.recordAnswer(
        _question.subject.id!,
        wasCorrect: isCorrect,
      );
    } catch (error) {
      debugPrint('Error saving Endless Recall progress: $error');
    }
  }

  Future<void> _continue() async {
    if (_selectedAnswer == null) return;
    if (_answerWasCorrect) {
      final nextQuestion = _cycle.next();
      if (nextQuestion == null) return;
      setState(() {
        _question = nextQuestion;
        _questionNumber++;
        _selectedAnswer = null;
        _answerWasCorrect = false;
      });
      return;
    }

    final result = await widget.endlessService.completeRun(_score);
    if (!mounted) return;
    await Navigator.of(context).pushReplacement(
      MaterialPageRoute<void>(
        builder: (context) => EndlessRecallResultScreen(
          result: result,
          archive: widget.archive,
          generator: widget.generator,
          progressService: widget.progressService,
          endlessService: widget.endlessService,
          onFinished: widget.onFinished,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final hasAnswered = _selectedAnswer != null;
    return Scaffold(
      backgroundColor: InterfaceThemeScope.maybePaletteOf(context).background,
      body: InterfaceSafeArea(
        child: Padding(
          padding: EdgeInsets.fromLTRB(24, 16, 24, 24),
          child: Column(
            children: [
              Row(
                children: [
                  IconButton(
                    tooltip: 'Exit Endless Recall',
                    onPressed: () => Navigator.of(context).pop(),
                    icon: Icon(
                      CupertinoIcons.back,
                      color: InterfaceThemeScope.maybePaletteOf(
                        context,
                      ).primary,
                      size: 26,
                    ),
                  ),
                  Expanded(
                    child: Text(
                      '$_questionNumber'.padLeft(2, '0'),
                      key: Key('endless-question-counter'),
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: InterfaceThemeScope.maybePaletteOf(
                          context,
                        ).primary.withValues(alpha: 0.75),
                        fontFamily: 'Figtree',
                        fontSize: 15,
                        fontWeight: FontWeight.w300,
                        letterSpacing: 1,
                      ),
                    ),
                  ),
                  SizedBox(width: 48),
                ],
              ),
              SizedBox(height: 50),
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        _question.content,
                        key: Key('endless-question-content'),
                        style: TextStyle(
                          color: InterfaceThemeScope.maybePaletteOf(
                            context,
                          ).primary,
                          fontFamily: 'NotoSerifJP',
                          fontSize:
                              _question.type ==
                                  RecallQuestionType.definitionToWord
                              ? 24
                              : 36,
                          fontWeight: FontWeight.w300,
                          height: 1.35,
                        ),
                      ),
                      SizedBox(height: 14),
                      Text(
                        _question.prompt,
                        style: TextStyle(
                          color: InterfaceThemeScope.maybePaletteOf(
                            context,
                          ).primary.withValues(alpha: 0.7),
                          fontFamily: 'Figtree',
                          fontSize: 16,
                          fontWeight: FontWeight.w300,
                          height: 1.4,
                        ),
                      ),
                      SizedBox(height: 26),
                      for (
                        var index = 0;
                        index < _question.answers.length;
                        index++
                      ) ...[
                        _EndlessAnswerChoice(
                          key: Key('endless-answer-$index'),
                          answer: _question.answers[index],
                          isSelected:
                              _selectedAnswer == _question.answers[index],
                          isCorrect:
                              _question.answers[index] ==
                              _question.correctAnswer,
                          hasAnswered: hasAnswered,
                          onTap: () => _selectAnswer(_question.answers[index]),
                        ),
                        SizedBox(height: 12),
                      ],
                    ],
                  ),
                ),
              ),
              SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  key: Key('endless-continue'),
                  onPressed: hasAnswered ? _continue : null,
                  style: FilledButton.styleFrom(
                    backgroundColor: InterfaceThemeScope.maybePaletteOf(
                      context,
                    ).accent,
                    disabledBackgroundColor: InterfaceThemeScope.maybePaletteOf(
                      context,
                    ).divider.withValues(alpha: 0.45),
                    foregroundColor: InterfaceThemeScope.maybePaletteOf(
                      context,
                    ).background,
                    disabledForegroundColor: InterfaceThemeScope.maybePaletteOf(
                      context,
                    ).primary.withValues(alpha: 0.35),
                    padding: EdgeInsets.symmetric(vertical: 16),
                    textStyle: TextStyle(fontFamily: 'Figtree', fontSize: 16),
                  ),
                  child: Text(
                    hasAnswered && !_answerWasCorrect
                        ? 'Finish run'
                        : 'Continue',
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EndlessAnswerChoice extends StatelessWidget {
  _EndlessAnswerChoice({
    required this.answer,
    required this.isSelected,
    required this.isCorrect,
    required this.hasAnswered,
    required this.onTap,
    super.key,
  });

  static const correctColor = Color(0xFF55B96A);
  static const incorrectColor = Color(0xFFD65B52);
  final String answer;
  final bool isSelected;
  final bool isCorrect;
  final bool hasAnswered;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final showCorrect = hasAnswered && isCorrect;
    final showIncorrect = hasAnswered && isSelected && !isCorrect;
    return InkWell(
      onTap: hasAnswered ? null : onTap,
      borderRadius: BorderRadius.circular(9),
      child: AnimatedContainer(
        duration: Duration(milliseconds: 140),
        constraints: BoxConstraints(minHeight: 66),
        padding: EdgeInsets.symmetric(horizontal: 18, vertical: 14),
        decoration: BoxDecoration(
          color: InterfaceThemeScope.maybePaletteOf(context).surface,
          borderRadius: BorderRadius.circular(9),
          border: Border.all(
            color: showCorrect
                ? correctColor
                : showIncorrect
                ? incorrectColor
                : InterfaceThemeScope.maybePaletteOf(context).divider,
            width: 1.4,
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                answer,
                style: TextStyle(
                  color: InterfaceThemeScope.maybePaletteOf(context).primary,
                  fontFamily: 'Figtree',
                  fontSize: 15,
                  fontWeight: FontWeight.w300,
                  height: 1.4,
                ),
              ),
            ),
            SizedBox(width: 12),
            if (showCorrect)
              Icon(
                CupertinoIcons.check_mark_circled_solid,
                key: Key('endless-correct-feedback'),
                color: correctColor,
                size: 22,
              )
            else if (showIncorrect)
              Icon(
                CupertinoIcons.xmark_circle_fill,
                key: Key('endless-incorrect-feedback'),
                color: incorrectColor,
                size: 22,
              )
            else
              Icon(
                CupertinoIcons.circle,
                color: InterfaceThemeScope.maybePaletteOf(
                  context,
                ).primary.withValues(alpha: 0.38),
                size: 20,
              ),
          ],
        ),
      ),
    );
  }
}
