import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:our_days_off/features/circles/data/circle_repository.dart';
import 'package:our_days_off/features/circles/models/circle_model.dart';
import 'package:our_days_off/features/circles/providers/circles_notifier.dart';
import 'package:our_days_off/features/circles/providers/circles_state.dart';
import 'package:our_days_off/features/circles/views/circles_screen.dart';
import 'package:our_days_off/features/circles/views/widgets/circle_card.dart';
import 'package:our_days_off/features/circles/views/widgets/create_circle_modal.dart';
import 'package:our_days_off/features/circles/views/widgets/join_circle_modal.dart';

class MockCircleRepository extends Fake implements CircleRepository {
  List<CircleModel> mockCircles = [];
  bool getCirclesCalled = false;
  String? lastCreatedName;
  String? lastJoinedCode;

  @override
  Future<List<CircleModel>> getCircles() async {
    getCirclesCalled = true;
    return List<CircleModel>.from(mockCircles);
  }

  @override
  Future<CircleModel> createCircle({
    required String name,
    String? handle,
    String discoverability = 'private',
  }) async {
    lastCreatedName = name;
    final circle = CircleModel(
      id: 99,
      ownerId: 1,
      name: name,
      handle: handle,
      discoverability: discoverability,
      myRole: 'owner',
      membersCount: 1,
    );
    mockCircles.insert(0, circle);
    return circle;
  }

  @override
  Future<CircleModel> joinCircle(String inviteCode) async {
    lastJoinedCode = inviteCode;
    const circle = CircleModel(
      id: 88,
      ownerId: 2,
      name: 'Joined Circle',
      myRole: 'member',
      membersCount: 5,
    );
    mockCircles.add(circle);
    return circle;
  }
}

void main() {
  late MockCircleRepository mockRepo;

  setUp(() {
    mockRepo = MockCircleRepository();
  });

  group('CirclesNotifier Unit Tests', () {
    test('initial state loads circles from repository', () async {
      mockRepo.mockCircles = [
        const CircleModel(id: 1, ownerId: 1, name: 'Night Crew', handle: 'night'),
        const CircleModel(id: 2, ownerId: 2, name: 'Day Team', handle: 'day'),
      ];

      final notifier = CirclesNotifier(mockRepo);
      // Wait for async loadCircles
      await Future.delayed(Duration.zero);

      expect(notifier.state.status, CirclesStatus.loaded);
      expect(notifier.state.circles.length, 2);
      expect(mockRepo.getCirclesCalled, isTrue);
    });

    test('search query filters circles by name and handle', () async {
      mockRepo.mockCircles = [
        const CircleModel(id: 1, ownerId: 1, name: 'Intensive Care Unit', handle: 'icu-ward'),
        const CircleModel(id: 2, ownerId: 2, name: 'Flight Dispatch', handle: 'dispatch'),
        const CircleModel(id: 3, ownerId: 3, name: 'Pediatrics Team', handle: 'peds'),
      ];

      final notifier = CirclesNotifier(mockRepo);
      await Future.delayed(Duration.zero);

      notifier.setSearchQuery('care');
      expect(notifier.state.filteredCircles.length, 1);
      expect(notifier.state.filteredCircles.first.name, 'Intensive Care Unit');

      notifier.setSearchQuery('dispatch');
      expect(notifier.state.filteredCircles.length, 1);
      expect(notifier.state.filteredCircles.first.name, 'Flight Dispatch');

      notifier.setSearchQuery('unknown');
      expect(notifier.state.filteredCircles.isEmpty, isTrue);
    });

    test('createCircle prepends new circle to list', () async {
      mockRepo.mockCircles = [];
      final notifier = CirclesNotifier(mockRepo);
      await Future.delayed(Duration.zero);

      final created = await notifier.createCircle(
        name: 'Paramedic Squad',
        handle: 'paramedics',
        discoverability: 'private',
      );

      expect(created, isNotNull);
      expect(created!.name, 'Paramedic Squad');
      expect(notifier.state.circles.length, 1);
      expect(mockRepo.lastCreatedName, 'Paramedic Squad');
    });

    test('joinCircle appends circle to list', () async {
      mockRepo.mockCircles = [];
      final notifier = CirclesNotifier(mockRepo);
      await Future.delayed(Duration.zero);

      final joined = await notifier.joinCircle('CODE42');
      expect(joined, isNotNull);
      expect(joined!.name, 'Joined Circle');
      expect(notifier.state.circles.length, 1);
      expect(mockRepo.lastJoinedCode, 'CODE42');
    });
  });

  group('CircleCard Widget Tests', () {
    testWidgets('renders name, handle, role, and members count', (WidgetTester tester) async {
      bool tapped = false;
      const circle = CircleModel(
        id: 10,
        ownerId: 1,
        name: 'Cardiac Surgery Ward',
        handle: 'cardiac-team',
        discoverability: 'private',
        myRole: 'owner',
        membersCount: 8,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CircleCard(
              circle: circle,
              onTap: () => tapped = true,
            ),
          ),
        ),
      );

      expect(find.text('Cardiac Surgery Ward'), findsOneWidget);
      expect(find.text('@cardiac-team'), findsOneWidget);
      expect(find.text('OWNER'), findsOneWidget);
      expect(find.text('8 members'), findsOneWidget);
      expect(find.text('Private Circle'), findsOneWidget);

      await tester.tap(find.byType(CircleCard));
      await tester.pumpAndSettle();
      expect(tapped, isTrue);
    });
  });

  group('CreateCircleModal Widget Tests', () {
    testWidgets('enters name and creates circle', (WidgetTester tester) async {
      CircleModel? result;

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            circleRepositoryProvider.overrideWithValue(mockRepo),
          ],
          child: MaterialApp(
            home: Scaffold(
              body: Builder(
                builder: (context) => ElevatedButton(
                  onPressed: () async {
                    result = await CreateCircleModal.show(context);
                  },
                  child: const Text('Open Modal'),
                ),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open Modal'));
      await tester.pumpAndSettle();

      expect(find.text('Create New Circle'), findsOneWidget);

      // Enter circle name
      final nameField = find.widgetWithText(TextField, 'e.g. ICU Shift Crew, Aviation Team');
      await tester.enterText(nameField, 'Emergency Room Crew');
      await tester.pumpAndSettle();

      // Tap Create Circle button
      await tester.tap(find.text('Create Circle'));
      await tester.pumpAndSettle();

      expect(result, isNotNull);
      expect(result!.name, 'Emergency Room Crew');
      expect(mockRepo.lastCreatedName, 'Emergency Room Crew');
    });
  });

  group('JoinCircleModal Widget Tests', () {
    testWidgets('enters invite code and joins circle', (WidgetTester tester) async {
      CircleModel? result;

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            circleRepositoryProvider.overrideWithValue(mockRepo),
          ],
          child: MaterialApp(
            home: Scaffold(
              body: Builder(
                builder: (context) => ElevatedButton(
                  onPressed: () async {
                    result = await JoinCircleModal.show(context);
                  },
                  child: const Text('Open Join'),
                ),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open Join'));
      await tester.pumpAndSettle();

      expect(find.text('Join a Circle'), findsOneWidget);

      // Enter invite code
      final codeField = find.widgetWithText(TextField, 'e.g. ABC123');
      await tester.enterText(codeField, 'JOIN42');
      await tester.pumpAndSettle();

      // Tap Join Circle button
      await tester.tap(find.text('Join Circle'));
      await tester.pumpAndSettle();

      expect(result, isNotNull);
      expect(result!.name, 'Joined Circle');
      expect(mockRepo.lastJoinedCode, 'JOIN42');
    });
  });

  group('CirclesScreen Widget Tests', () {
    testWidgets('renders empty state when user has no circles', (WidgetTester tester) async {
      mockRepo.mockCircles = [];

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            circleRepositoryProvider.overrideWithValue(mockRepo),
          ],
          child: const MaterialApp(
            home: CirclesScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('My Circles'), findsOneWidget);
      expect(find.text('No Circles Yet'), findsOneWidget);
      expect(find.text('Create a Circle'), findsOneWidget);
      expect(find.text('Join with Code'), findsOneWidget);
    });

    testWidgets('renders list of circles and filters via search', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(800, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      mockRepo.mockCircles = [
        const CircleModel(id: 1, ownerId: 1, name: 'ICU Nurses', handle: 'icu-nurses', membersCount: 12),
        const CircleModel(id: 2, ownerId: 2, name: 'Pilot Crew', handle: 'pilots', membersCount: 4),
      ];

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            circleRepositoryProvider.overrideWithValue(mockRepo),
          ],
          child: const MaterialApp(
            home: CirclesScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('ICU Nurses'), findsOneWidget);
      expect(find.text('Pilot Crew'), findsOneWidget);

      // Filter by "pilot"
      final searchField = find.byType(TextField).first;
      await tester.enterText(searchField, 'pilot');
      await tester.pumpAndSettle();

      expect(find.text('Pilot Crew'), findsOneWidget);
      expect(find.text('ICU Nurses'), findsNothing);
    });
  });
}
