<?php

namespace App\Http\Controllers\Api\V1;

use App\Http\Controllers\Controller;
use App\Http\Requests\V1\LoginRequest;
use App\Http\Requests\V1\RegisterRequest;
use App\Models\User;
use App\Models\UserDevice;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Hash;
use Illuminate\Validation\ValidationException;

class AuthController extends Controller
{
    public function register(RegisterRequest $request): JsonResponse
    {
        $validated = $request->validated();
        
        $user = User::create([
            'name' => $validated['name'],
            'email' => $validated['email'],
            'password' => Hash::make($validated['password']),
            'handle' => $validated['handle'] ?? null,
            'handle_visibility' => 'public',
        ]);

        $deviceName = $request->input('device_name', $request->header('User-Agent', 'Web Browser'));
        $token = $user->createToken($deviceName)->plainTextToken;

        UserDevice::create([
            'user_id' => $user->id,
            'device_name' => $deviceName,
            'device_type' => 'web',
            'device_identifier' => md5($user->id . $deviceName . microtime()),
            'last_seen_at' => now(),
        ]);

        return response()->json([
            'message' => 'User registered successfully.',
            'data' => [
                'user' => [
                    'id' => $user->id,
                    'name' => $user->name,
                    'email' => $user->email,
                    'handle' => $user->handle,
                    'timezone' => $user->timezone,
                    'is_premium' => (bool) $user->is_premium,
                    'is_admin' => (bool) $user->is_admin,
                ],
                'token' => $token,
            ]
        ], 201);
    }

    public function login(LoginRequest $request): JsonResponse
    {
        $validated = $request->validated();

        $user = User::where('email', $validated['email'])->first();

        if (! $user || ! Hash::check($validated['password'], $user->password)) {
            throw ValidationException::withMessages([
                'email' => ['The provided credentials do not match our records.'],
            ]);
        }

        $deviceName = $validated['device_name'] ?? $request->header('User-Agent', 'Web Browser');
        $token = $user->createToken($deviceName)->plainTextToken;

        UserDevice::updateOrCreate(
            ['user_id' => $user->id, 'device_name' => $deviceName],
            ['device_type' => 'web', 'device_identifier' => md5($user->id . $deviceName), 'last_seen_at' => now()]
        );

        return response()->json([
            'message' => 'Login successful.',
            'data' => [
                'user' => [
                    'id' => $user->id,
                    'name' => $user->name,
                    'email' => $user->email,
                    'handle' => $user->handle,
                    'timezone' => $user->timezone,
                    'is_premium' => (bool) $user->is_premium,
                    'is_admin' => (bool) $user->is_admin,
                ],
                'token' => $token,
            ]
        ]);
    }

    public function logout(Request $request): JsonResponse
    {
        $request->user()->currentAccessToken()->delete();

        return response()->json([
            'message' => 'Logged out successfully.'
        ]);
    }

    public function me(Request $request): JsonResponse
    {
        $user = $request->user();

        return response()->json([
            'data' => [
                'id' => $user->id,
                'name' => $user->name,
                'email' => $user->email,
                'handle' => $user->handle,
                'handle_visibility' => $user->handle_visibility,
                'timezone' => $user->timezone,
                'is_premium' => (bool) $user->is_premium,
                'is_admin' => (bool) $user->is_admin,
                'created_at' => $user->created_at->toIso8601String(),
            ]
        ]);
    }
}
