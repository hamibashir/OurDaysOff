import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/theme/app_colors.dart';
import '../../models/member_daily_status.dart';

class RotaGridCell extends StatelessWidget {
  final MemberDailyStatus? status;
  final VoidCallback? onTap;
  final double width;
  final double height;

  const RotaGridCell({
    super.key,
    required this.status,
    this.onTap,
    this.width = 76.0,
    this.height = 46.0,
  });

  @override
  Widget build(BuildContext context) {
    final cellStatus = status;

    if (cellStatus == null) {
      return SizedBox(
        width: width,
        height: height,
        child: const Center(
          child: Text('—', style: TextStyle(color: AppColors.textSubtle, fontSize: 11)),
        ),
      );
    }

    final config = _getCellStyle(cellStatus);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        width: width,
        height: height,
        margin: const EdgeInsets.symmetric(horizontal: 3, vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
        decoration: BoxDecoration(
          color: config.backgroundColor,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: config.borderColor, width: 1),
        ),
        child: Center(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Flexible(
                child: Text(
                  cellStatus.shortCode,
                  style: TextStyle(
                    color: config.textColor,
                    fontWeight: FontWeight.w700,
                    fontSize: 11,
                    fontFamily: 'monospace',
                    letterSpacing: -0.3,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (cellStatus.isOvernight) ...[
                const SizedBox(width: 3),
                Icon(
                  LucideIcons.moon,
                  size: 9,
                  color: config.textColor,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  _CellColorConfig _getCellStyle(MemberDailyStatus status) {
    if (status.isDayOff || status.status == 'off') {
      return const _CellColorConfig(
        backgroundColor: Color(0x2881D8D0), // ~16% teal
        borderColor: Color(0x6681D8D0), // 40% teal
        textColor: Color(0xFF1D5E57), // dark teal
      );
    }

    if (status.status == 'leave') {
      return const _CellColorConfig(
        backgroundColor: Color(0x35D7D982), // ~21% amber/lime
        borderColor: Color(0x75D7D982),
        textColor: Color(0xFF5C5E1A),
      );
    }

    if (status.status == 'study') {
      return const _CellColorConfig(
        backgroundColor: Color(0x24AE82D9), // ~14% lavender/purple
        borderColor: Color(0x66AE82D9),
        textColor: Color(0xFF6A3E94),
      );
    }

    if (status.status == 'busy') {
      return const _CellColorConfig(
        backgroundColor: Color(0xFFF9EFE7),
        borderColor: Color(0xFFE8DDD4),
        textColor: Color(0xFFA35439),
      );
    }

    if (status.status == 'work') {
      return const _CellColorConfig(
        backgroundColor: AppColors.statusBusyBg,
        borderColor: AppColors.statusBusyBorder,
        textColor: Color(0xFF1D4ED8),
      );
    }

    return const _CellColorConfig(
      backgroundColor: Color(0xFFF3F4F6),
      borderColor: Color(0xFFE5E7EB),
      textColor: AppColors.textSubtle,
    );
  }
}

class _CellColorConfig {
  final Color backgroundColor;
  final Color borderColor;
  final Color textColor;

  const _CellColorConfig({
    required this.backgroundColor,
    required this.borderColor,
    required this.textColor,
  });
}
