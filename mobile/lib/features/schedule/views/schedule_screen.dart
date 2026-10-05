import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../core/theme/app_colors.dart';
import '../providers/schedule_notifier.dart';
import 'widgets/day_agenda_view.dart';
import 'widgets/fast_tap_bar.dart';
import 'widgets/month_calendar_view.dart';

class ScheduleScreen extends ConsumerWidget {
  const ScheduleScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheduleState = ref.watch(scheduleNotifierProvider);
    final notifier = ref.read(scheduleNotifierProvider.notifier);

    return Scaffold(
      backgroundColor: AppColors.scaffoldBackground,
      appBar: AppBar(
        title: const Text('My Schedule'),
        elevation: 0,
        actions: [
          TextButton.icon(
            icon: const Icon(LucideIcons.calendarCheck, size: 16),
            label: const Text(
              'Today',
              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
            ),
            style: TextButton.styleFrom(
              foregroundColor: AppColors.primaryDark,
            ),
            onPressed: () => notifier.jumpToToday(),
          ),
          IconButton(
            icon: const Icon(LucideIcons.rotateCw, size: 18),
            tooltip: 'Refresh',
            onPressed: () => notifier.loadMonth(scheduleState.focusedMonth),
          ),
        ],
      ),
      bottomNavigationBar: const FastTapBar(),
      body: RefreshIndicator(
        onRefresh: () => notifier.loadMonth(scheduleState.focusedMonth),
        color: AppColors.primary,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.only(bottom: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (scheduleState.errorMessage != null) ...[
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.dangerBg,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.dangerBorder),
                  ),
                  child: Row(
                    children: [
                      const Icon(LucideIcons.alertCircle, size: 18, color: AppColors.danger),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          scheduleState.errorMessage!,
                          style: const TextStyle(
                            color: AppColors.danger,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              const MonthCalendarView(),
              const SizedBox(height: 8),
              const DayAgendaView(),
            ],
          ),
        ),
      ),
    );
  }
}
