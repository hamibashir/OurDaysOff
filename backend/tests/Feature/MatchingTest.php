<?php

namespace Tests\Feature;

use App\Domain\Availability\AvailabilityMatcher;
use App\Domain\Availability\AvailabilityRanker;
use App\Models\Circle;
use App\Models\CircleMember;
use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;

class MatchingTest extends TestCase
{
    use RefreshDatabase;

    public function test_exact_multi_user_availability_intersection(): void
    {
        $matcher = new AvailabilityMatcher();

        // Person A: 10:00 - 18:00 free
        // Person B: 13:00 - 20:00 free
        // Person C: 15:00 - 19:00 free
        $userAvailability = [
            1 => [
                ['start' => '10:00', 'end' => '18:00', 'status' => 'available']
            ],
            2 => [
                ['start' => '13:00', 'end' => '20:00', 'status' => 'available']
            ],
            3 => [
                ['start' => '15:00', 'end' => '19:00', 'status' => 'available']
            ],
        ];

        $common = $matcher->findCommonAvailability($userAvailability);

        // Expected intersection: 15:00 to 18:00
        $this->assertCount(1, $common);
        $this->assertEquals('15:00', $common[0]['start']);
        $this->assertEquals('18:00', $common[0]['end']);
    }

    public function test_ranker_flags_top_magic_hour_suggestion(): void
    {
        $ranker = new AvailabilityRanker();

        $dailyCommon = [
            '2026-10-10' => [
                ['start' => '18:00', 'end' => '21:00', 'status' => 'available'], // 3 hours, dinner window -> highest score
                ['start' => '08:00', 'end' => '09:00', 'status' => 'available'], // 1 hour
            ]
        ];

        $suggestions = $ranker->rankSuggestions($dailyCommon, 3);

        $this->assertCount(2, $suggestions);
        $this->assertTrue($suggestions[0]['is_magic_hour']);
        $this->assertEquals('18:00', $suggestions[0]['start']);
        $this->assertEquals('21:00', $suggestions[0]['end']);
    }
}
