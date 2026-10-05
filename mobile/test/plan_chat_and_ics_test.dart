import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:our_days_off/core/storage/secure_storage_service.dart';
import 'package:our_days_off/features/auth/data/auth_repository.dart';
import 'package:our_days_off/features/auth/models/user_model.dart';
import 'package:our_days_off/features/auth/providers/auth_notifier.dart';
import 'package:our_days_off/features/auth/providers/auth_state.dart';
import 'package:our_days_off/features/circles/models/circle_model.dart';
import 'package:our_days_off/features/plans/data/plan_repository.dart';
import 'package:our_days_off/features/plans/models/plan_location_model.dart';
import 'package:our_days_off/features/plans/models/plan_message_model.dart';
import 'package:our_days_off/features/plans/models/plan_model.dart';
import 'package:our_days_off/features/plans/utils/ics_generator.dart';
import 'package:our_days_off/features/plans/views/plan_detail_screen.dart';
import 'package:our_days_off/features/plans/views/widgets/plan_chat_widget.dart';

class MockPlanRepository extends Fake implements PlanRepository {
  List<PlanMessageModel> mockMessages = [];
  PlanModel? mockPlan;
  String? lastSentBody;

  @override
  Future<PlanModel> getPlan(int id) async => mockPlan!;

  @override
  Future<List<PlanMessageModel>> getMessages(int planId) async => mockMessages;

  @override
  Future<PlanMessageModel> sendMessage({
    required int planId,
    required String body,
  }) async {
    lastSentBody = body;
    final newMsg = PlanMessageModel(
      id: 99,
      planId: planId,
      userId: 1,
      body: body,
      createdAt: DateTime.now(),
      user: const UserModel(id: 1, name: 'Alice Johnson', email: 'alice@example.com'),
    );
    mockMessages = [...mockMessages, newMsg];
    return newMsg;
  }
}

class FakeAuthRepository extends Fake implements AuthRepository {
  @override
  Future<UserModel> getMe() async => const UserModel(
        id: 1,
        name: 'Alice Johnson',
        email: 'alice@example.com',
      );
}

class FakeSecureStorage extends Fake implements SecureStorageService {
  @override
  Future<String?> getAuthToken() async => 'fake_token';

  @override
  Future<void> saveAuthToken(String token) async {}

  @override
  Future<void> deleteAuthToken() async {}

  @override
  Future<String?> getUserData() async => null;

  @override
  Future<void> saveUserData(String data) async {}
}

extension on AuthNotifier {
  void setAuthenticatedUser(UserModel user) {
    state = AuthState.authenticated(user);
  }
}

void main() {
  const testUser = UserModel(
    id: 1,
    name: 'Alice Johnson',
    email: 'alice@example.com',
  );

  const testCircle = CircleModel(
    id: 10,
    ownerId: 1,
    name: 'Weekend Explorers',
  );

  final testPlan = PlanModel(
    id: 100,
    circleId: 10,
    createdBy: 1,
    title: 'Highland Trail Hike; Food & Drinks, Fun',
    description: 'Scenic ridge walk,\nand pub lunch stop.',
    eventType: 'social',
    status: 'confirmed',
    startAt: DateTime.utc(2026, 10, 25, 9, 30),
    endAt: DateTime.utc(2026, 10, 25, 16, 0),
    circle: testCircle,
    creator: testUser,
    locations: const [
      PlanLocationModel(id: 1, planId: 100, name: 'The Castle Pub, High St'),
    ],
  );

  group('ICS Calendar Generator Tests', () {
    test('generates valid RFC 5545 calendar string with escaped characters', () {
      final ics = generateIcsContent(testPlan);

      expect(ics.contains('BEGIN:VCALENDAR'), isTrue);
      expect(ics.contains('VERSION:2.0'), isTrue);
      expect(ics.contains('PRODID:-//Our Days Off//Schedule Coordination Platform//EN'), isTrue);
      expect(ics.contains('BEGIN:VEVENT'), isTrue);
      expect(ics.contains('SUMMARY:Highland Trail Hike\\; Food & Drinks\\, Fun'), isTrue);
      expect(ics.contains('DESCRIPTION:Scenic ridge walk\\,\\nand pub lunch stop.'), isTrue);
      expect(ics.contains('LOCATION:The Castle Pub\\, High St'), isTrue);
      expect(ics.contains('DTSTART:20261025T093000Z'), isTrue);
      expect(ics.contains('DTEND:20261025T160000Z'), isTrue);
      expect(ics.contains('STATUS:CONFIRMED'), isTrue);
      expect(ics.contains('END:VEVENT'), isTrue);
      expect(ics.contains('END:VCALENDAR'), isTrue);
    });

    test('escapes special characters correctly in escapeIcsText', () {
      expect(escapeIcsText(r'A\B'), r'A\\B');
      expect(escapeIcsText('A,B'), r'A\,B');
      expect(escapeIcsText('A;B'), r'A\;B');
      expect(escapeIcsText('A\nB'), r'A\nB');
    });

    test('handles fallback when dates or location are omitted', () {
      const barePlan = PlanModel(
        id: 200,
        circleId: 10,
        createdBy: 2,
        title: 'Simple Catchup',
        startAt: null,
        endAt: null,
      );

      final ics = generateIcsContent(barePlan, locationName: 'Coffee Shop');
      expect(ics.contains('LOCATION:Coffee Shop'), isTrue);
      expect(ics.contains('SUMMARY:Simple Catchup'), isTrue);
    });
  });

  group('PlanChatWidget Tests', () {
    testWidgets('renders empty placeholder and allows sending a message', (tester) async {
      final mockRepo = MockPlanRepository();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            planRepositoryProvider.overrideWithValue(mockRepo),
            authNotifierProvider.overrideWith(
              (ref) => AuthNotifier(
                repository: FakeAuthRepository(),
                storage: FakeSecureStorage(),
              )..setAuthenticatedUser(testUser),
            ),
          ],
          child: const MaterialApp(
            home: Scaffold(
              body: SingleChildScrollView(
                child: PlanChatWidget(planId: 100),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('DISCUSSION THREAD'), findsOneWidget);
      expect(find.text('No messages yet'), findsOneWidget);

      // Write a message
      await tester.enterText(find.byType(TextField), 'I can bring two extra backpacks!');
      await tester.pump();

      // Tap send button
      await tester.tap(find.byIcon(LucideIcons.send));
      await tester.pumpAndSettle();

      expect(mockRepo.lastSentBody, 'I can bring two extra backpacks!');
      expect(find.text('I can bring two extra backpacks!'), findsOneWidget);
    });

    testWidgets('renders other member message with name and avatar', (tester) async {
      final mockRepo = MockPlanRepository()
        ..mockMessages = [
          PlanMessageModel(
            id: 1,
            planId: 100,
            userId: 2, // Bob Smith (other member)
            body: 'Is anyone driving through North London?',
            createdAt: DateTime(2026, 10, 20, 14, 30),
            user: const UserModel(id: 2, name: 'Bob Smith', email: 'bob@example.com'),
          ),
        ];

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            planRepositoryProvider.overrideWithValue(mockRepo),
            authNotifierProvider.overrideWith(
              (ref) => AuthNotifier(
                repository: FakeAuthRepository(),
                storage: FakeSecureStorage(),
              )..setAuthenticatedUser(testUser), // Current user is 1 (Alice)
            ),
          ],
          child: const MaterialApp(
            home: Scaffold(
              body: SingleChildScrollView(
                child: PlanChatWidget(planId: 100),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Bob Smith'), findsOneWidget);
      expect(find.text('BS'), findsOneWidget);
      expect(find.text('Is anyone driving through North London?'), findsOneWidget);
    });
  });

  group('PlanDetailScreen with Export & Chat Tests', () {
    testWidgets('renders export .ics button and discussion thread in PlanDetailScreen', (tester) async {
      final mockRepo = MockPlanRepository()..mockPlan = testPlan;

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            planRepositoryProvider.overrideWithValue(mockRepo),
            authNotifierProvider.overrideWith(
              (ref) => AuthNotifier(
                repository: FakeAuthRepository(),
                storage: FakeSecureStorage(),
              )..setAuthenticatedUser(testUser),
            ),
          ],
          child: const MaterialApp(
            home: PlanDetailScreen(planId: 100),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Highland Trail Hike; Food & Drinks, Fun'), findsOneWidget);
      expect(find.byIcon(LucideIcons.download), findsOneWidget); // Export .ics action
      expect(find.text('DISCUSSION THREAD'), findsOneWidget); // Chat thread
    });
  });
}
