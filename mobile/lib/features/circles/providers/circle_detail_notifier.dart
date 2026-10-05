import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/error_handler.dart';
import '../data/circle_repository.dart';
import '../models/circle_member.dart';
import 'circle_detail_state.dart';
import 'circles_notifier.dart';

class CircleDetailNotifier extends StateNotifier<CircleDetailState> {
  final CircleRepository repository;
  final int circleId;
  final Ref? ref;

  CircleDetailNotifier({
    required this.repository,
    required this.circleId,
    this.ref,
  }) : super(const CircleDetailState()) {
    loadCircle();
  }

  Future<void> loadCircle({bool force = false}) async {
    if (state.status == CircleDetailStatus.loading && !force) return;

    state = state.copyWith(
      status: CircleDetailStatus.loading,
      clearError: true,
      clearSuccess: true,
    );

    try {
      final circle = await repository.getCircle(circleId);
      state = state.copyWith(
        status: CircleDetailStatus.loaded,
        circle: circle,
      );
    } on AppException catch (e) {
      state = state.copyWith(
        status: CircleDetailStatus.error,
        errorMessage: e.message,
      );
    } catch (e) {
      state = state.copyWith(
        status: CircleDetailStatus.error,
        errorMessage: 'Failed to load circle: ${e.toString()}',
      );
    }
  }

  Future<bool> updateMemberVisibility({
    required int memberId,
    required String visibility,
  }) async {
    return _updateMemberHelper(
      memberId: memberId,
      updater: () => repository.updateMember(
        circleId: circleId,
        memberId: memberId,
        visibility: visibility,
      ),
      successMessage: 'Visibility policy updated.',
    );
  }

  Future<bool> updateMemberType({
    required int memberId,
    required String memberType,
  }) async {
    return _updateMemberHelper(
      memberId: memberId,
      updater: () => repository.updateMember(
        circleId: circleId,
        memberId: memberId,
        memberType: memberType,
      ),
      successMessage: 'Member participation type updated.',
    );
  }

  Future<bool> updateMemberRole({
    required int memberId,
    required String role,
  }) async {
    return _updateMemberHelper(
      memberId: memberId,
      updater: () => repository.updateMember(
        circleId: circleId,
        memberId: memberId,
        role: role,
      ),
      successMessage: 'Member role updated.',
    );
  }

  Future<bool> _updateMemberHelper({
    required int memberId,
    required Future<CircleMember> Function() updater,
    required String successMessage,
  }) async {
    state = state.copyWith(
      activeMemberActionId: memberId,
      clearError: true,
      clearSuccess: true,
    );

    try {
      final updatedMember = await updater();

      if (state.circle != null) {
        final updatedMembers = state.circle!.members.map((m) {
          return m.id == memberId ? updatedMember : m;
        }).toList();

        // Also update myRole/myVisibility if it's the current user
        final isMe = state.circle!.myRole.toLowerCase() == updatedMember.role.toLowerCase() ||
            (updatedMember.user != null &&
                state.circle!.members.any((m) => m.id == memberId && m.userId == updatedMember.userId));

        final updatedCircle = state.circle!.copyWith(
          members: updatedMembers,
          myRole: isMe ? updatedMember.role : state.circle!.myRole,
          myVisibility: isMe ? updatedMember.visibility : state.circle!.myVisibility,
          myMemberType: isMe ? updatedMember.memberType : state.circle!.myMemberType,
        );

        state = state.copyWith(
          circle: updatedCircle,
          clearActiveAction: true,
          successMessage: successMessage,
        );
      } else {
        state = state.copyWith(
          clearActiveAction: true,
          successMessage: successMessage,
        );
      }

      _invalidateCirclesList();
      return true;
    } on AppException catch (e) {
      state = state.copyWith(
        clearActiveAction: true,
        errorMessage: e.message,
      );
      return false;
    } catch (e) {
      state = state.copyWith(
        clearActiveAction: true,
        errorMessage: 'Failed to update member: ${e.toString()}',
      );
      return false;
    }
  }

  Future<bool> removeMember(int memberId) async {
    state = state.copyWith(
      activeMemberActionId: memberId,
      clearError: true,
      clearSuccess: true,
    );

    try {
      await repository.removeMember(
        circleId: circleId,
        memberId: memberId,
      );

      if (state.circle != null) {
        final updatedMembers = state.circle!.members.where((m) => m.id != memberId).toList();
        final updatedCircle = state.circle!.copyWith(
          members: updatedMembers,
          membersCount: updatedMembers.length,
        );

        state = state.copyWith(
          circle: updatedCircle,
          clearActiveAction: true,
          successMessage: 'Member removed from circle.',
        );
      } else {
        state = state.copyWith(
          clearActiveAction: true,
          successMessage: 'Member removed from circle.',
        );
      }

      _invalidateCirclesList();
      return true;
    } on AppException catch (e) {
      state = state.copyWith(
        clearActiveAction: true,
        errorMessage: e.message,
      );
      return false;
    } catch (e) {
      state = state.copyWith(
        clearActiveAction: true,
        errorMessage: 'Failed to remove member: ${e.toString()}',
      );
      return false;
    }
  }

  Future<bool> leaveCircle(int currentUserId) async {
    if (state.circle == null) return false;

    // Find current user's membership
    final myMember = state.circle!.members.firstWhere(
      (m) => m.userId == currentUserId,
      orElse: () => state.circle!.members.firstWhere(
        (m) => m.role == state.circle!.myRole,
        orElse: () => CircleMember(id: 0, circleId: circleId, userId: currentUserId),
      ),
    );

    if (myMember.id == 0) {
      state = state.copyWith(errorMessage: 'Cannot locate membership record.');
      return false;
    }

    state = state.copyWith(
      status: CircleDetailStatus.actionInProgress,
      clearError: true,
      clearSuccess: true,
    );

    try {
      await repository.removeMember(
        circleId: circleId,
        memberId: myMember.id,
      );

      state = state.copyWith(
        status: CircleDetailStatus.deleted,
        successMessage: 'You have left the circle.',
      );

      _invalidateCirclesList();
      return true;
    } on AppException catch (e) {
      state = state.copyWith(
        status: CircleDetailStatus.loaded,
        errorMessage: e.message,
      );
      return false;
    } catch (e) {
      state = state.copyWith(
        status: CircleDetailStatus.loaded,
        errorMessage: 'Failed to leave circle: ${e.toString()}',
      );
      return false;
    }
  }

  Future<bool> deleteCircle() async {
    state = state.copyWith(
      status: CircleDetailStatus.actionInProgress,
      clearError: true,
      clearSuccess: true,
    );

    try {
      await repository.deleteCircle(circleId);

      state = state.copyWith(
        status: CircleDetailStatus.deleted,
        successMessage: 'Circle has been deleted.',
      );

      _invalidateCirclesList();
      return true;
    } on AppException catch (e) {
      state = state.copyWith(
        status: CircleDetailStatus.loaded,
        errorMessage: e.message,
      );
      return false;
    } catch (e) {
      state = state.copyWith(
        status: CircleDetailStatus.loaded,
        errorMessage: 'Failed to delete circle: ${e.toString()}',
      );
      return false;
    }
  }

  void _invalidateCirclesList() {
    try {
      ref?.read(circlesNotifierProvider.notifier).loadCircles();
    } catch (_) {}
  }
}

final circleDetailProvider = StateNotifierProvider.autoDispose
    .family<CircleDetailNotifier, CircleDetailState, int>((ref, circleId) {
  final repo = ref.watch(circleRepositoryProvider);
  return CircleDetailNotifier(
    repository: repo,
    circleId: circleId,
    ref: ref,
  );
});
