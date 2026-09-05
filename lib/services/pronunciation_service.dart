import 'package:flutter_tts/flutter_tts.dart';

import '../models/pronunciation_voice.dart';

const pronunciationPreviewWord = 'Testing';

class PronunciationService {
  PronunciationService._();

  static final PronunciationService instance = PronunciationService._();

  final FlutterTts _tts = FlutterTts();
  List<PronunciationVoice>? _englishVoices;
  PronunciationVoice? _defaultEnglishVoice;

  Future<List<PronunciationVoice>> getEnglishVoices() async {
    final cached = _englishVoices;
    if (cached != null) return cached;
    try {
      await _tts.awaitSpeakCompletion(true);
      final rawVoices = await _tts.getVoices;
      final voices = <PronunciationVoice>[];
      if (rawVoices is List) {
        for (final rawVoice in rawVoices) {
          if (rawVoice is! Map) continue;
          final name = rawVoice['name']?.toString() ?? '';
          final locale =
              (rawVoice['locale'] ?? rawVoice['language'])?.toString() ?? '';
          if (name.isEmpty || !locale.toLowerCase().startsWith('en')) continue;
          final voice = PronunciationVoice(name: name, locale: locale);
          if (!voices.contains(voice)) voices.add(voice);
        }
      }
      voices.sort((a, b) {
        final localeOrder = a.locale.compareTo(b.locale);
        return localeOrder != 0 ? localeOrder : a.name.compareTo(b.name);
      });
      _englishVoices = List.unmodifiable(voices);
      await _discoverDefaultVoice(voices);
      return _englishVoices!;
    } catch (_) {
      _englishVoices = const [];
      return _englishVoices!;
    }
  }

  Future<void> _discoverDefaultVoice(List<PronunciationVoice> voices) async {
    try {
      final rawDefault = await _tts.getDefaultVoice;
      if (rawDefault is Map) {
        final name = rawDefault['name']?.toString() ?? '';
        final locale =
            (rawDefault['locale'] ?? rawDefault['language'])?.toString() ?? '';
        final candidate = PronunciationVoice(name: name, locale: locale);
        if (voices.contains(candidate)) _defaultEnglishVoice = candidate;
      }
    } catch (_) {
      // Not every platform/engine exposes a default voice.
    }
  }

  Future<PronunciationVoice?> resolveVoice(
    PronunciationVoice? preferred,
  ) async {
    final voices = await getEnglishVoices();
    if (preferred != null && voices.contains(preferred)) return preferred;
    return _defaultEnglishVoice ?? (voices.isEmpty ? null : voices.first);
  }

  Future<void> speak(String word, {PronunciationVoice? preferred}) async {
    if (word.trim().isEmpty) return;
    try {
      final voice = await resolveVoice(preferred);
      if (voice == null) return;
      await _tts.stop();
      await _tts.setVoice({'name': voice.name, 'locale': voice.locale});
      await _tts.speak(word);
    } catch (_) {
      // Pronunciation is optional and must not interrupt publication reading.
    }
  }

  Future<void> preview(PronunciationVoice voice) async {
    try {
      await _tts.stop();
      await _tts.setVoice({'name': voice.name, 'locale': voice.locale});
      await _tts.speak(pronunciationPreviewWord);
    } catch (_) {
      // A missing or temporarily unavailable system voice fails silently.
    }
  }

  Future<void> stop() async {
    try {
      await _tts.stop();
    } catch (_) {
      // TTS may already be unavailable or disposed by the platform.
    }
  }
}
