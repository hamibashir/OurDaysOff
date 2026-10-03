<?php

namespace Tests\Feature;

use App\Models\Notification;
use App\Models\User;
use App\Models\UserDevice;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;

class DeviceAndNotificationTest extends TestCase
{
    use RefreshDatabase;

    public function test_user_can_generate_pairing_code_and_pair_device(): void
    {
        $user = User::factory()->create();

        // 1. Generate pairing code
        $res = $this->actingAs($user)->postJson('/api/v1/devices/pairing-code');
        $res->assertStatus(200)
            ->assertJsonStructure(['pairing_code', 'expires_at']);

        $code = $res->json('pairing_code');

        // 2. Mobile app pairs using the 6-character code
        $pairRes = $this->postJson('/api/v1/devices/pair', [
            'pairing_code' => $code,
            'device_name' => 'Flutter Mobile App',
            'device_type' => 'flutter',
            'device_identifier' => 'test-device-uuid-1234',
        ]);

        $pairRes->assertStatus(200)
            ->assertJsonStructure(['token', 'user', 'device']);

        $this->assertDatabaseHas('user_devices', [
            'user_id' => $user->id,
            'device_name' => 'Flutter Mobile App',
            'device_type' => 'flutter',
            'device_identifier' => 'test-device-uuid-1234',
        ]);
    }

    public function test_user_can_fetch_and_read_notifications(): void
    {
        $user = User::factory()->create();

        $notification = Notification::create([
            'user_id' => $user->id,
            'type' => 'plan_invite',
            'title' => 'New Meetup Invite',
            'body' => 'You were invited to Weekend Coffee',
        ]);

        // 1. List notifications
        $listRes = $this->actingAs($user)->getJson('/api/v1/notifications');
        $listRes->assertStatus(200)
            ->assertJson(['unread_count' => 1]);

        // 2. Mark as read
        $readRes = $this->actingAs($user)->putJson("/api/v1/notifications/{$notification->id}/read");
        $readRes->assertStatus(200);

        $this->assertNotNull($notification->fresh()->read_at);
    }
}
