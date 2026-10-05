import '../../auth/models/user_model.dart';

class PlanMemberModel {
  final int id;
  final int planId;
  final int userId;
  final String rsvpStatus; // 'attending' | 'tentative' | 'declined' | 'pending'
  final DateTime? respondedAt;
  final UserModel? user;

  const PlanMemberModel({
    required this.id,
    required this.planId,
    required this.userId,
    this.rsvpStatus = 'pending',
    this.respondedAt,
    this.user,
  });

  bool get isAttending => rsvpStatus.toLowerCase() == 'attending';
  bool get isTentative => rsvpStatus.toLowerCase() == 'tentative';
  bool get isDeclined => rsvpStatus.toLowerCase() == 'declined';
  bool get isPending => rsvpStatus.toLowerCase() == 'pending';

  String get displayName => user?.name ?? 'Member #$userId';
  String? get handle => user?.handle;
  String get initials => user?.initials ?? 'M';

  factory PlanMemberModel.fromJson(Map<String, dynamic> json) {
    return PlanMemberModel(
      id: json['id'] as int? ?? 0,
      planId: json['plan_id'] as int? ?? 0,
      userId: json['user_id'] as int? ?? 0,
      rsvpStatus: json['rsvp_status'] as String? ?? 'pending',
      respondedAt: json['responded_at'] != null
          ? DateTime.tryParse(json['responded_at'].toString())
          : null,
      user: json['user'] is Map<String, dynamic>
          ? UserModel.fromJson(json['user'] as Map<String, dynamic>)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'plan_id': planId,
      'user_id': userId,
      'rsvp_status': rsvpStatus,
      'responded_at': respondedAt?.toIso8601String(),
      if (user != null) 'user': user!.toJson(),
    };
  }

  PlanMemberModel copyWith({
    int? id,
    int? planId,
    int? userId,
    String? rsvpStatus,
    DateTime? respondedAt,
    UserModel? user,
  }) {
    return PlanMemberModel(
      id: id ?? this.id,
      planId: planId ?? this.planId,
      userId: userId ?? this.userId,
      rsvpStatus: rsvpStatus ?? this.rsvpStatus,
      respondedAt: respondedAt ?? this.respondedAt,
      user: user ?? this.user,
    );
  }
}
