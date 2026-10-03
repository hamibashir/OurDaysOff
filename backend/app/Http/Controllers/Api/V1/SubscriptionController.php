<?php

namespace App\Http\Controllers\Api\V1;

use App\Http\Controllers\Controller;
use App\Models\Coupon;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class SubscriptionController extends Controller
{
    /**
     * Get the user's current premium status
     */
    public function status(Request $request): JsonResponse
    {
        return response()->json([
            'is_premium' => (bool) $request->user()->is_premium,
        ]);
    }

    /**
     * Redeem a coupon code
     */
    public function redeem(Request $request): JsonResponse
    {
        $request->validate([
            'coupon_code' => 'required|string|max:255',
        ]);

        $code = trim($request->coupon_code);

        // Find coupon
        $coupon = Coupon::where('code', $code)->first();

        if (!$coupon) {
            return response()->json([
                'message' => 'Invalid coupon code.',
            ], 400);
        }

        if (!$coupon->is_active) {
            return response()->json([
                'message' => 'This coupon code has been deactivated.',
            ], 400);
        }

        if ($coupon->expires_at && $coupon->expires_at->isPast()) {
            return response()->json([
                'message' => 'This coupon code has expired.',
            ], 400);
        }

        if ($coupon->is_used) {
            return response()->json([
                'message' => 'This coupon code has already been used.',
            ], 400);
        }

        // Apply coupon to user
        $user = $request->user();
        
        $coupon->update([
            'is_used' => true,
            'used_by' => $user->id,
            'used_at' => now(),
        ]);

        $user->update([
            'is_premium' => true,
        ]);

        return response()->json([
            'message' => 'Premium activated successfully!',
            'is_premium' => true,
        ]);
    }
}
