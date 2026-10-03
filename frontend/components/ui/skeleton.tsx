"use client";

import { HTMLAttributes } from "react";

export function Skeleton({ className = "", ...props }: HTMLAttributes<HTMLDivElement>) {
  return (
    <div
      className={`bg-[#E8E5DF]/70 animate-pulse rounded-xl ${className}`}
      {...props}
    />
  );
}

export function SkeletonCard({ className = "" }: { className?: string }) {
  return (
    <div className={`bg-white border border-[#E8E5DF] rounded-2xl p-5 shadow-xs space-y-3 ${className}`}>
      <div className="flex items-center justify-between">
        <Skeleton className="w-10 h-10 rounded-xl" />
        <Skeleton className="w-16 h-5 rounded-full" />
      </div>
      <Skeleton className="w-3/4 h-6 rounded-md" />
      <Skeleton className="w-1/2 h-4 rounded-md" />
    </div>
  );
}

export function SkeletonMetricGrid() {
  return (
    <div className="grid grid-cols-2 lg:grid-cols-4 gap-4">
      {Array.from({ length: 4 }).map((_, i) => (
        <div key={i} className="bg-white border border-[#E8E5DF] rounded-2xl p-4 md:p-5 space-y-3 shadow-xs">
          <div className="flex items-center justify-between">
            <Skeleton className="w-9 h-9 rounded-xl" />
            <Skeleton className="w-12 h-4 rounded-md" />
          </div>
          <Skeleton className="w-20 h-7 rounded-lg" />
          <Skeleton className="w-28 h-3 rounded-md" />
        </div>
      ))}
    </div>
  );
}

export function SkeletonList({ count = 4 }: { count?: number }) {
  return (
    <div className="space-y-2.5">
      {Array.from({ length: count }).map((_, i) => (
        <div key={i} className="p-3.5 rounded-xl bg-[#FAF9F6] border border-[#E8E5DF] flex items-center justify-between gap-3">
          <div className="flex items-center gap-3">
            <Skeleton className="w-8 h-8 rounded-lg" />
            <div className="space-y-1.5">
              <Skeleton className="w-28 h-4 rounded-md" />
              <Skeleton className="w-20 h-3 rounded-md" />
            </div>
          </div>
          <Skeleton className="w-24 h-6 rounded-md" />
        </div>
      ))}
    </div>
  );
}
