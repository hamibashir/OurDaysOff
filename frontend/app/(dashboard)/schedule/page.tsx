"use client";

import { useEffect, useState } from "react";
import { ScheduleEntry, ShiftTemplate } from "@/types/api";
import { apiClient } from "@/lib/api-client";
import { ScheduleCalendar } from "@/features/schedule/components/schedule-calendar";
import { DayView } from "@/features/schedule/components/day-view";
import { ShiftTemplatePicker } from "@/features/schedule/components/shift-template-picker";
import { AvailabilityPreview } from "@/features/availability/components/availability-preview";
import { ImportRotaModal } from "@/features/schedule/components/import-rota-modal";
import { Clock, Plus, Calendar as CalendarIcon, Sparkles, X, Check, Upload, ShieldCheck } from "lucide-react";

import { sessionCache } from "@/lib/session-cache";

interface ScheduleCacheData {
  entries: ScheduleEntry[];
  templates: ShiftTemplate[];
}

export default function SchedulePage() {
  const [currentDate, setCurrentDate] = useState(new Date());

  const year = currentDate.getFullYear();
  const month = currentDate.getMonth();
  const cacheKey = `schedule_${year}_${month}`;

  const cachedData = sessionCache.get<ScheduleCacheData>(cacheKey);

  const [entries, setEntries] = useState<ScheduleEntry[]>(cachedData?.entries || []);
  const [templates, setTemplates] = useState<ShiftTemplate[]>(cachedData?.templates || []);
  const [selectedDate, setSelectedDate] = useState<string>(
    new Date().toISOString().slice(0, 10)
  );
  const [selectedTemplate, setSelectedTemplate] = useState<ShiftTemplate | null>(null);
  const [isLoading, setIsLoading] = useState(!cachedData);

  // Modals
  const [isShiftModalOpen, setIsShiftModalOpen] = useState(false);
  const [isTemplateModalOpen, setIsTemplateModalOpen] = useState(false);
  const [isImportOpen, setIsImportOpen] = useState(false);

  // Form states
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

  const loadScheduleData = async (forceRefetch = false) => {
    if (forceRefetch || !sessionCache.has(cacheKey)) {
      if (!sessionCache.has(cacheKey)) setIsLoading(true);
      try {
        const monthStr = String(month + 1).padStart(2, "0");
        const startDate = `${year}-${monthStr}-01`;
        const lastDay = new Date(year, month + 1, 0).getDate();
        const endDate = `${year}-${monthStr}-${String(lastDay).padStart(2, "0")}`;

        const [schedulesRes, templatesRes] = await Promise.all([
          apiClient.get<{ data: ScheduleEntry[] }>(`/schedules?start_date=${startDate}&end_date=${endDate}`),
          apiClient.get<{ data: ShiftTemplate[] }>("/shift-templates"),
        ]);

        const fetchedEntries = schedulesRes.data || [];
        const fetchedTemplates = templatesRes.data || [];

        setEntries(fetchedEntries);
        setTemplates(fetchedTemplates);

        sessionCache.set(cacheKey, {
          entries: fetchedEntries,
          templates: fetchedTemplates,
        });
      } catch (err) {
        console.error("Failed to load schedule data", err);
      } finally {
        setIsLoading(false);
      }
    }
  };

  useEffect(() => {
    const cached = sessionCache.get<ScheduleCacheData>(cacheKey);
    if (cached) {
      setEntries(cached.entries);
      setTemplates(cached.templates);
      setIsLoading(false);
    } else {
      loadScheduleData(true);
    }
  }, [currentDate]);

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

    // If template selected, quick-assign template to clicked date!
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
        sessionCache.invalidate(/^schedule_/);
        sessionCache.invalidate("dashboard_overview");
        await loadScheduleData(true);
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
      sessionCache.invalidate(/^schedule_/);
      sessionCache.invalidate("dashboard_overview");
      await loadScheduleData(true);
    } catch (err: any) {
      alert(err.message || "Failed to save schedule entry.");
    }
  };

  const handleSaveTemplate = async (e: React.FormEvent) => {
    e.preventDefault();
    try {
      await apiClient.post("/shift-templates", templateForm);
      setIsTemplateModalOpen(false);
      setTemplateForm({ name: "", start_time: "07:00", end_time: "15:00", color: "#3b82f6" });
      sessionCache.invalidate(/^schedule_/);
      await loadScheduleData(true);
    } catch (err: any) {
      alert(err.message || "Failed to create template.");
    }
  };

  const handleDeleteShift = async () => {
    const activeEntry = entries.find((e) => e.date === selectedDate);
    if (!activeEntry) return;

    if (confirm("Are you sure you want to remove this shift?")) {
      try {
        await apiClient.delete(`/schedules/${activeEntry.id}`);
        sessionCache.invalidate(/^schedule_/);
        sessionCache.invalidate("dashboard_overview");
        await loadScheduleData(true);
      } catch (err) {
        console.error("Failed to delete entry", err);
      }
    }
  };

  const selectedEntry = entries.find((e) => e.date === selectedDate) || null;

  return (
    <div className="max-w-6xl mx-auto space-y-6 md:space-y-8">
      {/* Top Header Controls */}
      <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-4 bg-white border border-[#E8E5DF] rounded-2xl p-5 md:p-6 shadow-xs">
        <div className="flex items-start gap-3.5">
          <div className="w-10 h-10 rounded-xl bg-[#81D8D0]/20 border border-[#81D8D0]/40 flex items-center justify-center shrink-0 mt-0.5 shadow-xs">
            <Clock className="w-5 h-5 text-[#1D5E57]" />
          </div>
          <div>
            <div className="flex items-center gap-2">
              <h1 className="text-xl font-bold text-[#1F2223] tracking-tight">
                My Personal Schedule
              </h1>
              <span className="inline-flex items-center gap-1 px-2 py-0.5 rounded-full bg-[#81D8D0]/20 text-[#1D5E57] text-[10px] font-mono font-semibold">
                <ShieldCheck className="w-3 h-3 text-[#2B7A72]" /> Private
              </span>
            </div>
            <p className="text-xs text-[#656A6D] mt-1 leading-relaxed">
              Tap any date to inspect details or activate 1-tap quick assign. Raw shift titles remain completely confidential.
            </p>
          </div>
        </div>

        <div className="flex items-center gap-2.5 shrink-0">
          <button
            onClick={() => setIsImportOpen(true)}
            className="px-3.5 py-2.5 bg-[#FAF9F6] hover:bg-[#F2EFE9] text-[#1F2223] border border-[#E8E5DF] rounded-xl text-xs font-semibold transition-all flex items-center gap-1.5 shadow-xs"
          >
            <Upload className="w-3.5 h-3.5 text-[#2B7A72]" />
            Add / Import Rota
          </button>
          <button
            onClick={() => setIsShiftModalOpen(true)}
            className="px-4 py-2.5 bg-[#2B7A72] hover:bg-[#1D5E57] text-white rounded-xl text-xs font-semibold transition-all shadow-xs flex items-center gap-1.5"
          >
            <Plus className="w-4 h-4 text-[#D7D982]" />
            Add Shift Entry
          </button>
        </div>
      </div>

      {/* Shift Templates Picker Bar */}
      <div className="bg-white border border-[#E8E5DF] rounded-2xl p-5 shadow-xs">
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
              1-Tap Quick Assign active for: <strong className="font-bold">{selectedTemplate.name}</strong> ({selectedTemplate.start_time.slice(0, 5)} - {selectedTemplate.end_time.slice(0, 5)}). Click dates on calendar to apply!
            </span>
            <button
              onClick={() => setSelectedTemplate(null)}
              className="text-[11px] font-semibold text-[#1D5E57] underline hover:text-[#154540] shrink-0"
            >
              Cancel Quick Assign
            </button>
          </div>
        )}
      </div>

      {/* Main Grid: Calendar (Left 2/3) + Day View (Right 1/3) */}
      <div className="grid grid-cols-1 lg:grid-cols-3 gap-6">
        <div className="lg:col-span-2">
          <ScheduleCalendar
            entries={entries}
            currentDate={currentDate}
            onNavigateMonth={handleNavigateMonth}
            onSelectDate={handleDateClick}
            selectedDate={selectedDate}
            isLoading={isLoading}
          />
        </div>

        <div>
          <DayView
            dateStr={selectedDate}
            entry={selectedEntry}
            onEdit={() => {
              if (selectedEntry) {
                setShiftForm({
                  date: selectedEntry.date,
                  start_time: selectedEntry.start_time.slice(0, 5),
                  end_time: selectedEntry.end_time.slice(0, 5),
                  entry_type: selectedEntry.entry_type,
                  label: selectedEntry.label || "",
                  notes: selectedEntry.notes || "",
                  is_overnight: selectedEntry.is_overnight,
                });
                setIsShiftModalOpen(true);
              }
            }}
            onDelete={handleDeleteShift}
          />
        </div>
      </div>

      {/* Availability Engine Preview */}
      <AvailabilityPreview
        startDate={`${currentDate.getFullYear()}-${String(currentDate.getMonth() + 1).padStart(2, "0")}-01`}
        endDate={`${currentDate.getFullYear()}-${String(currentDate.getMonth() + 1).padStart(2, "0")}-${String(new Date(currentDate.getFullYear(), currentDate.getMonth() + 1, 0).getDate()).padStart(2, "0")}`}
      />

      {/* Shift Entry Modal */}
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
                  placeholder="e.g. Early Shift, Night Duty"
                  value={shiftForm.label}
                  onChange={(e) => setShiftForm({ ...shiftForm, label: e.target.value })}
                  className="w-full bg-zinc-50 border border-zinc-200 rounded-xl px-3 py-2 text-xs text-zinc-900 outline-none focus:border-indigo-600"
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
                    className="w-full bg-zinc-50 border border-zinc-200 rounded-xl px-3 py-2 text-xs text-zinc-900 outline-none focus:border-indigo-600 font-mono"
                  />
                </div>
                <div>
                  <label className="block text-xs font-semibold uppercase text-zinc-600 mb-1">End Time</label>
                  <input
                    type="time"
                    required
                    value={shiftForm.end_time}
                    onChange={(e) => setShiftForm({ ...shiftForm, end_time: e.target.value })}
                    className="w-full bg-zinc-50 border border-zinc-200 rounded-xl px-3 py-2 text-xs text-zinc-900 outline-none focus:border-indigo-600 font-mono"
                  />
                </div>
              </div>

              <div>
                <label className="block text-xs font-semibold uppercase text-zinc-600 mb-1">Entry Type</label>
                <select
                  value={shiftForm.entry_type}
                  onChange={(e) => setShiftForm({ ...shiftForm, entry_type: e.target.value })}
                  className="w-full bg-zinc-50 border border-zinc-200 rounded-xl px-3 py-2 text-xs text-zinc-900 outline-none focus:border-indigo-600"
                >
                  <option value="work">Work Shift</option>
                  <option value="leave">Leave / Vacation</option>
                  <option value="off">Off Day</option>
                  <option value="personal">Personal Event</option>
                  <option value="other">Other</option>
                </select>
              </div>

              <div>
                <label className="block text-xs font-semibold uppercase text-zinc-600 mb-1">Notes & Directives</label>
                <textarea
                  rows={2}
                  placeholder="Optional shift notes..."
                  value={shiftForm.notes}
                  onChange={(e) => setShiftForm({ ...shiftForm, notes: e.target.value })}
                  className="w-full bg-zinc-50 border border-zinc-200 rounded-xl px-3 py-2 text-xs text-zinc-900 outline-none focus:border-indigo-600"
                />
              </div>

              <div className="pt-2 flex justify-end gap-3">
                <button
                  type="button"
                  onClick={() => setIsShiftModalOpen(false)}
                  className="px-4 py-2 bg-zinc-100 hover:bg-zinc-200 text-zinc-700 rounded-xl text-xs font-medium border border-zinc-200"
                >
                  Cancel
                </button>
                <button
                  type="submit"
                  className="px-4 py-2 bg-indigo-600 hover:bg-indigo-700 text-white rounded-xl text-xs font-medium shadow-xs"
                >
                  Save Shift
                </button>
              </div>
            </form>
          </div>
        </div>
      )}

      {/* Shift Template Creation Modal */}
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
                  placeholder="e.g. Early, Late, Night"
                  value={templateForm.name}
                  onChange={(e) => setTemplateForm({ ...templateForm, name: e.target.value })}
                  className="w-full bg-zinc-50 border border-zinc-200 rounded-xl px-3 py-2 text-xs text-zinc-900 outline-none focus:border-indigo-600"
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
                    className="w-full bg-zinc-50 border border-zinc-200 rounded-xl px-3 py-2 text-xs text-zinc-900 outline-none focus:border-indigo-600 font-mono"
                  />
                </div>
                <div>
                  <label className="block text-xs font-semibold uppercase text-zinc-600 mb-1">End Time</label>
                  <input
                    type="time"
                    required
                    value={templateForm.end_time}
                    onChange={(e) => setTemplateForm({ ...templateForm, end_time: e.target.value })}
                    className="w-full bg-zinc-50 border border-zinc-200 rounded-xl px-3 py-2 text-xs text-zinc-900 outline-none focus:border-indigo-600 font-mono"
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
                  className="px-4 py-2 bg-zinc-100 hover:bg-zinc-200 text-zinc-700 rounded-xl text-xs font-medium border border-zinc-200"
                >
                  Cancel
                </button>
                <button
                  type="submit"
                  className="px-4 py-2 bg-indigo-600 hover:bg-indigo-700 text-white rounded-xl text-xs font-medium shadow-xs"
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
        onSuccess={loadScheduleData}
      />
    </div>
  );
}
