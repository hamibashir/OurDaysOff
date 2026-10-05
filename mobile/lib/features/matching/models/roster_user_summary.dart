class RosterUserSummary {
  final int id;
  final String name;
  final String? handle;
  final String initials;

  const RosterUserSummary({
    required this.id,
    required this.name,
    this.handle,
    required this.initials,
  });

  String get displayHandle => handle != null && handle!.isNotEmpty ? '@$handle' : '';

  factory RosterUserSummary.fromJson(Map<String, dynamic> json) {
    return RosterUserSummary(
      id: json['id'] as int? ?? 0,
      name: json['name'] as String? ?? 'Member',
      handle: json['handle'] as String?,
      initials: json['initials'] as String? ?? 'M',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'handle': handle,
      'initials': initials,
    };
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is RosterUserSummary &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          name == other.name &&
          handle == other.handle &&
          initials == other.initials;

  @override
  int get hashCode =>
      id.hashCode ^
      name.hashCode ^
      (handle?.hashCode ?? 0) ^
      initials.hashCode;
}
