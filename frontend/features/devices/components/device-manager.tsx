"use client";

import { useEffect, useState } from "react";
import { apiClient } from "@/lib/api-client";
import { Smartphone, QrCode, Trash2, KeyRound, ShieldCheck, RefreshCw } from "lucide-react";

interface Device {
  id: number;
  device_name: string;
  device_type: string;
  device_identifier: string;
  last_seen_at: string | null;
}

import { Skeleton } from "@/components/ui/skeleton";
import { sessionCache } from "@/lib/session-cache";

const DEVICES_CACHE_KEY = "user_devices";

export function DeviceManager() {
  const cachedDevices = sessionCache.get<Device[]>(DEVICES_CACHE_KEY);

  const [devices, setDevices] = useState<Device[]>(cachedDevices || []);
  const [isLoading, setIsLoading] = useState(!cachedDevices);
  const [pairingCode, setPairingCode] = useState<string | null>(null);
  const [codeExpiresAt, setCodeExpiresAt] = useState<string | null>(null);

  const fetchDevices = async (forceRefetch = false) => {
    if (forceRefetch || !sessionCache.has(DEVICES_CACHE_KEY)) {
      if (!sessionCache.has(DEVICES_CACHE_KEY)) setIsLoading(true);
      try {
        const res = await apiClient.get<{ data: Device[] }>("/devices");
        const list = (res.data || []).filter((d) => !d.device_identifier.startsWith("pending_pairing"));
        setDevices(list);
        sessionCache.set(DEVICES_CACHE_KEY, list);
      } catch (err) {
        console.error("Failed to load devices", err);
      } finally {
        setIsLoading(false);
      }
    }
  };

  useEffect(() => {
    if (!sessionCache.has(DEVICES_CACHE_KEY)) {
      fetchDevices(true);
    }
  }, []);

  const handleGeneratePairingCode = async () => {
    try {
      const res = await apiClient.post<{ pairing_code: string; expires_at: string }>(
        "/devices/pairing-code"
      );
      setPairingCode(res.pairing_code);
      setCodeExpiresAt(res.expires_at);
    } catch (err) {
      alert("Failed to generate pairing code.");
    }
  };

  const handleRevokeDevice = async (id: number) => {
    if (!confirm("Revoke access for this device?")) return;
    try {
      await apiClient.delete(`/devices/${id}`);
      setDevices((prev) => {
        const updated = prev.filter((d) => d.id !== id);
        sessionCache.set(DEVICES_CACHE_KEY, updated);
        return updated;
      });
    } catch (err) {
      alert("Failed to revoke device.");
    }
  };

  return (
    <div className="bg-white border border-[#E8E5DF] rounded-2xl p-5 md:p-6 space-y-6 shadow-xs">
      <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-4 pb-4 border-b border-[#E8E5DF]">
        <div className="flex items-center gap-3">
          <div className="w-10 h-10 rounded-xl bg-[#AE82D9]/20 border border-[#AE82D9]/40 flex items-center justify-center shrink-0 shadow-xs">
            <Smartphone className="w-5 h-5 text-[#6A3E94]" />
          </div>
          <div>
            <h3 className="text-sm font-bold text-[#1F2223] tracking-tight">Connected Devices & Mobile Pairings</h3>
            <p className="text-xs text-[#656A6D] mt-0.5">Manage paired devices and connect Flutter companion apps</p>
          </div>
        </div>

        <button
          onClick={handleGeneratePairingCode}
          className="px-4 py-2.5 bg-[#2B7A72] hover:bg-[#1D5E57] text-white rounded-xl text-xs font-semibold shadow-xs flex items-center gap-2 transition-all shrink-0"
        >
          <KeyRound className="w-4 h-4 text-[#D7D982]" /> Pair Mobile Device
        </button>
      </div>

      {pairingCode && (
        <div className="p-5 rounded-2xl bg-[#81D8D0]/15 border border-[#81D8D0]/40 space-y-3">
          <div className="flex items-center justify-between">
            <span className="text-xs font-bold text-[#1D5E57] flex items-center gap-1.5">
              <QrCode className="w-4 h-4 text-[#2B7A72]" /> Enter Code in Mobile App
            </span>
            <span className="text-[10px] font-mono font-semibold text-[#656A6D]">Valid for 10 min</span>
          </div>
          <div className="text-center py-3.5 bg-white border border-[#E8E5DF] rounded-xl shadow-inner">
            <span className="text-3xl font-mono font-bold tracking-widest text-[#23756C]">
              {pairingCode}
            </span>
          </div>
          <p className="text-[11px] text-[#656A6D] text-center leading-relaxed">
            Open your Flutter mobile app, select &quot;Pair with Web Account&quot;, and type the 6-character code above.
          </p>
        </div>
      )}

      {isLoading ? (
        <div className="space-y-2.5">
          <Skeleton className="h-16 w-full rounded-xl" />
          <Skeleton className="h-16 w-full rounded-xl" />
        </div>
      ) : devices.length === 0 ? (
        <div className="p-8 text-center border border-dashed border-[#E8E5DF] rounded-2xl bg-[#FAF9F6] text-xs text-[#656A6D]">
          No active mobile devices paired yet. Click &quot;Pair Mobile Device&quot; to connect your phone.
        </div>
      ) : (
        <div className="space-y-2.5">
          {devices.map((device) => (
            <div
              key={device.id}
              className="p-4 rounded-xl bg-[#FAF9F6] border border-[#E8E5DF] flex items-center justify-between"
            >
              <div className="flex items-center gap-3">
                <ShieldCheck className="w-4.5 h-4.5 text-[#2B7A72]" />
                <div>
                  <h4 className="text-xs font-bold text-[#1F2223]">{device.device_name}</h4>
                  <p className="text-[10px] font-mono text-[#656A6D] uppercase">{device.device_type} • {device.device_identifier.slice(0, 16)}...</p>
                </div>
              </div>

              <button
                onClick={() => handleRevokeDevice(device.id)}
                className="p-2 text-[#959A9E] hover:text-rose-600 hover:bg-rose-50 rounded-lg transition-colors border border-transparent hover:border-rose-200"
                title="Revoke device"
              >
                <Trash2 className="w-4 h-4" />
              </button>
            </div>
          ))}
        </div>
      )}
    </div>
  );
}
