import 'package:flutter_test/flutter_test.dart';

import 'package:diurnul/main.dart';
import 'package:diurnul/models/daily_publication.dart';
import 'package:diurnul/screens/onboarding_screen.dart';
import 'package:diurnul/screens/today_screen.dart';
import 'package:diurnul/services/app_settings_service.dart';
import 'package:diurnul/services/edition_service.dart';
import 'package:diurnul/services/entitlement_service.dart';
import 'package:diurnul/services/install_identity_service.dart';
import 'package:diurnul/services/onboarding_service.dart';
import 'package:diurnul/services/publication_api_service.dart';
import 'package:diurnul/services/widget_sync_service.dart';

void main() {
  testWidgets('actual app startup displays Welcome for a new preview token', (
    tester,
  ) async {
    final storage = _MemoryOnboardingStorage()
      ..ints[OnboardingService.versionKey] = OnboardingService.currentVersion
      ..strings[OnboardingService.debugPreviewConsumedKey] = 'old-token';

    await _pumpApp(
      tester,
      onboardingService: OnboardingService(
        storage: storage,
        debugPreviewToken: 'new-token',
      ),
    );

    expect(find.byType(OnboardingScreen), findsOneWidget);
    expect(find.text('One remarkable\nword, every day.'), findsOneWidget);
    expect(find.byType(TodayScreen), findsNothing);

    await tester.pump(const Duration(seconds: 5));
    expect(find.byType(OnboardingScreen), findsOneWidget);
    expect(find.byType(TodayScreen), findsNothing);
  });

  testWidgets(
    'actual app startup displays Today for a completed preview token',
    (tester) async {
      final storage = _MemoryOnboardingStorage()
        ..ints[OnboardingService.versionKey] = OnboardingService.currentVersion
        ..bools[OnboardingService.menuShimmerConsumedKey] = true
        ..strings[OnboardingService.debugPreviewConsumedKey] = 'same-token';

      await _pumpApp(
        tester,
        onboardingService: OnboardingService(
          storage: storage,
          debugPreviewToken: 'same-token',
        ),
      );

      expect(find.byType(TodayScreen), findsOneWidget);
      expect(find.byType(OnboardingScreen), findsNothing);
    },
  );

  testWidgets('actual app startup displays Welcome for a fresh installation', (
    tester,
  ) async {
    final storage = _MemoryOnboardingStorage()
      ..ints[OnboardingService.versionKey] = OnboardingService.currentVersion
      ..extraKeys.add('diurnus.selectedEdition');

    await _pumpApp(
      tester,
      onboardingService: OnboardingService(storage: storage),
      freshInstallation: true,
    );

    expect(find.byType(OnboardingScreen), findsOneWidget);
    expect(find.byType(TodayScreen), findsNothing);
  });

  testWidgets(
    'actual app startup displays Today for an existing installation',
    (tester) async {
      final storage = _MemoryOnboardingStorage()
        ..extraKeys.add('diurnus.bookmarkedPublications');

      await _pumpApp(
        tester,
        onboardingService: OnboardingService(storage: storage),
      );

      expect(find.byType(TodayScreen), findsOneWidget);
      expect(find.byType(OnboardingScreen), findsNothing);
    },
  );
}

Future<void> _pumpApp(
  WidgetTester tester, {
  required OnboardingService onboardingService,
  bool freshInstallation = false,
}) async {
  final appSettingsStorage = _MemoryAppSettingsStorage();
  final entitlementStorage = _MemoryEntitlementStorage();
  final editionStorage = _MemoryEditionStorage();
  await tester.pumpWidget(
    DiurnalApp(
      appSettingsService: AppSettingsService(storage: appSettingsStorage),
      entitlementService: EntitlementService(storage: entitlementStorage),
      editionService: EditionService(storage: editionStorage),
      onboardingService: onboardingService,
      installIdentityService: _FakeInstallIdentityService(freshInstallation),
      widgetSyncService: WidgetSyncService(cache: _MemoryWidgetCache()),
      initialPublicationLoader: () async => const TodayPublicationLoad(
        publication: DailyPublication.localFallback,
        isOffline: true,
      ),
      enableStartupAudio: false,
    ),
  );
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 900));
  await tester.pump();
  // Future.any does not cancel the losing startup timeout.
  await tester.pump(const Duration(milliseconds: 1200));
}

class _FakeInstallIdentityService implements InstallIdentityService {
  const _FakeInstallIdentityService(this.fresh);

  final bool fresh;

  @override
  Future<bool> isFreshInstallation() async => fresh;
}

class _MemoryAppSettingsStorage implements AppSettingsStorage {
  @override
  Future<String?> read(String key) async => null;

  @override
  Future<void> write(String key, String value) async {}
}

class _MemoryEntitlementStorage implements EntitlementStorage {
  @override
  Future<String?> readTier() async => null;

  @override
  Future<void> writeTier(String tier) async {}
}

class _MemoryEditionStorage implements EditionStorage {
  String? value;

  @override
  Future<String?> read(String key) async => value;

  @override
  Future<void> write(String key, String value) async => this.value = value;
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
    ...ints.keys,
    ...bools.keys,
    ...strings.keys,
    ...extraKeys,
  };

  @override
  Future<void> writeInt(String key, int value) async => ints[key] = value;

  @override
  Future<void> writeBool(String key, bool value) async => bools[key] = value;

  @override
  Future<void> writeString(String key, String value) async =>
      strings[key] = value;
}

class _MemoryWidgetCache implements WidgetCache {
  @override
  Future<void> redraw() async {}

  @override
  Future<void> saveBool(String key, bool value) async {}

  @override
  Future<void> saveString(String key, String value) async {}
}
