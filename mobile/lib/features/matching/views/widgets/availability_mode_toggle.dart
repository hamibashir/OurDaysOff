import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/haptic_feedback.dart';
import '../../models/availability_mode.dart';

class AvailabilityModeToggle extends StatelessWidget {
  final AvailabilityMode currentMode;
  final ValueChanged<AvailabilityMode> onModeChanged;

  const AvailabilityModeToggle({
    super.key,
    required this.currentMode,
    required this.onModeChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppColors.surfaceSecondary,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Expanded(
            child: _buildSegment(
              mode: AvailabilityMode.daysOff,
              isSelected: currentMode == AvailabilityMode.daysOff,
            ),
          ),
          const SizedBox(width: 4),
          Expanded(
            child: _buildSegment(
              mode: AvailabilityMode.offTime,
              isSelected: currentMode == AvailabilityMode.offTime,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSegment({
    required AvailabilityMode mode,
    required bool isSelected,
  }) {
    return InkWell(
      onTap: () {
        if (!isSelected) {
          AppHaptics.selection();
          onModeChanged(mode);
        }
      },
      borderRadius: BorderRadius.circular(10),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeInOut,
        padding: const EdgeInsets.symmetric(vertical: 9, horizontal: 12),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.surface : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          border: isSelected ? Border.all(color: AppColors.borderLight) : null,
          boxShadow: isSelected
              ? const [
                  BoxShadow(
                    color: Color(0x0D000000),
                    blurRadius: 4,
                    offset: Offset(0, 1),
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              mode.icon,
              size: 15,
              color: isSelected ? AppColors.primary : AppColors.textMuted,
            ),
            const SizedBox(width: 6),
            Text(
              mode.label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                color: isSelected ? AppColors.textPrimary : AppColors.textMuted,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
