<?php

namespace App\Domain\Availability\Data;

use Illuminate\Support\Collection;

class UserAvailabilityContext
{
    public function __construct(
        public readonly int $userId,
        public readonly Collection $scheduleEntries,
        public readonly Collection $availabilityOverrides,
        public readonly string $startDate, // Y-m-d
        public readonly string $endDate,   // Y-m-d
        public readonly int $recoveryHoursAfterNightShift = 8,
        public readonly int $travelBufferBeforeMinutes = 0,
        public readonly int $travelBufferAfterMinutes = 0,
        public readonly string $timezone = 'UTC'
    ) {}
}
