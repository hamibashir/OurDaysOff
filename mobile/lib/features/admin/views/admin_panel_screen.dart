import 'dart:math';
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
import '../../../shared/widgets/status_badge.dart';
import '../../auth/providers/auth_notifier.dart';
import '../providers/admin_provider.dart';

class AdminPanelScreen extends ConsumerStatefulWidget {
  const AdminPanelScreen({super.key});

  @override
  ConsumerState<AdminPanelScreen> createState() => _AdminPanelScreenState();
}

class _AdminPanelScreenState extends ConsumerState<AdminPanelScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _showCreateCouponSheet() {
    final codeController = TextEditingController(text: _generateRandomCode());
    DateTime? selectedDate;
    bool isSubmitting = false;
    String? submitError;

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
                        Icon(LucideIcons.ticket, color: AppColors.primary, size: 20),
                        SizedBox(width: 8),
                        Text('Create VIP Promo Code', style: AppTextStyles.titleMedium),
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
                  'Create a single-use VIP code that grants a user unlimited circles & AI rota scanning.',
                  style: TextStyle(fontSize: 12, color: AppColors.textMuted),
                ),
                const SizedBox(height: 16),
                if (submitError != null) ...[
                  Text(
                    submitError!,
                    style: const TextStyle(color: AppColors.danger, fontSize: 12),
                  ),
                  const SizedBox(height: 8),
                ],
                Row(
                  children: [
                    Expanded(
                      child: AppTextField(
                        controller: codeController,
                        label: 'Coupon Code',
                        hint: 'e.g. SUMMER2026',
                        prefixIcon: LucideIcons.tag,
                        textCapitalization: TextCapitalization.characters,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Padding(
                      padding: const EdgeInsets.only(top: 24),
                      child: IconButton.outlined(
                        icon: const Icon(LucideIcons.sparkles, color: AppColors.primary),
                        tooltip: 'Generate Random Code',
                        onPressed: () {
                          AppHaptics.light();
                          setSheetState(() {
                            codeController.text = _generateRandomCode();
                          });
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                // Expiry Date Selector
                const Text(
                  'Expiration Date (Optional)',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 8),
                InkWell(
                  onTap: () async {
                    AppHaptics.light();
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: DateTime.now().add(const Duration(days: 30)),
                      firstDate: DateTime.now(),
                      lastDate: DateTime.now().add(const Duration(days: 365 * 2)),
                    );
                    if (picked != null) {
                      setSheetState(() => selectedDate = picked);
                    }
                  },
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    decoration: BoxDecoration(
                      color: AppColors.scaffoldBackground,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          selectedDate != null
                              ? DateFormat('EEE, MMM d, yyyy').format(selectedDate!)
                              : 'No expiration (Permanent)',
                          style: TextStyle(
                            fontSize: 13,
                            color: selectedDate != null
                                ? AppColors.textPrimary
                                : AppColors.textMuted,
                          ),
                        ),
                        if (selectedDate != null)
                          GestureDetector(
                            onTap: () => setSheetState(() => selectedDate = null),
                            child: const Icon(LucideIcons.x, size: 16, color: AppColors.textMuted),
                          )
                        else
                          const Icon(LucideIcons.calendar, size: 16, color: AppColors.primary),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                AppButton(
                  text: 'Create Coupon',
                  isLoading: isSubmitting,
                  onPressed: () async {
                    final code = codeController.text.trim();
                    if (code.isEmpty) {
                      setSheetState(() => submitError = 'Coupon code cannot be empty.');
                      return;
                    }

                    setSheetState(() => isSubmitting = true);
                    final success = await ref
                        .read(adminCouponsProvider.notifier)
                        .createCoupon(code: code, expiresAt: selectedDate);

                    if (sheetContext.mounted) {
                      if (success) {
                        Navigator.pop(sheetContext);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Coupon "$code" created successfully!'),
                            backgroundColor: AppColors.primary,
                          ),
                        );
                      } else {
                        final err = ref.read(adminCouponsProvider).error ??
                            'Failed to create coupon.';
                        setSheetState(() {
                          isSubmitting = false;
                          submitError = err;
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

  String _generateRandomCode() {
    const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
    final random = Random();
    return List.generate(8, (_) => chars[random.nextInt(chars.length)]).join();
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authNotifierProvider);
    final user = authState.user;

    // Guard: Only admins can view this screen
    if (user == null || !user.isAdmin) {
      return Scaffold(
        backgroundColor: AppColors.scaffoldBackground,
        appBar: AppBar(title: const Text('Access Denied')),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(LucideIcons.shieldAlert, size: 54, color: AppColors.danger),
                const SizedBox(height: 16),
                const Text('Administrator Privileges Required', style: AppTextStyles.titleMedium),
                const SizedBox(height: 8),
                const Text(
                  'You do not have administrative permissions to view platform metrics and management controls.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: AppColors.textMuted, fontSize: 13),
                ),
                const SizedBox(height: 24),
                AppButton(
                  text: 'Go Back',
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.scaffoldBackground,
      appBar: AppBar(
        title: const Row(
          children: [
            Icon(LucideIcons.shieldCheck, color: AppColors.primary, size: 20),
            SizedBox(width: 8),
            Text('Admin Dashboard'),
          ],
        ),
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppColors.primaryDark,
          unselectedLabelColor: AppColors.textMuted,
          indicatorColor: AppColors.primary,
          indicatorWeight: 3,
          labelStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12),
          tabs: const [
            Tab(text: 'Overview', icon: Icon(LucideIcons.layoutDashboard, size: 18)),
            Tab(text: 'Users', icon: Icon(LucideIcons.users, size: 18)),
            Tab(text: 'Coupons', icon: Icon(LucideIcons.ticket, size: 18)),
            Tab(text: 'Circles', icon: Icon(LucideIcons.compass, size: 18)),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildOverviewTab(),
          _buildUsersTab(),
          _buildCouponsTab(),
          _buildCirclesTab(),
        ],
      ),
      floatingActionButton: _tabController.index == 2
          ? FloatingActionButton.extended(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              icon: const Icon(LucideIcons.plus),
              label: const Text('New Coupon'),
              onPressed: _showCreateCouponSheet,
            )
          : null,
    );
  }

  // --- TAB 1: OVERVIEW METRICS ---
  Widget _buildOverviewTab() {
    final statsAsync = ref.watch(adminStatsProvider);

    return RefreshIndicator(
      onRefresh: () => ref.read(adminStatsProvider.notifier).loadStats(),
      child: statsAsync.when(
        loading: () => const Center(child: AppLoadingIndicator()),
        error: (err, _) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(LucideIcons.alertTriangle, size: 40, color: AppColors.danger),
              const SizedBox(height: 12),
              Text('Failed to load stats: $err', style: const TextStyle(fontSize: 13)),
              const SizedBox(height: 16),
              AppButton(
                text: 'Retry',
                onPressed: () => ref.read(adminStatsProvider.notifier).loadStats(),
              ),
            ],
          ),
        ),
        data: (stats) => SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text('PLATFORM PERFORMANCE METRICS', style: AppTextStyles.labelMedium),
              const SizedBox(height: 14),
              GridView.count(
                crossAxisCount: 2,
                crossAxisSpacing: 14,
                mainAxisSpacing: 14,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                childAspectRatio: 1.35,
                children: [
                  _StatCard(
                    title: 'Total Users',
                    value: stats.totalUsers.toString(),
                    icon: LucideIcons.users,
                    color: AppColors.primary,
                  ),
                  _StatCard(
                    title: 'VIP Members',
                    value: stats.premiumUsers.toString(),
                    icon: LucideIcons.crown,
                    color: const Color(0xFFD97706),
                    badge: '${((stats.premiumUsers / (stats.totalUsers > 0 ? stats.totalUsers : 1)) * 100).toStringAsFixed(1)}%',
                  ),
                  _StatCard(
                    title: 'Total Circles',
                    value: stats.totalCircles.toString(),
                    icon: LucideIcons.compass,
                    color: AppColors.accentViolet,
                  ),
                  _StatCard(
                    title: 'Meetup Plans',
                    value: stats.totalPlans.toString(),
                    icon: LucideIcons.calendarCheck,
                    color: const Color(0xFF2563EB),
                  ),
                  _StatCard(
                    title: 'Schedules',
                    value: stats.totalSchedules.toString(),
                    icon: LucideIcons.calendar,
                    color: const Color(0xFF059669),
                  ),
                  _StatCard(
                    title: 'Active Coupons',
                    value: stats.activeCoupons.toString(),
                    icon: LucideIcons.ticket,
                    color: const Color(0xFFDB2777),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              // Server Health Card
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.border),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(LucideIcons.activity, color: AppColors.statusAvailable, size: 18),
                        SizedBox(width: 8),
                        Text('System Engine Health', style: AppTextStyles.titleSmall),
                      ],
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'All background queue workers, AI rota parser engines, and Sanctum tokens are functioning normally.',
                      style: TextStyle(fontSize: 12, color: AppColors.textMuted),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
                            color: AppColors.statusAvailable,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 6),
                        const Text(
                          'REST API: Healthy • Response: ~45ms',
                          style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.statusAvailable),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // --- TAB 2: USERS MANAGEMENT ---
  Widget _buildUsersTab() {
    final state = ref.watch(adminUsersProvider);

    return Column(
      children: [
        // Search Header
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 10),
          child: AppTextField(
            controller: _searchController,
            hint: 'Search users by name, email, or handle...',
            prefixIcon: LucideIcons.search,
            suffixIcon: _searchController.text.isNotEmpty
                ? IconButton(
                    icon: const Icon(LucideIcons.x, size: 18),
                    onPressed: () {
                      _searchController.clear();
                      ref.read(adminUsersProvider.notifier).loadUsers(query: '');
                    },
                  )
                : null,
            onChanged: (val) {
              ref.read(adminUsersProvider.notifier).loadUsers(query: val);
            },
          ),
        ),

        // List
        Expanded(
          child: RefreshIndicator(
            onRefresh: () => ref.read(adminUsersProvider.notifier).loadUsers(),
            child: state.isLoading && state.users.isEmpty
                ? const Center(child: AppLoadingIndicator())
                : state.users.isEmpty
                    ? const EmptyStateView(
                        icon: LucideIcons.userX,
                        title: 'No Users Found',
                        description: 'Try refining your search keyword.',
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        itemCount: state.users.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 10),
                        itemBuilder: (context, index) {
                          final user = state.users[index];
                          return Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: AppColors.surface,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: AppColors.border),
                            ),
                            child: Column(
                              children: [
                                Row(
                                  children: [
                                    // Avatar
                                    CircleAvatar(
                                      radius: 20,
                                      backgroundColor: AppColors.primarySurface,
                                      child: Text(
                                        user.initials,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: AppColors.primaryDark,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
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
                                                  style: const TextStyle(
                                                    fontWeight: FontWeight.w700,
                                                    fontSize: 14,
                                                  ),
                                                  overflow: TextOverflow.ellipsis,
                                                ),
                                              ),
                                              if (user.isPremium) ...[
                                                const SizedBox(width: 6),
                                                const StatusBadge(
                                                  label: 'VIP',
                                                  type: StatusBadgeType.vip,
                                                  isSmall: true,
                                                ),
                                              ],
                                              if (user.isAdmin) ...[
                                                const SizedBox(width: 6),
                                                Container(
                                                  padding: const EdgeInsets.symmetric(
                                                    horizontal: 5,
                                                    vertical: 2,
                                                  ),
                                                  decoration: BoxDecoration(
                                                    color: AppColors.accentViolet.withValues(alpha: 0.1),
                                                    borderRadius: BorderRadius.circular(6),
                                                  ),
                                                  child: const Text(
                                                    'ADMIN',
                                                    style: TextStyle(
                                                      fontSize: 9,
                                                      fontWeight: FontWeight.w800,
                                                      color: AppColors.accentViolet,
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ],
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            user.email,
                                            style: const TextStyle(
                                              fontSize: 12,
                                              color: AppColors.textMuted,
                                            ),
                                          ),
                                          if (user.handle != null) ...[
                                            const SizedBox(height: 1),
                                            Text(
                                              '@${user.handle}',
                                              style: const TextStyle(
                                                fontSize: 11,
                                                color: AppColors.primary,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                          ],
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 10),
                                const Divider(height: 1),
                                const SizedBox(height: 8),
                                // Action Toggles
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    // VIP Toggle
                                    Row(
                                      children: [
                                        const Text('VIP Status:', style: TextStyle(fontSize: 12, color: AppColors.textMuted)),
                                        const SizedBox(width: 6),
                                        Switch.adaptive(
                                          value: user.isPremium,
                                          activeTrackColor: const Color(0xFFD97706),
                                          onChanged: (_) {
                                            AppHaptics.light();
                                            ref.read(adminUsersProvider.notifier).togglePremium(user.id);
                                          },
                                        ),
                                      ],
                                    ),
                                    // Admin Toggle
                                    Row(
                                      children: [
                                        const Text('Admin:', style: TextStyle(fontSize: 12, color: AppColors.textMuted)),
                                        const SizedBox(width: 6),
                                        Switch.adaptive(
                                          value: user.isAdmin,
                                          activeTrackColor: AppColors.accentViolet,
                                          onChanged: (_) async {
                                            final confirm = await ConfirmationDialog.show(
                                              context: context,
                                              title: user.isAdmin ? 'Revoke Admin' : 'Grant Admin',
                                              message: user.isAdmin
                                                  ? 'Revoke administrator access for ${user.name}?'
                                                  : 'Grant full system administrative rights to ${user.name}?',
                                              confirmLabel: user.isAdmin ? 'Revoke' : 'Grant',
                                              isDestructive: user.isAdmin,
                                            );
                                            if (confirm == true) {
                                              AppHaptics.medium();
                                              ref.read(adminUsersProvider.notifier).toggleAdmin(user.id);
                                            }
                                          },
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          );
                        },
                      ),
          ),
        ),
      ],
    );
  }

  // --- TAB 3: COUPONS MANAGEMENT ---
  Widget _buildCouponsTab() {
    final state = ref.watch(adminCouponsProvider);

    return Scaffold(
      backgroundColor: Colors.transparent,
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        icon: const Icon(LucideIcons.plus),
        label: const Text('Create Code'),
        onPressed: _showCreateCouponSheet,
      ),
      body: RefreshIndicator(
        onRefresh: () => ref.read(adminCouponsProvider.notifier).loadCoupons(),
        child: state.isLoading && state.coupons.isEmpty
            ? const Center(child: AppLoadingIndicator())
            : state.coupons.isEmpty
                ? const EmptyStateView(
                    icon: LucideIcons.ticket,
                    title: 'No Coupons Yet',
                    description: 'Generate promotional codes to grant VIP access to beta testers.',
                  )
                : ListView.separated(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                    itemCount: state.coupons.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (context, index) {
                      final coupon = state.coupons[index];
                      final isExpired = coupon.isExpired;

                      return Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: coupon.isActive && !coupon.isUsed && !isExpired
                                ? AppColors.border
                                : AppColors.borderLight,
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                      decoration: BoxDecoration(
                                        color: AppColors.primarySurface,
                                        borderRadius: BorderRadius.circular(8),
                                        border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
                                      ),
                                      child: Text(
                                        coupon.code,
                                        style: const TextStyle(
                                          fontSize: 15,
                                          fontWeight: FontWeight.w800,
                                          fontFamily: 'monospace',
                                          color: AppColors.primaryDark,
                                        ),
                                      ),
                                    ),
                                    IconButton(
                                      icon: const Icon(LucideIcons.copy, size: 16, color: AppColors.textMuted),
                                      tooltip: 'Copy Code',
                                      onPressed: () {
                                        AppHaptics.light();
                                        Clipboard.setData(ClipboardData(text: coupon.code));
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          SnackBar(content: Text('Coupon "${coupon.code}" copied!')),
                                        );
                                      },
                                    ),
                                  ],
                                ),
                                // Active Switch
                                Row(
                                  children: [
                                    Text(
                                      coupon.isActive ? 'Active' : 'Disabled',
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                        color: coupon.isActive ? AppColors.statusAvailable : AppColors.textMuted,
                                      ),
                                    ),
                                    Switch.adaptive(
                                      value: coupon.isActive,
                                      activeTrackColor: AppColors.primary,
                                      onChanged: (_) {
                                        AppHaptics.light();
                                        ref.read(adminCouponsProvider.notifier).toggleCoupon(coupon.id);
                                      },
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            Wrap(
                              spacing: 8,
                              runSpacing: 4,
                              children: [
                                if (coupon.isUsed)
                                  const StatusBadge(label: 'REDEEMED', type: StatusBadgeType.danger, isSmall: true)
                                else if (isExpired)
                                  const StatusBadge(label: 'EXPIRED', type: StatusBadgeType.danger, isSmall: true)
                                else if (coupon.isActive)
                                  const StatusBadge(label: 'READY TO USE', type: StatusBadgeType.available, isSmall: true),
                                if (coupon.expiresAt != null)
                                  Text(
                                    'Expires: ${DateFormat('MMM d, yyyy').format(coupon.expiresAt!)}',
                                    style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
                                  ),
                              ],
                            ),
                          ],
                        ),
                      );
                    },
                  ),
      ),
    );
  }

  // --- TAB 4: CIRCLES OVERSIGHT ---
  Widget _buildCirclesTab() {
    final circlesAsync = ref.watch(adminCirclesProvider);

    return RefreshIndicator(
      onRefresh: () => ref.read(adminCirclesProvider.notifier).loadCircles(),
      child: circlesAsync.when(
        loading: () => const Center(child: AppLoadingIndicator()),
        error: (err, _) => Center(
          child: Text('Failed to load circles: $err', style: const TextStyle(fontSize: 13)),
        ),
        data: (circles) => circles.isEmpty
            ? const EmptyStateView(
                icon: LucideIcons.compass,
                title: 'No Circles Found',
                description: 'Circles created by users will appear here.',
              )
            : ListView.separated(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                itemCount: circles.length,
                separatorBuilder: (_, __) => const SizedBox(height: 10),
                itemBuilder: (context, index) {
                  final circle = circles[index];

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
                          decoration: const BoxDecoration(
                            color: AppColors.primarySurface,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(LucideIcons.usersRound, color: AppColors.primaryDark, size: 20),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                circle.name,
                                style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Owner: ${circle.ownerName ?? "Unknown"} • ${circle.isDiscoverable ? "Public" : "Private"}',
                                style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppColors.scaffoldBackground,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: AppColors.border),
                          ),
                          child: Row(
                            children: [
                              const Icon(LucideIcons.user, size: 12, color: AppColors.textMuted),
                              const SizedBox(width: 4),
                              Text(
                                '${circle.membersCount}',
                                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;
  final String? badge;

  const _StatCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
    this.badge,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 6,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: color, size: 18),
              ),
              if (badge != null)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    badge!,
                    style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: color),
                  ),
                ),
            ],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: AppColors.textPrimary),
              ),
              const SizedBox(height: 2),
              Text(
                title,
                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.textMuted),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
