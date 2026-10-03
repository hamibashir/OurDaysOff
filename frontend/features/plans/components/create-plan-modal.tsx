"use client";

import { useState } from "react";
import { X, CalendarCheck, MapPin, Clock } from "lucide-react";
import { apiClient } from "@/lib/api-client";
import { Circle } from "@/types/api";

interface CreatePlanModalProps {
  circles: Circle[];
  initialDate?: string;
  initialStart?: string;
  initialEnd?: string;
  isOpen: boolean;
  onClose: () => void;
  onSuccess: () => void;
}

export function CreatePlanModal({
  circles,
  initialDate = "",
  initialStart = "18:00",
  initialEnd = "21:00",
  isOpen,
  onClose,
  onSuccess,
}: CreatePlanModalProps) {
  const [circleId, setCircleId] = useState<number>(circles[0]?.id || 0);
  const [title, setTitle] = useState("");
  const [description, setDescription] = useState("");
  const [eventType, setEventType] = useState<"social" | "meal" | "travel" | "other">("meal");
  const [date, setDate] = useState(initialDate || new Date().toISOString().slice(0, 10));
  const [startTime, setStartTime] = useState(initialStart);
  const [endTime, setEndTime] = useState(initialEnd);

  const [isSubmitting, setIsSubmitting] = useState(false);
  const [error, setError] = useState<string | null>(null);

  if (!isOpen) return null;

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    setError(null);
    setIsSubmitting(true);

    try {
      const startAt = `${date} ${startTime}:00`;
      const endAt = `${date} ${endTime}:00`;

      await apiClient.post("/plans", {
        circle_id: circleId || circles[0]?.id,
        title,
        description,
        event_type: eventType,
        start_at: startAt,
        end_at: endAt,
        status: "confirmed",
      });

      onSuccess();
      onClose();
    } catch (err: any) {
      setError(err.message || "Failed to create plan.");
    } finally {
      setIsSubmitting(false);
    }
  };

  return (
    <div className="fixed inset-0 bg-slate-900/40 backdrop-blur-xs z-50 flex items-center justify-center p-4">
      <div className="bg-white border border-[#E8E5DF] rounded-2xl max-w-md w-full p-6 shadow-xl space-y-4">
        <div className="flex items-center justify-between pb-3 border-b border-[#E8E5DF]">
          <h3 className="font-bold text-[#1F2223] text-base flex items-center gap-2">
            <CalendarCheck className="w-5 h-5 text-[#2B7A72]" />
            Create Meetup Plan
          </h3>
          <button onClick={onClose} className="text-[#959A9E] hover:text-[#1F2223]">
            <X className="w-5 h-5" />
          </button>
        </div>

        {error && (
          <div className="p-3 rounded-xl bg-rose-50 border border-rose-200 text-rose-700 text-xs font-medium">
            {error}
          </div>
        )}

        <form onSubmit={handleSubmit} className="space-y-4">
          <div>
            <label className="block text-[11px] font-bold uppercase tracking-wider text-[#656A6D] mb-1">Target Circle</label>
            <select
              value={circleId}
              onChange={(e) => setCircleId(Number(e.target.value))}
              className="w-full bg-[#FAF9F6] border border-[#E8E5DF] focus:border-[#81D8D0] rounded-xl px-3.5 py-2.5 text-xs text-[#1F2223] outline-none cursor-pointer font-semibold"
            >
              {circles.map((c) => (
                <option key={c.id} value={c.id}>
                  {c.name}
                </option>
              ))}
            </select>
          </div>

          <div>
            <label className="block text-[11px] font-bold uppercase tracking-wider text-[#656A6D] mb-1">Plan Title</label>
            <input
              type="text"
              required
              placeholder="e.g. Dinner & Board Games, Weekend Trip"
              value={title}
              onChange={(e) => setTitle(e.target.value)}
              className="w-full bg-[#FAF9F6] border border-[#E8E5DF] focus:border-[#81D8D0] rounded-xl px-3.5 py-2.5 text-xs text-[#1F2223] outline-none font-medium"
            />
          </div>

          <div className="grid grid-cols-2 gap-3">
            <div>
              <label className="block text-[11px] font-bold uppercase tracking-wider text-[#656A6D] mb-1">Event Category</label>
              <select
                value={eventType}
                onChange={(e) => setEventType(e.target.value as any)}
                className="w-full bg-[#FAF9F6] border border-[#E8E5DF] focus:border-[#81D8D0] rounded-xl px-3 py-2 text-xs text-[#1F2223] outline-none cursor-pointer"
              >
                <option value="meal">Meal / Dinner</option>
                <option value="social">Social Hangout</option>
                <option value="travel">Travel / Outdoor</option>
                <option value="other">Other</option>
              </select>
            </div>
            <div>
              <label className="block text-[11px] font-bold uppercase tracking-wider text-[#656A6D] mb-1">Date</label>
              <input
                type="date"
                required
                value={date}
                onChange={(e) => setDate(e.target.value)}
                className="w-full bg-[#FAF9F6] border border-[#E8E5DF] focus:border-[#81D8D0] rounded-xl px-3 py-2 text-xs text-[#1F2223] font-mono outline-none"
              />
            </div>
          </div>

          <div className="grid grid-cols-2 gap-3">
            <div>
              <label className="block text-[11px] font-bold uppercase tracking-wider text-[#656A6D] mb-1">Start Time</label>
              <input
                type="time"
                required
                value={startTime}
                onChange={(e) => setStartTime(e.target.value)}
                className="w-full bg-[#FAF9F6] border border-[#E8E5DF] focus:border-[#81D8D0] rounded-xl px-3 py-2 text-xs text-[#1F2223] font-mono outline-none"
              />
            </div>
            <div>
              <label className="block text-[11px] font-bold uppercase tracking-wider text-[#656A6D] mb-1">End Time</label>
              <input
                type="time"
                required
                value={endTime}
                onChange={(e) => setEndTime(e.target.value)}
                className="w-full bg-[#FAF9F6] border border-[#E8E5DF] focus:border-[#81D8D0] rounded-xl px-3 py-2 text-xs text-[#1F2223] font-mono outline-none"
              />
            </div>
          </div>

          <div>
            <label className="block text-[11px] font-bold uppercase tracking-wider text-[#656A6D] mb-1">Description & Notes</label>
            <textarea
              rows={2}
              placeholder="Optional plan details..."
              value={description}
              onChange={(e) => setDescription(e.target.value)}
              className="w-full bg-[#FAF9F6] border border-[#E8E5DF] focus:border-[#81D8D0] rounded-xl px-3.5 py-2 text-xs text-[#1F2223] outline-none"
            />
          </div>

          <div className="pt-2 flex justify-end gap-2.5">
            <button
              type="button"
              onClick={onClose}
              className="px-4 py-2 bg-[#FAF9F6] hover:bg-[#F2EFE9] text-[#1F2223] border border-[#E8E5DF] rounded-xl text-xs font-semibold"
            >
              Cancel
            </button>
            <button
              type="submit"
              disabled={isSubmitting}
              className="px-4 py-2 bg-[#2B7A72] hover:bg-[#1D5E57] text-white rounded-xl text-xs font-semibold shadow-xs disabled:opacity-50"
            >
              {isSubmitting ? "Creating..." : "Create & Send RSVPs"}
            </button>
          </div>
        </form>
      </div>
    </div>
  );
}
