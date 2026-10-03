import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/api_client.dart';
import '../models/auth_response.dart';
import '../models/user_model.dart';

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return AuthRepository(apiClient: apiClient);
});

class AuthRepository {
  final ApiClient apiClient;

  AuthRepository({required this.apiClient});

  /// Authenticate an existing user with email and password
  Future<AuthResponse> login({
    required String email,
    required String password,
    String? deviceName,
  }) async {
    final response = await apiClient.post(
      '/auth/login',
      data: {
        'email': email,
        'password': password,
        if (deviceName != null) 'device_name': deviceName,
      },
    );

    return AuthResponse.fromJson(response as Map<String, dynamic>);
  }

  /// Register a new account
  Future<AuthResponse> register({
    required String name,
    required String email,
    required String password,
    required String passwordConfirmation,
    String? handle,
    String? deviceName,
  }) async {
    final response = await apiClient.post(
      '/auth/register',
      data: {
        'name': name,
        'email': email,
        'password': password,
        'password_confirmation': passwordConfirmation,
        if (handle != null && handle.trim().isNotEmpty) 'handle': handle.trim(),
        if (deviceName != null) 'device_name': deviceName,
      },
    );

    return AuthResponse.fromJson(response as Map<String, dynamic>);
  }

  /// Invalidate current Sanctum Bearer token on backend
  Future<void> logout() async {
    await apiClient.post('/auth/logout');
  }

  /// Fetch current authenticated user record
  Future<UserModel> getMe() async {
    final response = await apiClient.get('/auth/me');
    final data = (response as Map<String, dynamic>)['data'] as Map<String, dynamic>;
    return UserModel.fromJson(data);
  }

  /// Verify whether a handle is available
  Future<bool> checkHandle(String handle) async {
    try {
      final response = await apiClient.post(
        '/profile/handle-check',
        data: {'handle': handle.trim().toLowerCase()},
      );
      final map = response as Map<String, dynamic>;
      return map['available'] == true;
    } catch (_) {
      return false;
    }
  }
}
