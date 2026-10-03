<?php

namespace Tests\Feature;

use App\Domain\Availability\PrivacyFilter;
use App\Models\Circle;
use App\Models\CircleInvite;
use App\Models\CircleMember;
use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;

class CircleTest extends TestCase
{
    use RefreshDatabase;

    public function test_user_can_create_circle_and_generate_invite(): void
    {
        $owner = User::factory()->create();

        $response = $this->actingAs($owner, 'sanctum')->postJson('/api/v1/circles', [
            'name' => 'Weekend Squad',
            'discoverability' => 'private',
        ]);

        $response->assertStatus(201)
            ->assertJsonPath('data.name', 'Weekend Squad');

        $circleId = $response->json('data.id');

        $inviteResponse = $this->actingAs($owner, 'sanctum')->postJson("/api/v1/circles/{$circleId}/invites");
        $inviteResponse->assertStatus(201)
            ->assertJsonStructure(['data' => ['invite_code', 'invite_url']]);
    }

    public function test_user_can_join_circle_via_invite_code(): void
    {
        $owner = User::factory()->create();
        $joiner = User::factory()->create();

        $circle = Circle::create([
            'owner_id' => $owner->id,
            'name' => 'Family Group',
        ]);

        $invite = CircleInvite::create([
            'circle_id' => $circle->id,
            'created_by' => $owner->id,
            'invite_code' => 'FAM123',
            'expires_at' => now()->addDays(7),
        ]);

        $joinResponse = $this->actingAs($joiner, 'sanctum')->postJson('/api/v1/invites/join', [
            'invite_code' => 'FAM123',
        ]);

        $joinResponse->assertStatus(200);

        $this->assertDatabaseHas('circle_members', [
            'circle_id' => $circle->id,
            'user_id' => $joiner->id,
            'visibility' => 'free_busy',
        ]);
    }

    public function test_privacy_filter_strips_shift_details_for_free_busy_members(): void
    {
        $filter = new PrivacyFilter();

        $rawAvailability = [
            '2026-10-10' => [
                [
                    'start' => '15:00',
                    'end' => '18:00',
                    'status' => 'available',
                    'shift_type' => 'work',
                    'reason' => 'Private Doctor Appointment Notes',
                ]
            ]
        ];

        // Free/Busy projection MUST drop reason, shift_type, and notes
        $freeBusyResult = $filter->filterAvailability($rawAvailability, 'free_busy');

        $this->assertEquals([
            '2026-10-10' => [
                [
                    'start' => '15:00',
                    'end' => '18:00',
                    'status' => 'available',
                ]
            ]
        ], $freeBusyResult);

        $this->assertArrayNotHasKey('reason', $freeBusyResult['2026-10-10'][0]);
        $this->assertArrayNotHasKey('shift_type', $freeBusyResult['2026-10-10'][0]);
    }
}
