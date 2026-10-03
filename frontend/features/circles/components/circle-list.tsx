"use client";

import Link from "next/link";
import { Circle } from "@/types/api";
import { Users, ShieldCheck, ArrowRight, UserCheck, KeyRound, Plus, Sparkles } from "lucide-react";
import { SkeletonCard } from "@/components/ui/skeleton";

interface CircleListProps {
  circles: Circle[];
  onCreateClick: () => void;
  onJoinClick: () => void;
  isLoading?: boolean;
}

export function CircleList({ circles, onCreateClick, onJoinClick, isLoading = false }: CircleListProps) {
  return (
    <div className="space-y-6 md:space-y-8">
      {/* Top Header Card */}
      <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-4 bg-white border border-[#E8E5DF] rounded-2xl p-5 md:p-6 shadow-xs">
        <div className="flex items-start gap-3.5">
          <div className="w-10 h-10 rounded-xl bg-[#AE82D9]/20 border border-[#AE82D9]/40 flex items-center justify-center shrink-0 mt-0.5 shadow-xs">
            <Users className="w-5 h-5 text-[#6A3E94]" />
          </div>
          <div>
            <div className="flex items-center gap-2">
              <h1 className="text-xl font-bold text-[#1F2223] tracking-tight">
                My Social Circles
              </h1>
              <span className="inline-flex items-center gap-1 px-2 py-0.5 rounded-full bg-[#81D8D0]/20 text-[#1D5E57] text-[10px] font-mono font-semibold">
                <ShieldCheck className="w-3 h-3 text-[#2B7A72]" /> Privacy Shielded
              </span>
            </div>
            <p className="text-xs text-[#656A6D] mt-1 leading-relaxed">
              Create or join private groups for shift-overlap heatmaps and instant meetup planning.
            </p>
          </div>
        </div>

        <div className="flex items-center gap-2.5 shrink-0">
          <button
            onClick={onJoinClick}
            className="px-3.5 py-2.5 bg-[#FAF9F6] hover:bg-[#F2EFE9] text-[#1F2223] border border-[#E8E5DF] rounded-xl text-xs font-semibold transition-all flex items-center gap-1.5 shadow-xs"
          >
            <KeyRound className="w-3.5 h-3.5 text-[#2B7A72]" />
            Join with Code
          </button>
          <button
            onClick={onCreateClick}
            className="px-4 py-2.5 bg-[#2B7A72] hover:bg-[#1D5E57] text-white rounded-xl text-xs font-semibold transition-all shadow-xs flex items-center gap-1.5"
          >
            <Plus className="w-4 h-4 text-[#D7D982]" />
            Create Circle
          </button>
        </div>
      </div>

      {/* Circle Grid */}
      {isLoading ? (
        <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-5">
          {Array.from({ length: 3 }).map((_, i) => (
            <SkeletonCard key={i} />
          ))}
        </div>
      ) : (
      <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-5">
        {circles.map((circle) => (
          <Link
            key={circle.id}
            href={`/circles/${circle.id}`}
            className="bg-white border border-[#E8E5DF] hover:border-[#81D8D0] rounded-2xl p-5 transition-all flex flex-col justify-between group shadow-xs hover:shadow-md"
          >
            <div>
              <div className="flex items-center justify-between mb-3.5">
                <div className="w-10 h-10 rounded-xl bg-[#AE82D9]/18 border border-[#AE82D9]/35 flex items-center justify-center">
                  <Users className="w-5 h-5 text-[#6A3E94]" />
                </div>
                <span className="text-[10px] font-bold uppercase tracking-wider px-2.5 py-0.5 rounded-full bg-[#81D8D0]/18 border border-[#81D8D0]/40 text-[#1D5E57]">
                  {circle.my_role || "Member"}
                </span>
              </div>

              <h3 className="text-base font-bold text-[#1F2223] group-hover:text-[#2B7A72] transition-colors">
                {circle.name}
              </h3>
              {circle.handle && (
                <p className="text-xs text-[#656A6D] font-mono mt-0.5">@{circle.handle}</p>
              )}
            </div>

            <div className="mt-6 pt-4 border-t border-[#E8E5DF] flex items-center justify-between text-xs text-[#656A6D]">
              <span className="flex items-center gap-1.5 font-medium">
                <UserCheck className="w-3.5 h-3.5 text-[#2B7A72]" />
                {circle.members_count || 1} {circle.members_count === 1 ? "member" : "members"}
              </span>

              <span className="text-[#2B7A72] font-semibold group-hover:translate-x-0.5 transition-transform flex items-center gap-1">
                Open Circle <ArrowRight className="w-3.5 h-3.5" />
              </span>
            </div>
          </Link>
        ))}

        {circles.length === 0 && (
          <div className="col-span-full py-12 px-6 text-center border border-dashed border-[#E8E5DF] rounded-2xl bg-white">
            <div className="w-12 h-12 rounded-2xl bg-[#81D8D0]/20 text-[#1D5E57] flex items-center justify-center mx-auto mb-3 shadow-xs">
              <Users className="w-6 h-6 text-[#2B7A72]" />
            </div>
            <h3 className="text-sm font-bold text-[#1F2223]">No circles yet</h3>
            <p className="text-xs text-[#656A6D] mt-1 max-w-sm mx-auto leading-relaxed">
              Create a circle for your friends, family, or shift team, or join an existing circle using an invite code.
            </p>
            <div className="mt-5 flex justify-center gap-3">
              <button
                onClick={onJoinClick}
                className="px-3.5 py-2 bg-[#FAF9F6] border border-[#E8E5DF] rounded-xl text-xs font-semibold text-[#1F2223] shadow-xs"
              >
                Join with Code
              </button>
              <button
                onClick={onCreateClick}
                className="px-4 py-2 bg-[#2B7A72] text-white rounded-xl text-xs font-semibold shadow-xs"
              >
                + Create First Circle
              </button>
            </div>
          </div>
        )}
      </div>
      )}
    </div>
  );
}
