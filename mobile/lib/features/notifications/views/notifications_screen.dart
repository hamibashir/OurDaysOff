import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/text_styles.dart';
import '../models/notification_model.dart';
import '../providers/notification_provider.dart';

class NotificationsScreen extends ConsumerWidget {
  const NotificationsScreen({super.key});

  String _formatNotificationTime(DateTime dt) {
    final now = DateTime.now();
    final difference = now.difference(dt);

    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24 && dt.day == now.day) {
      return DateFormat('h:mm a').format(dt);
    } else if (difference.inDays < 2) {
      return 'Yesterday';
    } else {
      return DateFormat('MMM d, h:mm a').format(dt);
    }
  }

  IconData _getTypeIcon(String type) {
    final lower = type.toLowerCase();
    if (lower.contains('plan') || lower.contains('meetup')) {
      return Icons.event_available_outlined;
    } else if (lower.contains('circle') || lower.contains('member') || lower.contains('invite')) {
      return Icons.people_outline;
    } else if (lower.contains('rota') || lower.contains('schedule') || lower.contains('shift')) {
      return Icons.calendar_today_outlined;
    } else if (lower.contains('device') || lower.contains('pair')) {
      return Icons.devices_outlined;
    }
    return Icons.notifications_outlined;
  }

  Color _getTypeColor(String type) {
    final lower = type.toLowerCase();
    if (lower.contains('plan') || lower.contains('meetup')) {
      return AppColors.primary;
    } else if (lower.contains('circle') || lower.contains('member') || lower.contains('invite')) {
      return AppColors.accentLavender;
    } else if (lower.contains('rota') || lower.contains('schedule') || lower.contains('shift')) {
      return AppColors.statusBusy;
    } else if (lower.contains('device') || lower.contains('pair')) {
      return AppColors.primaryDark;
    }
    return AppColors.textSubtle;
  }

  void _handleNotificationTap(BuildContext context, WidgetRef ref, NotificationModel item) {
    // 1. Mark as read optimistically
    if (!item.isRead) {
      ref.read(notificationsProvider.notifier).markAsRead(item.id);
    }

    // 2. Deep link navigation
    final data = item.data;
    if (data != null && data['url'] != null && data['url'].toString().isNotEmpty) {
      context.push(data['url'].toString());
      return;
    }

    if (data != null && data['plan_id'] != null) {
      context.push('/plans/${data['plan_id']}');
      return;
    }

    if (data != null && data['circle_id'] != null) {
      context.push('/circles/${data['circle_id']}');
      return;
    }

    final lower = item.type.toLowerCase();
    if (lower.contains('plan')) {
      context.push('/plans');
    } else if (lower.contains('circle')) {
      context.push('/circles');
    } else if (lower.contains('schedule') || lower.contains('shift') || lower.contains('rota')) {
      context.push('/schedule');
    } else if (lower.contains('device') || lower.contains('pair') || lower.contains('profile')) {
      context.push('/profile');
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(notificationsProvider);
    final unreadCount = state.unreadCount;

    return Scaffold(
      appBar: AppBar(
        titleSpacing: 0,
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Notifications',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
            if (unreadCount > 0) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.primarySurface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.primaryLight.withValues(alpha: 0.5)),
                ),
                child: Text(
                  '$unreadCount new',
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primaryDark,
                  ),
                ),
              ),
            ],
          ],
        ),
        actions: [
          if (unreadCount > 0)
            TextButton.icon(
              onPressed: () {
                ref.read(notificationsProvider.notifier).markAllAsRead();
              },
              icon: const Icon(Icons.done_all, size: 16, color: AppColors.primary),
              label: const Text(
                'Read all',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                ),
              ),
            ),
          const SizedBox(width: 8),
        ],
      ),
      body: RefreshIndicator(
        color: AppColors.primary,
        onRefresh: () => ref.read(notificationsProvider.notifier).loadNotifications(),
        child: _buildBody(context, ref, state),
      ),
    );
  }

  Widget _buildBody(BuildContext context, WidgetRef ref, NotificationState state) {
    if (state.isLoading && state.notifications.isEmpty) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.primary),
      );
    }

    if (state.errorMessage != null && state.notifications.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.cloud_off, size: 48, color: AppColors.textSubtle),
              const SizedBox(height: 12),
              const Text(
                'Unable to load notifications',
                style: AppTextStyles.titleMedium,
              ),
              const SizedBox(height: 4),
              Text(
                state.errorMessage!,
                textAlign: TextAlign.center,
                style: AppTextStyles.bodySmall,
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: () => ref.read(notificationsProvider.notifier).loadNotifications(),
                icon: const Icon(Icons.refresh, size: 16),
                label: const Text('Try Again'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (state.notifications.isEmpty) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          SizedBox(height: MediaQuery.of(context).size.height * 0.2),
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 64,
                  height: 64,
                  decoration: const BoxDecoration(
                    color: AppColors.primarySurface,
                    shape: BoxShape.circle,
                  ),
                  child: const Center(
                    child: Icon(
                      Icons.notifications_none,
                      size: 32,
                      color: AppColors.primary,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'No notifications yet',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 6),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 40),
                  child: Text(
                    "You're all caught up! Circle updates, rota changes, and meetup invites will appear here.",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 13,
                      color: AppColors.textMuted,
                      height: 1.4,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      );
    }

    return ListView.separated(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      itemCount: state.notifications.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        final item = state.notifications[index];
        return _buildNotificationCard(context, ref, item);
      },
    );
  }

  Widget _buildNotificationCard(
    BuildContext context,
    WidgetRef ref,
    NotificationModel item,
  ) {
    final typeIcon = _getTypeIcon(item.type);
    final typeColor = _getTypeColor(item.type);
    final timeStr = _formatNotificationTime(item.createdAt);

    return InkWell(
      onTap: () => _handleNotificationTap(context, ref, item),
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: item.isRead
              ? AppColors.surface
              : AppColors.primaryLight.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: item.isRead
                ? AppColors.border
                : AppColors.primaryLight.withValues(alpha: 0.35),
            width: item.isRead ? 1 : 1.2,
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Icon pill
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: typeColor.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Icon(typeIcon, size: 20, color: typeColor),
              ),
            ),
            const SizedBox(width: 12),

            // Content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          item.title,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: item.isRead ? FontWeight.w600 : FontWeight.bold,
                            color: item.isRead ? AppColors.textPrimary : AppColors.primaryDark,
                          ),
                        ),
                      ),
                      if (!item.isRead) ...[
                        Container(
                          width: 7,
                          height: 7,
                          margin: const EdgeInsets.only(left: 6, right: 4),
                          decoration: const BoxDecoration(
                            color: AppColors.danger,
                            shape: BoxShape.circle,
                          ),
                        ),
                      ],
                      const SizedBox(width: 4),
                      Text(
                        timeStr,
                        style: const TextStyle(
                          fontSize: 11,
                          color: AppColors.textSubtle,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    item.body,
                    style: TextStyle(
                      fontSize: 12,
                      color: item.isRead ? AppColors.textMuted : AppColors.textPrimary,
                      height: 1.35,
                    ),
                  ),
                ],
              ),
            ),

            // Quick mark as read button
            if (!item.isRead) ...[
              const SizedBox(width: 6),
              IconButton(
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
                icon: const Icon(Icons.check, size: 18, color: AppColors.primary),
                tooltip: 'Mark as read',
                onPressed: () {
                  ref.read(notificationsProvider.notifier).markAsRead(item.id);
                },
              ),
            ],
          ],
        ),
      ),
    );
  }
}
