import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/daily_publication.dart';
import '../models/recall_question.dart';
import '../services/endless_recall_service.dart';
import '../services/recall_progress_service.dart';
import '../theme/colors.dart';
import 'endless_recall_result_screen.dart';

class EndlessRecallSessionScreen extends StatefulWidget {
  const EndlessRecallSessionScreen({
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
    unawaited(
      isCorrect
          ? HapticFeedback.selectionClick()
          : HapticFeedback.lightImpact(),
    );
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
      backgroundColor: AppColors.menuBackground,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
          child: Column(
            children: [
              Row(
                children: [
                  IconButton(
                    tooltip: 'Exit Endless Recall',
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(
                      CupertinoIcons.back,
                      color: AppColors.textPrimary,
                      size: 26,
                    ),
                  ),
                  Expanded(
                    child: Text(
                      '$_questionNumber'.padLeft(2, '0'),
                      key: const Key('endless-question-counter'),
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: AppColors.textPrimary.withValues(alpha: 0.75),
                        fontFamily: 'Figtree',
                        fontSize: 15,
                        fontWeight: FontWeight.w300,
                        letterSpacing: 1,
                      ),
                    ),
                  ),
                  const SizedBox(width: 48),
                ],
              ),
              const SizedBox(height: 50),
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        _question.content,
                        key: const Key('endless-question-content'),
                        style: TextStyle(
                          color: AppColors.textPrimary,
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
                      const SizedBox(height: 14),
                      Text(
                        _question.prompt,
                        style: TextStyle(
                          color: AppColors.textPrimary.withValues(alpha: 0.7),
                          fontFamily: 'Figtree',
                          fontSize: 16,
                          fontWeight: FontWeight.w300,
                          height: 1.4,
                        ),
                      ),
                      const SizedBox(height: 26),
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
                        const SizedBox(height: 12),
                      ],
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  key: const Key('endless-continue'),
                  onPressed: hasAnswered ? _continue : null,
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.textSecondary,
                    disabledBackgroundColor: AppColors.menuDivider.withValues(
                      alpha: 0.45,
                    ),
                    foregroundColor: AppColors.menuBackground,
                    disabledForegroundColor: AppColors.textPrimary.withValues(
                      alpha: 0.35,
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    textStyle: const TextStyle(
                      fontFamily: 'Figtree',
                      fontSize: 16,
                    ),
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
  const _EndlessAnswerChoice({
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
        duration: const Duration(milliseconds: 140),
        constraints: const BoxConstraints(minHeight: 66),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
        decoration: BoxDecoration(
          color: const Color(0xFF0B332A),
          borderRadius: BorderRadius.circular(9),
          border: Border.all(
            color: showCorrect
                ? correctColor
                : showIncorrect
                ? incorrectColor
                : AppColors.menuDivider,
            width: 1.4,
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                answer,
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontFamily: 'Figtree',
                  fontSize: 15,
                  fontWeight: FontWeight.w300,
                  height: 1.4,
                ),
              ),
            ),
            const SizedBox(width: 12),
            if (showCorrect)
              const Icon(
                CupertinoIcons.check_mark_circled_solid,
                key: Key('endless-correct-feedback'),
                color: correctColor,
                size: 22,
              )
            else if (showIncorrect)
              const Icon(
                CupertinoIcons.xmark_circle_fill,
                key: Key('endless-incorrect-feedback'),
                color: incorrectColor,
                size: 22,
              )
            else
              Icon(
                CupertinoIcons.circle,
                color: AppColors.textPrimary.withValues(alpha: 0.38),
                size: 20,
              ),
          ],
        ),
      ),
    );
  }
}
