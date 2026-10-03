<?php

namespace App\Http\Controllers\Api\V1;

use App\Domain\Availability\AvailabilityEngine;
use App\Domain\Availability\AvailabilityMatcher;
use App\Domain\Availability\AvailabilityRanker;
use App\Domain\Availability\Data\UserAvailabilityContext;
use App\Domain\Availability\PrivacyFilter;
use App\Http\Controllers\Controller;
use App\Models\Circle;
use App\Models\User;
use Carbon\Carbon;
use Carbon\CarbonPeriod;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class CircleAvailabilityController extends Controller
{
    public function __construct(
        private readonly AvailabilityEngine $engine = new AvailabilityEngine(),
        private readonly AvailabilityMatcher $matcher = new AvailabilityMatcher(),
        private readonly AvailabilityRanker $ranker = new AvailabilityRanker(),
        private readonly PrivacyFilter $privacyFilter = new PrivacyFilter()
    ) {}

    public function circleMatch(Request $request, Circle $circle): JsonResponse
    {
        $request->validate([
            'start_date' => ['required', 'date_format:Y-m-d'],
            'end_date' => ['required', 'date_format:Y-m-d', 'after_or_equal:start_date'],
        ]);

        $user = $request->user();
        $myMembership = $circle->members()->where('user_id', $user->id)->first();

        if (! $myMembership || $myMembership->status !== 'active') {
            return response()->json(['message' => 'Unauthorized access to circle.'], 403);
        }

        $startDate = $request->input('start_date');
        $endDate = $request->input('end_date');

        // Fetch active working members (exclude viewer-only)
        $workingMembers = $circle->members()
            ->where('status', 'active')
            ->where('member_type', 'working')
            ->with('user')
            ->get();

        $result = $this->buildAvailabilityPayload($workingMembers, $startDate, $endDate, $circle);

        return response()->json([
            'data' => $result
        ]);
    }

    public function compareUsers(Request $request): JsonResponse
    {
        $request->validate([
            'user_ids' => ['required', 'array', 'min:2'],
            'user_ids.*' => ['required', 'integer', 'exists:users,id'],
            'start_date' => ['required', 'date_format:Y-m-d'],
            'end_date' => ['required', 'date_format:Y-m-d', 'after_or_equal:start_date'],
            'circle_id' => ['nullable', 'integer', 'exists:circles,id'],
        ]);

        $startDate = $request->input('start_date');
        $endDate = $request->input('end_date');
        $userIds = $request->input('user_ids');
        $circleId = $request->input('circle_id');

        $circle = $circleId ? Circle::find($circleId) : null;
        $users = User::whereIn('id', $userIds)->get();

        // Wrap users in pseudo-members with circle visibility if available or default to free_busy
        $pseudoMembers = $users->map(function ($u) use ($circle) {
            $visibility = 'free_busy';
            if ($circle) {
                $m = $circle->members()->where('user_id', $u->id)->first();
                if ($m) {
                    $visibility = $m->visibility;
                }
            }
            return (object)[
                'user_id' => $u->id,
                'user' => $u,
                'visibility' => $visibility,
                'member_type' => 'working',
            ];
        });

        $result = $this->buildAvailabilityPayload($pseudoMembers, $startDate, $endDate, $circle);

        return response()->json([
            'data' => $result
        ]);
    }

    private function buildAvailabilityPayload($members, string $startDate, string $endDate, ?Circle $circle = null): array
    {
        // Query starts from 1 day prior to capture overnight shifts that cross into startDate
        $queryStartDate = Carbon::parse($startDate)->subDay()->format('Y-m-d');
        $period = CarbonPeriod::create($startDate, $endDate);
        $periodDates = [];
        foreach ($period as $d) {
            $periodDates[] = $d->format('Y-m-d');
        }

        $memberDailyAvailability = [];
        $memberRosterData = [];

        foreach ($members as $member) {
            $mUser = $member->user;
            if (! $mUser) continue;

            $schedules = $mUser->scheduleEntries()
                ->where('date', '>=', $queryStartDate)
                ->where('date', '<=', $endDate)
                ->get();

            $overrides = $mUser->availabilityOverrides()
                ->where('date', '>=', $queryStartDate)
                ->where('date', '<=', $endDate)
                ->get();

            $context = new UserAvailabilityContext(
                userId: $mUser->id,
                scheduleEntries: $schedules,
                availabilityOverrides: $overrides,
                startDate: $startDate,
                endDate: $endDate
            );

            $rawIntervals = $this->engine->calculate($context);
            $memberDailyAvailability[$mUser->id] = $rawIntervals;

            // Compute rota cell representation per date with privacy
            $dailyStatus = [];
            $schedulesByDate = $schedules->keyBy(fn($s) => $s->date instanceof \DateTimeInterface ? $s->date->format('Y-m-d') : (string)$s->date);

            foreach ($periodDates as $dateStr) {
                $entry = $schedulesByDate->get($dateStr);
                $dailyStatus[$dateStr] = $this->formatMemberDateStatus($entry, $rawIntervals[$dateStr] ?? [], $member->visibility);
            }

            $memberRosterData[] = [
                'user' => [
                    'id' => $mUser->id,
                    'name' => $mUser->name,
                    'handle' => $mUser->handle,
                    'initials' => $this->getInitials($mUser->name),
                ],
                'visibility' => $member->visibility,
                'daily_status' => $dailyStatus,
                'availability' => $this->privacyFilter->filterAvailability($rawIntervals, $member->visibility),
            ];
        }

        // 1. Calculate Common Off Time & Magic Hours (Interval intersections)
        $dailyCommon = [];
        $offTimeSummary = [];
        $daysOffSummary = [];

        $totalMembersCount = count($members);

        foreach ($periodDates as $dateStr) {
            // Off Time (intersection across all working members)
            $usersDateAvailability = [];
            foreach ($members as $member) {
                if (isset($memberDailyAvailability[$member->user_id][$dateStr])) {
                    $usersDateAvailability[$member->user_id] = $memberDailyAvailability[$member->user_id][$dateStr];
                }
            }

            $commonIntervals = $this->matcher->findCommonAvailability($usersDateAvailability);
            $dailyCommon[$dateStr] = $commonIntervals;

            // Find best window in common intervals
            $bestWindow = null;
            $bestDuration = 0;
            foreach ($commonIntervals as $int) {
                $startC = Carbon::parse("{$dateStr} {$int['start']}");
                $endHour = $int['end'] === '24:00' ? '23:59:59' : $int['end'];
                $endC = Carbon::parse("{$dateStr} {$endHour}");
                $durMin = $startC->diffInMinutes($endC);
                if ($durMin > $bestDuration) {
                    $bestDuration = $durMin;
                    $bestWindow = [
                        'start' => $int['start'],
                        'end' => $int['end'],
                        'duration_minutes' => $durMin,
                        'duration_formatted' => round($durMin / 60, 1) . ' hrs',
                    ];
                }
            }

            // Who is free during Off Time vs Days Off on this date?
            $confirmedOffMembers = [];
            $workingMembersList = [];
            $unknownMembersList = [];

            foreach ($memberRosterData as $mRoster) {
                $statusObj = $mRoster['daily_status'][$dateStr] ?? null;
                $userSummary = $mRoster['user'];

                if ($statusObj && $statusObj['is_day_off']) {
                    $confirmedOffMembers[] = $userSummary;
                } elseif ($statusObj && $statusObj['status'] === 'unknown') {
                    $unknownMembersList[] = $userSummary;
                } else {
                    $workingMembersList[] = $userSummary;
                }
            }

            $offCount = count($confirmedOffMembers);
            $daysOffSummary[$dateStr] = [
                'free_count' => $offCount,
                'total_count' => $totalMembersCount,
                'all_free' => ($totalMembersCount > 0 && $offCount === $totalMembersCount),
                'free_members' => $confirmedOffMembers,
                'working_members' => $workingMembersList,
                'unknown_members' => $unknownMembersList,
            ];

            // Off Time Summary (overlap)
            $hasCommonOverlap = !empty($commonIntervals) && $bestWindow !== null && $bestWindow['duration_minutes'] >= 60;
            $offTimeSummary[$dateStr] = [
                'best_window' => $bestWindow,
                'has_overlap' => $hasCommonOverlap,
                'free_count' => $hasCommonOverlap ? $totalMembersCount : $offCount,
                'total_count' => $totalMembersCount,
                'all_free' => $hasCommonOverlap,
                'free_members' => $hasCommonOverlap ? array_map(fn($m) => $m['user'], $memberRosterData) : $confirmedOffMembers,
                'common_intervals' => $commonIntervals,
            ];
        }

        // Suggestions
        $suggestions = $this->ranker->rankSuggestions($dailyCommon, $totalMembersCount);

        // Fetch existing plans in circle for this date range
        $plans = [];
        if ($circle) {
            $plans = $circle->plans()
                ->where('start_at', '>=', Carbon::parse($startDate)->startOfDay())
                ->where('start_at', '<=', Carbon::parse($endDate)->endOfDay())
                ->with(['creator', 'locations.votes', 'members.user'])
                ->get()
                ->map(function ($plan) {
                    return [
                        'id' => $plan->id,
                        'title' => $plan->title,
                        'event_type' => $plan->event_type,
                        'date' => $plan->start_at->format('Y-m-d'),
                        'start_time' => $plan->start_at->format('H:i'),
                        'end_time' => $plan->end_at ? $plan->end_at->format('H:i') : null,
                        'status' => $plan->status,
                        'created_by' => $plan->creator ? $plan->creator->name : 'Member',
                        'members_count' => $plan->members->count(),
                    ];
                });
        }

        return [
            'members' => $memberRosterData,
            'common_availability' => $dailyCommon,
            'days_off' => $daysOffSummary,
            'off_time' => $offTimeSummary,
            'suggestions' => $suggestions,
            'plans' => $plans,
        ];
    }

    private function formatMemberDateStatus($entry, array $availableIntervals, string $visibility): array
    {
        if (! $entry) {
            // Missing schedule: Unknown and NEVER free
            return [
                'status' => 'unknown',
                'label' => 'Unknown Schedule',
                'short_code' => '—',
                'is_day_off' => false,
                'is_overnight' => false,
            ];
        }

        if ($entry->entry_type === 'off') {
            return [
                'status' => 'off',
                'label' => 'Off Day',
                'short_code' => 'OFF',
                'is_day_off' => true,
                'is_overnight' => false,
            ];
        }

        if ($entry->entry_type === 'leave') {
            return [
                'status' => 'leave',
                'label' => $visibility === 'free_busy' ? 'Unavailable' : ($entry->label ?: 'Annual Leave'),
                'short_code' => 'A/L',
                'is_day_off' => true,
                'is_overnight' => false,
            ];
        }

        $labelUpper = strtoupper($entry->label ?? '');
        $isStudy = str_contains($labelUpper, 'STUDY') || str_contains($labelUpper, 'EDT') || str_contains($labelUpper, 'DEV') || str_contains($labelUpper, 'TRAIN');

        if ($isStudy) {
            return [
                'status' => 'study',
                'label' => $visibility === 'free_busy' ? 'Busy' : ($entry->label ?: 'Study / Dev'),
                'short_code' => str_contains($labelUpper, 'DEV') ? 'DEV' : (str_contains($labelUpper, 'EDT') ? 'EDT' : 'STUDY'),
                'is_day_off' => false,
                'start_time' => substr((string)$entry->start_time, 0, 5),
                'end_time' => substr((string)$entry->end_time, 0, 5),
                'is_overnight' => (bool)$entry->is_overnight,
            ];
        }

        // Work shift
        $startShort = substr((string)$entry->start_time, 0, 2);
        $endShort = substr((string)$entry->end_time, 0, 2);
        $shortCode = "{$startShort}–{$endShort}";

        if ($visibility === 'free_busy') {
            return [
                'status' => 'busy',
                'label' => 'Busy',
                'short_code' => 'BUSY',
                'is_day_off' => false,
                'start_time' => substr((string)$entry->start_time, 0, 5),
                'end_time' => substr((string)$entry->end_time, 0, 5),
                'is_overnight' => (bool)$entry->is_overnight,
            ];
        }

        return [
            'status' => 'work',
            'label' => $entry->label ?: 'Work Shift',
            'short_code' => $shortCode,
            'is_day_off' => false,
            'start_time' => substr((string)$entry->start_time, 0, 5),
            'end_time' => substr((string)$entry->end_time, 0, 5),
            'is_overnight' => (bool)$entry->is_overnight,
            'notes' => $visibility === 'details' ? $entry->notes : null,
        ];
    }

    private function getInitials(?string $name): string
    {
        if (! $name) return '?';
        $parts = preg_split('/\s+/', trim($name));
        if (count($parts) >= 2) {
            return strtoupper(substr($parts[0], 0, 1) . substr($parts[1], 0, 1));
        }
        return strtoupper(substr($name, 0, 2));
    }
}
