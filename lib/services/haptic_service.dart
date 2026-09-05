import 'package:flutter/services.dart';

abstract final class HapticService {
  static void selection({required bool enabled}) {
    if (enabled) HapticFeedback.selectionClick();
  }

  static void confirmation({required bool enabled}) {
    if (enabled) HapticFeedback.mediumImpact();
  }

  static void success({required bool enabled}) {
    if (enabled) HapticFeedback.lightImpact();
  }

  static void error({required bool enabled}) {
    if (enabled) HapticFeedback.heavyImpact();
  }
}
