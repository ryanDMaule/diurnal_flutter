import 'package:flutter/widgets.dart';

import '../services/entitlement_service.dart';

class EntitlementScope extends InheritedNotifier<EntitlementController> {
  const EntitlementScope({
    required super.notifier,
    required super.child,
    super.key,
  });

  static EntitlementController controllerOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<EntitlementScope>()!.notifier!;

  static EntitlementController? maybeControllerOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<EntitlementScope>()?.notifier;
}
