import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/text_styles.dart';
import '../../../../core/utils/haptic_feedback.dart';
import '../../models/availability_mode.dart';
import '../../models/circle_roster_member.dart';
import '../../models/days_off_summary.dart';
import '../../models/member_daily_status.dart';
import '../../models/off_time_summary.dart';
import 'date_overlap_breakdown_sheet.dart';
import 'member_cell_detail_sheet.dart';
import 'rota_grid_cell.dart';

class RotaGridMatrix extends StatelessWidget {
  final List<CircleRosterMember> members;
  final AvailabilityMode mode;
  final Map<String, DaysOffDateSummary> daysOffSummary;
  final Map<String, OffTimeDateSummary> offTimeSummary;
  final List<String>? customDates;
  final void Function(CircleRosterMember member, String dateStr, MemberDailyStatus status)? onCellTap;

  static const double memberColumnWidth = 124.0;
  static const double cellWidth = 74.0;
  static const double rowHeight = 48.0;
  static const double headerHeight = 58.0;

  const RotaGridMatrix({
    super.key,
    required this.members,
    this.mode = AvailabilityMode.daysOff,
    this.daysOffSummary = const {},
    this.offTimeSummary = const {},
    this.customDates,
    this.onCellTap,
  });

  List<String> _getSortedDates() {
    if (customDates != null && customDates!.isNotEmpty) {
      return customDates!;
    }
    final allDates = <String>{};
    for (final member in members) {
      allDates.addAll(member.dailyStatus.keys);
    }
    final list = allDates.toList()..sort();
    return list;
  }

  DaysOffDateSummary? _findDayOffSummary(String dateStr) {
    return daysOffSummary[dateStr];
  }

  @override
  Widget build(BuildContext context) {
    if (members.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 36, horizontal: 20),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          children: [
            const Icon(LucideIcons.users, size: 36, color: AppColors.textSubtle),
            const SizedBox(height: 12),
            Text(
              'No active members in circle',
              style: AppTextStyles.titleSmall.copyWith(color: AppColors.textMuted),
            ),
          ],
        ),
      );
    }

    final dates = _getSortedDates();

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0A000000),
            blurRadius: 10,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Card Title
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              children: [
                const Icon(LucideIcons.calendarDays, size: 18, color: AppColors.primary),
                const SizedBox(width: 8),
                Text(
                  'Rota Grid Matrix',
                  style: AppTextStyles.titleSmall.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                Text(
                  '${members.length} members · ${dates.length} days',
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppColors.textMuted,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          const Divider(color: AppColors.border, height: 1),

          // 2D Matrix Table
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Sticky Left Column (Members)
              SizedBox(
                width: memberColumnWidth,
                child: Column(
                  children: [
                    // Member column header
                    Container(
                      height: headerHeight,
                      alignment: Alignment.centerLeft,
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: const BoxDecoration(
                        color: AppColors.scaffoldBackground,
                        border: Border(
                          bottom: BorderSide(color: AppColors.border, width: 1),
                          right: BorderSide(color: AppColors.border, width: 1),
                        ),
                      ),
                      child: const Text(
                        'MEMBER',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.5,
                          color: AppColors.textMuted,
                        ),
                      ),
                    ),

                    // Member rows
                    ...members.map((member) {
                      return Container(
                        height: rowHeight,
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        decoration: const BoxDecoration(
                          border: Border(
                            bottom: BorderSide(color: AppColors.borderLight, width: 1),
                            right: BorderSide(color: AppColors.border, width: 1),
                          ),
                        ),
                        child: Row(
                          children: [
                            // Avatar
                            Container(
                              width: 26,
                              height: 26,
                              decoration: const BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [AppColors.primaryLight, AppColors.accentLavender],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                                shape: BoxShape.circle,
                              ),
                              child: Center(
                                child: Text(
                                  member.user.initials,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 6),

                            // Name & Privacy badge
                            Expanded(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    member.user.name,
                                    style: const TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.textPrimary,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  Text(
                                    member.visibility.toUpperCase(),
                                    style: const TextStyle(
                                      fontSize: 8,
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.textSubtle,
                                      letterSpacing: 0.2,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
                    }),
                  ],
                ),
              ),

              // Horizontally Scrollable Right Columns (Dates & Cells)
              Expanded(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  physics: const BouncingScrollPhysics(),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Dates Header Row
                      Row(
                        children: dates.map((dateStr) {
                          final dayOffSummary = _findDayOffSummary(dateStr);
                          final offTime = offTimeSummary[dateStr];
                          DateTime? parsedDate = DateTime.tryParse(dateStr);
                          final weekday = parsedDate != null
                              ? DateFormat('EEE').format(parsedDate).toUpperCase()
                              : '';
                          final dayNum = parsedDate != null
                              ? DateFormat('d MMM').format(parsedDate)
                              : dateStr;

                          final allOff = dayOffSummary?.allFree ?? false;
                          final hasOverlap = offTime?.hasOverlap ?? false;
                          final isHighlighted = (mode == AvailabilityMode.daysOff && allOff) ||
                              (mode == AvailabilityMode.offTime && hasOverlap);

                          return InkWell(
                            onTap: () {
                              AppHaptics.selection();
                              DateOverlapBreakdownSheet.show(
                                context: context,
                                dateStr: dateStr,
                                mode: mode,
                                daysOffSummary: dayOffSummary,
                                offTimeSummary: offTime,
                                members: members,
                              );
                            },
                            child: Container(
                              width: cellWidth,
                              height: headerHeight,
                              padding: const EdgeInsets.symmetric(vertical: 2, horizontal: 2),
                              decoration: BoxDecoration(
                                color: isHighlighted
                                    ? const Color(0x2881D8D0)
                                    : AppColors.scaffoldBackground,
                                border: const Border(
                                  bottom: BorderSide(color: AppColors.border, width: 1),
                                  right: BorderSide(color: AppColors.borderLight, width: 1),
                                ),
                              ),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    weekday,
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w700,
                                      fontFamily: 'monospace',
                                      color: isHighlighted
                                          ? AppColors.primaryDark
                                          : AppColors.textMuted,
                                    ),
                                  ),
                                  Text(
                                    dayNum,
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                      color: isHighlighted
                                          ? AppColors.primaryDark
                                          : AppColors.textPrimary,
                                    ),
                                  ),
                                  if (mode == AvailabilityMode.daysOff) ...[
                                    if (allOff)
                                      const Text(
                                        'ALL OFF',
                                        style: TextStyle(
                                          fontSize: 7,
                                          fontWeight: FontWeight.w900,
                                          color: AppColors.primaryDark,
                                        ),
                                      )
                                    else if (dayOffSummary != null && dayOffSummary.freeCount > 0)
                                      Text(
                                        '${dayOffSummary.freeCount}/${dayOffSummary.totalCount} OFF',
                                        style: const TextStyle(
                                          fontSize: 7,
                                          fontWeight: FontWeight.w700,
                                          color: AppColors.textMuted,
                                        ),
                                      ),
                                  ] else ...[
                                    if (hasOverlap && offTime?.bestWindow != null)
                                      Text(
                                        '${offTime!.bestWindow!.start}–${offTime.bestWindow!.end}',
                                        style: const TextStyle(
                                          fontSize: 7,
                                          fontWeight: FontWeight.w800,
                                          fontFamily: 'monospace',
                                          color: AppColors.primaryDark,
                                        ),
                                      )
                                    else
                                      const Text(
                                        '—',
                                        style: TextStyle(
                                          fontSize: 7,
                                          color: AppColors.textSubtle,
                                        ),
                                      ),
                                  ],
                                ],
                              ),
                            ),
                          );
                        }).toList(),
                      ),

                      // Member Cells Rows
                      ...members.map((member) {
                        return Row(
                          children: dates.map((dateStr) {
                            final status = member.dailyStatus[dateStr];

                            return Container(
                              width: cellWidth,
                              height: rowHeight,
                              decoration: const BoxDecoration(
                                border: Border(
                                  bottom: BorderSide(color: AppColors.borderLight, width: 1),
                                  right: BorderSide(color: AppColors.borderLight, width: 1),
                                ),
                              ),
                              child: RotaGridCell(
                                status: status,
                                width: cellWidth,
                                height: rowHeight,
                                onTap: () {
                                  AppHaptics.selection();
                                  if (onCellTap != null && status != null) {
                                    onCellTap!(member, dateStr, status);
                                  } else if (status != null) {
                                    MemberCellDetailSheet.show(
                                      context: context,
                                      member: member,
                                      dateStr: dateStr,
                                      status: status,
                                    );
                                  }
                                },
                              ),
                            );
                          }).toList(),
                        );
                      }),
                    ],
                  ),
                ),
              ),
            ],
          ),

          // Legend Bar at bottom
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            child: Wrap(
              spacing: 12,
              runSpacing: 6,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                _buildLegendItem('OFF', 'Day Off', const Color(0x2881D8D0), const Color(0xFF1D5E57)),
                _buildLegendItem('A/L', 'Leave', const Color(0x35D7D982), const Color(0xFF5C5E1A)),
                _buildLegendItem('WORK', 'Shift', AppColors.statusBusyBg, const Color(0xFF1D4ED8)),
                _buildLegendItem('DEV', 'Study', const Color(0x24AE82D9), const Color(0xFF6A3E94)),
                _buildLegendItem('BUSY', 'Private', const Color(0xFFF9EFE7), const Color(0xFFA35439)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLegendItem(String code, String label, Color bg, Color text) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1.5),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(4),
          ),
          child: Text(
            code,
            style: TextStyle(
              fontSize: 9,
              fontWeight: FontWeight.bold,
              color: text,
              fontFamily: 'monospace',
            ),
          ),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: const TextStyle(
            fontSize: 10,
            color: AppColors.textMuted,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}
