"use client";

import { useEffect, useState, use } from "react";
import Link from "next/link";
import { Plan } from "@/types/api";
import { apiClient } from "@/lib/api-client";
import { LocationVotingWidget } from "@/features/plans/components/location-voting-widget";
import { PlanChatWidget } from "@/features/plans/components/plan-chat-widget";
import { CircleActivityFeed } from "@/features/circles/components/circle-activity-feed";
import { downloadIcsFile } from "@/lib/ics-generator";
import { CalendarCheck, Clock, MapPin, Users, ArrowLeft, Download } from "lucide-react";
import { sessionCache } from "@/lib/session-cache";

export default function PlanDetailPage({ params }: { params: Promise<{ id: string }> }) {
  const { id } = use(params);
  const planId = parseInt(id, 10);
  const cacheKey = `plan_detail_${planId}`;

  const cachedPlan = sessionCache.get<Plan>(cacheKey);

  const [plan, setPlan] = useState<Plan | null>(cachedPlan);
  const [isLoading, setIsLoading] = useState(!cachedPlan);

  const loadPlanDetail = async (forceRefetch = false) => {
    if (forceRefetch || !sessionCache.has(cacheKey)) {
      if (!sessionCache.has(cacheKey)) setIsLoading(true);
      try {
        const res = await apiClient.get<{ data: Plan }>(`/plans/${planId}`);
        setPlan(res.data);
        sessionCache.set(cacheKey, res.data);
      } catch (err) {
        console.error("Failed to load plan detail", err);
      } finally {
        setIsLoading(false);
      }
    }
  };

  useEffect(() => {
    if (planId) {
      if (!sessionCache.has(cacheKey)) {
        loadPlanDetail(true);
      }
    }
  }, [planId]);

  const handleRsvp = async (status: "attending" | "tentative" | "declined") => {
    try {
      await apiClient.post(`/plans/${planId}/rsvp`, { rsvp_status: status });
      sessionCache.invalidate(cacheKey);
      sessionCache.invalidate("user_plans");
      sessionCache.invalidate("dashboard_overview");
      await loadPlanDetail(true);
    } catch (err: any) {
      alert(err.message || "Failed to update RSVP.");
    }
  };

  const handleLocationUpdated = () => {
    sessionCache.invalidate(cacheKey);
    loadPlanDetail(true);
  };

  if (isLoading || !plan) {
    return (
      <div className="py-12 text-center flex justify-center">
        <div className="w-6 h-6 border-2 border-[#81D8D0] border-t-transparent rounded-full animate-spin" />
      </div>
    );
  }

  const formattedTime = plan.start_at
    ? new Date(plan.start_at).toLocaleString("en-US", {
        weekday: "long",
        month: "long",
        day: "numeric",
        year: "numeric",
        hour: "2-digit",
        minute: "2-digit",
      })
    : "Polling active";

  return (
    <div className="max-w-6xl mx-auto space-y-6">
      <Link href="/plans" className="text-xs text-[#656A6D] hover:text-[#1F2223] flex items-center gap-1.5 transition-colors font-medium">
        <ArrowLeft className="w-3.5 h-3.5" /> Back to Plans
      </Link>

      <div className="bg-white border border-[#E8E5DF] rounded-2xl p-6 flex flex-col md:flex-row md:items-center justify-between gap-6 shadow-xs">
        <div>
          <div className="flex items-center gap-2 mb-2.5">
            <span className="text-[10px] font-bold uppercase tracking-wider px-2.5 py-0.5 rounded-full bg-[#81D8D0]/18 border border-[#81D8D0]/40 text-[#1D5E57]">
              {plan.status}
            </span>
            <span className="text-[10px] font-bold uppercase tracking-wider px-2.5 py-0.5 rounded-full bg-[#D7D982]/25 border border-[#D7D982]/50 text-[#5C5E1A]">
              {plan.event_type}
            </span>
          </div>
          <h1 className="text-2xl font-bold text-[#1F2223] tracking-tight">{plan.title}</h1>
          {plan.description && <p className="text-xs text-[#656A6D] mt-1">{plan.description}</p>}
          <div className="flex items-center gap-2 text-xs text-[#656A6D] mt-3">
            <Clock className="w-4 h-4 text-[#2B7A72]" />
            <span className="font-mono font-medium">{formattedTime}</span>
          </div>
        </div>

        <div className="flex flex-col items-end gap-3 shrink-0">
          {/* Export to Calendar Button */}
          <button
            onClick={() => downloadIcsFile(plan)}
            className="px-4 py-2 bg-[#FAF9F6] hover:bg-[#F2EFE9] text-[#656A6D] border border-[#E8E5DF] rounded-xl text-xs font-semibold flex items-center gap-1.5 transition-all shadow-xs"
          >
            <Download className="w-3.5 h-3.5" /> Export .ics
          </button>

          {/* RSVP Selector */}
          <div className="flex items-center gap-1.5 bg-[#FAF9F6] p-1.5 rounded-xl border border-[#E8E5DF]">
            <button
              onClick={() => handleRsvp("attending")}
              className={`px-3 py-1.5 rounded-lg text-xs font-bold transition-all ${
                plan.my_rsvp === "attending" ? "bg-[#2B7A72] text-white shadow-xs" : "text-[#656A6D] hover:text-[#1F2223]"
              }`}
            >
              Attending
            </button>
            <button
              onClick={() => handleRsvp("tentative")}
              className={`px-3 py-1.5 rounded-lg text-xs font-bold transition-all ${
                plan.my_rsvp === "tentative" ? "bg-[#D99E82] text-white shadow-xs" : "text-[#656A6D] hover:text-[#1F2223]"
              }`}
            >
              Tentative
            </button>
            <button
              onClick={() => handleRsvp("declined")}
              className={`px-3 py-1.5 rounded-lg text-xs font-bold transition-all ${
                plan.my_rsvp === "declined" ? "bg-rose-500 text-white shadow-xs" : "text-[#656A6D] hover:text-[#1F2223]"
              }`}
            >
              Declined
            </button>
          </div>
        </div>
      </div>

      <div className="grid grid-cols-1 lg:grid-cols-3 gap-6">
        <div className="lg:col-span-2 space-y-6">
          <LocationVotingWidget
            planId={plan.id}
            locations={(plan as any).locations || []}
            onVoteSuccess={handleLocationUpdated}
          />

          <CircleActivityFeed circleId={plan.circle_id} />
        </div>
        
        <div className="lg:col-span-1">
          <PlanChatWidget planId={plan.id} />
        </div>
      </div>
    </div>
  );
}
