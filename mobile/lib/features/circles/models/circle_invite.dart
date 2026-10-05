class CircleInvite {
  final String inviteCode;
  final String inviteUrl;
  final DateTime? expiresAt;
  final int? maxUses;
  final int uses;

  const CircleInvite({
    required this.inviteCode,
    required this.inviteUrl,
    this.expiresAt,
    this.maxUses,
    this.uses = 0,
  });

  bool get isExpired => expiresAt != null && expiresAt!.isBefore(DateTime.now());
  bool get isMaxed => maxUses != null && uses >= maxUses!;
  bool get isValid => !isExpired && !isMaxed;

  factory CircleInvite.fromJson(Map<String, dynamic> json) {
    return CircleInvite(
      inviteCode: json['invite_code'] as String? ?? '',
      inviteUrl: json['invite_url'] as String? ?? '',
      expiresAt: json['expires_at'] != null ? DateTime.tryParse(json['expires_at'].toString()) : null,
      maxUses: json['max_uses'] as int?,
      uses: json['uses'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'invite_code': inviteCode,
      'invite_url': inviteUrl,
      'expires_at': expiresAt?.toIso8601String(),
      'max_uses': maxUses,
      'uses': uses,
    };
  }
}
