import 'package:flutter/material.dart';

import '../theme/colors.dart';

class Edition {
  const Edition({
    required this.id,
    required this.name,
    required this.description,
    this.backgroundAsset,
    this.backgroundColor = Colors.black,
    this.imageAlignment = Alignment.center,
    required this.tintColor,
    required this.tintOpacity,
    required this.gradientColors,
    required this.gradientStops,
    required this.gradientBegin,
    required this.gradientEnd,
    required this.primaryTextColor,
    required this.secondaryTextColor,
    required this.mutedTextColor,
    required this.accentColor,
    required this.systemUiIconBrightness,
  });

  final String id;
  final String name;
  final String description;
  final String? backgroundAsset;
  final Color backgroundColor;
  final AlignmentGeometry imageAlignment;
  final Color tintColor;
  final double tintOpacity;
  final List<Color> gradientColors;
  final List<double> gradientStops;
  final AlignmentGeometry gradientBegin;
  final AlignmentGeometry gradientEnd;
  final Color primaryTextColor;
  final Color secondaryTextColor;
  final Color mutedTextColor;
  final Color accentColor;
  final Brightness systemUiIconBrightness;
}

abstract final class Editions {
  static const library = Edition(
    id: 'library',
    name: 'Library',
    description: 'A deep, antique reading room',
    backgroundAsset: 'assets/images/default.png',
    tintColor: Color(0xFF000000),
    tintOpacity: 0.48,
    gradientColors: [Color(0x10000000), Color(0xB5000000), Color(0xF2000000)],
    gradientStops: [0, 0.55, 1],
    gradientBegin: Alignment.topCenter,
    gradientEnd: Alignment.bottomCenter,
    primaryTextColor: Color(0xFFE7E0D4),
    secondaryTextColor: Color(0xFFD2C7B5),
    mutedTextColor: Color(0xFF9E988E),
    accentColor: Color(0xFFC49A52),
    systemUiIconBrightness: Brightness.light,
  );

  static const evergreen = Edition(
    id: 'evergreen',
    name: 'Theme',
    description: 'Uses your selected Diurnus colour',
    backgroundColor: AppColors.menuBackground,
    tintColor: Colors.transparent,
    tintOpacity: 0,
    gradientColors: [],
    gradientStops: [],
    gradientBegin: Alignment.topCenter,
    gradientEnd: Alignment.bottomCenter,
    primaryTextColor: Color(0xFFF3EBDD),
    secondaryTextColor: Color(0xFFCFC7B8),
    mutedTextColor: Color(0xFF9AA89F),
    accentColor: AppColors.textSecondary,
    systemUiIconBrightness: Brightness.light,
  );

  static const atrium = Edition(
    id: 'atrium',
    name: 'Atrium',
    description: 'Light, architectural and quietly warm',
    backgroundAsset: 'assets/images/library-white.png',
    tintColor: Color(0xFFFFF2DD),
    tintOpacity: 0.22,
    gradientColors: [Color(0x10FFF7EA), Color(0xB8F0D7CF), Color(0xFFE8CDC5)],
    gradientStops: [0, 0.58, 1],
    gradientBegin: Alignment.topCenter,
    gradientEnd: Alignment.bottomCenter,
    primaryTextColor: Color(0xFF302B27),
    secondaryTextColor: Color(0xFF5C5048),
    mutedTextColor: Color(0xFF786C65),
    accentColor: Color(0xFFB85C5C),
    systemUiIconBrightness: Brightness.dark,
  );

  static const foundry = Edition(
    id: 'foundry',
    name: 'Foundry',
    description: 'Cold structure and industrial quiet',
    backgroundAsset: 'assets/images/abstract.png',
    tintColor: Color(0xFF000000),
    tintOpacity: 0.20,
    gradientColors: [
      Color(0x000A0E10),
      Color(0x120A0E10),
      Color(0xA60A0E10),
      Color(0xFF0A0E10),
    ],
    gradientStops: [0, 0.35, 0.65, 1],
    gradientBegin: Alignment.topCenter,
    gradientEnd: Alignment.bottomCenter,
    primaryTextColor: Color(0xFFF3EBDD),
    secondaryTextColor: Color(0xFFCED8DB),
    mutedTextColor: Color(0xFF8E9CA1),
    accentColor: Color(0xFFB9C9CF),
    systemUiIconBrightness: Brightness.light,
  );

  static const ascent = Edition(
    id: 'ascent',
    name: 'Ascent',
    description: 'A forbidden library in deep shadow',
    backgroundAsset: 'assets/images/ascent.png',
    tintColor: Color(0xFF000000),
    tintOpacity: 0.38,
    gradientColors: [Color(0x10000000), Color(0xB5000000), Color(0xFF000000)],
    gradientStops: [0, 0.55, 1],
    gradientBegin: Alignment.topCenter,
    gradientEnd: Alignment.bottomCenter,
    primaryTextColor: Color(0xFFF3EBDD),
    secondaryTextColor: Color(0xFFD2C3C0),
    mutedTextColor: Color(0xFF9A8583),
    accentColor: Color(0xFFB8B5AD),
    systemUiIconBrightness: Brightness.light,
  );

  static const hearth = Edition(
    id: 'hearth',
    name: 'Hearth',
    description: 'Warm shelves, plants and lived-in comfort',
    backgroundAsset: 'assets/images/cosy.png',
    tintColor: Color(0xFF000000),
    tintOpacity: 0.16,
    gradientColors: [Color(0x0818130F), Color(0x6618130F), Color(0xFF18130F)],
    gradientStops: [0, 0.55, 1],
    gradientBegin: Alignment.topCenter,
    gradientEnd: Alignment.bottomCenter,
    primaryTextColor: Color(0xFFF3EBDD),
    secondaryTextColor: Color(0xFFDDC9B9),
    mutedTextColor: Color(0xFFA99584),
    accentColor: Color(0xFFC97863),
    systemUiIconBrightness: Brightness.light,
  );

  static const reverie = Edition(
    id: 'reverie',
    name: 'Reverie',
    description: 'Romantic light and storybook ornament',
    backgroundAsset: 'assets/images/dream.png',
    tintColor: Color(0xFF000000),
    tintOpacity: 0.16,
    gradientColors: [Color(0x08151719), Color(0x66151719), Color(0xFF151719)],
    gradientStops: [0, 0.55, 1],
    gradientBegin: Alignment.topCenter,
    gradientEnd: Alignment.bottomCenter,
    primaryTextColor: Color(0xFFF3EBDD),
    secondaryTextColor: Color(0xFFE1D2BC),
    mutedTextColor: Color(0xFFAFA08B),
    accentColor: Color(0xFFC9B98D),
    systemUiIconBrightness: Brightness.light,
  );

  static const monolith = Edition(
    id: 'monolith',
    name: 'Monolith',
    description: 'Monumental architecture and soaring scale',
    backgroundAsset: 'assets/images/monolith.png',
    imageAlignment: Alignment.topCenter,
    tintColor: Color(0xFF000000),
    tintOpacity: 0.18,
    gradientColors: [
      Color(0x000E0D0B),
      Color(0x0D0E0D0B),
      Color(0x800E0D0B),
      Color(0xFF0E0D0B),
    ],
    gradientStops: [0, 0.45, 0.68, 1],
    gradientBegin: Alignment.topCenter,
    gradientEnd: Alignment.bottomCenter,
    primaryTextColor: Color(0xFFF3EBDD),
    secondaryTextColor: Color(0xFFD8C5AE),
    mutedTextColor: Color(0xFFA28B75),
    accentColor: Color(0xFFD19A55),
    systemUiIconBrightness: Brightness.light,
  );

  static const oak = Edition(
    id: 'oak',
    name: 'Oak',
    description: 'Aged books and traditional scholarship',
    backgroundAsset: 'assets/images/oak.png',
    tintColor: Color(0xFF000000),
    tintOpacity: 0.20,
    gradientColors: [
      Color(0x00160F0A),
      Color(0x0D160F0A),
      Color(0x8C160F0A),
      Color(0xFF160F0A),
    ],
    gradientStops: [0, 0.45, 0.68, 1],
    gradientBegin: Alignment.topCenter,
    gradientEnd: Alignment.bottomCenter,
    primaryTextColor: Color(0xFFF3EBDD),
    secondaryTextColor: Color(0xFFD6C2AA),
    mutedTextColor: Color(0xFF9E8973),
    accentColor: Color(0xFFB88A51),
    systemUiIconBrightness: Brightness.light,
  );

  static const gilded = Edition(
    id: 'gilded',
    name: 'Gilded',
    description: 'Historic ornament and quiet opulence',
    backgroundAsset: 'assets/images/ornate.png',
    tintColor: Color(0xFF000000),
    tintOpacity: 0.18,
    gradientColors: [
      Color(0x0014110E),
      Color(0x0A14110E),
      Color(0x7A14110E),
      Color(0xFF14110E),
    ],
    gradientStops: [0, 0.48, 0.7, 1],
    gradientBegin: Alignment.topCenter,
    gradientEnd: Alignment.bottomCenter,
    primaryTextColor: Color(0xFFF3EBDD),
    secondaryTextColor: Color(0xFFD9C8B1),
    mutedTextColor: Color(0xFFA28E79),
    accentColor: Color(0xFFC9A65F),
    systemUiIconBrightness: Brightness.light,
  );

  static const palindrome = Edition(
    id: 'palindrome',
    name: 'Palindrome',
    description: 'Symmetry, mystery and scholarly calm',
    backgroundAsset: 'assets/images/palindrome.png',
    tintColor: Color(0xFF000000),
    tintOpacity: 0.24,
    gradientColors: [Color(0x0A120E0B), Color(0x80120E0B), Color(0xFF120E0B)],
    gradientStops: [0, 0.55, 1],
    gradientBegin: Alignment.topCenter,
    gradientEnd: Alignment.bottomCenter,
    primaryTextColor: Color(0xFFF3EBDD),
    secondaryTextColor: Color(0xFFD4C2AF),
    mutedTextColor: Color(0xFF9B8878),
    accentColor: Color(0xFFB88756),
    systemUiIconBrightness: Brightness.light,
  );

  static const midnight = Edition(
    id: 'midnight',
    name: 'Midnight',
    description: 'A quiet, celestial reading hour',
    backgroundAsset: 'assets/images/midnight.png',
    tintColor: Color(0xFF07111F),
    tintOpacity: 0.32,
    gradientColors: [Color(0x12132438), Color(0xA5070D18), Color(0xFF03070E)],
    gradientStops: [0, 0.56, 1],
    gradientBegin: Alignment.topCenter,
    gradientEnd: Alignment.bottomCenter,
    primaryTextColor: Color(0xFFE2E7ED),
    secondaryTextColor: Color(0xFFB5C0CA),
    mutedTextColor: Color(0xFF87939F),
    accentColor: Color(0xFF6F8FAF),
    systemUiIconBrightness: Brightness.light,
  );

  static const all = [
    library,
    evergreen,
    midnight,
    atrium,
    foundry,
    ascent,
    hearth,
    reverie,
    monolith,
    oak,
    gilded,
    palindrome,
  ];

  static Edition fromId(String? id) =>
      all.firstWhere((edition) => edition.id == id, orElse: () => library);
}
