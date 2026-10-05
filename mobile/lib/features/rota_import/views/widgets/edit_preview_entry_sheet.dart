import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/text_styles.dart';
import '../../../../core/utils/haptic_feedback.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../../../shared/widgets/app_text_field.dart';
import '../../models/import_preview_entry.dart';

class EditPreviewEntrySheet extends StatefulWidget {
  final ImportPreviewEntry? initialEntry;
  final bool isNew;

  const EditPreviewEntrySheet({
    super.key,
    this.initialEntry,
    this.isNew = false,
  });

  static Future<ImportPreviewEntry?> show(
    BuildContext context, {
    ImportPreviewEntry? initialEntry,
    bool isNew = false,
  }) {
    AppHaptics.selection();
    return showModalBottomSheet<ImportPreviewEntry>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => EditPreviewEntrySheet(
        initialEntry: initialEntry,
        isNew: isNew,
      ),
    );
  }

  @override
  State<EditPreviewEntrySheet> createState() => _EditPreviewEntrySheetState();
}

class _EditPreviewEntrySheetState extends State<EditPreviewEntrySheet> {
  late final TextEditingController _dateController;
  late final TextEditingController _labelController;
  late final TextEditingController _startTimeController;
  late final TextEditingController _endTimeController;
  late String _entryType;
  late bool _isOvernight;

  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    final entry = widget.initialEntry;
    final now = DateTime.now();

    _dateController = TextEditingController(
      text: entry?.date ?? DateFormat('yyyy-MM-dd').format(now),
    );
    _labelController = TextEditingController(
      text: entry?.shiftLabel ?? 'Early Shift',
    );
    _startTimeController = TextEditingController(
      text: entry?.startTime ?? '08:00',
    );
    _endTimeController = TextEditingController(
      text: entry?.endTime ?? '16:00',
    );
    _entryType = entry?.entryType ?? 'work';
    _isOvernight = entry?.isOvernight ?? false;
  }

  @override
  void dispose() {
    _dateController.dispose();
    _labelController.dispose();
    _startTimeController.dispose();
    _endTimeController.dispose();
    super.dispose();
  }

  Future<void> _selectDate() async {
    AppHaptics.light();
    DateTime current;
    try {
      current = DateFormat('yyyy-MM-dd').parse(_dateController.text);
    } catch (_) {
      current = DateTime.now();
    }

    final picked = await showDatePicker(
      context: context,
      initialDate: current,
      firstDate: DateTime(2020),
      lastDate: DateTime(2035),
    );

    if (picked != null) {
      setState(() {
        _dateController.text = DateFormat('yyyy-MM-dd').format(picked);
      });
    }
  }

  Future<void> _selectTime(TextEditingController controller) async {
    AppHaptics.light();
    TimeOfDay initial = const TimeOfDay(hour: 8, minute: 0);
    try {
      final parts = controller.text.split(':');
      if (parts.length == 2) {
        initial = TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1]));
      }
    } catch (_) {}

    final picked = await showTimePicker(
      context: context,
      initialTime: initial,
    );

    if (picked != null) {
      final formatted =
          '${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}';
      setState(() {
        controller.text = formatted;
        // Auto-check overnight if end is before start
        if (controller == _endTimeController) {
          final start = _startTimeController.text;
          if (formatted.compareTo(start) < 0) {
            _isOvernight = true;
          }
        }
      });
    }
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;

    AppHaptics.selection();
    final updated = ImportPreviewEntry(
      date: _dateController.text.trim(),
      shiftLabel: _labelController.text.trim(),
      label: _labelController.text.trim(),
      startTime: _startTimeController.text.trim(),
      endTime: _endTimeController.text.trim(),
      entryType: _entryType,
      isOvernight: _isOvernight,
    );

    Navigator.of(context).pop(updated);
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      margin: EdgeInsets.only(bottom: bottomInset),
      child: Material(
        color: AppColors.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        clipBehavior: Clip.antiAlias,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
          child: SafeArea(
            top: false,
            child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      widget.isNew ? 'Add Missing Shift' : 'Edit Extracted Shift',
                      style: AppTextStyles.titleMedium,
                    ),
                    IconButton(
                      icon: const Icon(LucideIcons.x, size: 20),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Date Field
                InkWell(
                  onTap: _selectDate,
                  child: IgnorePointer(
                    child: AppTextField(
                      controller: _dateController,
                      label: 'Date (YYYY-MM-DD)',
                      prefixIcon: LucideIcons.calendar,
                      validator: (v) {
                        if (v == null || !RegExp(r'^\d{4}-\d{2}-\d{2}$').hasMatch(v)) {
                          return 'Enter valid date (YYYY-MM-DD)';
                        }
                        return null;
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 12),

                // Shift Label
                AppTextField(
                  controller: _labelController,
                  label: 'Shift Name / Label',
                  hint: 'e.g. Day Shift, ICU Night, Off',
                  prefixIcon: LucideIcons.tag,
                  validator: (v) =>
                      v == null || v.trim().isEmpty ? 'Shift name is required' : null,
                ),
                const SizedBox(height: 12),

                // Start & End Time Pickers
                Row(
                  children: [
                    Expanded(
                      child: InkWell(
                        onTap: () => _selectTime(_startTimeController),
                        child: IgnorePointer(
                          child: AppTextField(
                            controller: _startTimeController,
                            label: 'Start Time',
                            prefixIcon: LucideIcons.clock,
                            validator: (v) {
                              if (v == null || !RegExp(r'^\d{2}:\d{2}$').hasMatch(v)) {
                                return 'HH:MM';
                              }
                              return null;
                            },
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: InkWell(
                        onTap: () => _selectTime(_endTimeController),
                        child: IgnorePointer(
                          child: AppTextField(
                            controller: _endTimeController,
                            label: 'End Time',
                            prefixIcon: LucideIcons.clock,
                            validator: (v) {
                              if (v == null || !RegExp(r'^\d{2}:\d{2}$').hasMatch(v)) {
                                return 'HH:MM';
                              }
                              return null;
                            },
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),

                // Entry Type Segment
                const Text(
                  'Entry Type',
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                ),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: ['work', 'leave', 'off', 'personal', 'other'].map((type) {
                    final selected = _entryType == type;
                    return ChoiceChip(
                      label: Text(type.toUpperCase()),
                      selected: selected,
                      selectedColor: AppColors.primaryLight,
                      labelStyle: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: selected ? AppColors.primaryDark : AppColors.textMuted,
                      ),
                      onSelected: (val) {
                        if (val) {
                          AppHaptics.light();
                          setState(() {
                            _entryType = type;
                            if (type == 'off') {
                              _labelController.text = 'Day Off';
                            }
                          });
                        }
                      },
                    );
                  }).toList(),
                ),
                const SizedBox(height: 14),

                // Overnight switch
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text(
                    'Overnight Shift',
                    style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                  ),
                  subtitle: const Text(
                    'Ends on the following calendar day',
                    style: TextStyle(fontSize: 11, color: AppColors.textMuted),
                  ),
                  value: _isOvernight,
                  activeThumbColor: AppColors.primary,
                  onChanged: (val) {
                    AppHaptics.light();
                    setState(() => _isOvernight = val);
                  },
                ),
                const SizedBox(height: 18),

                // Save Button
                AppButton(
                  text: widget.isNew ? 'Add to Batch' : 'Save Changes',
                  icon: LucideIcons.check,
                  onPressed: _save,
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  ),
);
  }
}
