<?php

namespace App\Domain\Availability\Data;

use DateTimeInterface;

class TimeInterval
{
    public function __construct(
        public readonly string $startAt, // ISO string or H:i / Y-m-d H:i
        public readonly string $endAt,
        public readonly string $status = 'available', // available, busy, unavailable
        public readonly ?string $reason = null,
        public readonly ?string $shiftType = null
    ) {}

    public function toArray(): array
    {
        return [
            'start' => $this->startAt,
            'end' => $this->endAt,
            'status' => $this->status,
            'reason' => $this->reason,
            'shift_type' => $this->shiftType,
        ];
    }
}
