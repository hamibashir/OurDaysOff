import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:our_days_off/features/auth/models/user_model.dart';
import 'package:our_days_off/features/auth/providers/auth_notifier.dart';
import 'package:our_days_off/features/auth/providers/auth_state.dart';
import 'package:our_days_off/features/profile/views/profile_screen.dart';

class MockAuthNotifier extends StateNotifier<AuthState> implements AuthNotifier {
  MockAuthNotifier(super.state);

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  group('ProfileScreen Widget Tests', () {
    testWidgets('renders user profile details and settings options', (WidgetTester tester) async {
      const user = UserModel(
        id: 42,
        name: 'Alex Mercer',
        email: 'alex@example.com',
        handle: 'alexm',
        isPremium: false,
        isAdmin: false,
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authNotifierProvider.overrideWith(
              (ref) => MockAuthNotifier(AuthState.authenticated(user)),
            ),
          ],
          child: const MaterialApp(
            home: ProfileScreen(),
          ),
        ),
      );

      expect(find.text('Profile & Settings'), findsOneWidget);
      expect(find.text('Alex Mercer'), findsOneWidget);
      expect(find.text('@alexm'), findsOneWidget);
      expect(find.text('alex@example.com'), findsOneWidget);
      expect(find.text('AM'), findsOneWidget);
      expect(find.text('Upgrade to VIP'), findsOneWidget);
      expect(find.text('Handle Visibility'), findsOneWidget);
      expect(find.text('Companion Devices'), findsOneWidget);
      expect(find.text('Sign Out'), findsOneWidget);
    });

    testWidgets('renders VIP Pro badge when user is premium', (WidgetTester tester) async {
      const vipUser = UserModel(
        id: 99,
        name: 'Bruce Wayne',
        email: 'bruce@wayne.com',
        handle: 'batman',
        isPremium: true,
        isAdmin: true,
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authNotifierProvider.overrideWith(
              (ref) => MockAuthNotifier(AuthState.authenticated(vipUser)),
            ),
          ],
          child: const MaterialApp(
            home: ProfileScreen(),
          ),
        ),
      );

      expect(find.text('VIP PRO'), findsOneWidget);
      expect(find.text('VIP Membership Active'), findsOneWidget);
      expect(find.text('Admin Dashboard'), findsOneWidget);
    });
  });
}
