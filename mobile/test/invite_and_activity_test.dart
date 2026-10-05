import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:our_days_off/features/auth/models/user_model.dart';
import 'package:our_days_off/features/auth/providers/auth_notifier.dart';
import 'package:our_days_off/features/auth/providers/auth_state.dart';
import 'package:our_days_off/features/circles/data/circle_repository.dart';
import 'package:our_days_off/features/circles/models/activity_event.dart';
import 'package:our_days_off/features/circles/models/circle_invite.dart';
import 'package:our_days_off/features/circles/models/circle_member.dart';
import 'package:our_days_off/features/circles/models/circle_model.dart';
import 'package:our_days_off/features/circles/providers/activity_feed_notifier.dart';
import 'package:our_days_off/features/circles/views/circle_detail_screen.dart';
import 'package:our_days_off/features/circles/views/widgets/activity_feed_list.dart';
import 'package:our_days_off/features/circles/views/widgets/circle_invite_modal.dart';

class MockCircleRepository extends Fake implements CircleRepository {
  List<ActivityEvent> mockActivity = [];
  bool createInviteCalled = false;
  bool getActivityCalled = false;

  @override
  Future<CircleInvite> createInvite({
    required int circleId,
    int? maxUses,
  }) async {
    createInviteCalled = true;
    return CircleInvite(
      inviteCode: 'JOIN99',
      inviteUrl: 'https://ourdaysoff.app/circles/join?code=JOIN99',
      expiresAt: DateTime.now().add(const Duration(days: 7)),
    );
  }

  @override
  Future<List<ActivityEvent>> getCircleActivity(int circleId) async {
    getActivityCalled = true;
    return mockActivity;
  }

  @override
  Future<CircleModel> getCircle(int id) async {
    return const CircleModel(
      id: 42,
      ownerId: 1,
      name: 'Cardiology Team',
      handle: 'cardio',
      myRole: 'owner',
      membersCount: 1,
      members: [
        CircleMember(
          id: 101,
          circleId: 42,
          userId: 1,
          role: 'owner',
          memberType: 'working',
          visibility: 'free_busy',
          user: UserModel(
            id: 1,
            name: 'Dr. Jane Doe',
            email: 'jane@cardio.org',
            handle: 'janedoe',
          ),
        ),
      ],
    );
  }
}

class MockAuthNotifier extends StateNotifier<AuthState> implements AuthNotifier {
  MockAuthNotifier(super.state);

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  late MockCircleRepository mockRepo;

  setUp(() {
    mockRepo = MockCircleRepository();
    mockRepo.mockActivity = [
      ActivityEvent(
        id: 1,
        circleId: 42,
        actorId: 1,
        eventType: 'member_joined',
        createdAt: DateTime.now().subtract(const Duration(minutes: 5)),
        actor: const UserModel(
          id: 1,
          name: 'Dr. Jane Doe',
          email: 'jane@cardio.org',
          handle: 'janedoe',
        ),
      ),
      ActivityEvent(
        id: 2,
        circleId: 42,
        actorId: 1,
        eventType: 'schedule_updated',
        createdAt: DateTime.now().subtract(const Duration(hours: 2)),
        actor: const UserModel(
          id: 1,
          name: 'Dr. Jane Doe',
          email: 'jane@cardio.org',
          handle: 'janedoe',
        ),
      ),
    ];
  });

  group('ActivityFeedNotifier Unit Tests', () {
    test('loads circle activity events successfully', () async {
      final notifier = ActivityFeedNotifier(
        repository: mockRepo,
        circleId: 42,
      );

      await Future.delayed(Duration.zero);

      expect(notifier.state.isLoading, isFalse);
      expect(notifier.state.events.length, 2);
      expect(mockRepo.getActivityCalled, isTrue);
      expect(notifier.state.events.first.description, 'Dr. Jane Doe joined the circle');
      expect(notifier.state.events[1].description, 'Dr. Jane Doe updated their work schedule');
    });
  });

  group('CircleInviteModal Widget Tests', () {
    testWidgets('generates invite code and displays 6-character code', (WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            circleRepositoryProvider.overrideWithValue(mockRepo),
          ],
          child: MaterialApp(
            home: Scaffold(
              body: Builder(
                builder: (context) => ElevatedButton(
                  onPressed: () => CircleInviteModal.show(
                    context: context,
                    circleId: 42,
                    circleName: 'Cardiology Team',
                  ),
                  child: const Text('Open Invite'),
                ),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open Invite'));
      await tester.pumpAndSettle();

      expect(find.text('Invite Members'), findsOneWidget);
      expect(find.text('Generate Invite Code & Link'), findsOneWidget);

      // Tap generate button
      await tester.tap(find.text('Generate Invite Code & Link'));
      await tester.pumpAndSettle();

      expect(mockRepo.createInviteCalled, isTrue);
      expect(find.text('JOIN99'), findsOneWidget);
      expect(find.text('6-CHARACTER JOIN CODE'), findsOneWidget);
      expect(find.text('Share Invite...'), findsOneWidget);
    });
  });

  group('ActivityFeedList Widget Tests', () {
    testWidgets('renders list of activity events', (WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            circleRepositoryProvider.overrideWithValue(mockRepo),
          ],
          child: const MaterialApp(
            home: Scaffold(
              body: ActivityFeedList(circleId: 42),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Dr. Jane Doe joined the circle'), findsOneWidget);
      expect(find.text('Dr. Jane Doe updated their work schedule'), findsOneWidget);
      expect(find.text('@janedoe'), findsNWidgets(2));
    });

    testWidgets('renders empty state when there are no events', (WidgetTester tester) async {
      mockRepo.mockActivity = [];

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            circleRepositoryProvider.overrideWithValue(mockRepo),
          ],
          child: const MaterialApp(
            home: Scaffold(
              body: ActivityFeedList(circleId: 42),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('No Recent Activity'), findsOneWidget);
    });
  });

  group('CircleDetailScreen Segmented Tab Tests', () {
    testWidgets('switches between Members and Activity tab', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(800, 1400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      const authUser = UserModel(
        id: 1,
        name: 'Dr. Jane Doe',
        email: 'jane@cardio.org',
        handle: 'janedoe',
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            circleRepositoryProvider.overrideWithValue(mockRepo),
            authNotifierProvider.overrideWith((ref) => MockAuthNotifier(const AuthState(
              status: AuthStatus.authenticated,
              user: authUser,
            ))),
          ],
          child: const MaterialApp(
            home: CircleDetailScreen(circleId: 42),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Initially on Members tab
      expect(find.text('Members (1)'), findsOneWidget);
      expect(find.text('Circle Members & Privacy Roster'), findsOneWidget);

      // Switch to Activity tab
      await tester.tap(find.text('Activity'));
      await tester.pumpAndSettle();

      expect(find.text('Dr. Jane Doe joined the circle'), findsOneWidget);

      // Switch back to Members tab
      await tester.tap(find.text('Members (1)'));
      await tester.pumpAndSettle();

      expect(find.text('Circle Members & Privacy Roster'), findsOneWidget);
    });
  });
}
