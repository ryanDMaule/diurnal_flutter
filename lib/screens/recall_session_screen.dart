// ignore_for_file: prefer_const_constructors_in_immutables

import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/recall_question.dart';
import '../services/recall_progress_service.dart';
import '../theme/interface_theme.dart';
import 'recall_result_screen.dart';

class RecallSessionScreen extends StatefulWidget {
  RecallSessionScreen({
    required this.questions,
    required this.progressService,
    required this.onRecallAgain,
    super.key,
  });

  final List<RecallQuestion> questions;
  final RecallProgressService progressService;
  final RecallAgainCallback onRecallAgain;

  @override
  State<RecallSessionScreen> createState() => _RecallSessionScreenState();
}

class _RecallSessionScreenState extends State<RecallSessionScreen> {
  int _questionIndex = 0;
  int _correctAnswers = 0;
  String? _selectedAnswer;

  RecallQuestion get _question => widget.questions[_questionIndex];

  Future<void> _selectAnswer(String answer) async {
    if (_selectedAnswer != null) return;
    final isCorrect = answer == _question.correctAnswer;
    setState(() {
      _selectedAnswer = answer;
      if (isCorrect) _correctAnswers++;
    });
    if (isCorrect) {
      unawaited(HapticFeedback.selectionClick());
    } else {
      unawaited(HapticFeedback.lightImpact());
    }
    try {
      await widget.progressService.recordAnswer(
        _question.subject.id!,
        wasCorrect: isCorrect,
      );
    } catch (error) {
      debugPrint('Error saving Recall progress: $error');
    }
  }

  Future<void> _continue() async {
    if (_selectedAnswer == null) return;
    if (_questionIndex < widget.questions.length - 1) {
      setState(() {
        _questionIndex++;
        _selectedAnswer = null;
      });
      return;
    }

    await Navigator.of(context).pushReplacement(
      MaterialPageRoute<void>(
        builder: (context) => RecallResultScreen(
          correctAnswers: _correctAnswers,
          questionCount: widget.questions.length,
          previousSubjectIds: widget.questions
              .map((question) => question.subject.id!)
              .toSet(),
          progressService: widget.progressService,
          onRecallAgain: widget.onRecallAgain,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final questionNumber = _questionIndex + 1;
    final total = widget.questions.length;
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
                    tooltip: 'Exit Recall',
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
                      '${questionNumber.toString().padLeft(2, '0')} / '
                      '${total.toString().padLeft(2, '0')}',
                      key: Key('recall-question-counter'),
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
              SizedBox(height: 12),
              TweenAnimationBuilder<double>(
                duration: MediaQuery.disableAnimationsOf(context)
                    ? Duration.zero
                    : Duration(milliseconds: 250),
                curve: Curves.easeInOut,
                tween: Tween(end: recallProgressValue(questionNumber, total)),
                builder: (context, value, child) => ClipRRect(
                  borderRadius: BorderRadius.circular(2),
                  child: LinearProgressIndicator(
                    key: Key('recall-progress'),
                    value: value,
                    minHeight: 4,
                    backgroundColor: InterfaceThemeScope.maybePaletteOf(
                      context,
                    ).divider.withValues(alpha: 0.5),
                    valueColor: AlwaysStoppedAnimation(
                      InterfaceThemeScope.maybePaletteOf(context).accent,
                    ),
                  ),
                ),
              ),
              SizedBox(height: 34),
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        _question.content,
                        key: Key('recall-question-content'),
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
                        _AnswerChoice(
                          key: Key('recall-answer-$index'),
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
                  key: Key('recall-continue'),
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
                  child: Text('Continue'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

double recallProgressValue(int questionNumber, int questionCount) =>
    questionNumber / questionCount;

class _AnswerChoice extends StatelessWidget {
  _AnswerChoice({
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
    final borderColor = showCorrect
        ? correctColor
        : showIncorrect
        ? incorrectColor
        : InterfaceThemeScope.maybePaletteOf(context).divider;

    return Semantics(
      button: true,
      selected: isSelected,
      child: InkWell(
        onTap: hasAnswered ? null : onTap,
        borderRadius: BorderRadius.circular(9),
        child: AnimatedContainer(
          duration: Duration(milliseconds: 140),
          constraints: BoxConstraints(minHeight: 66),
          padding: EdgeInsets.symmetric(horizontal: 18, vertical: 14),
          decoration: BoxDecoration(
            color: InterfaceThemeScope.maybePaletteOf(context).surface,
            borderRadius: BorderRadius.circular(9),
            border: Border.all(color: borderColor, width: 1.4),
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
              AnimatedSwitcher(
                duration: Duration(milliseconds: 140),
                child: showCorrect
                    ? Icon(
                        CupertinoIcons.check_mark_circled_solid,
                        key: Key('correct-feedback'),
                        color: correctColor,
                        size: 22,
                      )
                    : showIncorrect
                    ? Icon(
                        CupertinoIcons.xmark_circle_fill,
                        key: Key('incorrect-feedback'),
                        color: incorrectColor,
                        size: 22,
                      )
                    : Icon(
                        CupertinoIcons.circle,
                        color: InterfaceThemeScope.maybePaletteOf(
                          context,
                        ).primary.withValues(alpha: 0.38),
                        size: 20,
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
