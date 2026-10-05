import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/text_styles.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../../../shared/widgets/app_text_field.dart';
import '../../providers/schedule_notifier.dart';

class CreateTemplateSheet extends ConsumerStatefulWidget {
  const CreateTemplateSheet({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const CreateTemplateSheet(),
    );
  }

  @override
  ConsumerState<CreateTemplateSheet> createState() => _CreateTemplateSheetState();
}

class _CreateTemplateSheetState extends ConsumerState<CreateTemplateSheet> {
  final _nameController = TextEditingController();
  final _startTimeController = TextEditingController(text: '08:00');
  final _endTimeController = TextEditingController(text: '16:00');
  bool _isOvernight = false;
  String _selectedColor = '#3B82F6';
  bool _isSaving = false;
  String? _errorMessage;

  final List<String> _presetColors = [
    '#3B82F6', // Blue
    '#8B5CF6', // Purple
    '#10B981', // Emerald
    '#F59E0B', // Amber
    '#EF4444', // Red
    '#EC4899', // Pink
    '#2B7A72', // Teal
  ];

  @override
  void dispose() {
    _nameController.dispose();
    _startTimeController.dispose();
    _endTimeController.dispose();
    super.dispose();
  }

  Future<void> _handleSave() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      setState(() => _errorMessage = 'Please enter a template name');
      return;
    }

    setState(() {
      _isSaving = true;
      _errorMessage = null;
    });

    try {
      await ref.read(scheduleNotifierProvider.notifier).createTemplate(
            name: name,
            startTime: _startTimeController.text.trim(),
            endTime: _endTimeController.text.trim(),
            isOvernight: _isOvernight,
            color: _selectedColor,
          );
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        setState(() {
          _isSaving = false;
          _errorMessage = e.toString().replaceFirst('Exception: ', '');
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Row(
                  children: [
                    Icon(LucideIcons.plusCircle, color: AppColors.primary, size: 20),
                    SizedBox(width: 8),
                    Text('New Shift Template', style: AppTextStyles.titleMedium),
                  ],
                ),
                IconButton(
                  icon: const Icon(LucideIcons.x, size: 20),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: 14),
            if (_errorMessage != null) ...[
              Text(
                _errorMessage!,
                style: const TextStyle(color: AppColors.danger, fontSize: 12),
              ),
              const SizedBox(height: 10),
            ],
            AppTextField(
              controller: _nameController,
              label: 'Template Name',
              hint: 'e.g. Day Shift, ICU, Flight',
              prefixIcon: LucideIcons.tag,
            ),
            const SizedBox(height: 14),
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
            const SizedBox(height: 14),
            Row(
              children: [
                Checkbox(
                  value: _isOvernight,
                  activeColor: AppColors.primary,
                  onChanged: (val) {
                    setState(() => _isOvernight = val ?? false);
                  },
                ),
                const Text(
                  'Spans past midnight (Overnight shift)',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                ),
              ],
            ),
            const SizedBox(height: 14),
            const Text(
              'Color Preset',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: _presetColors.map((colorHex) {
                final isSelected = _selectedColor == colorHex;
                final color = Color(int.parse('FF${colorHex.replaceAll('#', '')}', radix: 16));
                return GestureDetector(
                  onTap: () => setState(() => _selectedColor = colorHex),
                  child: Container(
                    width: 34,
                    height: 34,
                    decoration: BoxDecoration(
                      color: color,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: isSelected ? AppColors.textPrimary : Colors.transparent,
                        width: 2.5,
                      ),
                      boxShadow: isSelected
                          ? [
                              BoxShadow(
                                color: color.withValues(alpha: 0.4),
                                blurRadius: 6,
                                offset: const Offset(0, 2),
                              )
                            ]
                          : null,
                    ),
                    child: isSelected
                        ? const Icon(LucideIcons.check, size: 16, color: Colors.white)
                        : null,
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 24),
            AppButton(
              text: 'Create Template',
              isLoading: _isSaving,
              onPressed: _handleSave,
            ),
          ],
        ),
      ),
    );
  }
}
