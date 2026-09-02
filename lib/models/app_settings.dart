enum InterfaceAppearance { system, light, dark }

class AppSettings {
  const AppSettings({
    required this.soundEffectsEnabled,
    required this.reduceAnimations,
    required this.interfaceAppearance,
  });

  static const defaults = AppSettings(
    soundEffectsEnabled: true,
    reduceAnimations: false,
    interfaceAppearance: InterfaceAppearance.system,
  );

  final bool soundEffectsEnabled;
  final bool reduceAnimations;
  final InterfaceAppearance interfaceAppearance;

  AppSettings copyWith({
    bool? soundEffectsEnabled,
    bool? reduceAnimations,
    InterfaceAppearance? interfaceAppearance,
  }) => AppSettings(
    soundEffectsEnabled: soundEffectsEnabled ?? this.soundEffectsEnabled,
    reduceAnimations: reduceAnimations ?? this.reduceAnimations,
    interfaceAppearance: interfaceAppearance ?? this.interfaceAppearance,
  );

  Map<String, dynamic> toJson() => {
    'soundEffectsEnabled': soundEffectsEnabled,
    'reduceAnimations': reduceAnimations,
    'interfaceAppearance': interfaceAppearance.name,
  };

  factory AppSettings.fromJson(Map<String, dynamic> json) {
    final appearance = InterfaceAppearance.values.where(
      (value) => value.name == json['interfaceAppearance'],
    );
    return AppSettings(
      soundEffectsEnabled: json['soundEffectsEnabled'] is bool
          ? json['soundEffectsEnabled'] as bool
          : defaults.soundEffectsEnabled,
      reduceAnimations: json['reduceAnimations'] is bool
          ? json['reduceAnimations'] as bool
          : defaults.reduceAnimations,
      interfaceAppearance: appearance.isEmpty
          ? defaults.interfaceAppearance
          : appearance.first,
    );
  }
}
