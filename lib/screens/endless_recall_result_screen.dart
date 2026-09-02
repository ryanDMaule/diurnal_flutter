// ignore_for_file: prefer_const_constructors_in_immutables

import 'package:flutter/material.dart';

import '../models/daily_publication.dart';
import '../models/recall_question.dart';
import '../services/endless_recall_service.dart';
import '../services/recall_progress_service.dart';
import '../theme/interface_theme.dart';
import 'endless_recall_session_screen.dart';

class EndlessRecallResultScreen extends StatelessWidget {
  EndlessRecallResultScreen({
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
      backgroundColor: InterfaceThemeScope.maybePaletteOf(context).background,
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                '${result.score}',
                key: Key('endless-result-score'),
                style: TextStyle(
                  color: InterfaceThemeScope.maybePaletteOf(context).accent,
                  fontFamily: 'NotoSerifJP',
                  fontSize: 56,
                  fontWeight: FontWeight.w300,
                ),
              ),
              SizedBox(height: 22),
              Text(
                result.isNewBest ? 'New personal best' : 'Endless complete',
                key: Key('endless-result-title'),
                style: TextStyle(
                  color: InterfaceThemeScope.maybePaletteOf(context).primary,
                  fontFamily: 'NotoSerifJP',
                  fontSize: 31,
                ),
              ),
              if (!result.isNewBest && result.personalBest != null) ...[
                SizedBox(height: 12),
                Text(
                  'Personal best · ${result.personalBest}',
                  style: TextStyle(
                    color: InterfaceThemeScope.maybePaletteOf(
                      context,
                    ).primary.withValues(alpha: 0.58),
                    fontFamily: 'Figtree',
                    fontSize: 16,
                    fontWeight: FontWeight.w300,
                  ),
                ),
              ],
              SizedBox(height: 46),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  key: Key('endless-try-again'),
                  onPressed: () => _tryAgain(context),
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
                  child: Text('Try again'),
                ),
              ),
              SizedBox(height: 12),
              TextButton(
                key: Key('finish-endless'),
                onPressed: () async {
                  await onFinished();
                  if (context.mounted) Navigator.of(context).pop();
                },
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
