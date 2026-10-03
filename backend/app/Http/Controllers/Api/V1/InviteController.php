<?php

namespace App\Http\Controllers\Api\V1;

use App\Http\Controllers\Controller;
use App\Http\Requests\V1\JoinCircleRequest;
use App\Models\Circle;
use App\Models\CircleInvite;
use App\Models\CircleMember;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Str;

class InviteController extends Controller
{
    public function createInvite(Request $request, Circle $circle): JsonResponse
    {
        $user = $request->user();
        $membership = $circle->members()->where('user_id', $user->id)->first();

        if (! $membership || ! in_array($membership->role, ['owner', 'admin'])) {
            return response()->json(['message' => 'Only owners and admins can create invite links.'], 403);
        }

        // Generate 6-character unique uppercase code
        $inviteCode = strtoupper(Str::random(6));

        $invite = CircleInvite::create([
            'circle_id' => $circle->id,
            'created_by' => $user->id,
            'invite_code' => $inviteCode,
            'expires_at' => now()->addDays(7),
            'max_uses' => $request->input('max_uses'),
            'uses' => 0,
        ]);

        return response()->json([
            'message' => 'Invite code generated successfully.',
            'data' => [
                'invite_code' => $invite->invite_code,
                'expires_at' => $invite->expires_at->toIso8601String(),
                'invite_url' => config('app.frontend_url', 'http://localhost:3000') . '/circles/join?code=' . $invite->invite_code,
            ]
        ], 201);
    }

    public function join(JoinCircleRequest $request): JsonResponse
    {
        $user = $request->user();
        $code = strtoupper(trim($request->input('invite_code')));

        $invite = CircleInvite::where('invite_code', $code)
            ->where(function ($q) {
                $q->whereNull('expires_at')->orWhere('expires_at', '>', now());
            })
            ->first();

        if (! $invite) {
            return response()->json(['message' => 'Invalid or expired invite code.'], 422);
        }

        if ($invite->max_uses && $invite->uses >= $invite->max_uses) {
            return response()->json(['message' => 'This invite link has reached its maximum usage limit.'], 422);
        }

        $circle = $invite->circle;

        // Check if already a member
        $existing = CircleMember::where('circle_id', $circle->id)
            ->where('user_id', $user->id)
            ->first();

        if ($existing) {
            return response()->json([
                'message' => 'You are already a member of this circle.',
                'data' => $circle
            ]);
        }

        CircleMember::create([
            'circle_id' => $circle->id,
            'user_id' => $user->id,
            'role' => 'member',
            'member_type' => 'working',
            'visibility' => 'free_busy', // Default visibility for new joiners is privacy-first free_busy
            'status' => 'active',
            'joined_at' => now(),
        ]);

        $invite->increment('uses');

        return response()->json([
            'message' => "Successfully joined circle: {$circle->name}",
            'data' => $circle->load('members.user')
        ]);
    }
}
