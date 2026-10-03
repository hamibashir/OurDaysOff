"use client";

import { useEffect, useState, useMemo } from "react";
import {
  ScheduleEntry,
  ShiftTemplate,
  Circle,
  CircleAvailabilityResponseData,
  CircleRosterMember,
} from "@/types/api";
import { apiClient } from "@/lib/api-client";
import { sessionCache } from "@/lib/session-cache";
import { MonthCalendar } from "@/features/schedule/components/month-calendar";
import { RotaGrid } from "@/features/schedule/components/rota-grid";
import { CompareView } from "@/features/schedule/components/compare-view";
import { DateDetailDrawer } from "@/features/schedule/components/date-detail-drawer";
import { ShiftTemplatePicker } from "@/features/schedule/components/shift-template-picker";
import { ImportRotaModal } from "@/features/schedule/components/import-rota-modal";
import { CreatePlanModal } from "@/features/schedule/components/create-plan-modal";
import {
  Calendar as CalendarIcon,
  Clock,
  Sparkles,
  Users,
  Grid3X3,
  SlidersHorizontal,
  Plus,
  Upload,
  ShieldCheck,
  X,
  Check,
  Loader2,
  CalendarDays,
  Flame,
} from "lucide-react";

export default function SchedulePage() {
  const [currentDate, setCurrentDate] = useState(new Date());
  const year = currentDate.getFullYear();
  const month = currentDate.getMonth();

  // Active View Tabs
  const [activeTab, setActiveTab] = useState<"month" | "rota_grid" | "compare">("month");
  const [availabilityMode, setAvailabilityMode] = useState<"days_off" | "off_time">("days_off");
  const [viewPerspective, setViewPerspective] = useState<"group" | "individual">("group");
  const [selectedMemberId, setSelectedMemberId] = useState<number | null>(null);

  // Selected date for inspection and assignment
  const [selectedDate, setSelectedDate] = useState<string>(
    new Date().toISOString().slice(0, 10)
  );

  // Circles and active circle
  const cachedCircles = sessionCache.get<Circle[]>("user_circles");
  const [circles, setCircles] = useState<Circle[]>(cachedCircles || []);
  const [selectedCircleId, setSelectedCircleId] = useState<number | null>(
    cachedCircles && cachedCircles.length > 0 ? cachedCircles[0].id : null
  );

  // Personal schedule entries & templates
  const [personalEntries, setPersonalEntries] = useState<ScheduleEntry[]>([]);
  const [templates, setTemplates] = useState<ShiftTemplate[]>([]);
  const [selectedTemplate, setSelectedTemplate] = useState<ShiftTemplate | null>(null);
  const [currentUserId, setCurrentUserId] = useState<number | null>(null);

  // Circle availability & roster data
  const [circleData, setCircleData] = useState<CircleAvailabilityResponseData | null>(null);
  const [isLoadingCircle, setIsLoadingCircle] = useState(false);
  const [isLoadingPersonal, setIsLoadingPersonal] = useState(false);

  // Modals state
  const [isShiftModalOpen, setIsShiftModalOpen] = useState(false);
  const [isTemplateModalOpen, setIsTemplateModalOpen] = useState(false);
  const [isImportOpen, setIsImportOpen] = useState(false);
  const [isCreatePlanOpen, setIsCreatePlanOpen] = useState(false);
  const [planPrefill, setPlanPrefill] = useState({
    date: selectedDate,
    start_time: "18:00",
    end_time: "21:00",
  });

  // Shift & Template form states
  const [shiftForm, setShiftForm] = useState({
    date: selectedDate,
    start_time: "07:00",
    end_time: "15:00",
    entry_type: "work",
    label: "",
    notes: "",
    is_overnight: false,
  });

  const [templateForm, setTemplateForm] = useState({
    name: "",
    start_time: "07:00",
    end_time: "15:00",
    color: "#3b82f6",
  });

  // 1. Fetch current user & circles
  useEffect(() => {
    const fetchInitialUserAndCircles = async () => {
      try {
        const [meRes, circlesRes] = await Promise.all([
          apiClient.get<{ data: { user: { id: number } } }>("/auth/me"),
          apiClient.get<{ data: Circle[] }>("/circles"),
        ]);
        if (meRes.data?.user?.id) {
          setCurrentUserId(meRes.data.user.id);
        }
        const list = circlesRes.data || [];
        setCircles(list);
        sessionCache.set("user_circles", list);
        if (list.length > 0 && !selectedCircleId) {
          setSelectedCircleId(list[0].id);
        }
      } catch (err) {
        console.error("Failed to fetch user and circles", err);
      }
    };
    fetchInitialUserAndCircles();
  }, []);

  // 2. Fetch personal schedule & templates for current month
  const monthStr = String(month + 1).padStart(2, "0");
  const startDate = `${year}-${monthStr}-01`;
  const lastDay = new Date(year, month + 1, 0).getDate();
  const endDate = `${year}-${monthStr}-${String(lastDay).padStart(2, "0")}`;

  const loadPersonalData = async () => {
    setIsPersonalLoading(true);
    try {
      const [schedulesRes, templatesRes] = await Promise.all([
        apiClient.get<{ data: ScheduleEntry[] }>(`/schedules?start_date=${startDate}&end_date=${endDate}`),
        apiClient.get<{ data: ShiftTemplate[] }>("/shift-templates"),
      ]);
      setPersonalEntries(schedulesRes.data || []);
      setTemplates(templatesRes.data || []);
    } catch (err) {
      console.error("Failed to load personal schedules", err);
    } finally {
      setIsPersonalLoading(false);
    }
  };

  const setIsPersonalLoading = (loading: boolean) => setIsLoadingPersonal(loading);

  useEffect(() => {
    loadPersonalData();
  }, [currentDate]);

  // 3. Fetch circle availability data for the selected circle and month
  const loadCircleAvailability = async (force = false) => {
    if (!selectedCircleId) return;
    const cacheKey = `circle_avail_${selectedCircleId}_${startDate}_${endDate}`;
    const cached = sessionCache.get<CircleAvailabilityResponseData>(cacheKey);

    if (cached && !force) {
      setCircleData(cached);
      return;
    }

    setIsLoadingCircle(true);
    try {
      const res = await apiClient.get<{ data: CircleAvailabilityResponseData }>(
        `/circles/${selectedCircleId}/availability?start_date=${startDate}&end_date=${endDate}`
      );
      setCircleData(res.data);
      sessionCache.set(cacheKey, res.data);
    } catch (err) {
      console.error("Failed to load circle availability", err);
    } finally {
      setIsLoadingCircle(false);
    }
  };

  useEffect(() => {
    loadCircleAvailability();
  }, [selectedCircleId, currentDate]);

  const handleNavigateMonth = (direction: "prev" | "next") => {
    setCurrentDate((prev) => {
      const newDate = new Date(prev);
      if (direction === "prev") {
        newDate.setMonth(newDate.getMonth() - 1);
      } else {
        newDate.setMonth(newDate.getMonth() + 1);
      }
      return newDate;
    });
  };

  const handleDateClick = async (dateStr: string) => {
    setSelectedDate(dateStr);
    setShiftForm((prev) => ({ ...prev, date: dateStr }));

    // If template quick assign is active, apply template directly!
    if (selectedTemplate) {
      try {
        await apiClient.post("/schedules", {
          date: dateStr,
          shift_template_id: selectedTemplate.id,
          start_time: selectedTemplate.start_time.slice(0, 5),
          end_time: selectedTemplate.end_time.slice(0, 5),
          entry_type: "work",
          label: selectedTemplate.name,
          is_overnight: selectedTemplate.is_overnight,
        });
        sessionCache.invalidate(/^circle_avail_/);
        sessionCache.invalidate(/^compare_/);
        sessionCache.invalidate(/^schedule_/);
        await Promise.all([loadPersonalData(), loadCircleAvailability(true)]);
      } catch (err) {
        console.error("Failed to assign template", err);
      }
    }
  };

  const handleSaveShift = async (e: React.FormEvent) => {
    e.preventDefault();
    try {
      await apiClient.post("/schedules", shiftForm);
      setIsShiftModalOpen(false);
      sessionCache.invalidate(/^circle_avail_/);
      sessionCache.invalidate(/^compare_/);
      sessionCache.invalidate(/^schedule_/);
      await Promise.all([loadPersonalData(), loadCircleAvailability(true)]);
    } catch (err: any) {
      alert(err.message || "Failed to save shift.");
    }
  };

  const handleDeleteShift = async () => {
    const activeEntry = personalEntries.find((e) => e.date === selectedDate);
    if (!activeEntry) return;

    if (confirm("Remove this shift entry?")) {
      try {
        await apiClient.delete(`/schedules/${activeEntry.id}`);
        sessionCache.invalidate(/^circle_avail_/);
        sessionCache.invalidate(/^compare_/);
        sessionCache.invalidate(/^schedule_/);
        await Promise.all([loadPersonalData(), loadCircleAvailability(true)]);
      } catch (err) {
        console.error("Failed to delete entry", err);
      }
    }
  };

  const handleSaveTemplate = async (e: React.FormEvent) => {
    e.preventDefault();
    try {
      await apiClient.post("/shift-templates", templateForm);
      setIsTemplateModalOpen(false);
      setTemplateForm({ name: "", start_time: "07:00", end_time: "15:00", color: "#3b82f6" });
      await loadPersonalData();
    } catch (err: any) {
      alert(err.message || "Failed to create template.");
    }
  };

  const handleOpenCreatePlan = (prefill: { date: string; start_time: string; end_time: string }) => {
    setPlanPrefill(prefill);
    setIsCreatePlanOpen(true);
  };

  const selectedPersonalEntry = useMemo(() => {
    return personalEntries.find((e) => e.date === selectedDate) || null;
  }, [personalEntries, selectedDate]);

  const selectedCircle = useMemo(() => {
    return circles.find((c) => c.id === selectedCircleId) || null;
  }, [circles, selectedCircleId]);

  return (
    <div className="max-w-7xl mx-auto space-y-6 md:space-y-8 pb-12">
      {/* Top Banner & Control Deck */}
      <div className="bg-white border border-[#E8E5DF] rounded-2xl p-5 md:p-6 shadow-xs space-y-5">
        <div className="flex flex-col lg:flex-row lg:items-center justify-between gap-4">
          <div className="flex items-start gap-3.5">
            <div className="w-10 h-10 rounded-xl bg-[#81D8D0]/20 border border-[#81D8D0]/40 flex items-center justify-center shrink-0 mt-0.5 shadow-xs">
              <CalendarDays className="w-5 h-5 text-[#1D5E57]" />
            </div>
            <div>
              <div className="flex items-center gap-2">
                <h1 className="text-xl font-bold text-[#1F2223] tracking-tight">
                  Schedule & Availability Hub
                </h1>
                <span className="inline-flex items-center gap-1 px-2.5 py-0.5 rounded-full bg-[#81D8D0]/20 text-[#1D5E57] text-[10px] font-mono font-bold">
                  <ShieldCheck className="w-3.5 h-3.5 text-[#2B7A72]" /> Privacy Protected
                </span>
              </div>
              <p className="text-xs text-[#656A6D] mt-1 leading-relaxed max-w-2xl">
                When are we actually all free? Explore full Days Off, calculate mutual Magic Hours, and propose meetups directly from free windows.
              </p>
            </div>
          </div>

          {/* Quick Action Buttons */}
          <div className="flex flex-wrap items-center gap-2.5 shrink-0">
            <button
              onClick={() => setIsImportOpen(true)}
              className="px-3.5 py-2.5 bg-[#FAF9F6] hover:bg-[#F2EFE9] text-[#1F2223] border border-[#E8E5DF] rounded-xl text-xs font-semibold transition-all flex items-center gap-1.5 shadow-xs"
            >
              <Upload className="w-3.5 h-3.5 text-[#2B7A72]" />
              Import Rota
            </button>
            <button
              onClick={() => {
                setShiftForm({
                  date: selectedDate,
                  start_time: "07:00",
                  end_time: "15:00",
                  entry_type: "work",
                  label: "",
                  notes: "",
                  is_overnight: false,
                });
                setIsShiftModalOpen(true);
              }}
              className="px-4 py-2.5 bg-[#2B7A72] hover:bg-[#1D5E57] text-white rounded-xl text-xs font-semibold transition-all shadow-xs flex items-center gap-1.5"
            >
              <Plus className="w-4 h-4 text-[#D7D982]" />
              Add Shift Entry
            </button>
          </div>
        </div>

        {/* Navigation Deck: Circle Picker, 3 View Tabs, and Dual Availability Modes */}
        <div className="pt-3 border-t border-[#E8E5DF] flex flex-col md:flex-row md:items-center justify-between gap-4">
          {/* Active Circle Selector */}
          <div className="flex items-center gap-2 bg-[#FAF9F6] border border-[#E8E5DF] rounded-xl px-3 py-2 text-xs shadow-xs shrink-0">
            <Users className="w-4 h-4 text-[#2B7A72]" />
            <select
              value={selectedCircleId || ""}
              onChange={(e) => setSelectedCircleId(Number(e.target.value))}
              disabled={circles.length === 0}
              className="bg-transparent text-[#1F2223] font-bold outline-none cursor-pointer text-xs"
            >
              {circles.length === 0 ? (
                <option value="">No Circles Available</option>
              ) : (
                circles.map((c) => (
                  <option key={c.id} value={c.id}>
                    Circle: {c.name} ({circleData?.members?.length || c.members_count || 0} members)
                  </option>
                ))
              )}
            </select>
          </div>

          {/* 3 Core View Tabs (Month, Rota Grid, Compare) */}
          <div className="flex items-center bg-[#FAF9F6] p-1 rounded-xl border border-[#E8E5DF] self-start md:self-auto">
            <button
              onClick={() => setActiveTab("month")}
              className={`px-3.5 py-1.5 rounded-lg text-xs font-bold transition-all flex items-center gap-1.5 ${
                activeTab === "month"
                  ? "bg-white text-[#1D5E57] shadow-xs border border-[#E8E5DF]"
                  : "text-[#656A6D] hover:text-[#1F2223]"
              }`}
            >
              <CalendarIcon className="w-3.5 h-3.5" />
              Month
            </button>

            <button
              onClick={() => setActiveTab("rota_grid")}
              className={`px-3.5 py-1.5 rounded-lg text-xs font-bold transition-all flex items-center gap-1.5 ${
                activeTab === "rota_grid"
                  ? "bg-white text-[#1D5E57] shadow-xs border border-[#E8E5DF]"
                  : "text-[#656A6D] hover:text-[#1F2223]"
              }`}
            >
              <Grid3X3 className="w-3.5 h-3.5" />
              Rota Grid
            </button>

            <button
              onClick={() => setActiveTab("compare")}
              className={`px-3.5 py-1.5 rounded-lg text-xs font-bold transition-all flex items-center gap-1.5 ${
                activeTab === "compare"
                  ? "bg-white text-[#1D5E57] shadow-xs border border-[#E8E5DF]"
                  : "text-[#656A6D] hover:text-[#1F2223]"
              }`}
            >
              <SlidersHorizontal className="w-3.5 h-3.5" />
              Compare
            </button>
          </div>

          {/* Dual Availability Mode Toggle (Days Off vs Off Time) */}
          {(activeTab === "month" || activeTab === "compare") && (
            <div className="flex items-center bg-[#FAF9F6] p-1 rounded-xl border border-[#E8E5DF] shrink-0">
              <button
                onClick={() => setAvailabilityMode("days_off")}
                className={`px-3 py-1.5 rounded-lg text-xs font-bold transition-all flex items-center gap-1.5 ${
                  availabilityMode === "days_off"
                    ? "bg-[#2B7A72] text-white shadow-xs"
                    : "text-[#656A6D] hover:text-[#1F2223]"
                }`}
              >
                <span>Days Off</span>
              </button>
              <button
                onClick={() => setAvailabilityMode("off_time")}
                className={`px-3 py-1.5 rounded-lg text-xs font-bold transition-all flex items-center gap-1.5 ${
                  availabilityMode === "off_time"
                    ? "bg-[#2B7A72] text-white shadow-xs"
                    : "text-[#656A6D] hover:text-[#1F2223]"
                }`}
              >
                <Sparkles className="w-3 h-3 text-[#D7D982]" />
                <span>Off Time (Magic Hour)</span>
              </button>
            </div>
          )}
        </div>

        {/* Month View Sub-Perspective Switcher (Group Overview vs Individual Rota) */}
        {activeTab === "month" && (
          <div className="pt-2 border-t border-dashed border-[#E8E5DF] flex flex-wrap items-center justify-between gap-3">
            <div className="flex items-center gap-2">
              <span className="text-xs font-bold text-[#656A6D]">Perspective:</span>
              <div className="flex items-center bg-[#FAF9F6] p-0.5 rounded-lg border border-[#E8E5DF]">
                <button
                  onClick={() => setViewPerspective("group")}
                  className={`px-3 py-1 rounded-md text-xs font-semibold transition-all ${
                    viewPerspective === "group"
                      ? "bg-white text-[#1F2223] shadow-xs font-bold"
                      : "text-[#656A6D]"
                  }`}
                >
                  Circle Group Overview
                </button>
                <button
                  onClick={() => {
                    setViewPerspective("individual");
                    if (!selectedMemberId && circleData?.members?.length) {
                      setSelectedMemberId(circleData.members[0].user.id);
                    }
                  }}
                  className={`px-3 py-1 rounded-md text-xs font-semibold transition-all ${
                    viewPerspective === "individual"
                      ? "bg-white text-[#1F2223] shadow-xs font-bold"
                      : "text-[#656A6D]"
                  }`}
                >
                  Individual Person Rota
                </button>
              </div>
            </div>

            {viewPerspective === "individual" && (
              <div className="flex items-center gap-2">
                <span className="text-xs font-bold text-[#656A6D]">Viewing Member:</span>
                <select
                  value={selectedMemberId || ""}
                  onChange={(e) => setSelectedMemberId(Number(e.target.value))}
                  className="bg-[#FAF9F6] border border-[#E8E5DF] rounded-lg px-2.5 py-1 text-xs text-[#1F2223] font-bold outline-none cursor-pointer"
                >
                  {circleData?.members?.map((m) => (
                    <option key={m.user.id} value={m.user.id}>
                      {m.user.name} ({m.visibility})
                    </option>
                  ))}
                </select>
              </div>
            )}
          </div>
        )}
      </div>

      {/* 1-Tap Shift Template Bar */}
      <div className="bg-white border border-[#E8E5DF] rounded-2xl p-4 md:p-5 shadow-xs">
        <ShiftTemplatePicker
          templates={templates}
          selectedTemplateId={selectedTemplate?.id || null}
          onSelect={(tpl) => setSelectedTemplate(tpl)}
          onCreateNew={() => setIsTemplateModalOpen(true)}
        />
        {selectedTemplate && (
          <div className="text-xs text-[#1D5E57] mt-3 font-medium flex items-center justify-between gap-2 bg-[#81D8D0]/18 p-3 rounded-xl border border-[#81D8D0]/40">
            <span className="flex items-center gap-1.5">
              <Sparkles className="w-4 h-4 text-[#2B7A72] shrink-0" />
              1-Tap Quick Assign active for: <strong className="font-bold">{selectedTemplate.name}</strong> ({selectedTemplate.start_time.slice(0, 5)} - {selectedTemplate.end_time.slice(0, 5)}). Click any date on the calendar to apply!
            </span>
            <button
              onClick={() => setSelectedTemplate(null)}
              className="text-[11px] font-bold text-[#1D5E57] underline hover:text-[#154540] shrink-0"
            >
              Cancel Quick Assign
            </button>
          </div>
        )}
      </div>

      {/* Main Content Layout: Active View Component + Date Details Inspector */}
      <div className="grid grid-cols-1 lg:grid-cols-3 gap-6">
        <div className="lg:col-span-2">
          {activeTab === "month" && (
            <MonthCalendar
              currentDate={currentDate}
              onNavigateMonth={handleNavigateMonth}
              onSelectDate={handleDateClick}
              selectedDate={selectedDate}
              availabilityMode={availabilityMode}
              viewPerspective={viewPerspective}
              selectedMemberId={selectedMemberId}
              members={circleData?.members || []}
              daysOff={circleData?.days_off || {}}
              offTime={circleData?.off_time || {}}
              plans={circleData?.plans || []}
              personalEntries={personalEntries}
              currentUserId={currentUserId}
              isLoading={isLoadingCircle}
            />
          )}

          {activeTab === "rota_grid" && (
            <RotaGrid
              currentDate={currentDate}
              members={circleData?.members || []}
              plans={circleData?.plans || []}
              onSelectDate={handleDateClick}
              onSelectMember={(mId) => {
                setSelectedMemberId(mId);
                setViewPerspective("individual");
                setActiveTab("month");
              }}
              selectedDate={selectedDate}
              isLoading={isLoadingCircle}
            />
          )}

          {activeTab === "compare" && (
            <CompareView
              currentDate={currentDate}
              circleId={selectedCircleId}
              members={circleData?.members || []}
              plans={circleData?.plans || []}
              onNavigateMonth={handleNavigateMonth}
              onSelectDate={handleDateClick}
              selectedDate={selectedDate}
              availabilityMode={availabilityMode}
              onToggleAvailabilityMode={(m) => setAvailabilityMode(m)}
              onCreatePlanFromOverlap={(d, win) => {
                handleOpenCreatePlan({
                  date: d,
                  start_time: win.start,
                  end_time: win.end,
                });
              }}
            />
          )}
        </div>

        {/* Right 1/3: Date Detail Drawer & Direct Planning */}
        <div>
          <DateDetailDrawer
            dateStr={selectedDate}
            members={circleData?.members || []}
            daysOffSummary={circleData?.days_off?.[selectedDate]}
            offTimeSummary={circleData?.off_time?.[selectedDate]}
            plans={circleData?.plans || []}
            personalEntry={selectedPersonalEntry}
            currentUserId={currentUserId}
            onEditPersonalShift={() => {
              if (selectedPersonalEntry) {
                setShiftForm({
                  date: selectedPersonalEntry.date,
                  start_time: selectedPersonalEntry.start_time.slice(0, 5),
                  end_time: selectedPersonalEntry.end_time.slice(0, 5),
                  entry_type: selectedPersonalEntry.entry_type,
                  label: selectedPersonalEntry.label || "",
                  notes: selectedPersonalEntry.notes || "",
                  is_overnight: selectedPersonalEntry.is_overnight,
                });
              } else {
                setShiftForm({
                  date: selectedDate,
                  start_time: "07:00",
                  end_time: "15:00",
                  entry_type: "work",
                  label: "",
                  notes: "",
                  is_overnight: false,
                });
              }
              setIsShiftModalOpen(true);
            }}
            onDeletePersonalShift={handleDeleteShift}
            onOpenCreatePlan={handleOpenCreatePlan}
          />
        </div>
      </div>

      {/* Direct Create Plan Modal */}
      <CreatePlanModal
        isOpen={isCreatePlanOpen}
        onClose={() => setIsCreatePlanOpen(false)}
        onSuccess={() => {
          loadCircleAvailability(true);
        }}
        circles={circles}
        selectedCircleId={selectedCircleId}
        initialDate={planPrefill.date}
        initialStartTime={planPrefill.start_time}
        initialEndTime={planPrefill.end_time}
      />

      {/* Manual Shift Entry Modal */}
      {isShiftModalOpen && (
        <div className="fixed inset-0 bg-zinc-950/50 backdrop-blur-xs z-50 flex items-center justify-center p-4">
          <div className="bg-white border border-zinc-200 rounded-2xl max-w-md w-full p-6 shadow-xl space-y-4">
            <div className="flex items-center justify-between pb-3 border-b border-zinc-200">
              <h3 className="font-bold text-zinc-900 text-base">Shift Entry — {shiftForm.date}</h3>
              <button onClick={() => setIsShiftModalOpen(false)} className="text-zinc-400 hover:text-zinc-600">
                <X className="w-5 h-5" />
              </button>
            </div>

            <form onSubmit={handleSaveShift} className="space-y-4">
              <div>
                <label className="block text-xs font-semibold uppercase text-zinc-600 mb-1">Shift Label</label>
                <input
                  type="text"
                  placeholder="e.g. Early Shift, Night Duty, Training"
                  value={shiftForm.label}
                  onChange={(e) => setShiftForm({ ...shiftForm, label: e.target.value })}
                  className="w-full bg-zinc-50 border border-zinc-200 rounded-xl px-3 py-2 text-xs text-zinc-900 outline-none focus:border-[#2B7A72]"
                />
              </div>

              <div className="grid grid-cols-2 gap-3">
                <div>
                  <label className="block text-xs font-semibold uppercase text-zinc-600 mb-1">Start Time</label>
                  <input
                    type="time"
                    required
                    value={shiftForm.start_time}
                    onChange={(e) => setShiftForm({ ...shiftForm, start_time: e.target.value })}
                    className="w-full bg-zinc-50 border border-zinc-200 rounded-xl px-3 py-2 text-xs text-zinc-900 font-mono outline-none focus:border-[#2B7A72]"
                  />
                </div>
                <div>
                  <label className="block text-xs font-semibold uppercase text-zinc-600 mb-1">End Time</label>
                  <input
                    type="time"
                    required
                    value={shiftForm.end_time}
                    onChange={(e) => setShiftForm({ ...shiftForm, end_time: e.target.value })}
                    className="w-full bg-zinc-50 border border-zinc-200 rounded-xl px-3 py-2 text-xs text-zinc-900 font-mono outline-none focus:border-[#2B7A72]"
                  />
                </div>
              </div>

              <div className="flex items-center gap-2">
                <input
                  type="checkbox"
                  id="is_overnight"
                  checked={shiftForm.is_overnight}
                  onChange={(e) => setShiftForm({ ...shiftForm, is_overnight: e.target.checked })}
                  className="rounded border-zinc-300 text-[#2B7A72] focus:ring-[#2B7A72]"
                />
                <label htmlFor="is_overnight" className="text-xs text-zinc-700 font-medium cursor-pointer">
                  Overnight Shift (e.g. 19:00 to 07:00 next day)
                </label>
              </div>

              <div>
                <label className="block text-xs font-semibold uppercase text-zinc-600 mb-1">Entry Type</label>
                <select
                  value={shiftForm.entry_type}
                  onChange={(e) => setShiftForm({ ...shiftForm, entry_type: e.target.value })}
                  className="w-full bg-zinc-50 border border-zinc-200 rounded-xl px-3 py-2 text-xs text-zinc-900 outline-none focus:border-[#2B7A72]"
                >
                  <option value="work">Work Shift</option>
                  <option value="leave">Leave / Vacation</option>
                  <option value="off">Off Day</option>
                  <option value="personal">Personal Event</option>
                  <option value="other">Other</option>
                </select>
              </div>

              <div>
                <label className="block text-xs font-semibold uppercase text-zinc-600 mb-1">Notes (Visible only if details shared)</label>
                <textarea
                  rows={2}
                  placeholder="Optional shift notes..."
                  value={shiftForm.notes}
                  onChange={(e) => setShiftForm({ ...shiftForm, notes: e.target.value })}
                  className="w-full bg-zinc-50 border border-zinc-200 rounded-xl px-3 py-2 text-xs text-zinc-900 outline-none focus:border-[#2B7A72]"
                />
              </div>

              <div className="pt-2 flex justify-end gap-3">
                <button
                  type="button"
                  onClick={() => setIsShiftModalOpen(false)}
                  className="px-4 py-2 bg-zinc-100 hover:bg-zinc-200 text-zinc-700 rounded-xl text-xs font-semibold"
                >
                  Cancel
                </button>
                <button
                  type="submit"
                  className="px-5 py-2 bg-[#2B7A72] hover:bg-[#1D5E57] text-white rounded-xl text-xs font-semibold shadow-xs"
                >
                  Save Shift
                </button>
              </div>
            </form>
          </div>
        </div>
      )}

      {/* Template Creation Modal */}
      {isTemplateModalOpen && (
        <div className="fixed inset-0 bg-zinc-950/50 backdrop-blur-xs z-50 flex items-center justify-center p-4">
          <div className="bg-white border border-zinc-200 rounded-2xl max-w-md w-full p-6 shadow-xl space-y-4">
            <div className="flex items-center justify-between pb-3 border-b border-zinc-200">
              <h3 className="font-bold text-zinc-900 text-base">New Shift Template</h3>
              <button onClick={() => setIsTemplateModalOpen(false)} className="text-zinc-400 hover:text-zinc-600">
                <X className="w-5 h-5" />
              </button>
            </div>

            <form onSubmit={handleSaveTemplate} className="space-y-4">
              <div>
                <label className="block text-xs font-semibold uppercase text-zinc-600 mb-1">Template Name</label>
                <input
                  type="text"
                  required
                  placeholder="e.g. Early, Late, Night Shift"
                  value={templateForm.name}
                  onChange={(e) => setTemplateForm({ ...templateForm, name: e.target.value })}
                  className="w-full bg-zinc-50 border border-zinc-200 rounded-xl px-3 py-2 text-xs text-zinc-900 outline-none focus:border-[#2B7A72]"
                />
              </div>

              <div className="grid grid-cols-2 gap-3">
                <div>
                  <label className="block text-xs font-semibold uppercase text-zinc-600 mb-1">Start Time</label>
                  <input
                    type="time"
                    required
                    value={templateForm.start_time}
                    onChange={(e) => setTemplateForm({ ...templateForm, start_time: e.target.value })}
                    className="w-full bg-zinc-50 border border-zinc-200 rounded-xl px-3 py-2 text-xs text-zinc-900 font-mono outline-none focus:border-[#2B7A72]"
                  />
                </div>
                <div>
                  <label className="block text-xs font-semibold uppercase text-zinc-600 mb-1">End Time</label>
                  <input
                    type="time"
                    required
                    value={templateForm.end_time}
                    onChange={(e) => setTemplateForm({ ...templateForm, end_time: e.target.value })}
                    className="w-full bg-zinc-50 border border-zinc-200 rounded-xl px-3 py-2 text-xs text-zinc-900 font-mono outline-none focus:border-[#2B7A72]"
                  />
                </div>
              </div>

              <div>
                <label className="block text-xs font-semibold uppercase text-zinc-600 mb-1">Badge Color</label>
                <input
                  type="color"
                  value={templateForm.color}
                  onChange={(e) => setTemplateForm({ ...templateForm, color: e.target.value })}
                  className="w-full h-10 bg-zinc-50 border border-zinc-200 rounded-xl px-2 py-1 cursor-pointer"
                />
              </div>

              <div className="pt-2 flex justify-end gap-3">
                <button
                  type="button"
                  onClick={() => setIsTemplateModalOpen(false)}
                  className="px-4 py-2 bg-zinc-100 hover:bg-zinc-200 text-zinc-700 rounded-xl text-xs font-semibold"
                >
                  Cancel
                </button>
                <button
                  type="submit"
                  className="px-5 py-2 bg-[#2B7A72] hover:bg-[#1D5E57] text-white rounded-xl text-xs font-semibold shadow-xs"
                >
                  Create Template
                </button>
              </div>
            </form>
          </div>
        </div>
      )}

      {/* AI Rota Import Modal */}
      <ImportRotaModal
        isOpen={isImportOpen}
        onClose={() => setIsImportOpen(false)}
        onSuccess={() => {
          loadPersonalData();
          loadCircleAvailability(true);
        }}
      />
    </div>
  );
}
