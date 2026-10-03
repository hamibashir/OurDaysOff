<?php

namespace App\Domain\Availability;

use Carbon\Carbon;

class BufferCalculator
{
    /**
     * Expands busy blocks by pre-shift and post-shift travel buffers.
     *
     * @param array<array{start: Carbon, end: Carbon, entry: mixed}> $busyBlocks
     * @param int $bufferBeforeMinutes
     * @param int $bufferAfterMinutes
     * @return array<array{start: Carbon, end: Carbon, entry: mixed}>
     */
    public function applyBuffers(array $busyBlocks, int $bufferBeforeMinutes, int $bufferAfterMinutes): array
    {
        if ($bufferBeforeMinutes <= 0 && $bufferAfterMinutes <= 0) {
            return $busyBlocks;
        }

        $bufferedBlocks = [];

        foreach ($busyBlocks as $block) {
            $start = (clone $block['start'])->subMinutes($bufferBeforeMinutes);
            $end = (clone $block['end'])->addMinutes($bufferAfterMinutes);

            $bufferedBlocks[] = [
                'start' => $start,
                'end' => $end,
                'entry' => $block['entry'],
            ];
        }

        return $bufferedBlocks;
    }
}
