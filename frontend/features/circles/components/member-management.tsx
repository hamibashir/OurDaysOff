"use client";

import { CircleMember } from "@/types/api";
import { apiClient } from "@/lib/api-client";
import { Shield, Eye, Clock, UserCheck, Trash2, CheckCircle2 } from "lucide-react";
import { SkeletonList } from "@/components/ui/skeleton";

interface MemberManagementProps {
  circleId: number;
  members: CircleMember[];
  myRole: string;
  onMemberUpdated: () => void;
  isLoading?: boolean;
}

export function MemberManagement({ circleId, members, myRole, onMemberUpdated, isLoading = false }: MemberManagementProps) {
  const canManage = myRole === "owner" || myRole === "admin";

  const handleUpdateMember = async (memberId: number, data: Partial<CircleMember>) => {
    try {
      await apiClient.put(`/circles/${circleId}/members/${memberId}`, data);
      onMemberUpdated();
    } catch (err: any) {
      alert(err.message || "Failed to update member setting.");
    }
  };

  const handleRemoveMember = async (memberId: number, memberName: string) => {
    if (confirm(`Are you sure you want to remove ${memberName} from this circle?`)) {
      try {
        await apiClient.delete(`/circles/${circleId}/members/${memberId}`);
        onMemberUpdated();
      } catch (err: any) {
        alert(err.message || "Failed to remove member.");
      }
    }
  };

  return (
    <div className="bg-white border border-[#E8E5DF] rounded-2xl p-5 md:p-6 space-y-5 shadow-xs">
      <div className="flex items-center justify-between pb-3.5 border-b border-[#E8E5DF]">
        <div>
          <h3 className="text-sm font-bold text-[#1F2223] tracking-tight flex items-center gap-2">
            <UserCheck className="w-4 h-4 text-[#2B7A72]" />
            Circle Members & Privacy Roster
          </h3>
          <p className="text-xs text-[#656A6D] mt-0.5">
            Manage member participation (Working vs Viewer) and privacy visibility policies.
          </p>
        </div>
      </div>

      {isLoading ? (
        <SkeletonList count={3} />
      ) : (
        <div className="space-y-3">
        {members.map((m) => (
          <div
            key={m.id}
            className="p-4 rounded-xl bg-[#FAF9F6] border border-[#E8E5DF] flex flex-col sm:flex-row sm:items-center justify-between gap-4"
          >
            <div className="flex items-center gap-3">
              <div className="w-9 h-9 rounded-xl bg-[#81D8D0] flex items-center justify-center font-bold text-xs text-[#1D5E57] shadow-xs">
                {m.user?.name.charAt(0) || "U"}
              </div>
              <div>
                <p className="text-xs font-bold text-[#1F2223] flex items-center gap-2">
                  <span>{m.user?.name}</span>
                  <span className="text-[10px] font-bold uppercase tracking-wider px-2 py-0.5 rounded-full bg-[#81D8D0]/18 border border-[#81D8D0]/40 text-[#1D5E57]">
                    {m.role}
                  </span>
                </p>
                <p className="text-[11px] text-[#656A6D]">@{m.user?.handle || "user"}</p>
              </div>
            </div>

            <div className="flex flex-wrap items-center gap-3">
              {/* Member Type (Working vs Viewer) */}
              <div className="flex items-center gap-1.5 bg-white border border-[#E8E5DF] rounded-xl px-3 py-1.5 text-xs shadow-xs">
                <span className="text-[#656A6D]">Type:</span>
                {canManage ? (
                  <select
                    value={m.member_type}
                    onChange={(e) => handleUpdateMember(m.id, { member_type: e.target.value as any })}
                    className="bg-transparent text-[#2B7A72] font-semibold outline-none cursor-pointer"
                  >
                    <option value="working">Working Member</option>
                    <option value="viewer">Viewer (No Match Calculation)</option>
                  </select>
                ) : (
                  <span className="text-[#2B7A72] font-semibold">{m.member_type}</span>
                )}
              </div>

              {/* Visibility Policy */}
              <div className="flex items-center gap-1.5 bg-white border border-[#E8E5DF] rounded-xl px-3 py-1.5 text-xs shadow-xs">
                <span className="text-[#656A6D]">Visibility:</span>
                {canManage || m.user_id === m.user?.id ? (
                  <select
                    value={m.visibility}
                    onChange={(e) => handleUpdateMember(m.id, { visibility: e.target.value as any })}
                    className="bg-transparent text-[#23756C] font-semibold outline-none cursor-pointer"
                  >
                    <option value="free_busy">Free/Busy Only (Strict Privacy)</option>
                    <option value="shifts">Shifts Category</option>
                    <option value="details">Full Shift Details</option>
                  </select>
                ) : (
                  <span className="text-[#23756C] font-semibold">{m.visibility}</span>
                )}
              </div>

              {canManage && m.role !== "owner" && (
                <button
                  onClick={() => handleRemoveMember(m.id, m.user?.name || "member")}
                  className="p-2 hover:bg-rose-50 text-[#959A9E] hover:text-rose-600 rounded-lg transition-colors border border-transparent hover:border-rose-200"
                  title="Remove Member"
                >
                  <Trash2 className="w-3.5 h-3.5" />
                </button>
              )}
            </div>
          </div>
        ))}
      </div>
      )}
    </div>
  );
}
