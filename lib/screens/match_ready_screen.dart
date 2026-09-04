// ignore_for_file: prefer_const_constructors_in_immutables

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../theme/interface_theme.dart';

class MatchReadyScreen extends StatelessWidget {
  MatchReadyScreen({required this.onStart, super.key});

  final void Function(BuildContext context) onStart;

  @override
  Widget build(BuildContext context) {
    final palette = InterfaceThemeScope.maybePaletteOf(context);
    return Scaffold(
      backgroundColor: palette.background,
      body: InterfaceSafeArea(
        child: Stack(
          children: [
            Padding(
              padding: EdgeInsets.all(32),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Ready to play?',
                    key: Key('match-ready-title'),
                    style: TextStyle(
                      color: palette.primary,
                      fontFamily: 'NotoSerifJP',
                      fontSize: 36,
                      fontWeight: FontWeight.w300,
                    ),
                  ),
                  SizedBox(height: 20),
                  Text(
                    'Match all the terms with their definitions as quickly as you can. '
                    'Avoid incorrect matches — they add extra time!',
                    style: TextStyle(
                      color: palette.primary.withValues(alpha: 0.66),
                      fontFamily: 'Figtree',
                      fontSize: 16,
                      fontWeight: FontWeight.w300,
                      height: 1.55,
                    ),
                  ),
                  SizedBox(height: 52),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      key: Key('start-match'),
                      onPressed: () => onStart(context),
                      style: FilledButton.styleFrom(
                        backgroundColor: palette.accent,
                        foregroundColor: palette.background,
                        padding: EdgeInsets.symmetric(vertical: 16),
                        textStyle: TextStyle(
                          fontFamily: 'Figtree',
                          fontSize: 16,
                        ),
                      ),
                      child: Text('Start game'),
                    ),
                  ),
                ],
              ),
            ),
            Positioned(
              left: 18,
              top: 12,
              child: IconButton(
                tooltip: 'Back to Recall',
                onPressed: () => Navigator.of(context).pop(),
                icon: Icon(
                  CupertinoIcons.back,
                  color: palette.primary,
                  size: 26,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
