<?php

namespace App\Http\Controllers\Api\V1;

use App\Http\Controllers\Controller;
use App\Http\Requests\V1\StoreCircleRequest;
use App\Http\Requests\V1\UpdateCircleMemberRequest;
use App\Models\Circle;
use App\Models\CircleMember;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Str;

class CircleController extends Controller
{
    public function index(Request $request): JsonResponse
    {
        $user = $request->user();

        $circleIds = $user->circleMemberships()
            ->where('status', 'active')
            ->pluck('circle_id');

        $circles = Circle::whereIn('id', $circleIds)
            ->withCount('members')
            ->get();

        $result = $circles->map(function ($circle) use ($user) {
            $membership = $circle->members->firstWhere('user_id', $user->id);
            return array_merge($circle->toArray(), [
                'my_role' => $membership?->role,
                'my_member_type' => $membership?->member_type,
                'my_visibility' => $membership?->visibility,
            ]);
        });

        return response()->json([
            'data' => $result
        ]);
    }

    public function store(StoreCircleRequest $request): JsonResponse
    {
        $validated = $request->validated();
        $user = $request->user();

        $circle = Circle::create([
            'owner_id' => $user->id,
            'name' => $validated['name'],
            'handle' => $validated['handle'] ?? null,
            'discoverability' => $validated['discoverability'] ?? 'private',
        ]);

        // Auto add creator as Owner
        CircleMember::create([
            'circle_id' => $circle->id,
            'user_id' => $user->id,
            'role' => 'owner',
            'member_type' => 'working',
            'visibility' => 'details',
            'status' => 'active',
            'joined_at' => now(),
        ]);

        return response()->json([
            'message' => 'Circle created successfully.',
            'data' => $circle->load('members.user')
        ], 201);
    }

    public function show(Request $request, Circle $circle): JsonResponse
    {
        $user = $request->user();
        $membership = $circle->members()->where('user_id', $user->id)->first();

        if (! $membership || $membership->status !== 'active') {
            return response()->json(['message' => 'Unauthorized access to circle.'], 403);
        }

        $circle->load(['owner', 'members.user']);

        return response()->json([
            'data' => array_merge($circle->toArray(), [
                'my_role' => $membership->role,
                'my_member_type' => $membership->member_type,
                'my_visibility' => $membership->visibility,
            ])
        ]);
    }

    public function updateMember(UpdateCircleMemberRequest $request, Circle $circle, CircleMember $member): JsonResponse
    {
        $user = $request->user();
        $currentUserMember = $circle->members()->where('user_id', $user->id)->first();

        if (! $currentUserMember || ! in_array($currentUserMember->role, ['owner', 'admin']) && $member->user_id !== $user->id) {
            return response()->json(['message' => 'Unauthorized action.'], 403);
        }

        $member->update($request->validated());

        return response()->json([
            'message' => 'Member profile updated successfully.',
            'data' => $member->load('user')
        ]);
    }

    public function removeMember(Request $request, Circle $circle, CircleMember $member): JsonResponse
    {
        $user = $request->user();
        $currentUserMember = $circle->members()->where('user_id', $user->id)->first();

        if (! $currentUserMember || ! in_array($currentUserMember->role, ['owner', 'admin']) && $member->user_id !== $user->id) {
            return response()->json(['message' => 'Unauthorized action.'], 403);
        }

        $member->delete();

        return response()->json([
            'message' => 'Member removed from circle successfully.'
        ]);
    }

    public function destroy(Request $request, Circle $circle): JsonResponse
    {
        if ($circle->owner_id !== $request->user()->id) {
            return response()->json(['message' => 'Only circle owner can delete this circle.'], 403);
        }

        $circle->delete();

        return response()->json([
            'message' => 'Circle deleted successfully.'
        ]);
    }
}
