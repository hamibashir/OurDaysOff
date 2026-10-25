import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/haptic_feedback.dart';

class DashboardMetricsGrid extends StatelessWidget {
  final int freeDaysCount;
  final int circlesCount;
  final int activePlansCount;
  final int shiftsCount;
  final VoidCallback? onTapFreeDays;
  final VoidCallback? onTapCircles;
  final VoidCallback? onTapPlans;
  final VoidCallback? onTapShifts;

  const DashboardMetricsGrid({
    super.key,
    required this.freeDaysCount,
    required this.circlesCount,
    required this.activePlansCount,
    required this.shiftsCount,
    this.onTapFreeDays,
    this.onTapCircles,
    this.onTapPlans,
    this.onTapShifts,
  });

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: 1.35,
      children: [
        _MetricCard(
          title: 'FREE DAYS',
          value: '$freeDaysCount',
          subtitle: 'next 14 days',
          badge: 'Available',
          badgeColor: AppColors.statusAvailable,
          icon: LucideIcons.clock,
          color: AppColors.primary,
          onTap: onTapFreeDays,
        ),
        _MetricCard(
          title: 'CIRCLES',
          value: '$circlesCount',
          subtitle: 'connected',
          badge: 'Privacy Set',
          badgeColor: AppColors.accentViolet,
          icon: LucideIcons.users,
          color: AppColors.accentViolet,
          onTap: onTapCircles,
        ),
        _MetricCard(
          title: 'ACTIVE PLANS',
          value: '$activePlansCount',
          subtitle: 'meetups',
          badge: 'RSVP Open',
          badgeColor: const Color(0xFFD97706),
          icon: LucideIcons.calendarCheck,
          color: const Color(0xFFD97706),
          onTap: onTapPlans,
        ),
        _MetricCard(
          title: 'LOGGED SHIFTS',
          value: '$shiftsCount',
          subtitle: 'this period',
          badge: 'Rota Active',
          badgeColor: AppColors.statusBusy,
          icon: LucideIcons.sparkles,
          color: AppColors.statusBusy,
          onTap: onTapShifts,
        ),
      ],
    );
  }
}

class _MetricCard extends StatelessWidget {
  final String title;
  final String value;
  final String subtitle;
  final String badge;
  final Color badgeColor;
  final IconData icon;
  final Color color;
  final VoidCallback? onTap;

  const _MetricCard({
    required this.title,
    required this.value,
    required this.subtitle,
    required this.badge,
    required this.badgeColor,
    required this.icon,
    required this.color,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {
        AppHaptics.light();
        onTap?.call();
      },
      borderRadius: BorderRadius.circular(18),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AppColors.border),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.02),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.8,
                    color: AppColors.textMuted,
                  ),
                ),
                Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, size: 14, color: color),
                ),
              ],
            ),
            Row(
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(width: 6),
                Flexible(
                  child: Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppColors.textMuted,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            Row(
              children: [
                Container(
                  width: 6,
                  height: 6,
                  decoration: BoxDecoration(
                    color: badgeColor,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 5),
                Text(
                  badge,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: badgeColor,
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
