import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/haptic_feedback.dart';

enum AppButtonVariant {
  primary,
  secondary,
  outline,
  danger,
  text,
}

enum AppButtonSize {
  small,
  medium,
  large,
}

class AppButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final AppButtonVariant variant;
  final AppButtonSize size;
  final bool isLoading;
  final bool fullWidth;
  final IconData? icon;
  final IconData? trailingIcon;

  const AppButton({
    super.key,
    required this.text,
    this.onPressed,
    this.variant = AppButtonVariant.primary,
    this.size = AppButtonSize.medium,
    this.isLoading = false,
    this.fullWidth = true,
    this.icon,
    this.trailingIcon,
  });

  @override
  Widget build(BuildContext context) {
    final bool disabled = onPressed == null || isLoading;

    final double verticalPadding = switch (size) {
      AppButtonSize.small => 9,
      AppButtonSize.medium => 13,
      AppButtonSize.large => 16,
    };

    final double fontSize = switch (size) {
      AppButtonSize.small => 12,
      AppButtonSize.medium => 14,
      AppButtonSize.large => 16,
    };

    final double iconSize = switch (size) {
      AppButtonSize.small => 15,
      AppButtonSize.medium => 18,
      AppButtonSize.large => 20,
    };

    Color bgColor;
    Color fgColor;
    BorderSide borderSide = BorderSide.none;

    switch (variant) {
      case AppButtonVariant.primary:
        bgColor = disabled ? AppColors.primary.withValues(alpha: 0.5) : AppColors.primary;
        fgColor = AppColors.textInverse;
      case AppButtonVariant.secondary:
        bgColor = disabled ? AppColors.surfaceSecondary.withValues(alpha: 0.5) : AppColors.surfaceSecondary;
        fgColor = disabled ? AppColors.textSubtle : AppColors.primaryDark;
      case AppButtonVariant.outline:
        bgColor = Colors.transparent;
        fgColor = disabled ? AppColors.textSubtle : AppColors.primaryDark;
        borderSide = BorderSide(color: disabled ? AppColors.border : AppColors.border);
      case AppButtonVariant.danger:
        bgColor = disabled ? AppColors.danger.withValues(alpha: 0.5) : AppColors.danger;
        fgColor = AppColors.textInverse;
      case AppButtonVariant.text:
        bgColor = Colors.transparent;
        fgColor = disabled ? AppColors.textSubtle : AppColors.primary;
    }

    final buttonStyle = ElevatedButton.styleFrom(
      backgroundColor: bgColor,
      foregroundColor: fgColor,
      disabledBackgroundColor: bgColor,
      disabledForegroundColor: fgColor,
      elevation: 0,
      shadowColor: Colors.transparent,
      padding: EdgeInsets.symmetric(horizontal: 18, vertical: verticalPadding),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: borderSide,
      ),
    );

    Widget content = Row(
      mainAxisSize: fullWidth ? MainAxisSize.max : MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (isLoading) ...[
          SizedBox(
            width: iconSize,
            height: iconSize,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(fgColor),
            ),
          ),
          const SizedBox(width: 10),
        ] else if (icon != null) ...[
          Icon(icon, size: iconSize, color: fgColor),
          const SizedBox(width: 8),
        ],
        Text(
          text,
          style: TextStyle(
            fontSize: fontSize,
            fontWeight: FontWeight.w600,
            color: fgColor,
          ),
        ),
        if (!isLoading && trailingIcon != null) ...[
          const SizedBox(width: 8),
          Icon(trailingIcon, size: iconSize, color: fgColor),
        ],
      ],
    );

    final button = ElevatedButton(
      style: buttonStyle,
      onPressed: disabled
          ? null
          : () {
              AppHaptics.light();
              onPressed?.call();
            },
      child: content,
    );

    if (fullWidth) {
      return SizedBox(
        width: double.infinity,
        child: button,
      );
    }

    return button;
  }
}
