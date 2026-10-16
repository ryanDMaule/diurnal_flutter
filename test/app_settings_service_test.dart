import 'package:flutter_test/flutter_test.dart';

import 'package:diurnul/models/app_settings.dart';
import 'package:diurnul/models/edition.dart';
import 'package:diurnul/services/app_settings_service.dart';
import 'package:diurnul/services/edition_service.dart';

void main() {
  test(
    'defaults and all preferences persist across service instances',
    () async {
      final storage = _MemoryAppSettingsStorage();
      final service = AppSettingsService(storage: storage);
      expect(await service.load(), isA<AppSettings>());
      final defaults = await service.load();
      expect(defaults.soundEffectsEnabled, isTrue);
      expect(defaults.interfaceColor, InterfaceColor.evergreen);

      await service.save(
        const AppSettings(
          soundEffectsEnabled: false,
          interfaceColor: InterfaceColor.navy,
          textureEnabled: false,
        ),
      );
      final restored = await AppSettingsService(storage: storage).load();
      expect(restored.soundEffectsEnabled, isFalse);
      expect(restored.interfaceColor, InterfaceColor.navy);
    },
  );

  test(
    'legacy reduceAnimations value is ignored without losing settings',
    () async {
      final storage = _MemoryAppSettingsStorage()
        ..value =
            '{"soundEffectsEnabled":false,"hapticFeedbackEnabled":false,'
            '"reduceAnimations":true,"interfaceColor":"navy",'
            '"textureEnabled":false}';

      final service = AppSettingsService(storage: storage);
      final restored = await service.load();

      expect(restored.soundEffectsEnabled, isFalse);
      expect(restored.hapticFeedbackEnabled, isFalse);
      expect(restored.interfaceColor, InterfaceColor.navy);
      expect(restored.textureEnabled, isFalse);

      await service.save(restored);
      expect(storage.value, isNot(contains('reduceAnimations')));
    },
  );

  test('legacy interface appearances migrate to interface colours', () async {
    final storage = _MemoryAppSettingsStorage();
    storage.value = '{"interfaceAppearance":"light"}';
    expect(
      (await AppSettingsService(storage: storage).load()).interfaceColor,
      InterfaceColor.paper,
    );
    storage.value = '{"interfaceAppearance":"dark"}';
    expect(
      (await AppSettingsService(storage: storage).load()).interfaceColor,
      InterfaceColor.evergreen,
    );
    storage.value = '{"interfaceAppearance":"system"}';
    expect(
      (await AppSettingsService(storage: storage).load()).interfaceColor,
      InterfaceColor.evergreen,
    );
  });

  test('changing interface colour does not alter selected Edition', () async {
    final storage = _SharedSettingsStorage();
    final editions = EditionService(storage: storage);
    final settings = AppSettingsService(storage: storage);
    await editions.selectEdition(Editions.gilded);

    await settings.save(
      AppSettings.defaults.copyWith(interfaceColor: InterfaceColor.paper),
    );

    expect(await editions.loadSelectedEdition(), Editions.gilded);
  });
}

class _MemoryAppSettingsStorage implements AppSettingsStorage {
  String? value;
  @override
  Future<String?> read(String key) async => value;
  @override
  Future<void> write(String key, String value) async => this.value = value;
}

class _SharedSettingsStorage implements AppSettingsStorage, EditionStorage {
  final values = <String, String>{};
  @override
  Future<String?> read(String key) async => values[key];
  @override
  Future<void> write(String key, String value) async => values[key] = value;
}
