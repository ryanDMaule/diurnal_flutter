import 'package:flutter_test/flutter_test.dart';

import 'package:diurnul/services/onboarding_service.dart';

void main() {
  test(
    'fresh installation starts onboarding and resumes its saved step',
    () async {
      final storage = _MemoryOnboardingStorage();
      final service = OnboardingService(storage: storage);

      final initial = await service.resolve();
      expect(initial.shouldShow, isTrue);
      expect(initial.initialStep, 0);
      expect(storage.bools[OnboardingService.startedKey], isTrue);

      await service.saveStep(2);
      final resumed = await OnboardingService(storage: storage).resolve();
      expect(resumed.shouldShow, isTrue);
      expect(resumed.initialStep, 2);
    },
  );

  test(
    'existing installation is migrated without onboarding or shimmer',
    () async {
      final storage = _MemoryOnboardingStorage()
        ..extraKeys.add('diurnus.bookmarkedPublications');

      final state = await OnboardingService(storage: storage).resolve();

      expect(state.shouldShow, isFalse);
      expect(state.shouldShowMenuShimmer, isFalse);
      expect(
        storage.ints[OnboardingService.versionKey],
        OnboardingService.currentVersion,
      );
      expect(storage.bools[OnboardingService.menuShimmerConsumedKey], isTrue);
    },
  );

  test(
    'completion persists and exposes the shimmer exactly until consumed',
    () async {
      final storage = _MemoryOnboardingStorage();
      final service = OnboardingService(storage: storage);
      await service.resolve();
      await service.complete();

      final completed = await OnboardingService(storage: storage).resolve();
      expect(completed.shouldShow, isFalse);
      expect(completed.shouldShowMenuShimmer, isTrue);

      await service.consumeMenuShimmer();
      final consumed = await OnboardingService(storage: storage).resolve();
      expect(consumed.shouldShow, isFalse);
      expect(consumed.shouldShowMenuShimmer, isFalse);
    },
  );

  test(
    'fresh Android install overrides preferences restored by Auto Backup',
    () async {
      final storage = _MemoryOnboardingStorage()
        ..ints[OnboardingService.versionKey] = OnboardingService.currentVersion
        ..bools[OnboardingService.menuShimmerConsumedKey] = true
        ..extraKeys.addAll({
          'diurnus.appSettings',
          'diurnus.selectedEdition',
          'diurnus.bookmarkedPublications',
        });

      final state = await OnboardingService(
        storage: storage,
      ).resolve(isFreshInstallation: true);

      expect(state.shouldShow, isTrue);
      expect(state.initialStep, 0);
      expect(state.useDefaultAppearance, isTrue);
      expect(storage.ints[OnboardingService.versionKey], 0);
      expect(storage.extraKeys, contains('diurnus.bookmarkedPublications'));
    },
  );

  test(
    'onboarding-created app data does not convert an interrupted flow',
    () async {
      final storage = _MemoryOnboardingStorage();
      final service = OnboardingService(storage: storage);
      await service.resolve();
      storage.extraKeys.add('diurnus.appSettings');
      await service.saveStep(1);

      final resumed = await OnboardingService(storage: storage).resolve();

      expect(resumed.shouldShow, isTrue);
      expect(resumed.initialStep, 1);
    },
  );

  test(
    'development preview token runs once without resetting user data',
    () async {
      final storage = _MemoryOnboardingStorage()
        ..ints[OnboardingService.versionKey] = OnboardingService.currentVersion
        ..extraKeys.add('diurnus.bookmarkedPublications');
      final service = OnboardingService(
        storage: storage,
        debugPreviewToken: 'device-check-1',
      );

      final preview = await service.resolve();
      expect(preview.shouldShow, isTrue);
      expect(preview.useDefaultAppearance, isFalse);
      await service.complete();

      final finished = await OnboardingService(
        storage: storage,
        debugPreviewToken: 'device-check-1',
      ).resolve();
      expect(finished.shouldShow, isFalse);
      expect(storage.extraKeys, contains('diurnus.bookmarkedPublications'));
    },
  );
}

class _MemoryOnboardingStorage implements OnboardingStorage {
  final ints = <String, int>{};
  final bools = <String, bool>{};
  final strings = <String, String>{};
  final extraKeys = <String>{};

  @override
  Future<int?> readInt(String key) async => ints[key];

  @override
  Future<bool?> readBool(String key) async => bools[key];

  @override
  Future<String?> readString(String key) async => strings[key];

  @override
  Future<Set<String>> keys() async => {
    ...extraKeys,
    ...ints.keys,
    ...bools.keys,
    ...strings.keys,
  };

  @override
  Future<void> writeInt(String key, int value) async => ints[key] = value;

  @override
  Future<void> writeBool(String key, bool value) async => bools[key] = value;

  @override
  Future<void> writeString(String key, String value) async =>
      strings[key] = value;
}
