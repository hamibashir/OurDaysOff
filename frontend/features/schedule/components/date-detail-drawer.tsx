"use client";

import { useMemo } from "react";
import { CircleRosterMember, DaysOffDateSummary, OffTimeDateSummary, CirclePlanSummary, ScheduleEntry } from "@/types/api";
import { Calendar as CalendarIcon, Clock, Sparkles, Plus, Users, Moon, Edit3, Trash2, ShieldCheck, CheckCircle2, ChevronRight } from "lucide-react";

interface DateDetailDrawerProps {
  dateStr: string;
  members: CircleRosterMember[];
  daysOffSummary?: DaysOffDateSummary;
  offTimeSummary?: OffTimeDateSummary;
  plans: CirclePlanSummary[];
  personalEntry: ScheduleEntry | null;
  currentUserId: number | null;
  onEditPersonalShift: () => void;
  onDeletePersonalShift: () => void;
  onOpenCreatePlan: (prefill: { date: string; start_time: string; end_time: string }) => void;
}

export function DateDetailDrawer({
  dateStr,
  members,
  daysOffSummary,
  offTimeSummary,
  plans,
  personalEntry,
  currentUserId,
  onEditPersonalShift,
  onDeletePersonalShift,
  onOpenCreatePlan,
}: DateDetailDrawerProps) {
  const formattedDate = useMemo(() => {
    try {
      const parts = dateStr.split("-");
      const d = new Date(parseInt(parts[0], 10), parseInt(parts[1], 10) - 1, parseInt(parts[2], 10));
      return d.toLocaleDateString("en-GB", {
        weekday: "long",
        day: "numeric",
        month: "short",
        year: "numeric",
      });
    } catch (e) {
      return dateStr;
    }
  }, [dateStr]);

  const datePlans = useMemo(() => {
    return plans.filter((p) => p.date === dateStr);
  }, [plans, dateStr]);

  const bestWindow = offTimeSummary?.best_window;

  return (
    <div className="bg-white border border-[#E8E5DF] rounded-2xl p-5 shadow-xs space-y-5">
      {/* Date Header */}
      <div className="border-b border-[#E8E5DF] pb-4">
        <div className="flex items-center justify-between">
          <span className="text-[10px] uppercase font-bold tracking-wider text-[#656A6D]">
            Selected Date Details
          </span>
          <span className="font-mono text-xs font-semibold text-[#1D5E57] bg-[#81D8D0]/20 px-2 py-0.5 rounded-md">
            {dateStr}
          </span>
        </div>
        <h3 className="text-lg font-bold text-[#1F2223] mt-1 tracking-tight">
          {formattedDate}
        </h3>
      </div>

      {/* Overlap & Magic Hour Highlight Card */}
      <div className="p-4 rounded-xl border bg-gradient-to-br from-[#81D8D0]/15 to-transparent border-[#81D8D0]/50 space-y-3">
        <div className="flex items-center justify-between">
          <span className="text-xs font-bold text-[#1D5E57] uppercase tracking-wide flex items-center gap-1.5">
            <Sparkles className="w-3.5 h-3.5 text-[#2B7A72]" /> Mutual Free Window
          </span>
          {bestWindow && (
            <span className="text-[10px] font-mono font-bold px-2 py-0.5 rounded bg-[#2B7A72] text-white">
              {bestWindow.duration_formatted}
            </span>
          )}
        </div>

        {bestWindow ? (
          <div>
            <p className="text-base font-bold text-[#1F2223] font-mono">
              {bestWindow.start} – {bestWindow.end}
            </p>
            <p className="text-xs text-[#656A6D] mt-0.5">
              {offTimeSummary?.free_count} of {offTimeSummary?.total_count} members available simultaneously
            </p>
          </div>
        ) : (
          <p className="text-xs text-[#656A6D] italic">
            No overlapping free window identified across all members on this date.
          </p>
        )}

        {/* 1-Tap Action: Propose Meetup Plan */}
        <button
          onClick={() =>
            onOpenCreatePlan({
              date: dateStr,
              start_time: bestWindow?.start || "18:00",
              end_time: bestWindow?.end || "21:00",
            })
          }
          className="w-full py-2.5 px-3.5 bg-[#2B7A72] hover:bg-[#1D5E57] text-white rounded-xl text-xs font-bold transition-all shadow-xs flex items-center justify-center gap-2"
        >
          <Plus className="w-4 h-4 text-[#D7D982]" />
          Plan Meetup For This Day
        </button>
      </div>

      {/* Existing Meetup Plans on this date */}
      {datePlans.length > 0 && (
        <div className="space-y-2">
          <h4 className="text-xs font-bold uppercase tracking-wider text-[#656A6D]">
            Existing Plans ({datePlans.length})
          </h4>
          <div className="space-y-2">
            {datePlans.map((p) => (
              <div
                key={p.id}
                className="p-3 rounded-xl bg-[#FAF9F6] border border-[#E8E5DF] space-y-1.5"
              >
                <div className="flex items-center justify-between">
                  <span className="font-bold text-xs text-[#1F2223] truncate">{p.title}</span>
                  <span className="px-1.5 py-0.5 rounded bg-[#81D8D0]/30 text-[#1D5E57] text-[10px] font-mono capitalize">
                    {p.status}
                  </span>
                </div>
                <div className="flex items-center justify-between text-[11px] text-[#656A6D]">
                  <span>{p.start_time}{p.end_time ? ` – ${p.end_time}` : ""}</span>
                  <span>{p.members_count} RSVP(s)</span>
                </div>
              </div>
            ))}
          </div>
        </div>
      )}

      {/* My Personal Schedule on this Date */}
      <div className="space-y-2 border-t border-[#E8E5DF] pt-4">
        <div className="flex items-center justify-between">
          <h4 className="text-xs font-bold uppercase tracking-wider text-[#656A6D]">
            My Personal Shift
          </h4>
          {personalEntry && (
            <div className="flex items-center gap-2">
              <button
                onClick={onEditPersonalShift}
                className="p-1 text-[#656A6D] hover:text-[#1D5E57] rounded"
                title="Edit Shift"
              >
                <Edit3 className="w-3.5 h-3.5" />
              </button>
              <button
                onClick={onDeletePersonalShift}
                className="p-1 text-red-500 hover:text-red-700 rounded"
                title="Remove Shift"
              >
                <Trash2 className="w-3.5 h-3.5" />
              </button>
            </div>
          )}
        </div>

        {personalEntry ? (
          <div className="p-3 rounded-xl bg-[#FAF9F6] border border-[#E8E5DF] space-y-1">
            <div className="flex items-center justify-between">
              <span className="font-bold text-xs text-[#1F2223]">{personalEntry.label || "Work Shift"}</span>
              <span className="text-[10px] font-mono px-1.5 py-0.5 rounded bg-blue-100 text-blue-800">
                {personalEntry.start_time.slice(0, 5)} – {personalEntry.end_time.slice(0, 5)}
              </span>
            </div>
            {personalEntry.notes && (
              <p className="text-[11px] text-[#656A6D] italic">{personalEntry.notes}</p>
            )}
          </div>
        ) : (
          <div className="p-3 rounded-xl border border-dashed border-[#E8E5DF] flex items-center justify-between">
            <span className="text-xs text-[#656A6D] italic">No shift assigned</span>
            <button
              onClick={onEditPersonalShift}
              className="text-xs font-bold text-[#2B7A72] hover:text-[#1D5E57] flex items-center gap-1"
            >
              <Plus className="w-3.5 h-3.5" /> Add
            </button>
          </div>
        )}
      </div>

      {/* Circle Roster Availability Breakdown */}
      <div className="space-y-2 border-t border-[#E8E5DF] pt-4">
        <h4 className="text-xs font-bold uppercase tracking-wider text-[#656A6D]">
          Circle Roster Status ({members.length})
        </h4>

        <div className="space-y-2 max-h-[220px] overflow-y-auto pr-1">
          {members.map((m) => {
            const statusObj = m.daily_status[dateStr];
            return (
              <div
                key={m.user.id}
                className="p-2.5 rounded-xl bg-[#FAF9F6] border border-[#E8E5DF] flex items-center justify-between text-xs"
              >
                <div className="flex items-center gap-2">
                  <span className="w-5 h-5 rounded-full bg-[#2B7A72] text-white text-[9px] font-bold flex items-center justify-center">
                    {m.user.initials}
                  </span>
                  <div>
                    <p className="font-bold text-[#1F2223] leading-tight">{m.user.name}</p>
                    <p className="text-[10px] text-[#656A6D]">{statusObj?.label || "Unknown"}</p>
                  </div>
                </div>

                <div className="text-right">
                  <span
                    className={`text-[10px] font-mono font-semibold px-2 py-0.5 rounded-md ${
                      statusObj?.is_day_off
                        ? "bg-emerald-100 text-emerald-800"
                        : statusObj?.status === "work"
                        ? "bg-blue-100 text-blue-800"
                        : "bg-zinc-100 text-zinc-600"
                    }`}
                  >
                    {statusObj?.short_code || "—"}
                  </span>
                </div>
              </div>
            );
          })}
        </div>
      </div>
    </div>
  );
}
