"use client";

import { useMemo } from "react";
import { CircleRosterMember, CirclePlanSummary } from "@/types/api";
import { Calendar as CalendarIcon, Moon } from "lucide-react";

interface RotaGridProps {
  currentDate: Date;
  members: CircleRosterMember[];
  plans: CirclePlanSummary[];
  onSelectDate: (dateStr: string) => void;
  onSelectMember: (memberId: number) => void;
  selectedDate: string | null;
  isLoading?: boolean;
}

export function RotaGrid({
  currentDate,
  members,
  plans,
  onSelectDate,
  onSelectMember,
  selectedDate,
  isLoading = false,
}: RotaGridProps) {
  const year = currentDate.getFullYear();
  const month = currentDate.getMonth();

  const daysInMonth = new Date(year, month + 1, 0).getDate();
  const weekdayNames = ["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"];

  const datesList = useMemo(() => {
    const list: Array<{ dateStr: string; dayNum: number; weekday: string; isWeekend: boolean; isToday: boolean }> = [];
    const todayStr = new Date().toISOString().slice(0, 10);

    for (let d = 1; d <= daysInMonth; d++) {
      const mStr = String(month + 1).padStart(2, "0");
      const dStr = String(d).padStart(2, "0");
      const dateStr = `${year}-${mStr}-${dStr}`;
      const dateObj = new Date(year, month, d);
      const dayOfWeek = dateObj.getDay();

      list.push({
        dateStr,
        dayNum: d,
        weekday: weekdayNames[dayOfWeek],
        isWeekend: dayOfWeek === 0 || dayOfWeek === 6,
        isToday: dateStr === todayStr,
      });
    }
    return list;
  }, [year, month, daysInMonth]);

  const plansByDate = useMemo(() => {
    const map: Record<string, number> = {};
    for (const p of plans) {
      map[p.date] = (map[p.date] || 0) + 1;
    }
    return map;
  }, [plans]);

  const getCellTokenStyle = (statusObj: any) => {
    if (!statusObj || statusObj.status === "unknown") {
      return "bg-zinc-50 border-dashed border-zinc-200 text-zinc-400";
    }

    switch (statusObj.status) {
      case "off":
        return "bg-emerald-100 text-emerald-900 border border-emerald-300 font-bold";
      case "leave":
        return "bg-amber-100 text-amber-900 border border-amber-300 font-bold";
      case "study":
        return "bg-cyan-100 text-cyan-900 border border-cyan-300 font-bold";
      case "busy":
        return "bg-zinc-200 text-zinc-800 border border-zinc-300 font-medium";
      case "work":
        if (statusObj.is_overnight) {
          return "bg-purple-100 text-purple-900 border border-purple-300 font-bold";
        }
        // Early vs Late shift hour styling
        const startH = parseInt(statusObj.start_time?.slice(0, 2) || "0", 10);
        if (startH >= 13) {
          return "bg-violet-100 text-violet-900 border border-violet-300 font-bold";
        }
        return "bg-blue-100 text-blue-900 border border-blue-300 font-bold";
      default:
        return "bg-zinc-50 text-zinc-500 border border-zinc-200";
    }
  };

  return (
    <div className="bg-white border border-[#E8E5DF] rounded-2xl overflow-hidden shadow-xs space-y-4">
      {/* Rota Header Banner */}
      <div className="p-4 border-b border-[#E8E5DF] flex items-center justify-between bg-[#FAF9F6]">
        <div>
          <h3 className="text-sm font-bold text-[#1F2223] tracking-tight">
            Department Rota Matrix — {datesList[0]?.dateStr.slice(0, 7)}
          </h3>
          <p className="text-xs text-[#656A6D]">
            Compact circle duty overview. Tap a member column to open their rota, or click any cell to view overlap.
          </p>
        </div>
      </div>

      {/* Rota Table with Frozen Left Column and Sticky Header */}
      <div className="overflow-x-auto max-h-[620px] scrollbar-thin">
        <table className="w-full border-collapse text-left text-xs">
          {/* Header Row: Circle Members */}
          <thead className="sticky top-0 z-20 bg-[#FAF9F6] border-b border-[#E8E5DF] shadow-2xs">
            <tr>
              {/* Sticky Date/Weekday Header */}
              <th className="sticky left-0 z-30 bg-[#FAF9F6] border-r border-[#E8E5DF] p-3 text-[11px] font-bold uppercase tracking-wider text-[#656A6D] min-w-[110px]">
                Date
              </th>

              {/* Member Columns */}
              {members.map((m) => (
                <th
                  key={m.user.id}
                  onClick={() => onSelectMember(m.user.id)}
                  className="p-3 border-r border-[#E8E5DF] min-w-[100px] max-w-[130px] cursor-pointer hover:bg-[#81D8D0]/15 transition-colors group"
                  title="Click to switch to this member's individual Month view"
                >
                  <div className="flex items-center gap-2">
                    <span className="w-6 h-6 rounded-full bg-[#2B7A72] text-white text-[10px] font-bold flex items-center justify-center shrink-0">
                      {m.user.initials}
                    </span>
                    <div className="truncate">
                      <p className="font-bold text-[#1F2223] group-hover:text-[#1D5E57] truncate text-xs">
                        {m.user.name}
                      </p>
                      <p className="text-[10px] text-[#656A6D] font-mono capitalize">
                        {m.visibility.replace("_", "/")}
                      </p>
                    </div>
                  </div>
                </th>
              ))}
            </tr>
          </thead>

          {/* Body Rows: Dates */}
          <tbody className="divide-y divide-[#E8E5DF]">
            {datesList.map((item) => {
              const isSelected = selectedDate === item.dateStr;
              const plansCount = plansByDate[item.dateStr] || 0;

              return (
                <tr
                  key={item.dateStr}
                  onClick={() => onSelectDate(item.dateStr)}
                  className={`cursor-pointer transition-colors ${
                    isSelected
                      ? "bg-[#81D8D0]/18"
                      : item.isToday
                      ? "bg-[#81D8D0]/8 hover:bg-[#81D8D0]/15"
                      : item.isWeekend
                      ? "bg-[#FAF9F6]/60 hover:bg-[#FAF9F6]"
                      : "hover:bg-[#FAF9F6]/80"
                  }`}
                >
                  {/* Sticky Date Column */}
                  <td
                    className={`sticky left-0 z-10 border-r border-[#E8E5DF] p-2.5 font-mono text-xs font-semibold select-none ${
                      isSelected
                        ? "bg-[#81D8D0]/30 text-[#1D5E57] font-bold"
                        : item.isToday
                        ? "bg-[#2B7A72]/10 text-[#1D5E57] font-bold"
                        : item.isWeekend
                        ? "bg-[#FAF9F6] text-[#A2574F]"
                        : "bg-white text-[#1F2223]"
                    }`}
                  >
                    <div className="flex items-center justify-between gap-1.5">
                      <div className="flex items-center gap-1.5">
                        <span className="w-5 text-right font-bold">{item.dayNum}</span>
                        <span className="text-[10px] uppercase font-sans font-bold text-[#656A6D]">
                          {item.weekday}
                        </span>
                      </div>
                      {plansCount > 0 && (
                        <span
                          className="px-1 py-0.2 rounded-full bg-[#81D8D0] text-[#1D5E57] text-[8px] font-bold flex items-center gap-0.5"
                          title="Plan on this date"
                        >
                          <CalendarIcon className="w-2 h-2" />
                          {plansCount}
                        </span>
                      )}
                    </div>
                  </td>

                  {/* Member Cells */}
                  {members.map((m) => {
                    const statusObj = m.daily_status[item.dateStr];
                    const tokenClass = getCellTokenStyle(statusObj);

                    return (
                      <td key={m.user.id} className="p-2 border-r border-[#E8E5DF] text-center">
                        <div
                          className={`inline-flex items-center justify-center gap-1 px-2 py-1 rounded-md text-[11px] font-mono tracking-tight shadow-2xs w-full max-w-[90px] truncate ${tokenClass}`}
                          title={statusObj?.label || "Unknown"}
                        >
                          {statusObj?.is_overnight && (
                            <Moon className="w-2.5 h-2.5 shrink-0 text-purple-700" />
                          )}
                          <span className="truncate">{statusObj?.short_code || "—"}</span>
                        </div>
                      </td>
                    );
                  })}
                </tr>
              );
            })}
          </tbody>
        </table>
      </div>

      {/* Rota Legend */}
      <div className="p-4 border-t border-[#E8E5DF] bg-[#FAF9F6] flex flex-wrap items-center gap-4 text-xs text-[#656A6D]">
        <span className="font-bold text-[#1F2223]">Legend:</span>
        <div className="flex items-center gap-1.5">
          <span className="px-1.5 py-0.5 rounded bg-emerald-100 text-emerald-900 border border-emerald-300 font-mono font-bold text-[10px]">
            OFF
          </span>
          <span>Day Off</span>
        </div>
        <div className="flex items-center gap-1.5">
          <span className="px-1.5 py-0.5 rounded bg-blue-100 text-blue-900 border border-blue-300 font-mono font-bold text-[10px]">
            08–17
          </span>
          <span>Day Shift</span>
        </div>
        <div className="flex items-center gap-1.5">
          <span className="px-1.5 py-0.5 rounded bg-purple-100 text-purple-900 border border-purple-300 font-mono font-bold text-[10px]">
            19–07
          </span>
          <span>Night Duty</span>
        </div>
        <div className="flex items-center gap-1.5">
          <span className="px-1.5 py-0.5 rounded bg-amber-100 text-amber-900 border border-amber-300 font-mono font-bold text-[10px]">
            A/L
          </span>
          <span>Annual Leave</span>
        </div>
        <div className="flex items-center gap-1.5">
          <span className="px-1.5 py-0.5 rounded bg-cyan-100 text-cyan-900 border border-cyan-300 font-mono font-bold text-[10px]">
            STUDY
          </span>
          <span>Study / Training</span>
        </div>
        <div className="flex items-center gap-1.5">
          <span className="px-1.5 py-0.5 rounded bg-zinc-200 text-zinc-800 border border-zinc-300 font-mono font-bold text-[10px]">
            BUSY
          </span>
          <span>Private Busy</span>
        </div>
        <div className="flex items-center gap-1.5">
          <span className="px-1.5 py-0.5 rounded bg-zinc-50 text-zinc-400 border border-dashed border-zinc-300 font-mono font-bold text-[10px]">
            —
          </span>
          <span>Missing / Unknown</span>
        </div>
      </div>
    </div>
  );
}
