<?php

namespace Tests\Feature;

use App\Models\ScheduleEntry;
use App\Models\ShiftTemplate;
use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;

class ScheduleTest extends TestCase
{
    use RefreshDatabase;

    public function test_user_can_create_and_fetch_shift_templates(): void
    {
        $user = User::factory()->create();

        $response = $this->actingAs($user, 'sanctum')->postJson('/api/v1/shift-templates', [
            'name' => 'Night Shift',
            'start_time' => '22:00',
            'end_time' => '06:00',
            'color' => '#8b5cf6',
        ]);

        $response->assertStatus(201)
            ->assertJsonPath('data.name', 'Night Shift')
            ->assertJsonPath('data.is_overnight', true);

        $fetchResponse = $this->actingAs($user, 'sanctum')->getJson('/api/v1/shift-templates');
        $fetchResponse->assertStatus(200)
            ->assertJsonCount(1, 'data');
    }

    public function test_user_can_create_schedule_entry_and_batch_assign(): void
    {
        $user = User::factory()->create();

        $template = ShiftTemplate::create([
            'user_id' => $user->id,
            'name' => 'Early',
            'start_time' => '07:00',
            'end_time' => '15:00',
        ]);

        $batchResponse = $this->actingAs($user, 'sanctum')->postJson('/api/v1/schedules/batch', [
            'dates' => ['2026-10-10', '2026-10-11', '2026-10-12'],
            'shift_template_id' => $template->id,
            'start_time' => '07:00',
            'end_time' => '15:00',
            'entry_type' => 'work',
        ]);

        $batchResponse->assertStatus(201)
            ->assertJsonCount(3, 'data');

        $this->assertDatabaseHas('schedule_entries', [
            'user_id' => $user->id,
            'date' => '2026-10-10',
            'entry_type' => 'work',
        ]);
    }

    public function test_user_cannot_modify_another_users_schedule(): void
    {
        $userA = User::factory()->create();
        $userB = User::factory()->create();

        $entry = ScheduleEntry::create([
            'user_id' => $userA->id,
            'date' => '2026-10-15',
            'start_time' => '09:00',
            'end_time' => '17:00',
            'entry_type' => 'work',
        ]);

        $response = $this->actingAs($userB, 'sanctum')->deleteJson("/api/v1/schedules/{$entry->id}");
        $response->assertStatus(403);
    }
}
