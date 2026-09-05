class PronunciationVoice {
  const PronunciationVoice({required this.name, required this.locale});

  final String name;
  final String locale;

  String get key => '$name|$locale';

  Map<String, String> toJson() => {'name': name, 'locale': locale};

  factory PronunciationVoice.fromJson(Map<String, dynamic> json) =>
      PronunciationVoice(
        name: json['name'] as String? ?? '',
        locale: json['locale'] as String? ?? '',
      );

  @override
  bool operator ==(Object other) =>
      other is PronunciationVoice && name == other.name && locale == other.locale;

  @override
  int get hashCode => Object.hash(name, locale);
}
