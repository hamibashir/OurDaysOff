import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/text_styles.dart';
import '../../models/circle_roster_member.dart';
import '../../models/member_daily_status.dart';

class MemberCellDetailSheet extends StatelessWidget {
  final CircleRosterMember member;
  final String dateStr;
  final MemberDailyStatus status;

  const MemberCellDetailSheet({
    super.key,
    required this.member,
    required this.dateStr,
    required this.status,
  });

  static Future<void> show({
    required BuildContext context,
    required CircleRosterMember member,
    required String dateStr,
    required MemberDailyStatus status,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => MemberCellDetailSheet(
        member: member,
        dateStr: dateStr,
        status: status,
      ),
    );
  }

  String _formatDisplayDate(String dateStr) {
    try {
      final parsed = DateTime.parse(dateStr);
      return DateFormat('EEEE, MMM d, yyyy').format(parsed);
    } catch (_) {
      return dateStr;
    }
  }

  @override
  Widget build(BuildContext context) {
    final formattedDate = _formatDisplayDate(dateStr);
    final user = member.user;

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

          // Member Header Row
          Row(
            children: [
              // Avatar
              Container(
                width: 44,
                height: 44,
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
                    user.initials,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
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
                      user.name,
                      style: AppTextStyles.titleMedium.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (user.handle != null && user.handle!.isNotEmpty)
                      Text(
                        '@${user.handle}',
                        style: const TextStyle(
                          color: AppColors.textMuted,
                          fontSize: 12,
                          fontFamily: 'monospace',
                        ),
                      ),
                  ],
                ),
              ),

              // Visibility Badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0x1FA882D9),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0x40A882D9)),
                ),
                child: Text(
                  member.visibilityLabel,
                  style: const TextStyle(
                    color: Color(0xFF6A3E94),
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    fontFamily: 'monospace',
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),
          const Divider(color: AppColors.border, height: 1),
          const SizedBox(height: 16),

          // Date banner
          Row(
            children: [
              const Icon(LucideIcons.calendar, size: 16, color: AppColors.primary),
              const SizedBox(width: 8),
              Text(
                formattedDate,
                style: AppTextStyles.bodyMedium.copyWith(
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),

          const SizedBox(height: 14),

          // Status & Shift Info Card
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.scaffoldBackground,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      status.label,
                      style: AppTextStyles.titleSmall.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: status.isDayOff
                            ? const Color(0x2881D8D0)
                            : AppColors.statusBusyBg,
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                          color: status.isDayOff
                              ? const Color(0x6681D8D0)
                              : AppColors.statusBusyBorder,
                        ),
                      ),
                      child: Text(
                        status.shortCode,
                        style: TextStyle(
                          color: status.isDayOff
                              ? const Color(0xFF1D5E57)
                              : const Color(0xFF1D4ED8),
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'monospace',
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),

                // Timing details
                if (status.startTime != null && status.endTime != null) ...[
                  Row(
                    children: [
                      const Icon(LucideIcons.clock, size: 14, color: AppColors.textMuted),
                      const SizedBox(width: 6),
                      Text(
                        'Shift Hours: ${status.startTime} — ${status.endTime}',
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.textPrimary,
                          fontFamily: 'monospace',
                        ),
                      ),
                    ],
                  ),
                ] else if (status.isDayOff) ...[
                  const Row(
                    children: [
                      Icon(LucideIcons.checkCircle2, size: 14, color: AppColors.primary),
                      SizedBox(width: 6),
                      Text(
                        'Full Day Off — No shifts scheduled',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.primaryDark,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ],

                if (status.isOvernight) ...[
                  const SizedBox(height: 6),
                  const Row(
                    children: [
                      Icon(LucideIcons.moon, size: 14, color: AppColors.statusOvernight),
                      SizedBox(width: 6),
                      Text(
                        'Overnight shift (ends the following morning)',
                        style: TextStyle(
                          fontSize: 11,
                          color: AppColors.statusOvernight,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ],

                // Notes if visible
                if (status.notes != null && status.notes!.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  const Divider(color: AppColors.borderLight, height: 1),
                  const SizedBox(height: 8),
                  Text(
                    'Notes: ${status.notes}',
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textMuted,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ],
            ),
          ),

          const SizedBox(height: 14),

          // Privacy Guarantee Notice
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.primarySurface,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0x4D81D8D0)),
            ),
            child: const Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(LucideIcons.shieldCheck, size: 16, color: AppColors.primary),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Privacy-first guarantee: Free/Busy members hide shift names and custom notes automatically.',
                    style: TextStyle(
                      fontSize: 11,
                      color: AppColors.primaryDark,
                      height: 1.3,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
