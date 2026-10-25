class AdminStats {
  final int totalUsers;
  final int premiumUsers;
  final int totalCircles;
  final int totalPlans;
  final int totalSchedules;
  final int activeCoupons;

  const AdminStats({
    required this.totalUsers,
    required this.premiumUsers,
    required this.totalCircles,
    required this.totalPlans,
    required this.totalSchedules,
    required this.activeCoupons,
  });

  factory AdminStats.fromJson(Map<String, dynamic> json) {
    return AdminStats(
      totalUsers: json['total_users'] as int? ?? 0,
      premiumUsers: json['premium_users'] as int? ?? 0,
      totalCircles: json['total_circles'] as int? ?? 0,
      totalPlans: json['total_plans'] as int? ?? 0,
      totalSchedules: json['total_schedules'] as int? ?? 0,
      activeCoupons: json['active_coupons'] as int? ?? 0,
    );
  }
}

class AdminUser {
  final int id;
  final String name;
  final String email;
  final String? handle;
  final bool isPremium;
  final bool isAdmin;
  final DateTime? createdAt;

  const AdminUser({
    required this.id,
    required this.name,
    required this.email,
    this.handle,
    required this.isPremium,
    required this.isAdmin,
    this.createdAt,
  });

  factory AdminUser.fromJson(Map<String, dynamic> json) {
    return AdminUser(
      id: json['id'] as int,
      name: json['name'] as String? ?? 'Anonymous',
      email: json['email'] as String? ?? '',
      handle: json['handle'] as String?,
      isPremium: json['is_premium'] == true || json['is_premium'] == 1,
      isAdmin: json['is_admin'] == true || json['is_admin'] == 1,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString())
          : null,
    );
  }

  AdminUser copyWith({
    bool? isPremium,
    bool? isAdmin,
  }) {
    return AdminUser(
      id: id,
      name: name,
      email: email,
      handle: handle,
      isPremium: isPremium ?? this.isPremium,
      isAdmin: isAdmin ?? this.isAdmin,
      createdAt: createdAt,
    );
  }

  String get initials {
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty || parts[0].isEmpty) return '?';
    if (parts.length == 1) return parts[0][0].toUpperCase();
    return '${parts[0][0]}${parts[parts.length - 1][0]}'.toUpperCase();
  }
}

class AdminCoupon {
  final int id;
  final String code;
  final bool isActive;
  final bool isUsed;
  final int? usedBy;
  final DateTime? expiresAt;
  final DateTime? createdAt;

  const AdminCoupon({
    required this.id,
    required this.code,
    required this.isActive,
    required this.isUsed,
    this.usedBy,
    this.expiresAt,
    this.createdAt,
  });

  factory AdminCoupon.fromJson(Map<String, dynamic> json) {
    return AdminCoupon(
      id: json['id'] as int,
      code: json['code'] as String? ?? '',
      isActive: json['is_active'] == true || json['is_active'] == 1,
      isUsed: json['is_used'] == true || json['is_used'] == 1,
      usedBy: json['used_by'] as int?,
      expiresAt: json['expires_at'] != null
          ? DateTime.tryParse(json['expires_at'].toString())
          : null,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString())
          : null,
    );
  }

  AdminCoupon copyWith({
    bool? isActive,
    bool? isUsed,
  }) {
    return AdminCoupon(
      id: id,
      code: code,
      isActive: isActive ?? this.isActive,
      isUsed: isUsed ?? this.isUsed,
      usedBy: usedBy,
      expiresAt: expiresAt,
      createdAt: createdAt,
    );
  }

  bool get isExpired {
    if (expiresAt == null) return false;
    return expiresAt!.isBefore(DateTime.now());
  }
}

class AdminCircle {
  final int id;
  final String name;
  final String? handle;
  final String? ownerName;
  final int membersCount;
  final bool isDiscoverable;
  final DateTime? createdAt;

  const AdminCircle({
    required this.id,
    required this.name,
    this.handle,
    this.ownerName,
    required this.membersCount,
    required this.isDiscoverable,
    this.createdAt,
  });

  factory AdminCircle.fromJson(Map<String, dynamic> json) {
    String? owner;
    if (json['owner'] is Map<String, dynamic>) {
      owner = json['owner']['name'] as String?;
    }

    return AdminCircle(
      id: json['id'] as int,
      name: json['name'] as String? ?? 'Unnamed Circle',
      handle: json['handle'] as String?,
      ownerName: owner,
      membersCount: json['members_count'] as int? ?? 1,
      isDiscoverable: json['is_discoverable'] == true || json['is_discoverable'] == 1,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString())
          : null,
    );
  }
}
