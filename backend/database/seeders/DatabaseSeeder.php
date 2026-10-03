<?php

namespace Database\Seeders;

use App\Models\Circle;
use App\Models\CircleMember;
use App\Models\Plan;
use App\Models\PlanMember;
use App\Models\ScheduleEntry;
use App\Models\ShiftTemplate;
use App\Models\User;
use Carbon\Carbon;
use Illuminate\Database\Seeder;
use Illuminate\Support\Facades\Hash;

class DatabaseSeeder extends Seeder
{
    public function run(): void
    {
        // 1. Create Main Admin User
        $adminUser = User::create([
            'name' => 'Junaid Bashir',
            'email' => 'junaidbashir94@gmail.com',
            'password' => Hash::make('password'),
            'handle' => 'junaid_bashir',
            'handle_visibility' => 'public',
            'timezone' => 'Europe/London',
            'is_admin' => true,
            'is_premium' => true,
        ]);

        // Demo Users
        $demoUser = User::create([
            'name' => 'Hamza (Demo)',
            'email' => 'demo@example.com',
            'password' => Hash::make('password'),
            'handle' => 'hamza_demo',
            'handle_visibility' => 'public',
            'timezone' => 'Europe/London',
            'is_admin' => true,
            'is_premium' => true,
        ]);

        $alice = User::create([
            'name' => 'Alice Johnson',
            'email' => 'alice@example.com',
            'password' => Hash::make('password'),
            'handle' => 'alice_j',
            'handle_visibility' => 'public',
            'timezone' => 'Europe/London',
        ]);

        $bob = User::create([
            'name' => 'Bob Miller',
            'email' => 'bob@example.com',
            'password' => Hash::make('password'),
            'handle' => 'bob_m',
            'handle_visibility' => 'public',
            'timezone' => 'Europe/London',
        ]);

        $charlie = User::create([
            'name' => 'Charlie Davies',
            'email' => 'charlie@example.com',
            'password' => Hash::make('password'),
            'handle' => 'charlie_d',
            'handle_visibility' => 'public',
            'timezone' => 'Europe/London',
        ]);

        // 2. Create Shift Templates for Users
        $users = [$adminUser, $demoUser, $alice, $bob, $charlie];

        foreach ($users as $u) {
            ShiftTemplate::create([
                'user_id' => $u->id,
                'name' => 'Early Shift',
                'start_time' => '07:00',
                'end_time' => '15:00',
                'is_overnight' => false,
                'color' => '#3b82f6',
            ]);

            ShiftTemplate::create([
                'user_id' => $u->id,
                'name' => 'Late Shift',
                'start_time' => '15:00',
                'end_time' => '23:00',
                'is_overnight' => false,
                'color' => '#8b5cf6',
            ]);

            ShiftTemplate::create([
                'user_id' => $u->id,
                'name' => 'Night Shift',
                'start_time' => '19:00',
                'end_time' => '07:00',
                'is_overnight' => true,
                'color' => '#6A3E94',
            ]);
        }

        // 3. Create Circle & Memberships
        $circle1 = Circle::create([
            'owner_id' => $adminUser->id,
            'name' => 'Department Rota Team',
            'handle' => 'department_team',
            'discoverability' => 'private',
        ]);

        $circle2 = Circle::create([
            'owner_id' => $adminUser->id,
            'name' => 'Weekend Social Circle',
            'handle' => 'weekend_social',
            'discoverability' => 'private',
        ]);

        foreach ($users as $index => $u) {
            CircleMember::create([
                'circle_id' => $circle1->id,
                'user_id' => $u->id,
                'role' => $u->id === $adminUser->id ? 'owner' : 'member',
                'member_type' => 'working',
                'visibility' => $index === 3 ? 'free_busy' : 'shifts',
                'status' => 'active',
                'joined_at' => now(),
            ]);

            CircleMember::create([
                'circle_id' => $circle2->id,
                'user_id' => $u->id,
                'role' => $u->id === $adminUser->id ? 'owner' : 'member',
                'member_type' => 'working',
                'visibility' => 'details',
                'status' => 'active',
                'joined_at' => now(),
            ]);
        }

        // 4. Generate Varied Realistic Shift Rosters for the Month
        $startOfMonth = now()->startOfMonth();
        $daysInMonth = $startOfMonth->daysInMonth;

        foreach ($users as $userIndex => $u) {
            for ($d = 1; $d <= $daysInMonth; $d++) {
                $date = $startOfMonth->copy()->addDays($d - 1);
                $dateStr = $date->format('Y-m-d');
                $dayOfWeek = $date->dayOfWeek; // 0=Sun, 6=Sat

                // Pattern variations per user
                $patternIndex = ($d + $userIndex * 3) % 7;

                if ($patternIndex === 0 || $patternIndex === 4) {
                    // Confirmed Day Off
                    ScheduleEntry::create([
                        'user_id' => $u->id,
                        'date' => $dateStr,
                        'start_time' => '00:00',
                        'end_time' => '23:59',
                        'entry_type' => 'off',
                        'label' => 'Off Day',
                        'is_overnight' => false,
                        'source' => 'manual',
                    ]);
                } elseif ($patternIndex === 1) {
                    // Early shift (07:00 - 15:00) -> free in the evening!
                    ScheduleEntry::create([
                        'user_id' => $u->id,
                        'date' => $dateStr,
                        'start_time' => '07:00',
                        'end_time' => '15:00',
                        'entry_type' => 'work',
                        'label' => 'Early Shift',
                        'is_overnight' => false,
                        'source' => 'template',
                    ]);
                } elseif ($patternIndex === 2) {
                    // Late shift (15:00 - 23:00)
                    ScheduleEntry::create([
                        'user_id' => $u->id,
                        'date' => $dateStr,
                        'start_time' => '15:00',
                        'end_time' => '23:00',
                        'entry_type' => 'work',
                        'label' => 'Late Shift',
                        'is_overnight' => false,
                        'source' => 'template',
                    ]);
                } elseif ($patternIndex === 3) {
                    // Night Shift (19:00 - 07:00)
                    ScheduleEntry::create([
                        'user_id' => $u->id,
                        'date' => $dateStr,
                        'start_time' => '19:00',
                        'end_time' => '07:00',
                        'entry_type' => 'work',
                        'label' => 'Night Duty',
                        'is_overnight' => true,
                        'source' => 'template',
                    ]);
                } elseif ($patternIndex === 5) {
                    // Annual Leave or Training
                    ScheduleEntry::create([
                        'user_id' => $u->id,
                        'date' => $dateStr,
                        'start_time' => '09:00',
                        'end_time' => '17:00',
                        'entry_type' => ($userIndex % 2 === 0) ? 'leave' : 'work',
                        'label' => ($userIndex % 2 === 0) ? 'Annual Leave' : 'STUDY / Training',
                        'is_overnight' => false,
                        'source' => 'manual',
                    ]);
                }
                // (patternIndex 6 is intentionally left as Unknown to verify missing schedule handling!)
            }
        }

        // 5. Create Sample Meetup Plan
        $planDate = now()->addDays(5)->format('Y-m-d');
        $plan = Plan::create([
            'circle_id' => $circle1->id,
            'created_by' => $adminUser->id,
            'title' => 'Team Dinner & Catchup',
            'description' => 'Celebration dinner after rota week. Great overlap window!',
            'event_type' => 'meal',
            'start_at' => Carbon::parse("{$planDate} 19:00:00"),
            'end_at' => Carbon::parse("{$planDate} 22:00:00"),
            'status' => 'confirmed',
        ]);

        foreach ($users as $u) {
            PlanMember::create([
                'plan_id' => $plan->id,
                'user_id' => $u->id,
                'rsvp_status' => $u->id === $adminUser->id ? 'attending' : 'tentative',
            ]);
        }
    }
}
