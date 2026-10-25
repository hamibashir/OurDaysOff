import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/date_time_utils.dart';
import '../../../../core/utils/haptic_feedback.dart';
import '../../../schedule/models/schedule_entry.dart';

class DashboardTimelineStrip extends StatelessWidget {
  final Map<DateTime, List<ScheduleEntry>> entries;
  final Function(DateTime) onSelectDate;
  final VoidCallback onOpenSchedule;

  const DashboardTimelineStrip({
    super.key,
    required this.entries,
    required this.onSelectDate,
    required this.onOpenSchedule,
  });

  @override
  Widget build(BuildContext context) {
    final now = DateTimeUtils.dateOnly(DateTime.now());
    final days = List.generate(14, (i) => now.add(Duration(days: i)));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Row(
              children: [
                Icon(LucideIcons.calendarDays, size: 16, color: AppColors.primary),
                SizedBox(width: 6),
                Text(
                  '14-DAY AVAILABILITY PREVIEW',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.8,
                    color: AppColors.textMuted,
                  ),
                ),
              ],
            ),
            GestureDetector(
              onTap: () {
                AppHaptics.light();
                onOpenSchedule();
              },
              child: const Row(
                children: [
                  Text(
                    'Full Calendar',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: AppColors.primary,
                    ),
                  ),
                  SizedBox(width: 2),
                  Icon(LucideIcons.chevronRight, size: 14, color: AppColors.primary),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        SizedBox(
          height: 96,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            itemCount: days.length,
            separatorBuilder: (_, __) => const SizedBox(width: 8),
            itemBuilder: (context, index) {
              final day = days[index];
              final isToday = DateTimeUtils.isSameDay(day, now);
              final dayEntries = entries[day] ?? [];

              final hasEntries = dayEntries.isNotEmpty;
              final primaryEntry = hasEntries ? dayEntries.first : null;
              final isOvernight = primaryEntry?.isOvernight == true;

              String statusLabel = 'FREE';
              Color badgeColor = AppColors.statusAvailable;
              Color badgeBg = AppColors.statusAvailableBg;
              Color badgeBorder = AppColors.statusAvailableBorder;

              if (hasEntries && primaryEntry != null && !primaryEntry.isDayOff) {
                if (isOvernight) {
                  statusLabel = 'NIGHT';
                  badgeColor = AppColors.statusOvernight;
                  badgeBg = AppColors.statusOvernightBg;
                  badgeBorder = AppColors.statusOvernightBorder;
                } else if (primaryEntry.entryType == 'leave') {
                  statusLabel = 'LEAVE';
                  badgeColor = AppColors.statusLeave;
                  badgeBg = AppColors.statusLeaveBg;
                  badgeBorder = AppColors.statusLeaveBorder;
                } else {
                  statusLabel = DateTimeUtils.cleanTime(primaryEntry.startTime);
                  badgeColor = AppColors.statusBusy;
                  badgeBg = AppColors.statusBusyBg;
                  badgeBorder = AppColors.statusBusyBorder;
                }
              }

              return InkWell(
                onTap: () {
                  AppHaptics.selection();
                  onSelectDate(day);
                },
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  width: 68,
                  padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 6),
                  decoration: BoxDecoration(
                    color: isToday ? AppColors.primarySurface : AppColors.surface,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isToday ? AppColors.primary : AppColors.border,
                      width: isToday ? 1.5 : 1,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.02),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        isToday ? 'TODAY' : DateFormat('E').format(day).toUpperCase(),
                        style: TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.3,
                          color: isToday ? AppColors.primaryDark : AppColors.textMuted,
                        ),
                      ),
                      Text(
                        '${day.day}',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: isToday ? AppColors.primaryDark : AppColors.textPrimary,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                        decoration: BoxDecoration(
                          color: badgeBg,
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: badgeBorder),
                        ),
                        child: Text(
                          statusLabel,
                          style: TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.w800,
                            color: badgeColor,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
