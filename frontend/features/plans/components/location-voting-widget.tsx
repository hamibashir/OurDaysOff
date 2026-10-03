"use client";

import { useState } from "react";
import { MapPin, ThumbsUp, Plus } from "lucide-react";
import { apiClient } from "@/lib/api-client";

interface LocationOption {
  id: number;
  name: string;
  address?: string;
  votes: Array<{ id: number; user_id: number }>;
}

interface LocationVotingWidgetProps {
  planId: number;
  locations: LocationOption[];
  onVoteSuccess: () => void;
}

export function LocationVotingWidget({ planId, locations, onVoteSuccess }: LocationVotingWidgetProps) {
  const [name, setName] = useState("");
  const [address, setAddress] = useState("");
  const [isAdding, setIsAdding] = useState(false);

  const handlePropose = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!name.trim()) return;

    try {
      await apiClient.post(`/plans/${planId}/locations`, { name, address });
      setName("");
      setAddress("");
      setIsAdding(false);
      onVoteSuccess();
    } catch (err: any) {
      alert(err.message || "Failed to propose location.");
    }
  };

  const handleVote = async (locationId: number) => {
    try {
      await apiClient.post(`/locations/${locationId}/vote`);
      onVoteSuccess();
    } catch (err: any) {
      alert(err.message || "Failed to vote.");
    }
  };

  return (
    <div className="bg-white border border-[#E8E5DF] rounded-2xl p-5 space-y-4 shadow-xs">
      <div className="flex items-center justify-between pb-3 border-b border-[#E8E5DF]">
        <h4 className="text-xs font-bold text-[#1F2223] uppercase tracking-wider flex items-center gap-2">
          <MapPin className="w-4 h-4 text-[#2B7A72]" />
          Location Options & Voting
        </h4>
        <button
          onClick={() => setIsAdding(!isAdding)}
          className="text-xs text-[#2B7A72] hover:text-[#1D5E57] font-bold flex items-center gap-1 transition-colors"
        >
          <Plus className="w-3.5 h-3.5" /> Propose Venue
        </button>
      </div>

      {isAdding && (
        <form onSubmit={handlePropose} className="p-3.5 rounded-xl bg-[#FAF9F6] border border-[#E8E5DF] space-y-3">
          <input
            type="text"
            required
            placeholder="Venue Name (e.g. Italian Bistro Downtown)"
            value={name}
            onChange={(e) => setName(e.target.value)}
            className="w-full bg-white border border-[#E8E5DF] rounded-lg px-3 py-2 text-xs text-[#1F2223] outline-none focus:border-[#81D8D0] transition-colors"
          />
          <input
            type="text"
            placeholder="Address (Optional)"
            value={address}
            onChange={(e) => setAddress(e.target.value)}
            className="w-full bg-white border border-[#E8E5DF] rounded-lg px-3 py-2 text-xs text-[#1F2223] outline-none focus:border-[#81D8D0] transition-colors"
          />
          <div className="flex justify-end gap-2 pt-1">
            <button
              type="button"
              onClick={() => setIsAdding(false)}
              className="px-3 py-1.5 bg-white border border-[#E8E5DF] hover:bg-[#F2EFE9] text-[#656A6D] rounded-lg text-xs font-semibold transition-colors"
            >
              Cancel
            </button>
            <button
              type="submit"
              className="px-3 py-1.5 bg-[#2B7A72] hover:bg-[#1D5E57] text-white rounded-lg text-xs font-bold shadow-xs transition-colors"
            >
              Add Location
            </button>
          </div>
        </form>
      )}

      <div className="space-y-2">
        {locations.map((loc) => (
          <div
            key={loc.id}
            className="p-3.5 rounded-xl bg-[#FAF9F6] border border-[#E8E5DF] flex flex-col sm:flex-row sm:items-center justify-between gap-3 text-xs"
          >
            <div>
              <p className="font-bold text-[#1F2223]">{loc.name}</p>
              {loc.address && <p className="text-[11px] text-[#656A6D] mt-0.5">{loc.address}</p>}
            </div>

            <button
              onClick={() => handleVote(loc.id)}
              className="px-3 py-2 bg-white hover:bg-[#F2EFE9] border border-[#E8E5DF] rounded-lg text-[#656A6D] hover:text-[#1F2223] flex items-center justify-center gap-1.5 font-bold transition-colors shrink-0"
            >
              <ThumbsUp className="w-3.5 h-3.5 text-[#2B7A72]" />
              <span>{loc.votes?.length || 0} Votes</span>
            </button>
          </div>
        ))}

        {locations.length === 0 && !isAdding && (
          <p className="text-xs text-[#959A9E] italic py-3 text-center border border-dashed border-[#E8E5DF] rounded-xl bg-[#FAF9F6]">
            No location proposed yet. Click "+ Propose Venue" to suggest one.
          </p>
        )}
      </div>
    </div>
  );
}
