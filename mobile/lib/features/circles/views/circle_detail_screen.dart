import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/text_styles.dart';
import '../../../core/utils/haptic_feedback.dart';
import '../../auth/providers/auth_notifier.dart';
import '../providers/circle_detail_notifier.dart';
import '../providers/circle_detail_state.dart';
import 'widgets/activity_feed_list.dart';
import 'widgets/circle_invite_modal.dart';
import 'widgets/circle_settings_modal.dart';
import 'widgets/member_item_tile.dart';

class CircleDetailScreen extends ConsumerStatefulWidget {
  final int circleId;

  const CircleDetailScreen({
    super.key,
    required this.circleId,
  });

  @override
  ConsumerState<CircleDetailScreen> createState() => _CircleDetailScreenState();
}

class _CircleDetailScreenState extends ConsumerState<CircleDetailScreen> {
  int _selectedTabIndex = 0;

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(circleDetailProvider(widget.circleId));
    final notifier = ref.read(circleDetailProvider(widget.circleId).notifier);
    final authState = ref.watch(authNotifierProvider);
    final currentUserId = authState.user?.id ?? 0;

    // Listen for deleted state to navigate away
    ref.listen<CircleDetailState>(circleDetailProvider(widget.circleId), (prev, next) {
      if (next.status == CircleDetailStatus.deleted) {
        if (next.successMessage != null && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(next.successMessage!),
              backgroundColor: AppColors.primary,
            ),
          );
        }
        if (context.canPop()) {
          context.pop();
        } else {
          context.go('/circles');
        }
      } else if (next.errorMessage != null && next.errorMessage != prev?.errorMessage && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(next.errorMessage!),
            backgroundColor: AppColors.danger,
          ),
        );
      } else if (next.successMessage != null && next.successMessage != prev?.successMessage && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(next.successMessage!),
            backgroundColor: AppColors.primary,
          ),
        );
      }
    });

    final circle = state.circle;

    return Scaffold(
      backgroundColor: AppColors.scaffoldBackground,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(LucideIcons.arrowLeft, color: AppColors.textPrimary),
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go('/circles');
            }
          },
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              circle?.name ?? 'Circle Details',
              style: AppTextStyles.titleSmall.copyWith(
                fontWeight: FontWeight.bold,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            if (circle?.handle != null && circle!.handle!.isNotEmpty)
              Text(
                '@${circle.handle}',
                style: const TextStyle(
                  fontSize: 11,
                  color: AppColors.textMuted,
                  fontFamily: 'monospace',
                ),
              ),
          ],
        ),
        actions: [
          if (circle != null)
            IconButton(
              icon: const Icon(LucideIcons.settings, color: AppColors.textPrimary),
              tooltip: 'Circle Settings',
              onPressed: () {
                CircleSettingsModal.show(
                  context: context,
                  circle: circle,
                  onLeaveCircle: () => notifier.leaveCircle(currentUserId),
                  onDeleteCircle: () => notifier.deleteCircle(),
                );
              },
            ),
        ],
      ),
      body: Builder(
        builder: (context) {
          if (state.isLoading && circle == null) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          if (state.status == CircleDetailStatus.error && circle == null) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(LucideIcons.alertCircle, size: 48, color: AppColors.danger),
                    const SizedBox(height: 16),
                    Text(
                      'Failed to load circle',
                      style: AppTextStyles.titleMedium.copyWith(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      state.errorMessage ?? 'An unexpected error occurred.',
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: AppColors.textMuted),
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: () => notifier.loadCircle(force: true),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                      ),
                      child: const Text('Try Again'),
                    ),
                  ],
                ),
              ),
            );
          }

          if (circle == null) {
            return const SizedBox.shrink();
          }

          final isOwner = circle.isOwner;
          final isAdmin = circle.isAdmin;
          final canManageMembers = isOwner || isAdmin;
          final canManageRoles = isOwner;

          return RefreshIndicator(
            onRefresh: () => notifier.loadCircle(force: true),
            color: AppColors.primary,
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // Header Card
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppColors.border),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x06000000),
                        blurRadius: 8,
                        offset: Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Role & Visibility Pills
                      Wrap(
                        spacing: 8,
                        runSpacing: 6,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: AppColors.primarySurface,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: AppColors.primaryLight.withValues(alpha: 0.4)),
                            ),
                            child: Text(
                              'ROLE: ${circle.myRole.toUpperCase()}',
                              style: const TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: AppColors.primaryDark,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: AppColors.accentLime.withValues(alpha: 0.25),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: AppColors.accentLime.withValues(alpha: 0.5)),
                            ),
                            child: Text(
                              'VISIBILITY: ${circle.myVisibility.replaceAll('_', '/').toUpperCase()}',
                              style: const TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: AppColors.accentGold,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),

                      // Circle Name & Handle
                      Text(
                        circle.name,
                        style: AppTextStyles.displayMedium.copyWith(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (circle.handle != null && circle.handle!.isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Text(
                          '@${circle.handle}',
                          style: const TextStyle(
                            fontSize: 13,
                            color: AppColors.textMuted,
                            fontFamily: 'monospace',
                          ),
                        ),
                      ],

                      const SizedBox(height: 18),

                      // Action Buttons: Invite & Compare
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              icon: const Icon(LucideIcons.keyRound, size: 15, color: AppColors.primary),
                              label: const Text(
                                'Invite',
                                style: TextStyle(fontWeight: FontWeight.w600),
                              ),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: AppColors.primary,
                                side: const BorderSide(color: AppColors.primary),
                                padding: const EdgeInsets.symmetric(vertical: 12),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              onPressed: () {
                                AppHaptics.selection();
                                CircleInviteModal.show(
                                  context: context,
                                  circleId: circle.id,
                                  circleName: circle.name,
                                );
                              },
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: ElevatedButton.icon(
                              icon: const Icon(LucideIcons.sliders, size: 15, color: Colors.white),
                              label: const Text(
                                'Compare',
                                style: TextStyle(fontWeight: FontWeight.w600),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.primary,
                                foregroundColor: Colors.white,
                                elevation: 0,
                                padding: const EdgeInsets.symmetric(vertical: 12),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              onPressed: () {
                                AppHaptics.medium();
                                context.push('/compare?circle=${circle.id}');
                              },
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // Segmented Tab Switch: Members vs Activity Feed
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceSecondary,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: GestureDetector(
                          onTap: () {
                            AppHaptics.selection();
                            setState(() => _selectedTabIndex = 0);
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            decoration: BoxDecoration(
                              color: _selectedTabIndex == 0 ? AppColors.surface : Colors.transparent,
                              borderRadius: BorderRadius.circular(10),
                              boxShadow: _selectedTabIndex == 0
                                  ? const [
                                      BoxShadow(
                                        color: Color(0x0A000000),
                                        blurRadius: 4,
                                        offset: Offset(0, 1),
                                      ),
                                    ]
                                  : null,
                            ),
                            alignment: Alignment.center,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  LucideIcons.users,
                                  size: 14,
                                  color: _selectedTabIndex == 0 ? AppColors.primaryDark : AppColors.textMuted,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  'Members (${circle.members.length})',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: _selectedTabIndex == 0 ? FontWeight.bold : FontWeight.w600,
                                    color: _selectedTabIndex == 0 ? AppColors.primaryDark : AppColors.textMuted,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      Expanded(
                        child: GestureDetector(
                          onTap: () {
                            AppHaptics.selection();
                            setState(() => _selectedTabIndex = 1);
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            decoration: BoxDecoration(
                              color: _selectedTabIndex == 1 ? AppColors.surface : Colors.transparent,
                              borderRadius: BorderRadius.circular(10),
                              boxShadow: _selectedTabIndex == 1
                                  ? const [
                                      BoxShadow(
                                        color: Color(0x0A000000),
                                        blurRadius: 4,
                                        offset: Offset(0, 1),
                                      ),
                                    ]
                                  : null,
                            ),
                            alignment: Alignment.center,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  LucideIcons.activity,
                                  size: 14,
                                  color: _selectedTabIndex == 1 ? AppColors.primaryDark : AppColors.textMuted,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  'Activity',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: _selectedTabIndex == 1 ? FontWeight.bold : FontWeight.w600,
                                    color: _selectedTabIndex == 1 ? AppColors.primaryDark : AppColors.textMuted,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                if (_selectedTabIndex == 0) ...[
                  // Members Roster Section Header
                  Row(
                    children: [
                      const Icon(LucideIcons.users, size: 18, color: AppColors.primary),
                      const SizedBox(width: 8),
                      Text(
                        'Circle Members & Privacy Roster',
                        style: AppTextStyles.titleSmall.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.primarySurface,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          '${circle.members.length} members',
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: AppColors.primaryDark,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Manage member participation (Working vs Viewer) and privacy visibility policies.',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.textMuted,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Member Items List
                  ...circle.members.map((member) {
                    final isMe = member.userId == currentUserId;
                    final isActionInProgress = state.activeMemberActionId == member.id;

                    return MemberItemTile(
                      member: member,
                      canManageMembers: canManageMembers,
                      canManageRoles: canManageRoles,
                      isCurrentAuthUser: isMe,
                      isActionInProgress: isActionInProgress,
                      onUpdateType: (newType) {
                        notifier.updateMemberType(
                          memberId: member.id,
                          memberType: newType,
                        );
                      },
                      onUpdateVisibility: (newVis) {
                        notifier.updateMemberVisibility(
                          memberId: member.id,
                          visibility: newVis,
                        );
                      },
                      onUpdateRole: canManageRoles && !member.isOwner
                          ? (newRole) {
                              notifier.updateMemberRole(
                                memberId: member.id,
                                role: newRole,
                              );
                            }
                          : null,
                      onRemoveMember: (canManageMembers && !member.isOwner && !isMe)
                          ? () {
                              notifier.removeMember(member.id);
                            }
                          : null,
                    );
                  }),
                ] else ...[
                  // Activity Feed Tab
                  ActivityFeedList(circleId: circle.id),
                ],

                const SizedBox(height: 40),
              ],
            ),
          );
        },
      ),
    );
  }
}
