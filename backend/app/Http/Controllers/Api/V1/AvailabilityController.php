<?php

namespace App\Http\Controllers\Api\V1;

use App\Domain\Availability\AvailabilityEngine;
use App\Domain\Availability\Data\UserAvailabilityContext;
use App\Http\Controllers\Controller;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class AvailabilityController extends Controller
{
    public function personal(Request $request, AvailabilityEngine $engine): JsonResponse
    {
        $request->validate([
            'start_date' => ['required', 'date_format:Y-m-d'],
            'end_date' => ['required', 'date_format:Y-m-d', 'after_or_equal:start_date'],
            'recovery_hours' => ['nullable', 'integer', 'min:0', 'max:24'],
            'buffer_before' => ['nullable', 'integer', 'min:0', 'max:240'],
            'buffer_after' => ['nullable', 'integer', 'min:0', 'max:240'],
        ]);

        $user = $request->user();
        $startDate = $request->input('start_date');
        $endDate = $request->input('end_date');

        $scheduleEntries = $user->scheduleEntries()
            ->where('date', '>=', $startDate)
            ->where('date', '<=', $endDate)
            ->get();

        $overrides = $user->availabilityOverrides()
            ->where('date', '>=', $startDate)
            ->where('date', '<=', $endDate)
            ->get();

        $context = new UserAvailabilityContext(
            userId: $user->id,
            scheduleEntries: $scheduleEntries,
            availabilityOverrides: $overrides,
            startDate: $startDate,
            endDate: $endDate,
            recoveryHoursAfterNightShift: (int)$request->input('recovery_hours', 8),
            travelBufferBeforeMinutes: (int)$request->input('buffer_before', 0),
            travelBufferAfterMinutes: (int)$request->input('buffer_after', 0)
        );

        $availability = $engine->calculate($context);

        return response()->json([
            'data' => $availability
        ]);
    }
}
