<?php

namespace App\Domain\Availability;

use Carbon\Carbon;

class RecoveryCalculator
{
    /**
     * Appends forced post-shift recovery blocks for overnight or night shifts.
     *
     * @param array<array{start: Carbon, end: Carbon, entry: mixed}> $busyBlocks
     * @param int $recoveryHours
     * @return array<array{start: Carbon, end: Carbon, entry: mixed, is_recovery: bool}>
     */
    public function calculateRecoveryBlocks(array $busyBlocks, int $recoveryHours): array
    {
        if ($recoveryHours <= 0) {
            return $busyBlocks;
        }

        $allBlocks = $busyBlocks;

        foreach ($busyBlocks as $block) {
            $isOvernight = isset($block['entry']) && ($block['entry']->is_overnight || $block['end']->day !== $block['start']->day);
            $isNightShift = $block['start']->hour >= 20 || $block['start']->hour <= 4;

            if ($isOvernight || $isNightShift) {
                $recoveryStart = clone $block['end'];
                $recoveryEnd = (clone $block['end'])->addHours($recoveryHours);

                $allBlocks[] = [
                    'start' => $recoveryStart,
                    'end' => $recoveryEnd,
                    'entry' => $block['entry'],
                    'is_recovery' => true,
                ];
            }
        }

        return $allBlocks;
    }
}
