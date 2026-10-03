<?php

namespace App\Domain\Availability;

use App\Domain\Availability\Data\TimeInterval;
use Carbon\Carbon;
use Illuminate\Support\Collection;

class IntervalCalculator
{
    /**
     * Merges overlapping or adjacent busy blocks into contiguous busy intervals.
     *
     * @param array<array{start: Carbon, end: Carbon}> $blocks
     * @return array<array{start: Carbon, end: Carbon}>
     */
    public function mergeIntervals(array $blocks): array
    {
        if (empty($blocks)) {
            return [];
        }

        // Sort by start time
        usort($blocks, fn($a, $b) => $a['start']->timestamp <=> $b['start']->timestamp);

        $merged = [$blocks[0]];

        for ($i = 1; $i < count($blocks); $i++) {
            $last = &$merged[count($merged) - 1];
            $current = $blocks[$i];

            if ($current['start']->lessThanOrEqualTo($last['end'])) {
                if ($current['end']->greaterThan($last['end'])) {
                    $last['end'] = $current['end'];
                }
            } else {
                $merged[] = $current;
            }
        }

        return $merged;
    }

    /**
     * Inverts busy intervals across a day range [dayStart, dayEnd] to compute available intervals.
     *
     * @param Carbon $dayStart
     * @param Carbon $dayEnd
     * @param array<array{start: Carbon, end: Carbon}> $busyBlocks
     * @return array<TimeInterval>
     */
    public function deriveAvailableBlocks(Carbon $dayStart, Carbon $dayEnd, array $busyBlocks): array
    {
        $mergedBusy = $this->mergeIntervals($busyBlocks);
        $available = [];
        $currentPointer = clone $dayStart;

        foreach ($mergedBusy as $busy) {
            // Clip busy block to current day window
            $bStart = $busy['start']->lessThan($dayStart) ? clone $dayStart : clone $busy['start'];
            $bEnd = $busy['end']->greaterThan($dayEnd) ? clone $dayEnd : clone $busy['end'];

            if ($bStart->greaterThan($dayEnd) || $bEnd->lessThan($dayStart)) {
                continue;
            }

            if ($currentPointer->lessThan($bStart)) {
                $available[] = new TimeInterval(
                    startAt: $currentPointer->format('H:i'),
                    endAt: $bStart->format('H:i'),
                    status: 'available'
                );
            }

            if ($bEnd->greaterThan($currentPointer)) {
                $currentPointer = clone $bEnd;
            }
        }

        if ($currentPointer->lessThan($dayEnd)) {
            $endStr = $dayEnd->format('H:i');
            if ($endStr === '00:00') {
                $endStr = '24:00';
            }
            $available[] = new TimeInterval(
                startAt: $currentPointer->format('H:i'),
                endAt: $endStr,
                status: 'available'
            );
        }

        return $available;
    }
}
