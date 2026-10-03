<?php

namespace App\Http\Controllers\Api\V1;

use App\Http\Controllers\Controller;
use App\Http\Requests\V1\StoreShiftTemplateRequest;
use App\Http\Requests\V1\UpdateShiftTemplateRequest;
use App\Models\ShiftTemplate;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class ShiftTemplateController extends Controller
{
    public function index(Request $request): JsonResponse
    {
        $templates = $request->user()->shiftTemplates()->orderBy('name')->get();

        return response()->json([
            'data' => $templates
        ]);
    }

    public function store(StoreShiftTemplateRequest $request): JsonResponse
    {
        $validated = $request->validated();
        
        $template = $request->user()->shiftTemplates()->create([
            'name' => $validated['name'],
            'start_time' => $validated['start_time'],
            'end_time' => $validated['end_time'],
            'is_overnight' => $validated['is_overnight'] ?? ($validated['end_time'] < $validated['start_time']),
            'color' => $validated['color'] ?? '#3b82f6',
        ]);

        return response()->json([
            'message' => 'Shift template created successfully.',
            'data' => $template
        ], 201);
    }

    public function update(UpdateShiftTemplateRequest $request, ShiftTemplate $shiftTemplate): JsonResponse
    {
        if ($shiftTemplate->user_id !== $request->user()->id) {
            return response()->json(['message' => 'Unauthorized action.'], 403);
        }

        $validated = $request->validated();
        
        if (isset($validated['start_time']) && isset($validated['end_time']) && !isset($validated['is_overnight'])) {
            $validated['is_overnight'] = $validated['end_time'] < $validated['start_time'];
        }

        $shiftTemplate->update($validated);

        return response()->json([
            'message' => 'Shift template updated successfully.',
            'data' => $shiftTemplate
        ]);
    }

    public function destroy(Request $request, ShiftTemplate $shiftTemplate): JsonResponse
    {
        if ($shiftTemplate->user_id !== $request->user()->id) {
            return response()->json(['message' => 'Unauthorized action.'], 403);
        }

        $shiftTemplate->delete();

        return response()->json([
            'message' => 'Shift template deleted successfully.'
        ]);
    }
}
