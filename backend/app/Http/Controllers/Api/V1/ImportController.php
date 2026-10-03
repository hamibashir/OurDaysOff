<?php

namespace App\Http\Controllers\Api\V1;

use App\Http\Controllers\Controller;
use App\Http\Requests\V1\ConfirmImportRequest;
use App\Http\Requests\V1\ImportRotaRequest;
use App\Models\ScheduleEntry;
use App\Services\RotaImportService;
use Illuminate\Http\JsonResponse;

class ImportController extends Controller
{
    public function __construct(
        private readonly RotaImportService $importService = new RotaImportService()
    ) {}

    public function extractRota(ImportRotaRequest $request): JsonResponse
    {
        if (!$request->user()->is_premium) {
            return response()->json([
                'message' => 'Premium subscription required to use AI Rota Extraction.',
            ], 403);
        }

        $file = $request->file('file');
        $extracted = $this->importService->extractScheduleFromFile($file);

        return response()->json([
            'message' => 'Rota extracted successfully. Please review preview entries before confirming.',
            'data' => [
                'preview_entries' => $extracted,
            ]
        ]);
    }

    public function confirmImport(ConfirmImportRequest $request): JsonResponse
    {
        $user = $request->user();
        $entries = $request->input('entries');

        $inserted = [];

        foreach ($entries as $e) {
            $isOvernight = $e['is_overnight'] ?? ($e['end_time'] < $e['start_time']);
            $label = !empty($e['label']) ? $e['label'] : (!empty($e['shift_label']) ? $e['shift_label'] : 'Imported Shift');
            $entryType = strtolower($e['entry_type'] ?? 'work');
            if (!in_array($entryType, ['work', 'personal', 'leave', 'off', 'other'])) {
                $entryType = 'work';
            }

            $entry = ScheduleEntry::updateOrCreate(
                [
                    'user_id' => $user->id,
                    'date' => $e['date'],
                ],
                [
                    'start_time' => $e['start_time'],
                    'end_time' => $e['end_time'],
                    'timezone' => $user->timezone ?? 'UTC',
                    'entry_type' => $entryType,
                    'label' => $label,
                    'is_overnight' => $isOvernight,
                    'source' => 'import',
                ]
            );

            $inserted[] = $entry;
        }

        return response()->json([
            'message' => 'Rota schedules imported and saved successfully.',
            'data' => $inserted
        ], 201);
    }
}
