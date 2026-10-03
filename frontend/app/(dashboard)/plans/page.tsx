"use client";

import { useEffect, useState } from "react";
import { useSearchParams } from "next/navigation";
import { Plan, Circle } from "@/types/api";
import { apiClient } from "@/lib/api-client";
import { PlanCard } from "@/features/plans/components/plan-card";
import { CreatePlanModal } from "@/features/plans/components/create-plan-modal";
import { SkeletonCard } from "@/components/ui/skeleton";
import { CalendarCheck, Plus, ShieldCheck } from "lucide-react";
import { sessionCache } from "@/lib/session-cache";

interface PlansCacheData {
  plans: Plan[];
  circles: Circle[];
}

const PLANS_CACHE_KEY = "user_plans";

export default function PlansPage() {
  const searchParams = useSearchParams();
  const isCreateParam = searchParams.get("create") === "true";
  const dateParam = searchParams.get("date") || "";
  const startParam = searchParams.get("start") || "18:00";
  const endParam = searchParams.get("end") || "21:00";

  const cachedData = sessionCache.get<PlansCacheData>(PLANS_CACHE_KEY);

  const [plans, setPlans] = useState<Plan[]>(cachedData?.plans || []);
  const [circles, setCircles] = useState<Circle[]>(cachedData?.circles || []);
  const [isLoading, setIsLoading] = useState(!cachedData);
  const [isCreateOpen, setIsCreateOpen] = useState(isCreateParam);

  const loadPlansData = async (forceRefetch = false) => {
    if (forceRefetch || !sessionCache.has(PLANS_CACHE_KEY)) {
      if (!sessionCache.has(PLANS_CACHE_KEY)) setIsLoading(true);
      try {
        const [plansRes, circlesRes] = await Promise.all([
          apiClient.get<{ data: Plan[] }>("/plans"),
          apiClient.get<{ data: Circle[] }>("/circles"),
        ]);

        const fetchedPlans = plansRes.data || [];
        const fetchedCircles = circlesRes.data || [];

        setPlans(fetchedPlans);
        setCircles(fetchedCircles);

        sessionCache.set(PLANS_CACHE_KEY, {
          plans: fetchedPlans,
          circles: fetchedCircles,
        });
      } catch (err) {
        console.error("Failed to load plans data", err);
      } finally {
        setIsLoading(false);
      }
    }
  };

  useEffect(() => {
    if (!sessionCache.has(PLANS_CACHE_KEY)) {
      loadPlansData(true);
    }
  }, []);

  const handleRsvpChange = async (planId: number, rsvp: "attending" | "tentative" | "declined") => {
    try {
      await apiClient.post(`/plans/${planId}/rsvp`, { rsvp_status: rsvp });
      sessionCache.invalidate(PLANS_CACHE_KEY);
      sessionCache.invalidate("dashboard_overview");
      await loadPlansData(true);
    } catch (err: any) {
      alert(err.message || "Failed to update RSVP.");
    }
  };

  const handlePlanCreated = () => {
    sessionCache.invalidate(PLANS_CACHE_KEY);
    sessionCache.invalidate("dashboard_overview");
    loadPlansData(true);
  };

  return (
    <div className="max-w-6xl mx-auto space-y-6 md:space-y-8">
      {/* Header Controls Banner */}
      <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-4 bg-white border border-[#E8E5DF] rounded-2xl p-5 md:p-6 shadow-xs">
        <div className="flex items-start gap-3.5">
          <div className="w-10 h-10 rounded-xl bg-[#81D8D0]/20 border border-[#81D8D0]/40 flex items-center justify-center shrink-0 mt-0.5 shadow-xs">
            <CalendarCheck className="w-5 h-5 text-[#1D5E57]" />
          </div>
          <div>
            <div className="flex items-center gap-2">
              <h1 className="text-xl font-bold text-[#1F2223] tracking-tight">
                Meetup Plans & RSVPs
              </h1>
              <span className="inline-flex items-center gap-1 px-2 py-0.5 rounded-full bg-[#81D8D0]/20 text-[#1D5E57] text-[10px] font-mono font-semibold">
                <ShieldCheck className="w-3 h-3 text-[#2B7A72]" /> Circle Synced
              </span>
            </div>
            <p className="text-xs text-[#656A6D] mt-1 leading-relaxed">
              Coordinate confirmed social meetups, gather member RSVPs, and export direct .ics calendar invites.
            </p>
          </div>
        </div>

        <button
          onClick={() => setIsCreateOpen(true)}
          className="px-4 py-2.5 bg-[#2B7A72] hover:bg-[#1D5E57] text-white rounded-xl text-xs font-semibold transition-all shadow-xs flex items-center gap-1.5 shrink-0"
        >
          <Plus className="w-4 h-4 text-[#D7D982]" /> Create Meetup Plan
        </button>
      </div>

      {/* Plan Cards Grid */}
      <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-5">
        {isLoading ? (
          <>
            <SkeletonCard />
            <SkeletonCard />
            <SkeletonCard />
          </>
        ) : (
          <>
            {plans.map((plan) => (
              <PlanCard key={plan.id} plan={plan} onRsvpChange={handleRsvpChange} />
            ))}

            {plans.length === 0 && (
              <div className="col-span-full py-12 px-6 text-center border border-dashed border-[#E8E5DF] rounded-2xl bg-white">
                <div className="w-12 h-12 rounded-2xl bg-[#81D8D0]/20 text-[#1D5E57] flex items-center justify-center mx-auto mb-3 shadow-xs">
                  <CalendarCheck className="w-6 h-6 text-[#2B7A72]" />
                </div>
                <h3 className="text-sm font-bold text-[#1F2223]">No active meetup plans</h3>
                <p className="text-xs text-[#656A6D] mt-1 max-w-sm mx-auto leading-relaxed">
                  Create a plan or pick a Magic Hour suggestion on the Compare page to propose a new meetup.
                </p>
                <div className="mt-5">
                  <button
                    onClick={() => setIsCreateOpen(true)}
                    className="px-4 py-2 bg-[#2B7A72] text-white rounded-xl text-xs font-semibold shadow-xs"
                  >
                    + Create First Plan
                  </button>
                </div>
              </div>
            )}
          </>
        )}
      </div>

      {isCreateOpen && (
        <CreatePlanModal
          circles={circles}
          initialDate={dateParam}
          initialStart={startParam}
          initialEnd={endParam}
          isOpen={isCreateOpen}
          onClose={() => setIsCreateOpen(false)}
          onSuccess={handlePlanCreated}
        />
      )}
    </div>
  );
}
