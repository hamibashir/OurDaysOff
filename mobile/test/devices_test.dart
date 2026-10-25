import 'package:flutter_test/flutter_test.dart';
import 'package:our_days_off/features/devices/models/device_model.dart';

void main() {
  group('DeviceModel Serialization Tests', () {
    test('DeviceModel parses from Laravel backend JSON correctly', () {
      final json = {
        'id': 42,
        'user_id': 7,
        'device_name': 'Alice’s iPad Pro',
        'device_type': 'ios',
        'device_identifier': 'device_unique_123',
        'pairing_code': '8AB3X9',
        'pairing_code_expires_at': '2026-10-26T12:00:00Z',
        'last_seen_at': '2026-10-26T11:45:00Z',
        'created_at': '2026-10-26T10:00:00Z',
      };

      final device = DeviceModel.fromJson(json);

      expect(device.id, equals(42));
      expect(device.userId, equals(7));
      expect(device.deviceName, equals('Alice’s iPad Pro'));
      expect(device.deviceType, equals('ios'));
      expect(device.deviceIdentifier, equals('device_unique_123'));
      expect(device.pairingCode, equals('8AB3X9'));
      expect(device.pairingCodeExpiresAt, isNotNull);
      expect(device.lastSeenAt, isNotNull);
      expect(device.createdAt, isNotNull);
    });

    test('PairingCodeResponse parses correctly', () {
      final json = {
        'message': 'Pairing code generated',
        'pairing_code': 'K9F2Q8',
        'expires_at': '2026-10-26T12:10:00Z',
      };

      final response = PairingCodeResponse.fromJson(json);

      expect(response.pairingCode, equals('K9F2Q8'));
      expect(response.message, equals('Pairing code generated'));
      expect(response.expiresAt, equals(DateTime.parse('2026-10-26T12:10:00Z')));
    });
  });
}
