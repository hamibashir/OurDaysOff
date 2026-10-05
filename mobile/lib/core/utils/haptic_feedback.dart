import 'package:flutter/services.dart';

/// Centralized haptic feedback controller
class AppHaptics {
  AppHaptics._();

  /// Subtle click for fast-tap schedule stamping, selection toggles
  static Future<void> light() async {
    try {
      await HapticFeedback.lightImpact();
    } catch (_) {}
  }

  /// Medium impact for buttons, confirmations, RSVP actions
  static Future<void> medium() async {
    try {
      await HapticFeedback.mediumImpact();
    } catch (_) {}
  }

  /// Heavy impact for error notices or critical actions
  static Future<void> heavy() async {
    try {
      await HapticFeedback.heavyImpact();
    } catch (_) {}
  }

  /// Selection click for calendar date pickers and tabs
  static Future<void> selection() async {
    try {
      await HapticFeedback.selectionClick();
    } catch (_) {}
  }
}
