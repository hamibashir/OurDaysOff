"use client";

import { useState } from "react";
import { Circle } from "@/types/api";
import { apiClient } from "@/lib/api-client";
import { sessionCache } from "@/lib/session-cache";
import { X, Sparkles, Calendar, Clock, MapPin, Users, Loader2 } from "lucide-react";

interface CreatePlanModalProps {
  isOpen: boolean;
  onClose: () => void;
  onSuccess: () => void;
  circles: Circle[];
  selectedCircleId: number | null;
  initialDate: string;
  initialStartTime: string;
  initialEndTime: string;
}

export function CreatePlanModal({
  isOpen,
  onClose,
  onSuccess,
  circles,
  selectedCircleId,
  initialDate,
  initialStartTime,
  initialEndTime,
}: CreatePlanModalProps) {
  const [title, setTitle] = useState("Group Meetup");
  const [description, setDescription] = useState("");
  const [circleId, setCircleId] = useState<number>(
    selectedCircleId || (circles.length > 0 ? circles[0].id : 0)
  );
  const [eventType, setEventType] = useState<"social" | "meal" | "travel" | "other">("social");
  const [date, setDate] = useState(initialDate);
  const [startTime, setStartTime] = useState(initialStartTime || "18:00");
  const [endTime, setEndTime] = useState(initialEndTime || "21:00");
  const [locationName, setLocationName] = useState("");
  const [isSubmitting, setIsSubmitting] = useState(false);
  const [errorMsg, setErrorMsg] = useState<string | null>(null);

  if (!isOpen) return null;

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!circleId) {
      setErrorMsg("Please select a circle for this plan.");
      return;
    }

    setIsSubmitting(true);
    setErrorMsg(null);

    try {
      const startAt = `${date} ${startTime}:00`;
      const endAt = `${date} ${endTime}:00`;

      const res = await apiClient.post<{ data: { id: number } }>("/plans", {
        circle_id: circleId,
        title,
        description: description || null,
        event_type: eventType,
        start_at: startAt,
        end_at: endAt,
        status: "confirmed",
      });

      // If user specified location, submit initial location option
      if (locationName && res.data?.id) {
        try {
          await apiClient.post(`/plans/${res.data.id}/locations`, {
            name: locationName,
          });
        } catch (e) {
          // ignore location error
        }
      }

      sessionCache.invalidate(/^circle_availability/);
      sessionCache.invalidate(/^compare_/);
      sessionCache.invalidate("plans");
      onSuccess();
      onClose();
    } catch (err: any) {
      setErrorMsg(err.message || "Failed to create plan.");
    } finally {
      setIsSubmitting(false);
    }
  };

  return (
    <div className="fixed inset-0 bg-zinc-950/50 backdrop-blur-xs z-50 flex items-center justify-center p-4">
      <div className="bg-white border border-zinc-200 rounded-2xl max-w-lg w-full p-6 shadow-xl space-y-4">
        <div className="flex items-center justify-between pb-3 border-b border-zinc-200">
          <div className="flex items-center gap-2">
            <div className="w-8 h-8 rounded-lg bg-[#81D8D0]/20 border border-[#81D8D0]/40 flex items-center justify-center">
              <Sparkles className="w-4 h-4 text-[#1D5E57]" />
            </div>
            <div>
              <h3 className="font-bold text-zinc-900 text-base">Plan Meetup From Overlap</h3>
              <p className="text-[11px] text-zinc-500">Prefilled with the mutual free window</p>
            </div>
          </div>
          <button onClick={onClose} className="text-zinc-400 hover:text-zinc-600">
            <X className="w-5 h-5" />
          </button>
        </div>

        {errorMsg && (
          <div className="p-3 bg-red-50 border border-red-200 rounded-xl text-xs text-red-700">
            {errorMsg}
          </div>
        )}

        <form onSubmit={handleSubmit} className="space-y-4 text-xs">
          <div>
            <label className="block font-semibold uppercase text-zinc-600 mb-1">Plan Title</label>
            <input
              type="text"
              required
              placeholder="e.g. Dinner Catchup, Team Social"
              value={title}
              onChange={(e) => setTitle(e.target.value)}
              className="w-full bg-zinc-50 border border-zinc-200 rounded-xl px-3 py-2 text-xs text-zinc-900 outline-none focus:border-[#2B7A72]"
            />
          </div>

          <div className="grid grid-cols-2 gap-3">
            <div>
              <label className="block font-semibold uppercase text-zinc-600 mb-1">Target Circle</label>
              <select
                value={circleId}
                onChange={(e) => setCircleId(Number(e.target.value))}
                className="w-full bg-zinc-50 border border-zinc-200 rounded-xl px-3 py-2 text-xs text-zinc-900 outline-none focus:border-[#2B7A72]"
              >
                {circles.map((c) => (
                  <option key={c.id} value={c.id}>
                    {c.name}
                  </option>
                ))}
              </select>
            </div>
            <div>
              <label className="block font-semibold uppercase text-zinc-600 mb-1">Event Type</label>
              <select
                value={eventType}
                onChange={(e) => setEventType(e.target.value as any)}
                className="w-full bg-zinc-50 border border-zinc-200 rounded-xl px-3 py-2 text-xs text-zinc-900 outline-none focus:border-[#2B7A72]"
              >
                <option value="social">Social Hangout</option>
                <option value="meal">Food & Drinks</option>
                <option value="travel">Trip / Travel</option>
                <option value="other">Other Activity</option>
              </select>
            </div>
          </div>

          <div className="grid grid-cols-3 gap-3">
            <div>
              <label className="block font-semibold uppercase text-zinc-600 mb-1">Date</label>
              <input
                type="date"
                required
                value={date}
                onChange={(e) => setDate(e.target.value)}
                className="w-full bg-zinc-50 border border-zinc-200 rounded-xl px-2.5 py-2 text-xs text-zinc-900 font-mono outline-none focus:border-[#2B7A72]"
              />
            </div>
            <div>
              <label className="block font-semibold uppercase text-zinc-600 mb-1">Start Time</label>
              <input
                type="time"
                required
                value={startTime}
                onChange={(e) => setStartTime(e.target.value)}
                className="w-full bg-zinc-50 border border-zinc-200 rounded-xl px-2.5 py-2 text-xs text-zinc-900 font-mono outline-none focus:border-[#2B7A72]"
              />
            </div>
            <div>
              <label className="block font-semibold uppercase text-zinc-600 mb-1">End Time</label>
              <input
                type="time"
                required
                value={endTime}
                onChange={(e) => setEndTime(e.target.value)}
                className="w-full bg-zinc-50 border border-zinc-200 rounded-xl px-2.5 py-2 text-xs text-zinc-900 font-mono outline-none focus:border-[#2B7A72]"
              />
            </div>
          </div>

          <div>
            <label className="block font-semibold uppercase text-zinc-600 mb-1">
              Suggested Venue / Location (Optional)
            </label>
            <input
              type="text"
              placeholder="e.g. Dishoom Shoreditch, Central Park"
              value={locationName}
              onChange={(e) => setLocationName(e.target.value)}
              className="w-full bg-zinc-50 border border-zinc-200 rounded-xl px-3 py-2 text-xs text-zinc-900 outline-none focus:border-[#2B7A72]"
            />
          </div>

          <div>
            <label className="block font-semibold uppercase text-zinc-600 mb-1">Description / Notes</label>
            <textarea
              rows={2}
              placeholder="Add meetup details, agenda, or directions..."
              value={description}
              onChange={(e) => setDescription(e.target.value)}
              className="w-full bg-zinc-50 border border-zinc-200 rounded-xl px-3 py-2 text-xs text-zinc-900 outline-none focus:border-[#2B7A72]"
            />
          </div>

          <div className="pt-2 flex justify-end gap-3">
            <button
              type="button"
              onClick={onClose}
              className="px-4 py-2 bg-zinc-100 hover:bg-zinc-200 text-zinc-700 rounded-xl text-xs font-semibold"
            >
              Cancel
            </button>
            <button
              type="submit"
              disabled={isSubmitting}
              className="px-5 py-2 bg-[#2B7A72] hover:bg-[#1D5E57] text-white rounded-xl text-xs font-semibold shadow-xs flex items-center gap-1.5"
            >
              {isSubmitting ? (
                <Loader2 className="w-4 h-4 animate-spin text-white" />
              ) : (
                <Sparkles className="w-4 h-4 text-[#D7D982]" />
              )}
              Create & Invite Circle
            </button>
          </div>
        </form>
      </div>
    </div>
  );
}
