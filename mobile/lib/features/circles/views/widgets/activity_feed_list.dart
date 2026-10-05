import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/text_styles.dart';
import '../../../../shared/widgets/empty_state_view.dart';
import '../../providers/activity_feed_notifier.dart';

class ActivityFeedList extends ConsumerWidget {
  final int circleId;

  const ActivityFeedList({
    super.key,
    required this.circleId,
  });

  IconData _getEventIcon(String type) {
    switch (type) {
      case 'member_joined':
        return LucideIcons.userPlus;
      case 'member_left':
        return LucideIcons.userMinus;
      case 'member_removed':
        return LucideIcons.userX;
      case 'role_updated':
        return LucideIcons.shieldCheck;
      case 'schedule_updated':
        return LucideIcons.calendar;
      case 'plan_created':
        return LucideIcons.mapPin;
      case 'plan_rsvp':
        return LucideIcons.checkCircle2;
      default:
        return LucideIcons.activity;
    }
  }

  Color _getEventColor(String type) {
    switch (type) {
      case 'member_joined':
        return AppColors.statusAvailable;
      case 'member_left':
        return AppColors.statusLeave;
      case 'member_removed':
        return AppColors.danger;
      case 'role_updated':
        return AppColors.accentViolet;
      case 'schedule_updated':
        return AppColors.statusBusy;
      case 'plan_created':
      case 'plan_rsvp':
        return AppColors.primary;
      default:
        return AppColors.primaryDark;
    }
  }

  Color _getEventBgColor(String type) {
    switch (type) {
      case 'member_joined':
        return AppColors.statusAvailableBg;
      case 'member_left':
        return AppColors.statusLeaveBg;
      case 'member_removed':
        return AppColors.dangerBg;
      case 'role_updated':
        return AppColors.statusOvernightBg;
      case 'schedule_updated':
        return AppColors.statusBusyBg;
      default:
        return AppColors.primarySurface;
    }
  }

  String _formatRelativeTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inSeconds < 60) {
      return 'just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      return '${dateTime.month}/${dateTime.day}';
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(activityFeedProvider(circleId));
    final notifier = ref.read(activityFeedProvider(circleId).notifier);

    if (state.isLoading && state.events.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(40),
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (state.errorMessage != null && state.events.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(LucideIcons.alertCircle, size: 40, color: AppColors.danger),
              const SizedBox(height: 12),
              Text(
                'Failed to load activity',
                style: AppTextStyles.titleSmall.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 6),
              Text(
                state.errorMessage!,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => notifier.loadActivity(force: true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                ),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    if (state.events.isEmpty) {
      return const EmptyStateView(
        icon: LucideIcons.activity,
        title: 'No Recent Activity',
        description: 'Schedule updates, member joins, and meetup plans will appear here.',
      );
    }

    return RefreshIndicator(
      onRefresh: () => notifier.loadActivity(force: true),
      color: AppColors.primary,
      child: ListView.separated(
        padding: const EdgeInsets.only(top: 8, bottom: 40),
        physics: const AlwaysScrollableScrollPhysics(),
        shrinkWrap: true,
        itemCount: state.events.length,
        separatorBuilder: (_, __) => const SizedBox(height: 10),
        itemBuilder: (context, index) {
          final event = state.events[index];
          final eventColor = _getEventColor(event.eventType);
          final eventBg = _getEventBgColor(event.eventType);
          final icon = _getEventIcon(event.eventType);

          return Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.border),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Event icon container
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: eventBg,
                    shape: BoxShape.circle,
                  ),
                  alignment: Alignment.center,
                  child: Icon(icon, size: 16, color: eventColor),
                ),
                const SizedBox(width: 12),

                // Event details
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        event.description,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          if (event.actor?.handle != null) ...[
                            Text(
                              '@${event.actor!.handle}',
                              style: const TextStyle(
                                fontSize: 11,
                                color: AppColors.textMuted,
                                fontFamily: 'monospace',
                              ),
                            ),
                            const SizedBox(width: 6),
                            const Text('•', style: TextStyle(fontSize: 10, color: AppColors.textSubtle)),
                            const SizedBox(width: 6),
                          ],
                          Text(
                            _formatRelativeTime(event.createdAt),
                            style: const TextStyle(
                              fontSize: 11,
                              color: AppColors.textSubtle,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
