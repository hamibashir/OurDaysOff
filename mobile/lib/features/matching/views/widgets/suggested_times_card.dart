import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/text_styles.dart';
import '../../../../core/utils/haptic_feedback.dart';
import '../../models/match_suggestion.dart';

class SuggestedTimesCard extends StatelessWidget {
  final List<MatchSuggestion> suggestions;
  final void Function(MatchSuggestion suggestion)? onProposePlan;
  final bool isLoading;

  const SuggestedTimesCard({
    super.key,
    required this.suggestions,
    this.onProposePlan,
    this.isLoading = false,
  });

  String _formatDisplayDate(String dateStr) {
    try {
      final parsed = DateTime.parse(dateStr);
      return DateFormat('EEE, d MMM').format(parsed);
    } catch (_) {
      return dateStr;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              const Icon(LucideIcons.sparkles, size: 18, color: AppColors.primary),
              const SizedBox(width: 8),
              const Text(
                'Ranked Meet Suggestions',
                style: AppTextStyles.titleSmall,
              ),
              const Spacer(),
              if (suggestions.isNotEmpty)
                Text(
                  '${suggestions.length} slots',
                  style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
                ),
            ],
          ),
          const SizedBox(height: 2),
          const Text(
            'Top derived availability overlaps evaluated for maximum participants and meal windows.',
            style: TextStyle(fontSize: 11, color: AppColors.textMuted),
          ),
          const SizedBox(height: 14),

          if (suggestions.isEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
              decoration: BoxDecoration(
                color: AppColors.scaffoldBackground,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.borderLight),
              ),
              child: const Column(
                children: [
                  Icon(LucideIcons.clockAlert, size: 28, color: AppColors.textSubtle),
                  SizedBox(height: 8),
                  Text(
                    'No overlapping meetup windows found for the selected dates.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 12, color: AppColors.textMuted),
                  ),
                ],
              ),
            )
          else
            ...suggestions.map((suggestion) => _buildSuggestionTile(context, suggestion)),
        ],
      ),
    );
  }

  Widget _buildSuggestionTile(BuildContext context, MatchSuggestion suggestion) {
    final isMagic = suggestion.isMagicHour;
    final formattedDate = _formatDisplayDate(suggestion.date);

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isMagic ? const Color(0x28D7D982) : AppColors.scaffoldBackground,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isMagic ? const Color(0x80D7D982) : AppColors.border,
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top bar: Date & Magic Hour Badge
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                formattedDate,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              if (isMagic)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: const Color(0x35AE82D9),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0x66AE82D9)),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(LucideIcons.sparkles, size: 11, color: Color(0xFF6A3E94)),
                      SizedBox(width: 4),
                      Text(
                        'Magic Hour',
                        style: TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF6A3E94),
                          letterSpacing: 0.2,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),

          const SizedBox(height: 8),

          // Time Range & Duration
          Row(
            children: [
              const Icon(LucideIcons.clock, size: 14, color: AppColors.primary),
              const SizedBox(width: 6),
              Text(
                '${suggestion.start} — ${suggestion.end}',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  fontFamily: 'monospace',
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(width: 6),
              Text(
                '(${suggestion.durationHours} hrs)',
                style: const TextStyle(
                  fontSize: 11,
                  color: AppColors.textMuted,
                  fontFamily: 'monospace',
                ),
              ),
            ],
          ),

          // Reasons Chips
          if (suggestion.reasons.isNotEmpty) ...[
            const SizedBox(height: 8),
            Wrap(
              spacing: 6,
              runSpacing: 4,
              children: suggestion.reasons.map((reason) {
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Text(
                    reason,
                    style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w500,
                      color: AppColors.textPrimary,
                    ),
                  ),
                );
              }).toList(),
            ),
          ],

          const SizedBox(height: 10),

          // Propose Plan Button
          if (onProposePlan != null)
            Align(
              alignment: Alignment.centerRight,
              child: ElevatedButton.icon(
                icon: const Icon(LucideIcons.arrowRight, size: 13),
                label: const Text(
                  'Propose Plan',
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFD99E82),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  elevation: 0,
                ),
                onPressed: () {
                  AppHaptics.medium();
                  onProposePlan!(suggestion);
                },
              ),
            ),
        ],
      ),
    );
  }
}
