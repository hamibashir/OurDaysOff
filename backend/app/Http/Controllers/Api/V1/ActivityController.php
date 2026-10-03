<?php

namespace App\Http\Controllers\Api\V1;

use App\Http\Controllers\Controller;
use App\Models\ActivityEvent;
use App\Models\Circle;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class ActivityController extends Controller
{
    public function circleActivity(Request $request, Circle $circle): JsonResponse
    {
        $user = $request->user();
        $membership = $circle->members()->where('user_id', $user->id)->first();

        if (! $membership || $membership->status !== 'active') {
            return response()->json(['message' => 'Unauthorized access.'], 403);
        }

        $events = $circle->activityEvents()
            ->with('actor')
            ->orderBy('created_at', 'desc')
            ->take(30)
            ->get();

        return response()->json([
            'data' => $events
        ]);
    }
}
