<?php

namespace Database\Seeders;

use App\Models\ScheduleEntry;
use App\Models\ShiftTemplate;
use App\Models\User;
use Illuminate\Database\Seeder;
use Illuminate\Support\Facades\Hash;

class DatabaseSeeder extends Seeder
{
    public function run(): void
    {
        // 1. Create main Demo User
        $demoUser = User::create([
            'name' => 'Hamza (Demo)',
            'email' => 'demo@example.com',
            'password' => Hash::make('password'),
            'handle' => 'hamza_demo',
            'handle_visibility' => 'public',
            'timezone' => 'Asia/Karachi',
        ]);

        $alice = User::create([
            'name' => 'Alice Johnson',
            'email' => 'alice@example.com',
            'password' => Hash::make('password'),
            'handle' => 'alice_j',
            'handle_visibility' => 'public',
            'timezone' => 'America/New_York',
        ]);

        $bob = User::create([
            'name' => 'Bob Miller',
            'email' => 'bob@example.com',
            'password' => Hash::make('password'),
            'handle' => 'bob_m',
            'handle_visibility' => 'public',
            'timezone' => 'Europe/London',
        ]);

        // 2. Create Shift Templates for Demo User
        $earlyTpl = ShiftTemplate::create([
            'user_id' => $demoUser->id,
            'name' => 'Early Shift',
            'start_time' => '07:00',
            'end_time' => '15:00',
            'is_overnight' => false,
            'color' => '#3b82f6',
        ]);

        $lateTpl = ShiftTemplate::create([
            'user_id' => $demoUser->id,
            'name' => 'Late Shift',
            'start_time' => '15:00',
            'end_time' => '23:00',
            'is_overnight' => false,
            'color' => '#8b5cf6',
        ]);

        $nightTpl = ShiftTemplate::create([
            'user_id' => $demoUser->id,
            'name' => 'Night Shift',
            'start_time' => '22:00',
            'end_time' => '06:00',
            'is_overnight' => true,
            'color' => '#ec4899',
        ]);

        // 3. Create Sample Schedule Entries
        $today = now();
        for ($i = 1; $i <= 10; $i++) {
            $dateStr = $today->copy()->addDays($i)->format('Y-m-d');
            $tpl = ($i % 3 === 0) ? $nightTpl : (($i % 2 === 0) ? $lateTpl : $earlyTpl);

            ScheduleEntry::create([
                'user_id' => $demoUser->id,
                'shift_template_id' => $tpl->id,
                'date' => $dateStr,
                'start_time' => $tpl->start_time,
                'end_time' => $tpl->end_time,
                'timezone' => $demoUser->timezone,
                'entry_type' => 'work',
                'label' => $tpl->name,
                'is_overnight' => $tpl->is_overnight,
                'source' => 'template',
            ]);
        }
    }
}
