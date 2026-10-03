import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/storage/secure_storage_service.dart';
import '../data/auth_repository.dart';
import '../models/user_model.dart';
import 'auth_state.dart';

final authNotifierProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  final repository = ref.watch(authRepositoryProvider);
  final storage = ref.watch(secureStorageServiceProvider);
  return AuthNotifier(
    repository: repository,
    storage: storage,
  );
});

class AuthNotifier extends StateNotifier<AuthState> {
  final AuthRepository repository;
  final SecureStorageService storage;

  AuthNotifier({
    required this.repository,
    required this.storage,
  }) : super(AuthState.initial()) {
    checkAuthStatus();
  }

  /// Inspect stored Sanctum token and auto-login if valid
  Future<void> checkAuthStatus() async {
    state = AuthState.initial();
    try {
      final token = await storage.getAuthToken();
      if (token == null || token.isEmpty) {
        state = AuthState.unauthenticated();
        return;
      }

      // First try to load locally cached user for instantaneous render
      final cachedUserJson = await storage.getUserData();
      if (cachedUserJson != null) {
        try {
          final cachedUser = UserModel.fromJson(jsonDecode(cachedUserJson));
          state = AuthState.authenticated(cachedUser);
        } catch (_) {}
      }

      // Verify token with backend
      final freshUser = await repository.getMe();
      await storage.saveUserData(jsonEncode(freshUser.toJson()));
      state = AuthState.authenticated(freshUser);
    } catch (_) {
      // If token is invalid or network unreachable with bad token
      await storage.deleteAuthToken();
      state = AuthState.unauthenticated();
    }
  }

  /// Authenticate with email & password
  Future<void> login({
    required String email,
    required String password,
    String? deviceName,
  }) async {
    state = AuthState.authenticating();
    try {
      final response = await repository.login(
        email: email,
        password: password,
        deviceName: deviceName ?? 'Mobile App',
      );

      await storage.saveAuthToken(response.token);
      await storage.saveUserData(jsonEncode(response.user.toJson()));

      state = AuthState.authenticated(response.user);
    } catch (e) {
      state = AuthState.unauthenticated(e.toString());
      rethrow;
    }
  }

  /// Register new user account
  Future<void> register({
    required String name,
    required String email,
    required String password,
    required String passwordConfirmation,
    String? handle,
    String? deviceName,
  }) async {
    state = AuthState.authenticating();
    try {
      final response = await repository.register(
        name: name,
        email: email,
        password: password,
        passwordConfirmation: passwordConfirmation,
        handle: handle,
        deviceName: deviceName ?? 'Mobile App',
      );

      await storage.saveAuthToken(response.token);
      await storage.saveUserData(jsonEncode(response.user.toJson()));

      state = AuthState.authenticated(response.user);
    } catch (e) {
      state = AuthState.unauthenticated(e.toString());
      rethrow;
    }
  }

  /// Terminate session and clear secure storage
  Future<void> logout() async {
    try {
      await repository.logout();
    } catch (_) {
      // Ignore network errors on logout to allow local sign-out
    } finally {
      await storage.deleteAuthToken();
      await storage.clearAll();
      state = AuthState.unauthenticated();
    }
  }

  /// Invalidate session locally (invoked by 401 interceptor)
  void setUnauthenticated() {
    state = AuthState.unauthenticated('Session expired. Please log in again.');
  }

  /// Update local user state (e.g. after profile edit or coupon redemption)
  void updateUser(UserModel updatedUser) {
    storage.saveUserData(jsonEncode(updatedUser.toJson()));
    state = AuthState.authenticated(updatedUser);
  }
}
