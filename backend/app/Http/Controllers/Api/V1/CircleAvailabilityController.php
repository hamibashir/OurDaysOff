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

        // Fetch only working members
        $workingMembers = $circle->members()
            ->where('status', 'active')
            ->where('member_type', 'working')
            ->with('user')
            ->get();

        $memberDailyAvailability = [];
        $filteredMemberAvailability = [];

        foreach ($workingMembers as $member) {
            $mUser = $member->user;
            if (! $mUser) continue;

            $schedules = $mUser->scheduleEntries()
                ->where('date', '>=', $startDate)
                ->where('date', '<=', $endDate)
                ->get();

            $overrides = $mUser->availabilityOverrides()
                ->where('date', '>=', $startDate)
                ->where('date', '<=', $endDate)
                ->get();

            $context = new UserAvailabilityContext(
                userId: $mUser->id,
                scheduleEntries: $schedules,
                availabilityOverrides: $overrides,
                startDate: $startDate,
                endDate: $endDate
            );

            $raw = $this->engine->calculate($context);
            $memberDailyAvailability[$mUser->id] = $raw;

            // Apply privacy filter based on member's configured visibility
            $filteredMemberAvailability[$mUser->id] = [
                'user' => [
                    'id' => $mUser->id,
                    'name' => $mUser->name,
                    'handle' => $mUser->handle,
                ],
                'visibility' => $member->visibility,
                'availability' => $this->privacyFilter->filterAvailability($raw, $member->visibility),
            ];
        }

        // Calculate common intersection per date across working members
        $dailyCommon = [];
        $periodDates = array_keys(reset($memberDailyAvailability) ?: []);

        foreach ($periodDates as $dateStr) {
            $usersDateAvailability = [];
            foreach ($workingMembers as $member) {
                if (isset($memberDailyAvailability[$member->user_id][$dateStr])) {
                    $usersDateAvailability[$member->user_id] = $memberDailyAvailability[$member->user_id][$dateStr];
                }
            }
            $dailyCommon[$dateStr] = $this->matcher->findCommonAvailability($usersDateAvailability);
        }

        // Compute rank suggestions & Magic Hours
        $suggestions = $this->ranker->rankSuggestions($dailyCommon, $workingMembers->count());

        return response()->json([
            'data' => [
                'members' => array_values($filteredMemberAvailability),
                'common_availability' => $dailyCommon,
                'suggestions' => $suggestions,
            ]
        ]);
    }

    public function compareUsers(Request $request): JsonResponse
    {
        $request->validate([
            'user_ids' => ['required', 'array', 'min:2'],
            'user_ids.*' => ['required', 'integer', 'exists:users,id'],
            'start_date' => ['required', 'date_format:Y-m-d'],
            'end_date' => ['required', 'date_format:Y-m-d', 'after_or_equal:start_date'],
        ]);

        $startDate = $request->input('start_date');
        $endDate = $request->input('end_date');
        $userIds = $request->input('user_ids');

        $users = User::whereIn('id', $userIds)->get();
        $memberDailyAvailability = [];
        $filteredMemberAvailability = [];

        foreach ($users as $mUser) {
            $schedules = $mUser->scheduleEntries()
                ->where('date', '>=', $startDate)
                ->where('date', '<=', $endDate)
                ->get();

            $overrides = $mUser->availabilityOverrides()
                ->where('date', '>=', $startDate)
                ->where('date', '<=', $endDate)
                ->get();

            $context = new UserAvailabilityContext(
                userId: $mUser->id,
                scheduleEntries: $schedules,
                availabilityOverrides: $overrides,
                startDate: $startDate,
                endDate: $endDate
            );

            $raw = $this->engine->calculate($context);
            $memberDailyAvailability[$mUser->id] = $raw;

            // Default privacy for ad-hoc compare is free_busy
            $filteredMemberAvailability[$mUser->id] = [
                'user' => [
                    'id' => $mUser->id,
                    'name' => $mUser->name,
                    'handle' => $mUser->handle,
                ],
                'visibility' => 'free_busy',
                'availability' => $this->privacyFilter->filterAvailability($raw, 'free_busy'),
            ];
        }

        $dailyCommon = [];
        $periodDates = array_keys(reset($memberDailyAvailability) ?: []);

        foreach ($periodDates as $dateStr) {
            $usersDateAvailability = [];
            foreach ($users as $mUser) {
                if (isset($memberDailyAvailability[$mUser->id][$dateStr])) {
                    $usersDateAvailability[$mUser->id] = $memberDailyAvailability[$mUser->id][$dateStr];
                }
            }
            $dailyCommon[$dateStr] = $this->matcher->findCommonAvailability($usersDateAvailability);
        }

        $suggestions = $this->ranker->rankSuggestions($dailyCommon, $users->count());

        return response()->json([
            'data' => [
                'members' => array_values($filteredMemberAvailability),
                'common_availability' => $dailyCommon,
                'suggestions' => $suggestions,
            ]
        ]);
    }
}
