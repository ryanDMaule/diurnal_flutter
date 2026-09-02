import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:diurnul/models/app_settings.dart';
import 'package:diurnul/models/edition.dart';
import 'package:diurnul/services/app_settings_service.dart';
import 'package:diurnul/services/edition_service.dart';
import 'package:diurnul/theme/interface_theme.dart';

void main() {
  test(
    'defaults and all preferences persist across service instances',
    () async {
      final storage = _MemoryAppSettingsStorage();
      final service = AppSettingsService(storage: storage);
      expect(await service.load(), isA<AppSettings>());
      final defaults = await service.load();
      expect(defaults.soundEffectsEnabled, isTrue);
      expect(defaults.reduceAnimations, isFalse);
      expect(defaults.interfaceAppearance, InterfaceAppearance.system);

      await service.save(
        const AppSettings(
          soundEffectsEnabled: false,
          reduceAnimations: true,
          interfaceAppearance: InterfaceAppearance.light,
        ),
      );
      final restored = await AppSettingsService(storage: storage).load();
      expect(restored.soundEffectsEnabled, isFalse);
      expect(restored.reduceAnimations, isTrue);
      expect(restored.interfaceAppearance, InterfaceAppearance.light);
    },
  );

  test('interface appearance resolves explicit and system brightness', () {
    expect(
      resolveInterfaceBrightness(InterfaceAppearance.light, Brightness.dark),
      Brightness.light,
    );
    expect(
      resolveInterfaceBrightness(InterfaceAppearance.dark, Brightness.light),
      Brightness.dark,
    );
    expect(
      resolveInterfaceBrightness(InterfaceAppearance.system, Brightness.light),
      Brightness.light,
    );
    expect(
      resolveInterfaceBrightness(InterfaceAppearance.system, Brightness.dark),
      Brightness.dark,
    );
  });

  test(
    'changing interface appearance does not alter selected Edition',
    () async {
      final storage = _SharedSettingsStorage();
      final editions = EditionService(storage: storage);
      final settings = AppSettingsService(storage: storage);
      await editions.selectEdition(Editions.gallery);

      await settings.save(
        AppSettings.defaults.copyWith(
          interfaceAppearance: InterfaceAppearance.light,
        ),
      );

      expect(await editions.loadSelectedEdition(), Editions.gallery);
    },
  );
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
