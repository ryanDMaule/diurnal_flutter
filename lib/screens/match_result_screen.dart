// ignore_for_file: prefer_const_constructors_in_immutables

import 'package:flutter/material.dart';

import '../models/match_session.dart';
import '../services/match_service.dart';
import '../services/recall_progress_service.dart';
import '../theme/interface_theme.dart';
import 'match_session_screen.dart';

class MatchResultScreen extends StatefulWidget {
  MatchResultScreen({
    required this.completion,
    required this.previousSubjectIds,
    required this.matchService,
    required this.progressService,
    required this.onPlayAgain,
    required this.onFinished,
    super.key,
  });

  final MatchCompletion completion;
  final Set<String> previousSubjectIds;
  final MatchService matchService;
  final RecallProgressService progressService;
  final Future<MatchSession> Function(Set<String>) onPlayAgain;
  final Future<void> Function() onFinished;

  @override
  State<MatchResultScreen> createState() => _MatchResultScreenState();
}

class _MatchResultScreenState extends State<MatchResultScreen> {
  bool _isStarting = false;

  Future<void> _playAgain() async {
    if (_isStarting) return;
    setState(() => _isStarting = true);
    final session = await widget.onPlayAgain(widget.previousSubjectIds);
    if (!mounted) return;
    await Navigator.of(context).pushReplacement(
      MaterialPageRoute<void>(
        builder: (context) => MatchSessionScreen(
          session: session,
          matchService: widget.matchService,
          progressService: widget.progressService,
          onPlayAgain: widget.onPlayAgain,
          onFinished: widget.onFinished,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final palette = InterfaceThemeScope.maybePaletteOf(context);
    return Scaffold(
      backgroundColor: palette.background,
      body: InterfaceSafeArea(
        child: Padding(
          padding: EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'Match complete',
                key: Key('match-result-title'),
                style: TextStyle(
                  color: palette.primary,
                  fontFamily: 'NotoSerifJP',
                  fontSize: 31,
                ),
              ),
              SizedBox(height: 18),
              Text(
                formatMatchTime(widget.completion.elapsedMilliseconds),
                key: Key('match-result-time'),
                style: TextStyle(
                  color: palette.accent,
                  fontFamily: 'NotoSerifJP',
                  fontSize: 52,
                  fontWeight: FontWeight.w300,
                ),
              ),
              SizedBox(height: 14),
              Text(
                widget.completion.isNewBest
                    ? 'New personal best'
                    : 'Best · ${formatMatchTime(widget.completion.personalBestMilliseconds)}',
                key: Key('match-result-best'),
                style: TextStyle(
                  color: palette.primary.withValues(alpha: 0.58),
                  fontFamily: 'Figtree',
                  fontSize: 16,
                  fontWeight: FontWeight.w300,
                ),
              ),
              SizedBox(height: 46),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  key: Key('match-play-again'),
                  onPressed: _isStarting ? null : _playAgain,
                  style: FilledButton.styleFrom(
                    backgroundColor: palette.accent,
                    foregroundColor: palette.background,
                    padding: EdgeInsets.symmetric(vertical: 16),
                    textStyle: TextStyle(fontFamily: 'Figtree', fontSize: 16),
                  ),
                  child: _isStarting
                      ? SizedBox.square(
                          dimension: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: palette.background,
                          ),
                        )
                      : Text('Play again'),
                ),
              ),
              SizedBox(height: 12),
              TextButton(
                key: Key('finish-match'),
                onPressed: _isStarting
                    ? null
                    : () async {
                        await widget.onFinished();
                        if (context.mounted) Navigator.of(context).pop();
                      },
                style: TextButton.styleFrom(
                  foregroundColor: palette.primary.withValues(alpha: 0.68),
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
