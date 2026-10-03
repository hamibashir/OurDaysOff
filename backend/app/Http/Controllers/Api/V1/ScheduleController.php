<?php

namespace App\Http\Controllers\Api\V1;

use App\Http\Controllers\Controller;
use App\Http\Requests\V1\BatchScheduleEntryRequest;
use App\Http\Requests\V1\StoreScheduleEntryRequest;
use App\Models\ScheduleEntry;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class ScheduleController extends Controller
{
    public function index(Request $request): JsonResponse
    {
        $request->validate([
            'start_date' => ['nullable', 'date_format:Y-m-d'],
            'end_date' => ['nullable', 'date_format:Y-m-d'],
        ]);

        $query = $request->user()->scheduleEntries()->with('shiftTemplate');

        if ($request->filled('start_date')) {
            $query->where('date', '>=', $request->input('start_date'));
        }

        if ($request->filled('end_date')) {
            $query->where('date', '<=', $request->input('end_date'));
        }

        $entries = $query->orderBy('date')->get();

        return response()->json([
            'data' => $entries
        ]);
    }

    public function store(StoreScheduleEntryRequest $request): JsonResponse
    {
        $validated = $request->validated();
        $user = $request->user();

        // Calculate overnight if not explicitly set
        $isOvernight = $validated['is_overnight'] ?? ($validated['end_time'] < $validated['start_time']);

        $entry = $user->scheduleEntries()->updateOrCreate(
            ['date' => $validated['date']],
            [
                'shift_template_id' => $validated['shift_template_id'] ?? null,
                'start_time' => $validated['start_time'],
                'end_time' => $validated['end_time'],
                'timezone' => 'UTC',
                'entry_type' => $validated['entry_type'],
                'label' => $validated['label'] ?? null,
                'notes' => $validated['notes'] ?? null,
                'is_overnight' => $isOvernight,
                'source' => $validated['source'] ?? 'manual',
            ]
        );

        return response()->json([
            'message' => 'Schedule entry saved successfully.',
            'data' => $entry->load('shiftTemplate')
        ], 201);
    }

    public function batch(BatchScheduleEntryRequest $request): JsonResponse
    {
        $validated = $request->validated();
        $user = $request->user();
        $isOvernight = $validated['is_overnight'] ?? ($validated['end_time'] < $validated['start_time']);

        $createdEntries = [];

        foreach ($validated['dates'] as $date) {
            $entry = $user->scheduleEntries()->updateOrCreate(
                ['date' => $date],
                [
                    'shift_template_id' => $validated['shift_template_id'] ?? null,
                    'start_time' => $validated['start_time'],
                    'end_time' => $validated['end_time'],
                    'timezone' => 'UTC',
                    'entry_type' => $validated['entry_type'],
                    'label' => $validated['label'] ?? null,
                    'notes' => $validated['notes'] ?? null,
                    'is_overnight' => $isOvernight,
                    'source' => 'template',
                ]
            );
            $createdEntries[] = $entry;
        }

        return response()->json([
            'message' => 'Batch schedule entries saved successfully.',
            'data' => $createdEntries
        ], 201);
    }

    public function update(StoreScheduleEntryRequest $request, ScheduleEntry $scheduleEntry): JsonResponse
    {
        if ($scheduleEntry->user_id !== $request->user()->id) {
            return response()->json(['message' => 'Unauthorized action.'], 403);
        }

        $validated = $request->validated();
        $isOvernight = $validated['is_overnight'] ?? ($validated['end_time'] < $validated['start_time']);

        $scheduleEntry->update(array_merge($validated, ['is_overnight' => $isOvernight]));

        return response()->json([
            'message' => 'Schedule entry updated successfully.',
            'data' => $scheduleEntry->load('shiftTemplate')
        ]);
    }

    public function destroy(Request $request, ScheduleEntry $scheduleEntry): JsonResponse
    {
        if ($scheduleEntry->user_id !== $request->user()->id) {
            return response()->json(['message' => 'Unauthorized action.'], 403);
        }

        $scheduleEntry->delete();

        return response()->json([
            'message' => 'Schedule entry deleted successfully.'
        ]);
    }
}
