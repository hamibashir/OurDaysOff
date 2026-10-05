import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:share_plus/share_plus.dart';

import '../../../../core/network/error_handler.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/text_styles.dart';
import '../../../../core/utils/haptic_feedback.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../data/circle_repository.dart';
import '../../models/circle_invite.dart';

class CircleInviteModal extends ConsumerStatefulWidget {
  final int circleId;
  final String circleName;

  const CircleInviteModal({
    super.key,
    required this.circleId,
    required this.circleName,
  });

  static Future<void> show({
    required BuildContext context,
    required int circleId,
    required String circleName,
  }) {
    AppHaptics.medium();
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => CircleInviteModal(
        circleId: circleId,
        circleName: circleName,
      ),
    );
  }

  @override
  ConsumerState<CircleInviteModal> createState() => _CircleInviteModalState();
}

class _CircleInviteModalState extends ConsumerState<CircleInviteModal> {
  CircleInvite? _invite;
  bool _isLoading = false;
  bool _copiedCode = false;
  bool _copiedUrl = false;
  String? _errorMessage;

  Future<void> _generateInvite() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final repo = ref.read(circleRepositoryProvider);
      final invite = await repo.createInvite(circleId: widget.circleId);
      if (mounted) {
        setState(() {
          _invite = invite;
          _isLoading = false;
        });
        AppHaptics.medium();
      }
    } on AppException catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.message;
          _isLoading = false;
        });
        AppHaptics.heavy();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Failed to generate code: ${e.toString()}';
          _isLoading = false;
        });
        AppHaptics.heavy();
      }
    }
  }

  void _copyToClipboard(String text, bool isCode) {
    Clipboard.setData(ClipboardData(text: text));
    AppHaptics.light();
    setState(() {
      if (isCode) {
        _copiedCode = true;
      } else {
        _copiedUrl = true;
      }
    });

    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        setState(() {
          if (isCode) {
            _copiedCode = false;
          } else {
            _copiedUrl = false;
          }
        });
      }
    });
  }

  void _shareInvite() {
    if (_invite == null) return;
    AppHaptics.medium();
    final message =
        'Join "${widget.circleName}" on Our Days Off!\nUse invite code: ${_invite!.inviteCode}\nOr tap: ${_invite!.inviteUrl}';
    Share.share(message, subject: 'Invite to ${widget.circleName}');
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 28,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Drag handle
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
          const SizedBox(height: 16),

          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(LucideIcons.keyRound, size: 20, color: AppColors.primary),
                  const SizedBox(width: 8),
                  Text(
                    'Invite Members',
                    style: AppTextStyles.titleMedium.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              IconButton(
                icon: const Icon(LucideIcons.x, size: 20, color: AppColors.textMuted),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          ),
          const SizedBox(height: 8),
          const Divider(height: 1, color: AppColors.borderLight),
          const SizedBox(height: 16),

          if (_errorMessage != null) ...[
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.dangerBg,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.dangerBorder),
              ),
              child: Row(
                children: [
                  const Icon(LucideIcons.alertCircle, size: 16, color: AppColors.danger),
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
            const SizedBox(height: 16),
          ],

          if (_invite == null) ...[
            Text(
              'Generate a 6-character join code or link for your crew members to join "${widget.circleName}".',
              textAlign: TextAlign.center,
              style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textMuted),
            ),
            const SizedBox(height: 24),
            AppButton(
              text: 'Generate Invite Code & Link',
              icon: LucideIcons.sparkles,
              isLoading: _isLoading,
              onPressed: _isLoading ? null : _generateInvite,
            ),
          ] else ...[
            // 6-Character Join Code
            const Text(
              '6-CHARACTER JOIN CODE',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.5,
                color: AppColors.textMuted,
              ),
            ),
            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: AppColors.scaffoldBackground,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.border),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      _invite!.inviteCode,
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 6,
                        fontFamily: 'monospace',
                        color: AppColors.primaryDark,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: Icon(
                      _copiedCode ? LucideIcons.check : LucideIcons.copy,
                      color: _copiedCode ? AppColors.statusAvailable : AppColors.primary,
                      size: 20,
                    ),
                    tooltip: 'Copy Code',
                    onPressed: () => _copyToClipboard(_invite!.inviteCode, true),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Shareable Direct Link
            const Text(
              'SHAREABLE DIRECT LINK',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.5,
                color: AppColors.textMuted,
              ),
            ),
            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.scaffoldBackground,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.border),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      _invite!.inviteUrl,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 12,
                        fontFamily: 'monospace',
                        color: AppColors.textMuted,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: Icon(
                      _copiedUrl ? LucideIcons.check : LucideIcons.link,
                      color: _copiedUrl ? AppColors.statusAvailable : AppColors.primary,
                      size: 18,
                    ),
                    tooltip: 'Copy Link',
                    onPressed: () => _copyToClipboard(_invite!.inviteUrl, false),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Native Share Button
            AppButton(
              text: 'Share Invite...',
              icon: LucideIcons.share2,
              onPressed: _shareInvite,
            ),

            const SizedBox(height: 12),

            // Expiration Advisory
            const Text(
              'This code expires in 7 days. Anyone with this code can join your circle.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 11,
                color: AppColors.textSubtle,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
