import 'package:flutter/material.dart';

class Edition {
  const Edition({
    required this.id,
    required this.name,
    required this.description,
    required this.backgroundAsset,
    required this.usesLegacyTreatment,
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
  final String backgroundAsset;
  final bool usesLegacyTreatment;
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
  static const originalLibrary = Edition(
    id: 'original-library',
    name: 'Original Library',
    description: 'The original Diurnus library treatment',
    backgroundAsset: 'assets/images/background.png',
    usesLegacyTreatment: true,
    tintColor: Colors.transparent,
    tintOpacity: 0,
    gradientColors: [Colors.transparent, Colors.transparent],
    gradientStops: [0, 1],
    gradientBegin: Alignment.topCenter,
    gradientEnd: Alignment.bottomCenter,
    primaryTextColor: Color(0xFFD4D4D4),
    secondaryTextColor: Color(0xFFD4D4D4),
    mutedTextColor: Color(0x999D9D9D),
    accentColor: Color(0xFFC8A363),
    systemUiIconBrightness: Brightness.light,
  );

  static const library = Edition(
    id: 'library',
    name: 'Library',
    description: 'A deep, antique reading room',
    backgroundAsset: 'assets/images/default.png',
    usesLegacyTreatment: false,
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

  static const atrium = Edition(
    id: 'atrium',
    name: 'Atrium',
    description: 'Light, architectural and quietly warm',
    backgroundAsset: 'assets/images/library-white.png',
    usesLegacyTreatment: false,
    tintColor: Color(0xFFFFF2DD),
    tintOpacity: 0.22,
    gradientColors: [Color(0x10FFF7EA), Color(0xB8F0D7CF), Color(0xF5E8CDC5)],
    gradientStops: [0, 0.58, 1],
    gradientBegin: Alignment.topCenter,
    gradientEnd: Alignment.bottomCenter,
    primaryTextColor: Color(0xFF302B27),
    secondaryTextColor: Color(0xFF5C5048),
    mutedTextColor: Color(0xFF786C65),
    accentColor: Color(0xFFB85C5C),
    systemUiIconBrightness: Brightness.dark,
  );

  static const archive = Edition(
    id: 'archive',
    name: 'Archive',
    description: 'Warm stone, bronze and old histories',
    backgroundAsset: 'assets/images/bust.png',
    usesLegacyTreatment: false,
    tintColor: Color(0xFF5A321C),
    tintOpacity: 0.38,
    gradientColors: [Color(0x184A2B1C), Color(0xAA392317), Color(0xED1B120D)],
    gradientStops: [0, 0.55, 1],
    gradientBegin: Alignment.topCenter,
    gradientEnd: Alignment.bottomCenter,
    primaryTextColor: Color(0xFFEFE3D2),
    secondaryTextColor: Color(0xFFC7B7A3),
    mutedTextColor: Color(0xFF9F8F7F),
    accentColor: Color(0xFFA97842),
    systemUiIconBrightness: Brightness.light,
  );

  static const gallery = Edition(
    id: 'gallery',
    name: 'Gallery',
    description: 'Expressive colour with an editorial calm',
    backgroundAsset: 'assets/images/vibrant.png',
    usesLegacyTreatment: false,
    tintColor: Color(0xFF3B3C20),
    tintOpacity: 0.16,
    gradientColors: [Color(0x08343A25), Color(0x96333B20), Color(0xE9141C12)],
    gradientStops: [0, 0.52, 1],
    gradientBegin: Alignment.topCenter,
    gradientEnd: Alignment.bottomCenter,
    primaryTextColor: Color(0xFFF0E9D8),
    secondaryTextColor: Color(0xFFC9C3AC),
    mutedTextColor: Color(0xFFA2A08E),
    accentColor: Color(0xFFD8C66A),
    systemUiIconBrightness: Brightness.light,
  );

  static const midnight = Edition(
    id: 'midnight',
    name: 'Midnight',
    description: 'A quiet, celestial reading hour',
    backgroundAsset: 'assets/images/midnight.png',
    usesLegacyTreatment: false,
    tintColor: Color(0xFF07111F),
    tintOpacity: 0.32,
    gradientColors: [Color(0x12132438), Color(0xA5070D18), Color(0xF003070E)],
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
    originalLibrary,
    library,
    atrium,
    archive,
    gallery,
    midnight,
  ];

  static Edition fromId(String? id) => all.firstWhere(
    (edition) => edition.id == id,
    orElse: () => originalLibrary,
  );
}
