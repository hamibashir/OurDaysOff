<?php

namespace App\Domain\Availability;

class AvailabilityRanker
{
    /**
     * Ranks suggested meeting windows and computes Magic Hour highlights.
     *
     * @param array<string, array> $dailyCommonAvailability Keyed by date Y-m-d => common blocks
     * @param int $totalWorkingMembers Count of working members
     * @return array Array of suggested slots with human-readable reasons and is_magic_hour flag
     */
    public function rankSuggestions(array $dailyCommonAvailability, int $totalWorkingMembers): array
    {
        $suggestions = [];

        foreach ($dailyCommonAvailability as $dateStr => $blocks) {
            foreach ($blocks as $block) {
                $startMins = $this->timeToMinutes($block['start']);
                $endMins = $this->timeToMinutes($block['end']);
                $durationHours = ($endMins - $startMins) / 60.0;

                if ($durationHours < 0.5) {
                    continue; // Skip tiny windows under 30 mins
                }

                $score = $durationHours * 10;
                $reasons = [];

                if ($totalWorkingMembers > 1) {
                    $reasons[] = "Great time for all {$totalWorkingMembers} members";
                }

                $durationLabel = number_format($durationHours, 1) . " hour window";
                $reasons[] = $durationLabel;

                // Meal window checks
                if ($startMins >= 700 && $endMins <= 900) { // 11:40 - 15:00
                    $reasons[] = "Perfect for lunch";
                    $score += 15;
                } elseif ($startMins >= 1020 && $endMins <= 1320) { // 17:00 - 22:00
                    $reasons[] = "Ideal for dinner/evening meetup";
                    $score += 20;
                }

                $suggestions[] = [
                    'date' => $dateStr,
                    'start' => $block['start'],
                    'end' => $block['end'],
                    'duration_hours' => round($durationHours, 1),
                    'reasons' => $reasons,
                    'score' => $score,
                    'is_magic_hour' => false,
                ];
            }
        }

        // Sort by score descending
        usort($suggestions, fn($a, $b) => $b['score'] <=> $a['score']);

        // Flag top 2 as Magic Hour
        for ($i = 0; $i < min(2, count($suggestions)); $i++) {
            $suggestions[$i]['is_magic_hour'] = true;
        }

        return $suggestions;
    }

    private function timeToMinutes(string $time): int
    {
        if ($time === '24:00') return 1440;
        [$h, $m] = explode(':', $time);
        return ((int)$h * 60) + (int)$m;
    }
}
