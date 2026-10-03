"use client";

import { useState, useEffect } from "react";
import { AvailabilityBlock } from "@/types/api";
import { apiClient } from "@/lib/api-client";
import { Sparkles, Clock, Calendar as CalendarIcon, ShieldCheck } from "lucide-react";

interface AvailabilityPreviewProps {
  startDate: string;
  endDate: string;
}

export function AvailabilityPreview({ startDate, endDate }: AvailabilityPreviewProps) {
  const [availability, setAvailability] = useState<Record<string, AvailabilityBlock[]>>({});
  const [isLoading, setIsLoading] = useState(true);
  const [recoveryHours, setRecoveryHours] = useState(8);

  const fetchAvailability = async () => {
    setIsLoading(true);
    try {
      const res = await apiClient.get<{ data: Record<string, AvailabilityBlock[]> }>(
        `/availability/personal?start_date=${startDate}&end_date=${endDate}&recovery_hours=${recoveryHours}`
      );
      setAvailability(res.data);
    } catch (err) {
      console.error("Failed to fetch availability preview", err);
    } finally {
      setIsLoading(false);
    }
  };

  useEffect(() => {
    if (startDate && endDate) {
      fetchAvailability();
    }
  }, [startDate, endDate, recoveryHours]);

  return (
    <div className="bg-white border border-[#E8E5DF] rounded-xl p-6 space-y-5 shadow-xs">
      <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-4 pb-4 border-b border-[#E8E5DF]">
        <div>
          <h3 className="text-sm font-bold text-[#1F2223] tracking-tight flex items-center gap-2">
            <Sparkles className="w-4 h-4 text-[#2B7A72]" />
            Derived Free Time & Availability Preview
          </h3>
          <p className="text-xs text-[#656A6D] mt-0.5">
            Calculated automatically from your raw shifts, travel buffers, and rest recovery rules.
          </p>
        </div>

        <div className="flex items-center gap-3 text-xs">
          <div className="flex items-center gap-1.5 bg-[#FAF9F6] border border-[#E8E5DF] rounded-xl px-2.5 py-1.5">
            <span className="text-[#656A6D]">Post-Night Rest:</span>
            <select
              value={recoveryHours}
              onChange={(e) => setRecoveryHours(Number(e.target.value))}
              className="bg-transparent text-[#23756C] font-semibold outline-none cursor-pointer"
            >
              <option value={0}>0h</option>
              <option value={6}>6h</option>
              <option value={8}>8h</option>
              <option value={12}>12h</option>
            </select>
          </div>
        </div>
      </div>

      {isLoading ? (
        <div className="py-8 text-center flex justify-center">
          <div className="w-5 h-5 border-2 border-[#81D8D0] border-t-transparent rounded-full animate-spin" />
        </div>
      ) : (
        <div className="space-y-2.5">
          {Object.entries(availability).map(([dateStr, blocks]) => (
            <div key={dateStr} className="p-3 rounded-xl bg-[#FAF9F6] border border-[#E8E5DF] flex flex-col sm:flex-row sm:items-center justify-between gap-2">
              <div className="flex items-center gap-2">
                <CalendarIcon className="w-3.5 h-3.5 text-[#959A9E]" />
                <span className="text-xs font-semibold text-[#1F2223] font-mono">{dateStr}</span>
              </div>

              <div className="flex flex-wrap items-center gap-2">
                {blocks.map((block, idx) => (
                  <span
                    key={idx}
                    className="text-xs font-mono px-2.5 py-1 rounded-md badge-free font-semibold flex items-center gap-1.5"
                  >
                    <Clock className="w-3 h-3 text-[#23756C]" />
                    {block.start} — {block.end}
                  </span>
                ))}

                {blocks.length === 0 && (
                  <span className="text-xs text-[#A35439] bg-[#D99E82]/20 border border-[#D99E82]/40 px-2.5 py-1 rounded-md font-medium">
                    Fully Busy / Resting
                  </span>
                )}
              </div>
            </div>
          ))}
        </div>
      )}

      <div className="flex items-center gap-2 text-[11px] text-[#656A6D] pt-2 border-t border-[#E8E5DF]">
        <ShieldCheck className="w-3.5 h-3.5 text-[#2B7A72]" />
        <span>This derived free window preview is what will be evaluated by your circles.</span>
      </div>
    </div>
  );
}
