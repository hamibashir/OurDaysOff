"use client";

import { User } from "@/types/api";
import { Sliders, UserCheck, UserX, Users, Check, Plus, RefreshCw } from "lucide-react";

interface CompareMember {
  id: number;
  name: string;
  handle: string | null;
}

interface PersonalCompareToolProps {
  availableMembers: CompareMember[];
  selectedUserIds: number[];
  onToggleUser: (userId: number) => void;
  onSelectAll: () => void;
  onDeselectAll: () => void;
  onRunCompare: () => void;
  isLoading: boolean;
  circleName?: string;
}

export function PersonalCompareTool({
  availableMembers,
  selectedUserIds,
  onToggleUser,
  onSelectAll,
  onDeselectAll,
  onRunCompare,
  isLoading,
  circleName,
}: PersonalCompareToolProps) {
  if (isLoading && availableMembers.length === 0) {
    return (
      <div className="bg-white border border-[#E8E5DF] rounded-2xl p-6 text-center space-y-3 shadow-xs animate-pulse">
        <div className="w-10 h-10 rounded-xl bg-[#81D8D0]/20 mx-auto flex items-center justify-center">
          <Users className="w-5 h-5 text-[#2B7A72]" />
        </div>
        <div className="h-4 w-36 bg-[#E8E5DF] rounded mx-auto" />
        <div className="h-3 w-64 bg-[#E8E5DF] rounded mx-auto" />
      </div>
    );
  }

  if (!isLoading && availableMembers.length === 0) {
    return (
      <div className="bg-white border border-[#E8E5DF] rounded-2xl p-6 text-center space-y-3 shadow-xs">
        <div className="w-10 h-10 rounded-xl bg-[#81D8D0]/20 border border-[#81D8D0]/40 flex items-center justify-center mx-auto text-[#1D5E57]">
          <Users className="w-5 h-5" />
        </div>
        <h3 className="text-sm font-bold text-[#1F2223]">No Members Found</h3>
        <p className="text-xs text-[#656A6D] max-w-sm mx-auto">
          Add members to your circle to calculate common free time and Magic Hours.
        </p>
      </div>
    );
  }

  const allSelected = selectedUserIds.length === availableMembers.length;

  return (
    <div className="bg-white border border-[#E8E5DF] rounded-2xl p-5 md:p-6 space-y-5 shadow-xs">
      <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-4 pb-3.5 border-b border-[#E8E5DF]">
        <div>
          <div className="flex items-center gap-2">
            <h3 className="text-sm font-bold text-[#1F2223] tracking-tight flex items-center gap-2">
              <Sliders className="w-4 h-4 text-[#2B7A72]" />
              {circleName ? `Comparing: ${circleName}` : "Circle Member Comparison"}
            </h3>
            <span className="text-[11px] px-2 py-0.5 rounded-full bg-[#81D8D0]/20 text-[#1D5E57] font-semibold font-mono">
              {selectedUserIds.length} of {availableMembers.length} Active
            </span>
          </div>
          <p className="text-xs text-[#656A6D] mt-1">
            Tap members below to include or exclude them from the common free-time calculation.
          </p>
        </div>

        <div className="flex items-center gap-2">
          {allSelected ? (
            <button
              onClick={onDeselectAll}
              className="px-3 py-1.5 bg-[#FAF9F6] hover:bg-[#F2EFE9] text-[#656A6D] border border-[#E8E5DF] rounded-xl text-xs font-semibold transition-all shadow-xs"
            >
              Deselect All
            </button>
          ) : (
            <button
              onClick={onSelectAll}
              className="px-3 py-1.5 bg-[#FAF9F6] hover:bg-[#F2EFE9] text-[#1D5E57] border border-[#E8E5DF] rounded-xl text-xs font-semibold transition-all shadow-xs"
            >
              Select All
            </button>
          )}

          <button
            onClick={onRunCompare}
            disabled={isLoading || selectedUserIds.length < 2}
            className="px-4 py-2 bg-[#2B7A72] hover:bg-[#1D5E57] text-white rounded-xl text-xs font-semibold shadow-xs transition-all disabled:opacity-50 flex items-center gap-1.5 shrink-0 cursor-pointer"
          >
            {isLoading ? (
              <>
                <RefreshCw className="w-3.5 h-3.5 animate-spin" />
                <span>Calculating...</span>
              </>
            ) : (
              <span>Recalculate Match</span>
            )}
          </button>
        </div>
      </div>

      {/* Interactive Member Toggle Chips */}
      <div className="space-y-2.5">
        <label className="block text-[11px] font-bold uppercase tracking-wider text-[#656A6D]">
          Circle Members ({availableMembers.length})
        </label>

        <div className="flex flex-wrap items-center gap-2">
          {availableMembers.map((m) => {
            const isSelected = selectedUserIds.includes(m.id);

            return (
              <button
                key={m.id}
                type="button"
                onClick={() => onToggleUser(m.id)}
                className={`inline-flex items-center gap-2 px-3 py-1.5 rounded-xl text-xs font-semibold transition-all border shadow-xs cursor-pointer ${
                  isSelected
                    ? "bg-[#81D8D0]/20 border-[#81D8D0] text-[#1D5E57]"
                    : "bg-[#FAF9F6] border-[#E8E5DF] text-[#959A9E] hover:text-[#1F2223] opacity-60"
                }`}
              >
                {isSelected ? (
                  <Check className="w-3.5 h-3.5 text-[#2B7A72] shrink-0" />
                ) : (
                  <Plus className="w-3.5 h-3.5 text-[#959A9E] shrink-0" />
                )}
                <span>{m.name}</span>
                {m.handle && (
                  <span className="font-mono text-[10px] opacity-75">
                    (@{m.handle})
                  </span>
                )}
              </button>
            );
          })}
        </div>

        {selectedUserIds.length < 2 && (
          <p className="text-[11px] text-amber-700 bg-amber-50 border border-amber-200 rounded-lg p-2 font-medium">
            ⚠️ Select at least 2 members to calculate common free time.
          </p>
        )}
      </div>
    </div>
  );
}
