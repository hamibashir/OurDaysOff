import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/providers/auth_notifier.dart';
import '../data/device_repository.dart';
import '../models/device_model.dart';

class DevicesState {
  final List<DeviceModel> devices;
  final bool isLoading;
  final String? error;
  final PairingCodeResponse? activePairingCode;
  final bool isGeneratingCode;

  const DevicesState({
    this.devices = const [],
    this.isLoading = false,
    this.error,
    this.activePairingCode,
    this.isGeneratingCode = false,
  });

  DevicesState copyWith({
    List<DeviceModel>? devices,
    bool? isLoading,
    String? error,
    PairingCodeResponse? activePairingCode,
    bool? isGeneratingCode,
    bool clearPairingCode = false,
  }) {
    return DevicesState(
      devices: devices ?? this.devices,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      activePairingCode:
          clearPairingCode ? null : (activePairingCode ?? this.activePairingCode),
      isGeneratingCode: isGeneratingCode ?? this.isGeneratingCode,
    );
  }
}

final devicesNotifierProvider =
    StateNotifierProvider<DevicesNotifier, DevicesState>((ref) {
  final repository = ref.watch(deviceRepositoryProvider);
  return DevicesNotifier(repository: repository, ref: ref);
});

class DevicesNotifier extends StateNotifier<DevicesState> {
  final DeviceRepository repository;
  final Ref ref;

  DevicesNotifier({required this.repository, required this.ref})
      : super(const DevicesState()) {
    loadDevices();
  }

  Future<void> loadDevices() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final devices = await repository.getDevices();
      state = state.copyWith(devices: devices, isLoading: false);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString().replaceFirst('Exception: ', ''),
      );
    }
  }

  Future<PairingCodeResponse?> generatePairingCode() async {
    state = state.copyWith(isGeneratingCode: true, error: null);
    try {
      final codeResponse = await repository.generatePairingCode();
      state = state.copyWith(
        activePairingCode: codeResponse,
        isGeneratingCode: false,
      );
      // Reload device list in case pending device was registered
      loadDevices();
      return codeResponse;
    } catch (e) {
      state = state.copyWith(
        isGeneratingCode: false,
        error: e.toString().replaceFirst('Exception: ', ''),
      );
      return null;
    }
  }

  Future<bool> pairWithCode({
    required String pairingCode,
    String? customDeviceName,
  }) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final deviceName = customDeviceName ??
          (Platform.isIOS
              ? 'iOS Device'
              : Platform.isAndroid
                  ? 'Android Device'
                  : 'Mobile Companion');
      final deviceType = Platform.isIOS ? 'ios' : 'android';
      final deviceIdentifier =
          'device_${DateTime.now().millisecondsSinceEpoch}_${(pairingCode.hashCode).abs()}';

      final authResponse = await repository.pairDevice(
        pairingCode: pairingCode,
        deviceName: deviceName,
        deviceType: deviceType,
        deviceIdentifier: deviceIdentifier,
      );

      // Hydrate auth state in app
      await ref.read(authNotifierProvider.notifier).setSession(
            user: authResponse.user,
            token: authResponse.token,
          );

      state = state.copyWith(isLoading: false);
      return true;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString().replaceFirst('Exception: ', ''),
      );
      return false;
    }
  }

  Future<bool> revokeDevice(int deviceId) async {
    try {
      await repository.revokeDevice(deviceId);
      state = state.copyWith(
        devices: state.devices.where((d) => d.id != deviceId).toList(),
      );
      return true;
    } catch (e) {
      state = state.copyWith(
        error: e.toString().replaceFirst('Exception: ', ''),
      );
      return false;
    }
  }
}
