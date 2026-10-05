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

class JoinCircleModal extends ConsumerStatefulWidget {
  const JoinCircleModal({super.key});

  static Future<CircleModel?> show(BuildContext context) {
    AppHaptics.selection();
    return showModalBottomSheet<CircleModel>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const JoinCircleModal(),
    );
  }

  @override
  ConsumerState<JoinCircleModal> createState() => _JoinCircleModalState();
}

class _JoinCircleModalState extends ConsumerState<JoinCircleModal> {
  final _formKey = GlobalKey<FormState>();
  final _codeController = TextEditingController();

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    AppHaptics.selection();
    final notifier = ref.read(circlesNotifierProvider.notifier);

    final circle = await notifier.joinCircle(_codeController.text.trim());

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
                            Icon(LucideIcons.link, color: AppColors.primary, size: 20),
                            SizedBox(width: 8),
                            Text('Join a Circle', style: AppTextStyles.titleMedium),
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
                      'Enter the 6-character invite code provided by your colleague or circle owner.',
                      style: AppTextStyles.bodySmall.copyWith(color: AppColors.textMuted),
                    ),
                    const SizedBox(height: 18),

                    // Error notice if join failed
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

                    // Invite Code
                    AppTextField(
                      controller: _codeController,
                      label: 'Invite Code',
                      hint: 'e.g. ABC123',
                      prefixIcon: LucideIcons.keyRound,
                      autofocus: true,
                      validator: (value) {
                        if (value == null || value.trim().length < 4) {
                          return 'Please enter a valid invite code';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 22),

                    // Submit Button
                    AppButton(
                      text: 'Join Circle',
                      icon: LucideIcons.userPlus,
                      isLoading: state.isJoining,
                      onPressed: state.isJoining ? null : _submit,
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
