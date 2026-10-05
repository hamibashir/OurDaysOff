import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:our_days_off/core/theme/app_colors.dart';
import 'package:our_days_off/features/schedule/models/availability_block.dart';
import 'package:our_days_off/features/schedule/models/schedule_entry.dart';
import 'package:our_days_off/features/schedule/models/shift_template.dart';

void main() {
  group('ShiftTemplate Model Tests', () {
    test('parses from backend JSON and derives color and display times', () {
      final json = {
        'id': 10,
        'user_id': 1,
        'name': 'Day Shift',
        'start_time': '07:00:00',
        'end_time': '15:30:00',
        'is_overnight': false,
        'color': '#2B7A72',
      };

      final template = ShiftTemplate.fromJson(json);

      expect(template.id, 10);
      expect(template.name, 'Day Shift');
      expect(template.startTime, '07:00:00');
      expect(template.endTime, '15:30:00');
      expect(template.isOvernight, false);
      expect(template.colorValue, const Color(0xFF2B7A72));
      expect(template.displayTimeRange, '07:00 – 15:30');

      final serialized = template.toJson();
      expect(serialized['id'], 10);
      expect(serialized['name'], 'Day Shift');
      expect(serialized['color'], '#2B7A72');
    });

    test('handles fallback colors when color string is empty or invalid', () {
      const template = ShiftTemplate(
        id: 2,
        name: 'Night Watch',
        startTime: '22:00',
        endTime: '06:00',
        isOvernight: true,
        color: 'invalid',
      );

      expect(template.colorValue, AppColors.statusOvernight);
      expect(template.displayTimeRange, '22:00 – 06:00');
    });
  });

  group('ScheduleEntry Model Tests', () {
    test('parses from backend JSON with nested shift template', () {
      final json = {
        'id': 42,
        'user_id': 5,
        'shift_template_id': 10,
        'shift_template': {
          'id': 10,
          'name': 'Early Bird',
          'start_time': '06:00',
          'end_time': '14:00',
          'is_overnight': false,
          'color': '#3B82F6',
        },
        'date': '2026-10-15',
        'start_time': '06:00:00',
        'end_time': '14:00:00',
        'timezone': 'UTC',
        'entry_type': 'work',
        'label': 'Custom Rota Shift',
        'notes': 'Ward 4B coverage',
        'is_overnight': false,
        'source': 'import',
      };

      final entry = ScheduleEntry.fromJson(json);

      expect(entry.id, 42);
      expect(entry.date, DateTime(2026, 10, 15));
      expect(entry.shiftTemplate?.name, 'Early Bird');
      expect(entry.displayTitle, 'Custom Rota Shift');
      expect(entry.displayTimeRange, '06:00 – 14:00');
      expect(entry.isDayOff, false);
      expect(entry.displayColor, const Color(0xFF3B82F6));
    });

    test('correctly identifies days off and formats display for off time', () {
      final json = {
        'id': 55,
        'user_id': 5,
        'date': '2026-10-16',
        'start_time': '00:00',
        'end_time': '24:00',
        'entry_type': 'off',
        'is_overnight': false,
      };

      final entry = ScheduleEntry.fromJson(json);

      expect(entry.isDayOff, true);
      expect(entry.displayTitle, 'Day Off');
      expect(entry.displayTimeRange, 'All Day');
      expect(entry.displayColor, AppColors.statusAvailable);
    });

    test('overnight shift displays (+1d) tag', () {
      final json = {
        'id': 60,
        'user_id': 5,
        'date': '2026-10-17',
        'start_time': '21:00',
        'end_time': '07:00',
        'entry_type': 'work',
        'is_overnight': true,
      };

      final entry = ScheduleEntry.fromJson(json);

      expect(entry.isOvernight, true);
      expect(entry.displayTimeRange, '21:00 – 07:00 (+1d)');
      expect(entry.displayColor, AppColors.statusOvernight);
    });
  });

  group('AvailabilityBlock & AvailabilityOverride Tests', () {
    test('AvailabilityBlock parses status and time windows', () {
      final block = AvailabilityBlock.fromJson({
        'start': '14:00:00',
        'end': '22:00:00',
        'status': 'available',
        'reason': 'Between shifts',
      });

      expect(block.isAvailable, true);
      expect(block.cleanStartTime, '14:00');
      expect(block.cleanEndTime, '22:00');
      expect(block.reason, 'Between shifts');
    });

    test('AvailabilityOverride parses date and properties correctly', () {
      final override = AvailabilityOverride.fromJson({
        'id': 1,
        'user_id': 10,
        'date': '2026-10-20',
        'status': 'unavailable',
        'reason': 'Family doctor visit',
      });

      expect(override.id, 1);
      expect(override.date, DateTime(2026, 10, 20));
      expect(override.isAvailable, false);
      expect(override.reason, 'Family doctor visit');
    });
  });
}
