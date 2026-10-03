<?php

namespace App\Http\Controllers\Api\V1;

use App\Http\Controllers\Controller;
use App\Models\Plan;
use App\Models\PlanMessage;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class PlanMessageController extends Controller
{
    public function index(Request $request, Plan $plan): JsonResponse
    {
        $user = $request->user();
        $membership = $plan->circle->members()->where('user_id', $user->id)->first();

        if (! $membership || $membership->status !== 'active') {
            return response()->json(['message' => 'Unauthorized access.'], 403);
        }

        $messages = $plan->messages()->with('user:id,name,handle')->oldest()->get();

        return response()->json([
            'data' => $messages
        ]);
    }

    public function store(Request $request, Plan $plan): JsonResponse
    {
        $validated = $request->validate([
            'body' => ['required', 'string', 'max:1000'],
        ]);

        $user = $request->user();
        $membership = $plan->circle->members()->where('user_id', $user->id)->first();

        if (! $membership || $membership->status !== 'active') {
            return response()->json(['message' => 'Unauthorized access.'], 403);
        }

        $message = $plan->messages()->create([
            'user_id' => $user->id,
            'body' => $validated['body'],
        ]);

        return response()->json([
            'message' => 'Message sent successfully.',
            'data' => $message->load('user:id,name,handle')
        ], 201);
    }
}
