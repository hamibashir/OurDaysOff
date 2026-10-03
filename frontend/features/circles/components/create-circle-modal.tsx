"use client";

import { useState } from "react";
import { X, Users, AtSign, Globe, Lock, ShieldCheck } from "lucide-react";
import { apiClient } from "@/lib/api-client";

interface CreateCircleModalProps {
  isOpen: boolean;
  onClose: () => void;
  onSuccess: () => void;
}

export function CreateCircleModal({ isOpen, onClose, onSuccess }: CreateCircleModalProps) {
  const [name, setName] = useState("");
  const [handle, setHandle] = useState("");
  const [discoverability, setDiscoverability] = useState<"private" | "searchable">("private");
  const [isSubmitting, setIsSubmitting] = useState(false);
  const [error, setError] = useState<string | null>(null);

  if (!isOpen) return null;

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    setError(null);
    setIsSubmitting(true);

    try {
      await apiClient.post("/circles", { name, handle: handle || undefined, discoverability });
      setName("");
      setHandle("");
      onSuccess();
      onClose();
    } catch (err: any) {
      setError(err.message || "Failed to create circle.");
    } finally {
      setIsSubmitting(false);
    }
  };

  return (
    <div className="fixed inset-0 bg-slate-900/40 backdrop-blur-xs z-50 flex items-center justify-center p-4">
      <div className="bg-white border border-[#E8E5DF] rounded-2xl max-w-md w-full p-6 shadow-xl space-y-4">
        <div className="flex items-center justify-between pb-3 border-b border-[#E8E5DF]">
          <h3 className="font-bold text-[#1F2223] text-base flex items-center gap-2">
            <Users className="w-5 h-5 text-[#2B7A72]" />
            Create New Circle
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
              Circle Name
            </label>
            <input
              type="text"
              required
              placeholder="e.g. Flight Attendant Squad, Weekend Crew"
              value={name}
              onChange={(e) => setName(e.target.value)}
              className="w-full bg-[#FAF9F6] border border-[#E8E5DF] focus:border-[#81D8D0] rounded-xl px-3.5 py-2.5 text-xs text-[#1F2223] outline-none"
            />
          </div>

          <div>
            <label className="block text-[11px] font-bold uppercase tracking-wider text-[#656A6D] mb-1">
              Circle Handle (Optional)
            </label>
            <div className="relative">
              <AtSign className="absolute left-3 top-3 w-3.5 h-3.5 text-[#959A9E]" />
              <input
                type="text"
                placeholder="squad_handle"
                value={handle}
                onChange={(e) => setHandle(e.target.value)}
                className="w-full bg-[#FAF9F6] border border-[#E8E5DF] focus:border-[#81D8D0] rounded-xl py-2.5 pl-8 pr-3 text-xs text-[#1F2223] outline-none font-mono"
              />
            </div>
          </div>

          <div>
            <label className="block text-[11px] font-bold uppercase tracking-wider text-[#656A6D] mb-1">
              Discoverability Policy
            </label>
            <select
              value={discoverability}
              onChange={(e) => setDiscoverability(e.target.value as "private" | "searchable")}
              className="w-full bg-[#FAF9F6] border border-[#E8E5DF] focus:border-[#81D8D0] rounded-xl px-3.5 py-2.5 text-xs text-[#1F2223] outline-none cursor-pointer"
            >
              <option value="private">Private (Invite Link / Code Only)</option>
              <option value="searchable">Searchable (Public handle lookup)</option>
            </select>
          </div>

          <div className="flex items-center gap-1.5 text-[11px] text-[#656A6D] pt-1">
            <ShieldCheck className="w-3.5 h-3.5 text-[#2B7A72]" />
            <span>Circle members only see derived available windows, never raw shifts.</span>
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
              {isSubmitting ? "Creating..." : "Create Circle"}
            </button>
          </div>
        </form>
      </div>
    </div>
  );
}
