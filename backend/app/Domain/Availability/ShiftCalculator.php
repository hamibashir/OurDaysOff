<?php

namespace App\Domain\Availability;

use App\Domain\Availability\Data\TimeInterval;
use App\Models\ScheduleEntry;
use Carbon\Carbon;
use Illuminate\Support\Collection;

class ShiftCalculator
{
    /**
     * Converts schedule entries into absolute busy TimeInterval objects with Carbon timestamps.
     * Handles overnight shifts (e.g. 22:00 to 06:00 next day).
     *
     * @param Collection<ScheduleEntry> $entries
     * @return array<array{start: Carbon, end: Carbon, entry: ScheduleEntry}>
     */
    public function calculateBusyBlocks(Collection $entries): array
    {
        $busyBlocks = [];

        foreach ($entries as $entry) {
            // Off days do not create busy blocks
            if ($entry->entry_type === 'off') {
                continue;
            }

            $dateStr = $entry->date instanceof \DateTimeInterface 
                ? $entry->date->format('Y-m-d') 
                : (string)$entry->date;

            $start = Carbon::parse("{$dateStr} {$entry->start_time}");
            $end = Carbon::parse("{$dateStr} {$entry->end_time}");

            // Overnight shift check: if end time is before or equal to start time, or flagged is_overnight
            if ($entry->is_overnight || $end->lessThanOrEqualTo($start)) {
                $end->addDay();
            }

            $busyBlocks[] = [
                'start' => $start,
                'end' => $end,
                'entry' => $entry,
            ];
        }

        return $busyBlocks;
    }
}
