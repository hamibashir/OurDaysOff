"use client";

import { useEffect, useState } from "react";
import { useAuth } from "@/features/auth/auth-context";
import { apiClient } from "@/lib/api-client";
import { DeviceManager } from "@/features/devices/components/device-manager";
import { User, Check, ShieldCheck } from "lucide-react";

export default function ProfilePage() {
  const { user, refreshUser } = useAuth();
  const [name, setName] = useState(user?.name || "");
  const [isSaving, setIsSaving] = useState(false);
  const [successMessage, setSuccessMessage] = useState("");

  useEffect(() => {
    if (user) {
      setName(user.name);
    }
  }, [user]);

  const handleSaveProfile = async (e: React.FormEvent) => {
    e.preventDefault();
    setIsSaving(true);
    setSuccessMessage("");
    try {
      await apiClient.put("/profile", { name });
      await refreshUser();
      setSuccessMessage("Profile updated successfully!");
    } catch (err: any) {
      alert(err.message || "Failed to update profile");
    } finally {
      setIsSaving(false);
    }
  };

  if (!user) return null;

  return (
    <div className="max-w-4xl mx-auto space-y-6 md:space-y-8">
      {/* Header Banner */}
      <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-4 bg-white border border-[#E8E5DF] rounded-2xl p-5 md:p-6 shadow-xs">
        <div className="flex items-start gap-3.5">
          <div className="w-10 h-10 rounded-xl bg-[#81D8D0]/20 border border-[#81D8D0]/40 flex items-center justify-center shrink-0 mt-0.5 shadow-xs">
            <User className="w-5 h-5 text-[#1D5E57]" />
          </div>
          <div>
            <div className="flex items-center gap-2">
              <h1 className="text-xl font-bold text-[#1F2223] tracking-tight">
                Account Profile & Settings
              </h1>
              <span className="inline-flex items-center gap-1 px-2 py-0.5 rounded-full bg-[#81D8D0]/20 text-[#1D5E57] text-[10px] font-mono font-semibold">
                <ShieldCheck className="w-3 h-3 text-[#2B7A72]" /> Encrypted
              </span>
            </div>
            <p className="text-xs text-[#656A6D] mt-1 leading-relaxed">
              Manage your personal identity and companion device pairings.
            </p>
          </div>
        </div>
      </div>

      {/* Personal Information Form */}
      <div className="bg-white border border-[#E8E5DF] rounded-2xl p-5 md:p-6 space-y-5 shadow-xs">
        <div className="flex items-center gap-2 pb-4 border-b border-[#E8E5DF]">
          <User className="w-4 h-4 text-[#2B7A72]" />
          <h3 className="text-sm font-bold text-[#1F2223]">Personal Information</h3>
        </div>

        {successMessage && (
          <div className="p-3.5 rounded-xl bg-emerald-50 border border-emerald-200 text-emerald-800 text-xs font-semibold flex items-center gap-2">
            <Check className="w-4 h-4 text-emerald-600" /> {successMessage}
          </div>
        )}

        <form onSubmit={handleSaveProfile} className="space-y-4">
          <div className="grid grid-cols-1 sm:grid-cols-2 gap-4">
            <div>
              <label className="block text-[11px] font-bold uppercase tracking-wider text-[#656A6D] mb-1">Full Name</label>
              <input
                type="text"
                value={name}
                onChange={(e) => setName(e.target.value)}
                required
                className="w-full bg-[#FAF9F6] border border-[#E8E5DF] focus:border-[#81D8D0] rounded-xl px-3.5 py-2.5 text-xs text-[#1F2223] outline-none font-medium"
              />
            </div>

            <div>
              <label className="block text-[11px] font-bold uppercase tracking-wider text-[#656A6D] mb-1">Email Address</label>
              <input
                type="email"
                value={user.email}
                disabled
                className="w-full bg-[#FAF9F6]/60 border border-[#E8E5DF] text-[#959A9E] rounded-xl px-3.5 py-2.5 text-xs outline-none cursor-not-allowed"
              />
            </div>

            <div>
              <label className="block text-[11px] font-bold uppercase tracking-wider text-[#656A6D] mb-1">User Handle</label>
              <input
                type="text"
                value={`@${user.handle}`}
                disabled
                className="w-full bg-[#FAF9F6]/60 border border-[#E8E5DF] text-[#959A9E] rounded-xl px-3.5 py-2.5 text-xs outline-none cursor-not-allowed font-mono"
              />
            </div>
          </div>

          <div className="flex justify-end pt-2">
            <button
              type="submit"
              disabled={isSaving}
              className="px-4 py-2.5 bg-[#2B7A72] hover:bg-[#1D5E57] text-white rounded-xl text-xs font-semibold shadow-xs transition-all disabled:opacity-50"
            >
              {isSaving ? "Saving..." : "Save Changes"}
            </button>
          </div>
        </form>
      </div>

      <DeviceManager />
    </div>
  );
}
