"use client";

import { Clock, ShieldCheck, UserCheck, Sparkles } from "lucide-react";
import { Skeleton } from "@/components/ui/skeleton";

interface MemberAvailabilityData {
  user: { id: number; name: string; handle: string | null };
  visibility: string;
  availability: Record<string, Array<{ start: string; end: string; status: string; shift_type?: string }>>;
}

interface CircleAvailabilityGridProps {
  members: MemberAvailabilityData[];
  commonAvailability: Record<string, Array<{ start: string; end: string; status: string }>>;
  startDate: string;
  endDate: string;
  isLoading?: boolean;
}

export function CircleAvailabilityGrid({
  members,
  commonAvailability,
  startDate,
  endDate,
  isLoading,
}: CircleAvailabilityGridProps) {
  if (isLoading) {
    return (
      <div className="bg-white border border-[#E8E5DF] rounded-2xl p-5 md:p-6 space-y-6 shadow-xs">
        <div className="flex items-center justify-between pb-4 border-b border-[#E8E5DF]">
          <div className="space-y-1">
            <Skeleton className="h-5 w-64" />
            <Skeleton className="h-3.5 w-80" />
          </div>
        </div>
        <div className="space-y-4">
          <Skeleton className="h-28 w-full rounded-xl" />
          <Skeleton className="h-28 w-full rounded-xl" />
        </div>
      </div>
    );
  }

  const dates = Object.keys(commonAvailability);

  return (
    <div className="bg-white border border-[#E8E5DF] rounded-2xl p-5 md:p-6 space-y-6 shadow-xs">
      <div className="flex items-center justify-between pb-4 border-b border-[#E8E5DF]">
        <div>
          <h3 className="text-sm font-bold text-[#1F2223] tracking-tight flex items-center gap-2">
            <Clock className="w-4 h-4 text-[#2B7A72]" />
            Circle Member Availability Heatmap
          </h3>
          <p className="text-xs text-[#656A6D] mt-0.5">
            Individual member streams are filtered according to their configured circle privacy visibility rules.
          </p>
        </div>
      </div>

      {/* Member Streams */}
      <div className="space-y-4">
        {dates.map((dateStr) => {
          const commonBlocks = commonAvailability[dateStr] || [];

          return (
            <div key={dateStr} className="p-4 rounded-xl bg-[#FAF9F6] border border-[#E8E5DF] space-y-3">
              <div className="flex items-center justify-between border-b border-[#E8E5DF] pb-2.5">
                <span className="text-xs font-bold text-[#1F2223] font-mono">{dateStr}</span>

                <div className="flex items-center gap-2">
                  <span className="text-[11px] font-semibold text-[#656A6D]">Common Free Time:</span>
                  {commonBlocks.map((cBlock, idx) => (
                    <span
                      key={idx}
                      className="text-xs font-mono px-2.5 py-0.5 rounded badge-free font-bold"
                    >
                      {cBlock.start} — {cBlock.end}
                    </span>
                  ))}
                  {commonBlocks.length === 0 && (
                    <span className="text-xs text-[#959A9E] italic font-mono">No 100% overlap</span>
                  )}
                </div>
              </div>

              {/* Roster rows */}
              <div className="space-y-2 pt-1">
                {members.map((m) => {
                  const mBlocks = m.availability[dateStr] || [];

                  return (
                    <div key={m.user.id} className="flex flex-col sm:flex-row sm:items-center justify-between text-xs gap-2">
                      <div className="flex items-center gap-2 w-48 shrink-0">
                        <div className="w-5 h-5 rounded-full bg-gradient-to-br from-[#81D8D0] to-[#AE82D9] flex items-center justify-center font-bold text-[10px] text-white shadow-xs">
                          {m.user.name.charAt(0)}
                        </div>
                        <span className="font-semibold text-[#1F2223] truncate">{m.user.name}</span>
                        <span className="text-[9px] font-mono text-[#6A3E94] uppercase px-1.5 py-0.5 rounded bg-[#AE82D9]/15 border border-[#AE82D9]/40 font-semibold">
                          {m.visibility}
                        </span>
                      </div>

                      <div className="flex flex-wrap items-center gap-1.5 flex-1">
                        {mBlocks.map((b, idx) => (
                          <span
                            key={idx}
                            className="text-[11px] font-mono px-2 py-0.5 rounded-md bg-[#81D8D0]/18 border border-[#81D8D0]/40 text-[#23756C] font-medium"
                          >
                            {b.start}–{b.end}
                          </span>
                        ))}
                        {mBlocks.length === 0 && (
                          <span className="text-[10px] text-[#A35439] font-mono font-semibold">Busy / Shift</span>
                        )}
                      </div>
                    </div>
                  );
                })}
              </div>
            </div>
          );
        })}
      </div>

      <div className="flex items-center gap-2 text-[11px] text-[#656A6D] pt-2 border-t border-[#E8E5DF]">
        <ShieldCheck className="w-3.5 h-3.5 text-[#2B7A72] shrink-0" />
        <span>Privacy-first guarantee: Free/Busy members hide all shift names and custom notes from API output.</span>
      </div>
    </div>
  );
}

