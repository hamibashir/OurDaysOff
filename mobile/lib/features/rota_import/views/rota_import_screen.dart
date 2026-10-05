import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/text_styles.dart';
import '../../../core/utils/haptic_feedback.dart';
import '../../../shared/widgets/app_button.dart';
import '../../../shared/widgets/loading_indicator.dart';
import '../../../shared/widgets/app_text_field.dart';
import '../../../shared/widgets/status_badge.dart';
import '../../schedule/providers/schedule_notifier.dart';
import '../models/import_preview_entry.dart';
import '../models/picked_rota_file.dart';
import '../providers/rota_import_notifier.dart';
import '../providers/rota_import_state.dart';
import '../repositories/rota_import_repository.dart';
import '../services/media_picker_service.dart';
import 'widgets/edit_preview_entry_sheet.dart';
import 'widgets/image_source_picker_modal.dart';

class RotaImportScreen extends ConsumerStatefulWidget {
  const RotaImportScreen({super.key});

  @override
  ConsumerState<RotaImportScreen> createState() => _RotaImportScreenState();
}

class _RotaImportScreenState extends ConsumerState<RotaImportScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  final TextEditingController _couponController = TextEditingController();
  final TextEditingController _jsonController = TextEditingController();
  bool _promptCopied = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _couponController.dispose();
    _jsonController.dispose();
    super.dispose();
  }

  Future<void> _pickFile() async {
    final mediaPicker = ref.read(mediaPickerServiceProvider);
    final file = await ImageSourcePickerModal.show(
      context,
      mediaPicker: mediaPicker,
    );

    if (file != null) {
      ref.read(rotaImportNotifierProvider.notifier).setSelectedFile(file);
    }
  }

  Future<void> _copyPrompt() async {
    AppHaptics.selection();
    await Clipboard.setData(
      const ClipboardData(text: RotaImportRepository.externalPromptTemplate),
    );
    setState(() => _promptCopied = true);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('AI prompt copied to clipboard!'),
          duration: Duration(seconds: 2),
        ),
      );
    }
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) setState(() => _promptCopied = false);
    });
  }

  Future<void> _pasteFromClipboard() async {
    AppHaptics.selection();
    final data = await Clipboard.getData(Clipboard.kTextPlain);
    if (data?.text != null && data!.text!.isNotEmpty) {
      _jsonController.text = data.text!;
    }
  }

  Future<void> _editEntry(int index, ImportPreviewEntry entry) async {
    final updated = await EditPreviewEntrySheet.show(
      context,
      initialEntry: entry,
    );
    if (updated != null) {
      ref.read(rotaImportNotifierProvider.notifier).updatePreviewEntry(index, updated);
    }
  }

  Future<void> _addMissingEntry() async {
    final newEntry = await EditPreviewEntrySheet.show(
      context,
      isNew: true,
    );
    if (newEntry != null) {
      ref.read(rotaImportNotifierProvider.notifier).addManualEntry(newEntry);
    }
  }

  Future<void> _confirmBatch() async {
    AppHaptics.selection();
    final notifier = ref.read(rotaImportNotifierProvider.notifier);
    final count = ref.read(rotaImportNotifierProvider).previewEntries.length;

    final success = await notifier.confirmImport();
    if (success && mounted) {
      AppHaptics.heavy();
      // Reload month schedule so the newly imported shifts show up immediately
      final focusedMonth = ref.read(scheduleNotifierProvider).focusedMonth;
      ref.read(scheduleNotifierProvider.notifier).loadMonth(focusedMonth);
      _showSuccessCelebration(count);
    }
  }

  void _showSuccessCelebration(int count) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        contentPadding: const EdgeInsets.all(24),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 60,
              height: 60,
              decoration: const BoxDecoration(
                color: AppColors.statusAvailableBg,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                LucideIcons.calendarCheck,
                color: AppColors.statusAvailable,
                size: 32,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Import Successful!',
              style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18),
            ),
            const SizedBox(height: 8),
            Text(
              'Successfully added $count shift${count == 1 ? '' : 's'} to your calendar.',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 13, color: AppColors.textMuted),
            ),
            const SizedBox(height: 20),
            AppButton(
              text: 'View on Calendar',
              icon: LucideIcons.calendar,
              onPressed: () {
                Navigator.of(dialogContext).pop();
                context.go('/schedule');
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(rotaImportNotifierProvider);
    final notifier = ref.read(rotaImportNotifierProvider.notifier);

    return Scaffold(
      backgroundColor: AppColors.scaffoldBackground,
      appBar: AppBar(
        title: const Text('Import Rota & Shifts'),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(LucideIcons.x, size: 20),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Error banner
              if (state.errorMessage != null) ...[
                Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.dangerBg,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppColors.dangerBorder),
                  ),
                  child: Row(
                    children: [
                      const Icon(LucideIcons.alertCircle, color: AppColors.danger, size: 18),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          state.errorMessage!,
                          style: const TextStyle(
                            color: AppColors.danger,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(LucideIcons.x, size: 16, color: AppColors.danger),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                        onPressed: notifier.clearError,
                      ),
                    ],
                  ),
                ),
              ],

              // Coupon success banner
              if (state.couponSuccessMessage != null) ...[
                Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.statusAvailableBg,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppColors.statusAvailable.withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    children: [
                      const Icon(LucideIcons.checkCircle2, color: AppColors.statusAvailable, size: 18),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          state.couponSuccessMessage!,
                          style: const TextStyle(
                            color: AppColors.statusAvailable,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              // If shifts are already extracted / parsed
              if (state.hasPreview) ...[
                _buildPreviewSection(state, notifier),
              ] else ...[
                // Tabs: AI Vision vs External AI
                Container(
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: TabBar(
                    controller: _tabController,
                    indicatorColor: AppColors.primary,
                    indicatorSize: TabBarIndicatorSize.tab,
                    labelColor: AppColors.primaryDark,
                    unselectedLabelColor: AppColors.textMuted,
                    labelStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                    unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w500, fontSize: 13),
                    tabs: const [
                      Tab(
                        icon: Icon(LucideIcons.sparkles, size: 16),
                        text: 'AI Vision Scanner',
                      ),
                      Tab(
                        icon: Icon(LucideIcons.bot, size: 16),
                        text: 'Use Any AI Tool',
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Tab Content
                AnimatedBuilder(
                  animation: _tabController,
                  builder: (context, _) {
                    return _tabController.index == 0
                        ? _buildAiVisionTab(state, notifier)
                        : _buildExternalAiTab(state, notifier);
                  },
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAiVisionTab(RotaImportState state, RotaImportNotifier notifier) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // VIP Banner
        if (state.isCheckingPremium) ...[
          const Center(child: AppLoadingIndicator()),
        ] else if (state.isPremium == false) ...[
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFFFFBEB),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFFDE68A)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(LucideIcons.crown, color: AppColors.statusLeave, size: 20),
                    SizedBox(width: 8),
                    Text(
                      'AI Vision Scanner requires VIP',
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                        color: Color(0xFF92400E),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                const Text(
                  'Instantly scan physical rosters or PDFs using AI Vision. Have a promo coupon code? Redeem it below:',
                  style: TextStyle(fontSize: 12, color: Color(0xFFB45309)),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: AppTextField(
                        controller: _couponController,
                        hint: 'e.g. EARLYVIP',
                        prefixIcon: LucideIcons.tag,
                        textInputAction: TextInputAction.done,
                      ),
                    ),
                    const SizedBox(width: 8),
                    AppButton(
                      text: 'Redeem',
                      size: AppButtonSize.small,
                      fullWidth: false,
                      isLoading: state.isRedeemingCoupon,
                      onPressed: () async {
                        final success = await notifier.redeemCoupon(_couponController.text);
                        if (success) _couponController.clear();
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                GestureDetector(
                  onTap: () {
                    AppHaptics.light();
                    _tabController.animateTo(1);
                  },
                  child: const Text(
                    'Tip: "Use Any AI Tool" mode is 100% free! Tap here to switch →',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.primary,
                      decoration: TextDecoration.underline,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
        ] else if (state.isPremium == true) ...[
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: AppColors.statusAvailableBg,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.statusAvailable.withValues(alpha: 0.3)),
            ),
            child: const Row(
              children: [
                Icon(LucideIcons.crown, color: AppColors.statusAvailable, size: 16),
                SizedBox(width: 8),
                Text(
                  'VIP Premium Active — Unlimited AI Vision Uploads',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: AppColors.statusAvailable,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
        ],

        // File Selection Box
        if (state.selectedFile == null) ...[
          InkWell(
            onTap: _pickFile,
            borderRadius: BorderRadius.circular(16),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 36, horizontal: 20),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: AppColors.primary.withValues(alpha: 0.4),
                  width: 1.5,
                ),
              ),
              child: Column(
                children: [
                  Container(
                    width: 54,
                    height: 54,
                    decoration: const BoxDecoration(
                      color: Color(0xFFEFF6FF),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      LucideIcons.camera,
                      color: AppColors.primary,
                      size: 26,
                    ),
                  ),
                  const SizedBox(height: 14),
                  const Text(
                    'Select or Snap Rota Schedule',
                    style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Supports Camera Photos, Gallery Images, and PDF Documents',
                    textAlign: TextAlign.center,
                    style: AppTextStyles.bodySmall.copyWith(color: AppColors.textMuted),
                  ),
                  const SizedBox(height: 16),
                  AppButton(
                    text: 'Choose Source',
                    icon: LucideIcons.upload,
                    size: AppButtonSize.small,
                    fullWidth: false,
                    onPressed: _pickFile,
                  ),
                ],
              ),
            ),
          ),
        ] else ...[
          _buildSelectedFileCard(state.selectedFile!, notifier),
          const SizedBox(height: 16),

          if (state.uploadProgress != null && state.isLoading) ...[
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value: state.uploadProgress,
                backgroundColor: AppColors.border,
                valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary),
                minHeight: 6,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Analyzing rota with AI Vision (${(state.uploadProgress! * 100).toInt()}%)...',
              textAlign: TextAlign.center,
              style: AppTextStyles.bodySmall.copyWith(color: AppColors.textMuted),
            ),
            const SizedBox(height: 12),
          ],

          AppButton(
            text: 'Scan & Extract Shifts',
            icon: LucideIcons.sparkles,
            isLoading: state.isLoading,
            onPressed: state.isLoading ? null : () => notifier.uploadAndExtract(),
          ),
        ],
      ],
    );
  }

  Widget _buildSelectedFileCard(PickedRotaFile file, RotaImportNotifier notifier) {
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
              color: file.isPdf ? const Color(0xFFF5F3FF) : const Color(0xFFEFF6FF),
              shape: BoxShape.circle,
            ),
            child: Icon(
              file.isPdf ? LucideIcons.fileText : LucideIcons.image,
              color: file.isPdf ? AppColors.statusOvernight : AppColors.statusBusy,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  file.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                ),
                const SizedBox(height: 2),
                Text(
                  file.displaySize,
                  style: const TextStyle(color: AppColors.textMuted, fontSize: 11),
                ),
              ],
            ),
          ),
          TextButton(
            onPressed: _pickFile,
            child: const Text('Change', style: TextStyle(fontSize: 12)),
          ),
          IconButton(
            icon: const Icon(LucideIcons.trash2, size: 18, color: AppColors.danger),
            onPressed: () => notifier.setSelectedFile(null),
          ),
        ],
      ),
    );
  }

  Widget _buildExternalAiTab(RotaImportState state, RotaImportNotifier notifier) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Free Badge Info
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: const Color(0xFFEFF6FF),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFBFDBFE)),
          ),
          child: const Row(
            children: [
              Icon(LucideIcons.sparkles, color: AppColors.statusBusy, size: 16),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  '100% Free: Use ChatGPT, Claude, Gemini or DeepSeek with our prompt.',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1E40AF),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Step 1: Prompt
        const Text(
          'Step 1: Copy AI Prompt',
          style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
        ),
        const SizedBox(height: 6),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.scaffoldBackground,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.border),
          ),
          child: const Text(
            RotaImportRepository.externalPromptTemplate,
            maxLines: 5,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontFamily: 'monospace',
              fontSize: 10.5,
              color: AppColors.textMuted,
            ),
          ),
        ),
        const SizedBox(height: 10),
        AppButton(
          text: _promptCopied ? 'Copied Prompt to Clipboard!' : 'Copy AI Prompt to Clipboard',
          icon: _promptCopied ? LucideIcons.check : LucideIcons.copy,
          variant: _promptCopied ? AppButtonVariant.primary : AppButtonVariant.outline,
          size: AppButtonSize.small,
          onPressed: _copyPrompt,
        ),
        const SizedBox(height: 20),

        // Step 2 & 3: Paste Output
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Step 2: Paste AI JSON Output',
              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
            ),
            TextButton.icon(
              icon: const Icon(LucideIcons.clipboard, size: 14),
              label: const Text('Paste', style: TextStyle(fontSize: 12)),
              onPressed: _pasteFromClipboard,
            ),
          ],
        ),
        const SizedBox(height: 6),
        Container(
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.border),
          ),
          child: TextField(
            controller: _jsonController,
            maxLines: 7,
            style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
            decoration: const InputDecoration(
              hintText: '{\n  "entries": [\n    {\n      "date": "2026-10-15",\n      "shift_label": "Early Shift",\n      "start_time": "07:00",\n      "end_time": "15:00"\n    }\n  ]\n}',
              hintStyle: TextStyle(color: AppColors.textSubtle, fontSize: 11),
              contentPadding: EdgeInsets.all(12),
              border: InputBorder.none,
            ),
          ),
        ),
        const SizedBox(height: 16),

        AppButton(
          text: 'Parse & Preview Shifts',
          icon: LucideIcons.bot,
          isLoading: state.isLoading,
          onPressed: state.isLoading
              ? null
              : () => notifier.parseExternalJson(_jsonController.text),
        ),
      ],
    );
  }

  Widget _buildPreviewSection(RotaImportState state, RotaImportNotifier notifier) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Header
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.statusAvailableBg,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.statusAvailable.withValues(alpha: 0.3)),
          ),
          child: Row(
            children: [
              const Icon(LucideIcons.sparkles, color: AppColors.statusAvailable, size: 22),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${state.previewEntries.length} Shifts Extracted',
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                        color: AppColors.statusAvailable,
                      ),
                    ),
                    const SizedBox(height: 2),
                    const Text(
                      'Tap any shift to edit details or times before saving.',
                      style: TextStyle(fontSize: 12, color: AppColors.textMuted),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(LucideIcons.rotateCcw, size: 18),
                tooltip: 'Reset and scan again',
                onPressed: () {
                  AppHaptics.light();
                  notifier.reset();
                  _jsonController.clear();
                },
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),

        // Action Toolbar
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Preview Shifts (${state.previewEntries.length})',
              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
            ),
            TextButton.icon(
              icon: const Icon(LucideIcons.plus, size: 14),
              label: const Text('Add Shift', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
              onPressed: _addMissingEntry,
            ),
          ],
        ),
        const SizedBox(height: 8),

        // List preview entries
        ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: state.previewEntries.length,
          separatorBuilder: (_, __) => const SizedBox(height: 8),
          itemBuilder: (context, index) {
            final entry = state.previewEntries[index];
            return _buildPreviewCard(entry, index, notifier);
          },
        ),
        const SizedBox(height: 20),

        // Batch confirmation card
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.border),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Ready to save shifts:',
                    style: TextStyle(fontSize: 13, color: AppColors.textMuted),
                  ),
                  Text(
                    '${state.previewEntries.length} entries',
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              AppButton(
                text: 'Confirm & Import to Calendar',
                icon: LucideIcons.calendarCheck,
                isLoading: state.isConfirming,
                onPressed: state.isConfirming || state.previewEntries.isEmpty
                    ? null
                    : _confirmBatch,
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildPreviewCard(ImportPreviewEntry entry, int index, RotaImportNotifier notifier) {
    return InkWell(
      onTap: () => _editEntry(index, entry),
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.scaffoldBackground,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.border),
              ),
              child: Column(
                children: [
                  Text(
                    entry.date,
                    style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          entry.shiftLabel,
                          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                        ),
                      ),
                      if (entry.isOvernight) ...[
                        const StatusBadge(
                          label: 'Overnight',
                          type: StatusBadgeType.overnight,
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 3),
                  Text(
                    '${entry.startTime} – ${entry.endTime}  •  ${entry.entryType.toUpperCase()}',
                    style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
                  ),
                ],
              ),
            ),
            IconButton(
              icon: const Icon(LucideIcons.pencil, size: 16, color: AppColors.primary),
              tooltip: 'Edit shift',
              onPressed: () => _editEntry(index, entry),
            ),
            IconButton(
              icon: const Icon(LucideIcons.trash2, size: 16, color: AppColors.danger),
              tooltip: 'Remove shift',
              onPressed: () {
                AppHaptics.light();
                notifier.removePreviewEntry(index);
              },
            ),
          ],
        ),
      ),
    );
  }
}
