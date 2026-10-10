import 'dart:async';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';

enum SoundEffect {
  bookmarkSaved,
  bookmarkRemoved,
  answerCorrect,
  answerIncorrect,
  sessionCompleted,
  matchCardSelected,
  personalBest,
  soundEffectsEnabled,
}

@immutable
class SoundEffectSpec {
  const SoundEffectSpec({required this.assetPath, required this.volume});

  final String assetPath;
  final double volume;
}

abstract interface class SoundEffectsPlayback {
  Future<void> preload(Iterable<String> assetPaths);

  Future<void> play(String assetPath, {required double volume});

  Future<void> dispose();
}

class AudioplayersSoundEffectsPlayback implements SoundEffectsPlayback {
  final Map<String, Future<AudioPool>> _pools = {};
  bool _disposed = false;

  Future<AudioPool> _poolFor(String assetPath) => _pools.putIfAbsent(
    assetPath,
    () => AudioPool.createFromAsset(
      path: assetPath,
      maxPlayers: 2,
      minPlayers: 1,
    ),
  );

  @override
  Future<void> preload(Iterable<String> assetPaths) async {
    if (_disposed) return;
    await Future.wait(assetPaths.map(_poolFor));
  }

  @override
  Future<void> play(String assetPath, {required double volume}) async {
    if (_disposed) return;
    final pool = await _poolFor(assetPath);
    if (_disposed) return;
    await pool.start(volume: volume);
  }

  @override
  Future<void> dispose() async {
    if (_disposed) return;
    _disposed = true;
    final pools = await Future.wait(_pools.values);
    await Future.wait(pools.map((pool) => pool.dispose()));
    _pools.clear();
  }
}

class SoundEffectsService {
  SoundEffectsService({SoundEffectsPlayback? playback, bool enabled = true})
    : _playback = playback ?? AudioplayersSoundEffectsPlayback(),
      _enabled = enabled;

  static final SoundEffectsService instance = SoundEffectsService();

  static const specs = <SoundEffect, SoundEffectSpec>{
    SoundEffect.bookmarkSaved: SoundEffectSpec(
      assetPath: 'sfx/v2/popup_open.ogg',
      volume: 0.20,
    ),
    SoundEffect.bookmarkRemoved: SoundEffectSpec(
      assetPath: 'sfx/v2/popup_close.ogg',
      volume: 0.15,
    ),
    SoundEffect.answerCorrect: SoundEffectSpec(
      assetPath: 'sfx/v2/flower_01.ogg',
      volume: 0.40,
    ),
    SoundEffect.answerIncorrect: SoundEffectSpec(
      assetPath: 'sfx/v2/error_02.ogg',
      volume: 0.25,
    ),
    SoundEffect.sessionCompleted: SoundEffectSpec(
      assetPath: 'sfx/v2/craft_done.ogg',
      volume: 0.45,
    ),
    SoundEffect.matchCardSelected: SoundEffectSpec(
      assetPath: 'sfx/v2/tap_felt_01.ogg',
      volume: 0.25,
    ),
    SoundEffect.personalBest: SoundEffectSpec(
      assetPath: 'sfx/v2/level_up.ogg',
      volume: 0.45,
    ),
    SoundEffect.soundEffectsEnabled: SoundEffectSpec(
      assetPath: 'sfx/v2/select_01.ogg',
      volume: 0.20,
    ),
  };

  final SoundEffectsPlayback _playback;
  bool _enabled;
  bool _preloadStarted = false;

  bool get enabled => _enabled;

  void setEnabled(bool value) {
    _enabled = value;
  }

  void preload() {
    if (_preloadStarted) return;
    _preloadStarted = true;
    unawaited(
      _playback.preload(specs.values.map((spec) => spec.assetPath)).catchError((
        Object error,
      ) {
        debugPrint('Error preloading sound effects: $error');
      }),
    );
  }

  Future<void> play(SoundEffect effect) async {
    if (!_enabled) return;
    final spec = specs[effect];
    if (spec == null) return;
    try {
      await _playback.play(spec.assetPath, volume: spec.volume);
    } catch (error) {
      debugPrint('Error playing sound effect ${effect.name}: $error');
    }
  }

  Future<void> dispose() => _playback.dispose();
}
