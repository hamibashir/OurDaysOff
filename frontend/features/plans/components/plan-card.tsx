"use client";

import Link from "next/link";
import { Plan } from "@/types/api";
import { downloadIcsFile } from "@/lib/ics-generator";
import { Calendar, Clock, MapPin, Users, Download, ArrowRight } from "lucide-react";

interface PlanCardProps {
  plan: Plan;
  onRsvpChange?: (planId: number, rsvp: "attending" | "tentative" | "declined") => void;
}

export function PlanCard({ plan, onRsvpChange }: PlanCardProps) {
  const getStatusBadge = (status: string) => {
    switch (status) {
      case "confirmed":
        return "badge-free";
      case "polling":
        return "badge-recovery";
      default:
        return "bg-[#FAF9F6] border-[#E8E5DF] text-[#656A6D]";
    }
  };

  const formattedStart = plan.start_at
    ? new Date(plan.start_at).toLocaleString("en-US", {
        weekday: "short",
        month: "short",
        day: "numeric",
        hour: "2-digit",
        minute: "2-digit",
      })
    : "Date TBD (Polling active)";

  return (
    <div className="bg-white border border-[#E8E5DF] hover:border-[#81D8D0] rounded-2xl p-5 transition-all flex flex-col justify-between group shadow-xs hover:shadow-md">
      <div className="space-y-3">
        <div className="flex items-center justify-between">
          <span className={`text-[10px] font-bold uppercase tracking-wider px-2.5 py-0.5 rounded-full border ${getStatusBadge(plan.status)}`}>
            {plan.status}
          </span>
          
          <div className="flex items-center gap-2">
            <button
              onClick={() => downloadIcsFile(plan)}
              title="Export to Calendar (.ics)"
              className="p-1.5 hover:bg-[#FAF9F6] text-[#656A6D] hover:text-[#2B7A72] rounded-lg transition-colors border border-transparent hover:border-[#E8E5DF]"
            >
              <Download className="w-3.5 h-3.5" />
            </button>
            <span className="text-[11px] text-[#656A6D] font-mono capitalize">{plan.event_type}</span>
          </div>
        </div>

        <div>
          <Link href={`/plans/${plan.id}`} className="text-base font-bold text-[#1F2223] group-hover:text-[#2B7A72] transition-colors flex items-center justify-between gap-1">
            <span>{plan.title}</span>
            <ArrowRight className="w-3.5 h-3.5 opacity-0 group-hover:opacity-100 transition-opacity text-[#2B7A72]" />
          </Link>
          {plan.description && (
            <p className="text-xs text-[#656A6D] mt-1 line-clamp-2 leading-relaxed">{plan.description}</p>
          )}
        </div>

        <div className="pt-2 space-y-1.5 text-xs text-[#1F2223]">
          <div className="flex items-center gap-2">
            <Clock className="w-3.5 h-3.5 text-[#2B7A72] shrink-0" />
            <span className="font-mono text-xs font-semibold text-[#1F2223]">{formattedStart}</span>
          </div>
        </div>
      </div>

      {/* RSVP Controls */}
      <div className="mt-5 pt-4 border-t border-[#E8E5DF] flex items-center justify-between">
        <span className="text-[11px] font-bold uppercase tracking-wider text-[#656A6D]">RSVP:</span>
        <div className="flex items-center gap-1.5">
          <button
            onClick={() => onRsvpChange?.(plan.id, "attending")}
            className={`px-2.5 py-1 rounded-xl text-xs font-semibold transition-all ${
              plan.my_rsvp === "attending"
                ? "bg-[#2B7A72] text-white shadow-xs"
                : "bg-[#FAF9F6] hover:bg-[#F2EFE9] border border-[#E8E5DF] text-[#1F2223]"
            }`}
          >
            Going
          </button>
          <button
            onClick={() => onRsvpChange?.(plan.id, "tentative")}
            className={`px-2.5 py-1 rounded-xl text-xs font-semibold transition-all ${
              plan.my_rsvp === "tentative"
                ? "bg-[#D7D982] text-[#5C5E1A] shadow-xs"
                : "bg-[#FAF9F6] hover:bg-[#F2EFE9] border border-[#E8E5DF] text-[#1F2223]"
            }`}
          >
            Maybe
          </button>
          <button
            onClick={() => onRsvpChange?.(plan.id, "declined")}
            className={`px-2.5 py-1 rounded-xl text-xs font-semibold transition-all ${
              plan.my_rsvp === "declined"
                ? "bg-[#D99E82] text-white shadow-xs"
                : "bg-[#FAF9F6] hover:bg-[#F2EFE9] border border-[#E8E5DF] text-[#1F2223]"
            }`}
          >
            No
          </button>
        </div>
      </div>
    </div>
  );
}
