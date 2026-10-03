"use client";

import { useEffect, useState } from "react";
import { useSearchParams, useRouter } from "next/navigation";
import { apiClient } from "@/lib/api-client";
import { CircleAvailabilityGrid } from "@/features/matching/components/circle-availability-grid";
import { SuggestedTimesCard } from "@/features/matching/components/suggested-times-card";
import { PersonalCompareTool } from "@/features/compare/components/personal-compare-tool";
import { Sliders, Calendar as CalendarIcon, Sparkles, Users, Loader2 } from "lucide-react";
import { Circle } from "@/types/api";

import { sessionCache } from "@/lib/session-cache";

interface CompareMember {
  id: number;
  name: string;
  handle: string | null;
}

export function CompareContent() {
  const searchParams = useSearchParams();
  const circleIdParam = searchParams.get("circle");
  const router = useRouter();

  const todayStr = new Date().toISOString().slice(0, 10);
  const futureStr = new Date(Date.now() + 7 * 24 * 60 * 60 * 1000).toISOString().slice(0, 10);

  const [startDate, setStartDate] = useState(todayStr);
  const [endDate, setEndDate] = useState(futureStr);
  
  const cachedCircles = sessionCache.get<Circle[]>("user_circles");
  const [circles, setCircles] = useState<Circle[]>(cachedCircles || []);
  const [selectedCircleId, setSelectedCircleId] = useState<number | null>(() => {
    if (cachedCircles && cachedCircles.length > 0) {
      const paramId = circleIdParam ? parseInt(circleIdParam, 10) : null;
      return cachedCircles.find((c) => c.id === paramId)?.id || cachedCircles[0].id;
    }
    return null;
  });

  const cachedDetail = selectedCircleId ? sessionCache.get<any>(`circle_detail_${selectedCircleId}`) : null;
  const initialMembers: CompareMember[] = cachedDetail?.members
    ? cachedDetail.members
        .filter((m: any) => m.status === "active" && m.user)
        .map((m: any) => ({
          id: m.user.id,
          name: m.user.name,
          handle: m.user.handle || null,
        }))
    : [];

  const initialMatchKey = selectedCircleId && initialMembers.length >= 2
    ? `compare_${selectedCircleId}_${initialMembers.map((m) => m.id).sort().join("_")}_${todayStr}_${futureStr}`
    : null;
  const cachedMatch = initialMatchKey ? sessionCache.get<any>(initialMatchKey) : null;

  const [activeCircle, setActiveCircle] = useState<Circle | null>(cachedDetail || null);
  const [availableMembers, setAvailableMembers] = useState<CompareMember[]>(initialMembers);
  const [selectedUserIds, setSelectedUserIds] = useState<number[]>(initialMembers.map((m) => m.id));

  const [matchData, setMatchData] = useState<{
    members: any[];
    common_availability: Record<string, any[]>;
    suggestions: any[];
  } | null>(cachedMatch);
  
  const [isLoadingCircles, setIsLoadingCircles] = useState(!cachedCircles);
  const [isLoadingMatch, setIsLoadingMatch] = useState(!cachedDetail || (initialMembers.length >= 2 && !cachedMatch));

  // 1. Fetch user circles on mount
  useEffect(() => {
    const fetchCircles = async () => {
      if (!sessionCache.has("user_circles")) {
        setIsLoadingCircles(true);
      }
      try {
        const res = await apiClient.get<{ data: Circle[] }>("/circles");
        const list = res.data || [];
        setCircles(list);
        sessionCache.set("user_circles", list);

        if (list.length > 0 && !selectedCircleId) {
          const paramId = circleIdParam ? parseInt(circleIdParam, 10) : null;
          const initialCircle = list.find((c) => c.id === paramId) || list[0];
          setSelectedCircleId(initialCircle.id);
        }
      } catch (err) {
        console.error("Failed to fetch user circles", err);
      } finally {
        setIsLoadingCircles(false);
      }
    };

    fetchCircles();
  }, [circleIdParam]);

  // 2. Fetch full circle details (with real members) when selected circle changes
  useEffect(() => {
    if (!selectedCircleId) return;

    const detailCacheKey = `circle_detail_${selectedCircleId}`;
    const cached = sessionCache.get<any>(detailCacheKey);

    const fetchCircleDetails = async (forceRefetch = false) => {
      if (forceRefetch || !cached) {
        if (!cached) setIsLoadingMatch(true);
        try {
          const res = await apiClient.get<{ data: Circle & { members?: any[] } }>(`/circles/${selectedCircleId}`);
          const circleData = res.data;
          setActiveCircle(circleData);
          sessionCache.set(detailCacheKey, circleData);

          const realMembers: CompareMember[] = (circleData.members || [])
            .filter((m: any) => m.status === "active" && m.user)
            .map((m: any) => ({
              id: m.user.id,
              name: m.user.name,
              handle: m.user.handle || null,
            }));

          setAvailableMembers(realMembers);
          const memberIds = realMembers.map((m) => m.id);
          setSelectedUserIds(memberIds);

          if (memberIds.length >= 2) {
            await runComparison(memberIds);
          } else {
            setMatchData(null);
            setIsLoadingMatch(false);
          }
        } catch (err) {
          console.error("Failed to fetch circle details", err);
          setIsLoadingMatch(false);
        }
      } else {
        // Cached detail exists
        setActiveCircle(cached);
        const realMembers: CompareMember[] = (cached.members || [])
          .filter((m: any) => m.status === "active" && m.user)
          .map((m: any) => ({
            id: m.user.id,
            name: m.user.name,
            handle: m.user.handle || null,
          }));
        setAvailableMembers(realMembers);
        const memberIds = realMembers.map((m) => m.id);
        setSelectedUserIds(memberIds);
        if (memberIds.length >= 2) {
          await runComparison(memberIds);
        } else {
          setMatchData(null);
          setIsLoadingMatch(false);
        }
      }
    };

    fetchCircleDetails();
  }, [selectedCircleId, startDate, endDate]);

  const runComparison = async (userIdsToCompare: number[]) => {
    if (userIdsToCompare.length < 2) return;
    const matchCacheKey = `compare_${selectedCircleId}_${userIdsToCompare.sort().join("_")}_${startDate}_${endDate}`;
    const cachedMatch = sessionCache.get<any>(matchCacheKey);
    if (cachedMatch) {
      setMatchData(cachedMatch);
      return;
    }

    setIsLoadingMatch(true);
    try {
      const res = await apiClient.post<{ data: any }>("/availability/compare", {
        user_ids: userIdsToCompare,
        start_date: startDate,
        end_date: endDate,
      });
      setMatchData(res.data);
      sessionCache.set(matchCacheKey, res.data);
    } catch (err) {
      console.error("Failed to run availability comparison", err);
    } finally {
      setIsLoadingMatch(false);
    }
  };

  const handleToggleUser = (userId: number) => {
    const isSelected = selectedUserIds.includes(userId);
    const updatedIds = isSelected
      ? selectedUserIds.filter((id) => id !== userId)
      : [...selectedUserIds, userId];

    setSelectedUserIds(updatedIds);
    if (updatedIds.length >= 2) {
      runComparison(updatedIds);
    }
  };

  const handleSelectAll = () => {
    const allIds = availableMembers.map((m) => m.id);
    setSelectedUserIds(allIds);
    if (allIds.length >= 2) {
      runComparison(allIds);
    }
  };

  const handleDeselectAll = () => {
    setSelectedUserIds([]);
    setMatchData(null);
  };

  const handleProposePlan = (suggestion: any) => {
    router.push(`/plans?create=true&date=${suggestion.date}&start=${suggestion.start}&end=${suggestion.end}`);
  };

  return (
    <div className="max-w-6xl mx-auto space-y-6 md:space-y-8">
      {/* Header Controls Banner */}
      <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-4 bg-white border border-[#E8E5DF] rounded-2xl p-5 md:p-6 shadow-xs">
        <div className="flex items-start gap-3.5">
          <div className="w-10 h-10 rounded-xl bg-[#81D8D0]/20 border border-[#81D8D0]/40 flex items-center justify-center shrink-0 mt-0.5 shadow-xs">
            <Sliders className="w-5 h-5 text-[#1D5E57]" />
          </div>
          <div>
            <div className="flex items-center gap-2">
              <h1 className="text-xl font-bold text-[#1F2223] tracking-tight">
                Schedule Match & Comparison
              </h1>
              <span className="inline-flex items-center gap-1 px-2 py-0.5 rounded-full bg-[#D7D982]/25 text-[#5C5E1A] text-[10px] font-mono font-semibold">
                <Sparkles className="w-3 h-3 text-[#2B7A72]" /> Magic Hour Active
              </span>
            </div>
            <p className="text-xs text-[#656A6D] mt-1 leading-relaxed">
              Calculate real N-way availability intersections across your circle members without exposing private shift details.
            </p>
          </div>
        </div>

        {/* Circle Selector & Date Range */}
        <div className="flex flex-wrap items-center gap-2.5 shrink-0">
          {/* Circle Selector Dropdown */}
          <div className="flex items-center gap-2 bg-[#FAF9F6] border border-[#E8E5DF] rounded-xl px-3 py-2 text-xs shadow-xs">
            <Users className="w-4 h-4 text-[#2B7A72]" />
            <select
              value={selectedCircleId || ""}
              onChange={(e) => setSelectedCircleId(Number(e.target.value))}
              disabled={isLoadingCircles || circles.length === 0}
              className="bg-transparent text-[#1F2223] font-semibold outline-none cursor-pointer text-xs"
            >
              {circles.length === 0 ? (
                <option value="">No Circles Available</option>
              ) : (
                circles.map((c) => (
                  <option key={c.id} value={c.id}>
                    {c.name}
                  </option>
                ))
              )}
            </select>
          </div>

          {/* Date Range Selector */}
          <div className="flex items-center gap-2 bg-[#FAF9F6] border border-[#E8E5DF] rounded-xl px-3 py-2 text-xs shadow-xs">
            <CalendarIcon className="w-4 h-4 text-[#2B7A72]" />
            <input
              type="date"
              value={startDate}
              onChange={(e) => setStartDate(e.target.value)}
              className="bg-transparent text-[#1F2223] font-mono font-semibold outline-none cursor-pointer"
            />
            <span className="text-[#959A9E] font-mono">—</span>
            <input
              type="date"
              value={endDate}
              onChange={(e) => setEndDate(e.target.value)}
              className="bg-transparent text-[#1F2223] font-mono font-semibold outline-none cursor-pointer"
            />
          </div>
        </div>
      </div>

      {isLoadingCircles ? (
        <div className="py-12 flex justify-center items-center">
          <Loader2 className="w-8 h-8 text-[#2B7A72] animate-spin" />
        </div>
      ) : (
        <>
          {/* Member Selection & Personal Compare Tool */}
          <PersonalCompareTool
            availableMembers={availableMembers}
            selectedUserIds={selectedUserIds}
            onToggleUser={handleToggleUser}
            onSelectAll={handleSelectAll}
            onDeselectAll={handleDeselectAll}
            onRunCompare={() => runComparison(selectedUserIds)}
            isLoading={isLoadingMatch}
            circleName={activeCircle?.name}
          />

          {/* Suggested Magic Hours */}
          <div className="space-y-6 md:space-y-8">
            <SuggestedTimesCard
              suggestions={matchData?.suggestions || []}
              onProposePlan={handleProposePlan}
              isLoading={isLoadingMatch}
            />

            {/* Grid View */}
            <CircleAvailabilityGrid
              members={matchData?.members || []}
              commonAvailability={matchData?.common_availability || {}}
              startDate={startDate}
              endDate={endDate}
              isLoading={isLoadingMatch}
            />
          </div>
        </>
      )}
    </div>
  );
}

export default function ComparePage() {
  return <CompareContent />;
}
