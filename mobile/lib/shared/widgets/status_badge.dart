import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';

enum StatusBadgeType {
  available, // Free / Day off
  busy,      // Working / Shift
  leave,     // Leave / Vacation
  overnight, // Overnight shift
  neutral,   // Neutral tag
  vip,       // VIP Gold
  danger,    // Declined / Error
}

class StatusBadge extends StatelessWidget {
  final String label;
  final StatusBadgeType type;
  final IconData? icon;
  final bool isSmall;

  const StatusBadge({
    super.key,
    required this.label,
    this.type = StatusBadgeType.neutral,
    this.icon,
    this.isSmall = false,
  });

  @override
  Widget build(BuildContext context) {
    Color bg;
    Color border;
    Color text;

    switch (type) {
      case StatusBadgeType.available:
        bg = AppColors.statusAvailableBg;
        border = AppColors.statusAvailableBorder;
        text = AppColors.statusAvailable;
      case StatusBadgeType.busy:
        bg = AppColors.statusBusyBg;
        border = AppColors.statusBusyBorder;
        text = AppColors.statusBusy;
      case StatusBadgeType.leave:
        bg = AppColors.statusLeaveBg;
        border = AppColors.statusLeaveBorder;
        text = AppColors.statusLeave;
      case StatusBadgeType.overnight:
        bg = AppColors.statusOvernightBg;
        border = AppColors.statusOvernightBorder;
        text = AppColors.statusOvernight;
      case StatusBadgeType.vip:
        bg = const Color(0xFFFEF9C3);
        border = const Color(0xFFFDE047);
        text = const Color(0xFF854D0E);
      case StatusBadgeType.danger:
        bg = AppColors.dangerBg;
        border = AppColors.dangerBorder;
        text = AppColors.danger;
      case StatusBadgeType.neutral:
        bg = AppColors.surfaceSecondary;
        border = AppColors.border;
        text = AppColors.textMuted;
    }

    final double hPadding = isSmall ? 7 : 10;
    final double vPadding = isSmall ? 2 : 4;
    final double fontSize = isSmall ? 10 : 11;
    final double iconSize = isSmall ? 10 : 12;

    return Container(
      padding: EdgeInsets.symmetric(horizontal: hPadding, vertical: vPadding),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(100),
        border: Border.all(color: border, width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: iconSize, color: text),
            const SizedBox(width: 4),
          ],
          Text(
            label,
            style: TextStyle(
              fontSize: fontSize,
              fontWeight: FontWeight.w600,
              color: text,
            ),
          ),
        ],
      ),
    );
  }
}
