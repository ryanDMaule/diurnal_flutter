enum InterfaceColor { evergreen, charcoal, navy, oxblood, paper }

class AppSettings {
  const AppSettings({
    required this.soundEffectsEnabled,
    required this.reduceAnimations,
    required this.interfaceColor,
  });

  static const defaults = AppSettings(
    soundEffectsEnabled: true,
    reduceAnimations: false,
    interfaceColor: InterfaceColor.evergreen,
  );

  final bool soundEffectsEnabled;
  final bool reduceAnimations;
  final InterfaceColor interfaceColor;

  AppSettings copyWith({
    bool? soundEffectsEnabled,
    bool? reduceAnimations,
    InterfaceColor? interfaceColor,
  }) => AppSettings(
    soundEffectsEnabled: soundEffectsEnabled ?? this.soundEffectsEnabled,
    reduceAnimations: reduceAnimations ?? this.reduceAnimations,
    interfaceColor: interfaceColor ?? this.interfaceColor,
  );

  Map<String, dynamic> toJson() => {
    'soundEffectsEnabled': soundEffectsEnabled,
    'reduceAnimations': reduceAnimations,
    'interfaceColor': interfaceColor.name,
  };

  factory AppSettings.fromJson(Map<String, dynamic> json) {
    final storedColor = InterfaceColor.values.where(
      (value) => value.name == json['interfaceColor'],
    );
    final legacyColor = switch (json['interfaceAppearance']) {
      'light' => InterfaceColor.paper,
      'dark' || 'system' => InterfaceColor.evergreen,
      _ => defaults.interfaceColor,
    };
    return AppSettings(
      soundEffectsEnabled: json['soundEffectsEnabled'] is bool
          ? json['soundEffectsEnabled'] as bool
          : defaults.soundEffectsEnabled,
      reduceAnimations: json['reduceAnimations'] is bool
          ? json['reduceAnimations'] as bool
          : defaults.reduceAnimations,
      interfaceColor: storedColor.isEmpty ? legacyColor : storedColor.first,
    );
  }
}
