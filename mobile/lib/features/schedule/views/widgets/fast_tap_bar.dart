import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/text_styles.dart';
import '../../models/shift_template.dart';
import '../../providers/schedule_notifier.dart';
import 'create_template_sheet.dart';

class FastTapBar extends ConsumerWidget {
  const FastTapBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheduleState = ref.watch(scheduleNotifierProvider);
    final notifier = ref.read(scheduleNotifierProvider.notifier);
    final templates = scheduleState.templates;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: const Border(
          top: BorderSide(color: AppColors.border, width: 1),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, -3),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Mode Banner
            if (scheduleState.isStampModeActive) ...[
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
                color: AppColors.primarySurface,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        const Icon(LucideIcons.stamp, size: 15, color: AppColors.primaryDark),
                        const SizedBox(width: 8),
                        Text(
                          scheduleState.isDayOffStampActive
                              ? 'Active Stamp: Day Off'
                              : scheduleState.isEraseStampActive
                                  ? 'Active Stamp: Clear / Erase'
                                  : 'Active Stamp: ${scheduleState.activeStamp?.name ?? "Shift"}',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: AppColors.primaryDark,
                          ),
                        ),
                      ],
                    ),
                    GestureDetector(
                      onTap: () => notifier.clearStampMode(),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          borderRadius: BorderRadius.circular(100),
                        ),
                        child: const Row(
                          children: [
                            Text(
                              'Done',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            SizedBox(width: 3),
                            Icon(LucideIcons.check, size: 12, color: Colors.white),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ] else ...[
              const Padding(
                padding: EdgeInsets.only(left: 16, right: 16, top: 8, bottom: 2),
                child: Row(
                  children: [
                    Icon(LucideIcons.zap, size: 13, color: AppColors.primary),
                    SizedBox(width: 6),
                    Text(
                      'FAST-TAP STAMPING (Tap preset to stamp dates)',
                      style: AppTextStyles.labelSmall,
                    ),
                  ],
                ),
              ),
            ],

            // Horizontal Toolbar of Preset Pills
            SizedBox(
              height: 52,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                children: [
                  // 1. Day Off Preset Pill
                  _StampPill(
                    label: '+ Day Off',
                    color: AppColors.statusAvailable,
                    isActive: scheduleState.isDayOffStampActive,
                    onTap: () => notifier.setDayOffStamp(),
                  ),

                  // 2. Default Quick Presets (if no custom templates yet)
                  if (templates.isEmpty) ...[
                    _StampPill(
                      label: '+ Day (07-15)',
                      color: AppColors.statusBusy,
                      isActive: scheduleState.activeStamp?.name == 'Day Shift',
                      onTap: () {
                        const defaultDay = ShiftTemplate(
                          id: -1,
                          name: 'Day Shift',
                          startTime: '07:00',
                          endTime: '15:30',
                          color: '#3B82F6',
                        );
                        notifier.setActiveTemplateStamp(defaultDay);
                      },
                    ),
                    _StampPill(
                      label: '+ Night (21-07)',
                      color: AppColors.statusOvernight,
                      isActive: scheduleState.activeStamp?.name == 'Night Shift',
                      onTap: () {
                        const defaultNight = ShiftTemplate(
                          id: -2,
                          name: 'Night Shift',
                          startTime: '21:00',
                          endTime: '07:00',
                          isOvernight: true,
                          color: '#8B5CF6',
                        );
                        notifier.setActiveTemplateStamp(defaultNight);
                      },
                    ),
                  ] else ...[
                    // Custom User Templates
                    ...templates.map((template) {
                      final isSelected = scheduleState.activeStamp?.id == template.id;
                      return _StampPill(
                        label: '+ ${template.name}',
                        color: template.colorValue,
                        isActive: isSelected,
                        onTap: () => notifier.setActiveTemplateStamp(template),
                      );
                    }),
                  ],

                  // 3. Erase / Clear Tool
                  _StampPill(
                    label: 'Clear',
                    color: AppColors.danger,
                    icon: LucideIcons.eraser,
                    isActive: scheduleState.isEraseStampActive,
                    onTap: () => notifier.setEraseStamp(),
                  ),

                  // 4. Add Custom Template (+)
                  GestureDetector(
                    onTap: () => CreateTemplateSheet.show(context),
                    child: Container(
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceSecondary,
                        borderRadius: BorderRadius.circular(100),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(LucideIcons.plus, size: 14, color: AppColors.textPrimary),
                          SizedBox(width: 4),
                          Text(
                            'New Preset',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StampPill extends StatelessWidget {
  final String label;
  final Color color;
  final bool isActive;
  final VoidCallback onTap;
  final IconData? icon;

  const _StampPill({
    required this.label,
    required this.color,
    required this.isActive,
    required this.onTap,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        margin: const EdgeInsets.symmetric(horizontal: 4),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: isActive ? color : color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(100),
          border: Border.all(
            color: isActive ? AppColors.textPrimary : color.withValues(alpha: 0.4),
            width: isActive ? 2 : 1,
          ),
          boxShadow: isActive
              ? [
                  BoxShadow(
                    color: color.withValues(alpha: 0.4),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(
                icon,
                size: 13,
                color: isActive ? Colors.white : color,
              ),
              const SizedBox(width: 5),
            ],
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: isActive ? Colors.white : color,
              ),
            ),
            if (isActive) ...[
              const SizedBox(width: 5),
              const Icon(
                LucideIcons.check,
                size: 13,
                color: Colors.white,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
