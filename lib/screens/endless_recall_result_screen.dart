import 'package:flutter/material.dart';

import '../models/daily_publication.dart';
import '../models/recall_question.dart';
import '../services/endless_recall_service.dart';
import '../services/recall_progress_service.dart';
import '../theme/colors.dart';
import 'endless_recall_session_screen.dart';

class EndlessRecallResultScreen extends StatelessWidget {
  const EndlessRecallResultScreen({
    required this.result,
    required this.archive,
    required this.generator,
    required this.progressService,
    required this.endlessService,
    required this.onFinished,
    super.key,
  });

  final EndlessRecallResult result;
  final List<DailyPublication> archive;
  final RecallSessionGenerator generator;
  final RecallProgressService progressService;
  final EndlessRecallService endlessService;
  final Future<void> Function() onFinished;

  void _tryAgain(BuildContext context) {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute<void>(
        builder: (context) => EndlessRecallSessionScreen(
          archive: archive,
          generator: generator,
          progressService: progressService,
          endlessService: endlessService,
          onFinished: onFinished,
        ),
      ),
    );
  }

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
                '${result.score}',
                key: const Key('endless-result-score'),
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontFamily: 'NotoSerifJP',
                  fontSize: 56,
                  fontWeight: FontWeight.w300,
                ),
              ),
              const SizedBox(height: 22),
              Text(
                result.isNewBest ? 'New personal best' : 'Endless complete',
                key: const Key('endless-result-title'),
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontFamily: 'NotoSerifJP',
                  fontSize: 31,
                ),
              ),
              if (!result.isNewBest && result.personalBest != null) ...[
                const SizedBox(height: 12),
                Text(
                  'Personal best · ${result.personalBest}',
                  style: TextStyle(
                    color: AppColors.textPrimary.withValues(alpha: 0.58),
                    fontFamily: 'Figtree',
                    fontSize: 16,
                    fontWeight: FontWeight.w300,
                  ),
                ),
              ],
              const SizedBox(height: 46),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  key: const Key('endless-try-again'),
                  onPressed: () => _tryAgain(context),
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.textSecondary,
                    foregroundColor: AppColors.menuBackground,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    textStyle: const TextStyle(
                      fontFamily: 'Figtree',
                      fontSize: 16,
                    ),
                  ),
                  child: const Text('Try again'),
                ),
              ),
              const SizedBox(height: 12),
              TextButton(
                key: const Key('finish-endless'),
                onPressed: () async {
                  await onFinished();
                  if (context.mounted) Navigator.of(context).pop();
                },
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.textPrimary.withValues(
                    alpha: 0.68,
                  ),
                  textStyle: const TextStyle(
                    fontFamily: 'Figtree',
                    fontSize: 15,
                    fontWeight: FontWeight.w300,
                  ),
                ),
                child: const Text('Finish'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
