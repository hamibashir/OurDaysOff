class DeviceModel {
  final int id;
  final int userId;
  final String deviceName;
  final String deviceType;
  final String? deviceIdentifier;
  final String? pairingCode;
  final DateTime? pairingCodeExpiresAt;
  final DateTime? lastSeenAt;
  final DateTime? createdAt;

  const DeviceModel({
    required this.id,
    required this.userId,
    required this.deviceName,
    required this.deviceType,
    this.deviceIdentifier,
    this.pairingCode,
    this.pairingCodeExpiresAt,
    this.lastSeenAt,
    this.createdAt,
  });

  factory DeviceModel.fromJson(Map<String, dynamic> json) {
    return DeviceModel(
      id: json['id'] as int,
      userId: json['user_id'] as int? ?? 0,
      deviceName: json['device_name'] as String? ?? 'Unknown Device',
      deviceType: json['device_type'] as String? ?? 'flutter',
      deviceIdentifier: json['device_identifier'] as String?,
      pairingCode: json['pairing_code'] as String?,
      pairingCodeExpiresAt: json['pairing_code_expires_at'] != null
          ? DateTime.tryParse(json['pairing_code_expires_at'].toString())
          : null,
      lastSeenAt: json['last_seen_at'] != null
          ? DateTime.tryParse(json['last_seen_at'].toString())
          : null,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString())
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'device_name': deviceName,
      'device_type': deviceType,
      'device_identifier': deviceIdentifier,
      'pairing_code': pairingCode,
      'pairing_code_expires_at': pairingCodeExpiresAt?.toIso8601String(),
      'last_seen_at': lastSeenAt?.toIso8601String(),
      'created_at': createdAt?.toIso8601String(),
    };
  }
}

class PairingCodeResponse {
  final String pairingCode;
  final DateTime expiresAt;
  final String message;

  const PairingCodeResponse({
    required this.pairingCode,
    required this.expiresAt,
    required this.message,
  });

  factory PairingCodeResponse.fromJson(Map<String, dynamic> json) {
    return PairingCodeResponse(
      pairingCode: json['pairing_code'] as String? ?? '',
      expiresAt: DateTime.tryParse(json['expires_at']?.toString() ?? '') ??
          DateTime.now().add(const Duration(minutes: 10)),
      message: json['message'] as String? ?? 'Pairing code generated',
    );
  }
}
