<?php

use App\Http\Controllers\Api\V1\ActivityController;
use App\Http\Controllers\Api\V1\AuthController;
use App\Http\Controllers\Api\V1\AvailabilityController;
use App\Http\Controllers\Api\V1\AvailabilityOverrideController;
use App\Http\Controllers\Api\V1\CircleAvailabilityController;
use App\Http\Controllers\Api\V1\CircleController;
use App\Http\Controllers\Api\V1\ImportController;
use App\Http\Controllers\Api\V1\InviteController;
use App\Http\Controllers\Api\V1\LocationController;
use App\Http\Controllers\Api\V1\PlanController;
use App\Http\Controllers\Api\V1\ProfileController;
use App\Http\Controllers\Api\V1\ScheduleController;
use App\Http\Controllers\Api\V1\ShiftTemplateController;
use App\Http\Controllers\Api\V1\DeviceController;
use App\Http\Controllers\Api\V1\NotificationController;
use Illuminate\Support\Facades\Route;

Route::prefix('v1')->middleware('throttle:300,1')->group(function () {
    // Auth & Sensitive Routes (Strict Rate Limiting)
    Route::post('/auth/register', [AuthController::class, 'register'])->middleware('throttle:15,1');
    Route::post('/auth/login', [AuthController::class, 'login'])->middleware('throttle:15,1');
    Route::post('/devices/pair', [DeviceController::class, 'pairDevice'])->middleware('throttle:15,1');

    // Authenticated Routes
    Route::middleware('auth:sanctum')->group(function () {
        Route::post('/auth/logout', [AuthController::class, 'logout']);
        Route::get('/auth/me', [AuthController::class, 'me']);

        // Profile Routes
        Route::get('/profile', [ProfileController::class, 'show']);
        Route::put('/profile', [ProfileController::class, 'update']);
        Route::post('/profile/handle-check', [ProfileController::class, 'checkHandle']);

        // Devices
        Route::get('/devices', [DeviceController::class, 'index']);
        Route::post('/devices/pairing-code', [DeviceController::class, 'generatePairingCode']);
        Route::delete('/devices/{id}', [DeviceController::class, 'destroy']);

        // In-App Notifications
        Route::get('/notifications', [NotificationController::class, 'index']);
        Route::put('/notifications/{id}/read', [NotificationController::class, 'markAsRead']);
        Route::put('/notifications/read-all', [NotificationController::class, 'markAllAsRead']);

        // Shift Templates
        Route::get('/shift-templates', [ShiftTemplateController::class, 'index']);
        Route::post('/shift-templates', [ShiftTemplateController::class, 'store']);
        Route::put('/shift-templates/{shiftTemplate}', [ShiftTemplateController::class, 'update']);
        Route::delete('/shift-templates/{shiftTemplate}', [ShiftTemplateController::class, 'destroy']);

        // Schedules
        Route::get('/schedules', [ScheduleController::class, 'index']);
        Route::post('/schedules', [ScheduleController::class, 'store']);
        Route::post('/schedules/batch', [ScheduleController::class, 'batch']);
        Route::put('/schedules/{scheduleEntry}', [ScheduleController::class, 'update']);
        Route::delete('/schedules/{scheduleEntry}', [ScheduleController::class, 'destroy']);

        // Availability Engine & Overrides
        Route::get('/availability/personal', [AvailabilityController::class, 'personal']);
        Route::get('/availability/overrides', [AvailabilityOverrideController::class, 'index']);
        Route::post('/availability/overrides', [AvailabilityOverrideController::class, 'store']);
        Route::delete('/availability/overrides/{override}', [AvailabilityOverrideController::class, 'destroy']);

        // Circles & Roster
        Route::get('/circles', [CircleController::class, 'index']);
        Route::post('/circles', [CircleController::class, 'store']);
        Route::get('/circles/{circle}', [CircleController::class, 'show']);
        Route::delete('/circles/{circle}', [CircleController::class, 'destroy']);
        Route::put('/circles/{circle}/members/{member}', [CircleController::class, 'updateMember']);
        Route::delete('/circles/{circle}/members/{member}', [CircleController::class, 'removeMember']);
        Route::get('/circles/{circle}/activity', [ActivityController::class, 'circleActivity']);

        // Matching Engine & Compare
        Route::get('/circles/{circle}/availability', [CircleAvailabilityController::class, 'circleMatch']);
        Route::post('/availability/compare', [CircleAvailabilityController::class, 'compareUsers']);

        // Invites
        Route::post('/circles/{circle}/invites', [InviteController::class, 'createInvite']);
        Route::post('/invites/join', [InviteController::class, 'join']);

        // Meetup Plans & RSVPs
        Route::get('/plans', [PlanController::class, 'index']);
        Route::post('/plans', [PlanController::class, 'store']);
        Route::get('/plans/{plan}', [PlanController::class, 'show']);
        Route::delete('/plans/{plan}', [PlanController::class, 'destroy']);
        Route::post('/plans/{plan}/rsvp', [PlanController::class, 'rsvp']);
        Route::post('/plans/{plan}/options', [PlanController::class, 'addOption']);
        
        // Plan Messages (Chat)
        Route::get('/plans/{plan}/messages', [\App\Http\Controllers\Api\V1\PlanMessageController::class, 'index']);
        Route::post('/plans/{plan}/messages', [\App\Http\Controllers\Api\V1\PlanMessageController::class, 'store']);

        // Location Voting
        Route::post('/plans/{plan}/locations', [LocationController::class, 'store']);
        Route::post('/locations/{location}/vote', [LocationController::class, 'vote']);

        // Rota AI Imports
        Route::post('/imports/rota', [ImportController::class, 'extractRota']);
        Route::post('/imports/confirm', [ImportController::class, 'confirmImport']);

        // Subscriptions & Premium
        Route::get('/subscription/status', [\App\Http\Controllers\Api\V1\SubscriptionController::class, 'status']);
        Route::post('/subscription/redeem', [\App\Http\Controllers\Api\V1\SubscriptionController::class, 'redeem']);

        // System Admin Panel Routes
        Route::get('/admin/stats', [\App\Http\Controllers\Api\V1\AdminController::class, 'stats']);
        Route::get('/admin/users', [\App\Http\Controllers\Api\V1\AdminController::class, 'users']);
        Route::put('/admin/users/{user}/toggle-premium', [\App\Http\Controllers\Api\V1\AdminController::class, 'toggleUserPremium']);
        Route::get('/admin/coupons', [\App\Http\Controllers\Api\V1\AdminController::class, 'coupons']);
        Route::post('/admin/coupons', [\App\Http\Controllers\Api\V1\AdminController::class, 'storeCoupon']);
        Route::put('/admin/coupons/{coupon}/toggle', [\App\Http\Controllers\Api\V1\AdminController::class, 'toggleCoupon']);
        Route::get('/admin/circles', [\App\Http\Controllers\Api\V1\AdminController::class, 'circles']);
    });
});
