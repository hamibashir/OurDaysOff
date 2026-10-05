<?php

namespace Tests\Feature;

use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Http\UploadedFile;
use Tests\TestCase;

class ImportTest extends TestCase
{
    use RefreshDatabase;

    public function test_user_can_upload_rota_file_for_preview_and_confirm(): void
    {
        $user = User::factory()->create(['is_premium' => true]);

        // 1. Upload mock file for extraction preview
        $file = UploadedFile::fake()->create('my_rota.png', 500, 'image/png');

        $extractResponse = $this->actingAs($user, 'sanctum')->postJson('/api/v1/imports/rota', [
            'file' => $file,
        ]);

        $extractResponse->assertStatus(200)
            ->assertJsonStructure(['data' => ['preview_entries']]);

        $previewEntries = $extractResponse->json('data.preview_entries');

        // Ensure NO entries were inserted directly to DB yet
        $this->assertDatabaseCount('schedule_entries', 0);

        // 2. User reviews and confirms preview entries
        $confirmResponse = $this->actingAs($user, 'sanctum')->postJson('/api/v1/imports/confirm', [
            'entries' => $previewEntries,
        ]);

        $confirmResponse->assertStatus(201);
        $this->assertDatabaseHas('schedule_entries', [
            'user_id' => $user->id,
            'date' => $previewEntries[0]['date'],
            'label' => 'Early Shift (Extracted)',
            'source' => 'import',
        ]);
    }

    public function test_import_overwrites_existing_date_without_duplication(): void
    {
        $user = User::factory()->create();

        $previewEntries = [
            [
                'date' => '2026-10-15',
                'shift_label' => 'Night Duty',
                'start_time' => '22:00',
                'end_time' => '06:00',
                'entry_type' => 'work',
                'is_overnight' => true,
            ]
        ];

        // First import
        $this->actingAs($user, 'sanctum')->postJson('/api/v1/imports/confirm', [
            'entries' => $previewEntries,
        ])->assertStatus(201);

        $this->assertDatabaseCount('schedule_entries', 1);

        // Re-import modified entry for same date
        $previewEntries[0]['shift_label'] = 'Updated Night Duty';
        $this->actingAs($user, 'sanctum')->postJson('/api/v1/imports/confirm', [
            'entries' => $previewEntries,
        ])->assertStatus(201);

        // Verify count remains 1 and label updated cleanly
        $this->assertDatabaseCount('schedule_entries', 1);
        $this->assertDatabaseHas('schedule_entries', [
            'user_id' => $user->id,
            'date' => '2026-10-15',
            'label' => 'Updated Night Duty',
        ]);
    }
}
