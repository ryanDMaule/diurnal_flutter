import 'pronunciation_voice.dart';

enum InterfaceColor { evergreen, charcoal, navy, oxblood, paper }

class AppSettings {
  const AppSettings({
    required this.soundEffectsEnabled,
    this.hapticFeedbackEnabled = true,
    required this.reduceAnimations,
    required this.interfaceColor,
    required this.textureEnabled,
    this.pronunciationVoice,
  });

  static const defaults = AppSettings(
    soundEffectsEnabled: true,
    hapticFeedbackEnabled: true,
    reduceAnimations: false,
    interfaceColor: InterfaceColor.evergreen,
    textureEnabled: true,
  );

  final bool soundEffectsEnabled;
  final bool hapticFeedbackEnabled;
  final bool reduceAnimations;
  final InterfaceColor interfaceColor;
  final bool textureEnabled;
  final PronunciationVoice? pronunciationVoice;

  AppSettings copyWith({
    bool? soundEffectsEnabled,
    bool? hapticFeedbackEnabled,
    bool? reduceAnimations,
    InterfaceColor? interfaceColor,
    bool? textureEnabled,
    PronunciationVoice? pronunciationVoice,
  }) => AppSettings(
    soundEffectsEnabled: soundEffectsEnabled ?? this.soundEffectsEnabled,
    hapticFeedbackEnabled:
        hapticFeedbackEnabled ?? this.hapticFeedbackEnabled,
    reduceAnimations: reduceAnimations ?? this.reduceAnimations,
    interfaceColor: interfaceColor ?? this.interfaceColor,
    textureEnabled: textureEnabled ?? this.textureEnabled,
    pronunciationVoice: pronunciationVoice ?? this.pronunciationVoice,
  );

  Map<String, dynamic> toJson() => {
    'soundEffectsEnabled': soundEffectsEnabled,
    'hapticFeedbackEnabled': hapticFeedbackEnabled,
    'reduceAnimations': reduceAnimations,
    'interfaceColor': interfaceColor.name,
    'textureEnabled': textureEnabled,
    'pronunciationVoice': pronunciationVoice?.toJson(),
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
      hapticFeedbackEnabled: json['hapticFeedbackEnabled'] is bool
          ? json['hapticFeedbackEnabled'] as bool
          : defaults.hapticFeedbackEnabled,
      reduceAnimations: json['reduceAnimations'] is bool
          ? json['reduceAnimations'] as bool
          : defaults.reduceAnimations,
      interfaceColor: storedColor.isEmpty ? legacyColor : storedColor.first,
      textureEnabled: json['textureEnabled'] is bool
          ? json['textureEnabled'] as bool
          : defaults.textureEnabled,
      pronunciationVoice: json['pronunciationVoice'] is Map
          ? PronunciationVoice.fromJson(
              Map<String, dynamic>.from(json['pronunciationVoice'] as Map),
            )
          : null,
    );
  }
}
