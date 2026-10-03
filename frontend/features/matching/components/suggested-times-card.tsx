"use client";

import { Sparkles, Calendar, Clock, CheckCircle, ArrowRight } from "lucide-react";
import { SkeletonList } from "@/components/ui/skeleton";

interface Suggestion {
  date: string;
  start: string;
  end: string;
  duration_hours: number;
  reasons: string[];
  score: number;
  is_magic_hour: boolean;
}

interface SuggestedTimesCardProps {
  suggestions: Suggestion[];
  onProposePlan?: (suggestion: Suggestion) => void;
  isLoading?: boolean;
}

export function SuggestedTimesCard({ suggestions, onProposePlan, isLoading = false }: SuggestedTimesCardProps) {
  return (
    <div className="bg-white border border-[#E8E5DF] rounded-2xl p-5 md:p-6 space-y-5 shadow-xs">
      <div className="flex items-center justify-between pb-3.5 border-b border-[#E8E5DF]">
        <div>
          <h3 className="text-sm font-bold text-[#1F2223] tracking-tight flex items-center gap-2">
            <Sparkles className="w-4 h-4 text-[#2B7A72]" />
            Ranked Meet Suggestions & Magic Hour
          </h3>
          <p className="text-xs text-[#656A6D] mt-0.5">
            Top derived availability overlaps evaluated for maximum participant count and meal window suitability.
          </p>
        </div>
      </div>

      {isLoading ? (
        <SkeletonList count={2} />
      ) : (
        <div className="space-y-3">
        {suggestions.map((s, idx) => (
          <div
            key={idx}
            className={`p-4 rounded-xl border transition-all flex flex-col sm:flex-row sm:items-center justify-between gap-4 ${
              s.is_magic_hour
                ? "bg-[#D7D982]/20 border-[#D7D982]/60 shadow-xs"
                : "bg-[#FAF9F6] border border-[#E8E5DF] hover:border-[#D8D4CC]"
            }`}
          >
            <div className="space-y-2">
              <div className="flex items-center gap-2">
                {s.is_magic_hour && (
                  <span className="text-[10px] font-bold uppercase tracking-wider px-2.5 py-0.5 rounded-full badge-magic flex items-center gap-1 shadow-xs">
                    <Sparkles className="w-3 h-3 text-[#6A3E94]" /> Magic Hour
                  </span>
                )}
                <span className="text-xs font-bold text-[#1F2223] font-mono">{s.date}</span>
              </div>

              <div className="flex items-center gap-3">
                <span className="text-sm font-bold text-[#1F2223] font-mono flex items-center gap-1.5">
                  <Clock className="w-4 h-4 text-[#2B7A72]" />
                  {s.start} — {s.end}
                </span>
                <span className="text-xs text-[#656A6D] font-mono">({s.duration_hours} hrs)</span>
              </div>

              <div className="flex flex-wrap items-center gap-2 pt-1">
                {s.reasons.map((r, rIdx) => (
                  <span key={rIdx} className="text-[11px] text-[#1F2223] bg-white border border-[#E8E5DF] px-2.5 py-0.5 rounded-md font-medium shadow-xs">
                    {r}
                  </span>
                ))}
              </div>
            </div>

            {onProposePlan && (
              <button
                onClick={() => onProposePlan(s)}
                className="px-4 py-2.5 bg-[#D99E82] hover:bg-[#C98A6D] text-white rounded-xl text-xs font-bold shadow-xs shrink-0 flex items-center gap-2 transition-all"
              >
                Propose Plan <ArrowRight className="w-3.5 h-3.5" />
              </button>
            )}
          </div>
        ))}

        {suggestions.length === 0 && (
          <div className="py-8 text-center border border-dashed border-[#E8E5DF] rounded-2xl">
            <p className="text-xs text-[#656A6D]">No overlapping free time windows found for the selected dates.</p>
          </div>
        )}
      </div>
      )}
    </div>
  );
}

