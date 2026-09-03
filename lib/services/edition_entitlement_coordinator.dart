import 'package:flutter/foundation.dart';

import '../models/edition_access_policy.dart';
import 'edition_service.dart';
import 'entitlement_service.dart';
import 'widget_sync_service.dart';

class EditionEntitlementCoordinator {
  EditionEntitlementCoordinator({
    required this.entitlementController,
    required this.editionService,
    required this.widgetSyncService,
  });

  final EntitlementController entitlementController;
  final EditionService editionService;
  final WidgetSyncService widgetSyncService;
  bool _started = false;

  void start() {
    if (_started) return;
    _started = true;
    entitlementController.addListener(_entitlementChanged);
  }

  void dispose() {
    if (!_started) return;
    entitlementController.removeListener(_entitlementChanged);
    _started = false;
  }

  Future<void> syncNow() async {
    try {
      final stored = await editionService.loadSelectedEdition();
      final effective = EditionAccessPolicy.effectiveFor(
        stored,
        isPro: entitlementController.isPro,
      );
      await widgetSyncService.syncEdition(effective);
    } catch (error) {
      debugPrint('Error synchronizing entitled widget Edition: $error');
    }
  }

  void _entitlementChanged() {
    syncNow();
  }
}
