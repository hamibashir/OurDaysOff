import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/plan_repository.dart';
import '../models/plan_message_model.dart';
import '../models/plan_model.dart';

/// Notifier managing the authenticated user's plans list
class PlansListNotifier extends AsyncNotifier<List<PlanModel>> {
  @override
  Future<List<PlanModel>> build() async {
    final repo = ref.watch(planRepositoryProvider);
    return repo.getPlans();
  }

  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final repo = ref.read(planRepositoryProvider);
      return repo.getPlans();
    });
  }

  Future<void> updateRsvp(int planId, String rsvpStatus) async {
    final repo = ref.read(planRepositoryProvider);
    await repo.rsvp(planId: planId, rsvpStatus: rsvpStatus);

    state = state.whenData((plans) {
      return plans.map((p) {
        if (p.id == planId) {
          return p.copyWith(myRsvp: rsvpStatus);
        }
        return p;
      }).toList();
    });
  }

  Future<void> deletePlan(int planId) async {
    final repo = ref.read(planRepositoryProvider);
    await repo.deletePlan(planId);
    state = state.whenData((plans) => plans.where((p) => p.id != planId).toList());
  }

  void addPlan(PlanModel plan) {
    state = state.whenData((plans) => [plan, ...plans]);
  }
}

final plansListProvider =
    AsyncNotifierProvider<PlansListNotifier, List<PlanModel>>(
  PlansListNotifier.new,
);

/// Provider for a specific plan's details
final planDetailProvider =
    FutureProvider.family<PlanModel, int>((ref, planId) async {
  final repo = ref.watch(planRepositoryProvider);
  return repo.getPlan(planId);
});

/// Notifier for in-plan chat discussion
class PlanMessagesNotifier
    extends AutoDisposeFamilyAsyncNotifier<List<PlanMessageModel>, int> {
  @override
  Future<List<PlanMessageModel>> build(int arg) async {
    final repo = ref.watch(planRepositoryProvider);
    return repo.getMessages(arg);
  }

  Future<void> refresh() async {
    final repo = ref.read(planRepositoryProvider);
    final messages = await repo.getMessages(arg);
    state = AsyncValue.data(messages);
  }

  Future<void> sendMessage(String body) async {
    final repo = ref.read(planRepositoryProvider);
    final sent = await repo.sendMessage(planId: arg, body: body);
    state = state.whenData((messages) => [...messages, sent]);
  }
}

final planMessagesProvider = AsyncNotifierProvider.autoDispose
    .family<PlanMessagesNotifier, List<PlanMessageModel>, int>(
  PlanMessagesNotifier.new,
);
