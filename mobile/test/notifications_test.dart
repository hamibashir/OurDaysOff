import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:our_days_off/features/notifications/data/notification_repository.dart';
import 'package:our_days_off/features/notifications/models/notification_model.dart';
import 'package:our_days_off/features/notifications/providers/notification_provider.dart';
import 'package:our_days_off/features/notifications/views/notifications_screen.dart';
import 'package:our_days_off/features/notifications/views/widgets/notification_bell_button.dart';

class FakeNotificationRepository extends Fake implements NotificationRepository {
  List<NotificationModel> notifications = [];
  int markAsReadCallCount = 0;
  int markAllAsReadCallCount = 0;

  @override
  Future<NotificationsResponse> getNotifications() async {
    final unread = notifications.where((n) => !n.isRead).length;
    return NotificationsResponse(
      data: List.from(notifications),
      unreadCount: unread,
    );
  }

  @override
  Future<NotificationModel> markAsRead(int id) async {
    markAsReadCallCount++;
    final index = notifications.indexWhere((n) => n.id == id);
    if (index != -1) {
      final updated = notifications[index].copyWith(readAt: DateTime.now());
      notifications[index] = updated;
      return updated;
    }
    return NotificationModel(
      id: id,
      userId: 1,
      type: 'test',
      title: 'Test',
      body: 'Test',
      readAt: DateTime.now(),
      createdAt: DateTime.now(),
    );
  }

  @override
  Future<void> markAllAsRead() async {
    markAllAsReadCallCount++;
    final now = DateTime.now();
    notifications = notifications.map((n) => n.isRead ? n : n.copyWith(readAt: now)).toList();
  }
}

void main() {
  group('NotificationModel & NotificationsResponse Tests', () {
    test('serializes to and from json correctly', () {
      final json = {
        'id': 101,
        'user_id': 202,
        'type': 'plan_invite',
        'title': 'New Meetup',
        'body': 'You are invited to lunch',
        'data': {'plan_id': 5, 'url': '/plans/5'},
        'read_at': '2026-10-06T00:00:00.000Z',
        'created_at': '2026-10-05T12:00:00.000Z',
      };

      final model = NotificationModel.fromJson(json);
      expect(model.id, 101);
      expect(model.userId, 202);
      expect(model.type, 'plan_invite');
      expect(model.title, 'New Meetup');
      expect(model.body, 'You are invited to lunch');
      expect(model.isRead, isTrue);
      expect(model.data?['plan_id'], 5);

      final exported = model.toJson();
      expect(exported['id'], 101);
      expect(exported['type'], 'plan_invite');
      expect(exported['read_at'], isNotNull);
    });

    test('unread notification has isRead == false', () {
      final json = {
        'id': 102,
        'user_id': 202,
        'type': 'circle_member_joined',
        'title': 'New Member',
        'body': 'Bob joined your circle',
        'read_at': null,
        'created_at': '2026-10-05T12:00:00.000Z',
      };

      final model = NotificationModel.fromJson(json);
      expect(model.isRead, isFalse);
      expect(model.readAt, isNull);
    });

    test('NotificationsResponse parses list and unread count', () {
      final json = {
        'data': [
          {
            'id': 1,
            'user_id': 10,
            'type': 'plan_created',
            'title': 'Plan 1',
            'body': 'Body 1',
            'read_at': null,
            'created_at': '2026-10-05T12:00:00.000Z',
          },
          {
            'id': 2,
            'user_id': 10,
            'type': 'circle_invite',
            'title': 'Plan 2',
            'body': 'Body 2',
            'read_at': '2026-10-05T12:30:00.000Z',
            'created_at': '2026-10-05T12:00:00.000Z',
          },
        ],
        'unread_count': 1,
      };

      final res = NotificationsResponse.fromJson(json);
      expect(res.data.length, 2);
      expect(res.unreadCount, 1);
      expect(res.data.first.isRead, isFalse);
      expect(res.data.last.isRead, isTrue);
    });
  });

  group('NotificationNotifier Tests', () {
    late FakeNotificationRepository fakeRepo;

    setUp(() {
      fakeRepo = FakeNotificationRepository();
      fakeRepo.notifications = [
        NotificationModel(
          id: 1,
          userId: 10,
          type: 'plan_invite',
          title: 'Meetup Invitation',
          body: 'Come along!',
          readAt: null,
          createdAt: DateTime.now(),
        ),
        NotificationModel(
          id: 2,
          userId: 10,
          type: 'shift_change',
          title: 'Shift Updated',
          body: 'Rota changed',
          readAt: null,
          createdAt: DateTime.now(),
        ),
      ];
    });

    test('loadNotifications sets unreadCount and notifications list', () async {
      final notifier = NotificationNotifier(fakeRepo);
      await notifier.loadNotifications();

      expect(notifier.state.notifications.length, 2);
      expect(notifier.state.unreadCount, 2);
      notifier.dispose();
    });

    test('markAsRead optimistically decrements unreadCount and marks item read', () async {
      final notifier = NotificationNotifier(fakeRepo);
      await notifier.loadNotifications();

      await notifier.markAsRead(1);

      expect(notifier.state.unreadCount, 1);
      expect(notifier.state.notifications.firstWhere((n) => n.id == 1).isRead, isTrue);
      expect(fakeRepo.markAsReadCallCount, 1);
      notifier.dispose();
    });

    test('markAllAsRead optimistically marks all items read and resets count to 0', () async {
      final notifier = NotificationNotifier(fakeRepo);
      await notifier.loadNotifications();

      await notifier.markAllAsRead();

      expect(notifier.state.unreadCount, 0);
      expect(notifier.state.notifications.every((n) => n.isRead), isTrue);
      expect(fakeRepo.markAllAsReadCallCount, 1);
      notifier.dispose();
    });
  });

  group('NotificationBellButton Widget Tests', () {
    testWidgets('renders bell icon without badge when unreadCount is 0', (tester) async {
      final fakeRepo = FakeNotificationRepository();
      fakeRepo.notifications = [];

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            notificationRepositoryProvider.overrideWithValue(fakeRepo),
          ],
          child: const MaterialApp(
            home: Scaffold(
              body: NotificationBellButton(),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.notifications_none), findsOneWidget);
      expect(find.text('0'), findsNothing);
    });

    testWidgets('renders badge counter when unreadCount > 0', (tester) async {
      final fakeRepo = FakeNotificationRepository();
      fakeRepo.notifications = [
        NotificationModel(
          id: 1,
          userId: 1,
          type: 'test',
          title: 'Test',
          body: 'Body',
          readAt: null,
          createdAt: DateTime.now(),
        ),
        NotificationModel(
          id: 2,
          userId: 1,
          type: 'test',
          title: 'Test 2',
          body: 'Body 2',
          readAt: null,
          createdAt: DateTime.now(),
        ),
      ];

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            notificationRepositoryProvider.overrideWithValue(fakeRepo),
          ],
          child: const MaterialApp(
            home: Scaffold(
              body: NotificationBellButton(),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.notifications_active_outlined), findsOneWidget);
      expect(find.text('2'), findsOneWidget);
    });
  });

  group('NotificationsScreen Widget Tests', () {
    testWidgets('displays empty state when there are no notifications', (tester) async {
      final fakeRepo = FakeNotificationRepository();
      fakeRepo.notifications = [];

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            notificationRepositoryProvider.overrideWithValue(fakeRepo),
          ],
          child: const MaterialApp(
            home: NotificationsScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('No notifications yet'), findsOneWidget);
      expect(find.text("You're all caught up! Circle updates, rota changes, and meetup invites will appear here."), findsOneWidget);
      expect(find.text('Read all'), findsNothing);
    });

    testWidgets('renders notifications and allows marking single and all as read', (tester) async {
      final fakeRepo = FakeNotificationRepository();
      fakeRepo.notifications = [
        NotificationModel(
          id: 1,
          userId: 1,
          type: 'plan_invite',
          title: 'Weekend BBQ',
          body: 'You were invited to BBQ by Sarah',
          readAt: null,
          createdAt: DateTime.now().subtract(const Duration(minutes: 5)),
        ),
        NotificationModel(
          id: 2,
          userId: 1,
          type: 'circle_joined',
          title: 'New Member',
          body: 'Alex joined ER Team',
          readAt: DateTime.now().subtract(const Duration(hours: 1)),
          createdAt: DateTime.now().subtract(const Duration(hours: 1)),
        ),
      ];

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            notificationRepositoryProvider.overrideWithValue(fakeRepo),
          ],
          child: const MaterialApp(
            home: NotificationsScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Notifications'), findsOneWidget);
      expect(find.text('1 new'), findsOneWidget);
      expect(find.text('Weekend BBQ'), findsOneWidget);
      expect(find.text('Alex joined ER Team'), findsOneWidget);
      expect(find.text('Read all'), findsOneWidget);

      // Tap single mark as read
      final checkButton = find.byTooltip('Mark as read');
      expect(checkButton, findsOneWidget);
      await tester.tap(checkButton);
      await tester.pumpAndSettle();

      expect(fakeRepo.markAsReadCallCount, 1);
      expect(find.text('1 new'), findsNothing);
      expect(find.text('Read all'), findsNothing);
    });

    testWidgets('tapping Read all marks all items as read', (tester) async {
      final fakeRepo = FakeNotificationRepository();
      fakeRepo.notifications = [
        NotificationModel(
          id: 10,
          userId: 1,
          type: 'plan_created',
          title: 'Plan A',
          body: 'Description A',
          readAt: null,
          createdAt: DateTime.now(),
        ),
        NotificationModel(
          id: 11,
          userId: 1,
          type: 'shift_assigned',
          title: 'Plan B',
          body: 'Description B',
          readAt: null,
          createdAt: DateTime.now(),
        ),
      ];

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            notificationRepositoryProvider.overrideWithValue(fakeRepo),
          ],
          child: const MaterialApp(
            home: NotificationsScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('2 new'), findsOneWidget);
      await tester.tap(find.text('Read all'));
      await tester.pumpAndSettle();

      expect(fakeRepo.markAllAsReadCallCount, 1);
      expect(find.text('2 new'), findsNothing);
      expect(find.text('Read all'), findsNothing);
    });
  });
}
