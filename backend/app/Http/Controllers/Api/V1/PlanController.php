<?php

namespace App\Http\Controllers\Api\V1;

use App\Http\Controllers\Controller;
use App\Http\Requests\V1\RsvpRequest;
use App\Http\Requests\V1\StorePlanOptionRequest;
use App\Http\Requests\V1\StorePlanRequest;
use App\Models\ActivityEvent;
use App\Models\Circle;
use App\Models\Plan;
use App\Models\PlanMember;
use App\Models\PlanOption;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class PlanController extends Controller
{
    public function index(Request $request): JsonResponse
    {
        $user = $request->user();

        // Get user's circle IDs
        $circleIds = $user->circleMemberships()->where('status', 'active')->pluck('circle_id');

        $plans = Plan::whereIn('circle_id', $circleIds)
            ->with(['creator', 'circle', 'members.user'])
            ->orderBy('created_at', 'desc')
            ->get();

        $result = $plans->map(function ($plan) use ($user) {
            $myMember = $plan->members->firstWhere('user_id', $user->id);
            return array_merge($plan->toArray(), [
                'my_rsvp' => $myMember?->rsvp_status ?? 'pending'
            ]);
        });

        return response()->json([
            'data' => $result
        ]);
    }

    public function store(StorePlanRequest $request): JsonResponse
    {
        $validated = $request->validated();
        $user = $request->user();

        $circle = Circle::findOrFail($validated['circle_id']);
        $membership = $circle->members()->where('user_id', $user->id)->first();

        if (! $membership || $membership->status !== 'active') {
            return response()->json(['message' => 'Unauthorized circle plan creation.'], 403);
        }

        $plan = Plan::create([
            'circle_id' => $circle->id,
            'created_by' => $user->id,
            'title' => $validated['title'],
            'description' => $validated['description'] ?? null,
            'event_type' => $validated['event_type'],
            'start_at' => $validated['start_at'] ?? null,
            'end_at' => $validated['end_at'] ?? null,
            'timezone' => 'UTC',
            'status' => $validated['status'] ?? ($validated['start_at'] ? 'confirmed' : 'polling'),
        ]);

        // Auto add creator as Attending
        PlanMember::create([
            'plan_id' => $plan->id,
            'user_id' => $user->id,
            'rsvp_status' => 'attending',
            'responded_at' => now(),
        ]);

        // Record Circle Activity Event
        ActivityEvent::create([
            'circle_id' => $circle->id,
            'actor_id' => $user->id,
            'event_type' => 'plan_created',
            'entity_type' => 'Plan',
            'entity_id' => $plan->id,
            'metadata' => ['title' => $plan->title, 'event_type' => $plan->event_type],
        ]);

        return response()->json([
            'message' => 'Plan created successfully.',
            'data' => $plan->load(['creator', 'members.user', 'options', 'locations.votes'])
        ], 201);
    }

    public function show(Request $request, Plan $plan): JsonResponse
    {
        $user = $request->user();
        $membership = $plan->circle->members()->where('user_id', $user->id)->first();

        if (! $membership || $membership->status !== 'active') {
            return response()->json(['message' => 'Unauthorized access.'], 403);
        }

        $plan->load(['creator', 'circle', 'members.user', 'options', 'locations.votes']);
        $myMember = $plan->members->firstWhere('user_id', $user->id);

        return response()->json([
            'data' => array_merge($plan->toArray(), [
                'my_rsvp' => $myMember?->rsvp_status ?? 'pending'
            ])
        ]);
    }

    public function rsvp(RsvpRequest $request, Plan $plan): JsonResponse
    {
        $user = $request->user();
        $membership = $plan->circle->members()->where('user_id', $user->id)->first();

        if (! $membership || $membership->status !== 'active') {
            return response()->json(['message' => 'Unauthorized access.'], 403);
        }

        $rsvp = PlanMember::updateOrCreate(
            ['plan_id' => $plan->id, 'user_id' => $user->id],
            [
                'rsvp_status' => $request->input('rsvp_status'),
                'responded_at' => now(),
            ]
        );

        ActivityEvent::create([
            'circle_id' => $plan->circle_id,
            'actor_id' => $user->id,
            'event_type' => 'rsvp_updated',
            'entity_type' => 'Plan',
            'entity_id' => $plan->id,
            'metadata' => ['rsvp_status' => $rsvp->rsvp_status, 'plan_title' => $plan->title],
        ]);

        return response()->json([
            'message' => 'RSVP updated successfully.',
            'data' => $rsvp
        ]);
    }

    public function addOption(StorePlanOptionRequest $request, Plan $plan): JsonResponse
    {
        $user = $request->user();
        if ($plan->created_by !== $user->id) {
            return response()->json(['message' => 'Only plan creator can add date options.'], 403);
        }

        $option = $plan->options()->create($request->validated());

        ActivityEvent::create([
            'circle_id' => $plan->circle_id,
            'actor_id' => $user->id,
            'event_type' => 'poll_created',
            'entity_type' => 'PlanOption',
            'entity_id' => $option->id,
            'metadata' => ['plan_title' => $plan->title],
        ]);

        return response()->json([
            'message' => 'Poll option added successfully.',
            'data' => $option
        ], 201);
    }

    public function destroy(Request $request, Plan $plan): JsonResponse
    {
        if ($plan->created_by !== $request->user()->id) {
            return response()->json(['message' => 'Only plan creator can delete this plan.'], 403);
        }

        $plan->delete();

        return response()->json([
            'message' => 'Plan deleted successfully.'
        ]);
    }
}
