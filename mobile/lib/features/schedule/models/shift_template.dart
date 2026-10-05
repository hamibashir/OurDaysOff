import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/date_time_utils.dart';

class ShiftTemplate {
  final int id;
  final int? userId;
  final String name;
  final String startTime;
  final String endTime;
  final bool isOvernight;
  final String color;

  const ShiftTemplate({
    required this.id,
    this.userId,
    required this.name,
    required this.startTime,
    required this.endTime,
    this.isOvernight = false,
    this.color = '#3B82F6',
  });

  /// Parse the hex string into a Flutter Color object
  Color get colorValue {
    try {
      final hex = color.replaceAll('#', '');
      if (hex.length == 6) {
        return Color(int.parse('FF$hex', radix: 16));
      }
      if (hex.length == 8) {
        return Color(int.parse(hex, radix: 16));
      }
    } catch (_) {}
    return isOvernight ? AppColors.statusOvernight : AppColors.statusBusy;
  }

  /// Formatted time range (e.g. "07:00 - 15:00")
  String get displayTimeRange {
    final start = DateTimeUtils.cleanTime(startTime);
    final end = DateTimeUtils.cleanTime(endTime);
    return '$start – $end';
  }

  factory ShiftTemplate.fromJson(Map<String, dynamic> json) {
    return ShiftTemplate(
      id: json['id'] as int,
      userId: json['user_id'] as int?,
      name: json['name'] as String? ?? 'Shift',
      startTime: json['start_time'] as String? ?? '09:00',
      endTime: json['end_time'] as String? ?? '17:00',
      isOvernight: json['is_overnight'] == true || json['is_overnight'] == 1,
      color: json['color'] as String? ?? '#3B82F6',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      if (userId != null) 'user_id': userId,
      'name': name,
      'start_time': startTime,
      'end_time': endTime,
      'is_overnight': isOvernight,
      'color': color,
    };
  }

  ShiftTemplate copyWith({
    int? id,
    int? userId,
    String? name,
    String? startTime,
    String? endTime,
    bool? isOvernight,
    String? color,
  }) {
    return ShiftTemplate(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      name: name ?? this.name,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      isOvernight: isOvernight ?? this.isOvernight,
      color: color ?? this.color,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ShiftTemplate &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          name == other.name &&
          startTime == other.startTime &&
          endTime == other.endTime &&
          isOvernight == other.isOvernight &&
          color == other.color;

  @override
  int get hashCode => Object.hash(id, name, startTime, endTime, isOvernight, color);
}
