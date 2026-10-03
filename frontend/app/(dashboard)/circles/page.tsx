"use client";

import { useEffect, useState } from "react";
import { Circle } from "@/types/api";
import { apiClient } from "@/lib/api-client";
import { CircleList } from "@/features/circles/components/circle-list";
import { CreateCircleModal } from "@/features/circles/components/create-circle-modal";
import { JoinCircleModal } from "@/features/circles/components/join-circle-modal";
import { sessionCache } from "@/lib/session-cache";

const CIRCLES_CACHE_KEY = "user_circles";

export default function CirclesPage() {
  const cachedCircles = sessionCache.get<Circle[]>(CIRCLES_CACHE_KEY);

  const [circles, setCircles] = useState<Circle[]>(cachedCircles || []);
  const [isLoading, setIsLoading] = useState(!cachedCircles);
  const [isCreateOpen, setIsCreateOpen] = useState(false);
  const [isJoinOpen, setIsJoinOpen] = useState(false);

  const loadCircles = async (forceRefetch = false) => {
    if (forceRefetch || !sessionCache.has(CIRCLES_CACHE_KEY)) {
      if (!sessionCache.has(CIRCLES_CACHE_KEY)) setIsLoading(true);
      try {
        const res = await apiClient.get<{ data: Circle[] }>("/circles");
        const list = res.data || [];
        setCircles(list);
        sessionCache.set(CIRCLES_CACHE_KEY, list);
      } catch (err) {
        console.error("Failed to load circles", err);
      } finally {
        setIsLoading(false);
      }
    }
  };

  useEffect(() => {
    if (!sessionCache.has(CIRCLES_CACHE_KEY)) {
      loadCircles(true);
    }
  }, []);

  const handleSuccess = () => {
    sessionCache.invalidate(CIRCLES_CACHE_KEY);
    sessionCache.invalidate("dashboard_overview");
    loadCircles(true);
  };

  return (
    <div className="max-w-6xl mx-auto space-y-6">
      <CircleList
        circles={circles}
        onCreateClick={() => setIsCreateOpen(true)}
        onJoinClick={() => setIsJoinOpen(true)}
        isLoading={isLoading}
      />

      {isCreateOpen && (
        <CreateCircleModal
          isOpen={isCreateOpen}
          onClose={() => setIsCreateOpen(false)}
          onSuccess={handleSuccess}
        />
      )}

      {isJoinOpen && (
        <JoinCircleModal
          isOpen={isJoinOpen}
          onClose={() => setIsJoinOpen(false)}
          onSuccess={handleSuccess}
        />
      )}
    </div>
  );
}
