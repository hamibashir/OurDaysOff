import '../../auth/models/user_model.dart';
import 'circle_member.dart';

class CircleModel {
  final int id;
  final int ownerId;
  final String name;
  final String? handle;
  final String discoverability; // 'private' | 'searchable'
  final DateTime? createdAt;
  final int membersCount;
  final String myRole; // 'owner' | 'admin' | 'member'
  final String myMemberType; // 'working' | 'viewer'
  final String myVisibility; // 'free_busy' | 'shifts' | 'details'
  final List<CircleMember> members;
  final UserModel? owner;

  const CircleModel({
    required this.id,
    required this.ownerId,
    required this.name,
    this.handle,
    this.discoverability = 'private',
    this.createdAt,
    this.membersCount = 1,
    this.myRole = 'member',
    this.myMemberType = 'working',
    this.myVisibility = 'free_busy',
    this.members = const [],
    this.owner,
  });

  bool get isOwner => myRole.toLowerCase() == 'owner';
  bool get isAdmin => myRole.toLowerCase() == 'admin';
  bool get isOwnerOrAdmin => isOwner || isAdmin;
  bool get isPrivate => discoverability.toLowerCase() == 'private';
  bool get isSearchable => discoverability.toLowerCase() == 'searchable';

  String get displayHandle => handle != null && handle!.isNotEmpty ? '@$handle' : '';

  factory CircleModel.fromJson(Map<String, dynamic> json) {
    var rawMembers = json['members'];
    List<CircleMember> parsedMembers = [];
    if (rawMembers is List) {
      parsedMembers = rawMembers
          .whereType<Map<String, dynamic>>()
          .map((m) => CircleMember.fromJson(m))
          .toList();
    }

    int count = json['members_count'] as int? ?? parsedMembers.length;
    if (count == 0 && parsedMembers.isNotEmpty) {
      count = parsedMembers.length;
    }

    return CircleModel(
      id: json['id'] as int? ?? 0,
      ownerId: json['owner_id'] as int? ?? 0,
      name: json['name'] as String? ?? 'Untitled Circle',
      handle: json['handle'] as String?,
      discoverability: json['discoverability'] as String? ?? 'private',
      createdAt: json['created_at'] != null ? DateTime.tryParse(json['created_at'].toString()) : null,
      membersCount: count,
      myRole: json['my_role'] as String? ?? 'member',
      myMemberType: json['my_member_type'] as String? ?? 'working',
      myVisibility: json['my_visibility'] as String? ?? 'free_busy',
      members: parsedMembers,
      owner: json['owner'] is Map<String, dynamic> ? UserModel.fromJson(json['owner'] as Map<String, dynamic>) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'owner_id': ownerId,
      'name': name,
      'handle': handle,
      'discoverability': discoverability,
      'created_at': createdAt?.toIso8601String(),
      'members_count': membersCount,
      'my_role': myRole,
      'my_member_type': myMemberType,
      'my_visibility': myVisibility,
      'members': members.map((m) => m.toJson()).toList(),
      if (owner != null) 'owner': owner!.toJson(),
    };
  }

  CircleModel copyWith({
    int? id,
    int? ownerId,
    String? name,
    String? handle,
    String? discoverability,
    DateTime? createdAt,
    int? membersCount,
    String? myRole,
    String? myMemberType,
    String? myVisibility,
    List<CircleMember>? members,
    UserModel? owner,
  }) {
    return CircleModel(
      id: id ?? this.id,
      ownerId: ownerId ?? this.ownerId,
      name: name ?? this.name,
      handle: handle ?? this.handle,
      discoverability: discoverability ?? this.discoverability,
      createdAt: createdAt ?? this.createdAt,
      membersCount: membersCount ?? this.membersCount,
      myRole: myRole ?? this.myRole,
      myMemberType: myMemberType ?? this.myMemberType,
      myVisibility: myVisibility ?? this.myVisibility,
      members: members ?? this.members,
      owner: owner ?? this.owner,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CircleModel &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          ownerId == other.ownerId &&
          name == other.name &&
          handle == other.handle &&
          discoverability == other.discoverability &&
          myRole == other.myRole;

  @override
  int get hashCode =>
      id.hashCode ^
      ownerId.hashCode ^
      name.hashCode ^
      handle.hashCode ^
      discoverability.hashCode ^
      myRole.hashCode;
}
