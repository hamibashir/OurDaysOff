<?php

namespace App\Http\Controllers\Api\V1;

use App\Http\Controllers\Controller;
use App\Http\Requests\V1\StoreAvailabilityOverrideRequest;
use App\Models\AvailabilityOverride;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class AvailabilityOverrideController extends Controller
{
    public function index(Request $request): JsonResponse
    {
        $request->validate([
            'start_date' => ['nullable', 'date_format:Y-m-d'],
            'end_date' => ['nullable', 'date_format:Y-m-d'],
        ]);

        $query = $request->user()->availabilityOverrides();

        if ($request->filled('start_date')) {
            $query->where('date', '>=', $request->input('start_date'));
        }

        if ($request->filled('end_date')) {
            $query->where('date', '<=', $request->input('end_date'));
        }

        return response()->json([
            'data' => $query->orderBy('date')->get()
        ]);
    }

    public function store(StoreAvailabilityOverrideRequest $request): JsonResponse
    {
        $validated = $request->validated();
        
        $override = $request->user()->availabilityOverrides()->create($validated);

        return response()->json([
            'message' => 'Availability override saved successfully.',
            'data' => $override
        ], 201);
    }

    public function destroy(Request $request, AvailabilityOverride $override): JsonResponse
    {
        if ($override->user_id !== $request->user()->id) {
            return response()->json(['message' => 'Unauthorized action.'], 403);
        }

        $override->delete();

        return response()->json([
            'message' => 'Availability override removed successfully.'
        ]);
    }
}
