import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/text_styles.dart';
import '../../../../core/utils/haptic_feedback.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../../../shared/widgets/app_text_field.dart';
import '../../models/circle_model.dart';
import '../../providers/circles_notifier.dart';

class CreateCircleModal extends ConsumerStatefulWidget {
  const CreateCircleModal({super.key});

  static Future<CircleModel?> show(BuildContext context) {
    AppHaptics.selection();
    return showModalBottomSheet<CircleModel>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const CreateCircleModal(),
    );
  }

  @override
  ConsumerState<CreateCircleModal> createState() => _CreateCircleModalState();
}

class _CreateCircleModalState extends ConsumerState<CreateCircleModal> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _handleController = TextEditingController();
  String _discoverability = 'private';

  @override
  void dispose() {
    _nameController.dispose();
    _handleController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    AppHaptics.selection();
    final notifier = ref.read(circlesNotifierProvider.notifier);

    final cleanHandle = _handleController.text.trim().replaceAll('@', '');
    final circle = await notifier.createCircle(
      name: _nameController.text.trim(),
      handle: cleanHandle.isNotEmpty ? cleanHandle : null,
      discoverability: _discoverability,
    );

    if (circle != null && mounted) {
      AppHaptics.heavy();
      Navigator.of(context).pop(circle);
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(circlesNotifierProvider);
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
                        const Row(
                          children: [
                            Icon(LucideIcons.users, color: AppColors.primary, size: 20),
                            SizedBox(width: 8),
                            Text('Create New Circle', style: AppTextStyles.titleMedium),
                          ],
                        ),
                        IconButton(
                          icon: const Icon(LucideIcons.x, size: 20),
                          onPressed: () => Navigator.of(context).pop(),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Set up a shared roster for your work team, department, or friend group.',
                      style: AppTextStyles.bodySmall.copyWith(color: AppColors.textMuted),
                    ),
                    const SizedBox(height: 18),

                    // Error notice if creation failed
                    if (state.errorMessage != null) ...[
                      Container(
                        margin: const EdgeInsets.only(bottom: 14),
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: AppColors.dangerBg,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: AppColors.dangerBorder),
                        ),
                        child: Text(
                          state.errorMessage!,
                          style: const TextStyle(fontSize: 12, color: AppColors.danger),
                        ),
                      ),
                    ],

                    // Circle Name
                    AppTextField(
                      controller: _nameController,
                      label: 'Circle Name',
                      hint: 'e.g. ICU Shift Crew, Aviation Team',
                      prefixIcon: LucideIcons.building,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Please enter a circle name';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 14),

                    // Handle / Tag
                    AppTextField(
                      controller: _handleController,
                      label: 'Unique Handle (Optional)',
                      hint: 'e.g. icu-crew',
                      prefixIcon: LucideIcons.atSign,
                    ),
                    const SizedBox(height: 16),

                    // Discoverability selector
                    const Text(
                      'Discoverability',
                      style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: ChoiceChip(
                            label: const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(LucideIcons.lock, size: 14),
                                SizedBox(width: 6),
                                Text('Private'),
                              ],
                            ),
                            selected: _discoverability == 'private',
                            selectedColor: AppColors.primaryLight.withValues(alpha: 0.5),
                            labelStyle: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: _discoverability == 'private'
                                  ? AppColors.primaryDark
                                  : AppColors.textMuted,
                            ),
                            onSelected: (val) {
                              if (val) {
                                AppHaptics.light();
                                setState(() => _discoverability = 'private');
                              }
                            },
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: ChoiceChip(
                            label: const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(LucideIcons.globe, size: 14),
                                SizedBox(width: 6),
                                Text('Searchable'),
                              ],
                            ),
                            selected: _discoverability == 'searchable',
                            selectedColor: AppColors.primaryLight.withValues(alpha: 0.5),
                            labelStyle: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: _discoverability == 'searchable'
                                  ? AppColors.primaryDark
                                  : AppColors.textMuted,
                            ),
                            onSelected: (val) {
                              if (val) {
                                AppHaptics.light();
                                setState(() => _discoverability = 'searchable');
                              }
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      _discoverability == 'private'
                          ? 'Only people invited with an invite link/code can find and join.'
                          : 'Anyone can discover this circle by searching its name or handle.',
                      style: const TextStyle(fontSize: 11, color: AppColors.textSubtle),
                    ),
                    const SizedBox(height: 22),

                    // Submit Button
                    AppButton(
                      text: 'Create Circle',
                      icon: LucideIcons.plus,
                      isLoading: state.isCreating,
                      onPressed: state.isCreating ? null : _submit,
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
