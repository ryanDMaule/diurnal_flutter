import 'package:flutter/foundation.dart';

/// Release switch for Diurnus Pro feature restrictions.
///
/// Keep the entitlement and access-policy infrastructure in place so the
/// restricted experience can be restored without changing feature code.
const bool kProRestrictionsEnabled = false;

abstract final class ProRestrictions {
  static bool? _testOverride;

  static bool get enabled => _testOverride ?? kProRestrictionsEnabled;

  static bool hasAccess({required bool isPro}) => !enabled || isPro;

  @visibleForTesting
  static void setTestOverride(bool? enabled) {
    _testOverride = enabled;
  }
}
