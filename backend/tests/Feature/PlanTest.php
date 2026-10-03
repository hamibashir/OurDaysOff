<?php

namespace Tests\Feature;

use App\Models\Circle;
use App\Models\CircleMember;
use App\Models\Plan;
use App\Models\PlanLocation;
use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;

class PlanTest extends TestCase
{
    use RefreshDatabase;

    public function test_user_can_create_plan_and_rsvp(): void
    {
        $user = User::factory()->create();
        $circle = Circle::create([
            'owner_id' => $user->id,
            'name' => 'Friday Dinner Club',
        ]);

        CircleMember::create([
            'circle_id' => $circle->id,
            'user_id' => $user->id,
            'role' => 'owner',
            'status' => 'active',
        ]);

        $response = $this->actingAs($user, 'sanctum')->postJson('/api/v1/plans', [
            'circle_id' => $circle->id,
            'title' => 'Italian Bistro Dinner',
            'event_type' => 'meal',
            'start_at' => '2026-10-10 19:00:00',
            'end_at' => '2026-10-10 22:00:00',
        ]);

        $response->assertStatus(201)
            ->assertJsonPath('data.title', 'Italian Bistro Dinner');

        $planId = $response->json('data.id');

        $this->assertDatabaseHas('plan_members', [
            'plan_id' => $planId,
            'user_id' => $user->id,
            'rsvp_status' => 'attending',
        ]);
    }

    public function test_location_voting_prevents_duplicate_votes(): void
    {
        $user = User::factory()->create();
        $circle = Circle::create(['owner_id' => $user->id, 'name' => 'Team Social']);
        CircleMember::create(['circle_id' => $circle->id, 'user_id' => $user->id, 'role' => 'owner', 'status' => 'active']);

        $plan = Plan::create([
            'circle_id' => $circle->id,
            'created_by' => $user->id,
            'title' => 'Coffee & Catchup',
            'event_type' => 'social',
        ]);

        $location = PlanLocation::create([
            'plan_id' => $plan->id,
            'name' => 'Downtown Cafe',
            'created_by' => $user->id,
        ]);

        // First vote
        $vote1 = $this->actingAs($user, 'sanctum')->postJson("/api/v1/locations/{$location->id}/vote");
        $vote1->assertStatus(200);

        // Duplicate vote attempt (should succeed idempotently without creating duplicate DB records)
        $vote2 = $this->actingAs($user, 'sanctum')->postJson("/api/v1/locations/{$location->id}/vote");
        $vote2->assertStatus(200);

        $this->assertDatabaseCount('plan_location_votes', 1);
    }
}
