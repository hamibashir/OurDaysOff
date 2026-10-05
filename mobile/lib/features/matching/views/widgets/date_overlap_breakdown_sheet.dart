import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/text_styles.dart';
import '../../models/availability_mode.dart';
import '../../models/circle_roster_member.dart';
import '../../models/days_off_summary.dart';
import '../../models/off_time_summary.dart';

class DateOverlapBreakdownSheet extends StatelessWidget {
  final String dateStr;
  final AvailabilityMode mode;
  final DaysOffDateSummary? daysOffSummary;
  final OffTimeDateSummary? offTimeSummary;
  final List<CircleRosterMember> members;

  const DateOverlapBreakdownSheet({
    super.key,
    required this.dateStr,
    required this.mode,
    this.daysOffSummary,
    this.offTimeSummary,
    this.members = const [],
  });

  static Future<void> show({
    required BuildContext context,
    required String dateStr,
    required AvailabilityMode mode,
    DaysOffDateSummary? daysOffSummary,
    OffTimeDateSummary? offTimeSummary,
    List<CircleRosterMember> members = const [],
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => DateOverlapBreakdownSheet(
        dateStr: dateStr,
        mode: mode,
        daysOffSummary: daysOffSummary,
        offTimeSummary: offTimeSummary,
        members: members,
      ),
    );
  }

  String _formatDisplayDate(String date) {
    try {
      final parsed = DateTime.parse(date);
      return DateFormat('EEEE, MMM d, yyyy').format(parsed);
    } catch (_) {
      return date;
    }
  }

  @override
  Widget build(BuildContext context) {
    final formattedDate = _formatDisplayDate(dateStr);

    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 14,
        bottom: MediaQuery.of(context).viewInsets.bottom + 28,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
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
          const SizedBox(height: 18),

          // Header Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    formattedDate,
                    style: AppTextStyles.titleMedium.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    mode == AvailabilityMode.daysOff
                        ? 'Full Days Off Breakdown'
                        : 'Overlapping Off Time Breakdown',
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textMuted,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.primarySurface,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0x4D81D8D0)),
                ),
                child: Row(
                  children: [
                    Icon(mode.icon, size: 13, color: AppColors.primaryDark),
                    const SizedBox(width: 4),
                    Text(
                      mode.label,
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: AppColors.primaryDark,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),
          const Divider(color: AppColors.border, height: 1),
          const SizedBox(height: 16),

          // Mode-specific content
          if (mode == AvailabilityMode.daysOff)
            _buildDaysOffContent()
          else
            _buildOffTimeContent(),
        ],
      ),
    );
  }

  Widget _buildDaysOffContent() {
    final summary = daysOffSummary;
    if (summary == null) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 16),
        child: Center(
          child: Text('No availability summary for this date.', style: TextStyle(color: AppColors.textMuted)),
        ),
      );
    }

    final allFree = summary.allFree;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Status overview banner
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: allFree ? const Color(0x2881D8D0) : AppColors.scaffoldBackground,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: allFree ? const Color(0x6681D8D0) : AppColors.border,
            ),
          ),
          child: Row(
            children: [
              Icon(
                allFree ? LucideIcons.sparkles : LucideIcons.info,
                size: 18,
                color: allFree ? AppColors.primaryDark : AppColors.textMuted,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  allFree
                      ? '100% Shared Day Off! All ${summary.totalCount} members are completely off.'
                      : '${summary.freeCount} of ${summary.totalCount} members have this day off.',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: allFree ? AppColors.primaryDark : AppColors.textPrimary,
                  ),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 14),

        // Free Members List
        if (summary.freeMembers.isNotEmpty) ...[
          const Text(
            'OFF WORK TODAY',
            style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, letterSpacing: 0.5, color: AppColors.textMuted),
          ),
          const SizedBox(height: 6),
          ...summary.freeMembers.map(
            (u) => _buildMemberTile(
              name: u.name,
              handle: u.handle,
              initials: u.initials,
              statusBadge: 'OFF',
              badgeColor: const Color(0x2881D8D0),
              textColor: const Color(0xFF1D5E57),
            ),
          ),
          const SizedBox(height: 12),
        ],

        // Working Members List
        if (summary.workingMembers.isNotEmpty) ...[
          const Text(
            'ON SHIFT TODAY',
            style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, letterSpacing: 0.5, color: AppColors.textMuted),
          ),
          const SizedBox(height: 6),
          ...summary.workingMembers.map(
            (u) {
              final mStatus = _findMemberDailyStatus(u.id);
              final code = mStatus?.shortCode ?? 'WORK';
              return _buildMemberTile(
                name: u.name,
                handle: u.handle,
                initials: u.initials,
                statusBadge: code,
                badgeColor: AppColors.statusBusyBg,
                textColor: const Color(0xFF1D4ED8),
              );
            },
          ),
        ],
      ],
    );
  }

  Widget _buildOffTimeContent() {
    final summary = offTimeSummary;
    final bestWindow = summary?.bestWindow;
    final hasOverlap = summary?.hasOverlap ?? false;
    final commonIntervals = summary?.commonIntervals ?? [];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Best Window Card
        if (hasOverlap && bestWindow != null) ...[
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0x2881D8D0),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0x6681D8D0)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Row(
                      children: [
                        Icon(LucideIcons.sparkles, size: 16, color: AppColors.primaryDark),
                        SizedBox(width: 6),
                        Text(
                          'Best Overlap Window',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: AppColors.primaryDark,
                          ),
                        ),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        bestWindow.durationFormatted,
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primaryDark,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  '${bestWindow.start} — ${bestWindow.end}',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    fontFamily: 'monospace',
                    color: AppColors.primaryDark,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'All active members are free during this window.',
                  style: TextStyle(fontSize: 11, color: AppColors.primaryDark),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
        ] else ...[
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.scaffoldBackground,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.border),
            ),
            child: const Row(
              children: [
                Icon(LucideIcons.clockAlert, size: 18, color: AppColors.textSubtle),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'No common 100% overlapping window found across all members on this date.',
                    style: TextStyle(fontSize: 12, color: AppColors.textMuted),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
        ],

        // Common intervals chips
        if (commonIntervals.isNotEmpty) ...[
          const Text(
            'COMMON FREE TIME BLOCKS',
            style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, letterSpacing: 0.5, color: AppColors.textMuted),
          ),
          const SizedBox(height: 6),
          Wrap(
            spacing: 8,
            runSpacing: 6,
            children: commonIntervals.map((interval) {
              final start = interval['start'] ?? '';
              final end = interval['end'] ?? '';
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: const Color(0x2881D8D0),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0x6681D8D0)),
                ),
                child: Text(
                  '$start – $end',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    fontFamily: 'monospace',
                    color: Color(0xFF1D5E57),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ],
    );
  }

  Widget _buildMemberTile({
    required String name,
    required String? handle,
    required String initials,
    required String statusBadge,
    required Color badgeColor,
    required Color textColor,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Container(
            width: 28,
            height: 28,
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
                initials,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                if (handle != null && handle.isNotEmpty)
                  Text(
                    '@$handle',
                    style: const TextStyle(fontSize: 10, color: AppColors.textMuted, fontFamily: 'monospace'),
                  ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: badgeColor,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              statusBadge,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                fontFamily: 'monospace',
                color: textColor,
              ),
            ),
          ),
        ],
      ),
    );
  }

  dynamic _findMemberDailyStatus(int userId) {
    try {
      final member = members.firstWhere((m) => m.user.id == userId);
      return member.dailyStatus[dateStr];
    } catch (_) {
      return null;
    }
  }
}
