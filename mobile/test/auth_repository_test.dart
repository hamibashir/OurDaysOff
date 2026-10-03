import 'package:flutter_test/flutter_test.dart';
import 'package:our_days_off/features/auth/models/auth_response.dart';
import 'package:our_days_off/features/auth/models/user_model.dart';

void main() {
  group('Auth Models & Serialization Tests', () {
    test('UserModel parses from Laravel backend JSON correctly', () {
      final json = {
        'id': 42,
        'name': 'Sarah Connor',
        'email': 'sarah@example.com',
        'handle': 'sarah_c',
        'handle_visibility': 'circle_only',
        'timezone': 'Europe/London',
        'is_premium': 1,
        'is_admin': false,
        'created_at': '2026-10-04T02:00:00.000000Z',
      };

      final user = UserModel.fromJson(json);

      expect(user.id, 42);
      expect(user.name, 'Sarah Connor');
      expect(user.email, 'sarah@example.com');
      expect(user.handle, 'sarah_c');
      expect(user.handleVisibility, 'circle_only');
      expect(user.isPremium, isTrue);
      expect(user.isAdmin, isFalse);
      expect(user.initials, 'SC');
    });

    test('AuthResponse parses response with user and Sanctum bearer token', () {
      final json = {
        'message': 'Login successful.',
        'data': {
          'user': {
            'id': 1,
            'name': 'Alex Rivera',
            'email': 'alex@example.com',
            'handle': 'arivera',
            'timezone': 'America/New_York',
            'is_premium': false,
            'is_admin': true,
          },
          'token': '1|laravel_sanctum_plain_text_token_xyz',
        },
      };

      final authResponse = AuthResponse.fromJson(json);

      expect(authResponse.message, 'Login successful.');
      expect(authResponse.token, '1|laravel_sanctum_plain_text_token_xyz');
      expect(authResponse.user.id, 1);
      expect(authResponse.user.name, 'Alex Rivera');
      expect(authResponse.user.isAdmin, isTrue);
      expect(authResponse.user.initials, 'AR');
    });

    test('UserModel initials calculation edge cases', () {
      const singleName = UserModel(id: 1, name: 'Madonna', email: 'm@example.com');
      expect(singleName.initials, 'M');

      const tripleName = UserModel(id: 2, name: 'John Fitzgerald Kennedy', email: 'j@example.com');
      expect(tripleName.initials, 'JF');
    });
  });
}
