import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

abstract interface class OnboardingStorage {
  Future<int?> readInt(String key);

  Future<bool?> readBool(String key);

  Future<String?> readString(String key);

  Future<Set<String>> keys();

  Future<void> writeInt(String key, int value);

  Future<void> writeBool(String key, bool value);

  Future<void> writeString(String key, String value);
}

class SharedPreferencesOnboardingStorage implements OnboardingStorage {
  SharedPreferencesOnboardingStorage({SharedPreferencesAsync? preferences})
    : _preferences = preferences ?? SharedPreferencesAsync();

  final SharedPreferencesAsync _preferences;

  @override
  Future<int?> readInt(String key) => _preferences.getInt(key);

  @override
  Future<bool?> readBool(String key) => _preferences.getBool(key);

  @override
  Future<String?> readString(String key) => _preferences.getString(key);

  @override
  Future<Set<String>> keys() => _preferences.getKeys();

  @override
  Future<void> writeInt(String key, int value) =>
      _preferences.setInt(key, value);

  @override
  Future<void> writeBool(String key, bool value) =>
      _preferences.setBool(key, value);

  @override
  Future<void> writeString(String key, String value) =>
      _preferences.setString(key, value);
}

class OnboardingState {
  const OnboardingState({
    required this.shouldShow,
    required this.initialStep,
    required this.shouldShowMenuShimmer,
    required this.useDefaultAppearance,
    required this.previewTokenStatus,
    required this.onboardingComplete,
  });

  final bool shouldShow;
  final int initialStep;
  final bool shouldShowMenuShimmer;
  final bool useDefaultAppearance;
  final PreviewTokenStatus previewTokenStatus;
  final bool onboardingComplete;
}

enum PreviewTokenStatus { disabled, newToken, completedToken }

class OnboardingService {
  OnboardingService({
    OnboardingStorage? storage,
    String debugPreviewToken = const String.fromEnvironment(
      'DIURNUS_ONBOARDING_PREVIEW',
    ),
  }) : _storage = storage ?? SharedPreferencesOnboardingStorage(),
       _debugPreviewToken = kDebugMode ? debugPreviewToken.trim() : '';

  static const currentVersion = 1;
  static const pageCount = 3;
  static const lastPageIndex = pageCount - 1;
  static const versionKey = 'diurnus.onboardingVersion';
  static const startedKey = 'diurnus.onboardingStarted';
  static const stepKey = 'diurnus.onboardingStep';
  static const menuShimmerConsumedKey = 'diurnus.onboardingMenuShimmerConsumed';
  static const resetAppearanceKey = 'diurnus.onboardingUseDefaultAppearance';
  static const debugPreviewConsumedKey = 'diurnus.onboardingDebugPreview';

  static const establishedDataKeys = <String>{
    'diurnus.appSettings',
    'diurnus.selectedEdition',
    'diurnus.todayPublication.lastSuccessful',
    'diurnus.archivePublications.lastSuccessful',
    'diurnus.archivePublications.lastSuccessfulRefresh',
    'diurnus.bookmarkedPublications',
    'diurnus.recalledPublicationIds',
    'diurnus.attemptedPublicationIds',
    'diurnus.recallSettings',
    'diurnus.endlessRecallBest',
    'diurnus.matchBestMilliseconds',
    'diurnus.subscriptionTier',
  };

  final OnboardingStorage _storage;
  final String _debugPreviewToken;

  Future<OnboardingState> resolve({bool isFreshInstallation = false}) async {
    final version = await _storage.readInt(versionKey);
    final consumedPreviewToken = _debugPreviewToken.isEmpty
        ? null
        : await _storage.readString(debugPreviewConsumedKey);
    final previewTokenStatus = _debugPreviewToken.isEmpty
        ? PreviewTokenStatus.disabled
        : consumedPreviewToken == _debugPreviewToken
        ? PreviewTokenStatus.completedToken
        : PreviewTokenStatus.newToken;
    final onboardingComplete = (version ?? 0) >= currentVersion;

    if (isFreshInstallation) {
      await _storage.writeInt(versionKey, 0);
      await _storage.writeInt(stepKey, 0);
      await _storage.writeBool(startedKey, true);
      await _storage.writeBool(resetAppearanceKey, true);
      return OnboardingState(
        shouldShow: true,
        initialStep: 0,
        shouldShowMenuShimmer: false,
        useDefaultAppearance: true,
        previewTokenStatus: previewTokenStatus,
        onboardingComplete: onboardingComplete,
      );
    }

    if (previewTokenStatus == PreviewTokenStatus.newToken) {
      await _storage.writeInt(stepKey, 0);
      return OnboardingState(
        shouldShow: true,
        initialStep: 0,
        shouldShowMenuShimmer: false,
        useDefaultAppearance: false,
        previewTokenStatus: previewTokenStatus,
        onboardingComplete: onboardingComplete,
      );
    }

    if ((version ?? 0) >= currentVersion) {
      return OnboardingState(
        shouldShow: false,
        initialStep: 0,
        shouldShowMenuShimmer:
            !(await _storage.readBool(menuShimmerConsumedKey) ?? true),
        useDefaultAppearance: false,
        previewTokenStatus: previewTokenStatus,
        onboardingComplete: true,
      );
    }

    final started = await _storage.readBool(startedKey) ?? false;
    if (!started) {
      final existingKeys = await _storage.keys();
      if (existingKeys.any(establishedDataKeys.contains)) {
        await _storage.writeInt(versionKey, currentVersion);
        await _storage.writeBool(menuShimmerConsumedKey, true);
        return OnboardingState(
          shouldShow: false,
          initialStep: 0,
          shouldShowMenuShimmer: false,
          useDefaultAppearance: false,
          previewTokenStatus: previewTokenStatus,
          onboardingComplete: true,
        );
      }
      await _storage.writeBool(startedKey, true);
    }

    final storedStep = await _storage.readInt(stepKey) ?? 0;
    return OnboardingState(
      shouldShow: true,
      initialStep: storedStep.clamp(0, lastPageIndex),
      shouldShowMenuShimmer: false,
      useDefaultAppearance:
          await _storage.readBool(resetAppearanceKey) ?? false,
      previewTokenStatus: previewTokenStatus,
      onboardingComplete: false,
    );
  }

  Future<void> saveStep(int step) =>
      _storage.writeInt(stepKey, step.clamp(0, lastPageIndex));

  Future<void> complete() async {
    await _storage.writeInt(versionKey, currentVersion);
    await _storage.writeInt(stepKey, 0);
    await _storage.writeBool(menuShimmerConsumedKey, false);
    await _storage.writeBool(resetAppearanceKey, false);
    if (_debugPreviewToken.isNotEmpty) {
      await _storage.writeString(debugPreviewConsumedKey, _debugPreviewToken);
    }
  }

  Future<void> consumeMenuShimmer() =>
      _storage.writeBool(menuShimmerConsumedKey, true);
}
