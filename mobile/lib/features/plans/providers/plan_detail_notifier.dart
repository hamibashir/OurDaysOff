import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/plan_repository.dart';
import '../models/plan_location_model.dart';
import '../models/plan_member_model.dart';
import '../models/plan_model.dart';
import 'plan_providers.dart';

class PlanDetailNotifier extends AutoDisposeFamilyAsyncNotifier<PlanModel, int> {
  @override
  Future<PlanModel> build(int arg) async {
    final repo = ref.watch(planRepositoryProvider);
    return repo.getPlan(arg);
  }

  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final repo = ref.read(planRepositoryProvider);
      return repo.getPlan(arg);
    });
  }

  Future<void> updateRsvp(String rsvpStatus, {int? currentUserId}) async {
    final repo = ref.read(planRepositoryProvider);
    final memberResult = await repo.rsvp(planId: arg, rsvpStatus: rsvpStatus);

    // Keep feed list in sync
    ref.read(plansListProvider.notifier).updateRsvp(arg, rsvpStatus);

    state = state.whenData((plan) {
      // Update or add current user to members list
      final effectiveUserId = currentUserId ?? memberResult.userId;
      final existingIndex = plan.members.indexWhere((m) => m.userId == effectiveUserId);

      List<PlanMemberModel> updatedMembers = [...plan.members];
      if (existingIndex >= 0) {
        updatedMembers[existingIndex] = updatedMembers[existingIndex].copyWith(
          rsvpStatus: rsvpStatus,
          respondedAt: DateTime.now(),
        );
      } else {
        updatedMembers.add(memberResult);
      }

      return plan.copyWith(
        myRsvp: rsvpStatus,
        members: updatedMembers,
      );
    });
  }

  Future<PlanLocationModel> proposeLocation({
    required String name,
    String? address,
    double? latitude,
    double? longitude,
    String? notes,
  }) async {
    final repo = ref.read(planRepositoryProvider);
    final newLocation = await repo.proposeLocation(
      planId: arg,
      name: name,
      address: address,
      latitude: latitude,
      longitude: longitude,
      notes: notes,
    );

    state = state.whenData((plan) {
      return plan.copyWith(
        locations: [...plan.locations, newLocation],
      );
    });

    return newLocation;
  }

  Future<void> voteLocation(int locationId, int currentUserId) async {
    final repo = ref.read(planRepositoryProvider);
    final voteResult = await repo.voteLocation(locationId);

    state = state.whenData((plan) {
      final updatedLocations = plan.locations.map((loc) {
        if (loc.id == locationId) {
          // If already voted, keep it, otherwise append new vote
          if (loc.hasVoted(currentUserId)) {
            return loc;
          }
          final newVote = PlanLocationVoteModel(
            id: voteResult.id,
            planLocationId: locationId,
            userId: currentUserId,
            createdAt: DateTime.now(),
          );
          return loc.copyWith(votes: [...loc.votes, newVote]);
        }
        return loc;
      }).toList();

      return plan.copyWith(locations: updatedLocations);
    });
  }

  Future<void> deletePlan() async {
    final repo = ref.read(planRepositoryProvider);
    await repo.deletePlan(arg);
    ref.read(plansListProvider.notifier).deletePlan(arg);
  }
}

final planDetailNotifierProvider = AsyncNotifierProvider.autoDispose
    .family<PlanDetailNotifier, PlanModel, int>(
  PlanDetailNotifier.new,
);
