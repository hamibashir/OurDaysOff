import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:our_days_off/features/auth/models/user_model.dart';
import 'package:our_days_off/features/auth/providers/auth_notifier.dart';
import 'package:our_days_off/features/auth/providers/auth_state.dart';
import 'package:our_days_off/main.dart';

class MockAuthNotifier extends StateNotifier<AuthState> implements AuthNotifier {
  MockAuthNotifier(super.state);

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  testWidgets('App redirects unauthenticated user to login screen', (WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authNotifierProvider.overrideWith(
            (ref) => MockAuthNotifier(AuthState.unauthenticated()),
          ),
        ],
        child: const OurDaysOffApp(),
      ),
    );
    await tester.pumpAndSettle();

    // Verify redirected to LoginScreen
    expect(find.text('Sign In to Our Days Off'), findsOneWidget);
  });

  testWidgets('App renders navigation shell when authenticated', (WidgetTester tester) async {
    const testUser = UserModel(
      id: 1,
      name: 'Sarah Connor',
      email: 'sarah@example.com',
      handle: 'sarah_c',
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authNotifierProvider.overrideWith(
            (ref) => MockAuthNotifier(AuthState.authenticated(testUser)),
          ),
        ],
        child: const OurDaysOffApp(),
      ),
    );
    await tester.pumpAndSettle();

    // Verify header handle badge displays @sarah_c and avatar initial SC
    expect(find.text('@sarah_c'), findsOneWidget);
    expect(find.text('SC'), findsOneWidget);

    // Verify all 5 primary bottom navigation items appear
    expect(find.text('Dashboard'), findsOneWidget);
    expect(find.text('Schedule'), findsOneWidget);
    expect(find.text('Circles'), findsOneWidget);
    expect(find.text('Compare'), findsOneWidget);
    expect(find.text('Plans'), findsOneWidget);

    // Verify default active screen is Dashboard
    expect(find.text('Schedule Intelligence Active'), findsOneWidget);
  });
}
