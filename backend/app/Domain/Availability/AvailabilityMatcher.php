<?php

namespace App\Domain\Availability;

use App\Domain\Availability\Data\TimeInterval;

class AvailabilityMatcher
{
    /**
     * Calculates the intersection of availability blocks across N users for a specific date.
     *
     * @param array<int, array<TimeInterval>> $usersDailyAvailability Array keyed by userId => array of available TimeIntervals
     * @return array<TimeInterval> Intersected available blocks
     */
    public function findCommonAvailability(array $usersDailyAvailability): array
    {
        if (empty($usersDailyAvailability)) {
            return [];
        }

        $userIds = array_keys($usersDailyAvailability);
        $firstUserBlocks = $usersDailyAvailability[$userIds[0]] ?? [];

        if (count($userIds) === 1) {
            return $firstUserBlocks;
        }

        $common = $firstUserBlocks;

        for ($i = 1; $i < count($userIds); $i++) {
            $currentUserBlocks = $usersDailyAvailability[$userIds[$i]] ?? [];
            $intersected = [];

            foreach ($common as $blockA) {
                foreach ($currentUserBlocks as $blockB) {
                    $startA = $blockA['start'];
                    $endA = $blockA['end'];
                    $startB = $blockB['start'];
                    $endB = $blockB['end'];

                    // Maximum start and minimum end
                    $latestStart = strcmp($startA, $startB) > 0 ? $startA : $startB;
                    $earliestEnd = strcmp($endA, $endB) < 0 ? $endA : $endB;

                    if ($latestStart < $earliestEnd) {
                        $intersected[] = [
                            'start' => $latestStart,
                            'end' => $earliestEnd,
                            'status' => 'available',
                        ];
                    }
                }
            }

            $common = $intersected;
        }

        return $common;
    }
}
