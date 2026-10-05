class MemberDailyStatus {
  final String status; // 'off' | 'work' | 'leave' | 'study' | 'busy' | 'unknown'
  final String label;
  final String shortCode;
  final bool isDayOff;
  final String? startTime;
  final String? endTime;
  final bool isOvernight;
  final String? notes;

  const MemberDailyStatus({
    required this.status,
    required this.label,
    required this.shortCode,
    required this.isDayOff,
    this.startTime,
    this.endTime,
    this.isOvernight = false,
    this.notes,
  });

  bool get isOff => status.toLowerCase() == 'off';
  bool get isWork => status.toLowerCase() == 'work';
  bool get isLeave => status.toLowerCase() == 'leave';
  bool get isStudy => status.toLowerCase() == 'study';
  bool get isBusy => status.toLowerCase() == 'busy';
  bool get isUnknown => status.toLowerCase() == 'unknown';

  factory MemberDailyStatus.fromJson(Map<String, dynamic> json) {
    return MemberDailyStatus(
      status: json['status'] as String? ?? 'unknown',
      label: json['label'] as String? ?? '',
      shortCode: json['short_code'] as String? ?? '—',
      isDayOff: json['is_day_off'] as bool? ?? false,
      startTime: json['start_time'] as String?,
      endTime: json['end_time'] as String?,
      isOvernight: json['is_overnight'] as bool? ?? false,
      notes: json['notes'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'status': status,
      'label': label,
      'short_code': shortCode,
      'is_day_off': isDayOff,
      'start_time': startTime,
      'end_time': endTime,
      'is_overnight': isOvernight,
      if (notes != null) 'notes': notes,
    };
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MemberDailyStatus &&
          runtimeType == other.runtimeType &&
          status == other.status &&
          shortCode == other.shortCode &&
          isDayOff == other.isDayOff &&
          startTime == other.startTime &&
          endTime == other.endTime &&
          isOvernight == other.isOvernight;

  @override
  int get hashCode =>
      status.hashCode ^
      shortCode.hashCode ^
      isDayOff.hashCode ^
      (startTime?.hashCode ?? 0) ^
      (endTime?.hashCode ?? 0) ^
      isOvernight.hashCode;
}
