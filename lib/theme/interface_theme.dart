import 'package:flutter/material.dart';

import '../models/app_settings.dart';
import '../models/edition.dart';
import '../services/app_settings_service.dart';
import '../services/widget_sync_service.dart';
class InterfacePalette {
  const InterfacePalette({
    required this.brightness,
    required this.background,
    required this.surface,
    required this.primary,
    required this.secondary,
    required this.divider,
    required this.accent,
  });

  final Brightness brightness;
  final Color background;
  final Color surface;
  final Color primary;
  final Color secondary;
  final Color divider;
  final Color accent;

  static const evergreen = InterfacePalette(
    brightness: Brightness.dark,
    background: Color(0xFF032C23),
    surface: Color(0xFF0B332A),
    primary: Color(0xFFF3EBDD),
    secondary: Color(0xFFCFC7B8),
    divider: Color(0xFF9AA89F),
    accent: Color(0xFFC8A363),
  );
  static const charcoal = InterfacePalette(
    brightness: Brightness.dark,
    background: Color(0xFF211F1C),
    surface: Color(0xFF2B2824),
    primary: Color(0xFFF3EBDD),
    secondary: Color(0xFFC9C0B4),
    divider: Color(0xFF625C54),
    accent: Color(0xFFC5A063),
  );
  static const navy = InterfacePalette(
    brightness: Brightness.dark,
    background: Color(0xFF0B1724),
    surface: Color(0xFF122131),
    primary: Color(0xFFF3EBDD),
    secondary: Color(0xFFB9C2CA),
    divider: Color(0xFF43515E),
    accent: Color(0xFFC5A063),
  );
  static const oxblood = InterfacePalette(
    brightness: Brightness.dark,
    background: Color(0xFF351519),
    surface: Color(0xFF421C21),
    primary: Color(0xFFF3EBDD),
    secondary: Color(0xFFCDB9B5),
    divider: Color(0xFF755056),
    accent: Color(0xFFC5A063),
  );
  static const paper = InterfacePalette(
    brightness: Brightness.light,
    background: Color(0xFFF1EBDD),
    surface: Color(0xFFE7DECB),
    primary: Color(0xFF282722),
    secondary: Color(0xFF665F56),
    divider: Color(0xFFC9BEA8),
    accent: Color(0xFF8C682F),
  );

  static InterfacePalette forColor(InterfaceColor color) => switch (color) {
    InterfaceColor.evergreen => evergreen,
    InterfaceColor.charcoal => charcoal,
    InterfaceColor.navy => navy,
    InterfaceColor.oxblood => oxblood,
    InterfaceColor.paper => paper,
  };
}

Edition resolveInterfaceColorEdition(
  Edition edition,
  InterfacePalette palette,
) {
  if (edition.id != Editions.evergreen.id) return edition;
  return Edition(
    id: edition.id,
    name: edition.name,
    description: edition.description,
    backgroundAsset: edition.backgroundAsset,
    backgroundColor: palette.background,
    tintColor: edition.tintColor,
    tintOpacity: edition.tintOpacity,
    gradientColors: edition.gradientColors,
    gradientStops: edition.gradientStops,
    gradientBegin: edition.gradientBegin,
    gradientEnd: edition.gradientEnd,
    primaryTextColor: palette.primary,
    secondaryTextColor: palette.secondary,
    mutedTextColor: palette.divider,
    accentColor: palette.accent,
    systemUiIconBrightness: palette.brightness == Brightness.light
        ? Brightness.dark
        : Brightness.light,
  );
}

class InterfaceColorController extends ChangeNotifier {
  InterfaceColorController(this.service, {WidgetSyncService? widgetSyncService})
    : _widgetSyncService = widgetSyncService;
  final AppSettingsService service;
  final WidgetSyncService? _widgetSyncService;
  AppSettings settings = AppSettings.defaults;

  Future<void> load() async {
    settings = await service.load();
    notifyListeners();
    await _syncWidget();
  }

  Future<void> update(AppSettings value) async {
    final previous = settings;
    settings = value;
    notifyListeners();
    try {
      await service.save(value);
    } catch (_) {
      settings = previous;
      notifyListeners();
      rethrow;
    }
    await _syncWidget();
  }

  Future<void> _syncWidget() async {
    final widgetSyncService = _widgetSyncService;
    if (widgetSyncService == null) return;
    try {
      await widgetSyncService.syncInterfaceSettings(settings);
    } catch (error) {
      debugPrint('Error synchronizing widget Theme Colour: $error');
    }
  }
}

class InterfaceThemeScope
    extends InheritedNotifier<InterfaceColorController> {
  const InterfaceThemeScope({
    required super.notifier,
    required super.child,
    super.key,
  });

  static InterfaceColorController controllerOf(BuildContext context) =>
      context
          .dependOnInheritedWidgetOfExactType<InterfaceThemeScope>()!
          .notifier!;

  static InterfacePalette paletteOf(BuildContext context) {
    return InterfacePalette.forColor(
      controllerOf(context).settings.interfaceColor,
    );
  }

  static InterfaceColorController? maybeControllerOf(
    BuildContext context,
  ) => context
      .dependOnInheritedWidgetOfExactType<InterfaceThemeScope>()
      ?.notifier;

  static InterfacePalette maybePaletteOf(BuildContext context) {
    final controller = maybeControllerOf(context);
    if (controller == null) return InterfacePalette.evergreen;
    return InterfacePalette.forColor(
      controller.settings.interfaceColor,
    );
  }
}

class InterfaceSafeArea extends StatelessWidget {
  const InterfaceSafeArea({
    required this.child,
    this.textureEnabled = true,
    super.key,
  });

  final Widget child;
  final bool textureEnabled;

  @override
  Widget build(BuildContext context) {
    final controller = InterfaceThemeScope.maybeControllerOf(context);
    final palette = InterfaceThemeScope.maybePaletteOf(context);
    final showTexture =
        textureEnabled && (controller?.settings.textureEnabled ?? true);
    return Stack(
      fit: StackFit.expand,
      children: [
        if (showTexture)
          InterfaceTextureOverlay(
            asset: 'assets/images/paper.png',
            baseColor: palette.background,
            strength: 0.10,
          ),
        SafeArea(child: child),
      ],
    );
  }
}

class InterfaceTextureOverlay extends StatelessWidget {
  const InterfaceTextureOverlay({
    required this.asset,
    required this.baseColor,
    required this.strength,
    super.key,
  });

  final String asset;
  final Color baseColor;
  final double strength;

  @override
  Widget build(BuildContext context) => IgnorePointer(
    child: Opacity(
      opacity: strength,
      child: ColorFiltered(
        colorFilter: ColorFilter.mode(baseColor, BlendMode.modulate),
        child: ColorFiltered(
          colorFilter: const ColorFilter.matrix([
            0.2126, 0.7152, 0.0722, 0, 0,
            0.2126, 0.7152, 0.0722, 0, 0,
            0.2126, 0.7152, 0.0722, 0, 0,
            0, 0, 0, 1, 0,
          ]),
          child: Image.asset(asset, fit: BoxFit.cover),
        ),
      ),
    ),
  );
}
