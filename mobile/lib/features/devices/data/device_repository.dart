import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_client.dart';
import '../../auth/models/auth_response.dart';
import '../models/device_model.dart';

final deviceRepositoryProvider = Provider<DeviceRepository>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return DeviceRepository(apiClient: apiClient);
});

class DeviceRepository {
  final ApiClient apiClient;

  DeviceRepository({required this.apiClient});

  /// Get list of user's registered companion devices
  Future<List<DeviceModel>> getDevices() async {
    final response = await apiClient.get('/devices');
    if (response is Map<String, dynamic> && response['data'] is List) {
      final list = response['data'] as List;
      return list
          .map((item) => DeviceModel.fromJson(item as Map<String, dynamic>))
          .toList();
    }
    return [];
  }

  /// Generate a 6-digit sync pairing code valid for 10 minutes
  Future<PairingCodeResponse> generatePairingCode() async {
    final response = await apiClient.post('/devices/pairing-code');
    if (response is Map<String, dynamic>) {
      return PairingCodeResponse.fromJson(response);
    }
    throw Exception('Failed to generate pairing code');
  }

  /// Pair device using 6-digit code (can be called unauthenticated or authenticated)
  Future<AuthResponse> pairDevice({
    required String pairingCode,
    required String deviceName,
    required String deviceType,
    required String deviceIdentifier,
  }) async {
    final response = await apiClient.post(
      '/devices/pair',
      data: {
        'pairing_code': pairingCode.trim().toUpperCase(),
        'device_name': deviceName,
        'device_type': deviceType,
        'device_identifier': deviceIdentifier,
      },
    );

    if (response is Map<String, dynamic>) {
      return AuthResponse.fromJson(response);
    }
    throw Exception('Failed to pair device');
  }

  /// Revoke / delete a companion device
  Future<void> revokeDevice(int deviceId) async {
    await apiClient.delete('/devices/$deviceId');
  }
}
