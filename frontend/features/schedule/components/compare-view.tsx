"use client";

import { useState, useEffect, useMemo } from "react";
import { CircleRosterMember, CirclePlanSummary, CircleAvailabilityResponseData } from "@/types/api";
import { apiClient } from "@/lib/api-client";
import { Users, Sparkles, Check, Info, Calendar as CalendarIcon, Loader2 } from "lucide-react";
import { MonthCalendar } from "./month-calendar";

interface CompareViewProps {
  currentDate: Date;
  circleId: number | null;
  members: CircleRosterMember[];
  plans: CirclePlanSummary[];
  onNavigateMonth: (direction: "prev" | "next") => void;
  onSelectDate: (dateStr: string) => void;
  selectedDate: string | null;
  availabilityMode: "days_off" | "off_time";
  onToggleAvailabilityMode: (mode: "days_off" | "off_time") => void;
  onCreatePlanFromOverlap: (dateStr: string, window: { start: string; end: string }) => void;
}

export function CompareView({
  currentDate,
  circleId,
  members,
  plans,
  onNavigateMonth,
  onSelectDate,
  selectedDate,
  availabilityMode,
  onToggleAvailabilityMode,
  onCreatePlanFromOverlap,
}: CompareViewProps) {
  const storageKey = circleId ? `odo_compare_selection_${circleId}` : null;

  // Initialize selected members from localStorage or first 2 members
  const [selectedUserIds, setSelectedUserIds] = useState<number[]>(() => {
    if (typeof window === "undefined" || !storageKey) {
      return members.slice(0, 2).map((m) => m.user.id);
    }
    try {
      const saved = localStorage.getItem(storageKey);
      if (saved) {
        const parsed = JSON.parse(saved);
        const validIds = parsed.filter((id: number) => members.some((m) => m.user.id === id));
        if (validIds.length >= 2) return validIds;
      }
    } catch (e) {
      // ignore
    }
    return members.slice(0, 2).map((m) => m.user.id);
  });

  const [compareData, setCompareData] = useState<CircleAvailabilityResponseData | null>(null);
  const [isLoading, setIsLoading] = useState(false);

  // Sync selected members when circle changes
  useEffect(() => {
    if (!storageKey) return;
    try {
      const saved = localStorage.getItem(storageKey);
      if (saved) {
        const parsed = JSON.parse(saved);
        const validIds = parsed.filter((id: number) => members.some((m) => m.user.id === id));
        if (validIds.length >= 2) {
          setSelectedUserIds(validIds);
          return;
        }
      }
    } catch (e) {}

    // Default to all working members if <= 4 or first 2
    const defaultIds = members.length >= 2 ? members.slice(0, Math.min(4, members.length)).map((m) => m.user.id) : [];
    setSelectedUserIds(defaultIds);
  }, [circleId, members.length]);

  // Persist to localStorage when selection changes
  useEffect(() => {
    if (storageKey && selectedUserIds.length >= 2) {
      try {
        localStorage.setItem(storageKey, JSON.stringify(selectedUserIds));
      } catch (e) {}
    }
  }, [storageKey, selectedUserIds]);

  const year = currentDate.getFullYear();
  const month = currentDate.getMonth();
  const monthStr = String(month + 1).padStart(2, "0");
  const startDate = `${year}-${monthStr}-01`;
  const lastDay = new Date(year, month + 1, 0).getDate();
  const endDate = `${year}-${monthStr}-${String(lastDay).padStart(2, "0")}`;

  // Fetch compare calculations whenever selection or month changes
  useEffect(() => {
    if (selectedUserIds.length < 2) {
      setCompareData(null);
      return;
    }

    let isMounted = true;
    const fetchCompare = async () => {
      setIsLoading(true);
      try {
        const res = await apiClient.post<{ data: CircleAvailabilityResponseData }>("/availability/compare", {
          user_ids: selectedUserIds,
          start_date: startDate,
          end_date: endDate,
          circle_id: circleId || undefined,
        });
        if (isMounted) {
          setCompareData(res.data);
        }
      } catch (err) {
        console.error("Failed to run compare", err);
      } finally {
        if (isMounted) setIsLoading(false);
      }
    };

    fetchCompare();

    return () => {
      isMounted = false;
    };
  }, [selectedUserIds, startDate, endDate, circleId]);

  const handleToggleMember = (userId: number) => {
    setSelectedUserIds((prev) => {
      if (prev.includes(userId)) {
        return prev.filter((id) => id !== userId);
      } else {
        return [...prev, userId];
      }
    });
  };

  const handleSelectAll = () => {
    setSelectedUserIds(members.map((m) => m.user.id));
  };

  const handleClearSelection = () => {
    setSelectedUserIds([]);
  };

  const selectedMembers = useMemo(() => {
    return members.filter((m) => selectedUserIds.includes(m.user.id));
  }, [members, selectedUserIds]);

  return (
    <div className="space-y-6">
      {/* Selection Chip Bar Card */}
      <div className="bg-white border border-[#E8E5DF] rounded-2xl p-5 shadow-xs space-y-4">
        <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-3">
          <div className="flex items-center gap-2.5">
            <div className="w-8 h-8 rounded-lg bg-[#81D8D0]/20 border border-[#81D8D0]/40 flex items-center justify-center">
              <Users className="w-4 h-4 text-[#1D5E57]" />
            </div>
            <div>
              <h3 className="text-sm font-bold text-[#1F2223] tracking-tight">
                Compare Selected Circle Members
              </h3>
              <p className="text-xs text-[#656A6D]">
                Select any 2 or more people to calculate exact shared Days Off or Magic Hour free windows.
              </p>
            </div>
          </div>

          <div className="flex items-center gap-2">
            <button
              onClick={handleSelectAll}
              className="text-xs font-semibold text-[#2B7A72] hover:text-[#1D5E57] hover:underline"
            >
              Select All
            </button>
            <span className="text-zinc-300">|</span>
            <button
              onClick={handleClearSelection}
              className="text-xs font-semibold text-[#656A6D] hover:text-[#1F2223] hover:underline"
            >
              Clear
            </button>
          </div>
        </div>

        {/* Member Selectable Chips */}
        <div className="flex flex-wrap gap-2 pt-1">
          {members.map((m) => {
            const isSelected = selectedUserIds.includes(m.user.id);
            return (
              <button
                key={m.user.id}
                onClick={() => handleToggleMember(m.user.id)}
                className={`px-3 py-2 rounded-xl text-xs font-semibold transition-all flex items-center gap-2 border shadow-xs ${
                  isSelected
                    ? "bg-[#2B7A72] text-white border-[#2B7A72] ring-2 ring-[#81D8D0]/40"
                    : "bg-white text-[#4B5054] border-[#E8E5DF] hover:bg-[#FAF9F6] hover:text-[#1F2223]"
                }`}
              >
                <span
                  className={`w-5 h-5 rounded-full text-[9px] font-bold flex items-center justify-center uppercase ${
                    isSelected ? "bg-white/20 text-white" : "bg-[#81D8D0]/25 text-[#1D5E57]"
                  }`}
                >
                  {m.user.initials}
                </span>
                <span>{m.user.name}</span>
                {isSelected && <Check className="w-3.5 h-3.5 text-[#D7D982]" />}
              </button>
            );
          })}
        </div>

        {/* Validation Warning if < 2 selected */}
        {selectedUserIds.length < 2 && (
          <div className="p-3 bg-amber-50 border border-amber-200 rounded-xl flex items-center gap-2 text-xs text-amber-800">
            <Info className="w-4 h-4 shrink-0" />
            <span>Please select at least <strong>2 people</strong> to compute shared availability comparisons.</span>
          </div>
        )}
      </div>

      {/* Compare Results Calendar and Top Overlap Opportunities */}
      {selectedUserIds.length >= 2 && compareData && (
        <div className="space-y-6">
          {/* Top Ranked Overlap Windows for Selected Members */}
          {compareData.suggestions && compareData.suggestions.length > 0 && (
            <div className="bg-gradient-to-br from-[#81D8D0]/15 to-[#D7D982]/15 border border-[#81D8D0]/40 rounded-2xl p-5 shadow-xs space-y-3">
              <div className="flex items-center justify-between">
                <span className="inline-flex items-center gap-1.5 text-xs font-bold text-[#1D5E57] uppercase tracking-wider">
                  <Sparkles className="w-4 h-4 text-[#2B7A72]" /> Top Mutual Magic Hours ({selectedUserIds.length} members)
                </span>
                <span className="text-[11px] text-[#656A6D]">Click date or plan to lock in a meetup</span>
              </div>

              <div className="grid grid-cols-1 sm:grid-cols-2 md:grid-cols-3 gap-3">
                {compareData.suggestions.slice(0, 3).map((sug, i) => (
                  <div
                    key={i}
                    onClick={() => {
                      onSelectDate(sug.date);
                      onCreatePlanFromOverlap(sug.date, { start: sug.start, end: sug.end });
                    }}
                    className="p-3.5 bg-white border border-[#81D8D0]/50 hover:border-[#2B7A72] rounded-xl cursor-pointer transition-all hover:shadow-sm space-y-1.5 group"
                  >
                    <div className="flex items-center justify-between">
                      <span className="text-xs font-bold text-[#1F2223] font-mono group-hover:text-[#1D5E57]">
                        {sug.date}
                      </span>
                      <span className="px-1.5 py-0.5 rounded bg-[#81D8D0]/30 text-[#1D5E57] text-[10px] font-bold font-mono">
                        {sug.duration_hours} hrs
                      </span>
                    </div>
                    <p className="text-xs text-[#2B7A72] font-semibold">
                      {sug.start} – {sug.end}
                    </p>
                    <p className="text-[10px] text-[#656A6D]">
                      All {selectedUserIds.length} selected free
                    </p>
                  </div>
                ))}
              </div>
            </div>
          )}

          {/* Month Calendar using the compare calculations */}
          <MonthCalendar
            currentDate={currentDate}
            onNavigateMonth={onNavigateMonth}
            onSelectDate={onSelectDate}
            selectedDate={selectedDate}
            availabilityMode={availabilityMode}
            viewPerspective="group"
            selectedMemberId={null}
            members={compareData.members || []}
            daysOff={compareData.days_off || {}}
            offTime={compareData.off_time || {}}
            plans={plans}
            personalEntries={[]}
            currentUserId={null}
            isLoading={isLoading}
          />
        </div>
      )}
    </div>
  );
}
