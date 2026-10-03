"use client";

import { useMemo } from "react";
import { CircleRosterMember, DaysOffDateSummary, OffTimeDateSummary, CirclePlanSummary, ScheduleEntry } from "@/types/api";
import { ChevronLeft, ChevronRight, Moon, Sparkles, Calendar as CalendarIcon, Clock, Users, User as UserIcon, Plus } from "lucide-react";

interface MonthCalendarProps {
  currentDate: Date;
  onNavigateMonth: (direction: "prev" | "next") => void;
  onSelectDate: (dateStr: string) => void;
  selectedDate: string | null;
  availabilityMode: "days_off" | "off_time";
  viewPerspective: "group" | "individual";
  selectedMemberId: number | null;
  members: CircleRosterMember[];
  daysOff: Record<string, DaysOffDateSummary>;
  offTime: Record<string, OffTimeDateSummary>;
  plans: CirclePlanSummary[];
  personalEntries: ScheduleEntry[];
  currentUserId: number | null;
  isLoading?: boolean;
}

export function MonthCalendar({
  currentDate,
  onNavigateMonth,
  onSelectDate,
  selectedDate,
  availabilityMode,
  viewPerspective,
  selectedMemberId,
  members,
  daysOff,
  offTime,
  plans,
  personalEntries,
  currentUserId,
  isLoading = false,
}: MonthCalendarProps) {
  const year = currentDate.getFullYear();
  const month = currentDate.getMonth();

  const monthNames = [
    "January", "February", "March", "April", "May", "June",
    "July", "August", "September", "October", "November", "December"
  ];

  // Monday–Sunday grid calculation
  const { daysGrid, startDayOffset, daysInMonth } = useMemo(() => {
    const firstDay = new Date(year, month, 1);
    const totalDays = new Date(year, month + 1, 0).getDate();
    // In JS, getDay(): 0 = Sun, 1 = Mon, ..., 6 = Sat
    // Convert to Monday = 0, ..., Sunday = 6
    const dayOfWeek = firstDay.getDay();
    const offset = (dayOfWeek + 6) % 7;

    const grid: (number | null)[] = [];
    for (let i = 0; i < offset; i++) {
      grid.push(null);
    }
    for (let d = 1; d <= totalDays; d++) {
      grid.push(d);
    }
    return { daysGrid: grid, startDayOffset: offset, daysInMonth: totalDays };
  }, [year, month]);

  const plansByDate = useMemo(() => {
    const map: Record<string, CirclePlanSummary[]> = {};
    for (const p of plans) {
      if (!map[p.date]) map[p.date] = [];
      map[p.date].push(p);
    }
    return map;
  }, [plans]);

  const personalEntriesByDate = useMemo(() => {
    const map: Record<string, ScheduleEntry> = {};
    for (const e of personalEntries) {
      map[e.date] = e;
    }
    return map;
  }, [personalEntries]);

  const activeIndividual = useMemo(() => {
    if (viewPerspective !== "individual") return null;
    return members.find((m) => m.user.id === selectedMemberId) || members[0] || null;
  }, [viewPerspective, selectedMemberId, members]);

  const formatDateStr = (dayNum: number) => {
    const m = String(month + 1).padStart(2, "0");
    const d = String(dayNum).padStart(2, "0");
    return `${year}-${m}-${d}`;
  };

  const getStatusColor = (status: string) => {
    switch (status) {
      case "off":
        return "bg-emerald-50 border-emerald-200 text-emerald-800";
      case "leave":
        return "bg-amber-50 border-amber-200 text-amber-800";
      case "study":
        return "bg-cyan-50 border-cyan-200 text-cyan-800";
      case "busy":
        return "bg-zinc-100 border-zinc-300 text-zinc-700";
      case "work":
        return "bg-indigo-50 border-indigo-200 text-indigo-800";
      default:
        return "bg-zinc-50 border-zinc-200 text-zinc-400";
    }
  };

  return (
    <div className="bg-white border border-[#E8E5DF] rounded-2xl overflow-hidden shadow-xs">
      {/* Calendar Header Navigation */}
      <div className="p-4 border-b border-[#E8E5DF] flex items-center justify-between bg-[#FAF9F6]">
        <div className="flex items-center gap-3">
          <div className="w-8 h-8 rounded-lg bg-[#81D8D0]/20 border border-[#81D8D0]/40 flex items-center justify-center">
            <CalendarIcon className="w-4 h-4 text-[#1D5E57]" />
          </div>
          <div>
            <h2 className="text-base font-bold text-[#1F2223] tracking-tight">
              {monthNames[month]} {year}
            </h2>
            <p className="text-[11px] text-[#656A6D]">
              {viewPerspective === "group"
                ? availabilityMode === "days_off"
                  ? "Confirmed full-day off counts & roster"
                  : "Magic Hour overlapping free windows"
                : `Individual Rota for ${activeIndividual?.user.name || "Member"}`}
            </p>
          </div>
        </div>

        <div className="flex items-center gap-1.5">
          <button
            onClick={() => onNavigateMonth("prev")}
            className="p-2 bg-white hover:bg-[#FAF9F6] text-[#656A6D] border border-[#E8E5DF] rounded-xl transition-all shadow-xs"
            title="Previous Month"
          >
            <ChevronLeft className="w-4 h-4" />
          </button>
          <button
            onClick={() => onNavigateMonth("next")}
            className="p-2 bg-white hover:bg-[#FAF9F6] text-[#656A6D] border border-[#E8E5DF] rounded-xl transition-all shadow-xs"
            title="Next Month"
          >
            <ChevronRight className="w-4 h-4" />
          </button>
        </div>
      </div>

      {/* Weekday Labels (Monday to Sunday) */}
      <div className="grid grid-cols-7 border-b border-[#E8E5DF] text-center py-2.5 text-[11px] font-bold uppercase tracking-wider text-[#656A6D] bg-[#FAF9F6]">
        <div>Mon</div>
        <div>Tue</div>
        <div>Wed</div>
        <div>Thu</div>
        <div>Fri</div>
        <div>Sat</div>
        <div className="text-[#A2574F]">Sun</div>
      </div>

      {/* Days Grid */}
      <div className="grid grid-cols-7 divide-x divide-y divide-[#E8E5DF] bg-white">
        {daysGrid.map((dayNum, index) => {
          if (dayNum === null) {
            return <div key={`empty-${index}`} className="min-h-[105px] bg-[#FAF9F6]/50" />;
          }

          const dateStr = formatDateStr(dayNum);
          const isSelected = selectedDate === dateStr;
          const isToday = new Date().toISOString().slice(0, 10) === dateStr;
          const datePlans = plansByDate[dateStr] || [];

          // Group calculations
          const dayOffData = daysOff[dateStr];
          const offTimeData = offTime[dateStr];

          // Individual calculation
          const individualStatus = activeIndividual?.daily_status[dateStr];
          const isCurrentUsersPersonal = activeIndividual?.user.id === currentUserId;
          const personalEntry = personalEntriesByDate[dateStr];

          return (
            <div
              key={dateStr}
              onClick={() => onSelectDate(dateStr)}
              className={`min-h-[105px] p-2 cursor-pointer transition-all flex flex-col justify-between group relative select-none ${
                isSelected
                  ? "bg-[#81D8D0]/18 ring-2 ring-[#81D8D0] ring-inset z-10"
                  : "hover:bg-[#FAF9F6]/80"
              }`}
            >
              {/* Cell Top Header */}
              <div className="flex items-center justify-between gap-1">
                <span
                  className={`text-xs font-bold w-6 h-6 rounded-full flex items-center justify-center font-mono ${
                    isToday
                      ? "bg-[#2B7A72] text-white shadow-xs"
                      : isSelected
                      ? "bg-[#81D8D0] text-[#1D5E57] font-bold"
                      : "text-[#4B5054] group-hover:text-[#1F2223]"
                  }`}
                >
                  {dayNum}
                </span>

                {/* Plan Indicator Badge */}
                {datePlans.length > 0 && (
                  <span
                    className="px-1.5 py-0.5 rounded-full bg-[#E5F5F3] border border-[#81D8D0]/60 text-[#1D5E57] text-[9px] font-bold flex items-center gap-0.5"
                    title={`${datePlans.length} active plan(s)`}
                  >
                    <CalendarIcon className="w-2.5 h-2.5 text-[#2B7A72]" />
                    {datePlans.length}
                  </span>
                )}
              </div>

              {/* Cell Content Area */}
              {isLoading ? (
                <div className="my-auto space-y-1.5">
                  <div className="h-4 bg-[#E8E5DF]/70 rounded animate-pulse w-3/4" />
                  <div className="h-3 bg-[#E8E5DF]/50 rounded animate-pulse w-1/2" />
                </div>
              ) : viewPerspective === "group" ? (
                // ==================== GROUP OVERVIEW ====================
                availabilityMode === "days_off" ? (
                  // DAYS OFF MODE
                  <div className="mt-1 space-y-1">
                    {dayOffData ? (
                      <>
                        <div className="flex items-center justify-between">
                          <span
                            className={`text-[10px] font-mono font-bold px-1.5 py-0.5 rounded-md ${
                              dayOffData.all_free
                                ? "bg-emerald-500 text-white shadow-xs"
                                : dayOffData.free_count > 0
                                ? "bg-emerald-50 text-emerald-800 border border-emerald-200"
                                : "bg-zinc-100 text-zinc-500"
                            }`}
                          >
                            {dayOffData.all_free ? "🎉 ALL OFF" : `${dayOffData.free_count}/${dayOffData.total_count} off`}
                          </span>
                        </div>

                        {/* Avatars of Confirmed Off People */}
                        <div className="flex flex-wrap gap-1 mt-1">
                          {dayOffData.free_members.length > 0 ? (
                            dayOffData.free_members.map((u) => (
                              <span
                                key={u.id}
                                className="w-4 h-4 rounded-full bg-emerald-600 text-white text-[8px] font-bold flex items-center justify-center uppercase shadow-2xs"
                                title={`${u.name} (Off all day)`}
                              >
                                {u.initials}
                              </span>
                            ))
                          ) : (
                            <span className="text-[9px] text-[#959A9E] italic">None off</span>
                          )}
                        </div>
                      </>
                    ) : (
                      <span className="text-[10px] text-zinc-400">—</span>
                    )}
                  </div>
                ) : (
                  // OFF TIME / MAGIC HOUR MODE
                  <div className="mt-1 space-y-1">
                    {offTimeData && offTimeData.has_overlap && offTimeData.best_window ? (
                      <>
                        <div className="flex items-center gap-1">
                          <span
                            className={`text-[10px] font-mono font-bold px-1.5 py-0.5 rounded-md flex items-center gap-1 truncate ${
                              offTimeData.all_free
                                ? "bg-[#2B7A72] text-white shadow-xs"
                                : "bg-[#81D8D0]/20 text-[#1D5E57] border border-[#81D8D0]/50"
                            }`}
                          >
                            <Sparkles className="w-2.5 h-2.5 text-[#D7D982] shrink-0" />
                            {offTimeData.best_window.start}–{offTimeData.best_window.end}
                          </span>
                        </div>
                        <div className="flex items-center justify-between text-[9px] text-[#656A6D]">
                          <span>{offTimeData.best_window.duration_formatted}</span>
                          <span className="font-mono font-semibold">{offTimeData.free_count}/{offTimeData.total_count}</span>
                        </div>

                        {/* Avatars */}
                        <div className="flex flex-wrap gap-1">
                          {offTimeData.free_members.map((u) => (
                            <span
                              key={u.id}
                              className="w-4 h-4 rounded-full bg-[#1D5E57] text-white text-[8px] font-bold flex items-center justify-center uppercase shadow-2xs"
                              title={`${u.name} (Free in window)`}
                            >
                              {u.initials}
                            </span>
                          ))}
                        </div>
                      </>
                    ) : (
                      <div className="py-1">
                        <span className="text-[10px] text-[#959A9E] italic">No overlap</span>
                      </div>
                    )}
                  </div>
                )
              ) : (
                // ==================== INDIVIDUAL ROTA ====================
                <div className="mt-1 space-y-1">
                  {individualStatus ? (
                    <div
                      className={`p-1 rounded-lg border text-[10px] leading-tight ${getStatusColor(
                        individualStatus.status
                      )}`}
                    >
                      <div className="flex items-center justify-between">
                        <span className="font-bold truncate">{individualStatus.label}</span>
                        {individualStatus.is_overnight && (
                          <Moon className="w-3 h-3 text-[#6A3E94] shrink-0" />
                        )}
                      </div>
                      {individualStatus.start_time && individualStatus.end_time && (
                        <p className="text-[9px] font-mono mt-0.5 opacity-85">
                          {individualStatus.start_time} - {individualStatus.end_time}
                        </p>
                      )}
                    </div>
                  ) : personalEntry ? (
                    <div className="p-1 rounded-lg border bg-indigo-50 border-indigo-200 text-indigo-900 text-[10px]">
                      <div className="flex items-center justify-between">
                        <span className="font-bold truncate">{personalEntry.label || "Work"}</span>
                        {personalEntry.is_overnight && <Moon className="w-3 h-3 text-purple-600" />}
                      </div>
                      <p className="text-[9px] font-mono mt-0.5">
                        {personalEntry.start_time.slice(0, 5)} - {personalEntry.end_time.slice(0, 5)}
                      </p>
                    </div>
                  ) : (
                    <div className="p-1 rounded-lg border border-dashed border-zinc-200 text-center">
                      <span className="text-[10px] text-zinc-400 italic">Unknown</span>
                    </div>
                  )}
                </div>
              )}

              {/* Bottom Quick-action affordance */}
              <div className="h-1" />
            </div>
          );
        })}
      </div>
    </div>
  );
}
