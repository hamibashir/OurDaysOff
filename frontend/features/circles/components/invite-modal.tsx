"use client";

import { useState } from "react";
import { X, Copy, Check, QrCode, Link2, KeyRound } from "lucide-react";
import { apiClient } from "@/lib/api-client";

interface InviteModalProps {
  circleId: number;
  isOpen: boolean;
  onClose: () => void;
}

export function InviteModal({ circleId, isOpen, onClose }: InviteModalProps) {
  const [inviteData, setInviteData] = useState<{ invite_code: string; invite_url: string } | null>(null);
  const [isLoading, setIsLoading] = useState(false);
  const [copiedCode, setCopiedCode] = useState(false);
  const [copiedUrl, setCopiedUrl] = useState(false);

  if (!isOpen) return null;

  const handleGenerate = async () => {
    setIsLoading(true);
    try {
      const res = await apiClient.post<{ data: { invite_code: string; invite_url: string } }>(
        `/circles/${circleId}/invites`
      );
      setInviteData(res.data);
    } catch (err: any) {
      alert(err.message || "Failed to generate invite code.");
    } finally {
      setIsLoading(false);
    }
  };

  const copyToClipboard = (text: string, type: "code" | "url") => {
    navigator.clipboard.writeText(text);
    if (type === "code") {
      setCopiedCode(true);
      setTimeout(() => setCopiedCode(false), 2000);
    } else {
      setCopiedUrl(true);
      setTimeout(() => setCopiedUrl(false), 2000);
    }
  };

  return (
    <div className="fixed inset-0 bg-slate-900/40 backdrop-blur-xs z-50 flex items-center justify-center p-4">
      <div className="bg-white border border-[#E8E5DF] rounded-2xl max-w-md w-full p-6 shadow-xl space-y-4">
        <div className="flex items-center justify-between pb-3 border-b border-[#E8E5DF]">
          <h3 className="font-bold text-[#1F2223] text-base flex items-center gap-2">
            <KeyRound className="w-5 h-5 text-[#2B7A72]" />
            Circle Invitation Code
          </h3>
          <button onClick={onClose} className="text-[#959A9E] hover:text-[#1F2223]">
            <X className="w-5 h-5" />
          </button>
        </div>

        {!inviteData ? (
          <div className="text-center py-6 space-y-4">
            <p className="text-xs text-[#656A6D] leading-relaxed">
              Generate a 6-character single-use or shareable join code for friends and team members.
            </p>
            <button
              onClick={handleGenerate}
              disabled={isLoading}
              className="px-4 py-2.5 bg-[#2B7A72] hover:bg-[#1D5E57] text-white rounded-xl text-xs font-semibold transition-all shadow-xs disabled:opacity-50"
            >
              {isLoading ? "Generating Code..." : "Generate Invite Code & Link"}
            </button>
          </div>
        ) : (
          <div className="space-y-4 pt-1">
            <div>
              <label className="block text-[11px] font-bold uppercase tracking-wider text-[#656A6D] mb-1">
                6-Character Join Code
              </label>
              <div className="flex items-center gap-2">
                <input
                  type="text"
                  readOnly
                  value={inviteData.invite_code}
                  className="flex-1 bg-[#FAF9F6] border border-[#E8E5DF] rounded-xl px-3 py-2.5 text-center font-mono font-bold text-lg text-[#23756C] tracking-widest outline-none shadow-inner"
                />
                <button
                  onClick={() => copyToClipboard(inviteData.invite_code, "code")}
                  className="p-2.5 bg-[#2B7A72] hover:bg-[#1D5E57] text-white rounded-xl text-xs font-semibold transition-all shrink-0 shadow-xs"
                >
                  {copiedCode ? <Check className="w-4 h-4 text-[#D7D982]" /> : <Copy className="w-4 h-4" />}
                </button>
              </div>
            </div>

            <div>
              <label className="block text-[11px] font-bold uppercase tracking-wider text-[#656A6D] mb-1">
                Shareable Direct Link
              </label>
              <div className="flex items-center gap-2">
                <input
                  type="text"
                  readOnly
                  value={inviteData.invite_url}
                  className="flex-1 bg-[#FAF9F6] border border-[#E8E5DF] rounded-xl px-3 py-2 text-xs font-mono text-[#1F2223] truncate outline-none"
                />
                <button
                  onClick={() => copyToClipboard(inviteData.invite_url, "url")}
                  className="p-2 bg-[#FAF9F6] hover:bg-[#F2EFE9] border border-[#E8E5DF] text-[#1F2223] rounded-xl text-xs transition-all shrink-0 shadow-xs"
                >
                  {copiedUrl ? <Check className="w-4 h-4 text-[#2B7A72]" /> : <Link2 className="w-4 h-4" />}
                </button>
              </div>
            </div>

            <div className="p-3 rounded-xl bg-[#FAF9F6] border border-[#E8E5DF] text-center">
              <p className="text-[11px] text-[#656A6D] leading-relaxed">
                This code expires in 7 days. Anyone with this code can request to join your circle.
              </p>
            </div>
          </div>
        )}
      </div>
    </div>
  );
}
