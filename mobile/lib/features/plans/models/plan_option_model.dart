class PlanOptionModel {
  final int id;
  final int planId;
  final DateTime startAt;
  final DateTime endAt;
  final String timezone;

  const PlanOptionModel({
    required this.id,
    required this.planId,
    required this.startAt,
    required this.endAt,
    this.timezone = 'UTC',
  });

  Duration get duration => endAt.difference(startAt);

  factory PlanOptionModel.fromJson(Map<String, dynamic> json) {
    return PlanOptionModel(
      id: json['id'] as int? ?? 0,
      planId: json['plan_id'] as int? ?? 0,
      startAt: json['start_at'] != null
          ? DateTime.tryParse(json['start_at'].toString()) ?? DateTime.now()
          : DateTime.now(),
      endAt: json['end_at'] != null
          ? DateTime.tryParse(json['end_at'].toString()) ?? DateTime.now()
          : DateTime.now(),
      timezone: json['timezone'] as String? ?? 'UTC',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'plan_id': planId,
      'start_at': startAt.toIso8601String(),
      'end_at': endAt.toIso8601String(),
      'timezone': timezone,
    };
  }

  PlanOptionModel copyWith({
    int? id,
    int? planId,
    DateTime? startAt,
    DateTime? endAt,
    String? timezone,
  }) {
    return PlanOptionModel(
      id: id ?? this.id,
      planId: planId ?? this.planId,
      startAt: startAt ?? this.startAt,
      endAt: endAt ?? this.endAt,
      timezone: timezone ?? this.timezone,
    );
  }
}
