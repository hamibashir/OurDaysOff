<?php

namespace App\Http\Controllers\Api\V1;

use App\Http\Controllers\Controller;
use App\Models\Circle;
use App\Models\Coupon;
use App\Models\Plan;
use App\Models\ScheduleEntry;
use App\Models\User;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class AdminController extends Controller
{
    private function checkAdmin(Request $request): ?JsonResponse
    {
        if (! $request->user() || ! $request->user()->is_admin) {
            return response()->json(['message' => 'Forbidden. Admin privileges required.'], 403);
        }
        return null;
    }

    public function stats(Request $request): JsonResponse
    {
        if ($forbidden = $this->checkAdmin($request)) return $forbidden;

        return response()->json([
            'data' => [
                'total_users' => User::count(),
                'premium_users' => User::where('is_premium', true)->count(),
                'total_circles' => Circle::count(),
                'total_plans' => Plan::count(),
                'total_schedules' => ScheduleEntry::count(),
                'active_coupons' => Coupon::where('is_active', true)->count(),
            ]
        ]);
    }

    public function users(Request $request): JsonResponse
    {
        if ($forbidden = $this->checkAdmin($request)) return $forbidden;

        $search = $request->query('search');
        $query = User::query()->latest();

        if ($search) {
            $query->where(function ($q) use ($search) {
                $q->where('name', 'like', "%{$search}%")
                  ->orWhere('email', 'like', "%{$search}%")
                  ->orWhere('handle', 'like', "%{$search}%");
            });
        }

        $users = $query->limit(100)->get();

        return response()->json([
            'data' => $users
        ]);
    }

    public function toggleUserPremium(Request $request, User $user): JsonResponse
    {
        if ($forbidden = $this->checkAdmin($request)) return $forbidden;

        $user->is_premium = ! $user->is_premium;
        $user->save();

        return response()->json([
            'message' => 'User premium status updated successfully.',
            'data' => $user
        ]);
    }

    public function toggleUserAdmin(Request $request, User $user): JsonResponse
    {
        if ($forbidden = $this->checkAdmin($request)) return $forbidden;

        $user->is_admin = ! $user->is_admin;
        $user->save();

        return response()->json([
            'message' => 'User admin status updated successfully.',
            'data' => $user
        ]);
    }

    public function coupons(Request $request): JsonResponse
    {
        if ($forbidden = $this->checkAdmin($request)) return $forbidden;

        $coupons = Coupon::latest()->get();

        return response()->json([
            'data' => $coupons
        ]);
    }

    public function storeCoupon(Request $request): JsonResponse
    {
        if ($forbidden = $this->checkAdmin($request)) return $forbidden;

        $validated = $request->validate([
            'code' => ['required', 'string', 'max:50', 'unique:coupons,code'],
            'expires_at' => ['nullable', 'date'],
        ]);

        $coupon = Coupon::create([
            'code' => strtoupper(trim($validated['code'])),
            'is_active' => true,
            'expires_at' => $validated['expires_at'] ?? null,
        ]);

        return response()->json([
            'message' => 'Coupon code created successfully.',
            'data' => $coupon
        ], 201);
    }

    public function toggleCoupon(Request $request, Coupon $coupon): JsonResponse
    {
        if ($forbidden = $this->checkAdmin($request)) return $forbidden;

        $coupon->is_active = ! $coupon->is_active;
        $coupon->save();

        return response()->json([
            'message' => 'Coupon status updated successfully.',
            'data' => $coupon
        ]);
    }

    public function circles(Request $request): JsonResponse
    {
        if ($forbidden = $this->checkAdmin($request)) return $forbidden;

        $circles = Circle::with('owner')
            ->withCount('members')
            ->latest()
            ->limit(100)
            ->get();

        return response()->json([
            'data' => $circles
        ]);
    }
}
