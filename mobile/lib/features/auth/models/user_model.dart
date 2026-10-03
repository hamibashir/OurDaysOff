class UserModel {
  final int id;
  final String name;
  final String email;
  final String? handle;
  final String? handleVisibility;
  final bool isPremium;
  final bool isAdmin;
  final String? timezone;
  final DateTime? createdAt;

  const UserModel({
    required this.id,
    required this.name,
    required this.email,
    this.handle,
    this.handleVisibility = 'public',
    this.isPremium = false,
    this.isAdmin = false,
    this.timezone,
    this.createdAt,
  });

  /// Derive user initials (e.g. "John Doe" -> "JD")
  String get initials {
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty || parts[0].isEmpty) return 'U';
    if (parts.length == 1) return parts[0][0].toUpperCase();
    return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
  }

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] as int,
      name: json['name'] as String? ?? '',
      email: json['email'] as String? ?? '',
      handle: json['handle'] as String?,
      handleVisibility: json['handle_visibility'] as String? ?? 'public',
      isPremium: json['is_premium'] == true || json['is_premium'] == 1,
      isAdmin: json['is_admin'] == true || json['is_admin'] == 1,
      timezone: json['timezone'] as String?,
      createdAt: json['created_at'] != null ? DateTime.tryParse(json['created_at'].toString()) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'handle': handle,
      'handle_visibility': handleVisibility,
      'is_premium': isPremium,
      'is_admin': isAdmin,
      'timezone': timezone,
      'created_at': createdAt?.toIso8601String(),
    };
  }

  UserModel copyWith({
    int? id,
    String? name,
    String? email,
    String? handle,
    String? handleVisibility,
    bool? isPremium,
    bool? isAdmin,
    String? timezone,
    DateTime? createdAt,
  }) {
    return UserModel(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      handle: handle ?? this.handle,
      handleVisibility: handleVisibility ?? this.handleVisibility,
      isPremium: isPremium ?? this.isPremium,
      isAdmin: isAdmin ?? this.isAdmin,
      timezone: timezone ?? this.timezone,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is UserModel &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          name == other.name &&
          email == other.email &&
          handle == other.handle &&
          isPremium == other.isPremium &&
          isAdmin == other.isAdmin;

  @override
  int get hashCode => Object.hash(id, name, email, handle, isPremium, isAdmin);
}
