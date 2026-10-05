import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/text_styles.dart';
import '../../../../core/utils/haptic_feedback.dart';
import '../../models/plan_member_model.dart';
import '../../models/plan_model.dart';

class PlanRsvpBar extends StatelessWidget {
  final PlanModel plan;
  final ValueChanged<String> onRsvpSelected;

  const PlanRsvpBar({
    super.key,
    required this.plan,
    required this.onRsvpSelected,
  });

  void _showAttendeeCohortSheet(BuildContext context) {
    AppHaptics.light();
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => Container(
        decoration: const BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(ctx).size.height * 0.75,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
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
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Row(
                  children: [
                    Icon(LucideIcons.users, size: 20, color: AppColors.primary),
                    SizedBox(width: 8),
                    Text('Attendee Roster', style: AppTextStyles.titleMedium),
                  ],
                ),
                IconButton(
                  icon: const Icon(LucideIcons.x, size: 20, color: AppColors.textSubtle),
                  onPressed: () => Navigator.of(ctx).pop(),
                ),
              ],
            ),
            const Divider(color: AppColors.borderLight),
            const SizedBox(height: 8),

            Expanded(
              child: ListView(
                children: [
                  _buildCohortSection(
                    title: 'Attending (${plan.attendingCount})',
                    members: plan.attendingMembers,
                    badgeColor: const Color(0xFF10B981),
                    badgeBg: const Color(0xFFECFDF5),
                  ),
                  _buildCohortSection(
                    title: 'Tentative (${plan.tentativeMembers.length})',
                    members: plan.tentativeMembers,
                    badgeColor: const Color(0xFFD99E82),
                    badgeBg: const Color(0xFFFFFBEB),
                  ),
                  _buildCohortSection(
                    title: "Can't Go (${plan.declinedMembers.length})",
                    members: plan.declinedMembers,
                    badgeColor: const Color(0xFFEF4444),
                    badgeBg: const Color(0xFFFEF2F2),
                  ),
                  if (plan.pendingMembers.isNotEmpty)
                    _buildCohortSection(
                      title: 'Pending (${plan.pendingMembers.length})',
                      members: plan.pendingMembers,
                      badgeColor: AppColors.textMuted,
                      badgeBg: AppColors.scaffoldBackground,
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCohortSection({
    required String title,
    required List<PlanMemberModel> members,
    required Color badgeColor,
    required Color badgeBg,
  }) {
    if (members.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: badgeBg,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: badgeColor.withValues(alpha: 0.3)),
            ),
            child: Text(
              title,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: badgeColor,
              ),
            ),
          ),
          const SizedBox(height: 8),
          ...members.map((member) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 4),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 14,
                      backgroundColor: AppColors.primarySurface,
                      child: Text(
                        member.initials,
                        style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primaryDark,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            member.displayName,
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          if (member.handle != null)
                            Text(
                              '@${member.handle}',
                              style: const TextStyle(
                                fontSize: 11,
                                color: AppColors.textSubtle,
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              )),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'YOUR RSVP',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.5,
                  color: AppColors.textMuted,
                ),
              ),
              InkWell(
                onTap: () => _showAttendeeCohortSheet(context),
                borderRadius: BorderRadius.circular(6),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  child: Row(
                    children: [
                      Text(
                        '${plan.attendingCount} Going',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primaryDark,
                        ),
                      ),
                      const SizedBox(width: 4),
                      const Icon(LucideIcons.chevronRight, size: 14, color: AppColors.primary),
                    ],
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // 3-Segmented RSVP Selector
          Row(
            children: [
              Expanded(
                child: _buildRsvpButton(
                  label: 'Going',
                  status: 'attending',
                  count: plan.attendingCount,
                  isSelected: plan.myRsvp == 'attending',
                  icon: LucideIcons.check,
                  activeColor: const Color(0xFF10B981),
                  activeBg: const Color(0xFFECFDF5),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildRsvpButton(
                  label: 'Maybe',
                  status: 'tentative',
                  count: plan.tentativeMembers.length,
                  isSelected: plan.myRsvp == 'tentative',
                  icon: LucideIcons.helpCircle,
                  activeColor: const Color(0xFFD99E82),
                  activeBg: const Color(0xFFFFFBEB),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildRsvpButton(
                  label: "Can't Go",
                  status: 'declined',
                  count: plan.declinedMembers.length,
                  isSelected: plan.myRsvp == 'declined',
                  icon: LucideIcons.x,
                  activeColor: const Color(0xFFEF4444),
                  activeBg: const Color(0xFFFEF2F2),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRsvpButton({
    required String label,
    required String status,
    required int count,
    required bool isSelected,
    required IconData icon,
    required Color activeColor,
    required Color activeBg,
  }) {
    return InkWell(
      onTap: () {
        AppHaptics.medium();
        onRsvpSelected(status);
      },
      borderRadius: BorderRadius.circular(12),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
        decoration: BoxDecoration(
          color: isSelected ? activeBg : AppColors.scaffoldBackground,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? activeColor : AppColors.border,
            width: isSelected ? 1.5 : 1.0,
          ),
        ),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  icon,
                  size: 14,
                  color: isSelected ? activeColor : AppColors.textMuted,
                ),
                const SizedBox(width: 4),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                    color: isSelected ? activeColor : AppColors.textPrimary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 2),
            Text(
              '$count',
              style: TextStyle(
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                color: isSelected ? activeColor : AppColors.textSubtle,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
