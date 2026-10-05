import '../../../core/utils/date_time_utils.dart';

class AvailabilityBlock {
  final String start;
  final String end;
  final String status;
  final String? reason;
  final String? shiftType;

  const AvailabilityBlock({
    required this.start,
    required this.end,
    this.status = 'available',
    this.reason,
    this.shiftType,
  });

  bool get isAvailable => status == 'available';

  String get cleanStartTime => DateTimeUtils.cleanTime(start);
  String get cleanEndTime => DateTimeUtils.cleanTime(end);

  factory AvailabilityBlock.fromJson(Map<String, dynamic> json) {
    return AvailabilityBlock(
      start: json['start'] as String? ?? '00:00',
      end: json['end'] as String? ?? '24:00',
      status: json['status'] as String? ?? 'available',
      reason: json['reason'] as String?,
      shiftType: json['shift_type'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'start': start,
      'end': end,
      'status': status,
      if (reason != null) 'reason': reason,
      if (shiftType != null) 'shift_type': shiftType,
    };
  }
}

class AvailabilityOverride {
  final int id;
  final int userId;
  final DateTime date;
  final String? startTime;
  final String? endTime;
  final String status;
  final String? reason;

  const AvailabilityOverride({
    required this.id,
    required this.userId,
    required this.date,
    this.startTime,
    this.endTime,
    this.status = 'available',
    this.reason,
  });

  bool get isAvailable => status == 'available';

  factory AvailabilityOverride.fromJson(Map<String, dynamic> json) {
    DateTime parsedDate;
    final rawDate = json['date'];
    if (rawDate is String) {
      parsedDate = DateTimeUtils.parseYmd(rawDate) ?? DateTime.now();
    } else if (rawDate is DateTime) {
      parsedDate = rawDate;
    } else {
      parsedDate = DateTime.now();
    }

    return AvailabilityOverride(
      id: json['id'] as int,
      userId: json['user_id'] as int? ?? 0,
      date: DateTimeUtils.dateOnly(parsedDate),
      startTime: json['start_time'] as String?,
      endTime: json['end_time'] as String?,
      status: json['status'] as String? ?? 'available',
      reason: json['reason'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'date': DateTimeUtils.formatYmd(date),
      if (startTime != null) 'start_time': startTime,
      if (endTime != null) 'end_time': endTime,
      'status': status,
      if (reason != null) 'reason': reason,
    };
  }
}
