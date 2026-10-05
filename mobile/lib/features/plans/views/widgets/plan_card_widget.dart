import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/text_styles.dart';
import '../../../../core/utils/haptic_feedback.dart';
import '../../models/plan_model.dart';

class PlanCardWidget extends StatelessWidget {
  final PlanModel plan;
  final ValueChanged<PlanModel>? onTap;
  final void Function(int planId, String rsvpStatus)? onRsvpChange;

  const PlanCardWidget({
    super.key,
    required this.plan,
    this.onTap,
    this.onRsvpChange,
  });

  IconData _getEventTypeIcon(String eventType) {
    switch (eventType.toLowerCase()) {
      case 'meal':
        return LucideIcons.utensils;
      case 'travel':
        return LucideIcons.plane;
      case 'social':
        return LucideIcons.sparkles;
      default:
        return LucideIcons.calendar;
    }
  }

  Color _getStatusBg(String status) {
    switch (status.toLowerCase()) {
      case 'confirmed':
        return const Color(0xFFECFDF5);
      case 'polling':
        return const Color(0xFFFFFBEB);
      case 'cancelled':
        return const Color(0xFFFEF2F2);
      default:
        return AppColors.surfaceSecondary;
    }
  }

  Color _getStatusBorder(String status) {
    switch (status.toLowerCase()) {
      case 'confirmed':
        return const Color(0xFFA7F3D0);
      case 'polling':
        return const Color(0xFFFDE68A);
      case 'cancelled':
        return const Color(0xFFFECACA);
      default:
        return AppColors.border;
    }
  }

  Color _getStatusTextColor(String status) {
    switch (status.toLowerCase()) {
      case 'confirmed':
        return const Color(0xFF047857);
      case 'polling':
        return const Color(0xFFB45309);
      case 'cancelled':
        return const Color(0xFFB91C1C);
      default:
        return AppColors.textMuted;
    }
  }

  String _formatTiming() {
    if (plan.startAt == null) {
      return 'Date TBD (Polling active)';
    }

    final start = plan.startAt!;
    final dateStr = DateFormat('EEE, MMM d').format(start);
    final startTimeStr = DateFormat('h:mm a').format(start);

    if (plan.endAt != null) {
      final endTimeStr = DateFormat('h:mm a').format(plan.endAt!);
      return '$dateStr • $startTimeStr – $endTimeStr';
    }

    return '$dateStr • $startTimeStr';
  }

  @override
  Widget build(BuildContext context) {
    final statusBg = _getStatusBg(plan.status);
    final statusBorder = _getStatusBorder(plan.status);
    final statusTextColor = _getStatusTextColor(plan.status);
    final eventIcon = _getEventTypeIcon(plan.eventType);

    final attendingList = plan.attendingMembers;

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 0),
      color: AppColors.surface,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: AppColors.border),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () {
          AppHaptics.light();
          onTap?.call(plan);
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top Badges Row: Status + Event Type + Circle Name
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Status Badge
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: statusBg,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: statusBorder),
                    ),
                    child: Text(
                      plan.status.toUpperCase(),
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.5,
                        color: statusTextColor,
                      ),
                    ),
                  ),

                  // Event Type & Circle Tag
                  Row(
                    children: [
                      if (plan.circle != null) ...[
                        Text(
                          plan.circle!.name,
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textMuted,
                          ),
                        ),
                        const SizedBox(width: 8),
                      ],
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                        decoration: BoxDecoration(
                          color: AppColors.scaffoldBackground,
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: AppColors.borderLight),
                        ),
                        child: Row(
                          children: [
                            Icon(eventIcon, size: 12, color: AppColors.primary),
                            const SizedBox(width: 4),
                            Text(
                              plan.eventType.toUpperCase(),
                              style: const TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textPrimary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),

              const SizedBox(height: 12),

              // Plan Title
              Text(
                plan.title,
                style: AppTextStyles.titleMedium.copyWith(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),

              // Description if present
              if (plan.description != null && plan.description!.trim().isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(
                  plan.description!,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textMuted,
                    height: 1.35,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],

              const SizedBox(height: 10),

              // Timing Row
              Row(
                children: [
                  Icon(
                    plan.startAt != null ? LucideIcons.calendar : LucideIcons.helpCircle,
                    size: 14,
                    color: AppColors.primary,
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      _formatTiming(),
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: plan.startAt != null
                            ? AppColors.textPrimary
                            : AppColors.textMuted,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),

              // Location Row if present
              if (plan.hasLocation) ...[
                const SizedBox(height: 6),
                Row(
                  children: [
                    const Icon(LucideIcons.mapPin, size: 14, color: AppColors.primary),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        plan.primaryLocation!.name,
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.w500,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],

              const SizedBox(height: 14),
              const Divider(color: AppColors.borderLight, height: 1),
              const SizedBox(height: 12),

              // Bottom Section: Attendees & Quick RSVP
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Attendees count & Avatars
                  Row(
                    children: [
                      // Stacked Initials
                      if (attendingList.isNotEmpty) ...[
                        SizedBox(
                          height: 24,
                          width: (attendingList.length > 3 ? 3 : attendingList.length) * 16.0 + 10,
                          child: Stack(
                            children: List.generate(
                              attendingList.length > 3 ? 3 : attendingList.length,
                              (i) {
                                final member = attendingList[i];
                                return Positioned(
                                  left: i * 16.0,
                                  child: Container(
                                    width: 24,
                                    height: 24,
                                    decoration: BoxDecoration(
                                      color: AppColors.primary,
                                      shape: BoxShape.circle,
                                      border: Border.all(color: Colors.white, width: 1.5),
                                    ),
                                    child: Center(
                                      child: Text(
                                        member.initials,
                                        style: const TextStyle(
                                          fontSize: 9,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                      ],
                      Text(
                        '${plan.attendingCount} Going',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ],
                  ),

                  // Quick RSVP Buttons
                  Row(
                    children: [
                      _buildRsvpPill(
                        label: 'Going',
                        rsvpStatus: 'attending',
                        isSelected: plan.myRsvp == 'attending',
                        selectedColor: const Color(0xFF10B981),
                        selectedBg: const Color(0xFFECFDF5),
                      ),
                      const SizedBox(width: 4),
                      _buildRsvpPill(
                        label: 'Maybe',
                        rsvpStatus: 'tentative',
                        isSelected: plan.myRsvp == 'tentative',
                        selectedColor: const Color(0xFFF59E0B),
                        selectedBg: const Color(0xFFFFFBEB),
                      ),
                      const SizedBox(width: 4),
                      _buildRsvpPill(
                        label: "Can't",
                        rsvpStatus: 'declined',
                        isSelected: plan.myRsvp == 'declined',
                        selectedColor: const Color(0xFFEF4444),
                        selectedBg: const Color(0xFFFEF2F2),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRsvpPill({
    required String label,
    required String rsvpStatus,
    required bool isSelected,
    required Color selectedColor,
    required Color selectedBg,
  }) {
    return InkWell(
      onTap: () {
        AppHaptics.selection();
        onRsvpChange?.call(plan.id, rsvpStatus);
      },
      borderRadius: BorderRadius.circular(8),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: isSelected ? selectedBg : AppColors.scaffoldBackground,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? selectedColor : AppColors.border,
            width: isSelected ? 1.5 : 1.0,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
            color: isSelected ? selectedColor : AppColors.textMuted,
          ),
        ),
      ),
    );
  }
}
