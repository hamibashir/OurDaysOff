import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:our_days_off/features/auth/models/user_model.dart';
import 'package:our_days_off/features/auth/providers/auth_notifier.dart';
import 'package:our_days_off/features/auth/providers/auth_state.dart';
import 'package:our_days_off/features/circles/data/circle_repository.dart';
import 'package:our_days_off/features/circles/models/circle_member.dart';
import 'package:our_days_off/features/circles/models/circle_model.dart';
import 'package:our_days_off/features/circles/providers/circle_detail_notifier.dart';
import 'package:our_days_off/features/circles/providers/circle_detail_state.dart';
import 'package:our_days_off/features/circles/views/circle_detail_screen.dart';
import 'package:our_days_off/features/circles/views/widgets/circle_settings_modal.dart';
import 'package:our_days_off/features/circles/views/widgets/member_item_tile.dart';

class MockCircleRepository extends Fake implements CircleRepository {
  late CircleModel mockCircle;
  bool deleteCircleCalled = false;
  int? lastRemovedMemberId;
  String? lastUpdatedRole;
  String? lastUpdatedType;
  String? lastUpdatedVisibility;

  @override
  Future<CircleModel> getCircle(int id) async {
    return mockCircle;
  }

  @override
  Future<CircleMember> updateMember({
    required int circleId,
    required int memberId,
    String? role,
    String? memberType,
    String? visibility,
  }) async {
    lastUpdatedRole = role;
    lastUpdatedType = memberType;
    lastUpdatedVisibility = visibility;

    final existing = mockCircle.members.firstWhere((m) => m.id == memberId);
    final updated = existing.copyWith(
      role: role ?? existing.role,
      memberType: memberType ?? existing.memberType,
      visibility: visibility ?? existing.visibility,
    );

    final updatedMembers = mockCircle.members.map((m) => m.id == memberId ? updated : m).toList();
    mockCircle = mockCircle.copyWith(members: updatedMembers);
    return updated;
  }

  @override
  Future<void> removeMember({
    required int circleId,
    required int memberId,
  }) async {
    lastRemovedMemberId = memberId;
    final updatedMembers = mockCircle.members.where((m) => m.id != memberId).toList();
    mockCircle = mockCircle.copyWith(
      members: updatedMembers,
      membersCount: updatedMembers.length,
    );
  }

  @override
  Future<void> deleteCircle(int id) async {
    deleteCircleCalled = true;
  }
}

class MockAuthNotifier extends StateNotifier<AuthState> implements AuthNotifier {
  MockAuthNotifier(super.state);

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  late MockCircleRepository mockRepo;
  late CircleModel testCircle;

  setUp(() {
    mockRepo = MockCircleRepository();
    testCircle = const CircleModel(
      id: 42,
      ownerId: 1,
      name: 'Trauma Shift Crew',
      handle: 'trauma-crew',
      discoverability: 'private',
      myRole: 'owner',
      myMemberType: 'working',
      myVisibility: 'free_busy',
      membersCount: 2,
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
            name: 'Dr. Sarah Connor',
            email: 'sarah@hospital.org',
            handle: 'sconnor',
          ),
        ),
        CircleMember(
          id: 102,
          circleId: 42,
          userId: 2,
          role: 'member',
          memberType: 'working',
          visibility: 'free_busy',
          user: UserModel(
            id: 2,
            name: 'John Miller',
            email: 'john@hospital.org',
            handle: 'jmiller',
          ),
        ),
      ],
    );
    mockRepo.mockCircle = testCircle;
  });

  group('CircleDetailNotifier Unit Tests', () {
    test('initial state loads circle details successfully', () async {
      final notifier = CircleDetailNotifier(
        repository: mockRepo,
        circleId: 42,
      );

      await Future.delayed(Duration.zero);

      expect(notifier.state.status, CircleDetailStatus.loaded);
      expect(notifier.state.circle, isNotNull);
      expect(notifier.state.circle!.name, 'Trauma Shift Crew');
      expect(notifier.state.circle!.members.length, 2);
    });

    test('updateMemberVisibility updates policy', () async {
      final notifier = CircleDetailNotifier(
        repository: mockRepo,
        circleId: 42,
      );
      await Future.delayed(Duration.zero);

      final success = await notifier.updateMemberVisibility(
        memberId: 102,
        visibility: 'shifts',
      );

      expect(success, isTrue);
      expect(mockRepo.lastUpdatedVisibility, 'shifts');
      final updatedMember = notifier.state.circle!.members.firstWhere((m) => m.id == 102);
      expect(updatedMember.visibility, 'shifts');
    });

    test('updateMemberType switches between working and viewer', () async {
      final notifier = CircleDetailNotifier(
        repository: mockRepo,
        circleId: 42,
      );
      await Future.delayed(Duration.zero);

      final success = await notifier.updateMemberType(
        memberId: 102,
        memberType: 'viewer',
      );

      expect(success, isTrue);
      expect(mockRepo.lastUpdatedType, 'viewer');
      final updatedMember = notifier.state.circle!.members.firstWhere((m) => m.id == 102);
      expect(updatedMember.memberType, 'viewer');
    });

    test('updateMemberRole promotes member to admin', () async {
      final notifier = CircleDetailNotifier(
        repository: mockRepo,
        circleId: 42,
      );
      await Future.delayed(Duration.zero);

      final success = await notifier.updateMemberRole(
        memberId: 102,
        role: 'admin',
      );

      expect(success, isTrue);
      expect(mockRepo.lastUpdatedRole, 'admin');
      final updatedMember = notifier.state.circle!.members.firstWhere((m) => m.id == 102);
      expect(updatedMember.role, 'admin');
    });

    test('removeMember removes member from state list', () async {
      final notifier = CircleDetailNotifier(
        repository: mockRepo,
        circleId: 42,
      );
      await Future.delayed(Duration.zero);

      final success = await notifier.removeMember(102);

      expect(success, isTrue);
      expect(mockRepo.lastRemovedMemberId, 102);
      expect(notifier.state.circle!.members.length, 1);
      expect(notifier.state.circle!.members.any((m) => m.id == 102), isFalse);
    });

    test('deleteCircle deletes circle and marks status as deleted', () async {
      final notifier = CircleDetailNotifier(
        repository: mockRepo,
        circleId: 42,
      );
      await Future.delayed(Duration.zero);

      final success = await notifier.deleteCircle();

      expect(success, isTrue);
      expect(mockRepo.deleteCircleCalled, isTrue);
      expect(notifier.state.status, CircleDetailStatus.deleted);
    });

    test('leaveCircle removes current user membership', () async {
      final notifier = CircleDetailNotifier(
        repository: mockRepo,
        circleId: 42,
      );
      await Future.delayed(Duration.zero);

      final success = await notifier.leaveCircle(1);

      expect(success, isTrue);
      expect(mockRepo.lastRemovedMemberId, 101);
      expect(notifier.state.status, CircleDetailStatus.deleted);
    });
  });

  group('MemberItemTile Widget Tests', () {
    testWidgets('renders member details and handles permissions correctly', (WidgetTester tester) async {
      final member = testCircle.members[1]; // John Miller (regular member)
      String? changedType;
      String? changedVis;
      String? changedRole;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MemberItemTile(
              member: member,
              canManageMembers: true,
              canManageRoles: true,
              isCurrentAuthUser: false,
              isActionInProgress: false,
              onUpdateType: (val) => changedType = val,
              onUpdateVisibility: (val) => changedVis = val,
              onUpdateRole: (val) => changedRole = val,
              onRemoveMember: () {},
            ),
          ),
        ),
      );

      expect(find.text('John Miller'), findsOneWidget);
      expect(find.text('@jmiller'), findsOneWidget);
      expect(find.text('MEMBER'), findsOneWidget);
      expect(find.text('Working'), findsOneWidget);
      expect(find.text('Free/Busy Only'), findsOneWidget);

      // Verify role change popup button exists
      await tester.tap(find.text('MEMBER'));
      await tester.pumpAndSettle();
      expect(find.text('Admin'), findsOneWidget);

      await tester.tap(find.text('Admin'));
      await tester.pumpAndSettle();
      expect(changedRole, 'admin');

      // Test changing type
      await tester.tap(find.text('Working'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Viewer (No Match Calculation)'));
      await tester.pumpAndSettle();
      expect(changedType, 'viewer');

      // Test changing visibility
      await tester.tap(find.text('Free/Busy Only'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Shifts Category'));
      await tester.pumpAndSettle();
      expect(changedVis, 'shifts');
    });
  });

  group('CircleSettingsModal Widget Tests', () {
    testWidgets('renders circle info and danger zone for owner', (WidgetTester tester) async {
      bool deleteCalled = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CircleSettingsModal(
              circle: testCircle,
              onLeaveCircle: () {},
              onDeleteCircle: () => deleteCalled = true,
            ),
          ),
        ),
      );

      expect(find.text('Circle Settings'), findsOneWidget);
      expect(find.text('Trauma Shift Crew'), findsOneWidget);
      expect(find.text('@trauma-crew'), findsOneWidget);
      expect(find.text('Private Circle'), findsOneWidget);
      expect(find.text('Danger Zone'), findsOneWidget);
      expect(find.text('Delete Circle'), findsOneWidget);

      await tester.tap(find.text('Delete Circle'));
      await tester.pumpAndSettle();
      expect(find.text('Delete Circle?'), findsOneWidget);
      await tester.tap(find.text('Delete Permanently'));
      await tester.pumpAndSettle();
      expect(deleteCalled, isTrue);
    });

    testWidgets('renders leave circle option for regular member', (WidgetTester tester) async {
      bool leaveCalled = false;
      final nonOwnerCircle = testCircle.copyWith(myRole: 'member');

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CircleSettingsModal(
              circle: nonOwnerCircle,
              onLeaveCircle: () => leaveCalled = true,
              onDeleteCircle: () {},
            ),
          ),
        ),
      );

      expect(find.text('Circle Membership'), findsOneWidget);
      expect(find.text('Leave Circle'), findsOneWidget);

      await tester.tap(find.text('Leave Circle'));
      await tester.pumpAndSettle();
      expect(find.text('Leave Circle?'), findsOneWidget);
      await tester.tap(find.text('Leave'));
      await tester.pumpAndSettle();
      expect(leaveCalled, isTrue);
    });
  });

  group('CircleDetailScreen Widget Tests', () {
    testWidgets('renders full circle screen with header and member roster', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(800, 1400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final authUser = testCircle.members.first.user!;

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            circleRepositoryProvider.overrideWithValue(mockRepo),
            authNotifierProvider.overrideWith((ref) => MockAuthNotifier(AuthState.authenticated(authUser))),
          ],
          child: const MaterialApp(
            home: CircleDetailScreen(circleId: 42),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Trauma Shift Crew'), findsWidgets);
      expect(find.text('@trauma-crew'), findsWidgets);
      expect(find.text('ROLE: OWNER'), findsOneWidget);
      expect(find.text('Invite'), findsOneWidget);
      expect(find.text('Compare'), findsOneWidget);
      expect(find.text('Circle Members & Privacy Roster'), findsOneWidget);
      expect(find.text('2 members'), findsOneWidget);
      expect(find.text('Dr. Sarah Connor'), findsOneWidget);
      expect(find.text('John Miller'), findsOneWidget);
    });
  });
}
