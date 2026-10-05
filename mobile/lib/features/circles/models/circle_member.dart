import '../../auth/models/user_model.dart';

class CircleMember {
  final int id;
  final int circleId;
  final int userId;
  final String role; // 'owner' | 'admin' | 'member'
  final String memberType; // 'working' | 'viewer'
  final String visibility; // 'free_busy' | 'shifts' | 'details'
  final String status; // 'active' | 'pending' | 'removed'
  final DateTime? joinedAt;
  final UserModel? user;

  const CircleMember({
    required this.id,
    required this.circleId,
    required this.userId,
    this.role = 'member',
    this.memberType = 'working',
    this.visibility = 'free_busy',
    this.status = 'active',
    this.joinedAt,
    this.user,
  });

  bool get isOwner => role.toLowerCase() == 'owner';
  bool get isAdmin => role.toLowerCase() == 'admin';
  bool get isOwnerOrAdmin => isOwner || isAdmin;
  bool get isWorking => memberType.toLowerCase() == 'working';

  String get displayName => user?.name ?? 'Member #$userId';
  String? get handle => user?.handle;
  String get initials => user?.initials ?? 'M';

  factory CircleMember.fromJson(Map<String, dynamic> json) {
    return CircleMember(
      id: json['id'] as int? ?? 0,
      circleId: json['circle_id'] as int? ?? 0,
      userId: json['user_id'] as int? ?? 0,
      role: json['role'] as String? ?? 'member',
      memberType: json['member_type'] as String? ?? 'working',
      visibility: json['visibility'] as String? ?? 'free_busy',
      status: json['status'] as String? ?? 'active',
      joinedAt: json['joined_at'] != null ? DateTime.tryParse(json['joined_at'].toString()) : null,
      user: json['user'] is Map<String, dynamic> ? UserModel.fromJson(json['user'] as Map<String, dynamic>) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'circle_id': circleId,
      'user_id': userId,
      'role': role,
      'member_type': memberType,
      'visibility': visibility,
      'status': status,
      'joined_at': joinedAt?.toIso8601String(),
      if (user != null) 'user': user!.toJson(),
    };
  }

  CircleMember copyWith({
    int? id,
    int? circleId,
    int? userId,
    String? role,
    String? memberType,
    String? visibility,
    String? status,
    DateTime? joinedAt,
    UserModel? user,
  }) {
    return CircleMember(
      id: id ?? this.id,
      circleId: circleId ?? this.circleId,
      userId: userId ?? this.userId,
      role: role ?? this.role,
      memberType: memberType ?? this.memberType,
      visibility: visibility ?? this.visibility,
      status: status ?? this.status,
      joinedAt: joinedAt ?? this.joinedAt,
      user: user ?? this.user,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CircleMember &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          circleId == other.circleId &&
          userId == other.userId &&
          role == other.role &&
          memberType == other.memberType &&
          visibility == other.visibility &&
          status == other.status;

  @override
  int get hashCode =>
      id.hashCode ^
      circleId.hashCode ^
      userId.hashCode ^
      role.hashCode ^
      memberType.hashCode ^
      visibility.hashCode ^
      status.hashCode;
}
