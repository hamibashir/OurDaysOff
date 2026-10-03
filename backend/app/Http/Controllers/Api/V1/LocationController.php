<?php

namespace App\Http\Controllers\Api\V1;

use App\Http\Controllers\Controller;
use App\Http\Requests\V1\StorePlanLocationRequest;
use App\Models\ActivityEvent;
use App\Models\Plan;
use App\Models\PlanLocation;
use App\Models\PlanLocationVote;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class LocationController extends Controller
{
    public function store(StorePlanLocationRequest $request, Plan $plan): JsonResponse
    {
        $user = $request->user();
        $membership = $plan->circle->members()->where('user_id', $user->id)->first();

        if (! $membership || $membership->status !== 'active') {
            return response()->json(['message' => 'Unauthorized access.'], 403);
        }

        $validated = $request->validated();

        $location = $plan->locations()->create([
            'name' => $validated['name'],
            'address' => $validated['address'] ?? null,
            'latitude' => $validated['latitude'] ?? null,
            'longitude' => $validated['longitude'] ?? null,
            'notes' => $validated['notes'] ?? null,
            'created_by' => $user->id,
        ]);

        ActivityEvent::create([
            'circle_id' => $plan->circle_id,
            'actor_id' => $user->id,
            'event_type' => 'location_added',
            'entity_type' => 'PlanLocation',
            'entity_id' => $location->id,
            'metadata' => ['location_name' => $location->name, 'plan_title' => $plan->title],
        ]);

        return response()->json([
            'message' => 'Location proposed successfully.',
            'data' => $location->load('votes')
        ], 201);
    }

    public function vote(Request $request, PlanLocation $location): JsonResponse
    {
        $user = $request->user();
        $plan = $location->plan;
        $membership = $plan->circle->members()->where('user_id', $user->id)->first();

        if (! $membership || $membership->status !== 'active') {
            return response()->json(['message' => 'Unauthorized access.'], 403);
        }

        // Prevent duplicate votes via firstOrCreate
        $vote = PlanLocationVote::firstOrCreate([
            'plan_location_id' => $location->id,
            'user_id' => $user->id,
        ]);

        ActivityEvent::create([
            'circle_id' => $plan->circle_id,
            'actor_id' => $user->id,
            'event_type' => 'location_vote',
            'entity_type' => 'PlanLocation',
            'entity_id' => $location->id,
            'metadata' => ['location_name' => $location->name, 'plan_title' => $plan->title],
        ]);

        return response()->json([
            'message' => 'Location vote recorded successfully.',
            'data' => $vote
        ]);
    }
}
