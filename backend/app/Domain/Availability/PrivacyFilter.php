<?php

namespace App\Domain\Availability;

use App\Domain\Availability\Data\TimeInterval;

class PrivacyFilter
{
    /**
     * Filters availability blocks strictly according to circle member visibility permissions.
     *
     * @param array<string, array<array{start: string, end: string, status: string, reason?: string, shift_type?: string}>> $availability
     * @param string $visibilityLevel ('free_busy' | 'shifts' | 'details')
     * @return array<string, array<array>>
     */
    public function filterAvailability(array $availability, string $visibilityLevel): array
    {
        $filtered = [];

        foreach ($availability as $dateStr => $blocks) {
            $filtered[$dateStr] = array_map(function ($block) use ($visibilityLevel) {
                if ($visibilityLevel === 'free_busy') {
                    // Strips label, notes, reason, and specific shift names completely
                    return [
                        'start' => $block['start'],
                        'end' => $block['end'],
                        'status' => $block['status'],
                    ];
                }

                if ($visibilityLevel === 'shifts') {
                    // Includes shift status/category but strips private notes
                    return [
                        'start' => $block['start'],
                        'end' => $block['end'],
                        'status' => $block['status'],
                        'shift_type' => $block['shift_type'] ?? 'work',
                    ];
                }

                // Full details level
                return $block;
            }, $blocks);
        }

        return $filtered;
    }
}
