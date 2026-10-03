"use client";

import { useEffect, useState, use } from "react";
import { Circle } from "@/types/api";
import { apiClient } from "@/lib/api-client";
import { MemberManagement } from "@/features/circles/components/member-management";
import { InviteModal } from "@/features/circles/components/invite-modal";
import { Users, KeyRound, ArrowLeft, ShieldCheck, Sliders, Sparkles } from "lucide-react";
import Link from "next/link";
import { sessionCache } from "@/lib/session-cache";

import { useRouter } from "next/navigation";

export default function CircleDetailPage({ params }: { params: Promise<{ id: string }> }) {
  const { id } = use(params);
  const router = useRouter();
  const circleId = parseInt(id, 10);
  const cacheKey = `circle_detail_${circleId}`;

  const cachedCircle = isNaN(circleId) ? null : sessionCache.get<Circle>(cacheKey);

  const [circle, setCircle] = useState<Circle | null>(cachedCircle);
  const [isLoading, setIsLoading] = useState(!cachedCircle);
  const [isInviteOpen, setIsInviteOpen] = useState(false);

  const loadCircle = async (forceRefetch = false) => {
    if (isNaN(circleId)) return;
    if (forceRefetch || !sessionCache.has(cacheKey)) {
      if (!sessionCache.has(cacheKey)) setIsLoading(true);
      try {
        const res = await apiClient.get<{ data: Circle }>(`/circles/${circleId}`);
        setCircle(res.data);
        sessionCache.set(cacheKey, res.data);
      } catch (err) {
        console.error("Failed to load circle detail", err);
      } finally {
        setIsLoading(false);
      }
    }
  };

  useEffect(() => {
    if (isNaN(circleId)) {
      router.replace("/circles");
      return;
    }

    if (circleId) {
      if (!sessionCache.has(cacheKey)) {
        loadCircle(true);
      }
    }
  }, [circleId, router]);

  const handleMemberUpdated = () => {
    sessionCache.invalidate(cacheKey);
    sessionCache.invalidate("user_circles");
    loadCircle(true);
  };

  return (
    <div className="max-w-6xl mx-auto space-y-6 md:space-y-8">
      {/* Back Link & Action Bar */}
      <div className="flex items-center justify-between">
        <Link href="/circles" className="text-xs text-[#656A6D] hover:text-[#1F2223] flex items-center gap-1.5 transition-colors font-medium">
          <ArrowLeft className="w-3.5 h-3.5" /> Back to Circles
        </Link>

        <div className="flex items-center gap-3">
          <button
            onClick={() => setIsInviteOpen(true)}
            className="px-3.5 py-2 bg-[#2B7A72] hover:bg-[#1D5E57] text-white rounded-xl text-xs font-semibold transition-all shadow-xs flex items-center gap-1.5"
          >
            <KeyRound className="w-3.5 h-3.5 text-[#D7D982]" /> Invite Members
          </button>
        </div>
      </div>

      {/* Circle Header Info Card */}
      <div className="bg-white border border-[#E8E5DF] rounded-2xl p-5 md:p-6 flex flex-col md:flex-row md:items-center justify-between gap-6 shadow-xs">
        <div>
          <div className="flex items-center gap-2 mb-2.5">
            <span className="text-[10px] font-bold uppercase tracking-wider px-2.5 py-0.5 rounded-full bg-[#81D8D0]/18 border border-[#81D8D0]/40 text-[#1D5E57]">
              Role: {circle?.my_role || "Member"}
            </span>
            <span className="text-[10px] font-bold uppercase tracking-wider px-2.5 py-0.5 rounded-full bg-[#D7D982]/25 border border-[#D7D982]/50 text-[#5C5E1A]">
              Visibility: {circle?.my_visibility || "Free/Busy Only"}
            </span>
          </div>
          <h1 className="text-2xl font-bold text-[#1F2223] tracking-tight flex items-center gap-2">
            {circle?.name || "Circle Details"}
          </h1>
          {circle?.handle && <p className="text-xs text-[#656A6D] font-mono mt-0.5">@{circle.handle}</p>}
        </div>

        <div className="flex items-center gap-3 shrink-0">
          <Link
            href={`/compare?circle=${circleId}`}
            className="px-4 py-2.5 bg-[#81D8D0]/20 hover:bg-[#81D8D0]/30 text-[#1D5E57] border border-[#81D8D0]/50 rounded-xl text-xs font-bold transition-all flex items-center gap-2 shadow-xs"
          >
            <Sliders className="w-4 h-4 text-[#2B7A72]" />
            Compare Off Days with Circle
          </Link>
        </div>
      </div>

      {/* Member Roster & Privacy Config */}
      <MemberManagement
        circleId={circleId}
        members={(circle as any)?.members || []}
        myRole={circle?.my_role || "member"}
        onMemberUpdated={handleMemberUpdated}
        isLoading={isLoading}
      />

      {isInviteOpen && (
        <InviteModal
          circleId={circle?.id || circleId}
          isOpen={isInviteOpen}
          onClose={() => setIsInviteOpen(false)}
        />
      )}
    </div>
  );
}
