import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/text_styles.dart';
import '../../../../core/utils/haptic_feedback.dart';
import '../../models/circle_member.dart';

class MemberItemTile extends StatelessWidget {
  final CircleMember member;
  final bool canManageMembers;
  final bool canManageRoles;
  final bool isCurrentAuthUser;
  final bool isActionInProgress;
  final ValueChanged<String> onUpdateType;
  final ValueChanged<String> onUpdateVisibility;
  final ValueChanged<String>? onUpdateRole;
  final VoidCallback? onRemoveMember;

  const MemberItemTile({
    super.key,
    required this.member,
    required this.canManageMembers,
    required this.canManageRoles,
    required this.isCurrentAuthUser,
    required this.isActionInProgress,
    required this.onUpdateType,
    required this.onUpdateVisibility,
    this.onUpdateRole,
    this.onRemoveMember,
  });

  Color _getRoleColor(String role) {
    switch (role.toLowerCase()) {
      case 'owner':
        return AppColors.primary;
      case 'admin':
        return AppColors.accentViolet;
      default:
        return AppColors.textMuted;
    }
  }

  Color _getRoleBgColor(String role) {
    switch (role.toLowerCase()) {
      case 'owner':
        return AppColors.primarySurface;
      case 'admin':
        return AppColors.statusOvernightBg;
      default:
        return AppColors.surfaceSecondary;
    }
  }

  String _formatVisibility(String visibility) {
    switch (visibility.toLowerCase()) {
      case 'shifts':
        return 'Shifts Category';
      case 'details':
        return 'Full Shift Details';
      case 'free_busy':
      default:
        return 'Free/Busy Only';
    }
  }

  @override
  Widget build(BuildContext context) {
    final roleColor = _getRoleColor(member.role);
    final roleBg = _getRoleBgColor(member.role);
    final canEditVisibility = canManageMembers || isCurrentAuthUser;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
        boxShadow: const [
          BoxShadow(
            color: Color(0x05000000),
            blurRadius: 4,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header: Avatar, Name, Handle, Role Badge, and Options
          Row(
            children: [
              // Avatar
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppColors.primaryLight.withValues(alpha: 0.35),
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: Text(
                  member.initials,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primaryDark,
                  ),
                ),
              ),
              const SizedBox(width: 12),

              // Name & Handle
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            member.displayName,
                            style: AppTextStyles.titleSmall.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (isCurrentAuthUser) ...[
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                            decoration: BoxDecoration(
                              color: AppColors.accentLime.withValues(alpha: 0.3),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: const Text(
                              'YOU',
                              style: TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.bold,
                                color: AppColors.accentGold,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      member.handle != null && member.handle!.isNotEmpty
                          ? '@${member.handle}'
                          : 'No handle',
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textMuted,
                      ),
                    ),
                  ],
                ),
              ),

              // Role Badge & Role Change Menu
              if (canManageRoles && !member.isOwner && onUpdateRole != null)
                PopupMenuButton<String>(
                  tooltip: 'Change Role',
                  onSelected: (role) {
                    AppHaptics.light();
                    onUpdateRole!(role);
                  },
                  itemBuilder: (context) => [
                    PopupMenuItem(
                      value: 'admin',
                      child: Row(
                        children: [
                          Icon(
                            member.isAdmin ? Icons.check : LucideIcons.shieldAlert,
                            size: 16,
                            color: AppColors.accentViolet,
                          ),
                          const SizedBox(width: 8),
                          const Text('Admin'),
                        ],
                      ),
                    ),
                    PopupMenuItem(
                      value: 'member',
                      child: Row(
                        children: [
                          Icon(
                            !member.isAdmin ? Icons.check : LucideIcons.user,
                            size: 16,
                            color: AppColors.textMuted,
                          ),
                          const SizedBox(width: 8),
                          const Text('Regular Member'),
                        ],
                      ),
                    ),
                  ],
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: roleBg,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: roleColor.withValues(alpha: 0.3)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          member.role.toUpperCase(),
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: roleColor,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Icon(LucideIcons.chevronDown, size: 12, color: roleColor),
                      ],
                    ),
                  ),
                )
              else
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: roleBg,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: roleColor.withValues(alpha: 0.3)),
                  ),
                  child: Text(
                    member.role.toUpperCase(),
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: roleColor,
                    ),
                  ),
                ),

              // Remove Member Action
              if (onRemoveMember != null) ...[
                const SizedBox(width: 4),
                IconButton(
                  icon: const Icon(LucideIcons.trash2, size: 16, color: AppColors.textSubtle),
                  visualDensity: VisualDensity.compact,
                  tooltip: 'Remove Member',
                  onPressed: () {
                    AppHaptics.medium();
                    _showRemoveConfirmation(context);
                  },
                ),
              ],
            ],
          ),

          const SizedBox(height: 12),
          const Divider(height: 1, color: AppColors.borderLight),
          const SizedBox(height: 12),

          // Controls Row: Type & Visibility
          if (isActionInProgress)
            const Center(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 8),
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
            )
          else
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                // Member Participation Type
                if (canManageMembers)
                  PopupMenuButton<String>(
                    tooltip: 'Change Participation Type',
                    onSelected: (val) {
                      AppHaptics.selection();
                      onUpdateType(val);
                    },
                    itemBuilder: (context) => const [
                      PopupMenuItem(
                        value: 'working',
                        child: Text('Working Member (Matches Availability)'),
                      ),
                      PopupMenuItem(
                        value: 'viewer',
                        child: Text('Viewer (No Match Calculation)'),
                      ),
                    ],
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: AppColors.scaffoldBackground,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(LucideIcons.activity, size: 13, color: AppColors.primary),
                          const SizedBox(width: 6),
                          Text(
                            member.isWorking ? 'Working' : 'Viewer',
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: AppColors.primaryDark,
                            ),
                          ),
                          const SizedBox(width: 4),
                          const Icon(LucideIcons.chevronDown, size: 12, color: AppColors.textMuted),
                        ],
                      ),
                    ),
                  )
                else
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppColors.scaffoldBackground,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(LucideIcons.activity, size: 13, color: AppColors.primary),
                        const SizedBox(width: 6),
                        Text(
                          member.isWorking ? 'Working' : 'Viewer',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: AppColors.primaryDark,
                          ),
                        ),
                      ],
                    ),
                  ),

                // Visibility Policy
                if (canEditVisibility)
                  PopupMenuButton<String>(
                    tooltip: 'Change Visibility Policy',
                    onSelected: (val) {
                      AppHaptics.selection();
                      onUpdateVisibility(val);
                    },
                    itemBuilder: (context) => const [
                      PopupMenuItem(
                        value: 'free_busy',
                        child: Text('Free/Busy Only (Strict Privacy)'),
                      ),
                      PopupMenuItem(
                        value: 'shifts',
                        child: Text('Shifts Category'),
                      ),
                      PopupMenuItem(
                        value: 'details',
                        child: Text('Full Shift Details'),
                      ),
                    ],
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: AppColors.scaffoldBackground,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(LucideIcons.eye, size: 13, color: AppColors.primaryDark),
                          const SizedBox(width: 6),
                          Text(
                            _formatVisibility(member.visibility),
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(width: 4),
                          const Icon(LucideIcons.chevronDown, size: 12, color: AppColors.textMuted),
                        ],
                      ),
                    ),
                  )
                else
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppColors.scaffoldBackground,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(LucideIcons.eye, size: 13, color: AppColors.primaryDark),
                        const SizedBox(width: 6),
                        Text(
                          _formatVisibility(member.visibility),
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
        ],
      ),
    );
  }

  void _showRemoveConfirmation(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        title: const Text('Remove Member'),
        content: Text(
          'Are you sure you want to remove ${member.displayName} from this circle?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogCtx).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(dialogCtx).pop();
              onRemoveMember?.call();
            },
            style: TextButton.styleFrom(foregroundColor: AppColors.danger),
            child: const Text('Remove'),
          ),
        ],
      ),
    );
  }
}
