import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/text_styles.dart';
import '../../../core/utils/haptic_feedback.dart';
import '../../../shared/widgets/app_button.dart';
import '../../../shared/widgets/app_text_field.dart';
import '../../../shared/widgets/confirmation_dialog.dart';
import '../../../shared/widgets/status_badge.dart';
import '../../auth/models/user_model.dart';
import '../../auth/providers/auth_notifier.dart';
import '../providers/profile_notifier.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  final _couponController = TextEditingController();

  @override
  void dispose() {
    _couponController.dispose();
    super.dispose();
  }

  void _showEditProfileDialog(UserModel user) {
    final nameController = TextEditingController(text: user.name);
    String selectedVisibility = user.handleVisibility ?? 'public';
    bool isSaving = false;
    String? dialogError;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => StatefulBuilder(
        builder: (context, setSheetState) => Padding(
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
                    const Text('Edit Profile', style: AppTextStyles.titleMedium),
                    IconButton(
                      icon: const Icon(LucideIcons.x, size: 20),
                      onPressed: () => Navigator.pop(sheetContext),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                if (dialogError != null) ...[
                  Text(
                    dialogError!,
                    style: const TextStyle(color: AppColors.danger, fontSize: 12),
                  ),
                  const SizedBox(height: 8),
                ],
                AppTextField(
                  controller: nameController,
                  label: 'Full Name',
                  hint: 'Your display name',
                  prefixIcon: LucideIcons.user,
                ),
                const SizedBox(height: 16),
                const Text(
                  'Handle Visibility',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  decoration: BoxDecoration(
                    color: AppColors.scaffoldBackground,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: selectedVisibility,
                      isExpanded: true,
                      items: const [
                        DropdownMenuItem(
                          value: 'public',
                          child: Text('Public (Anyone can search you)'),
                        ),
                        DropdownMenuItem(
                          value: 'circles_only',
                          child: Text('Circles Only (Only circle members)'),
                        ),
                        DropdownMenuItem(
                          value: 'private',
                          child: Text('Private (Hidden from searches)'),
                        ),
                      ],
                      onChanged: (val) {
                        if (val != null) {
                          setSheetState(() => selectedVisibility = val);
                        }
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                AppButton(
                  text: 'Save Changes',
                  isLoading: isSaving,
                  onPressed: () async {
                    if (nameController.text.trim().isEmpty) {
                      setSheetState(() => dialogError = 'Name cannot be empty');
                      return;
                    }
                    setSheetState(() => isSaving = true);
                    try {
                      await ref.read(profileNotifierProvider).updateProfile(
                            name: nameController.text.trim(),
                            handleVisibility: selectedVisibility,
                          );
                      if (sheetContext.mounted) {
                        Navigator.pop(sheetContext);
                      }
                    } catch (e) {
                      if (sheetContext.mounted) {
                        setSheetState(() {
                          isSaving = false;
                          dialogError = e.toString().replaceFirst('Exception: ', '');
                        });
                      }
                    }
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showRedeemCouponDialog() {
    _couponController.clear();
    final messenger = ScaffoldMessenger.of(context);
    bool isRedeeming = false;
    String? redeemError;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => StatefulBuilder(
        builder: (ctx, setSheetState) => Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(ctx).viewInsets.bottom,
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
                        Icon(LucideIcons.sparkles, color: Color(0xFFD97706), size: 20),
                        SizedBox(width: 8),
                        Text('Redeem VIP Promo Code', style: AppTextStyles.titleMedium),
                      ],
                    ),
                    IconButton(
                      icon: const Icon(LucideIcons.x, size: 20),
                      onPressed: () => Navigator.pop(sheetContext),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'Enter your invitation promo or VIP coupon code to unlock AI Vision Rota Scanning and unlimited circles.',
                  style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textMuted),
                ),
                const SizedBox(height: 16),
                if (redeemError != null) ...[
                  Text(
                    redeemError!,
                    style: const TextStyle(color: AppColors.danger, fontSize: 12),
                  ),
                  const SizedBox(height: 8),
                ],
                AppTextField(
                  controller: _couponController,
                  label: 'Coupon Code',
                  hint: 'e.g. VIP2026',
                  prefixIcon: LucideIcons.tag,
                ),
                const SizedBox(height: 20),
                AppButton(
                  text: 'Redeem Code',
                  isLoading: isRedeeming,
                  onPressed: () async {
                    final code = _couponController.text.trim();
                    if (code.isEmpty) {
                      setSheetState(() => redeemError = 'Please enter a code');
                      return;
                    }
                    setSheetState(() => isRedeeming = true);
                    try {
                      await ref.read(profileNotifierProvider).redeemCoupon(code);
                      if (sheetContext.mounted) {
                        Navigator.pop(sheetContext);
                      }
                      if (mounted) {
                        messenger.showSnackBar(
                          const SnackBar(
                            content: Text('🎉 VIP Premium successfully activated!'),
                            backgroundColor: AppColors.primary,
                          ),
                        );
                      }
                    } catch (e) {
                      if (sheetContext.mounted) {
                        setSheetState(() {
                          isRedeeming = false;
                          redeemError = e.toString().replaceFirst('Exception: ', '');
                        });
                      }
                    }
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _handleLogout() async {
    final confirmed = await ConfirmationDialog.show(
      context: context,
      title: 'Sign Out',
      message: 'Are you sure you want to sign out from Our Days Off on this device?',
      confirmLabel: 'Sign Out',
      isDestructive: true,
    );

    if (confirmed == true && mounted) {
      await ref.read(authNotifierProvider.notifier).logout();
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authNotifierProvider);
    final user = authState.user;

    if (user == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.scaffoldBackground,
      appBar: AppBar(
        title: const Text('Profile & Settings'),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(LucideIcons.logOut, color: AppColors.danger),
            tooltip: 'Sign Out',
            onPressed: _handleLogout,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // User Header Card
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppColors.border),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.02),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      // Avatar Circle
                      Container(
                        width: 60,
                        height: 60,
                        decoration: const BoxDecoration(
                          gradient: AppColors.heroGradient,
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: Text(
                            user.initials,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      // Details
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Flexible(
                                  child: Text(
                                    user.name,
                                    style: AppTextStyles.titleMedium,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                if (user.isPremium) ...[
                                  const SizedBox(width: 8),
                                  const StatusBadge(
                                    label: 'VIP PRO',
                                    type: StatusBadgeType.vip,
                                    isSmall: true,
                                    icon: LucideIcons.sparkles,
                                  ),
                                ],
                              ],
                            ),
                            const SizedBox(height: 3),
                            Text(
                              user.handle != null ? '@${user.handle}' : 'No handle set',
                              style: AppTextStyles.bodySmall.copyWith(
                                color: AppColors.primaryDark,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              user.email,
                              style: AppTextStyles.bodySmall,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(LucideIcons.edit3, size: 20, color: AppColors.primary),
                        onPressed: () => _showEditProfileDialog(user),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // VIP / Subscription Card
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                gradient: user.isPremium
                    ? const LinearGradient(
                        colors: [Color(0xFFFEF9C3), Color(0xFFFEF08A)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      )
                    : null,
                color: user.isPremium ? null : AppColors.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: user.isPremium ? const Color(0xFFFDE047) : AppColors.border,
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: user.isPremium
                          ? const Color(0xFFEAB308).withValues(alpha: 0.2)
                          : AppColors.primarySurface,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      LucideIcons.crown,
                      color: user.isPremium ? const Color(0xFF854D0E) : AppColors.primary,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          user.isPremium ? 'VIP Membership Active' : 'Upgrade to VIP',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: user.isPremium
                                ? const Color(0xFF854D0E)
                                : AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          user.isPremium
                              ? 'Unlimited circles & AI vision rota scanning enabled'
                              : 'Redeem code for AI scanning and unlimited circles',
                          style: TextStyle(
                            fontSize: 12,
                            color: user.isPremium
                                ? const Color(0xFFA16207)
                                : AppColors.textMuted,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (!user.isPremium) ...[
                    const SizedBox(width: 8),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                        textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
                      ),
                      onPressed: _showRedeemCouponDialog,
                      child: const Text('Redeem'),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Settings & Preferences Section
            const Text(
              'ACCOUNT & PREFERENCES',
              style: AppTextStyles.labelMedium,
            ),
            const SizedBox(height: 10),
            Container(
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.border),
              ),
              child: Column(
                children: [
                  _SettingsTile(
                    icon: LucideIcons.eye,
                    title: 'Handle Visibility',
                    subtitle: switch (user.handleVisibility) {
                      'circles_only' => 'Visible only to circles',
                      'private' => 'Private (hidden)',
                      _ => 'Public to everyone',
                    },
                    onTap: () => _showEditProfileDialog(user),
                  ),
                  const Divider(height: 1),
                  _SettingsTile(
                    icon: LucideIcons.smartphone,
                    title: 'Companion Devices',
                    subtitle: 'Sync with tablet or secondary phone',
                    trailing: const Icon(LucideIcons.chevronRight, size: 18, color: AppColors.textSubtle),
                    onTap: () {
                      AppHaptics.light();
                      // Show companion device dialog or route
                      _showCompanionDeviceSheet();
                    },
                  ),
                  const Divider(height: 1),
                  _SettingsTile(
                    icon: LucideIcons.bell,
                    title: 'Notification Preferences',
                    subtitle: 'Push alerts & schedule match updates',
                    trailing: const Icon(LucideIcons.chevronRight, size: 18, color: AppColors.textSubtle),
                    onTap: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Notifications are managed via device settings.')),
                      );
                    },
                  ),
                  if (user.isAdmin) ...[
                    const Divider(height: 1),
                    _SettingsTile(
                      icon: LucideIcons.shield,
                      title: 'Admin Dashboard',
                      subtitle: 'Platform metrics, users & coupon manager',
                      iconColor: AppColors.accentViolet,
                      trailing: const Icon(LucideIcons.chevronRight, size: 18, color: AppColors.textSubtle),
                      onTap: () {
                        // Navigate to Admin screen if available
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Admin panel will open.')),
                        );
                      },
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Sign Out Button
            AppButton(
              text: 'Sign Out',
              variant: AppButtonVariant.outline,
              icon: LucideIcons.logOut,
              onPressed: _handleLogout,
            ),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  void _showCompanionDeviceSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
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
                    Icon(LucideIcons.smartphone, color: AppColors.primary, size: 22),
                    SizedBox(width: 8),
                    Text('Companion Device Sync', style: AppTextStyles.titleMedium),
                  ],
                ),
                IconButton(
                  icon: const Icon(LucideIcons.x, size: 20),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              'Pair your iPad, Android tablet, or desktop companion to sync your roster in real time without entering passwords.',
              style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textMuted),
            ),
            const SizedBox(height: 24),
            AppButton(
              text: 'Generate 6-Digit Pairing Code',
              icon: LucideIcons.key,
              onPressed: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Pairing code generated! Ready for secondary device.'),
                    backgroundColor: AppColors.primary,
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;
  final Color? iconColor;

  const _SettingsTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.trailing,
    this.onTap,
    this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Icon(icon, size: 20, color: iconColor ?? AppColors.primaryDark),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppColors.textMuted,
                    ),
                  ),
                ],
              ),
            ),
            if (trailing != null) trailing!,
          ],
        ),
      ),
    );
  }
}
