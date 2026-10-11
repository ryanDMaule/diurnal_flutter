import 'package:diurnul/services/feature_introduction_service.dart';

FeatureIntroductionService seenFeatureIntroductions() =>
    FeatureIntroductionService(storage: _SeenFeatureIntroductionStorage());

class _SeenFeatureIntroductionStorage implements FeatureIntroductionStorage {
  @override
  Future<bool?> read(String key) async => true;

  @override
  Future<void> write(String key, bool value) async {}
}
