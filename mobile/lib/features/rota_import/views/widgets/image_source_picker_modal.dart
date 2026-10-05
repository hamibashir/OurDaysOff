import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/text_styles.dart';
import '../../../../core/utils/haptic_feedback.dart';
import '../../models/picked_rota_file.dart';
import '../../services/media_picker_service.dart';

class ImageSourcePickerModal extends StatelessWidget {
  final MediaPickerService mediaPicker;

  const ImageSourcePickerModal({
    super.key,
    required this.mediaPicker,
  });

  static Future<PickedRotaFile?> show(
    BuildContext context, {
    required MediaPickerService mediaPicker,
  }) {
    AppHaptics.selection();
    return showModalBottomSheet<PickedRotaFile>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => ImageSourcePickerModal(mediaPicker: mediaPicker),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        decoration: const BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Row(
                children: [
                  Icon(LucideIcons.scanLine, color: AppColors.primary, size: 20),
                  SizedBox(width: 8),
                  Text('Import Rota & Shifts', style: AppTextStyles.titleMedium),
                ],
              ),
              IconButton(
                icon: const Icon(LucideIcons.x, size: 20),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            'Select how you want to upload your physical roster or rota document for AI parsing.',
            style: AppTextStyles.bodySmall.copyWith(color: AppColors.textMuted),
          ),
          const SizedBox(height: 20),

          // Option 1: Take Photo with Camera
          _PickerOptionTile(
            icon: LucideIcons.camera,
            iconBg: const Color(0xFFEFF6FF),
            iconColor: AppColors.statusBusy,
            title: 'Take Photo of Rota',
            subtitle: 'Capture physical printed paper or wall schedule',
            onTap: () async {
              final file = await mediaPicker.pickFromCamera();
              if (context.mounted) {
                Navigator.pop(context, file);
              }
            },
          ),
          const SizedBox(height: 10),

          // Option 2: Choose from Photos
          _PickerOptionTile(
            icon: LucideIcons.image,
            iconBg: AppColors.statusAvailableBg,
            iconColor: AppColors.statusAvailable,
            title: 'Choose from Photo Library',
            subtitle: 'Select existing photo or screenshot of rota',
            onTap: () async {
              final file = await mediaPicker.pickFromGallery();
              if (context.mounted) {
                Navigator.pop(context, file);
              }
            },
          ),
          const SizedBox(height: 10),

          // Option 3: Choose PDF / Document
          _PickerOptionTile(
            icon: LucideIcons.fileText,
            iconBg: const Color(0xFFF5F3FF),
            iconColor: AppColors.statusOvernight,
            title: 'Upload PDF Document',
            subtitle: 'Select digital PDF rota from workplace portal',
            onTap: () async {
              final file = await mediaPicker.pickDocument();
              if (context.mounted) {
                Navigator.pop(context, file);
              }
            },
          ),
          const SizedBox(height: 12),
        ],
          ),
        ),
      ),
    );
  }
}

class _PickerOptionTile extends StatelessWidget {
  final IconData icon;
  final Color iconBg;
  final Color iconColor;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _PickerOptionTile({
    required this.icon,
    required this.iconBg,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {
        AppHaptics.light();
        onTap();
      },
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: AppColors.scaffoldBackground,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: iconBg,
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: iconColor, size: 20),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textMuted,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(LucideIcons.chevronRight, size: 18, color: AppColors.textSubtle),
          ],
        ),
      ),
    );
  }
}
