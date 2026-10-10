import 'package:diurnul/services/sound_effects_service.dart';

class SoundPlaybackCall {
  const SoundPlaybackCall(this.assetPath, this.volume);

  final String assetPath;
  final double volume;
}

class FakeSoundEffectsPlayback implements SoundEffectsPlayback {
  final List<String> preloadedAssets = [];
  final List<SoundPlaybackCall> calls = [];
  bool disposed = false;

  @override
  Future<void> preload(Iterable<String> assetPaths) async {
    preloadedAssets.addAll(assetPaths);
  }

  @override
  Future<void> play(String assetPath, {required double volume}) async {
    calls.add(SoundPlaybackCall(assetPath, volume));
  }

  @override
  Future<void> dispose() async {
    disposed = true;
  }
}
