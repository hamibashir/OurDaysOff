import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/text_styles.dart';
import '../../../../core/utils/haptic_feedback.dart';
import '../../models/availability_mode.dart';
import '../../models/circle_roster_member.dart';
import '../../models/days_off_summary.dart';
import '../../models/off_time_summary.dart';
import 'date_overlap_breakdown_sheet.dart';

class ModeSummaryHighlightCard extends StatelessWidget {
  final AvailabilityMode mode;
  final Map<String, DaysOffDateSummary> daysOffSummary;
  final Map<String, OffTimeDateSummary> offTimeSummary;
  final List<CircleRosterMember> members;

  const ModeSummaryHighlightCard({
    super.key,
    required this.mode,
    required this.daysOffSummary,
    required this.offTimeSummary,
    this.members = const [],
  });

  String _formatDateShort(String dateStr) {
    try {
      final parsed = DateTime.parse(dateStr);
      return DateFormat('EEE, d MMM').format(parsed);
    } catch (_) {
      return dateStr;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (mode == AvailabilityMode.daysOff) {
      return _buildDaysOffCard(context);
    } else {
      return _buildOffTimeCard(context);
    }
  }

  Widget _buildDaysOffCard(BuildContext context) {
    // Find dates where at least one member is off, prioritize allFree
    final validDates = daysOffSummary.entries
        .where((e) => e.value.freeCount > 0)
        .toList()
      ..sort((a, b) {
        if (a.value.allFree && !b.value.allFree) return -1;
        if (!a.value.allFree && b.value.allFree) return 1;
        return b.value.freeCount.compareTo(a.value.freeCount);
      });

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(LucideIcons.calendarCheck, size: 16, color: AppColors.primary),
              const SizedBox(width: 8),
              const Text(
                'Top Days Off',
                style: AppTextStyles.titleSmall,
              ),
              const Spacer(),
              Text(
                '${validDates.length} matching dates',
                style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
              ),
            ],
          ),
          const SizedBox(height: 10),

          if (validDates.isEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
              decoration: BoxDecoration(
                color: AppColors.scaffoldBackground,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Row(
                children: [
                  Icon(LucideIcons.info, size: 16, color: AppColors.textSubtle),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'No members have full days off in this date range. Try switching to "Off Time" to find shift overlaps.',
                      style: TextStyle(fontSize: 11, color: AppColors.textMuted),
                    ),
                  ),
                ],
              ),
            )
          else
            SizedBox(
              height: 82,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                itemCount: validDates.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (context, index) {
                  final entry = validDates[index];
                  final dateStr = entry.key;
                  final summary = entry.value;
                  final allOff = summary.allFree;

                  return InkWell(
                    onTap: () {
                      AppHaptics.selection();
                      DateOverlapBreakdownSheet.show(
                        context: context,
                        dateStr: dateStr,
                        mode: AvailabilityMode.daysOff,
                        daysOffSummary: summary,
                        offTimeSummary: offTimeSummary[dateStr],
                        members: members,
                      );
                    },
                    borderRadius: BorderRadius.circular(10),
                    child: Container(
                      width: 148,
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                      decoration: BoxDecoration(
                        color: allOff ? const Color(0x2881D8D0) : AppColors.scaffoldBackground,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: allOff ? const Color(0x6681D8D0) : AppColors.border,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Text(
                                  _formatDateShort(dateStr),
                                  style: const TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.textPrimary,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              if (allOff)
                                const Icon(LucideIcons.sparkles, size: 13, color: AppColors.primaryDark),
                            ],
                          ),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: allOff ? AppColors.primaryDark : AppColors.surface,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  allOff ? 'ALL OFF' : '${summary.freeCount}/${summary.totalCount} Off',
                                  style: TextStyle(
                                    fontSize: 9,
                                    fontWeight: FontWeight.bold,
                                    color: allOff ? Colors.white : AppColors.primaryDark,
                                    fontFamily: 'monospace',
                                  ),
                                ),
                              ),
                              const SizedBox(width: 4),
                              Flexible(
                                child: Text(
                                  '${summary.freeMembers.length} free',
                                  style: const TextStyle(fontSize: 10, color: AppColors.textMuted),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildOffTimeCard(BuildContext context) {
    // Find dates where there is a common overlap window
    final validDates = offTimeSummary.entries
        .where((e) => e.value.hasOverlap && e.value.bestWindow != null)
        .toList()
      ..sort((a, b) {
        final durA = a.value.bestWindow?.durationMinutes ?? 0;
        final durB = b.value.bestWindow?.durationMinutes ?? 0;
        return durB.compareTo(durA);
      });

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(LucideIcons.clock, size: 16, color: AppColors.primary),
              const SizedBox(width: 8),
              const Text(
                'Top Overlapping Shift Windows',
                style: AppTextStyles.titleSmall,
              ),
              const Spacer(),
              Text(
                '${validDates.length} windows found',
                style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
              ),
            ],
          ),
          const SizedBox(height: 10),

          if (validDates.isEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
              decoration: BoxDecoration(
                color: AppColors.scaffoldBackground,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Row(
                children: [
                  Icon(LucideIcons.info, size: 16, color: AppColors.textSubtle),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'No overlapping free time windows across all members on these dates.',
                      style: TextStyle(fontSize: 11, color: AppColors.textMuted),
                    ),
                  ),
                ],
              ),
            )
          else
            SizedBox(
              height: 88,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                itemCount: validDates.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (context, index) {
                  final entry = validDates[index];
                  final dateStr = entry.key;
                  final summary = entry.value;
                  final best = summary.bestWindow!;

                  return InkWell(
                    onTap: () {
                      AppHaptics.selection();
                      DateOverlapBreakdownSheet.show(
                        context: context,
                        dateStr: dateStr,
                        mode: AvailabilityMode.offTime,
                        daysOffSummary: daysOffSummary[dateStr],
                        offTimeSummary: summary,
                        members: members,
                      );
                    },
                    borderRadius: BorderRadius.circular(10),
                    child: Container(
                      width: 172,
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: const Color(0x2881D8D0),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: const Color(0x6681D8D0)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Text(
                                  _formatDateShort(dateStr),
                                  style: const TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.textPrimary,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const SizedBox(width: 4),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                                decoration: BoxDecoration(
                                  color: AppColors.surface,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  best.durationFormatted,
                                  style: const TextStyle(
                                    fontSize: 9,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.primaryDark,
                                    fontFamily: 'monospace',
                                  ),
                                ),
                              ),
                            ],
                          ),
                          Row(
                            children: [
                              const Icon(LucideIcons.sparkles, size: 12, color: AppColors.primaryDark),
                              const SizedBox(width: 4),
                              Flexible(
                                child: Text(
                                  '${best.start} — ${best.end}',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w800,
                                    fontFamily: 'monospace',
                                    color: AppColors.primaryDark,
                                    letterSpacing: -0.3,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }
}
