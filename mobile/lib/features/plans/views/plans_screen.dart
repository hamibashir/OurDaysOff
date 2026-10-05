import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/text_styles.dart';
import '../../../core/utils/haptic_feedback.dart';
import '../models/plan_model.dart';
import '../providers/plan_providers.dart';
import 'widgets/create_plan_bottom_sheet.dart';
import 'widgets/plan_card_widget.dart';

class PlansScreen extends ConsumerStatefulWidget {
  final bool autoOpenCreate;
  final int? initialCircleId;
  final String? initialDate;
  final String? initialStart;
  final String? initialEnd;

  const PlansScreen({
    super.key,
    this.autoOpenCreate = false,
    this.initialCircleId,
    this.initialDate,
    this.initialStart,
    this.initialEnd,
  });

  @override
  ConsumerState<PlansScreen> createState() => _PlansScreenState();
}

class _PlansScreenState extends ConsumerState<PlansScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _hasOpenedAutoCreate = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);

    if (widget.autoOpenCreate && !_hasOpenedAutoCreate) {
      _hasOpenedAutoCreate = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _openCreatePlanModal();
      });
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _openCreatePlanModal() {
    AppHaptics.medium();
    CreatePlanBottomSheet.show(
      context,
      initialCircleId: widget.initialCircleId,
      initialDate: widget.initialDate,
      initialStart: widget.initialStart,
      initialEnd: widget.initialEnd,
    );
  }

  List<PlanModel> _filterUpcoming(List<PlanModel> plans) {
    final yesterday = DateTime.now().subtract(const Duration(days: 1));
    return plans.where((p) {
      if (p.isCancelled || p.isCompleted) return false;
      if (p.isPolling) return false;
      if (p.startAt == null) return false;
      return p.startAt!.isAfter(yesterday);
    }).toList();
  }

  List<PlanModel> _filterPolling(List<PlanModel> plans) {
    return plans.where((p) => p.isPolling || p.startAt == null).toList();
  }

  List<PlanModel> _filterPast(List<PlanModel> plans) {
    final yesterday = DateTime.now().subtract(const Duration(days: 1));
    return plans.where((p) {
      if (p.isCancelled || p.isCompleted) return true;
      if (p.startAt != null && p.startAt!.isBefore(yesterday)) return true;
      return false;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final plansAsync = ref.watch(plansListProvider);

    return Scaffold(
      backgroundColor: AppColors.scaffoldBackground,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        title: Row(
          children: [
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: AppColors.primarySurface,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.primaryLight.withValues(alpha: 0.3)),
              ),
              child: const Icon(LucideIcons.calendarCheck, size: 18, color: AppColors.primary),
            ),
            const SizedBox(width: 10),
            const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Meetup Plans & RSVPs',
                  style: AppTextStyles.titleMedium,
                ),
                Row(
                  children: [
                    Icon(LucideIcons.shieldCheck, size: 11, color: AppColors.primary),
                    SizedBox(width: 4),
                    Text(
                      'Circle Synced',
                      style: TextStyle(
                        fontSize: 11,
                        color: AppColors.textMuted,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(LucideIcons.refreshCw, size: 18, color: AppColors.textPrimary),
            tooltip: 'Refresh Plans',
            onPressed: () {
              AppHaptics.light();
              ref.read(plansListProvider.notifier).refresh();
            },
          ),
          IconButton(
            icon: const Icon(LucideIcons.plus, size: 22, color: AppColors.primary),
            tooltip: 'Create Plan',
            onPressed: _openCreatePlanModal,
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(48),
          child: Container(
            decoration: const BoxDecoration(
              border: Border(bottom: BorderSide(color: AppColors.borderLight)),
            ),
            child: plansAsync.when(
              data: (plans) {
                final upcoming = _filterUpcoming(plans);
                final polling = _filterPolling(plans);
                final past = _filterPast(plans);

                return TabBar(
                  controller: _tabController,
                  labelColor: AppColors.primaryDark,
                  unselectedLabelColor: AppColors.textMuted,
                  indicatorColor: AppColors.primary,
                  indicatorWeight: 3,
                  labelStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                  unselectedLabelStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
                  tabs: [
                    Tab(text: 'Upcoming (${upcoming.length})'),
                    Tab(text: 'Polling (${polling.length})'),
                    Tab(text: 'Past (${past.length})'),
                  ],
                );
              },
              loading: () => TabBar(
                controller: _tabController,
                labelColor: AppColors.primaryDark,
                unselectedLabelColor: AppColors.textMuted,
                indicatorColor: AppColors.primary,
                tabs: const [
                  Tab(text: 'Upcoming'),
                  Tab(text: 'Polling'),
                  Tab(text: 'Past'),
                ],
              ),
              error: (_, __) => TabBar(
                controller: _tabController,
                labelColor: AppColors.primaryDark,
                unselectedLabelColor: AppColors.textMuted,
                indicatorColor: AppColors.primary,
                tabs: const [
                  Tab(text: 'Upcoming'),
                  Tab(text: 'Polling'),
                  Tab(text: 'Past'),
                ],
              ),
            ),
          ),
        ),
      ),
      body: plansAsync.when(
        data: (plans) {
          final upcomingPlans = _filterUpcoming(plans);
          final pollingPlans = _filterPolling(plans);
          final pastPlans = _filterPast(plans);

          return TabBarView(
            controller: _tabController,
            children: [
              _buildPlansList(
                plans: upcomingPlans,
                emptyTitle: 'No Upcoming Meetups',
                emptySubtitle:
                    'Create a plan or browse Magic Hour windows in the Rota Matrix to propose one.',
              ),
              _buildPlansList(
                plans: pollingPlans,
                emptyTitle: 'No Active Polls',
                emptySubtitle:
                    'Start a polling plan with Date TBD to let members vote on common free times.',
              ),
              _buildPlansList(
                plans: pastPlans,
                emptyTitle: 'No Past Plans',
                emptySubtitle: 'Completed and past meetup records will be archived here.',
              ),
            ],
          );
        },
        loading: () => const Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
        error: (err, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(LucideIcons.alertTriangle, size: 40, color: AppColors.danger),
                const SizedBox(height: 12),
                const Text('Failed to load plans', style: AppTextStyles.titleMedium),
                const SizedBox(height: 6),
                Text(
                  err.toString(),
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
                ),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: () => ref.read(plansListProvider.notifier).refresh(),
                  icon: const Icon(LucideIcons.refreshCw, size: 14),
                  label: const Text('Try Again'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 2,
        icon: const Icon(LucideIcons.plus, size: 18),
        label: const Text('New Plan', style: TextStyle(fontWeight: FontWeight.bold)),
        onPressed: _openCreatePlanModal,
      ),
    );
  }

  Widget _buildPlansList({
    required List<PlanModel> plans,
    required String emptyTitle,
    required String emptySubtitle,
  }) {
    if (plans.isEmpty) {
      return RefreshIndicator(
        onRefresh: () => ref.read(plansListProvider.notifier).refresh(),
        color: AppColors.primary,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 60),
          children: [
            Container(
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppColors.border),
              ),
              child: Column(
                children: [
                  Container(
                    width: 54,
                    height: 54,
                    decoration: BoxDecoration(
                      color: AppColors.primarySurface,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.primaryLight.withValues(alpha: 0.4)),
                    ),
                    child: const Icon(LucideIcons.calendarCheck, size: 28, color: AppColors.primaryDark),
                  ),
                  const SizedBox(height: 16),
                  Text(emptyTitle, style: AppTextStyles.titleMedium),
                  const SizedBox(height: 8),
                  Text(
                    emptySubtitle,
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 12, color: AppColors.textMuted, height: 1.4),
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton.icon(
                    onPressed: _openCreatePlanModal,
                    icon: const Icon(LucideIcons.plus, size: 14),
                    label: const Text('Create Meetup Plan'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      elevation: 0,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () => ref.read(plansListProvider.notifier).refresh(),
      color: AppColors.primary,
      child: ListView.builder(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 80),
        itemCount: plans.length,
        itemBuilder: (context, index) {
          final plan = plans[index];
          return PlanCardWidget(
            plan: plan,
            onTap: (p) {
              context.push('/plans/${p.id}');
            },
            onRsvpChange: (planId, rsvp) {
              ref.read(plansListProvider.notifier).updateRsvp(planId, rsvp);
            },
          );
        },
      ),
    );
  }
}
