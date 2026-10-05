import '../../auth/models/user_model.dart';

class PlanMessageModel {
  final int id;
  final int planId;
  final int userId;
  final String body;
  final DateTime createdAt;
  final UserModel? user;

  const PlanMessageModel({
    required this.id,
    required this.planId,
    required this.userId,
    required this.body,
    required this.createdAt,
    this.user,
  });

  String get authorName => user?.name ?? 'User #$userId';
  String? get authorHandle => user?.handle;
  String get authorInitials => user?.initials ?? 'U';

  factory PlanMessageModel.fromJson(Map<String, dynamic> json) {
    return PlanMessageModel(
      id: json['id'] as int? ?? 0,
      planId: json['plan_id'] as int? ?? 0,
      userId: json['user_id'] as int? ?? 0,
      body: json['body'] as String? ?? '',
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString()) ?? DateTime.now()
          : DateTime.now(),
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
      'body': body,
      'created_at': createdAt.toIso8601String(),
      if (user != null) 'user': user!.toJson(),
    };
  }

  PlanMessageModel copyWith({
    int? id,
    int? planId,
    int? userId,
    String? body,
    DateTime? createdAt,
    UserModel? user,
  }) {
    return PlanMessageModel(
      id: id ?? this.id,
      planId: planId ?? this.planId,
      userId: userId ?? this.userId,
      body: body ?? this.body,
      createdAt: createdAt ?? this.createdAt,
      user: user ?? this.user,
    );
  }
}
