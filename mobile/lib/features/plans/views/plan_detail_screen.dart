import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/text_styles.dart';
import '../../../core/utils/haptic_feedback.dart';
import '../../auth/providers/auth_notifier.dart';
import '../providers/plan_detail_notifier.dart';
import '../utils/ics_generator.dart';
import 'widgets/location_voting_widget.dart';
import 'widgets/plan_chat_widget.dart';
import 'widgets/plan_rsvp_bar.dart';

class PlanDetailScreen extends ConsumerWidget {
  final int planId;

  const PlanDetailScreen({
    super.key,
    required this.planId,
  });

  String _formatDateTime(DateTime dt) {
    return DateFormat('EEEE, MMMM d, yyyy • h:mm a').format(dt);
  }

  Future<void> _confirmDelete(BuildContext context, WidgetRef ref) async {
    AppHaptics.medium();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Meetup Plan?'),
        content: const Text(
          'Are you sure you want to delete this plan? All member RSVPs, votes, and discussion messages will be permanently removed.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.danger,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await ref.read(planDetailNotifierProvider(planId).notifier).deletePlan();
      if (context.mounted) {
        Navigator.of(context).pop();
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final planAsync = ref.watch(planDetailNotifierProvider(planId));
    final currentUserId = ref.watch(authNotifierProvider).user?.id ?? 0;

    return Scaffold(
      backgroundColor: AppColors.scaffoldBackground,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        title: const Text('Plan Details', style: AppTextStyles.titleMedium),
        actions: [
          IconButton(
            icon: const Icon(LucideIcons.refreshCw, size: 18, color: AppColors.textPrimary),
            tooltip: 'Refresh',
            onPressed: () {
              AppHaptics.light();
              ref.read(planDetailNotifierProvider(planId).notifier).refresh();
            },
          ),
          planAsync.maybeWhen(
            data: (plan) => IconButton(
              icon: const Icon(LucideIcons.download, size: 18, color: AppColors.primary),
              tooltip: 'Export .ics',
              onPressed: () => exportPlanIcs(plan, locationName: plan.primaryLocation?.name),
            ),
            orElse: () => const SizedBox.shrink(),
          ),
          planAsync.maybeWhen(
            data: (plan) {
              if (plan.isCreator(currentUserId)) {
                return IconButton(
                  icon: const Icon(LucideIcons.trash2, size: 18, color: AppColors.danger),
                  tooltip: 'Delete Plan',
                  onPressed: () => _confirmDelete(context, ref),
                );
              }
              return const SizedBox.shrink();
            },
            orElse: () => const SizedBox.shrink(),
          ),
        ],
      ),
      body: planAsync.when(
        data: (plan) {
          final isConfirmed = plan.isConfirmed;
          final statusBg = isConfirmed
              ? const Color(0xFFECFDF5)
              : const Color(0xFFFFFBEB);
          final statusBorder = isConfirmed
              ? const Color(0xFFA7F3D0)
              : const Color(0xFFFDE68A);
          final statusText = isConfirmed
              ? const Color(0xFF047857)
              : const Color(0xFFB45309);

          return RefreshIndicator(
            onRefresh: () =>
                ref.read(planDetailNotifierProvider(planId).notifier).refresh(),
            color: AppColors.primary,
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 40),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 1. Hero Card
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Badges Row
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: statusBg,
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(color: statusBorder),
                              ),
                              child: Text(
                                plan.status.toUpperCase(),
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 0.5,
                                  color: statusText,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: const Color(0xFFD7D982).withValues(alpha: 0.25),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: const Color(0xFFD7D982).withValues(alpha: 0.6),
                                ),
                              ),
                              child: Text(
                                plan.eventType.toUpperCase(),
                                style: const TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w800,
                                  color: Color(0xFF5C5E1A),
                                ),
                              ),
                            ),
                            const Spacer(),
                            if (plan.circle != null)
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: AppColors.scaffoldBackground,
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: AppColors.border),
                                ),
                                child: Row(
                                  children: [
                                    const Icon(LucideIcons.users, size: 12, color: AppColors.primary),
                                    const SizedBox(width: 4),
                                    Text(
                                      plan.circle!.name,
                                      style: const TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w600,
                                        color: AppColors.textPrimary,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                          ],
                        ),

                        const SizedBox(height: 14),

                        // Title
                        Text(
                          plan.title,
                          style: AppTextStyles.titleLarge.copyWith(
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                          ),
                        ),

                        // Description
                        if (plan.description != null && plan.description!.trim().isNotEmpty) ...[
                          const SizedBox(height: 8),
                          Text(
                            plan.description!,
                            style: const TextStyle(
                              fontSize: 13,
                              color: AppColors.textMuted,
                              height: 1.4,
                            ),
                          ),
                        ],

                        const SizedBox(height: 14),
                        const Divider(color: AppColors.borderLight, height: 1),
                        const SizedBox(height: 12),

                        // Time Row
                        Row(
                          children: [
                            const Icon(LucideIcons.clock, size: 16, color: AppColors.primary),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                plan.startAt != null
                                    ? _formatDateTime(plan.startAt!)
                                    : 'Date TBD (Voting in progress)',
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                            ),
                          ],
                        ),

                        // Organizer attribution
                        if (plan.creator != null) ...[
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              const Icon(LucideIcons.user, size: 14, color: AppColors.textSubtle),
                              const SizedBox(width: 8),
                              Text(
                                'Organized by ${plan.creator!.name}',
                                style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),

                  const SizedBox(height: 14),

                  // 2. RSVP State Machine Bar
                  PlanRsvpBar(
                    plan: plan,
                    onRsvpSelected: (status) {
                      ref
                          .read(planDetailNotifierProvider(planId).notifier)
                          .updateRsvp(status, currentUserId: currentUserId);
                    },
                  ),

                  const SizedBox(height: 14),

                  // 3. Polling Date Options (if polling plan)
                  if (plan.options.isNotEmpty) ...[
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Row(
                            children: [
                              Icon(LucideIcons.vote, size: 16, color: AppColors.primary),
                              SizedBox(width: 8),
                              Text(
                                'PROPOSED TIME SLOTS',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 0.5,
                                  color: AppColors.textMuted,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          ...plan.options.map((opt) => Padding(
                                padding: const EdgeInsets.only(bottom: 8),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                  decoration: BoxDecoration(
                                    color: AppColors.scaffoldBackground,
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(color: AppColors.borderLight),
                                  ),
                                  child: Row(
                                    children: [
                                      const Icon(LucideIcons.calendar, size: 14, color: AppColors.primary),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          '${DateFormat('EEE, MMM d • h:mm a').format(opt.startAt)} – ${DateFormat('h:mm a').format(opt.endAt)}',
                                          style: const TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w600,
                                            color: AppColors.textPrimary,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              )),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),
                  ],

                  // 4. Location Options & Voting Widget
                  LocationVotingWidget(
                    planId: plan.id,
                    locations: plan.locations,
                    currentUserId: currentUserId,
                    onProposeLocation: ({required name, address, notes}) async {
                      await ref
                          .read(planDetailNotifierProvider(planId).notifier)
                          .proposeLocation(name: name, address: address, notes: notes);
                    },
                    onVoteLocation: (locId) {
                      ref
                          .read(planDetailNotifierProvider(planId).notifier)
                          .voteLocation(locId, currentUserId);
                    },
                  ),
                  const SizedBox(height: 14),

                  // 5. In-Plan Discussion Thread
                  PlanChatWidget(planId: plan.id),
                ],
              ),
            ),
          );
        },
        loading: () => const Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
        error: (err, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(LucideIcons.alertTriangle, size: 40, color: AppColors.danger),
                const SizedBox(height: 12),
                const Text('Failed to load plan details', style: AppTextStyles.titleMedium),
                const SizedBox(height: 6),
                Text(
                  err.toString(),
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
                ),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: () =>
                      ref.read(planDetailNotifierProvider(planId).notifier).refresh(),
                  icon: const Icon(LucideIcons.refreshCw, size: 14),
                  label: const Text('Try Again'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
