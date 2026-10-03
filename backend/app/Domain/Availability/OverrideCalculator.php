<?php

namespace App\Domain\Availability;

use App\Domain\Availability\Data\TimeInterval;
use App\Models\AvailabilityOverride;
use Carbon\Carbon;
use Illuminate\Support\Collection;

class OverrideCalculator
{
    /**
     * Applies manual overrides to derived availability intervals for a date.
     * Overrides take precedence over automatically derived availability.
     *
     * @param array<TimeInterval> $derivedIntervals
     * @param Collection<AvailabilityOverride> $overrides
     * @param string $dateStr
     * @return array<TimeInterval>
     */
    public function applyOverrides(array $derivedIntervals, Collection $overrides, string $dateStr): array
    {
        $dayOverrides = $overrides->filter(function ($override) use ($dateStr) {
            $oDate = $override->date instanceof \DateTimeInterface 
                ? $override->date->format('Y-m-d') 
                : (string)$override->date;
            return $oDate === $dateStr;
        });

        if ($dayOverrides->isEmpty()) {
            return $derivedIntervals;
        }

        // For simplicity & accuracy, if manual override exists for full day or slot, slice intervals accordingly
        $finalIntervals = $derivedIntervals;

        foreach ($dayOverrides as $override) {
            $oStart = substr((string)$override->start_time, 0, 5);
            $oEnd = substr((string)$override->end_time, 0, 5);

            if ($override->status === 'unavailable') {
                // Remove override window from available intervals
                $updated = [];
                foreach ($finalIntervals as $interval) {
                    if ($interval->status !== 'available') {
                        $updated[] = $interval;
                        continue;
                    }

                    // Check overlap
                    if ($oStart >= $interval->endAt || $oEnd <= $interval->startAt) {
                        $updated[] = $interval;
                    } else {
                        // Split interval around unavailable override
                        if ($interval->startAt < $oStart) {
                            $updated[] = new TimeInterval($interval->startAt, $oStart, 'available');
                        }
                        if ($interval->endAt > $oEnd) {
                            $updated[] = new TimeInterval($oEnd, $interval->endAt, 'available');
                        }
                    }
                }
                $finalIntervals = $updated;
            } elseif ($override->status === 'available') {
                // Insert forced available interval
                $finalIntervals[] = new TimeInterval($oStart, $oEnd, 'available', $override->reason);
            }
        }

        // Sort by start time
        usort($finalIntervals, fn($a, $b) => strcmp($a->startAt, $b->startAt));

        return $finalIntervals;
    }
}
