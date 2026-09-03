import 'package:home_widget/home_widget.dart';

import '../models/daily_publication.dart';
import '../models/edition.dart';

abstract interface class WidgetCache {
  Future<void> saveString(String key, String value);

  Future<void> redraw();
}

class HomeWidgetCache implements WidgetCache {
  @override
  Future<void> saveString(String key, String value) =>
      HomeWidget.saveWidgetData<String>(key, value);

  @override
  Future<void> redraw() => HomeWidget.updateWidget(
    name: 'HomeWidgetProvider',
    androidName: 'HomeWidgetProvider',
    iOSName: 'HomeWidget',
    qualifiedAndroidName: 'com.example.diurnul.HomeWidgetProvider',
  );
}

class WidgetSyncService {
  WidgetSyncService({WidgetCache? cache}) : _cache = cache ?? HomeWidgetCache();

  static const wordKey = 'word';
  static const typeKey = 'type';
  static const phoneticKey = 'phonetic';
  static const definitionKey = 'definition';
  static const editionKey = 'edition';

  final WidgetCache _cache;

  Future<void> syncPublication(DailyPublication publication) async {
    await _cache.saveString(wordKey, publication.word);
    await _cache.saveString(typeKey, publication.type);
    await _cache.saveString(phoneticKey, publication.phonetic);
    await _cache.saveString(definitionKey, publication.definition);
    await _cache.redraw();
  }

  Future<void> syncEdition(Edition edition) async {
    await _cache.saveString(editionKey, edition.id);
    await _cache.redraw();
  }
}
