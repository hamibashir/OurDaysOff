import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/text_styles.dart';
import '../../../../core/utils/haptic_feedback.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../models/circle_model.dart';

class CircleSettingsModal extends StatelessWidget {
  final CircleModel circle;
  final VoidCallback onLeaveCircle;
  final VoidCallback onDeleteCircle;

  const CircleSettingsModal({
    super.key,
    required this.circle,
    required this.onLeaveCircle,
    required this.onDeleteCircle,
  });

  static Future<void> show({
    required BuildContext context,
    required CircleModel circle,
    required VoidCallback onLeaveCircle,
    required VoidCallback onDeleteCircle,
  }) {
    AppHaptics.medium();
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => CircleSettingsModal(
        circle: circle,
        onLeaveCircle: onLeaveCircle,
        onDeleteCircle: onDeleteCircle,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 28,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Drag handle
          Center(
            child: Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Circle Settings',
                style: AppTextStyles.titleMedium.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              IconButton(
                icon: const Icon(LucideIcons.x, size: 20, color: AppColors.textMuted),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Circle Info Card
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.scaffoldBackground,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  circle.name,
                  style: AppTextStyles.titleSmall.copyWith(
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
                const SizedBox(height: 12),
                Row(
                  children: [
                    const Icon(LucideIcons.shield, size: 14, color: AppColors.primary),
                    const SizedBox(width: 6),
                    Text(
                      circle.isPrivate ? 'Private Circle' : 'Discoverable Circle',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppColors.primaryDark,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),
          const Divider(height: 1, color: AppColors.borderLight),
          const SizedBox(height: 24),

          // Destructive Action: Leave Circle or Delete Circle
          if (circle.isOwner) ...[
            Text(
              'Danger Zone',
              style: AppTextStyles.titleSmall.copyWith(
                fontWeight: FontWeight.bold,
                color: AppColors.danger,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'Deleting this circle will permanently delete all rosters, invites, and matching data for all members.',
              style: TextStyle(fontSize: 12, color: AppColors.textMuted),
            ),
            const SizedBox(height: 16),
            AppButton(
              text: 'Delete Circle',
              icon: LucideIcons.trash2,
              variant: AppButtonVariant.danger,
              onPressed: () {
                Navigator.of(context).pop();
                _confirmDeleteCircle(context);
              },
            ),
          ] else ...[
            Text(
              'Circle Membership',
              style: AppTextStyles.titleSmall.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'You can leave this circle at any time. Your schedule and availability will no longer be shared with other members.',
              style: TextStyle(fontSize: 12, color: AppColors.textMuted),
            ),
            const SizedBox(height: 16),
            AppButton(
              text: 'Leave Circle',
              icon: LucideIcons.logOut,
              variant: AppButtonVariant.danger,
              onPressed: () {
                Navigator.of(context).pop();
                _confirmLeaveCircle(context);
              },
            ),
          ],
        ],
      ),
    );
  }

  void _confirmDeleteCircle(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        title: const Text('Delete Circle?'),
        content: Text(
          'Are you sure you want to permanently delete "${circle.name}"? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogCtx).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(dialogCtx).pop();
              onDeleteCircle();
            },
            style: TextButton.styleFrom(foregroundColor: AppColors.danger),
            child: const Text('Delete Permanently'),
          ),
        ],
      ),
    );
  }

  void _confirmLeaveCircle(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        title: const Text('Leave Circle?'),
        content: Text(
          'Are you sure you want to leave "${circle.name}"?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogCtx).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(dialogCtx).pop();
              onLeaveCircle();
            },
            style: TextButton.styleFrom(foregroundColor: AppColors.danger),
            child: const Text('Leave'),
          ),
        ],
      ),
    );
  }
}
