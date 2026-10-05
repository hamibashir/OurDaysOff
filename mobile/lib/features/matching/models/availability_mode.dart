import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

enum AvailabilityMode {
  daysOff,
  offTime;

  String get label {
    switch (this) {
      case AvailabilityMode.daysOff:
        return 'Days Off';
      case AvailabilityMode.offTime:
        return 'Off Time';
    }
  }

  String get description {
    switch (this) {
      case AvailabilityMode.daysOff:
        return 'Full days without shifts';
      case AvailabilityMode.offTime:
        return 'Overlapping free hours';
    }
  }

  IconData get icon {
    switch (this) {
      case AvailabilityMode.daysOff:
        return LucideIcons.calendarCheck;
      case AvailabilityMode.offTime:
        return LucideIcons.clock;
    }
  }
}
