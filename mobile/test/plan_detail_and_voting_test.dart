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
import 'package:our_days_off/features/plans/models/plan_member_model.dart';
import 'package:our_days_off/features/plans/models/plan_model.dart';
import 'package:our_days_off/features/plans/models/plan_option_model.dart';
import 'package:our_days_off/features/plans/providers/plan_detail_notifier.dart';
import 'package:our_days_off/features/plans/views/plan_detail_screen.dart';
import 'package:our_days_off/features/plans/views/widgets/location_voting_widget.dart';
import 'package:our_days_off/features/plans/views/widgets/plan_rsvp_bar.dart';

class MockPlanRepository extends Fake implements PlanRepository {
  PlanModel? mockPlan;
  String? lastRsvpStatus;
  int? lastRsvpPlanId;
  PlanLocationModel? proposedLocation;
  int? votedLocationId;
  int? deletedPlanId;

  @override
  Future<List<PlanModel>> getPlans() async => mockPlan != null ? [mockPlan!] : [];

  @override
  Future<PlanModel> getPlan(int id) async {
    if (mockPlan != null && mockPlan!.id == id) {
      return mockPlan!;
    }
    throw Exception('Plan not found');
  }

  @override
  Future<PlanMemberModel> rsvp({
    required int planId,
    required String rsvpStatus,
  }) async {
    lastRsvpPlanId = planId;
    lastRsvpStatus = rsvpStatus;
    return PlanMemberModel(
      id: 50,
      planId: planId,
      userId: 1,
      rsvpStatus: rsvpStatus,
    );
  }

  @override
  Future<PlanLocationModel> proposeLocation({
    required int planId,
    required String name,
    String? address,
    double? latitude,
    double? longitude,
    String? notes,
  }) async {
    proposedLocation = PlanLocationModel(
      id: 88,
      planId: planId,
      name: name,
      address: address,
      notes: notes,
      createdBy: 1,
      votes: [],
    );
    return proposedLocation!;
  }

  @override
  Future<PlanLocationVoteModel> voteLocation(int locationId) async {
    votedLocationId = locationId;
    return PlanLocationVoteModel(
      id: 77,
      planLocationId: locationId,
      userId: 1,
      createdAt: DateTime.now(),
    );
  }

  @override
  Future<void> deletePlan(int id) async {
    deletedPlanId = id;
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
    handle: 'explorers',
  );

  final testPlan = PlanModel(
    id: 100,
    circleId: 10,
    createdBy: 1, // User 1 is creator
    title: 'Highland Trail Hike',
    description: 'Scenic ridge walk with pub lunch stop',
    eventType: 'social',
    status: 'confirmed',
    startAt: DateTime(2026, 10, 25, 9, 30),
    endAt: DateTime(2026, 10, 25, 16, 0),
    myRsvp: 'attending',
    circle: testCircle,
    creator: testUser,
    members: const [
      PlanMemberModel(
        id: 1,
        planId: 100,
        userId: 1,
        rsvpStatus: 'attending',
        user: testUser,
      ),
      PlanMemberModel(
        id: 2,
        planId: 100,
        userId: 2,
        rsvpStatus: 'tentative',
        user: UserModel(id: 2, name: 'Bob Smith', email: 'bob@example.com'),
      ),
      PlanMemberModel(
        id: 3,
        planId: 100,
        userId: 3,
        rsvpStatus: 'declined',
        user: UserModel(id: 3, name: 'Charlie Day', email: 'charlie@example.com'),
      ),
    ],
    locations: const [
      PlanLocationModel(
        id: 201,
        planId: 100,
        name: 'North Ridge Carpark',
        address: 'B4012 Highland Pass',
        notes: 'Free parking before 10am',
        votes: [
          PlanLocationVoteModel(id: 1, planLocationId: 201, userId: 1),
        ],
      ),
      PlanLocationModel(
        id: 202,
        planId: 100,
        name: 'The Golden Lion Pub',
        address: 'High Street, Village Center',
        votes: [],
      ),
    ],
    options: [
      PlanOptionModel(
        id: 1,
        planId: 100,
        startAt: DateTime(2026, 10, 25, 9, 30),
        endAt: DateTime(2026, 10, 25, 16, 0),
      ),
    ],
  );

  group('PlanRsvpBar Widget Tests', () {
    testWidgets('renders Going, Maybe, and Can\'t Go buttons with counts', (tester) async {
      String? selectedRsvp;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PlanRsvpBar(
              plan: testPlan,
              onRsvpSelected: (status) => selectedRsvp = status,
            ),
          ),
        ),
      );

      expect(find.text('YOUR RSVP'), findsOneWidget);
      expect(find.text('1 Going'), findsOneWidget);
      expect(find.text('Going'), findsOneWidget);
      expect(find.text('Maybe'), findsOneWidget);
      expect(find.text("Can't Go"), findsOneWidget);

      // Tap Maybe
      await tester.tap(find.text('Maybe'));
      await tester.pump();
      expect(selectedRsvp, 'tentative');

      // Tap Going counter to open cohort sheet
      await tester.tap(find.text('1 Going'));
      await tester.pumpAndSettle();

      expect(find.text('Attendee Roster'), findsOneWidget);
      expect(find.text('Attending (1)'), findsOneWidget);
      expect(find.text('Tentative (1)'), findsOneWidget);
      expect(find.text("Can't Go (1)"), findsOneWidget);
      expect(find.text('Alice Johnson'), findsOneWidget);
      expect(find.text('Bob Smith'), findsOneWidget);
      expect(find.text('Charlie Day'), findsOneWidget);
    });
  });

  group('LocationVotingWidget Tests', () {
    testWidgets('renders candidate venues and handles voting', (tester) async {
      int? votedId;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: LocationVotingWidget(
              planId: 100,
              locations: testPlan.locations,
              currentUserId: 1,
              onProposeLocation: ({required name, address, notes}) async {},
              onVoteLocation: (id) => votedId = id,
            ),
          ),
        ),
      );

      expect(find.text('LOCATION OPTIONS & VOTING'), findsOneWidget);
      expect(find.text('North Ridge Carpark'), findsOneWidget);
      expect(find.text('B4012 Highland Pass'), findsOneWidget);
      expect(find.text('The Golden Lion Pub'), findsOneWidget);
      expect(find.text('1'), findsOneWidget); // 1 vote on carpark
      expect(find.text('0'), findsOneWidget); // 0 votes on pub

      // Vote on pub
      await tester.tap(find.byIcon(LucideIcons.thumbsUp).last);
      await tester.pump();
      expect(votedId, 202);
    });

    testWidgets('toggles propose venue form and validates input', (tester) async {
      String? proposedName;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: LocationVotingWidget(
                planId: 100,
                locations: const [],
                currentUserId: 1,
                onProposeLocation: ({required name, address, notes}) async {
                  proposedName = name;
                },
                onVoteLocation: (_) {},
              ),
            ),
          ),
        ),
      );

      expect(find.text('No venues proposed yet'), findsOneWidget);

      // Open propose form
      await tester.tap(find.text('Propose Venue'));
      await tester.pumpAndSettle();

      expect(find.text('Propose Candidate Venue'), findsOneWidget);

      // Try submitting empty
      await tester.tap(find.widgetWithText(ElevatedButton, 'Submit Proposal'));
      await tester.pump();
      expect(find.text('Venue name is required'), findsOneWidget);

      // Enter name
      await tester.enterText(find.byType(TextFormField).first, 'Sunset Lookout Point');
      await tester.tap(find.widgetWithText(ElevatedButton, 'Submit Proposal'));
      await tester.pumpAndSettle();

      expect(proposedName, 'Sunset Lookout Point');
    });
  });

  group('PlanDetailNotifier State Tests', () {
    test('updates RSVP and casts location vote', () async {
      final mockRepo = MockPlanRepository()..mockPlan = testPlan;

      final container = ProviderContainer(
        overrides: [
          planRepositoryProvider.overrideWithValue(mockRepo),
        ],
      );

      // Read plan
      final initial = await container.read(planDetailNotifierProvider(100).future);
      expect(initial.title, 'Highland Trail Hike');
      expect(initial.myRsvp, 'attending');

      // Update RSVP to declined
      await container.read(planDetailNotifierProvider(100).notifier).updateRsvp('declined', currentUserId: 1);
      final updatedRsvp = container.read(planDetailNotifierProvider(100)).value!;
      expect(updatedRsvp.myRsvp, 'declined');
      expect(mockRepo.lastRsvpStatus, 'declined');

      // Vote on location 202
      await container.read(planDetailNotifierProvider(100).notifier).voteLocation(202, 1);
      final updatedVote = container.read(planDetailNotifierProvider(100)).value!;
      final pub = updatedVote.locations.firstWhere((l) => l.id == 202);
      expect(pub.voteCount, 1);
      expect(pub.hasVoted(1), isTrue);

      // Propose new location
      await container.read(planDetailNotifierProvider(100).notifier).proposeLocation(
            name: 'Summit Cafe',
            address: 'Peak Station',
          );
      final updatedLocs = container.read(planDetailNotifierProvider(100)).value!;
      expect(updatedLocs.locations.length, 3);
      expect(updatedLocs.locations.last.name, 'Summit Cafe');
    });
  });

  group('PlanDetailScreen Widget Tests', () {
    testWidgets('renders hero header, time, RSVP bar, and delete option for creator', (tester) async {
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

      expect(find.text('Highland Trail Hike'), findsOneWidget);
      expect(find.text('Scenic ridge walk with pub lunch stop'), findsOneWidget);
      expect(find.text('Weekend Explorers'), findsOneWidget);
      expect(find.text('Organized by Alice Johnson'), findsOneWidget);
      expect(find.text('CONFIRMED'), findsOneWidget);
      expect(find.text('YOUR RSVP'), findsOneWidget);
      expect(find.text('North Ridge Carpark'), findsOneWidget);
      expect(find.text('PROPOSED TIME SLOTS'), findsOneWidget);

      // Creator delete button in AppBar
      expect(find.byIcon(LucideIcons.trash2), findsOneWidget);
    });

    testWidgets('renders error view with retry button on failure', (tester) async {
      final mockRepo = MockPlanRepository()..mockPlan = null; // Forces failure

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            planRepositoryProvider.overrideWithValue(mockRepo),
          ],
          child: const MaterialApp(
            home: PlanDetailScreen(planId: 999),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Failed to load plan details'), findsOneWidget);
      expect(find.widgetWithText(ElevatedButton, 'Try Again'), findsOneWidget);
    });
  });
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
