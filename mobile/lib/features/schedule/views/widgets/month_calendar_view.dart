import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:table_calendar/table_calendar.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/text_styles.dart';
import '../../../../core/utils/date_time_utils.dart';
import '../../models/schedule_entry.dart';
import '../../providers/schedule_notifier.dart';

class MonthCalendarView extends ConsumerWidget {
  const MonthCalendarView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheduleState = ref.watch(scheduleNotifierProvider);
    final notifier = ref.read(scheduleNotifierProvider.notifier);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // Month Header with Prev/Next Navigation
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(LucideIcons.calendar, size: 18, color: AppColors.primary),
                    const SizedBox(width: 8),
                    Text(
                      DateTimeUtils.formatMonthYear(scheduleState.focusedMonth),
                      style: AppTextStyles.titleMedium,
                    ),
                  ],
                ),
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(LucideIcons.chevronLeft, size: 20),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      splashRadius: 20,
                      onPressed: () {
                        final prev = DateTime(
                          scheduleState.focusedMonth.year,
                          scheduleState.focusedMonth.month - 1,
                          1,
                        );
                        notifier.changeFocusedMonth(prev);
                      },
                    ),
                    const SizedBox(width: 14),
                    IconButton(
                      icon: const Icon(LucideIcons.chevronRight, size: 20),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      splashRadius: 20,
                      onPressed: () {
                        final next = DateTime(
                          scheduleState.focusedMonth.year,
                          scheduleState.focusedMonth.month + 1,
                          1,
                        );
                        notifier.changeFocusedMonth(next);
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
          const Divider(height: 1),

          // Table Calendar Core
          TableCalendar<ScheduleEntry>(
            firstDay: DateTime.utc(2020, 1, 1),
            lastDay: DateTime.utc(2035, 12, 31),
            focusedDay: scheduleState.focusedMonth,
            currentDay: DateTime.now(),
            calendarFormat: CalendarFormat.month,
            startingDayOfWeek: StartingDayOfWeek.monday,
            headerVisible: false,
            rowHeight: 46,
            daysOfWeekHeight: 28,
            daysOfWeekStyle: const DaysOfWeekStyle(
              weekdayStyle: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: AppColors.textSubtle,
              ),
              weekendStyle: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: AppColors.textMuted,
              ),
            ),
            selectedDayPredicate: (day) =>
                DateTimeUtils.isSameDay(day, scheduleState.selectedDate),
            eventLoader: (day) => scheduleState.getEntriesForDay(day),
            onDaySelected: (selectedDay, focusedDay) {
              notifier.selectDate(selectedDay);
            },
            onPageChanged: (focusedDay) {
              notifier.changeFocusedMonth(focusedDay);
            },
            calendarBuilders: CalendarBuilders(
              // Selected Day Cell
              selectedBuilder: (context, day, focusedDay) {
                return Center(
                  child: Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(10),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primary.withValues(alpha: 0.3),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      '${day.day}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                );
              },
              // Today Cell
              todayBuilder: (context, day, focusedDay) {
                return Center(
                  child: Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: AppColors.primarySurface,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: AppColors.primaryLight, width: 1.5),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      '${day.day}',
                      style: const TextStyle(
                        color: AppColors.primaryDark,
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                );
              },
              // Outside Days Cell
              outsideBuilder: (context, day, focusedDay) {
                return Center(
                  child: Text(
                    '${day.day}',
                    style: const TextStyle(
                      color: Color(0xFFC4C2BE),
                      fontSize: 13,
                    ),
                  ),
                );
              },
              // Multi-color Shift Marker Dots
              markerBuilder: (context, day, events) {
                if (events.isEmpty) return null;

                return Positioned(
                  bottom: 3,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: events.take(3).map((entry) {
                      return Container(
                        margin: const EdgeInsets.symmetric(horizontal: 1.5),
                        width: 5,
                        height: 5,
                        decoration: BoxDecoration(
                          color: entry.displayColor,
                          shape: BoxShape.circle,
                        ),
                      );
                    }).toList(),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 10),
        ],
      ),
    );
  }
}
