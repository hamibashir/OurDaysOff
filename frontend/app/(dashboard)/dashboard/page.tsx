"use client";

import { useEffect, useState } from "react";
import { useAuth } from "@/features/auth/auth-context";
import { apiClient } from "@/lib/api-client";
import { Circle, Plan, ScheduleEntry } from "@/types/api";
import { ImportRotaModal } from "@/features/schedule/components/import-rota-modal";
import {
  Calendar,
  Clock,
  Users,
  Sparkles,
  ArrowRight,
  ShieldCheck,
  Plus,
  Upload,
  CalendarCheck,
  CheckCircle2,
  TrendingUp,
  MapPin,
  ChevronRight,
  Compass,
} from "lucide-react";
import Link from "next/link";
import { SkeletonMetricGrid, SkeletonList } from "@/components/ui/skeleton";

interface AvailabilityBlock {
  start: string;
  end: string;
  status: "available" | "busy" | "recovery";
}

type AvailabilityMap = Record<string, AvailabilityBlock[]>;

import { sessionCache } from "@/lib/session-cache";

interface DashboardCacheData {
  circles: Circle[];
  plans: Plan[];
  schedules: ScheduleEntry[];
  availability: AvailabilityMap;
}

const DASHBOARD_CACHE_KEY = "dashboard_overview";

export default function DashboardPage() {
  const { user } = useAuth();

  const cachedData = sessionCache.get<DashboardCacheData>(DASHBOARD_CACHE_KEY);

  const [circles, setCircles] = useState<Circle[]>(cachedData?.circles || []);
  const [plans, setPlans] = useState<Plan[]>(cachedData?.plans || []);
  const [schedules, setSchedules] = useState<ScheduleEntry[]>(cachedData?.schedules || []);
  const [availability, setAvailability] = useState<AvailabilityMap>(cachedData?.availability || {});
  const [isLoading, setIsLoading] = useState(!cachedData);
  const [isImportOpen, setIsImportOpen] = useState(false);

  const loadDashboardData = async (showLoading = true) => {
    if (showLoading) setIsLoading(true);
    try {
      const today = new Date();
      const startDate = today.toISOString().slice(0, 10);
      const nextWeek = new Date(today.getTime() + 14 * 86400000).toISOString().slice(0, 10);

      const [circlesRes, plansRes, schedulesRes, availRes] = await Promise.allSettled([
        apiClient.get<{ data: Circle[] }>("/circles"),
        apiClient.get<{ data: Plan[] }>("/plans"),
        apiClient.get<{ data: ScheduleEntry[] }>(`/schedules?start_date=${startDate}&end_date=${nextWeek}`),
        apiClient.get<{ data: AvailabilityMap }>(`/availability/personal?start_date=${startDate}&end_date=${nextWeek}`),
      ]);

      const fetchedCircles = circlesRes.status === "fulfilled" ? circlesRes.value.data || [] : [];
      const fetchedPlans = plansRes.status === "fulfilled" ? plansRes.value.data || [] : [];
      const fetchedSchedules = schedulesRes.status === "fulfilled" ? schedulesRes.value.data || [] : [];
      const fetchedAvailability = availRes.status === "fulfilled" ? availRes.value.data || {} : {};

      if (circlesRes.status === "fulfilled") setCircles(fetchedCircles);
      if (plansRes.status === "fulfilled") setPlans(fetchedPlans);
      if (schedulesRes.status === "fulfilled") setSchedules(fetchedSchedules);
      if (availRes.status === "fulfilled") setAvailability(fetchedAvailability);

      sessionCache.set(DASHBOARD_CACHE_KEY, {
        circles: fetchedCircles,
        plans: fetchedPlans,
        schedules: fetchedSchedules,
        availability: fetchedAvailability,
      });
    } catch (err) {
      console.error("Error loading dashboard data", err);
    } finally {
      setIsLoading(false);
    }
  };

  useEffect(() => {
    if (!sessionCache.has(DASHBOARD_CACHE_KEY)) {
      loadDashboardData(true);
    }
  }, []);

  const availabilityEntries = Object.entries(availability || {});
  const upcomingFreeDays = availabilityEntries.filter(
    ([_, blocks]) => Array.isArray(blocks) && blocks.some((b) => b.status === "available")
  );
  const activePlans = Array.isArray(plans) ? plans.filter((p) => p.status === "polling" || p.status === "confirmed") : [];

  return (
    <div className="max-w-6xl mx-auto space-y-6 md:space-y-8">
      {/* Hero Header Banner */}
      <div className="relative overflow-hidden rounded-2xl p-5 md:p-7 bg-gradient-to-r from-[#45ACA3] via-[#65A3B3] to-[#8C6DBE] text-white shadow-xs">
        <div className="absolute top-0 right-0 w-80 h-80 bg-white/10 rounded-full blur-3xl -z-10 pointer-events-none" />
        <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-5">
          <div className="space-y-1.5">
            <div className="inline-flex items-center gap-1.5 px-2.5 py-0.5 rounded-full bg-white/20 border border-white/30 text-white text-[11px] font-mono font-semibold backdrop-blur-xs">
              <Sparkles className="w-3 h-3 text-[#D7D982]" />
              <span>Schedule Intelligence Active</span>
            </div>
            <h1 className="text-xl md:text-2xl font-bold tracking-tight text-white">
              Welcome back, {user?.name.split(" ")[0]} 👋
            </h1>
            <p className="text-white/90 text-xs max-w-lg leading-relaxed">
              Your shift schedule stays 100% private. Free/busy availability is derived automatically for your circles.
            </p>
          </div>

          <div className="flex items-center gap-2.5 shrink-0">
            <button
              onClick={() => setIsImportOpen(true)}
              className="px-4 py-2.5 bg-white text-[#1D5E57] hover:bg-white/90 rounded-xl text-xs font-bold transition-all shadow-md flex items-center gap-2 cursor-pointer"
            >
              <Plus className="w-4 h-4 text-[#1D5E57]" />
              <span>Add / Import Rota</span>
            </button>
          </div>
        </div>
      </div>

      {/* Metrics Row - 4 Column Desktop / 2 Column Mobile */}
      {isLoading ? (
        <SkeletonMetricGrid />
      ) : (
        <div className="grid grid-cols-2 lg:grid-cols-4 gap-3.5 md:gap-4">
          {/* Metric 1: Upcoming Free Windows */}
          <div className="bg-white border border-[#E8E5DF] rounded-xl p-4 space-y-1.5 shadow-xs">
            <div className="flex items-center justify-between text-[#656A6D]">
              <span className="text-[10px] sm:text-[11px] font-bold uppercase tracking-wider">Upcoming Free Days</span>
              <Clock className="w-4 h-4 text-[#2B7A72]" />
            </div>
            <div className="flex items-baseline gap-2">
              <span className="text-2xl font-bold text-[#1F2223] font-mono">{upcomingFreeDays.length}</span>
              <span className="text-[11px] text-[#656A6D]">next 14 days</span>
            </div>
            <p className="text-[11px] text-[#2B7A72] font-semibold">Ready for matching</p>
          </div>

          {/* Metric 2: Active Circles */}
          <div className="bg-white border border-[#E8E5DF] rounded-xl p-4 space-y-1.5 shadow-xs">
            <div className="flex items-center justify-between text-[#656A6D]">
              <span className="text-[10px] sm:text-[11px] font-bold uppercase tracking-wider">Active Circles</span>
              <Users className="w-4 h-4 text-[#6A3E94]" />
            </div>
            <div className="flex items-baseline gap-2">
              <span className="text-2xl font-bold text-[#1F2223] font-mono">{circles.length}</span>
              <span className="text-[11px] text-[#656A6D]">connected</span>
            </div>
            <p className="text-[11px] text-[#6A3E94] font-semibold">Privacy visibility set</p>
          </div>

          {/* Metric 3: Active Plans */}
          <div className="bg-white border border-[#E8E5DF] rounded-xl p-4 space-y-1.5 shadow-xs">
            <div className="flex items-center justify-between text-[#656A6D]">
              <span className="text-[10px] sm:text-[11px] font-bold uppercase tracking-wider">Confirmed & Open Plans</span>
              <CalendarCheck className="w-4 h-4 text-[#A35439]" />
            </div>
            <div className="flex items-baseline gap-2">
              <span className="text-2xl font-bold text-[#1F2223] font-mono">{activePlans.length}</span>
              <span className="text-[11px] text-[#656A6D]">meetups</span>
            </div>
            <p className="text-[11px] text-[#A35439] font-semibold">RSVPs active</p>
          </div>

          {/* Metric 4: Rota Shifts */}
          <div className="bg-white border border-[#E8E5DF] rounded-xl p-4 space-y-1.5 shadow-xs">
            <div className="flex items-center justify-between text-[#656A6D]">
              <span className="text-[10px] sm:text-[11px] font-bold uppercase tracking-wider">Logged Shifts</span>
              <Sparkles className="w-4 h-4 text-[#66681E]" />
            </div>
            <div className="flex items-baseline gap-2">
              <span className="text-2xl font-bold text-[#1F2223] font-mono">{schedules.length}</span>
              <span className="text-[11px] text-[#656A6D]">shifts</span>
            </div>
            <p className="text-[11px] text-[#65681E] font-semibold">AI Rota parsed</p>
          </div>
        </div>
      )}

      {/* Quick Action Cards - Visible Early */}
      <div className="grid grid-cols-1 sm:grid-cols-2 gap-4">
        <Link href="/compare" className="bg-white border border-[#E8E5DF] hover:border-[#81D8D0] rounded-xl p-4.5 block group space-y-1.5 shadow-xs transition-all">
          <div className="flex items-center justify-between">
            <div className="flex items-center gap-2">
              <div className="w-8 h-8 rounded-lg bg-[#81D8D0]/20 border border-[#81D8D0]/40 flex items-center justify-center">
                <Compass className="w-4 h-4 text-[#2B7A72]" />
              </div>
              <h4 className="text-sm font-bold text-[#1F2223]">Compare Circle Schedules</h4>
            </div>
            <ArrowRight className="w-4 h-4 text-[#959A9E] group-hover:text-[#2B7A72] group-hover:translate-x-0.5 transition-all" />
          </div>
          <p className="text-xs text-[#656A6D] leading-relaxed">
            Instantly calculate N-way availability intersections and discover Magic Hour meeting windows.
          </p>
        </Link>

        <Link href="/plans" className="bg-white border border-[#E8E5DF] hover:border-[#D99E82] rounded-xl p-4.5 block group space-y-1.5 shadow-xs transition-all">
          <div className="flex items-center justify-between">
            <div className="flex items-center gap-2">
              <div className="w-8 h-8 rounded-lg bg-[#D99E82]/20 border border-[#D99E82]/40 flex items-center justify-center">
                <Calendar className="w-4 h-4 text-[#A35439]" />
              </div>
              <h4 className="text-sm font-bold text-[#1F2223]">Create Meetup Plan</h4>
            </div>
            <ArrowRight className="w-4 h-4 text-[#959A9E] group-hover:text-[#A35439] group-hover:translate-x-0.5 transition-all" />
          </div>
          <p className="text-xs text-[#656A6D] leading-relaxed">
            Propose dates, poll locations, gather RSVPs, and export confirmed events to `.ics` calendar.
          </p>
        </Link>
      </div>

      {/* Main Grid: Availability Preview (Left 2/3) + My Circles (Right 1/3) */}
      <div className="grid grid-cols-1 lg:grid-cols-3 gap-6">
        {/* Left Column (2/3): 14-Day Availability Timeline Preview */}
        <div className="lg:col-span-2 space-y-4">
          <div className="bg-white border border-[#E8E5DF] rounded-xl p-5 space-y-4 shadow-xs">
            <div className="flex items-center justify-between pb-3 border-b border-[#E8E5DF]">
              <div className="flex items-center gap-2">
                <Clock className="w-4 h-4 text-[#2B7A72]" />
                <h3 className="text-sm font-bold text-[#1F2223] tracking-tight">14-Day Availability Preview</h3>
              </div>
              <Link href="/schedule" className="text-xs text-[#2B7A72] hover:underline font-semibold flex items-center gap-1">
                Full Calendar <ChevronRight className="w-3.5 h-3.5" />
              </Link>
            </div>

            {isLoading ? (
              <SkeletonList count={5} />
            ) : availabilityEntries.length === 0 ? (
              <div className="p-6 text-center border border-dashed border-[#E8E5DF] rounded-xl text-xs text-[#656A6D] space-y-2">
                <p>No shift entries logged for the next 14 days.</p>
                <Link href="/schedule" className="inline-block px-3.5 py-1.5 bg-[#81D8D0]/20 text-[#23756C] rounded-lg text-xs font-semibold border border-[#81D8D0]/40">
                  + Add Shifts or Import Rota
                </Link>
              </div>
            ) : (
              <div className="space-y-2">
                {availabilityEntries.slice(0, 6).map(([dateStr, blocks]) => {
                  const primaryStatus = blocks[0]?.status || "available";
                  const timeSummary = blocks.map((b) => `${b.start}–${b.end}`).join(", ");
                  return (
                    <div
                      key={dateStr}
                      className="p-3 rounded-xl bg-[#FAF9F6] border border-[#E8E5DF] flex items-center justify-between text-xs"
                    >
                      <div className="flex items-center gap-3">
                        <span className="font-mono text-[#1F2223] font-semibold w-24">{dateStr}</span>
                        <span
                          className={`text-[10px] font-bold uppercase tracking-wider px-2.5 py-0.5 rounded ${
                            primaryStatus === "available"
                              ? "badge-free"
                              : primaryStatus === "recovery"
                              ? "badge-recovery"
                              : "badge-busy"
                          }`}
                        >
                          {primaryStatus}
                        </span>
                      </div>

                      <div className="text-right font-mono text-[#656A6D] text-[11px]">
                        {timeSummary}
                      </div>
                    </div>
                  );
                })}
              </div>
            )}
          </div>
        </div>

        {/* Right Column (1/3): Active Circles & Privacy Guarantee */}
        <div className="space-y-6">
          {/* Active Circles Quick List */}
          <div className="bg-white border border-[#E8E5DF] rounded-xl p-5 space-y-4 shadow-xs">
            <div className="flex items-center justify-between pb-3 border-b border-[#E8E5DF]">
              <div className="flex items-center gap-2">
                <Users className="w-4 h-4 text-[#6A3E94]" />
                <h3 className="text-sm font-bold text-[#1F2223]">My Circles</h3>
              </div>
              <Link href="/circles" className="text-xs text-[#6A3E94] hover:underline font-semibold">
                View All
              </Link>
            </div>

            {circles.length === 0 ? (
              <div className="p-4 text-center text-xs text-[#959A9E]">No circles joined yet</div>
            ) : (
              <div className="space-y-2">
                {circles.slice(0, 4).map((c) => (
                  <Link
                    key={c.id}
                    href={`/circles/${c.id}`}
                    className="p-3 rounded-xl bg-[#FAF9F6] border border-[#E8E5DF] hover:border-[#D8D4CC] flex items-center justify-between transition-colors block"
                  >
                    <div>
                      <h4 className="text-xs font-bold text-[#1F2223]">{c.name}</h4>
                      <p className="text-[10px] text-[#656A6D] font-mono">@{c.handle}</p>
                    </div>
                    <span className="text-[10px] text-[#6A3E94] font-semibold uppercase px-2 py-0.5 rounded bg-[#AE82D9]/15 border border-[#AE82D9]/40">
                      {(c as any).pivot?.role || "member"}
                    </span>
                  </Link>
                ))}
              </div>
            )}
          </div>

          {/* Privacy Guarantee Footer Box */}
          <div className="p-4 rounded-xl bg-[#81D8D0]/12 border border-[#81D8D0]/40 flex items-start gap-3 text-xs text-[#1F2223] shadow-xs">
            <ShieldCheck className="w-4 h-4 text-[#2B7A72] shrink-0 mt-0.5" />
            <div className="space-y-1">
              <h4 className="font-semibold text-[#1F2223]">Privacy Guarantee</h4>
              <p className="text-[11px] text-[#656A6D] leading-relaxed">
                Raw shifts stay encrypted on your account. Circles only process derived free/busy windows according to your configured privacy rules.
              </p>
            </div>
          </div>
        </div>
      </div>

      {/* AI Rota Import Modal */}
      <ImportRotaModal
        isOpen={isImportOpen}
        onClose={() => setIsImportOpen(false)}
        onSuccess={loadDashboardData}
      />
    </div>
  );
}
