// ignore_for_file: prefer_const_constructors_in_immutables

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../theme/interface_theme.dart';

class PlaceholderScreen extends StatelessWidget {
  PlaceholderScreen({required this.title, super.key});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: InterfaceThemeScope.maybePaletteOf(context).background,
      body: SafeArea(
        child: Stack(
          children: [
            Positioned(
              top: 4,
              left: 8,
              child: IconButton(
                tooltip: 'Back',
                onPressed: () => Navigator.of(context).pop(),
                icon: Icon(
                  CupertinoIcons.back,
                  color: InterfaceThemeScope.maybePaletteOf(context).primary,
                  size: 26,
                ),
              ),
            ),
            Center(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 32),
                child: Text(
                  title,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: InterfaceThemeScope.maybePaletteOf(context).primary,
                    fontFamily: 'NotoSerifJP',
                    fontSize: 34,
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
