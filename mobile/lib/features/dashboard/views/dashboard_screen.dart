import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/utils/date_time_utils.dart';
import '../../../core/utils/haptic_feedback.dart';
import '../../auth/providers/auth_notifier.dart';
import '../../circles/providers/circles_notifier.dart';
import '../../plans/providers/plan_providers.dart';
import '../../schedule/models/schedule_entry.dart';
import '../../schedule/providers/schedule_notifier.dart';
import 'widgets/dashboard_circles_preview.dart';
import 'widgets/dashboard_hero_card.dart';
import 'widgets/dashboard_metrics_grid.dart';
import 'widgets/dashboard_plans_preview.dart';
import 'widgets/dashboard_quick_actions.dart';
import 'widgets/dashboard_timeline_strip.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  Future<void> _handleRefresh(WidgetRef ref) async {
    AppHaptics.light();
    await Future.wait([
      ref.read(scheduleNotifierProvider.notifier).loadMonth(DateTime.now()),
      ref.read(circlesNotifierProvider.notifier).loadCircles(),
      ref.read(plansListProvider.notifier).refresh(),
    ]);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authNotifierProvider);
    final user = authState.user;
    final scheduleState = ref.watch(scheduleNotifierProvider);
    final circlesState = ref.watch(circlesNotifierProvider);
    final plansAsync = ref.watch(plansListProvider);

    final today = DateTimeUtils.dateOnly(DateTime.now());

    // Derive 14-day metrics dynamically
    int freeDaysCount = 0;
    int shiftsCount = 0;
    ScheduleEntry? nextWorkShift;

    for (int i = 0; i < 14; i++) {
      final day = today.add(Duration(days: i));
      final dayEntries = scheduleState.entries[day] ?? [];
      final hasWork = dayEntries.any((e) => !e.isDayOff);

      if (hasWork) {
        shiftsCount++;
        nextWorkShift ??= dayEntries.firstWhere((e) => !e.isDayOff);
      } else {
        freeDaysCount++;
      }
    }

    final activePlans = plansAsync.valueOrNull ?? [];
    final circles = circlesState.circles;

    return Scaffold(
      backgroundColor: AppColors.scaffoldBackground,
      body: RefreshIndicator(
        onRefresh: () => _handleRefresh(ref),
        color: AppColors.primary,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 1. Hero Greeting Banner
              DashboardHeroCard(user: user),
              const SizedBox(height: 18),

              // 2. High-Frequency Quick Actions
              const DashboardQuickActions(),
              const SizedBox(height: 20),

              // 3. Next Shift Spotlight (if upcoming work shift exists)
              if (nextWorkShift != null) ...[
                _NextShiftBanner(shift: nextWorkShift),
                const SizedBox(height: 18),
              ],

              // 4. Real-Time Overview Metrics Grid
              const Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'OVERVIEW',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.0,
                      color: AppColors.textMuted,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              DashboardMetricsGrid(
                freeDaysCount: freeDaysCount,
                circlesCount: circles.length,
                activePlansCount: activePlans.length,
                shiftsCount: shiftsCount,
                onTapFreeDays: () => context.go('/schedule'),
                onTapCircles: () => context.go('/circles'),
                onTapPlans: () => context.go('/plans'),
                onTapShifts: () => context.go('/schedule'),
              ),
              const SizedBox(height: 24),

              // 5. 14-Day Timeline Preview Strip
              DashboardTimelineStrip(
                entries: scheduleState.entries,
                onSelectDate: (selectedDay) {
                  ref.read(scheduleNotifierProvider.notifier).selectDate(selectedDay);
                  context.go('/schedule');
                },
                onOpenSchedule: () => context.go('/schedule'),
              ),
              const SizedBox(height: 24),

              // 6. Upcoming Meetup Plans & RSVPs
              DashboardPlansPreview(
                plans: activePlans,
                onOpenPlan: (planId) => context.push('/plans/$planId'),
                onSeeAll: () => context.go('/plans'),
                onCreatePlan: () => context.go('/plans?create=true'),
              ),
              const SizedBox(height: 24),

              // 7. My Connected Circles Preview
              DashboardCirclesPreview(
                circles: circles,
                onOpenCircle: (circleId) => context.push('/circles/$circleId'),
                onManageCircles: () => context.go('/circles'),
                onCreateCircle: () => context.go('/circles'),
              ),
              const SizedBox(height: 24),

              // 8. Privacy & Security Reassurance Banner
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.border),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 38,
                      height: 38,
                      decoration: const BoxDecoration(
                        color: AppColors.statusAvailableBg,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(LucideIcons.shieldCheck, color: AppColors.statusAvailable, size: 20),
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Zero-Knowledge Privacy',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          SizedBox(height: 2),
                          Text(
                            'Your shift calendar details and notes remain private. Circle members only see derived free/busy blocks.',
                            style: TextStyle(fontSize: 11, color: AppColors.textMuted),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }
}

class _NextShiftBanner extends StatelessWidget {
  final ScheduleEntry shift;

  const _NextShiftBanner({required this.shift});

  @override
  Widget build(BuildContext context) {
    final now = DateTimeUtils.dateOnly(DateTime.now());
    final isToday = DateTimeUtils.isSameDay(shift.date, now);
    final isTomorrow = DateTimeUtils.isSameDay(shift.date, now.add(const Duration(days: 1)));

    final dayPrefix = isToday
        ? 'Today'
        : (isTomorrow ? 'Tomorrow' : DateFormat('EEEE, MMM d').format(shift.date));

    final timeSpan = '${DateTimeUtils.cleanTime(shift.startTime)} – ${DateTimeUtils.cleanTime(shift.endTime)}';

    return InkWell(
      onTap: () {
        AppHaptics.light();
        context.go('/schedule');
      },
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: shift.isOvernight ? AppColors.statusOvernightBg : AppColors.statusBusyBg,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: shift.isOvernight ? AppColors.statusOvernightBorder : AppColors.statusBusyBorder,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: shift.isOvernight ? AppColors.statusOvernight : AppColors.statusBusy,
                shape: BoxShape.circle,
              ),
              child: Icon(
                shift.isOvernight ? LucideIcons.moon : LucideIcons.briefcase,
                color: Colors.white,
                size: 18,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        'Upcoming Shift: ${shift.displayTitle}',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: shift.isOvernight ? AppColors.statusOvernight : const Color(0xFF1E40AF),
                        ),
                      ),
                      if (shift.isOvernight) ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                          decoration: BoxDecoration(
                            color: AppColors.statusOvernight.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Text(
                            'OVERNIGHT',
                            style: TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.w800,
                              color: AppColors.statusOvernight,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '$dayPrefix • $timeSpan',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: shift.isOvernight
                          ? AppColors.statusOvernight.withValues(alpha: 0.8)
                          : const Color(0xFF3B82F6),
                    ),
                  ),
                ],
              ),
            ),
            const Icon(LucideIcons.chevronRight, size: 16, color: AppColors.textSubtle),
          ],
        ),
      ),
    );
  }
}
