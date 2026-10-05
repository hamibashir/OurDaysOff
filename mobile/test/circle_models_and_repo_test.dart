import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:our_days_off/core/network/api_client.dart';
import 'package:our_days_off/core/storage/secure_storage_service.dart';
import 'package:our_days_off/features/auth/models/user_model.dart';
import 'package:our_days_off/features/circles/data/circle_repository.dart';
import 'package:our_days_off/features/circles/models/activity_event.dart';
import 'package:our_days_off/features/circles/models/circle_invite.dart';
import 'package:our_days_off/features/circles/models/circle_member.dart';
import 'package:our_days_off/features/circles/models/circle_model.dart';

class MockSecureStorage extends Fake implements SecureStorageService {
  @override
  Future<String?> getAuthToken() async => 'fake_token';
}

class FakeApiClient extends ApiClient {
  dynamic nextGetResponse;
  dynamic nextPostResponse;
  dynamic nextPutResponse;
  dynamic nextDeleteResponse;

  String? lastGetPath;
  String? lastPostPath;
  String? lastPutPath;
  String? lastDeletePath;
  dynamic lastPostData;
  dynamic lastPutData;

  FakeApiClient() : super(storage: MockSecureStorage());

  @override
  Future<dynamic> get(
    String path, {
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    lastGetPath = path;
    return nextGetResponse;
  }

  @override
  Future<dynamic> post(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    lastPostPath = path;
    lastPostData = data;
    return nextPostResponse;
  }

  @override
  Future<dynamic> put(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    lastPutPath = path;
    lastPutData = data;
    return nextPutResponse;
  }

  @override
  Future<dynamic> delete(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    lastDeletePath = path;
    return nextDeleteResponse;
  }
}

void main() {
  late FakeApiClient fakeApiClient;
  late CircleRepository repository;

  setUp(() {
    fakeApiClient = FakeApiClient();
    repository = CircleRepository(apiClient: fakeApiClient);
  });

  group('CircleMember Model Tests', () {
    test('parses json correctly with nested user', () {
      final json = {
        'id': 10,
        'circle_id': 1,
        'user_id': 5,
        'role': 'owner',
        'member_type': 'working',
        'visibility': 'details',
        'status': 'active',
        'joined_at': '2026-10-01T10:00:00Z',
        'user': {
          'id': 5,
          'name': 'Sarah Connor',
          'email': 'sarah@example.com',
          'handle': 'sarahc',
        },
      };

      final member = CircleMember.fromJson(json);
      expect(member.id, 10);
      expect(member.circleId, 1);
      expect(member.userId, 5);
      expect(member.isOwner, isTrue);
      expect(member.isAdmin, isFalse);
      expect(member.isOwnerOrAdmin, isTrue);
      expect(member.isWorking, isTrue);
      expect(member.displayName, 'Sarah Connor');
      expect(member.handle, 'sarahc');
      expect(member.initials, 'SC');
    });

    test('serializes to json correctly', () {
      const member = CircleMember(
        id: 11,
        circleId: 2,
        userId: 6,
        role: 'admin',
        memberType: 'viewer',
        visibility: 'free_busy',
      );

      final json = member.toJson();
      expect(json['id'], 11);
      expect(json['role'], 'admin');
      expect(json['member_type'], 'viewer');
      expect(json['visibility'], 'free_busy');
    });
  });

  group('CircleModel Tests', () {
    test('parses json correctly with members list and role', () {
      final json = {
        'id': 1,
        'owner_id': 5,
        'name': 'ICU Ward Team',
        'handle': 'icu-team',
        'discoverability': 'private',
        'members_count': 3,
        'my_role': 'owner',
        'my_member_type': 'working',
        'my_visibility': 'details',
        'members': [
          {
            'id': 1,
            'circle_id': 1,
            'user_id': 5,
            'role': 'owner',
            'user': {'id': 5, 'name': 'Sarah', 'email': 's@ex.com'}
          }
        ],
      };

      final circle = CircleModel.fromJson(json);
      expect(circle.id, 1);
      expect(circle.name, 'ICU Ward Team');
      expect(circle.displayHandle, '@icu-team');
      expect(circle.isPrivate, isTrue);
      expect(circle.isOwner, isTrue);
      expect(circle.membersCount, 3);
      expect(circle.members.length, 1);
    });

    test('copyWith updates specified properties', () {
      const circle = CircleModel(
        id: 1,
        ownerId: 5,
        name: 'Alpha Team',
        myRole: 'member',
      );

      final updated = circle.copyWith(name: 'Beta Team', myRole: 'admin');
      expect(updated.name, 'Beta Team');
      expect(updated.myRole, 'admin');
      expect(updated.id, 1);
    });
  });

  group('CircleInvite Model Tests', () {
    test('parses and checks expiration and usage limits', () {
      final validJson = {
        'invite_code': 'ABC123',
        'invite_url': 'https://ourdaysoff.com/join?code=ABC123',
        'expires_at': DateTime.now().add(const Duration(days: 7)).toIso8601String(),
        'max_uses': 5,
        'uses': 2,
      };

      final invite = CircleInvite.fromJson(validJson);
      expect(invite.inviteCode, 'ABC123');
      expect(invite.isExpired, isFalse);
      expect(invite.isMaxed, isFalse);
      expect(invite.isValid, isTrue);

      final expiredJson = {
        'invite_code': 'EXPIRED',
        'invite_url': '',
        'expires_at': DateTime.now().subtract(const Duration(days: 1)).toIso8601String(),
        'uses': 0,
      };
      final expiredInvite = CircleInvite.fromJson(expiredJson);
      expect(expiredInvite.isExpired, isTrue);
      expect(expiredInvite.isValid, isFalse);
    });
  });

  group('ActivityEvent Model Tests', () {
    test('parses event and formats human-friendly description', () {
      final json = {
        'id': 1,
        'circle_id': 1,
        'actor_id': 5,
        'event_type': 'member_joined',
        'created_at': '2026-10-02T12:00:00Z',
        'actor': {
          'id': 5,
          'name': 'John Connor',
          'email': 'john@example.com',
        },
      };

      final event = ActivityEvent.fromJson(json);
      expect(event.actorName, 'John Connor');
      expect(event.description, 'John Connor joined the circle');

      final planEvent = ActivityEvent(
        id: 2,
        circleId: 1,
        actorId: 5,
        eventType: 'plan_created',
        metadata: {'title': 'Friday Dinner'},
        createdAt: DateTime.now(),
        actor: const UserModel(id: 5, name: 'John', email: 'j@ex.com'),
      );
      expect(planEvent.description, 'John created plan "Friday Dinner"');
    });
  });

  group('CircleRepository Tests', () {
    test('getCircles calls GET /circles and returns parsed list', () async {
      fakeApiClient.nextGetResponse = {
        'data': [
          {
            'id': 1,
            'owner_id': 2,
            'name': 'Friends Circle',
            'discoverability': 'private',
            'members_count': 4,
          }
        ]
      };

      final circles = await repository.getCircles();
      expect(circles.length, 1);
      expect(circles.first.name, 'Friends Circle');
      expect(fakeApiClient.lastGetPath, '/circles');
    });

    test('createCircle calls POST /circles with payload', () async {
      fakeApiClient.nextPostResponse = {
        'data': {
          'id': 2,
          'owner_id': 1,
          'name': 'Night Shift Crew',
          'handle': 'nightcrew',
          'discoverability': 'searchable',
        }
      };

      final circle = await repository.createCircle(
        name: 'Night Shift Crew',
        handle: 'nightcrew',
        discoverability: 'searchable',
      );

      expect(circle.id, 2);
      expect(circle.name, 'Night Shift Crew');
      expect(fakeApiClient.lastPostPath, '/circles');
      expect(fakeApiClient.lastPostData['name'], 'Night Shift Crew');
      expect(fakeApiClient.lastPostData['handle'], 'nightcrew');
    });

    test('getCircle calls GET /circles/{id}', () async {
      fakeApiClient.nextGetResponse = {
        'data': {
          'id': 5,
          'owner_id': 1,
          'name': 'Detail Circle',
          'members': [],
        }
      };

      final circle = await repository.getCircle(5);
      expect(circle.id, 5);
      expect(fakeApiClient.lastGetPath, '/circles/5');
    });

    test('deleteCircle calls DELETE /circles/{id}', () async {
      fakeApiClient.nextDeleteResponse = {'message': 'Deleted'};

      await repository.deleteCircle(5);
      expect(fakeApiClient.lastDeletePath, '/circles/5');
    });

    test('updateMember calls PUT /circles/{id}/members/{memberId}', () async {
      fakeApiClient.nextPutResponse = {
        'data': {
          'id': 8,
          'circle_id': 5,
          'user_id': 2,
          'role': 'admin',
          'visibility': 'shifts',
        }
      };

      final member = await repository.updateMember(
        circleId: 5,
        memberId: 8,
        role: 'admin',
        visibility: 'shifts',
      );

      expect(member.role, 'admin');
      expect(fakeApiClient.lastPutPath, '/circles/5/members/8');
      expect(fakeApiClient.lastPutData['role'], 'admin');
      expect(fakeApiClient.lastPutData['visibility'], 'shifts');
    });

    test('removeMember calls DELETE /circles/{id}/members/{memberId}', () async {
      fakeApiClient.nextDeleteResponse = {'message': 'Removed'};

      await repository.removeMember(circleId: 5, memberId: 8);
      expect(fakeApiClient.lastDeletePath, '/circles/5/members/8');
    });

    test('getCircleActivity calls GET /circles/{id}/activity', () async {
      fakeApiClient.nextGetResponse = {
        'data': [
          {
            'id': 1,
            'circle_id': 5,
            'actor_id': 1,
            'event_type': 'schedule_updated',
            'created_at': '2026-10-04T12:00:00Z',
          }
        ]
      };

      final events = await repository.getCircleActivity(5);
      expect(events.length, 1);
      expect(events.first.eventType, 'schedule_updated');
      expect(fakeApiClient.lastGetPath, '/circles/5/activity');
    });

    test('createInvite calls POST /circles/{id}/invites', () async {
      fakeApiClient.nextPostResponse = {
        'data': {
          'invite_code': 'JOIN42',
          'invite_url': 'https://app.com/join?code=JOIN42',
          'max_uses': 10,
          'uses': 0,
        }
      };

      final invite = await repository.createInvite(circleId: 5, maxUses: 10);
      expect(invite.inviteCode, 'JOIN42');
      expect(fakeApiClient.lastPostPath, '/circles/5/invites');
      expect(fakeApiClient.lastPostData['max_uses'], 10);
    });

    test('joinCircle calls POST /invites/join with invite_code', () async {
      fakeApiClient.nextPostResponse = {
        'data': {
          'id': 9,
          'owner_id': 2,
          'name': 'Joined Circle',
        }
      };

      final circle = await repository.joinCircle('join42');
      expect(circle.id, 9);
      expect(fakeApiClient.lastPostPath, '/invites/join');
      expect(fakeApiClient.lastPostData['invite_code'], 'JOIN42');
    });
  });
}
