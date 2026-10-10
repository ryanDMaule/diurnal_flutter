import 'package:flutter_test/flutter_test.dart';

import 'package:diurnul/services/sound_effects_service.dart';

import 'support/fake_sound_effects.dart';

void main() {
  test('maps every semantic event to its selected asset and volume', () {
    expect(
      SoundEffectsService.specs,
      containsPair(
        SoundEffect.bookmarkSaved,
        isA<SoundEffectSpec>()
            .having((spec) => spec.assetPath, 'asset', 'sfx/v2/popup_open.ogg')
            .having((spec) => spec.volume, 'volume', 0.20),
      ),
    );
    expect(
      SoundEffectsService.specs,
      containsPair(
        SoundEffect.bookmarkRemoved,
        isA<SoundEffectSpec>()
            .having((spec) => spec.assetPath, 'asset', 'sfx/v2/popup_close.ogg')
            .having((spec) => spec.volume, 'volume', 0.15),
      ),
    );
    expect(
      SoundEffectsService.specs,
      containsPair(
        SoundEffect.answerCorrect,
        isA<SoundEffectSpec>()
            .having((spec) => spec.assetPath, 'asset', 'sfx/v2/flower_01.ogg')
            .having((spec) => spec.volume, 'volume', 0.40),
      ),
    );
    expect(
      SoundEffectsService.specs,
      containsPair(
        SoundEffect.answerIncorrect,
        isA<SoundEffectSpec>()
            .having((spec) => spec.assetPath, 'asset', 'sfx/v2/error_02.ogg')
            .having((spec) => spec.volume, 'volume', 0.25),
      ),
    );
    expect(
      SoundEffectsService.specs,
      containsPair(
        SoundEffect.sessionCompleted,
        isA<SoundEffectSpec>()
            .having((spec) => spec.assetPath, 'asset', 'sfx/v2/craft_done.ogg')
            .having((spec) => spec.volume, 'volume', 0.45),
      ),
    );
    expect(
      SoundEffectsService.specs,
      containsPair(
        SoundEffect.matchCardSelected,
        isA<SoundEffectSpec>()
            .having((spec) => spec.assetPath, 'asset', 'sfx/v2/tap_felt_01.ogg')
            .having((spec) => spec.volume, 'volume', 0.25),
      ),
    );
    expect(
      SoundEffectsService.specs,
      containsPair(
        SoundEffect.personalBest,
        isA<SoundEffectSpec>()
            .having((spec) => spec.assetPath, 'asset', 'sfx/v2/level_up.ogg')
            .having((spec) => spec.volume, 'volume', 0.45),
      ),
    );
    expect(
      SoundEffectsService.specs,
      containsPair(
        SoundEffect.soundEffectsEnabled,
        isA<SoundEffectSpec>()
            .having((spec) => spec.assetPath, 'asset', 'sfx/v2/select_01.ogg')
            .having((spec) => spec.volume, 'volume', 0.20),
      ),
    );
  });

  test(
    'disabled service stays silent and applies changes immediately',
    () async {
      final playback = FakeSoundEffectsPlayback();
      final service = SoundEffectsService(playback: playback, enabled: false);

      await service.play(SoundEffect.answerCorrect);
      expect(playback.calls, isEmpty);

      service.setEnabled(true);
      await service.play(SoundEffect.answerCorrect);
      expect(playback.calls, hasLength(1));

      service.setEnabled(false);
      await service.play(SoundEffect.answerIncorrect);
      expect(playback.calls, hasLength(1));
    },
  );

  test('preload initializes every selected asset once', () async {
    final playback = FakeSoundEffectsPlayback();
    final service = SoundEffectsService(playback: playback);

    service.preload();
    service.preload();
    await Future<void>.delayed(Duration.zero);

    expect(
      playback.preloadedAssets,
      SoundEffectsService.specs.values.map((spec) => spec.assetPath),
    );
  });
}
