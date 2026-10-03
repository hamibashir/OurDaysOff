"use client";

import { useState } from "react";
import { ScheduleEntry, ShiftTemplate } from "@/types/api";
import { ChevronLeft, ChevronRight, Moon, Sun, Plus, Calendar as CalendarIcon } from "lucide-react";

interface ScheduleCalendarProps {
  entries: ScheduleEntry[];
  currentDate: Date;
  onNavigateMonth: (direction: "prev" | "next") => void;
  onSelectDate: (dateStr: string) => void;
  selectedDate: string | null;
  isLoading?: boolean;
}

export function ScheduleCalendar({
  entries,
  currentDate,
  onNavigateMonth,
  onSelectDate,
  selectedDate,
  isLoading = false,
}: ScheduleCalendarProps) {
  const year = currentDate.getFullYear();
  const month = currentDate.getMonth();

  const firstDayOfMonth = new Date(year, month, 1);
  const daysInMonth = new Date(year, month + 1, 0).getDate();
  const startDayOfWeek = firstDayOfMonth.getDay();

  const monthNames = [
    "January", "February", "March", "April", "May", "June",
    "July", "August", "September", "October", "November", "December"
  ];

  const entriesByDate = entries.reduce<Record<string, ScheduleEntry>>((acc, entry) => {
    acc[entry.date] = entry;
    return acc;
  }, {});

  const daysGrid = [];
  for (let i = 0; i < startDayOfWeek; i++) {
    daysGrid.push(null);
  }
  for (let d = 1; d <= daysInMonth; d++) {
    daysGrid.push(d);
  }

  const formatDateStr = (dayNum: number) => {
    const m = String(month + 1).padStart(2, "0");
    const d = String(dayNum).padStart(2, "0");
    return `${year}-${m}-${d}`;
  };

  const getEntryBadgeColor = (type: string) => {
    switch (type) {
      case "work":
        return "badge-busy";
      case "leave":
        return "badge-recovery";
      case "off":
        return "badge-free";
      case "personal":
        return "badge-magic";
      default:
        return "bg-white/[0.05] border-white/[0.1] text-slate-300";
    }
  };

  return (
    <div className="bg-white border border-[#E8E5DF] rounded-xl overflow-hidden shadow-xs">
      {/* Calendar Header Nav */}
      <div className="p-4 border-b border-[#E8E5DF] flex items-center justify-between bg-[#FAF9F6]">
        <div className="flex items-center gap-2.5">
          <CalendarIcon className="w-4 h-4 text-[#2B7A72]" />
          <h2 className="text-sm font-bold text-[#1F2223] tracking-tight">
            {monthNames[month]} {year}
          </h2>
        </div>

        <div className="flex items-center gap-1.5">
          <button
            onClick={() => onNavigateMonth("prev")}
            className="p-1.5 bg-white hover:bg-[#FAF9F6] text-[#656A6D] border border-[#E8E5DF] rounded-lg transition-all shadow-xs"
            title="Previous Month"
          >
            <ChevronLeft className="w-3.5 h-3.5" />
          </button>
          <button
            onClick={() => onNavigateMonth("next")}
            className="p-1.5 bg-white hover:bg-[#FAF9F6] text-[#656A6D] border border-[#E8E5DF] rounded-lg transition-all shadow-xs"
            title="Next Month"
          >
            <ChevronRight className="w-3.5 h-3.5" />
          </button>
        </div>
      </div>

      {/* Weekday Labels */}
      <div className="grid grid-cols-7 border-b border-[#E8E5DF] text-center py-2.5 text-[11px] font-semibold uppercase tracking-wider text-[#656A6D] bg-[#FAF9F6]">
        <div>Sun</div>
        <div>Mon</div>
        <div>Tue</div>
        <div>Wed</div>
        <div>Thu</div>
        <div>Fri</div>
        <div>Sat</div>
      </div>

      {/* Days Grid */}
      <div className="grid grid-cols-7 divide-x divide-y divide-[#E8E5DF] bg-white">
        {daysGrid.map((dayNum, index) => {
          if (dayNum === null) {
            return <div key={`empty-${index}`} className="min-h-[85px] bg-[#FAF9F6]/60" />;
          }

          const dateStr = formatDateStr(dayNum);
          const entry = entriesByDate[dateStr];
          const isSelected = selectedDate === dateStr;
          const isToday = new Date().toISOString().slice(0, 10) === dateStr;

          return (
            <div
              key={dateStr}
              onClick={() => onSelectDate(dateStr)}
              className={`min-h-[90px] p-2 cursor-pointer transition-all flex flex-col justify-between group ${
                isSelected
                  ? "bg-[#81D8D0]/18 ring-1 ring-[#81D8D0]"
                  : "hover:bg-[#FAF9F6]"
              }`}
            >
              <div className="flex items-center justify-between">
                <span
                  className={`text-xs font-bold w-5 h-5 rounded-full flex items-center justify-center font-mono ${
                    isToday
                      ? "bg-[#81D8D0] text-[#1D5E57] shadow-xs"
                      : "text-[#656A6D] group-hover:text-[#1F2223]"
                  }`}
                >
                  {dayNum}
                </span>

                {entry?.is_overnight && (
                  <Moon className="w-3.5 h-3.5 text-[#6A3E94] shrink-0" />
                )}
              </div>

              {isLoading ? (
                <div className="mt-2 h-5 w-full rounded-md bg-[#E8E5DF]/60 animate-pulse" />
              ) : entry ? (
                <div className={`mt-1.5 p-1 rounded-md text-[10px] font-medium leading-tight ${getEntryBadgeColor(entry.entry_type)}`}>
                  <p className="font-bold truncate">{entry.label || entry.entry_type.toUpperCase()}</p>
                  <p className="text-[9px] opacity-90 font-mono mt-0.5">
                    {entry.start_time.slice(0, 5)} - {entry.end_time.slice(0, 5)}
                  </p>
                </div>
              ) : (
                <div className="mt-1 text-[10px] text-[#959A9E] group-hover:text-[#2B7A72] flex items-center gap-1 opacity-0 group-hover:opacity-100 transition-opacity">
                  <Plus className="w-3 h-3" />
                  <span>Assign</span>
                </div>
              )}
            </div>
          );
        })}
      </div>
    </div>
  );
}

