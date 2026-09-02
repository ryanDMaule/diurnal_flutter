import 'package:flutter/material.dart';

import '../theme/colors.dart';

class RecallResultScreen extends StatelessWidget {
  const RecallResultScreen({
    required this.correctAnswers,
    required this.questionCount,
    super.key,
  });

  final int correctAnswers;
  final int questionCount;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.menuBackground,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                '$correctAnswers / $questionCount',
                key: const Key('recall-result-score'),
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontFamily: 'NotoSerifJP',
                  fontSize: 48,
                  fontWeight: FontWeight.w300,
                ),
              ),
              const SizedBox(height: 22),
              const Text(
                'Recall complete',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontFamily: 'NotoSerifJP',
                  fontSize: 31,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'You remembered $correctAnswers of $questionCount words.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: AppColors.textPrimary.withValues(alpha: 0.58),
                  fontFamily: 'Figtree',
                  fontSize: 16,
                  fontWeight: FontWeight.w300,
                ),
              ),
              const SizedBox(height: 46),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  key: const Key('finish-recall'),
                  onPressed: () => Navigator.of(context).pop(),
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.textSecondary,
                    foregroundColor: AppColors.menuBackground,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    textStyle: const TextStyle(
                      fontFamily: 'Figtree',
                      fontSize: 16,
                    ),
                  ),
                  child: const Text('Finish'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
