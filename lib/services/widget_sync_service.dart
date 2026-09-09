import 'package:home_widget/home_widget.dart';

import '../models/app_settings.dart';
import '../models/daily_publication.dart';
import '../models/edition.dart';

abstract interface class WidgetCache {
  Future<void> saveString(String key, String value);

  Future<void> saveBool(String key, bool value);

  Future<void> redraw();
}

class HomeWidgetCache implements WidgetCache {
  @override
  Future<void> saveString(String key, String value) =>
      HomeWidget.saveWidgetData<String>(key, value);

  @override
  Future<void> saveBool(String key, bool value) =>
      HomeWidget.saveWidgetData<bool>(key, value);

  @override
  Future<void> redraw() async {
    await HomeWidget.updateWidget(
      name: 'HomeWidgetProvider',
      androidName: 'HomeWidgetProvider',
      iOSName: 'HomeWidget',
      qualifiedAndroidName: 'com.example.diurnul.HomeWidgetProvider',
    );
    await HomeWidget.updateWidget(
      name: 'MediumWidgetProvider',
      androidName: 'MediumWidgetProvider',
      qualifiedAndroidName: 'com.example.diurnul.MediumWidgetProvider',
    );
    await HomeWidget.updateWidget(
      name: 'LargeWidgetProvider',
      androidName: 'LargeWidgetProvider',
      qualifiedAndroidName: 'com.example.diurnul.LargeWidgetProvider',
    );
    await HomeWidget.updateWidget(
      name: 'MarkWidgetProvider',
      androidName: 'MarkWidgetProvider',
      qualifiedAndroidName: 'com.example.diurnul.MarkWidgetProvider',
    );
    await HomeWidget.updateWidget(
      name: 'BrandWidgetProvider',
      androidName: 'BrandWidgetProvider',
      qualifiedAndroidName: 'com.example.diurnul.BrandWidgetProvider',
    );
  }
}

class WidgetSyncService {
  WidgetSyncService({WidgetCache? cache}) : _cache = cache ?? HomeWidgetCache();

  static const wordKey = 'word';
  static const typeKey = 'type';
  static const phoneticKey = 'phonetic';
  static const definitionKey = 'definition';
  static const sequenceKey = 'sequence';
  static const editionKey = 'edition';
  static const interfaceColorKey = 'interfaceColor';
  static const textureEnabledKey = 'textureEnabled';

  final WidgetCache _cache;

  Future<void> syncPublication(DailyPublication publication) async {
    await _cache.saveString(wordKey, publication.word);
    await _cache.saveString(typeKey, publication.type);
    await _cache.saveString(phoneticKey, publication.phonetic);
    await _cache.saveString(definitionKey, publication.definition);
    await _cache.saveString(
      sequenceKey,
      publication.sequence?.toString() ?? '',
    );
    await _cache.redraw();
  }

  Future<void> syncEdition(Edition edition) async {
    await _cache.saveString(editionKey, edition.id);
    await _cache.redraw();
  }

  Future<void> syncInterfaceColor(InterfaceColor color) async {
    await _cache.saveString(interfaceColorKey, color.name);
    await _cache.redraw();
  }

  Future<void> syncInterfaceSettings(AppSettings settings) async {
    await _cache.saveString(interfaceColorKey, settings.interfaceColor.name);
    await _cache.saveBool(textureEnabledKey, settings.textureEnabled);
    await _cache.redraw();
  }
}
