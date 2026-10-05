import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/text_styles.dart';
import '../../../../core/utils/date_time_utils.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../../../shared/widgets/app_text_field.dart';
import '../../../../shared/widgets/confirmation_dialog.dart';
import '../../../../shared/widgets/status_badge.dart';
import '../../models/schedule_entry.dart';
import '../../providers/schedule_notifier.dart';

class DateDetailBottomSheet extends ConsumerStatefulWidget {
  final DateTime date;

  const DateDetailBottomSheet({
    super.key,
    required this.date,
  });

  static Future<void> show(BuildContext context, DateTime date) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => DateDetailBottomSheet(date: date),
    );
  }

  @override
  ConsumerState<DateDetailBottomSheet> createState() => _DateDetailBottomSheetState();
}

class _DateDetailBottomSheetState extends ConsumerState<DateDetailBottomSheet> {
  late final TextEditingController _labelController;
  late final TextEditingController _startTimeController;
  late final TextEditingController _endTimeController;
  late final TextEditingController _notesController;
  late final TextEditingController _overrideReasonController;

  String _selectedEntryType = 'work';
  bool _isOvernight = false;
  String _overrideStatus = 'none'; // 'none', 'available', 'unavailable'
  bool _isSavingShift = false;
  bool _isSavingOverride = false;
  String? _shiftError;
  String? _overrideError;

  @override
  void initState() {
    super.initState();
    final scheduleState = ref.read(scheduleNotifierProvider);
    final entries = scheduleState.getEntriesForDay(widget.date);
    final existingEntry = entries.isNotEmpty ? entries.first : null;
    final existingOverride = scheduleState.getOverrideForDay(widget.date);

    _labelController = TextEditingController(text: existingEntry?.label ?? existingEntry?.shiftTemplate?.name ?? '');
    _startTimeController = TextEditingController(text: existingEntry?.startTime ?? '08:00');
    _endTimeController = TextEditingController(text: existingEntry?.endTime ?? '16:30');
    _notesController = TextEditingController(text: existingEntry?.notes ?? '');
    _selectedEntryType = existingEntry?.entryType ?? 'work';
    _isOvernight = existingEntry?.isOvernight ?? false;

    if (existingOverride != null) {
      _overrideStatus = existingOverride.status;
      _overrideReasonController = TextEditingController(text: existingOverride.reason ?? '');
    } else {
      _overrideStatus = 'none';
      _overrideReasonController = TextEditingController();
    }
  }

  @override
  void dispose() {
    _labelController.dispose();
    _startTimeController.dispose();
    _endTimeController.dispose();
    _notesController.dispose();
    _overrideReasonController.dispose();
    super.dispose();
  }

  Future<void> _handleSaveShift(ScheduleEntry? existingEntry) async {
    setState(() {
      _isSavingShift = true;
      _shiftError = null;
    });

    try {
      await ref.read(scheduleNotifierProvider.notifier).saveScheduleEntry(
            date: widget.date,
            startTime: _startTimeController.text.trim(),
            endTime: _endTimeController.text.trim(),
            entryType: _selectedEntryType,
            label: _labelController.text.trim().isNotEmpty
                ? _labelController.text.trim()
                : null,
            notes: _notesController.text.trim().isNotEmpty
                ? _notesController.text.trim()
                : null,
            isOvernight: _isOvernight,
            shiftTemplateId: existingEntry?.shiftTemplateId,
          );
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        setState(() {
          _isSavingShift = false;
          _shiftError = e.toString().replaceFirst('Exception: ', '');
        });
      }
    }
  }

  Future<void> _handleDeleteShift(ScheduleEntry entry) async {
    final confirmed = await ConfirmationDialog.show(
      context: context,
      title: 'Delete Shift',
      message: 'Remove this scheduled shift from ${DateTimeUtils.formatDayMonth(widget.date)}?',
      confirmLabel: 'Delete',
      isDestructive: true,
    );

    if (confirmed == true && mounted) {
      setState(() => _isSavingShift = true);
      try {
        await ref.read(scheduleNotifierProvider.notifier).deleteScheduleEntry(entry.id, widget.date);
        if (mounted) Navigator.pop(context);
      } catch (e) {
        if (mounted) {
          setState(() {
            _isSavingShift = false;
            _shiftError = e.toString().replaceFirst('Exception: ', '');
          });
        }
      }
    }
  }

  Future<void> _handleSaveOverride() async {
    setState(() {
      _isSavingOverride = true;
      _overrideError = null;
    });

    try {
      final notifier = ref.read(scheduleNotifierProvider.notifier);
      if (_overrideStatus == 'none') {
        await notifier.removeAvailabilityOverride(widget.date);
      } else {
        await notifier.setAvailabilityOverride(
          date: widget.date,
          status: _overrideStatus,
          reason: _overrideReasonController.text.trim().isNotEmpty
              ? _overrideReasonController.text.trim()
              : null,
        );
      }
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        setState(() {
          _isSavingOverride = false;
          _overrideError = e.toString().replaceFirst('Exception: ', '');
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheduleState = ref.watch(scheduleNotifierProvider);
    final entries = scheduleState.getEntriesForDay(widget.date);
    final existingEntry = entries.isNotEmpty ? entries.first : null;

    final entryTypes = [
      {'key': 'work', 'label': 'Work Shift'},
      {'key': 'off', 'label': 'Day Off'},
      {'key': 'leave', 'label': 'Annual Leave'},
      {'key': 'personal', 'label': 'Personal'},
    ];

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.88,
        ),
        padding: const EdgeInsets.all(22),
        decoration: const BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        DateTimeUtils.formatFullDate(widget.date),
                        style: AppTextStyles.titleMedium,
                      ),
                      const SizedBox(height: 2),
                      const Text(
                        'Shift Details & Availability Overrides',
                        style: TextStyle(fontSize: 12, color: AppColors.textMuted),
                      ),
                    ],
                  ),
                  IconButton(
                    icon: const Icon(LucideIcons.x, size: 20),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 18),

              // SECTION 1: SHIFT DETAILS
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.scaffoldBackground,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.border),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Row(
                          children: [
                            Icon(LucideIcons.briefcase, size: 16, color: AppColors.primary),
                            SizedBox(width: 8),
                            Text('Shift Assignment', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
                          ],
                        ),
                        if (existingEntry != null)
                          StatusBadge(
                            label: existingEntry.isDayOff ? 'Day Off' : 'Active Shift',
                            type: existingEntry.isDayOff ? StatusBadgeType.available : StatusBadgeType.busy,
                            isSmall: true,
                          ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    if (_shiftError != null) ...[
                      Text(_shiftError!, style: const TextStyle(color: AppColors.danger, fontSize: 12)),
                      const SizedBox(height: 8),
                    ],

                    // Entry Type Selector
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: entryTypes.map((type) {
                        final isSelected = _selectedEntryType == type['key'];
                        return ChoiceChip(
                          label: Text(type['label']!),
                          selected: isSelected,
                          selectedColor: AppColors.primary,
                          labelStyle: TextStyle(
                            color: isSelected ? Colors.white : AppColors.textPrimary,
                            fontWeight: FontWeight.w600,
                            fontSize: 12,
                          ),
                          onSelected: (val) {
                            if (val) {
                              setState(() {
                                _selectedEntryType = type['key']!;
                                if (_selectedEntryType == 'off') {
                                  _startTimeController.text = '00:00';
                                  _endTimeController.text = '24:00';
                                  _labelController.text = 'Day Off';
                                  _isOvernight = false;
                                }
                              });
                            }
                          },
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 14),

                    AppTextField(
                      controller: _labelController,
                      label: 'Shift Label / Custom Title',
                      hint: 'e.g. Day Shift, ICU, Flight',
                      prefixIcon: LucideIcons.tag,
                    ),
                    const SizedBox(height: 12),

                    if (_selectedEntryType != 'off') ...[
                      Row(
                        children: [
                          Expanded(
                            child: AppTextField(
                              controller: _startTimeController,
                              label: 'Start Time',
                              hint: '07:00',
                              prefixIcon: LucideIcons.clock,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: AppTextField(
                              controller: _endTimeController,
                              label: 'End Time',
                              hint: '15:30',
                              prefixIcon: LucideIcons.clock,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Checkbox(
                            value: _isOvernight,
                            activeColor: AppColors.primary,
                            onChanged: (val) => setState(() => _isOvernight = val ?? false),
                          ),
                          const Text(
                            'Spans past midnight (Overnight)',
                            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                    ],

                    AppTextField(
                      controller: _notesController,
                      label: 'Notes / Location (Optional)',
                      hint: 'e.g. Ward 4B, coverage for Sarah',
                      prefixIcon: LucideIcons.fileText,
                    ),
                    const SizedBox(height: 16),

                    Row(
                      children: [
                        Expanded(
                          child: AppButton(
                            text: existingEntry != null ? 'Update Shift' : 'Save Shift',
                            isLoading: _isSavingShift,
                            onPressed: () => _handleSaveShift(existingEntry),
                          ),
                        ),
                        if (existingEntry != null) ...[
                          const SizedBox(width: 10),
                          IconButton(
                            icon: const Icon(LucideIcons.trash2, color: AppColors.danger),
                            tooltip: 'Delete Shift',
                            onPressed: () => _handleDeleteShift(existingEntry),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // SECTION 2: MANUAL AVAILABILITY OVERRIDES
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.scaffoldBackground,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.border),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(LucideIcons.sliders, size: 16, color: AppColors.accentViolet),
                        SizedBox(width: 8),
                        Text(
                          'Availability Override',
                          style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Overrides force your availability for circle matching regardless of whether you have a shift scheduled.',
                      style: AppTextStyles.bodySmall.copyWith(color: AppColors.textMuted),
                    ),
                    const SizedBox(height: 12),
                    if (_overrideError != null) ...[
                      Text(_overrideError!, style: const TextStyle(color: AppColors.danger, fontSize: 12)),
                      const SizedBox(height: 8),
                    ],

                    // Override status selector
                    SegmentedButton<String>(
                      segments: const [
                        ButtonSegment(
                          value: 'none',
                          label: Text('Normal', style: TextStyle(fontSize: 11)),
                        ),
                        ButtonSegment(
                          value: 'available',
                          label: Text('Force Free', style: TextStyle(fontSize: 11)),
                          icon: Icon(LucideIcons.check, size: 13),
                        ),
                        ButtonSegment(
                          value: 'unavailable',
                          label: Text('Force Busy', style: TextStyle(fontSize: 11)),
                          icon: Icon(LucideIcons.x, size: 13),
                        ),
                      ],
                      selected: {_overrideStatus},
                      onSelectionChanged: (val) {
                        setState(() => _overrideStatus = val.first);
                      },
                    ),
                    if (_overrideStatus != 'none') ...[
                      const SizedBox(height: 14),
                      AppTextField(
                        controller: _overrideReasonController,
                        label: 'Reason for Override (Optional)',
                        hint: 'e.g. Doctor visit, family event',
                        prefixIcon: LucideIcons.messageSquare,
                      ),
                    ],
                    const SizedBox(height: 16),
                    AppButton(
                      text: 'Save Override',
                      variant: AppButtonVariant.secondary,
                      isLoading: _isSavingOverride,
                      onPressed: _handleSaveOverride,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}
