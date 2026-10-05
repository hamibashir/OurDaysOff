import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:our_days_off/core/network/api_client.dart';
import 'package:our_days_off/core/storage/secure_storage_service.dart';
import 'package:our_days_off/features/plans/data/plan_repository.dart';
import 'package:our_days_off/features/plans/models/plan_location_model.dart';
import 'package:our_days_off/features/plans/models/plan_member_model.dart';
import 'package:our_days_off/features/plans/models/plan_message_model.dart';
import 'package:our_days_off/features/plans/models/plan_model.dart';
import 'package:our_days_off/features/plans/models/plan_option_model.dart';
import 'package:our_days_off/features/plans/providers/plan_providers.dart';

class MockSecureStorage extends Fake implements SecureStorageService {
  @override
  Future<String?> getAuthToken() async => 'fake_token';
}

class FakeApiClient extends ApiClient {
  dynamic nextGetResponse;
  dynamic nextPostResponse;
  String? lastGetPath;
  String? lastPostPath;
  String? lastDeletePath;
  Map<String, dynamic>? lastGetParams;
  dynamic lastPostData;

  FakeApiClient() : super(storage: MockSecureStorage());

  @override
  Future<dynamic> get(
    String path, {
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    lastGetPath = path;
    lastGetParams = queryParameters;
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
  Future<dynamic> delete(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    lastDeletePath = path;
    return {'message': 'Deleted'};
  }
}

void main() {
  group('PlanMemberModel Tests', () {
    test('parses json and provides correct getters', () {
      final json = {
        'id': 10,
        'plan_id': 100,
        'user_id': 20,
        'rsvp_status': 'attending',
        'responded_at': '2026-10-10T15:30:00.000Z',
        'user': {
          'id': 20,
          'name': 'John Doe',
          'email': 'john@example.com',
          'handle': 'johndoe',
        },
      };

      final member = PlanMemberModel.fromJson(json);
      expect(member.id, 10);
      expect(member.planId, 100);
      expect(member.userId, 20);
      expect(member.rsvpStatus, 'attending');
      expect(member.isAttending, isTrue);
      expect(member.isTentative, isFalse);
      expect(member.isDeclined, isFalse);
      expect(member.isPending, isFalse);
      expect(member.displayName, 'John Doe');
      expect(member.handle, 'johndoe');
      expect(member.initials, 'JD');

      final serialized = member.toJson();
      expect(serialized['id'], 10);
      expect(serialized['rsvp_status'], 'attending');
      expect(serialized['user'], isNotNull);

      final updated = member.copyWith(rsvpStatus: 'declined');
      expect(updated.isDeclined, isTrue);
      expect(updated.isAttending, isFalse);
    });

    test('handles null user gracefully', () {
      final member = PlanMemberModel.fromJson({
        'id': 11,
        'plan_id': 100,
        'user_id': 25,
      });

      expect(member.displayName, 'Member #25');
      expect(member.handle, isNull);
      expect(member.initials, 'M');
      expect(member.isPending, isTrue);
    });
  });

  group('PlanOptionModel Tests', () {
    test('parses and computes duration', () {
      final json = {
        'id': 1,
        'plan_id': 100,
        'start_at': '2026-10-12T10:00:00.000Z',
        'end_at': '2026-10-12T14:30:00.000Z',
        'timezone': 'UTC',
      };

      final option = PlanOptionModel.fromJson(json);
      expect(option.id, 1);
      expect(option.planId, 100);
      expect(option.duration.inMinutes, 270);
      expect(option.timezone, 'UTC');

      final serialized = option.toJson();
      expect(serialized['plan_id'], 100);
      expect(serialized['timezone'], 'UTC');

      final copy = option.copyWith(timezone: 'Asia/Tokyo');
      expect(copy.timezone, 'Asia/Tokyo');
    });
  });

  group('PlanLocationModel & PlanLocationVoteModel Tests', () {
    test('parses location with votes and checks voting helpers', () {
      final json = {
        'id': 5,
        'plan_id': 100,
        'name': 'The Rusty Anchor Pub',
        'address': '123 Harbor View Road',
        'latitude': 51.5074,
        'longitude': -0.1278,
        'notes': 'Booked outdoors on terrace',
        'created_by': 2,
        'creator': {
          'id': 2,
          'name': 'Alice Smith',
          'email': 'alice@example.com',
        },
        'votes': [
          {
            'id': 1,
            'plan_location_id': 5,
            'user_id': 2,
            'created_at': '2026-10-10T12:00:00.000Z',
          },
          {
            'id': 2,
            'plan_location_id': 5,
            'user_id': 3,
            'created_at': '2026-10-10T12:05:00.000Z',
          },
        ],
      };

      final location = PlanLocationModel.fromJson(json);
      expect(location.id, 5);
      expect(location.name, 'The Rusty Anchor Pub');
      expect(location.address, '123 Harbor View Road');
      expect(location.latitude, 51.5074);
      expect(location.longitude, -0.1278);
      expect(location.creator?.name, 'Alice Smith');
      expect(location.voteCount, 2);
      expect(location.hasVoted(2), isTrue);
      expect(location.hasVoted(3), isTrue);
      expect(location.hasVoted(99), isFalse);

      final serialized = location.toJson();
      expect(serialized['name'], 'The Rusty Anchor Pub');
      expect((serialized['votes'] as List).length, 2);
    });
  });

  group('PlanMessageModel Tests', () {
    test('parses and extracts user initials', () {
      final json = {
        'id': 42,
        'plan_id': 100,
        'user_id': 5,
        'body': 'Sounds good! See you all at 7pm.',
        'created_at': '2026-10-10T18:00:00.000Z',
        'user': {
          'id': 5,
          'name': 'Charlie Day',
          'email': 'charlie@example.com',
          'handle': 'cday',
        },
      };

      final message = PlanMessageModel.fromJson(json);
      expect(message.id, 42);
      expect(message.body, 'Sounds good! See you all at 7pm.');
      expect(message.authorName, 'Charlie Day');
      expect(message.authorHandle, 'cday');
      expect(message.authorInitials, 'CD');

      final serialized = message.toJson();
      expect(serialized['body'], 'Sounds good! See you all at 7pm.');
      expect(serialized['user'], isNotNull);
    });

    test('handles fallback when user is null', () {
      final message = PlanMessageModel.fromJson({
        'id': 43,
        'plan_id': 100,
        'user_id': 9,
        'body': 'Hello everyone',
        'created_at': '2026-10-10T18:05:00.000Z',
      });

      expect(message.authorName, 'User #9');
      expect(message.authorHandle, isNull);
      expect(message.authorInitials, 'U');
    });
  });

  group('PlanModel Tests', () {
    test('parses complete plan with all nested models and calculates counts', () {
      final json = {
        'id': 100,
        'circle_id': 1,
        'created_by': 1,
        'title': 'Weekend Mountain Hike',
        'description': 'Hiking the high ridge trail followed by pub lunch',
        'event_type': 'social',
        'start_at': '2026-10-15T09:00:00.000Z',
        'end_at': '2026-10-15T15:00:00.000Z',
        'timezone': 'UTC',
        'status': 'confirmed',
        'created_at': '2026-10-01T10:00:00.000Z',
        'my_rsvp': 'attending',
        'circle': {
          'id': 1,
          'owner_id': 1,
          'name': 'Weekend Warriors',
          'handle': 'warriors',
          'discoverability': 'private',
        },
        'creator': {
          'id': 1,
          'name': 'Dan Miller',
          'email': 'dan@example.com',
        },
        'members': [
          {
            'id': 101,
            'plan_id': 100,
            'user_id': 1,
            'rsvp_status': 'attending',
            'user': {'id': 1, 'name': 'Dan Miller', 'email': 'dan@example.com'},
          },
          {
            'id': 102,
            'plan_id': 100,
            'user_id': 2,
            'rsvp_status': 'tentative',
            'user': {'id': 2, 'name': 'Alice Smith', 'email': 'alice@example.com'},
          },
          {
            'id': 103,
            'plan_id': 100,
            'user_id': 3,
            'rsvp_status': 'declined',
            'user': {'id': 3, 'name': 'Bob Jones', 'email': 'bob@example.com'},
          },
        ],
        'options': [
          {
            'id': 50,
            'plan_id': 100,
            'start_at': '2026-10-15T09:00:00.000Z',
            'end_at': '2026-10-15T15:00:00.000Z',
            'timezone': 'UTC',
          }
        ],
        'locations': [
          {
            'id': 30,
            'plan_id': 100,
            'name': 'Trailhead Carpark',
            'address': 'Old Mountain Road',
            'votes': [],
          }
        ],
        'messages': [
          {
            'id': 200,
            'plan_id': 100,
            'user_id': 1,
            'body': 'Bring water and rain gear!',
            'created_at': '2026-10-02T12:00:00.000Z',
          }
        ],
      };

      final plan = PlanModel.fromJson(json);
      expect(plan.id, 100);
      expect(plan.title, 'Weekend Mountain Hike');
      expect(plan.isConfirmed, isTrue);
      expect(plan.isPolling, isFalse);
      expect(plan.isCreator(1), isTrue);
      expect(plan.isCreator(2), isFalse);
      expect(plan.myRsvp, 'attending');

      expect(plan.circle?.name, 'Weekend Warriors');
      expect(plan.creator?.name, 'Dan Miller');

      expect(plan.members.length, 3);
      expect(plan.attendingCount, 1);
      expect(plan.attendingMembers.first.displayName, 'Dan Miller');
      expect(plan.tentativeMembers.first.displayName, 'Alice Smith');
      expect(plan.declinedMembers.first.displayName, 'Bob Jones');

      expect(plan.hasLocation, isTrue);
      expect(plan.primaryLocation?.name, 'Trailhead Carpark');
      expect(plan.options.length, 1);
      expect(plan.messages.length, 1);
      expect(plan.messages.first.body, 'Bring water and rain gear!');

      final serialized = plan.toJson();
      expect(serialized['id'], 100);
      expect(serialized['circle'], isNotNull);
      expect(serialized['creator'], isNotNull);
      expect((serialized['members'] as List).length, 3);
      expect((serialized['locations'] as List).length, 1);
    });

    test('handles empty / default state gracefully', () {
      final plan = PlanModel.fromJson({
        'id': 101,
        'circle_id': 2,
        'created_by': 4,
        'title': 'Coffee Catchup',
        'status': 'polling',
      });

      expect(plan.isPolling, isTrue);
      expect(plan.isConfirmed, isFalse);
      expect(plan.members, isEmpty);
      expect(plan.options, isEmpty);
      expect(plan.locations, isEmpty);
      expect(plan.messages, isEmpty);
      expect(plan.hasLocation, isFalse);
      expect(plan.primaryLocation, isNull);
      expect(plan.attendingCount, 0);
      expect(plan.myRsvp, 'pending');
    });
  });

  group('PlanRepository API Tests', () {
    late FakeApiClient fakeApi;
    late PlanRepository repository;

    setUp(() {
      fakeApi = FakeApiClient();
      repository = PlanRepository(apiClient: fakeApi);
    });

    test('getPlans calls GET /plans and maps result list', () async {
      fakeApi.nextGetResponse = {
        'data': [
          {
            'id': 1,
            'circle_id': 1,
            'created_by': 1,
            'title': 'Dinner at Luigi’s',
            'event_type': 'meal',
            'status': 'confirmed',
            'my_rsvp': 'attending',
          }
        ]
      };

      final plans = await repository.getPlans();
      expect(fakeApi.lastGetPath, '/plans');
      expect(plans.length, 1);
      expect(plans.first.title, 'Dinner at Luigi’s');
      expect(plans.first.eventType, 'meal');
    });

    test('getPlan calls GET /plans/{id} and maps detail', () async {
      fakeApi.nextGetResponse = {
        'data': {
          'id': 55,
          'circle_id': 2,
          'created_by': 3,
          'title': 'Board Games Evening',
          'event_type': 'social',
          'status': 'polling',
        }
      };

      final plan = await repository.getPlan(55);
      expect(fakeApi.lastGetPath, '/plans/55');
      expect(plan.id, 55);
      expect(plan.title, 'Board Games Evening');
    });

    test('createPlan sends POST /plans with payload', () async {
      fakeApi.nextPostResponse = {
        'message': 'Plan created successfully.',
        'data': {
          'id': 77,
          'circle_id': 10,
          'created_by': 1,
          'title': 'Bouldering Session',
          'event_type': 'social',
          'start_at': '2026-10-18 10:00:00',
          'end_at': '2026-10-18 13:00:00',
          'status': 'confirmed',
        }
      };

      final start = DateTime.utc(2026, 10, 18, 10, 0, 0);
      final end = DateTime.utc(2026, 10, 18, 13, 0, 0);

      final plan = await repository.createPlan(
        circleId: 10,
        title: 'Bouldering Session',
        eventType: 'social',
        startAt: start,
        endAt: end,
        status: 'confirmed',
      );

      expect(fakeApi.lastPostPath, '/plans');
      expect(fakeApi.lastPostData['circle_id'], 10);
      expect(fakeApi.lastPostData['title'], 'Bouldering Session');
      expect(fakeApi.lastPostData['event_type'], 'social');
      expect(fakeApi.lastPostData['start_at'], '2026-10-18 10:00:00');
      expect(fakeApi.lastPostData['end_at'], '2026-10-18 13:00:00');
      expect(plan.id, 77);
    });

    test('deletePlan sends DELETE /plans/{id}', () async {
      await repository.deletePlan(88);
      expect(fakeApi.lastDeletePath, '/plans/88');
    });

    test('rsvp sends POST /plans/{id}/rsvp', () async {
      fakeApi.nextPostResponse = {
        'message': 'RSVP updated successfully.',
        'data': {
          'id': 99,
          'plan_id': 77,
          'user_id': 1,
          'rsvp_status': 'attending',
        }
      };

      final member = await repository.rsvp(planId: 77, rsvpStatus: 'attending');
      expect(fakeApi.lastPostPath, '/plans/77/rsvp');
      expect(fakeApi.lastPostData['rsvp_status'], 'attending');
      expect(member.rsvpStatus, 'attending');
    });

    test('addOption sends POST /plans/{id}/options', () async {
      fakeApi.nextPostResponse = {
        'message': 'Poll option added successfully.',
        'data': {
          'id': 20,
          'plan_id': 77,
          'start_at': '2026-10-18 10:00:00',
          'end_at': '2026-10-18 13:00:00',
          'timezone': 'UTC',
        }
      };

      final start = DateTime.utc(2026, 10, 18, 10, 0, 0);
      final end = DateTime.utc(2026, 10, 18, 13, 0, 0);

      final option = await repository.addOption(planId: 77, startAt: start, endAt: end);
      expect(fakeApi.lastPostPath, '/plans/77/options');
      expect(fakeApi.lastPostData['start_at'], '2026-10-18 10:00:00');
      expect(option.id, 20);
    });

    test('proposeLocation sends POST /plans/{id}/locations', () async {
      fakeApi.nextPostResponse = {
        'message': 'Location proposed successfully.',
        'data': {
          'id': 33,
          'plan_id': 77,
          'name': 'The Depot Climbing Wall',
          'address': 'Unit 4, Trade Park',
          'votes': [],
        }
      };

      final loc = await repository.proposeLocation(
        planId: 77,
        name: 'The Depot Climbing Wall',
        address: 'Unit 4, Trade Park',
      );
      expect(fakeApi.lastPostPath, '/plans/77/locations');
      expect(fakeApi.lastPostData['name'], 'The Depot Climbing Wall');
      expect(loc.name, 'The Depot Climbing Wall');
    });

    test('voteLocation sends POST /locations/{id}/vote', () async {
      fakeApi.nextPostResponse = {
        'message': 'Location vote recorded successfully.',
        'data': {
          'id': 12,
          'plan_location_id': 33,
          'user_id': 1,
        }
      };

      final vote = await repository.voteLocation(33);
      expect(fakeApi.lastPostPath, '/locations/33/vote');
      expect(vote.planLocationId, 33);
    });

    test('getMessages calls GET /plans/{id}/messages', () async {
      fakeApi.nextGetResponse = {
        'data': [
          {
            'id': 1,
            'plan_id': 77,
            'user_id': 1,
            'body': 'Anyone driving from the north side?',
            'created_at': '2026-10-10T12:00:00.000Z',
          }
        ]
      };

      final messages = await repository.getMessages(77);
      expect(fakeApi.lastGetPath, '/plans/77/messages');
      expect(messages.length, 1);
      expect(messages.first.body, 'Anyone driving from the north side?');
    });

    test('sendMessage sends POST /plans/{id}/messages', () async {
      fakeApi.nextPostResponse = {
        'message': 'Message sent successfully.',
        'data': {
          'id': 2,
          'plan_id': 77,
          'user_id': 2,
          'body': 'I can offer two lifts!',
          'created_at': '2026-10-10T12:05:00.000Z',
        }
      };

      final msg = await repository.sendMessage(planId: 77, body: 'I can offer two lifts!');
      expect(fakeApi.lastPostPath, '/plans/77/messages');
      expect(fakeApi.lastPostData['body'], 'I can offer two lifts!');
      expect(msg.body, 'I can offer two lifts!');
    });
  });

  group('Riverpod Providers Tests', () {
    test('PlansListNotifier updates RSVP and deletes plan locally', () async {
      final fakeApi = FakeApiClient();
      final repo = PlanRepository(apiClient: fakeApi);

      fakeApi.nextGetResponse = {
        'data': [
          {
            'id': 1,
            'circle_id': 1,
            'created_by': 1,
            'title': 'Coffee',
            'my_rsvp': 'pending',
          },
          {
            'id': 2,
            'circle_id': 1,
            'created_by': 1,
            'title': 'Dinner',
            'my_rsvp': 'pending',
          }
        ]
      };

      final container = ProviderContainer(
        overrides: [
          planRepositoryProvider.overrideWithValue(repo),
        ],
      );

      // Initial read
      final initialPlans = await container.read(plansListProvider.future);
      expect(initialPlans.length, 2);

      // Mock RSVP
      fakeApi.nextPostResponse = {
        'data': {'id': 1, 'plan_id': 1, 'user_id': 1, 'rsvp_status': 'attending'}
      };
      await container.read(plansListProvider.notifier).updateRsvp(1, 'attending');

      final updatedPlans = container.read(plansListProvider).value!;
      expect(updatedPlans.firstWhere((p) => p.id == 1).myRsvp, 'attending');

      // Mock Delete Plan
      await container.read(plansListProvider.notifier).deletePlan(2);
      final remainingPlans = container.read(plansListProvider).value!;
      expect(remainingPlans.length, 1);
      expect(remainingPlans.first.id, 1);

      // Add Plan
      container.read(plansListProvider.notifier).addPlan(
            const PlanModel(id: 3, circleId: 1, createdBy: 1, title: 'Brunch'),
          );
      final withAdded = container.read(plansListProvider).value!;
      expect(withAdded.length, 2);
      expect(withAdded.first.title, 'Brunch');
    });
  });
}
