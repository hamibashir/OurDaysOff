"use client";

import { useState } from "react";
import { X, KeyRound, ShieldCheck } from "lucide-react";
import { apiClient } from "@/lib/api-client";

interface JoinCircleModalProps {
  isOpen: boolean;
  onClose: () => void;
  onSuccess: () => void;
}

export function JoinCircleModal({ isOpen, onClose, onSuccess }: JoinCircleModalProps) {
  const [inviteCode, setInviteCode] = useState("");
  const [isSubmitting, setIsSubmitting] = useState(false);
  const [error, setError] = useState<string | null>(null);

  if (!isOpen) return null;

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    setError(null);
    setIsSubmitting(true);

    try {
      await apiClient.post("/invites/join", { invite_code: inviteCode });
      setInviteCode("");
      onSuccess();
      onClose();
    } catch (err: any) {
      setError(err.message || "Invalid or expired invite code.");
    } finally {
      setIsSubmitting(false);
    }
  };

  return (
    <div className="fixed inset-0 bg-slate-900/40 backdrop-blur-xs z-50 flex items-center justify-center p-4">
      <div className="bg-white border border-[#E8E5DF] rounded-2xl max-w-md w-full p-6 shadow-xl space-y-4">
        <div className="flex items-center justify-between pb-3 border-b border-[#E8E5DF]">
          <h3 className="font-bold text-[#1F2223] text-base flex items-center gap-2">
            <KeyRound className="w-5 h-5 text-[#2B7A72]" />
            Join Circle with Code
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
            <label className="block text-[11px] font-bold uppercase tracking-wider text-[#656A6D] mb-1">
              6-Character Invite Code
            </label>
            <input
              type="text"
              required
              maxLength={10}
              placeholder="e.g. FAM123"
              value={inviteCode}
              onChange={(e) => setInviteCode(e.target.value.toUpperCase())}
              className="w-full bg-[#FAF9F6] border border-[#E8E5DF] focus:border-[#81D8D0] rounded-xl px-3 py-3 text-center font-mono font-bold text-lg text-[#23756C] tracking-widest outline-none shadow-inner"
            />
          </div>

          <div className="flex items-center gap-1.5 text-[11px] text-[#656A6D]">
            <ShieldCheck className="w-3.5 h-3.5 text-[#2B7A72]" />
            <span>Joining a circle grants derived free/busy availability view access only.</span>
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
              {isSubmitting ? "Joining..." : "Join Circle"}
            </button>
          </div>
        </form>
      </div>
    </div>
  );
}
