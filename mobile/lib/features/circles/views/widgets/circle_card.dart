import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/text_styles.dart';
import '../../../../core/utils/haptic_feedback.dart';
import '../../../../shared/widgets/status_badge.dart';
import '../../models/circle_model.dart';

class CircleCard extends StatelessWidget {
  final CircleModel circle;
  final VoidCallback? onTap;

  const CircleCard({
    super.key,
    required this.circle,
    this.onTap,
  });

  StatusBadgeType get _roleBadgeType {
    switch (circle.myRole.toLowerCase()) {
      case 'owner':
        return StatusBadgeType.vip;
      case 'admin':
        return StatusBadgeType.busy;
      default:
        return StatusBadgeType.neutral;
    }
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {
        AppHaptics.light();
        onTap?.call();
      },
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.02),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                // Circle Avatar
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: AppColors.primaryLight.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Center(
                    child: Icon(
                      LucideIcons.users,
                      color: AppColors.primaryDark,
                      size: 20,
                    ),
                  ),
                ),
                const SizedBox(width: 12),

                // Name & Handle
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        circle.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyles.titleSmall,
                      ),
                      if (circle.displayHandle.isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Text(
                          circle.displayHandle,
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.primary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),

                // User Role Badge
                StatusBadge(
                  label: circle.myRole.toUpperCase(),
                  type: _roleBadgeType,
                  isSmall: true,
                ),
                const SizedBox(width: 8),
                const Icon(
                  LucideIcons.chevronRight,
                  size: 18,
                  color: AppColors.textSubtle,
                ),
              ],
            ),
            const SizedBox(height: 12),
            const Divider(height: 1, color: AppColors.borderLight),
            const SizedBox(height: 10),

            // Metadata: Members count & Discoverability
            Row(
              children: [
                const Icon(
                  LucideIcons.userCheck,
                  size: 14,
                  color: AppColors.textMuted,
                ),
                const SizedBox(width: 4),
                Text(
                  '${circle.membersCount} member${circle.membersCount == 1 ? '' : 's'}',
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textMuted,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(width: 16),
                Icon(
                  circle.isPrivate ? LucideIcons.lock : LucideIcons.globe,
                  size: 13,
                  color: AppColors.textMuted,
                ),
                const SizedBox(width: 4),
                Text(
                  circle.isPrivate ? 'Private Circle' : 'Searchable',
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textMuted,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
