class CirclePlanSummary {
  final int id;
  final String title;
  final String eventType;
  final String date;
  final String startTime;
  final String? endTime;
  final String status;
  final String createdBy;
  final int membersCount;

  const CirclePlanSummary({
    required this.id,
    required this.title,
    required this.eventType,
    required this.date,
    required this.startTime,
    this.endTime,
    required this.status,
    required this.createdBy,
    this.membersCount = 1,
  });

  factory CirclePlanSummary.fromJson(Map<String, dynamic> json) {
    return CirclePlanSummary(
      id: json['id'] as int? ?? 0,
      title: json['title'] as String? ?? 'Untitled Plan',
      eventType: json['event_type'] as String? ?? 'social',
      date: json['date'] as String? ?? '',
      startTime: json['start_time'] as String? ?? '00:00',
      endTime: json['end_time'] as String?,
      status: json['status'] as String? ?? 'draft',
      createdBy: json['created_by'] as String? ?? 'Member',
      membersCount: json['members_count'] as int? ?? 1,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'event_type': eventType,
      'date': date,
      'start_time': startTime,
      'end_time': endTime,
      'status': status,
      'created_by': createdBy,
      'members_count': membersCount,
    };
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CirclePlanSummary &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          title == other.title &&
          date == other.date &&
          startTime == other.startTime &&
          status == other.status;

  @override
  int get hashCode =>
      id.hashCode ^
      title.hashCode ^
      date.hashCode ^
      startTime.hashCode ^
      status.hashCode;
}
