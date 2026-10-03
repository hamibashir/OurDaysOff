import 'package:flutter_test/flutter_test.dart';
import 'package:our_days_off/features/auth/models/user_model.dart';
import 'package:our_days_off/features/auth/providers/auth_state.dart';

void main() {
  group('AuthState Tests', () {
    test('Initial state is not authenticated', () {
      final state = AuthState.initial();
      expect(state.status, AuthStatus.initial);
      expect(state.isAuthenticated, isFalse);
      expect(state.isLoading, isTrue);
    });

    test('Authenticated state sets user and authenticated flag to true', () {
      const user = UserModel(
        id: 1,
        name: 'Jane Doe',
        email: 'jane@example.com',
        handle: 'janedoe',
      );

      final state = AuthState.authenticated(user);
      expect(state.status, AuthStatus.authenticated);
      expect(state.isAuthenticated, isTrue);
      expect(state.user?.name, 'Jane Doe');
      expect(state.user?.initials, 'JD');
    });

    test('Unauthenticated state clears user and sets flag to false', () {
      final state = AuthState.unauthenticated('Invalid credentials');
      expect(state.status, AuthStatus.unauthenticated);
      expect(state.isAuthenticated, isFalse);
      expect(state.errorMessage, 'Invalid credentials');
    });
  });
}
