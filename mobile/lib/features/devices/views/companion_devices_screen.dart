import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/text_styles.dart';
import '../../../core/utils/haptic_feedback.dart';
import '../../../shared/widgets/app_button.dart';
import '../../../shared/widgets/app_text_field.dart';
import '../../../shared/widgets/confirmation_dialog.dart';
import '../../../shared/widgets/empty_state_view.dart';
import '../../../shared/widgets/loading_indicator.dart';
import '../models/device_model.dart';
import '../providers/device_provider.dart';

class CompanionDevicesScreen extends ConsumerStatefulWidget {
  const CompanionDevicesScreen({super.key});

  @override
  ConsumerState<CompanionDevicesScreen> createState() =>
      _CompanionDevicesScreenState();
}

class _CompanionDevicesScreenState extends ConsumerState<CompanionDevicesScreen> {
  final _codeController = TextEditingController();
  final _deviceNameController = TextEditingController();

  @override
  void dispose() {
    _codeController.dispose();
    _deviceNameController.dispose();
    super.dispose();
  }

  void _showPairDeviceSheet() {
    _codeController.clear();
    _deviceNameController.clear();
    bool isPairing = false;
    String? pairError;

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
                    const Row(
                      children: [
                        Icon(LucideIcons.link, color: AppColors.primary, size: 20),
                        SizedBox(width: 8),
                        Text('Pair Secondary Device', style: AppTextStyles.titleMedium),
                      ],
                    ),
                    IconButton(
                      icon: const Icon(LucideIcons.x, size: 20),
                      onPressed: () => Navigator.pop(sheetContext),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                const Text(
                  'Enter the 6-character sync code displayed on your other device to link it instantly.',
                  style: TextStyle(fontSize: 13, color: AppColors.textMuted),
                ),
                const SizedBox(height: 16),
                if (pairError != null) ...[
                  Text(
                    pairError!,
                    style: const TextStyle(color: AppColors.danger, fontSize: 12),
                  ),
                  const SizedBox(height: 8),
                ],
                AppTextField(
                  controller: _codeController,
                  label: '6-Digit Code',
                  hint: 'e.g. AB12CD',
                  prefixIcon: LucideIcons.keyRound,
                ),
                const SizedBox(height: 14),
                AppTextField(
                  controller: _deviceNameController,
                  label: 'Device Label (Optional)',
                  hint: 'e.g. My iPad Pro or Living Room Tablet',
                  prefixIcon: LucideIcons.tag,
                ),
                const SizedBox(height: 20),
                AppButton(
                  text: 'Link Device',
                  isLoading: isPairing,
                  onPressed: () async {
                    final code = _codeController.text.trim();
                    if (code.length < 6) {
                      setSheetState(() => pairError = 'Please enter a valid 6-character code.');
                      return;
                    }

                    setSheetState(() => isPairing = true);
                    final success = await ref
                        .read(devicesNotifierProvider.notifier)
                        .pairWithCode(
                          pairingCode: code,
                          customDeviceName: _deviceNameController.text.trim().isNotEmpty
                              ? _deviceNameController.text.trim()
                              : null,
                        );

                    if (sheetContext.mounted) {
                      if (success) {
                        Navigator.pop(sheetContext);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Device paired successfully!'),
                            backgroundColor: AppColors.primary,
                          ),
                        );
                      } else {
                        final err = ref.read(devicesNotifierProvider).error ??
                            'Pairing failed. Please check the code.';
                        setSheetState(() {
                          isPairing = false;
                          pairError = err;
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

  Future<void> _handleRevoke(DeviceModel device) async {
    final confirmed = await ConfirmationDialog.show(
      context: context,
      title: 'Revoke Companion Device',
      message: 'Are you sure you want to revoke "${device.deviceName}"? This will terminate its active session.',
      confirmLabel: 'Revoke Session',
      isDestructive: true,
    );

    if (confirmed == true && mounted) {
      AppHaptics.light();
      final success = await ref
          .read(devicesNotifierProvider.notifier)
          .revokeDevice(device.id);

      if (mounted) {
        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('"${device.deviceName}" revoked.')),
          );
        } else {
          final err = ref.read(devicesNotifierProvider).error ?? 'Failed to revoke device';
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(err), backgroundColor: AppColors.danger),
          );
        }
      }
    }
  }

  IconData _getDeviceIcon(String type) {
    final lower = type.toLowerCase();
    if (lower.contains('ios') || lower.contains('iphone')) {
      return LucideIcons.smartphone;
    } else if (lower.contains('ipad') || lower.contains('tablet')) {
      return LucideIcons.tablet;
    } else if (lower.contains('web') || lower.contains('desktop')) {
      return LucideIcons.monitor;
    }
    return LucideIcons.smartphone;
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(devicesNotifierProvider);

    return Scaffold(
      backgroundColor: AppColors.scaffoldBackground,
      appBar: AppBar(
        title: const Text('Companion Devices'),
        actions: [
          IconButton(
            icon: const Icon(LucideIcons.refreshCw, size: 20),
            tooltip: 'Refresh',
            onPressed: () {
              AppHaptics.light();
              ref.read(devicesNotifierProvider.notifier).loadDevices();
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () => ref.read(devicesNotifierProvider.notifier).loadDevices(),
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Info Card
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.border),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: const BoxDecoration(
                        color: AppColors.primarySurface,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(LucideIcons.smartphoneNfc, color: AppColors.primary, size: 22),
                    ),
                    const SizedBox(width: 14),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Instant Multi-Device Sync', style: AppTextStyles.titleSmall),
                          SizedBox(height: 3),
                          Text(
                            'Pair tablets and secondary phones using a secure 6-digit one-time code.',
                            style: TextStyle(fontSize: 12, color: AppColors.textMuted),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Code Generator Section
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
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Row(
                      children: [
                        Icon(LucideIcons.qrCode, color: AppColors.primary, size: 20),
                        SizedBox(width: 8),
                        Text('Sync a Secondary Device', style: AppTextStyles.titleMedium),
                      ],
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'Generate a one-time pairing code to link another device to this account.',
                      style: TextStyle(fontSize: 12, color: AppColors.textMuted),
                    ),
                    const SizedBox(height: 16),

                    if (state.activePairingCode != null) ...[
                      Container(
                        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
                        decoration: BoxDecoration(
                          color: AppColors.primarySurface,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
                        ),
                        child: Column(
                          children: [
                            const Text(
                              'YOUR 6-DIGIT PAIRING CODE',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 1.2,
                                color: AppColors.primaryDark,
                              ),
                            ),
                            const SizedBox(height: 12),
                            // Code display boxes
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: state.activePairingCode!.pairingCode
                                  .split('')
                                  .map(
                                    (char) => Container(
                                      margin: const EdgeInsets.symmetric(horizontal: 4),
                                      width: 40,
                                      height: 48,
                                      decoration: BoxDecoration(
                                        color: AppColors.surface,
                                        borderRadius: BorderRadius.circular(10),
                                        border: Border.all(color: AppColors.primary, width: 1.5),
                                        boxShadow: [
                                          BoxShadow(
                                            color: AppColors.primary.withValues(alpha: 0.1),
                                            blurRadius: 4,
                                            offset: const Offset(0, 2),
                                          ),
                                        ],
                                      ),
                                      child: Center(
                                        child: Text(
                                          char,
                                          style: const TextStyle(
                                            fontSize: 22,
                                            fontWeight: FontWeight.w800,
                                            fontFamily: 'monospace',
                                            color: AppColors.primaryDark,
                                          ),
                                        ),
                                      ),
                                    ),
                                  )
                                  .toList(),
                            ),
                            const SizedBox(height: 14),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(LucideIcons.clock, size: 14, color: AppColors.textMuted),
                                const SizedBox(width: 5),
                                Text(
                                  'Expires at ${DateFormat('hh:mm a').format(state.activePairingCode!.expiresAt)} (10 min)',
                                  style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            OutlinedButton.icon(
                              style: OutlinedButton.styleFrom(
                                foregroundColor: AppColors.primaryDark,
                                side: const BorderSide(color: AppColors.primary),
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                              ),
                              icon: const Icon(LucideIcons.copy, size: 16),
                              label: const Text('Copy Code', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                              onPressed: () {
                                AppHaptics.light();
                                Clipboard.setData(ClipboardData(text: state.activePairingCode!.pairingCode));
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Pairing code copied to clipboard!'),
                                    duration: Duration(seconds: 2),
                                  ),
                                );
                              },
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                    ],

                    Row(
                      children: [
                        Expanded(
                          child: AppButton(
                            text: state.activePairingCode != null ? 'Generate New Code' : 'Generate Code',
                            variant: state.activePairingCode != null
                                ? AppButtonVariant.outline
                                : AppButtonVariant.primary,
                            icon: LucideIcons.key,
                            isLoading: state.isGeneratingCode,
                            onPressed: () {
                              AppHaptics.selection();
                              ref.read(devicesNotifierProvider.notifier).generatePairingCode();
                            },
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: AppButton(
                            text: 'Enter Code',
                            variant: AppButtonVariant.secondary,
                            icon: LucideIcons.arrowDownToLine,
                            onPressed: _showPairDeviceSheet,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Active Paired Devices List Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('ACTIVE PAIRED DEVICES', style: AppTextStyles.labelMedium),
                  Text(
                    '${state.devices.length} registered',
                    style: const TextStyle(fontSize: 11, color: AppColors.textMuted, fontWeight: FontWeight.w600),
                  ),
                ],
              ),
              const SizedBox(height: 10),

              if (state.isLoading && state.devices.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 40),
                  child: AppLoadingIndicator(),
                )
              else if (state.devices.isEmpty)
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: const EmptyStateView(
                    icon: LucideIcons.smartphone,
                    title: 'No Paired Devices Yet',
                    description: 'Link your iPad, secondary phone, or desktop to view schedules together in real-time.',
                  ),
                )
              else
                ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: state.devices.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (context, index) {
                    final device = state.devices[index];
                    final lastSeen = device.lastSeenAt != null
                        ? DateFormat('MMM d, hh:mm a').format(device.lastSeenAt!)
                        : 'Never';

                    return Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              color: AppColors.scaffoldBackground,
                              shape: BoxShape.circle,
                              border: Border.all(color: AppColors.border),
                            ),
                            child: Icon(_getDeviceIcon(device.deviceType), size: 22, color: AppColors.primary),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Flexible(
                                      child: Text(
                                        device.deviceName,
                                        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: AppColors.scaffoldBackground,
                                        borderRadius: BorderRadius.circular(6),
                                        border: Border.all(color: AppColors.border),
                                      ),
                                      child: Text(
                                        device.deviceType.toUpperCase(),
                                        style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w700, color: AppColors.textMuted),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    Container(
                                      width: 6,
                                      height: 6,
                                      decoration: const BoxDecoration(
                                        color: AppColors.statusAvailable,
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      'Last active: $lastSeen',
                                      style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            icon: const Icon(LucideIcons.trash2, size: 18, color: AppColors.danger),
                            tooltip: 'Revoke Device',
                            onPressed: () => _handleRevoke(device),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }
}
