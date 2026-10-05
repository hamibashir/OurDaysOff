import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/utils/haptic_feedback.dart';
import '../../../shared/widgets/app_button.dart';
import '../../../shared/widgets/empty_state_view.dart';
import '../../../shared/widgets/loading_indicator.dart';
import '../providers/circles_notifier.dart';
import 'widgets/circle_card.dart';
import 'widgets/create_circle_modal.dart';
import 'widgets/join_circle_modal.dart';

class CirclesScreen extends ConsumerStatefulWidget {
  const CirclesScreen({super.key});

  @override
  ConsumerState<CirclesScreen> createState() => _CirclesScreenState();
}

class _CirclesScreenState extends ConsumerState<CirclesScreen> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _openCreateModal() {
    AppHaptics.selection();
    CreateCircleModal.show(context);
  }

  void _openJoinModal() {
    AppHaptics.selection();
    JoinCircleModal.show(context);
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(circlesNotifierProvider);
    final notifier = ref.read(circlesNotifierProvider.notifier);
    final filtered = state.filteredCircles;

    return Scaffold(
      backgroundColor: AppColors.scaffoldBackground,
      appBar: AppBar(
        title: const Text('My Circles'),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(LucideIcons.link, size: 20),
            tooltip: 'Join with Code',
            onPressed: _openJoinModal,
          ),
          IconButton(
            icon: const Icon(LucideIcons.plus, size: 22),
            tooltip: 'Create Circle',
            onPressed: _openCreateModal,
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () => notifier.loadCircles(),
        color: AppColors.primary,
        child: Column(
          children: [
            // Search Bar
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              child: Container(
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.border),
                ),
                child: TextField(
                  controller: _searchController,
                  onChanged: (val) => notifier.setSearchQuery(val),
                  decoration: InputDecoration(
                    hintText: 'Search circles by name or @handle...',
                    hintStyle: const TextStyle(fontSize: 13, color: AppColors.textSubtle),
                    prefixIcon: const Icon(LucideIcons.search, size: 18, color: AppColors.textMuted),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(LucideIcons.x, size: 16, color: AppColors.textMuted),
                            onPressed: () {
                              _searchController.clear();
                              notifier.setSearchQuery('');
                            },
                          )
                        : null,
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  ),
                ),
              ),
            ),

            // Content
            Expanded(
              child: Builder(
                builder: (context) {
                  if (state.isLoading && state.circles.isEmpty) {
                    return const Center(child: AppLoadingIndicator());
                  }

                  if (state.errorMessage != null && state.circles.isEmpty) {
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(LucideIcons.alertCircle, size: 36, color: AppColors.danger),
                            const SizedBox(height: 12),
                            Text(
                              state.errorMessage!,
                              textAlign: TextAlign.center,
                              style: const TextStyle(fontSize: 13, color: AppColors.textMuted),
                            ),
                            const SizedBox(height: 16),
                            AppButton(
                              text: 'Retry',
                              size: AppButtonSize.small,
                              fullWidth: false,
                              onPressed: () => notifier.loadCircles(),
                            ),
                          ],
                        ),
                      ),
                    );
                  }

                  if (state.circles.isEmpty) {
                    return EmptyStateView(
                      icon: LucideIcons.users,
                      title: 'No Circles Yet',
                      description:
                          'Join an existing circle with an invite code or create a new circle to coordinate schedules with your crew.',
                      actionText: 'Create a Circle',
                      onAction: _openCreateModal,
                      secondaryActionText: 'Join with Code',
                      onSecondaryAction: _openJoinModal,
                    );
                  }

                  if (filtered.isEmpty) {
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(LucideIcons.searchX, size: 36, color: AppColors.textSubtle),
                            const SizedBox(height: 12),
                            Text(
                              'No circles found matching "${_searchController.text}"',
                              textAlign: TextAlign.center,
                              style: const TextStyle(fontSize: 13, color: AppColors.textMuted),
                            ),
                            const SizedBox(height: 12),
                            TextButton(
                              onPressed: () {
                                _searchController.clear();
                                notifier.setSearchQuery('');
                              },
                              child: const Text('Clear search'),
                            ),
                          ],
                        ),
                      ),
                    );
                  }

                  return ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                    itemCount: filtered.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (context, index) {
                      final circle = filtered[index];
                      return CircleCard(
                        circle: circle,
                        onTap: () {
                          // Will navigate to Circle Details in Step 5.3
                          context.push('/circles/${circle.id}');
                        },
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
