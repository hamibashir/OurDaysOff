import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/text_styles.dart';
import '../../../../core/utils/haptic_feedback.dart';
import '../../../circles/models/circle_model.dart';
import '../../../circles/providers/circles_notifier.dart';
import '../../data/plan_repository.dart';
import '../../models/plan_model.dart';
import '../../providers/plan_providers.dart';

class CreatePlanBottomSheet extends ConsumerStatefulWidget {
  final List<CircleModel>? circles;
  final int? initialCircleId;
  final String? initialDate; // 'yyyy-MM-dd'
  final String? initialStart; // 'HH:mm'
  final String? initialEnd; // 'HH:mm'
  final ValueChanged<PlanModel>? onPlanCreated;

  const CreatePlanBottomSheet({
    super.key,
    this.circles,
    this.initialCircleId,
    this.initialDate,
    this.initialStart,
    this.initialEnd,
    this.onPlanCreated,
  });

  static Future<PlanModel?> show(
    BuildContext context, {
    List<CircleModel>? circles,
    int? initialCircleId,
    String? initialDate,
    String? initialStart,
    String? initialEnd,
  }) {
    return showModalBottomSheet<PlanModel>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(ctx).viewInsets.bottom,
        ),
        child: CreatePlanBottomSheet(
          circles: circles,
          initialCircleId: initialCircleId,
          initialDate: initialDate,
          initialStart: initialStart,
          initialEnd: initialEnd,
        ),
      ),
    );
  }

  @override
  ConsumerState<CreatePlanBottomSheet> createState() => _CreatePlanBottomSheetState();
}

class _CreatePlanBottomSheetState extends ConsumerState<CreatePlanBottomSheet> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descController = TextEditingController();

  int? _selectedCircleId;
  String _eventType = 'social';
  bool _isPolling = false;

  late DateTime _selectedDate;
  late TimeOfDay _startTime;
  late TimeOfDay _endTime;

  bool _isSubmitting = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _selectedCircleId = widget.initialCircleId;

    // Parse initial date
    if (widget.initialDate != null && widget.initialDate!.isNotEmpty) {
      _selectedDate = DateTime.tryParse(widget.initialDate!) ?? DateTime.now();
    } else {
      _selectedDate = DateTime.now().add(const Duration(days: 1));
    }

    // Parse initial start time
    if (widget.initialStart != null && widget.initialStart!.contains(':')) {
      final parts = widget.initialStart!.split(':');
      _startTime = TimeOfDay(
        hour: int.tryParse(parts[0]) ?? 18,
        minute: int.tryParse(parts[1]) ?? 0,
      );
    } else {
      _startTime = const TimeOfDay(hour: 18, minute: 0);
    }

    // Parse initial end time
    if (widget.initialEnd != null && widget.initialEnd!.contains(':')) {
      final parts = widget.initialEnd!.split(':');
      _endTime = TimeOfDay(
        hour: int.tryParse(parts[0]) ?? 21,
        minute: int.tryParse(parts[1]) ?? 0,
      );
    } else {
      _endTime = const TimeOfDay(hour: 21, minute: 0);
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    AppHaptics.light();
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now().subtract(const Duration(days: 1)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) {
      setState(() => _selectedDate = picked);
    }
  }

  Future<void> _pickStartTime() async {
    AppHaptics.light();
    final picked = await showTimePicker(
      context: context,
      initialTime: _startTime,
    );
    if (picked != null) {
      setState(() => _startTime = picked);
    }
  }

  Future<void> _pickEndTime() async {
    AppHaptics.light();
    final picked = await showTimePicker(
      context: context,
      initialTime: _endTime,
    );
    if (picked != null) {
      setState(() => _endTime = picked);
    }
  }

  DateTime _combineDateAndTime(DateTime date, TimeOfDay time) {
    return DateTime(date.year, date.month, date.day, time.hour, time.minute);
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedCircleId == null) {
      setState(() => _errorMessage = 'Please select a circle for this plan.');
      return;
    }

    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
    });

    try {
      DateTime? startAt;
      DateTime? endAt;

      if (!_isPolling) {
        startAt = _combineDateAndTime(_selectedDate, _startTime);
        endAt = _combineDateAndTime(_selectedDate, _endTime);

        if (endAt.isBefore(startAt)) {
          // If end time is before start time, assume next day
          endAt = endAt.add(const Duration(days: 1));
        }
      }

      final repo = ref.read(planRepositoryProvider);
      final newPlan = await repo.createPlan(
        circleId: _selectedCircleId!,
        title: _titleController.text.trim(),
        description: _descController.text.trim().isNotEmpty
            ? _descController.text.trim()
            : null,
        eventType: _eventType,
        startAt: startAt,
        endAt: endAt,
        status: _isPolling ? 'polling' : 'confirmed',
      );

      AppHaptics.medium();
      ref.read(plansListProvider.notifier).addPlan(newPlan);
      widget.onPlanCreated?.call(newPlan);

      if (mounted) {
        Navigator.of(context).pop(newPlan);
      }
    } catch (err) {
      setState(() {
        _errorMessage = err.toString().replaceFirst('Exception: ', '');
        _isSubmitting = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // Resolve circles list from widget or circlesNotifier
    final availableCircles = widget.circles ??
        ref.watch(circlesNotifierProvider).circles;

    if (_selectedCircleId == null && availableCircles.isNotEmpty) {
      _selectedCircleId = availableCircles.first.id;
    }

    final dateFormat = DateFormat('EEE, MMM d, yyyy');

    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Drag Handle
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

              // Title Bar
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Row(
                    children: [
                      Icon(LucideIcons.calendarCheck, size: 20, color: AppColors.primary),
                      SizedBox(width: 8),
                      Text(
                        'New Meetup Plan',
                        style: AppTextStyles.titleMedium,
                      ),
                    ],
                  ),
                  IconButton(
                    icon: const Icon(LucideIcons.x, size: 20, color: AppColors.textSubtle),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),

              const Divider(color: AppColors.borderLight),
              const SizedBox(height: 12),

              // Error banner if any
              if (_errorMessage != null) ...[
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: AppColors.dangerBg,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppColors.dangerBorder),
                  ),
                  child: Row(
                    children: [
                      const Icon(LucideIcons.alertCircle, size: 14, color: AppColors.danger),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _errorMessage!,
                          style: const TextStyle(fontSize: 12, color: AppColors.danger),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
              ],

              // Target Circle Selector
              const Text(
                'TARGET CIRCLE',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.5,
                  color: AppColors.textMuted,
                ),
              ),
              const SizedBox(height: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  color: AppColors.scaffoldBackground,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.border),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<int>(
                    isExpanded: true,
                    value: _selectedCircleId,
                    hint: const Text('Select a Circle', style: TextStyle(fontSize: 13)),
                    items: availableCircles.map((circle) {
                      return DropdownMenuItem<int>(
                        value: circle.id,
                        child: Text(
                          circle.name,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      );
                    }).toList(),
                    onChanged: (id) {
                      if (id != null) {
                        setState(() => _selectedCircleId = id);
                      }
                    },
                  ),
                ),
              ),

              const SizedBox(height: 14),

              // Plan Title Field
              const Text(
                'TITLE',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.5,
                  color: AppColors.textMuted,
                ),
              ),
              const SizedBox(height: 6),
              TextFormField(
                controller: _titleController,
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                decoration: InputDecoration(
                  hintText: 'e.g. Dinner & Drinks, Weekend Hike',
                  hintStyle: const TextStyle(fontSize: 13, color: AppColors.textSubtle),
                  filled: true,
                  fillColor: AppColors.scaffoldBackground,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: AppColors.border),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: AppColors.border),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                ),
                validator: (val) {
                  if (val == null || val.trim().isEmpty) {
                    return 'Title is required';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 14),

              // Event Type Chips
              const Text(
                'EVENT TYPE',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.5,
                  color: AppColors.textMuted,
                ),
              ),
              const SizedBox(height: 6),
              Row(
                children: [
                  _buildEventTypeChip('meal', 'Meal', LucideIcons.utensils),
                  const SizedBox(width: 8),
                  _buildEventTypeChip('social', 'Social', LucideIcons.sparkles),
                  const SizedBox(width: 8),
                  _buildEventTypeChip('travel', 'Travel', LucideIcons.plane),
                  const SizedBox(width: 8),
                  _buildEventTypeChip('other', 'Other', LucideIcons.calendar),
                ],
              ),

              const SizedBox(height: 14),

              // Polling / Date TBD Switch
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: AppColors.scaffoldBackground,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.border),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Row(
                      children: [
                        Icon(LucideIcons.vote, size: 16, color: AppColors.primary),
                        SizedBox(width: 8),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Date TBD (Polling Mode)',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            Text(
                              'Let members vote on dates & times',
                              style: TextStyle(fontSize: 11, color: AppColors.textMuted),
                            ),
                          ],
                        ),
                      ],
                    ),
                    Switch.adaptive(
                      value: _isPolling,
                      activeTrackColor: AppColors.primary,
                      onChanged: (val) {
                        AppHaptics.selection();
                        setState(() => _isPolling = val);
                      },
                    ),
                  ],
                ),
              ),

              if (!_isPolling) ...[
                const SizedBox(height: 14),

                // Date Picker Row
                const Text(
                  'DATE',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.5,
                    color: AppColors.textMuted,
                  ),
                ),
                const SizedBox(height: 6),
                InkWell(
                  onTap: _pickDate,
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    decoration: BoxDecoration(
                      color: AppColors.scaffoldBackground,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Row(
                      children: [
                        const Icon(LucideIcons.calendar, size: 16, color: AppColors.primary),
                        const SizedBox(width: 10),
                        Text(
                          dateFormat.format(_selectedDate),
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const Spacer(),
                        const Text(
                          'Change',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: AppColors.primary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 14),

                // Start & End Time Pickers
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'START TIME',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.5,
                              color: AppColors.textMuted,
                            ),
                          ),
                          const SizedBox(height: 6),
                          InkWell(
                            onTap: _pickStartTime,
                            borderRadius: BorderRadius.circular(12),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                              decoration: BoxDecoration(
                                color: AppColors.scaffoldBackground,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: AppColors.border),
                              ),
                              child: Row(
                                children: [
                                  const Icon(LucideIcons.clock, size: 15, color: AppColors.primary),
                                  const SizedBox(width: 6),
                                  Text(
                                    _startTime.format(context),
                                    style: const TextStyle(
                                      fontSize: 13,
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
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'END TIME',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.5,
                              color: AppColors.textMuted,
                            ),
                          ),
                          const SizedBox(height: 6),
                          InkWell(
                            onTap: _pickEndTime,
                            borderRadius: BorderRadius.circular(12),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                              decoration: BoxDecoration(
                                color: AppColors.scaffoldBackground,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: AppColors.border),
                              ),
                              child: Row(
                                children: [
                                  const Icon(LucideIcons.clock, size: 15, color: AppColors.primary),
                                  const SizedBox(width: 6),
                                  Text(
                                    _endTime.format(context),
                                    style: const TextStyle(
                                      fontSize: 13,
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
              ],

              const SizedBox(height: 14),

              // Description Field
              const Text(
                'DESCRIPTION (OPTIONAL)',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.5,
                  color: AppColors.textMuted,
                ),
              ),
              const SizedBox(height: 6),
              TextFormField(
                controller: _descController,
                maxLines: 2,
                style: const TextStyle(fontSize: 13),
                decoration: InputDecoration(
                  hintText: 'Add details, location suggestions, or agenda...',
                  hintStyle: const TextStyle(fontSize: 12, color: AppColors.textSubtle),
                  filled: true,
                  fillColor: AppColors.scaffoldBackground,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: AppColors.border),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: AppColors.border),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
                  ),
                  contentPadding: const EdgeInsets.all(12),
                ),
              ),

              const SizedBox(height: 20),

              // Submit Button
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: _isSubmitting ? null : _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                  child: _isSubmitting
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : const Text(
                          'Create Meetup Plan',
                          style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEventTypeChip(String type, String label, IconData icon) {
    final isSelected = _eventType == type;

    return Expanded(
      child: InkWell(
        onTap: () {
          AppHaptics.selection();
          setState(() => _eventType = type);
        },
        borderRadius: BorderRadius.circular(10),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.primarySurface : AppColors.scaffoldBackground,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: isSelected ? AppColors.primary : AppColors.border,
              width: isSelected ? 1.5 : 1.0,
            ),
          ),
          child: Column(
            children: [
              Icon(
                icon,
                size: 16,
                color: isSelected ? AppColors.primaryDark : AppColors.textMuted,
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                  color: isSelected ? AppColors.primaryDark : AppColors.textMuted,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
