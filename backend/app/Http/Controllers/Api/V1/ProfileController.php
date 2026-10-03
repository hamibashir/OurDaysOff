<?php

namespace App\Http\Controllers\Api\V1;

use App\Http\Controllers\Controller;
use App\Http\Requests\V1\UpdateProfileRequest;
use App\Models\User;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class ProfileController extends Controller
{
    public function show(Request $request): JsonResponse
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
            ]
        ]);
    }

    public function update(UpdateProfileRequest $request): JsonResponse
    {
        $user = $request->user();
        $user->update($request->validated());

        return response()->json([
            'message' => 'Profile updated successfully.',
            'data' => [
                'id' => $user->id,
                'name' => $user->name,
                'email' => $user->email,
                'handle' => $user->handle,
                'handle_visibility' => $user->handle_visibility,
                'timezone' => $user->timezone,
            ]
        ]);
    }

    public function checkHandle(Request $request): JsonResponse
    {
        $request->validate([
            'handle' => ['required', 'string', 'max:30', 'regex:/^[a-zA-Z0-9_]+$/']
        ]);

        $handle = strtolower($request->input('handle'));
        $reserved = ['admin', 'support', 'ourdaysoff', 'system', 'root', 'api', 'help', 'privacy'];

        if (in_array($handle, $reserved)) {
            return response()->json([
                'available' => false,
                'reason' => 'Reserved handle.'
            ], 422);
        }

        $exists = User::where('handle', $handle)
            ->where('id', '!=', $request->user()?->id ?? 0)
            ->exists();

        return response()->json([
            'available' => ! $exists,
            'handle' => $handle,
        ]);
    }
}
