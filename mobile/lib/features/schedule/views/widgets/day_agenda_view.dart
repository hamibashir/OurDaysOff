import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/text_styles.dart';
import '../../../../core/utils/date_time_utils.dart';
import '../../../../shared/widgets/status_badge.dart';
import '../../providers/schedule_notifier.dart';
import 'date_detail_bottom_sheet.dart';

class DayAgendaView extends ConsumerWidget {
  const DayAgendaView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheduleState = ref.watch(scheduleNotifierProvider);
    final selectedDate = scheduleState.selectedDate;
    final entries = scheduleState.getEntriesForDay(selectedDate);
    final override = scheduleState.getOverrideForDay(selectedDate);
    final isToday = DateTimeUtils.isSameDay(selectedDate, DateTime.now());

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Day Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    DateTimeUtils.formatFullDate(selectedDate),
                    style: AppTextStyles.titleMedium,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    isToday ? 'Today' : DateTimeUtils.formatDayMonth(selectedDate),
                    style: AppTextStyles.bodySmall.copyWith(
                      color: isToday ? AppColors.primaryDark : AppColors.textMuted,
                      fontWeight: isToday ? FontWeight.w700 : FontWeight.w500,
                    ),
                  ),
                ],
              ),
              Row(
                children: [
                  if (override != null) ...[
                    StatusBadge(
                      label: override.isAvailable ? 'Override: Free' : 'Override: Busy',
                      type: override.isAvailable ? StatusBadgeType.available : StatusBadgeType.danger,
                      isSmall: true,
                    ),
                    const SizedBox(width: 8),
                  ],
                  if (entries.isNotEmpty) ...[
                    StatusBadge(
                      label: entries.first.isDayOff ? 'Day Off' : 'Working',
                      type: entries.first.isDayOff
                          ? StatusBadgeType.available
                          : StatusBadgeType.busy,
                      isSmall: true,
                    ),
                    const SizedBox(width: 6),
                  ],
                  IconButton(
                    icon: const Icon(LucideIcons.edit3, size: 18, color: AppColors.primary),
                    tooltip: 'Edit Details & Overrides',
                    onPressed: () => DateDetailBottomSheet.show(context, selectedDate),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Entries List or Empty State
          if (entries.isEmpty)
            GestureDetector(
              onTap: () => DateDetailBottomSheet.show(context, selectedDate),
              child: Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.border),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: const BoxDecoration(
                        color: AppColors.statusAvailableBg,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        LucideIcons.sun,
                        color: AppColors.statusAvailable,
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: 14),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'No Shifts Scheduled',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          SizedBox(height: 2),
                          Text(
                            'You are free and marked as available on this date.',
                            style: TextStyle(fontSize: 12, color: AppColors.textMuted),
                          ),
                        ],
                      ),
                    ),
                    const Icon(LucideIcons.chevronRight, size: 18, color: AppColors.textSubtle),
                  ],
                ),
              ),
            )
          else
            ...entries.map((entry) {
              return GestureDetector(
                onTap: () => DateDetailBottomSheet.show(context, selectedDate),
                child: Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.border),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.02),
                        blurRadius: 8,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: Container(
                      decoration: BoxDecoration(
                        border: Border(
                          left: BorderSide(
                            color: entry.displayColor,
                            width: 5,
                          ),
                        ),
                      ),
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                entry.displayTitle,
                                style: const TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                              Row(
                                children: [
                                  if (entry.isOvernight) ...[
                                    const StatusBadge(
                                      label: 'Overnight',
                                      type: StatusBadgeType.overnight,
                                      isSmall: true,
                                      icon: LucideIcons.moon,
                                    ),
                                    const SizedBox(width: 6),
                                  ],
                                  const Icon(LucideIcons.edit2, size: 14, color: AppColors.textSubtle),
                                ],
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              const Icon(LucideIcons.clock, size: 14, color: AppColors.textMuted),
                              const SizedBox(width: 6),
                              Text(
                                entry.displayTimeRange,
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.textMuted,
                                ),
                              ),
                            ],
                          ),
                          if (entry.notes != null && entry.notes!.trim().isNotEmpty) ...[
                            const SizedBox(height: 8),
                            Text(
                              entry.notes!,
                              style: const TextStyle(
                                fontSize: 12,
                                color: AppColors.textSubtle,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ),
              );
            }),
        ],
      ),
    );
  }
}
