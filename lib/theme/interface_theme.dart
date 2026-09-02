import 'package:flutter/material.dart';

import '../models/app_settings.dart';
import '../services/app_settings_service.dart';
import 'colors.dart';

class InterfacePalette {
  const InterfacePalette({
    required this.background,
    required this.surface,
    required this.primary,
    required this.secondary,
    required this.divider,
    required this.accent,
  });

  final Color background;
  final Color surface;
  final Color primary;
  final Color secondary;
  final Color divider;
  final Color accent;

  static const dark = InterfacePalette(
    background: AppColors.menuBackground,
    surface: Color(0xFF0B332A),
    primary: AppColors.textPrimary,
    secondary: Color(0xFF8E9E99),
    divider: AppColors.menuDivider,
    accent: AppColors.textSecondary,
  );
  static const light = InterfacePalette(
    background: Color(0xFFF1EBDD),
    surface: Color(0xFFE7DECB),
    primary: Color(0xFF16342D),
    secondary: Color(0xFF52645E),
    divider: Color(0xFFC9BEA8),
    accent: Color(0xFF9A7337),
  );
}

Brightness resolveInterfaceBrightness(
  InterfaceAppearance appearance,
  Brightness platformBrightness,
) => switch (appearance) {
  InterfaceAppearance.system => platformBrightness,
  InterfaceAppearance.light => Brightness.light,
  InterfaceAppearance.dark => Brightness.dark,
};

class InterfaceAppearanceController extends ChangeNotifier {
  InterfaceAppearanceController(this.service);
  final AppSettingsService service;
  AppSettings settings = AppSettings.defaults;

  Future<void> load() async {
    settings = await service.load();
    notifyListeners();
  }

  Future<void> update(AppSettings value) async {
    await service.save(value);
    settings = value;
    notifyListeners();
  }
}

class InterfaceThemeScope
    extends InheritedNotifier<InterfaceAppearanceController> {
  const InterfaceThemeScope({
    required super.notifier,
    required super.child,
    super.key,
  });

  static InterfaceAppearanceController controllerOf(BuildContext context) =>
      context
          .dependOnInheritedWidgetOfExactType<InterfaceThemeScope>()!
          .notifier!;

  static InterfacePalette paletteOf(BuildContext context) {
    final appearance = controllerOf(context).settings.interfaceAppearance;
    final brightness = resolveInterfaceBrightness(
      appearance,
      MediaQuery.platformBrightnessOf(context),
    );
    return brightness == Brightness.light
        ? InterfacePalette.light
        : InterfacePalette.dark;
  }

  static InterfaceAppearanceController? maybeControllerOf(
    BuildContext context,
  ) => context
      .dependOnInheritedWidgetOfExactType<InterfaceThemeScope>()
      ?.notifier;

  static InterfacePalette maybePaletteOf(BuildContext context) {
    final controller = maybeControllerOf(context);
    if (controller == null) return InterfacePalette.dark;
    final brightness = resolveInterfaceBrightness(
      controller.settings.interfaceAppearance,
      MediaQuery.platformBrightnessOf(context),
    );
    return brightness == Brightness.light
        ? InterfacePalette.light
        : InterfacePalette.dark;
  }
}
