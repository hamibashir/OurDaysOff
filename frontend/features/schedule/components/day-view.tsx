"use client";

import { ScheduleEntry } from "@/types/api";
import { Clock, Trash2, Edit3, Moon, AlignLeft } from "lucide-react";

interface DayViewProps {
  dateStr: string;
  entry: ScheduleEntry | null;
  onEdit: () => void;
  onDelete: () => void;
}

export function DayView({ dateStr, entry, onEdit, onDelete }: DayViewProps) {
  const hours = Array.from({ length: 24 }, (_, i) => i);

  const formattedDate = new Date(`${dateStr}T00:00:00`).toLocaleDateString("en-US", {
    weekday: "long",
    month: "short",
    day: "numeric",
    year: "numeric",
  });

  return (
    <div className="bg-white border border-[#E8E5DF] rounded-xl p-5 flex flex-col h-full shadow-xs">
      <div className="flex items-center justify-between pb-3.5 border-b border-[#E8E5DF] mb-5">
        <div>
          <h3 className="text-xs font-bold text-[#1F2223] tracking-tight">{formattedDate}</h3>
          <p className="text-[11px] text-[#656A6D] font-mono mt-0.5">{dateStr}</p>
        </div>

        {entry && (
          <div className="flex items-center gap-1.5">
            <button
              onClick={onEdit}
              className="p-1.5 bg-white hover:bg-[#FAF9F6] text-[#1F2223] border border-[#E8E5DF] rounded-lg text-xs flex items-center gap-1 transition-all shadow-xs"
            >
              <Edit3 className="w-3 h-3 text-[#2B7A72]" />
              Edit
            </button>
            <button
              onClick={onDelete}
              className="p-1.5 bg-rose-50 hover:bg-rose-100 text-rose-700 border border-rose-200 rounded-lg text-xs flex items-center gap-1 transition-all"
            >
              <Trash2 className="w-3 h-3" />
              Delete
            </button>
          </div>
        )}
      </div>

      {entry ? (
        <div className="space-y-5">
          <div className="p-4 rounded-xl bg-[#FAF9F6] border border-[#E8E5DF] space-y-2.5">
            <div className="flex items-center justify-between">
              <span className="text-[10px] font-bold uppercase tracking-wider px-2.5 py-0.5 rounded badge-busy">
                {entry.entry_type}
              </span>
              {entry.is_overnight && (
                <span className="text-xs text-[#6A3E94] flex items-center gap-1 font-mono font-medium">
                  <Moon className="w-3.5 h-3.5 text-[#6A3E94]" /> Overnight
                </span>
              )}
            </div>

            <div>
              <h4 className="text-sm font-bold text-[#1F2223]">{entry.label || "Work Shift"}</h4>
              <p className="text-xs font-mono text-[#2B7A72] mt-1 flex items-center gap-1.5 font-semibold">
                <Clock className="w-3.5 h-3.5 text-[#2B7A72]" />
                {entry.start_time.slice(0, 5)} — {entry.end_time.slice(0, 5)}
              </p>
            </div>
          </div>

          {entry.notes && (
            <div className="p-3.5 rounded-xl bg-[#FAF9F6] border border-[#E8E5DF] text-xs text-[#1F2223] space-y-1">
              <div className="flex items-center gap-1.5 text-[#656A6D] font-semibold uppercase tracking-wider text-[10px]">
                <AlignLeft className="w-3 h-3 text-[#2B7A72]" />
                Notes & Directives
              </div>
              <p className="leading-relaxed text-[#1F2223]">{entry.notes}</p>
            </div>
          )}

          {/* Timeline visualization */}
          <div className="space-y-1 pt-1 max-h-[260px] overflow-y-auto pr-1">
            {hours.map((h) => {
              const hourStr = String(h).padStart(2, "0") + ":00";
              const startH = parseInt(entry.start_time.slice(0, 2), 10);
              const endH = parseInt(entry.end_time.slice(0, 2), 10);

              let isBusy = false;
              if (entry.is_overnight) {
                isBusy = h >= startH || h < endH;
              } else {
                isBusy = h >= startH && h < endH;
              }

              return (
                <div key={h} className="flex items-center text-xs gap-2.5">
                  <span className="w-10 text-[10px] font-mono text-[#959A9E] text-right">{hourStr}</span>
                  <div
                    className={`flex-1 h-4 rounded-md transition-all ${
                      isBusy
                        ? "bg-[#D99E82] border border-[#C98A6D] shadow-xs"
                        : "bg-[#FAF9F6] border border-[#E8E5DF]"
                    }`}
                  />
                </div>
              );
            })}
          </div>
        </div>
      ) : (
        <div className="flex-1 flex flex-col items-center justify-center text-center p-6 border border-dashed border-[#E8E5DF] rounded-xl">
          <Clock className="w-6 h-6 text-[#959A9E] mb-2" />
          <p className="text-xs font-semibold text-[#1F2223]">No shift scheduled for this date</p>
          <p className="text-[11px] text-[#656A6D] mt-1 max-w-xs leading-relaxed">
            Click "+ Add Shift Entry" or pick a template above to assign a shift.
          </p>
        </div>
      )}
    </div>
  );
}

