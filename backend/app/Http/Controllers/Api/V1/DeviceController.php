<?php

namespace App\Http\Controllers\Api\V1;

use App\Http\Controllers\Controller;
use App\Models\UserDevice;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Str;

class DeviceController extends Controller
{
    public function index(Request $request): JsonResponse
    {
        $devices = $request->user()->devices()->latest('last_seen_at')->get();

        return response()->json([
            'data' => $devices,
        ]);
    }

    public function generatePairingCode(Request $request): JsonResponse
    {
        $code = strtoupper(Str::random(6));
        $expiresAt = now()->addMinutes(10);

        // Store active pairing code in user_devices (or update existing pending)
        UserDevice::updateOrCreate(
            [
                'user_id' => $request->user()->id,
                'device_identifier' => 'pending_pairing_' . $request->user()->id,
            ],
            [
                'device_name' => 'Pending Mobile Pairing',
                'device_type' => 'flutter',
                'pairing_code' => $code,
                'pairing_code_expires_at' => $expiresAt,
            ]
        );

        return response()->json([
            'message' => 'Pairing code generated',
            'pairing_code' => $code,
            'expires_at' => $expiresAt->toIso8601String(),
        ]);
    }

    public function pairDevice(Request $request): JsonResponse
    {
        $validated = $request->validate([
            'pairing_code' => 'required|string|size:6',
            'device_name' => 'required|string|max:255',
            'device_type' => 'required|string|in:ios,android,flutter,web',
            'device_identifier' => 'required|string|max:255',
        ]);

        $pendingDevice = UserDevice::where('pairing_code', strtoupper($validated['pairing_code']))
            ->where('pairing_code_expires_at', '>', now())
            ->first();

        if (!$pendingDevice) {
            return response()->json(['message' => 'Invalid or expired pairing code'], 422);
        }

        $user = $pendingDevice->user;

        // Register paired device
        $device = UserDevice::updateOrCreate(
            [
                'user_id' => $user->id,
                'device_identifier' => $validated['device_identifier'],
            ],
            [
                'device_name' => $validated['device_name'],
                'device_type' => $validated['device_type'],
                'pairing_code' => null,
                'pairing_code_expires_at' => null,
                'last_seen_at' => now(),
            ]
        );

        // Clean up pending pairing row if different
        if ($pendingDevice->id !== $device->id) {
            $pendingDevice->delete();
        }

        $token = $user->createToken('Mobile App: ' . $validated['device_name'])->plainTextToken;

        return response()->json([
            'message' => 'Device paired successfully',
            'token' => $token,
            'user' => $user,
            'device' => $device,
        ]);
    }

    public function destroy(Request $request, int $id): JsonResponse
    {
        $device = $request->user()->devices()->findOrFail($id);
        $device->delete();

        return response()->json([
            'message' => 'Device revoked successfully',
        ]);
    }
}
