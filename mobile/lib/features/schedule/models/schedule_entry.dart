import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/date_time_utils.dart';
import 'shift_template.dart';

class ScheduleEntry {
  final int id;
  final int userId;
  final int? shiftTemplateId;
  final ShiftTemplate? shiftTemplate;
  final DateTime date;
  final String startTime;
  final String endTime;
  final String? timezone;
  final String entryType;
  final String? label;
  final String? notes;
  final bool isOvernight;
  final String? source;

  const ScheduleEntry({
    required this.id,
    required this.userId,
    this.shiftTemplateId,
    this.shiftTemplate,
    required this.date,
    required this.startTime,
    required this.endTime,
    this.timezone = 'UTC',
    this.entryType = 'work',
    this.label,
    this.notes,
    this.isOvernight = false,
    this.source = 'manual',
  });

  /// Check whether this entry represents a full or partial day off
  bool get isDayOff => entryType == 'off' || entryType == 'leave';

  /// Primary title to render in calendar views and cards
  String get displayTitle {
    if (label != null && label!.trim().isNotEmpty) {
      return label!;
    }
    if (shiftTemplate != null && shiftTemplate!.name.trim().isNotEmpty) {
      return shiftTemplate!.name;
    }
    return switch (entryType) {
      'off' => 'Day Off',
      'leave' => 'Leave / Vacation',
      'personal' => 'Personal Time',
      'work' => 'Work Shift',
      _ => 'Scheduled Shift',
    };
  }

  /// Theme color derived from shift template or entry status
  Color get displayColor {
    if (shiftTemplate != null) {
      return shiftTemplate!.colorValue;
    }
    if (isOvernight) return AppColors.statusOvernight;
    return switch (entryType) {
      'off' => AppColors.statusAvailable,
      'leave' => AppColors.statusLeave,
      'personal' => AppColors.accentViolet,
      _ => AppColors.statusBusy,
    };
  }

  /// Formatted time range (e.g. "07:00 – 15:00")
  String get displayTimeRange {
    if (isDayOff) return 'All Day';
    final start = DateTimeUtils.cleanTime(startTime);
    final end = DateTimeUtils.cleanTime(endTime);
    return isOvernight ? '$start – $end (+1d)' : '$start – $end';
  }

  factory ScheduleEntry.fromJson(Map<String, dynamic> json) {
    DateTime parsedDate;
    final rawDate = json['date'];
    if (rawDate is String) {
      parsedDate = DateTimeUtils.parseYmd(rawDate) ?? DateTime.now();
    } else if (rawDate is DateTime) {
      parsedDate = rawDate;
    } else {
      parsedDate = DateTime.now();
    }

    ShiftTemplate? template;
    if (json['shift_template'] is Map<String, dynamic>) {
      template = ShiftTemplate.fromJson(json['shift_template'] as Map<String, dynamic>);
    } else if (json['shiftTemplate'] is Map<String, dynamic>) {
      template = ShiftTemplate.fromJson(json['shiftTemplate'] as Map<String, dynamic>);
    }

    return ScheduleEntry(
      id: json['id'] as int,
      userId: json['user_id'] as int? ?? 0,
      shiftTemplateId: json['shift_template_id'] as int?,
      shiftTemplate: template,
      date: DateTimeUtils.dateOnly(parsedDate),
      startTime: json['start_time'] as String? ?? '00:00',
      endTime: json['end_time'] as String? ?? '00:00',
      timezone: json['timezone'] as String? ?? 'UTC',
      entryType: json['entry_type'] as String? ?? 'work',
      label: json['label'] as String?,
      notes: json['notes'] as String?,
      isOvernight: json['is_overnight'] == true || json['is_overnight'] == 1,
      source: json['source'] as String? ?? 'manual',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'shift_template_id': shiftTemplateId,
      if (shiftTemplate != null) 'shift_template': shiftTemplate!.toJson(),
      'date': DateTimeUtils.formatYmd(date),
      'start_time': startTime,
      'end_time': endTime,
      'timezone': timezone,
      'entry_type': entryType,
      'label': label,
      'notes': notes,
      'is_overnight': isOvernight,
      'source': source,
    };
  }

  ScheduleEntry copyWith({
    int? id,
    int? userId,
    int? shiftTemplateId,
    ShiftTemplate? shiftTemplate,
    DateTime? date,
    String? startTime,
    String? endTime,
    String? timezone,
    String? entryType,
    String? label,
    String? notes,
    bool? isOvernight,
    String? source,
  }) {
    return ScheduleEntry(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      shiftTemplateId: shiftTemplateId ?? this.shiftTemplateId,
      shiftTemplate: shiftTemplate ?? this.shiftTemplate,
      date: date != null ? DateTimeUtils.dateOnly(date) : this.date,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      timezone: timezone ?? this.timezone,
      entryType: entryType ?? this.entryType,
      label: label ?? this.label,
      notes: notes ?? this.notes,
      isOvernight: isOvernight ?? this.isOvernight,
      source: source ?? this.source,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ScheduleEntry &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          userId == other.userId &&
          date == other.date &&
          startTime == other.startTime &&
          endTime == other.endTime &&
          entryType == other.entryType &&
          isOvernight == other.isOvernight;

  @override
  int get hashCode => Object.hash(id, userId, date, startTime, endTime, entryType, isOvernight);
}
