"use client";

import { useEffect, useState } from "react";
import { ActivityEvent } from "@/types/api";
import { apiClient } from "@/lib/api-client";
import { Activity, UserCheck, CalendarCheck, MapPin, ThumbsUp } from "lucide-react";

interface CircleActivityFeedProps {
  circleId: number;
}

export function CircleActivityFeed({ circleId }: CircleActivityFeedProps) {
  const [events, setEvents] = useState<ActivityEvent[]>([]);
  const [isLoading, setIsLoading] = useState(true);

  useEffect(() => {
    async function loadFeed() {
      try {
        const res = await apiClient.get<{ data: ActivityEvent[] }>(`/circles/${circleId}/activity`);
        setEvents(res.data);
      } catch (err) {
        console.error("Failed to load activity feed", err);
      } finally {
        setIsLoading(false);
      }
    }
    if (circleId) loadFeed();
  }, [circleId]);

  if (isLoading) {
    return <div className="text-xs text-slate-500 py-4 text-center">Loading activity feed...</div>;
  }

  const getEventIcon = (type: string) => {
    switch (type) {
      case "plan_created":
        return <CalendarCheck className="w-3.5 h-3.5 text-emerald-400" />;
      case "location_added":
        return <MapPin className="w-3.5 h-3.5 text-indigo-400" />;
      case "location_vote":
        return <ThumbsUp className="w-3.5 h-3.5 text-amber-400" />;
      default:
        return <Activity className="w-3.5 h-3.5 text-slate-400" />;
    }
  };

  return (
    <div className="bg-[#141a25] border border-slate-800 rounded-xl p-5 space-y-4">
      <h4 className="text-xs font-bold text-white uppercase tracking-wider flex items-center gap-2 pb-2 border-b border-slate-800">
        <Activity className="w-4 h-4 text-indigo-400" />
        Circle Activity Feed
      </h4>

      <div className="space-y-3 max-h-[300px] overflow-y-auto pr-1">
        {events.map((e) => (
          <div key={e.id} className="flex items-start gap-2.5 text-xs">
            <div className="p-1 rounded bg-[#0b0f17] border border-slate-800 shrink-0 mt-0.5">
              {getEventIcon(e.event_type)}
            </div>
            <div className="flex-1 min-w-0">
              <p className="text-slate-200 leading-snug">
                <strong className="text-white">{e.actor?.name || "Member"}</strong>{" "}
                {e.event_type.replace("_", " ")}
                {e.metadata?.title ? `: "${e.metadata.title}"` : ""}
              </p>
              <span className="text-[10px] text-slate-500 font-mono">
                {new Date(e.created_at).toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' })}
              </span>
            </div>
          </div>
        ))}

        {events.length === 0 && (
          <p className="text-xs text-slate-500 italic py-2">No recent activity recorded for this circle.</p>
        )}
      </div>
    </div>
  );
}
