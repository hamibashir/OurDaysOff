import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/text_styles.dart';
import '../../../core/utils/haptic_feedback.dart';
import '../models/match_suggestion.dart';
import '../providers/matching_grid_notifier.dart';
import 'widgets/availability_mode_toggle.dart';
import 'widgets/mode_summary_highlight_card.dart';
import 'widgets/personal_compare_tool.dart';
import 'widgets/rota_grid_matrix.dart';
import 'widgets/rota_grid_skeleton.dart';
import 'widgets/suggested_times_card.dart';

class CompareScreen extends ConsumerStatefulWidget {
  final int? initialCircleId;

  const CompareScreen({
    super.key,
    this.initialCircleId,
  });

  @override
  ConsumerState<CompareScreen> createState() => _CompareScreenState();
}

class _CompareScreenState extends ConsumerState<CompareScreen> {
  int _selectedRangeDays = 7;

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      ref.read(matchingGridProvider.notifier).loadCirclesAndAvailability(
            initialCircleId: widget.initialCircleId,
          );
    });
  }

  void _onRangeSelected(int days) {
    AppHaptics.selection();
    setState(() {
      _selectedRangeDays = days;
    });

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final endDate = today.add(Duration(days: days - 1));

    ref.read(matchingGridProvider.notifier).setDateRange(today, endDate);
  }

  Future<void> _pickCustomDateRange(DateTime currentStart, DateTime currentEnd) async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime.now().subtract(const Duration(days: 30)),
      lastDate: DateTime.now().add(const Duration(days: 120)),
      initialDateRange: DateTimeRange(start: currentStart, end: currentEnd),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppColors.primary,
              onPrimary: Colors.white,
              surface: AppColors.surface,
              onSurface: AppColors.textPrimary,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      AppHaptics.medium();
      setState(() {
        _selectedRangeDays = -1; // custom
      });
      ref.read(matchingGridProvider.notifier).setDateRange(picked.start, picked.end);
    }
  }

  void _handleProposePlan(MatchSuggestion suggestion, int? circleId) {
    AppHaptics.medium();
    final circleParam = circleId != null ? '&circle_id=$circleId' : '';
    context.push(
      '/plans?create=true$circleParam&date=${suggestion.date}&start=${suggestion.start}&end=${suggestion.end}',
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(matchingGridProvider);
    final notifier = ref.read(matchingGridProvider.notifier);

    final activeCircle = state.selectedCircle;

    return Scaffold(
      backgroundColor: AppColors.scaffoldBackground,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Schedule Matching',
              style: AppTextStyles.titleMedium,
            ),
            Text(
              activeCircle != null ? activeCircle.name : 'Rota Grid & Overlap',
              style: const TextStyle(
                fontSize: 12,
                color: AppColors.textMuted,
                fontWeight: FontWeight.normal,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(LucideIcons.refreshCw, size: 18, color: AppColors.textPrimary),
            onPressed: () {
              AppHaptics.light();
              notifier.refresh();
            },
            tooltip: 'Refresh Rota',
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () => notifier.refresh(),
        color: AppColors.primary,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Circle Picker & Range Controls Card
              _buildControlsCard(state, notifier),
              const SizedBox(height: 12),

              // Availability Mode Switcher (Days Off vs Off Time)
              AvailabilityModeToggle(
                currentMode: state.mode,
                onModeChanged: (mode) => notifier.setMode(mode),
              ),
              const SizedBox(height: 14),

              // Content based on state
              if (state.isLoading) ...[
                const RotaGridSkeleton(),
              ] else if (state.errorMessage != null) ...[
                _buildErrorCard(state.errorMessage!, notifier),
              ] else if (state.circles.isEmpty) ...[
                _buildEmptyCirclesCard(),
              ] else if (state.availabilityData != null) ...[
                // 1. Personal Compare Tool (1-on-1 member filter)
                PersonalCompareTool(
                  availableMembers: state.availabilityData!.members,
                  selectedUserIds: state.selectedMemberIds,
                  onToggleUser: notifier.toggleMember,
                  onSelectAll: notifier.selectAllMembers,
                  onDeselectAll: notifier.deselectAllMembers,
                  onRunCompare: notifier.runCustomCompare,
                  onResetToCircle: notifier.resetToFullCircle,
                  isCustomCompare: state.isCustomCompare,
                  isLoading: state.isLoading,
                  circleName: state.selectedCircle?.name,
                ),
                const SizedBox(height: 14),

                // 2. AI Ranked Meet Suggestions & Magic Hour
                SuggestedTimesCard(
                  suggestions: state.availabilityData!.suggestions,
                  onProposePlan: (s) => _handleProposePlan(s, state.selectedCircleId),
                  isLoading: state.isLoading,
                ),
                const SizedBox(height: 14),

                // 3. Mode Summary Highlight Card (Top Days Off / Overlapping Windows)
                ModeSummaryHighlightCard(
                  mode: state.mode,
                  daysOffSummary: state.availabilityData!.daysOff,
                  offTimeSummary: state.availabilityData!.offTime,
                  members: state.availabilityData!.members,
                ),
                const SizedBox(height: 14),

                // 4. 2D Rota Grid Matrix
                RotaGridMatrix(
                  members: state.availabilityData!.members,
                  mode: state.mode,
                  daysOffSummary: state.availabilityData!.daysOff,
                  offTimeSummary: state.availabilityData!.offTime,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildControlsCard(dynamic state, MatchingGridNotifier notifier) {
    final dateFormat = DateFormat('MMM d');
    final rangeText = '${dateFormat.format(state.startDate)} – ${dateFormat.format(state.endDate)}';

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Circle Selector Row
          Row(
            children: [
              const Icon(LucideIcons.users, size: 16, color: AppColors.primary),
              const SizedBox(width: 8),
              const Text(
                'Circle:',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textMuted,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: state.circles.isEmpty
                    ? const Text(
                        'No circles available',
                        style: TextStyle(fontSize: 13, color: AppColors.textSubtle),
                      )
                    : Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.scaffoldBackground,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<int>(
                            value: state.selectedCircleId,
                            isExpanded: true,
                            icon: const Icon(LucideIcons.chevronDown, size: 16),
                            style: const TextStyle(
                              color: AppColors.textPrimary,
                              fontWeight: FontWeight.w600,
                              fontSize: 13,
                            ),
                            items: state.circles.map<DropdownMenuItem<int>>((c) {
                              return DropdownMenuItem<int>(
                                value: c.id,
                                child: Text(
                                  c.name,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              );
                            }).toList(),
                            onChanged: (id) {
                              if (id != null) {
                                AppHaptics.selection();
                                notifier.selectCircle(id);
                              }
                            },
                          ),
                        ),
                      ),
              ),
            ],
          ),

          const SizedBox(height: 12),
          const Divider(color: AppColors.borderLight, height: 1),
          const SizedBox(height: 12),

          // Date Range Quick Filter Row
          Row(
            children: [
              _buildRangeChip('7 Days', 7),
              const SizedBox(width: 6),
              _buildRangeChip('14 Days', 14),
              const SizedBox(width: 6),
              _buildRangeChip('30 Days', 30),
              const Spacer(),
              // Custom Date Range Trigger
              InkWell(
                onTap: () => _pickCustomDateRange(state.startDate, state.endDate),
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                  decoration: BoxDecoration(
                    color: _selectedRangeDays == -1
                        ? AppColors.primarySurface
                        : AppColors.scaffoldBackground,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: _selectedRangeDays == -1
                          ? AppColors.primary
                          : AppColors.border,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        LucideIcons.calendar,
                        size: 13,
                        color: _selectedRangeDays == -1
                            ? AppColors.primaryDark
                            : AppColors.textMuted,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        rangeText,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          fontFamily: 'monospace',
                          color: _selectedRangeDays == -1
                              ? AppColors.primaryDark
                              : AppColors.textPrimary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRangeChip(String label, int days) {
    final isSelected = _selectedRangeDays == days;

    return InkWell(
      onTap: () => _onRangeSelected(days),
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : AppColors.scaffoldBackground,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.border,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: isSelected ? Colors.white : AppColors.textMuted,
          ),
        ),
      ),
    );
  }

  Widget _buildErrorCard(String error, MatchingGridNotifier notifier) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          const Icon(LucideIcons.alertTriangle, size: 40, color: AppColors.danger),
          const SizedBox(height: 12),
          const Text(
            'Failed to load rota matrix',
            style: AppTextStyles.titleSmall,
          ),
          const SizedBox(height: 6),
          Text(
            error,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            icon: const Icon(LucideIcons.refreshCw, size: 14),
            label: const Text('Try Again'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () {
              AppHaptics.medium();
              notifier.refresh();
            },
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyCirclesCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          const Icon(LucideIcons.users, size: 44, color: AppColors.textSubtle),
          const SizedBox(height: 14),
          const Text(
            'No Circles Found',
            style: AppTextStyles.titleMedium,
          ),
          const SizedBox(height: 6),
          const Text(
            'Create or join a circle to compare schedules and find shared days off.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 13, color: AppColors.textMuted),
          ),
          const SizedBox(height: 18),
          ElevatedButton.icon(
            icon: const Icon(LucideIcons.plus, size: 15),
            label: const Text('Go to Circles'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () {
              AppHaptics.medium();
              context.go('/circles');
            },
          ),
        ],
      ),
    );
  }
}
