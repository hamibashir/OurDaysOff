<?php

namespace Tests\Unit\Domain;

use App\Domain\Availability\AvailabilityEngine;
use App\Domain\Availability\Data\TimeInterval;
use App\Domain\Availability\Data\UserAvailabilityContext;
use App\Models\AvailabilityOverride;
use App\Models\ScheduleEntry;
use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;

class AvailabilityEngineTest extends TestCase
{
    use RefreshDatabase;

    private AvailabilityEngine $engine;

    protected function setUp(): void
    {
        parent::setUp();
        $this->engine = new AvailabilityEngine();
    }

    public function test_normal_shift_availability_calculation(): void
    {
        $user = User::factory()->create();

        // 07:00 to 15:00 shift on 2026-10-10
        $entry = new ScheduleEntry([
            'user_id' => $user->id,
            'date' => '2026-10-10',
            'start_time' => '07:00',
            'end_time' => '15:00',
            'entry_type' => 'work',
            'is_overnight' => false,
            'timezone' => 'UTC',
        ]);

        $context = new UserAvailabilityContext(
            userId: $user->id,
            scheduleEntries: collect([$entry]),
            availabilityOverrides: collect([]),
            startDate: '2026-10-10',
            endDate: '2026-10-10',
            recoveryHoursAfterNightShift: 0
        );

        $result = $this->engine->calculate($context);

        $this->assertArrayHasKey('2026-10-10', $result);
        $dayBlocks = $result['2026-10-10'];

        $this->assertCount(2, $dayBlocks);
        $this->assertEquals('00:00', $dayBlocks[0]['start']);
        $this->assertEquals('07:00', $dayBlocks[0]['end']);
        $this->assertEquals('15:00', $dayBlocks[1]['start']);
        $this->assertEquals('24:00', $dayBlocks[1]['end']);
    }

    public function test_overnight_shift_and_recovery_rest_period(): void
    {
        $user = User::factory()->create();

        // Night shift 22:00 -> 06:00 starting on 2026-10-10
        $entry = new ScheduleEntry([
            'user_id' => $user->id,
            'date' => '2026-10-10',
            'start_time' => '22:00',
            'end_time' => '06:00',
            'entry_type' => 'work',
            'is_overnight' => true,
            'timezone' => 'UTC',
        ]);

        // 8 hour post-night-shift recovery: 06:00 -> 14:00 on 2026-10-11
        $context = new UserAvailabilityContext(
            userId: $user->id,
            scheduleEntries: collect([$entry]),
            availabilityOverrides: collect([]),
            startDate: '2026-10-10',
            endDate: '2026-10-11',
            recoveryHoursAfterNightShift: 8
        );

        $result = $this->engine->calculate($context);

        // Day 1 (2026-10-10): Free 00:00 -> 22:00
        $this->assertCount(1, $result['2026-10-10']);
        $this->assertEquals('00:00', $result['2026-10-10'][0]['start']);
        $this->assertEquals('22:00', $result['2026-10-10'][0]['end']);

        // Day 2 (2026-10-11): Shift ends at 06:00 + 8h recovery = busy/unavailable until 14:00. Free 14:00 -> 24:00.
        $this->assertCount(1, $result['2026-10-11']);
        $this->assertEquals('14:00', $result['2026-10-11'][0]['start']);
        $this->assertEquals('24:00', $result['2026-10-11'][0]['end']);
    }

    public function test_travel_buffer_expansion(): void
    {
        $user = User::factory()->create();

        // Work shift 09:00 -> 17:00 with 30min buffer before and 30min buffer after
        $entry = new ScheduleEntry([
            'user_id' => $user->id,
            'date' => '2026-10-10',
            'start_time' => '09:00',
            'end_time' => '17:00',
            'entry_type' => 'work',
            'is_overnight' => false,
            'timezone' => 'UTC',
        ]);

        $context = new UserAvailabilityContext(
            userId: $user->id,
            scheduleEntries: collect([$entry]),
            availabilityOverrides: collect([]),
            startDate: '2026-10-10',
            endDate: '2026-10-10',
            travelBufferBeforeMinutes: 30,
            travelBufferAfterMinutes: 30
        );

        $result = $this->engine->calculate($context);
        $dayBlocks = $result['2026-10-10'];

        $this->assertCount(2, $dayBlocks);
        $this->assertEquals('08:30', $dayBlocks[0]['end']);
        $this->assertEquals('17:30', $dayBlocks[1]['start']);
    }

    public function test_manual_override_takes_precedence(): void
    {
        $user = User::factory()->create();

        $entry = new ScheduleEntry([
            'user_id' => $user->id,
            'date' => '2026-10-10',
            'start_time' => '07:00',
            'end_time' => '15:00',
            'entry_type' => 'work',
            'timezone' => 'UTC',
        ]);

        $override = new AvailabilityOverride([
            'user_id' => $user->id,
            'date' => '2026-10-10',
            'start_time' => '16:00',
            'end_time' => '17:00',
            'status' => 'unavailable',
        ]);

        $context = new UserAvailabilityContext(
            userId: $user->id,
            scheduleEntries: collect([$entry]),
            availabilityOverrides: collect([$override]),
            startDate: '2026-10-10',
            endDate: '2026-10-10'
        );

        $result = $this->engine->calculate($context);
        $dayBlocks = $result['2026-10-10'];

        $this->assertCount(3, $dayBlocks);
        $this->assertEquals('15:00', $dayBlocks[1]['start']);
        $this->assertEquals('16:00', $dayBlocks[1]['end']);
        $this->assertEquals('17:00', $dayBlocks[2]['start']);
        $this->assertEquals('24:00', $dayBlocks[2]['end']);
    }

    public function test_full_day_free_when_no_shifts_scheduled(): void
    {
        $user = User::factory()->create();

        $context = new UserAvailabilityContext(
            userId: $user->id,
            scheduleEntries: collect([]),
            availabilityOverrides: collect([]),
            startDate: '2026-10-10',
            endDate: '2026-10-10'
        );

        $result = $this->engine->calculate($context);

        $this->assertCount(1, $result['2026-10-10']);
        $this->assertEquals('00:00', $result['2026-10-10'][0]['start']);
        $this->assertEquals('24:00', $result['2026-10-10'][0]['end']);
        $this->assertEquals('available', $result['2026-10-10'][0]['status']);
    }
}
