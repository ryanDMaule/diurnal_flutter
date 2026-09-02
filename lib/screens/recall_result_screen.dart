// ignore_for_file: prefer_const_constructors_in_immutables

import 'package:flutter/material.dart';

import '../models/recall_question.dart';
import '../services/recall_progress_service.dart';
import '../theme/interface_theme.dart';
import 'recall_session_screen.dart';

class RecallResultScreen extends StatefulWidget {
  RecallResultScreen({
    required this.correctAnswers,
    required this.questionCount,
    required this.previousSubjectIds,
    required this.progressService,
    required this.onRecallAgain,
    super.key,
  });

  final int correctAnswers;
  final int questionCount;
  final Set<String> previousSubjectIds;
  final RecallProgressService progressService;
  final RecallAgainCallback onRecallAgain;

  @override
  State<RecallResultScreen> createState() => _RecallResultScreenState();
}

class _RecallResultScreenState extends State<RecallResultScreen> {
  bool _isStartingAgain = false;
  bool _retryFailed = false;

  Future<void> _recallAgain() async {
    if (_isStartingAgain) return;
    setState(() {
      _isStartingAgain = true;
      _retryFailed = false;
    });
    try {
      final questions = await widget.onRecallAgain(widget.previousSubjectIds);
      if (!mounted) return;
      if (questions.isEmpty) throw StateError('No Recall questions available.');
      await Navigator.of(context).pushReplacement(
        MaterialPageRoute<void>(
          builder: (context) => RecallSessionScreen(
            questions: questions,
            progressService: widget.progressService,
            onRecallAgain: widget.onRecallAgain,
          ),
        ),
      );
    } catch (error) {
      debugPrint('Error restarting Recall: $error');
      if (mounted) {
        setState(() {
          _isStartingAgain = false;
          _retryFailed = true;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: InterfaceThemeScope.maybePaletteOf(context).background,
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                '${widget.correctAnswers} / ${widget.questionCount}',
                key: Key('recall-result-score'),
                style: TextStyle(
                  color: InterfaceThemeScope.maybePaletteOf(context).accent,
                  fontFamily: 'NotoSerifJP',
                  fontSize: 48,
                  fontWeight: FontWeight.w300,
                ),
              ),
              SizedBox(height: 22),
              Text(
                'Recall complete',
                style: TextStyle(
                  color: InterfaceThemeScope.maybePaletteOf(context).primary,
                  fontFamily: 'NotoSerifJP',
                  fontSize: 31,
                ),
              ),
              SizedBox(height: 12),
              Text(
                recallResultSummary(
                  widget.correctAnswers,
                  widget.questionCount,
                ),
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: InterfaceThemeScope.maybePaletteOf(
                    context,
                  ).primary.withValues(alpha: 0.58),
                  fontFamily: 'Figtree',
                  fontSize: 16,
                  fontWeight: FontWeight.w300,
                ),
              ),
              SizedBox(height: 46),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  key: Key('recall-again'),
                  onPressed: _isStartingAgain ? null : _recallAgain,
                  style: FilledButton.styleFrom(
                    backgroundColor: InterfaceThemeScope.maybePaletteOf(
                      context,
                    ).accent,
                    foregroundColor: InterfaceThemeScope.maybePaletteOf(
                      context,
                    ).background,
                    padding: EdgeInsets.symmetric(vertical: 16),
                    textStyle: TextStyle(fontFamily: 'Figtree', fontSize: 16),
                  ),
                  child: _isStartingAgain
                      ? SizedBox.square(
                          dimension: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: InterfaceThemeScope.maybePaletteOf(
                              context,
                            ).background,
                          ),
                        )
                      : Text('Recall again'),
                ),
              ),
              if (_retryFailed) ...[
                SizedBox(height: 10),
                Text(
                  'Unable to begin another session.',
                  style: TextStyle(
                    color: InterfaceThemeScope.maybePaletteOf(
                      context,
                    ).primary.withValues(alpha: 0.55),
                    fontFamily: 'Figtree',
                    fontSize: 13,
                  ),
                ),
              ],
              SizedBox(height: 12),
              TextButton(
                key: Key('finish-recall'),
                onPressed: _isStartingAgain
                    ? null
                    : () => Navigator.of(context).pop(),
                style: TextButton.styleFrom(
                  foregroundColor: InterfaceThemeScope.maybePaletteOf(
                    context,
                  ).primary.withValues(alpha: 0.68),
                  textStyle: TextStyle(
                    fontFamily: 'Figtree',
                    fontSize: 15,
                    fontWeight: FontWeight.w300,
                  ),
                ),
                child: Text('Finish'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

String recallResultSummary(int correctAnswers, int questionCount) {
  final toRevisit = questionCount - correctAnswers;
  if (correctAnswers == 0) return '$toRevisit to revisit';
  if (toRevisit == 0) return '$correctAnswers correct';
  return '$correctAnswers correct · $toRevisit to revisit';
}
