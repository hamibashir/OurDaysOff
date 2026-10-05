import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/text_styles.dart';
import '../../../../core/utils/haptic_feedback.dart';
import '../../models/circle_roster_member.dart';

class PersonalCompareTool extends StatelessWidget {
  final List<CircleRosterMember> availableMembers;
  final List<int> selectedUserIds;
  final ValueChanged<int> onToggleUser;
  final VoidCallback onSelectAll;
  final VoidCallback onDeselectAll;
  final VoidCallback onRunCompare;
  final VoidCallback? onResetToCircle;
  final bool isCustomCompare;
  final bool isLoading;
  final String? circleName;

  const PersonalCompareTool({
    super.key,
    required this.availableMembers,
    required this.selectedUserIds,
    required this.onToggleUser,
    required this.onSelectAll,
    required this.onDeselectAll,
    required this.onRunCompare,
    this.onResetToCircle,
    this.isCustomCompare = false,
    this.isLoading = false,
    this.circleName,
  });

  @override
  Widget build(BuildContext context) {
    if (availableMembers.isEmpty) {
      return const SizedBox.shrink();
    }

    final allSelected = selectedUserIds.length == availableMembers.length;
    final canCalculate = selectedUserIds.length >= 2;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isCustomCompare ? AppColors.primary : AppColors.border,
          width: isCustomCompare ? 1.5 : 1.0,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Bar
          Row(
            children: [
              const Icon(LucideIcons.sliders, size: 16, color: AppColors.primary),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  circleName != null ? 'Compare: $circleName' : 'Member Comparison',
                  style: AppTextStyles.titleSmall,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
                decoration: BoxDecoration(
                  color: AppColors.primarySurface,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '${selectedUserIds.length} of ${availableMembers.length} Active',
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primaryDark,
                    fontFamily: 'monospace',
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          const Text(
            'Select 2 or more members to calculate custom overlapping free time.',
            style: TextStyle(fontSize: 11, color: AppColors.textMuted),
          ),
          const SizedBox(height: 12),

          // Member Toggle Chips
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: availableMembers.map((member) {
              final isSelected = selectedUserIds.contains(member.user.id);

              return InkWell(
                onTap: () {
                  AppHaptics.selection();
                  onToggleUser(member.user.id);
                },
                borderRadius: BorderRadius.circular(10),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: isSelected ? const Color(0x2881D8D0) : AppColors.scaffoldBackground,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: isSelected ? AppColors.primaryLight : AppColors.border,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        isSelected ? LucideIcons.check : LucideIcons.plus,
                        size: 13,
                        color: isSelected ? AppColors.primaryDark : AppColors.textSubtle,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        member.user.name,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                          color: isSelected ? AppColors.primaryDark : AppColors.textMuted,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),

          // Validation alert if < 2 selected
          if (!canCalculate) ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.statusLeaveBg,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.statusLeaveBorder),
              ),
              child: const Row(
                children: [
                  Icon(LucideIcons.alertCircle, size: 14, color: AppColors.statusLeave),
                  SizedBox(width: 6),
                  Text(
                    'Select at least 2 members to calculate common free time.',
                    style: TextStyle(fontSize: 11, color: AppColors.textPrimary),
                  ),
                ],
              ),
            ),
          ],

          const SizedBox(height: 14),
          const Divider(color: AppColors.borderLight, height: 1),
          const SizedBox(height: 12),

          // Bottom Action Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Select/Deselect All button
              TextButton(
                onPressed: () {
                  AppHaptics.light();
                  if (allSelected) {
                    onDeselectAll();
                  } else {
                    onSelectAll();
                  }
                },
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: Text(
                  allSelected ? 'Deselect All' : 'Select All',
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textMuted,
                  ),
                ),
              ),

              Row(
                children: [
                  if (isCustomCompare && onResetToCircle != null) ...[
                    OutlinedButton.icon(
                      icon: const Icon(LucideIcons.rotateCcw, size: 12),
                      label: const Text('Reset', style: TextStyle(fontSize: 11)),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.textMuted,
                        side: const BorderSide(color: AppColors.border),
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      onPressed: () {
                        AppHaptics.light();
                        onResetToCircle!();
                      },
                    ),
                    const SizedBox(width: 8),
                  ],
                  ElevatedButton.icon(
                    icon: isLoading
                        ? const SizedBox(
                            width: 12,
                            height: 12,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(LucideIcons.refreshCw, size: 12),
                    label: Text(
                      isLoading ? 'Calculating...' : 'Recalculate Match',
                      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      elevation: 0,
                    ),
                    onPressed: canCalculate && !isLoading
                        ? () {
                            AppHaptics.medium();
                            onRunCompare();
                          }
                        : null,
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}
