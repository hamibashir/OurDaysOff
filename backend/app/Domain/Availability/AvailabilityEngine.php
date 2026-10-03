<?php

namespace App\Domain\Availability;

use App\Domain\Availability\Data\TimeInterval;
use App\Domain\Availability\Data\UserAvailabilityContext;
use Carbon\Carbon;
use Carbon\CarbonPeriod;

class AvailabilityEngine
{
    public function __construct(
        private readonly ShiftCalculator $shiftCalculator = new ShiftCalculator(),
        private readonly BufferCalculator $bufferCalculator = new BufferCalculator(),
        private readonly RecoveryCalculator $recoveryCalculator = new RecoveryCalculator(),
        private readonly IntervalCalculator $intervalCalculator = new IntervalCalculator(),
        private readonly OverrideCalculator $overrideCalculator = new OverrideCalculator()
    ) {}

    /**
     * Calculates derived daily availability for a user context.
     *
     * @param UserAvailabilityContext $context
     * @return array<string, array<TimeInterval>>
     */
    public function calculate(UserAvailabilityContext $context): array
    {
        // 1. Convert schedules into initial busy blocks
        $busyBlocks = $this->shiftCalculator->calculateBusyBlocks($context->scheduleEntries);

        // 2. Apply travel buffers
        $busyBlocks = $this->bufferCalculator->applyBuffers(
            $busyBlocks,
            $context->travelBufferBeforeMinutes,
            $context->travelBufferAfterMinutes
        );

        // 3. Apply post-shift recovery blocks
        $busyBlocks = $this->recoveryCalculator->calculateRecoveryBlocks(
            $busyBlocks,
            $context->recoveryHoursAfterNightShift
        );

        // 4. Iterate day by day in range and invert busy blocks
        $period = CarbonPeriod::create($context->startDate, $context->endDate);
        $result = [];

        foreach ($period as $date) {
            $dateStr = $date->format('Y-m-d');
            $dayStart = Carbon::parse("{$dateStr} 00:00:00");
            $dayEnd = Carbon::parse("{$dateStr} 24:00:00");

            // Filter busy blocks intersecting this date
            $dayBusy = array_filter($busyBlocks, function ($b) use ($dayStart, $dayEnd) {
                return $b['start']->lessThan($dayEnd) && $b['end']->greaterThan($dayStart);
            });

            // Derive available windows
            $availableBlocks = $this->intervalCalculator->deriveAvailableBlocks(
                $dayStart,
                $dayEnd,
                array_values($dayBusy)
            );

            // Apply manual overrides
            $finalBlocks = $this->overrideCalculator->applyOverrides(
                $availableBlocks,
                $context->availabilityOverrides,
                $dateStr
            );

            $result[$dateStr] = array_map(fn($b) => $b->toArray(), $finalBlocks);
        }

        return $result;
    }
}
