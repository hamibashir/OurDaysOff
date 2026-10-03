import { useState, useEffect } from "react";
import { X, Upload, Check, Sparkles, Copy, FileJson, Edit, Bot, Star, Crown, ShieldCheck, Loader2 } from "lucide-react";
import { apiClient } from "@/lib/api-client";

interface PreviewEntry {
  date: string;
  shift_label?: string;
  label?: string;
  start_time: string;
  end_time: string;
  entry_type: string;
  is_overnight: boolean;
}

interface ImportRotaModalProps {
  isOpen: boolean;
  onClose: () => void;
  onSuccess: () => void;
}

export function ImportRotaModal({ isOpen, onClose, onSuccess }: ImportRotaModalProps) {
  const [activeTab, setActiveTab] = useState<"ai-vision" | "ai-external" | "manual">("manual");
  
  // Premium state
  const [isPremium, setIsPremium] = useState<boolean | null>(null);
  const [isCheckingPremium, setIsCheckingPremium] = useState(false);

  // Coupon state
  const [showCouponPrompt, setShowCouponPrompt] = useState(false);
  const [couponCode, setCouponCode] = useState("");
  const [isRedeeming, setIsRedeeming] = useState(false);

  // AI Vision state
  const [file, setFile] = useState<File | null>(null);
  
  // External AI state
  const [externalJson, setExternalJson] = useState("");
  const [isCopied, setIsCopied] = useState(false);

  // Common state
  const [previewEntries, setPreviewEntries] = useState<PreviewEntry[] | null>(null);
  const [isLoading, setIsLoading] = useState(false);
  const [isConfirming, setIsConfirming] = useState(false);
  const [error, setError] = useState<string | null>(null);

  useEffect(() => {
    if (isOpen) {
      checkPremiumStatus();
    } else {
      // Reset state on close
      resetState();
      setActiveTab("manual");
      setShowCouponPrompt(false);
    }
  }, [isOpen]);

  const checkPremiumStatus = async () => {
    setIsCheckingPremium(true);
    try {
      const res = await apiClient.get<{ is_premium: boolean }>("/subscription/status");
      setIsPremium(res.is_premium);
    } catch (err) {
      console.error("Failed to check premium status", err);
      // Default to false on error
      setIsPremium(false);
    } finally {
      setIsCheckingPremium(false);
    }
  };

  const handleRedeemCoupon = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!couponCode.trim()) return;

    setIsRedeeming(true);
    setError(null);

    try {
      const res = await apiClient.post<{ message: string, is_premium: boolean }>("/subscription/redeem", {
        coupon_code: couponCode
      });
      setIsPremium(res.is_premium);
      setShowCouponPrompt(false);
      setCouponCode("");
      // Show success briefly or just rely on the UI update
    } catch (err: any) {
      setError(err.message || "Failed to redeem coupon.");
    } finally {
      setIsRedeeming(false);
    }
  };

  const handleUpload = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!file) return;

    setError(null);
    setIsLoading(true);

    try {
      const formData = new FormData();
      formData.append("file", file);

      const res = await apiClient.upload<{ data: { preview_entries: PreviewEntry[] } }>("/imports/rota", formData);
      setPreviewEntries(res.data.preview_entries);
    } catch (err: any) {
      setError(err.message || "Failed to extract schedule from file.");
    } finally {
      setIsLoading(false);
    }
  };

  const handleExternalImport = (e: React.FormEvent) => {
    e.preventDefault();
    setError(null);

    try {
      if (!externalJson.trim()) {
        throw new Error("Please paste the AI response.");
      }

      let cleanJsonStr = externalJson.trim();
      if (cleanJsonStr.startsWith("```json")) {
        cleanJsonStr = cleanJsonStr.replace(/^```json/, "").replace(/```$/, "").trim();
      } else if (cleanJsonStr.startsWith("```")) {
        cleanJsonStr = cleanJsonStr.replace(/^```/, "").replace(/```$/, "").trim();
      }

      const parsed = JSON.parse(cleanJsonStr);

      if (!parsed.entries || !Array.isArray(parsed.entries)) {
        throw new Error("Invalid format: Missing 'entries' array in the JSON response.");
      }

      const validTypes = ["work", "leave", "off", "personal", "other"];
      const validated: PreviewEntry[] = [];

      for (let i = 0; i < parsed.entries.length; i++) {
        const item = parsed.entries[i];
        if (!item.date || !item.date.match(/^\d{4}-\d{2}-\d{2}$/)) {
          throw new Error(`Invalid date format for entry ${i + 1}. Expected YYYY-MM-DD.`);
        }
        if (!item.start_time || !item.start_time.match(/^\d{2}:\d{2}$/)) {
          throw new Error(`Invalid start_time for entry ${i + 1}. Expected HH:MM.`);
        }
        if (!item.end_time || !item.end_time.match(/^\d{2}:\d{2}$/)) {
          throw new Error(`Invalid end_time for entry ${i + 1}. Expected HH:MM.`);
        }
        if (!item.entry_type || !validTypes.includes(item.entry_type)) {
          throw new Error(`Invalid entry_type for entry ${i + 1}. Expected one of: ${validTypes.join(", ")}`);
        }

        validated.push({
          date: item.date,
          shift_label: item.shift_label || item.label || "Shift",
          start_time: item.start_time,
          end_time: item.end_time,
          entry_type: item.entry_type,
          is_overnight: Boolean(item.is_overnight),
        });
      }

      if (validated.length === 0) {
        throw new Error("No valid entries found in the JSON.");
      }

      setPreviewEntries(validated);
    } catch (err: any) {
      setError("Validation Error: " + err.message);
    }
  };

  const handleConfirm = async () => {
    if (!previewEntries) return;
    setIsConfirming(true);
    setError(null);

    try {
      const normalizedEntries = previewEntries.map((e) => {
        const lbl = e.shift_label || e.label || "Imported Shift";
        return {
          ...e,
          label: lbl,
          shift_label: lbl,
        };
      });

      await apiClient.post("/imports/confirm", { entries: normalizedEntries });
      onSuccess();
      onClose();
    } catch (err: any) {
      setError(err.message || "Failed to save confirmed entries.");
    } finally {
      setIsConfirming(false);
    }
  };

  const handleEntryChange = (index: number, field: keyof PreviewEntry, value: any) => {
    if (!previewEntries) return;
    const updated = [...previewEntries];
    updated[index] = { ...updated[index], [field]: value };
    if (field === "shift_label") {
      updated[index].label = value;
    } else if (field === "label") {
      updated[index].shift_label = value;
    }
    setPreviewEntries(updated);
  };

  const copyPrompt = () => {
    const prompt = `Please read the provided work rota schedule and extract all shift entries. Output the result ONLY as a valid JSON object matching this exact schema:

{
  "entries": [
    {
      "date": "YYYY-MM-DD",
      "shift_label": "e.g. Early Shift, Night, Off",
      "start_time": "HH:MM",
      "end_time": "HH:MM",
      "entry_type": "work",
      "is_overnight": false
    }
  ]
}

Rules:
- \`entry_type\` must be one of: "work", "leave", "off", "personal", "other".
- \`is_overnight\` must be true if the shift ends on the following calendar day.
- Do not include any markdown formatting, explanations, or text outside the JSON object. Just the raw JSON.`;
    navigator.clipboard.writeText(prompt);
    setIsCopied(true);
    setTimeout(() => setIsCopied(false), 2000);
  };

  const resetState = () => {
    setPreviewEntries(null);
    setFile(null);
    setExternalJson("");
    setError(null);
  };

  if (!isOpen) return null;

  return (
    <div className="fixed inset-0 bg-slate-950/60 backdrop-blur-xs z-50 flex items-center justify-center p-4">
      <div className="bg-white border border-[#E8E5DF] rounded-2xl max-w-2xl w-full p-6 shadow-xl space-y-4 max-h-[90vh] overflow-y-auto relative">
        <div className="flex items-center justify-between pb-3 border-b border-[#E8E5DF]">
          <h3 className="font-bold text-[#1F2223] text-base flex items-center gap-2">
            <Sparkles className="w-5 h-5 text-[#2B7A72]" />
            Import Rota Schedule
          </h3>
          <button onClick={onClose} className="text-[#959A9E] hover:text-[#1F2223]">
            <X className="w-5 h-5" />
          </button>
        </div>

        {error && (
          <div className="p-3 rounded-xl bg-rose-50 border border-rose-200 text-rose-800 text-xs font-medium">
            {error}
          </div>
        )}

        {isCheckingPremium ? (
          <div className="py-12 flex justify-center items-center">
            <Loader2 className="w-8 h-8 text-[#2B7A72] animate-spin" />
          </div>
        ) : !previewEntries ? (
          <div className="space-y-6">
            {/* Tabs */}
            <div className="flex p-1 bg-[#FAF9F6] border border-[#E8E5DF] rounded-xl overflow-hidden">
              <button
                onClick={() => { setActiveTab("manual"); setError(null); setShowCouponPrompt(false); }}
                className={`flex-1 flex flex-col items-center justify-center gap-1 p-2 text-[11px] font-bold rounded-lg transition-colors ${
                  activeTab === "manual" ? "bg-white text-[#2B7A72] shadow-xs" : "text-[#656A6D] hover:text-[#1F2223]"
                }`}
              >
                <Edit className="w-4 h-4" />
                1. Manual Entry
              </button>
              <button
                onClick={() => { setActiveTab("ai-vision"); setError(null); setShowCouponPrompt(false); }}
                className={`flex-1 flex flex-col items-center justify-center gap-1 p-2 text-[11px] font-bold rounded-lg transition-colors ${
                  activeTab === "ai-vision" ? "bg-white text-[#2B7A72] shadow-xs" : "text-[#656A6D] hover:text-[#1F2223]"
                }`}
              >
                <Sparkles className="w-4 h-4" />
                2. AI Extraction
              </button>
              <button
                onClick={() => { setActiveTab("ai-external"); setError(null); setShowCouponPrompt(false); }}
                className={`flex-1 flex flex-col items-center justify-center gap-1 p-2 text-[11px] font-bold rounded-lg transition-colors ${
                  activeTab === "ai-external" ? "bg-white text-[#2B7A72] shadow-xs" : "text-[#656A6D] hover:text-[#1F2223]"
                }`}
              >
                <Bot className="w-4 h-4" />
                3. Use Any AI Tool
              </button>
            </div>

            {/* Tab Contents */}
            {activeTab === "manual" && (
              <div className="text-center py-8 space-y-3">
                <div className="w-12 h-12 bg-[#81D8D0]/20 rounded-full flex items-center justify-center mx-auto mb-2">
                  <Edit className="w-6 h-6 text-[#1D5E57]" />
                </div>
                <h4 className="text-sm font-bold text-[#1F2223]">Enter Rota Yourself</h4>
                <p className="text-xs text-[#656A6D] max-w-sm mx-auto">
                  Close this window and use the "Add Shift Entry" button on the calendar, or use the 1-Tap Quick Assign feature for faster manual entry.
                </p>
                <button
                  onClick={onClose}
                  className="mt-4 px-4 py-2 bg-[#2B7A72] hover:bg-[#1D5E57] text-white rounded-xl text-xs font-semibold shadow-xs"
                >
                  Go to Calendar
                </button>
              </div>
            )}

            {activeTab === "ai-vision" && isPremium === true && (
              <form onSubmit={handleUpload} className="space-y-4">
                <div className="border-2 border-dashed border-[#E8E5DF] rounded-xl p-8 text-center space-y-3 bg-[#FAF9F6] relative overflow-hidden">
                  <div className="absolute top-0 right-0 bg-gradient-to-r from-[#2B7A72] to-[#81D8D0] text-white text-[9px] font-bold uppercase tracking-wider px-3 py-1 rounded-bl-xl shadow-xs">
                    Premium Active
                  </div>
                  <Upload className="w-8 h-8 text-[#2B7A72] mx-auto" />
                  <div>
                    <p className="text-xs font-semibold text-[#1F2223]">
                      Upload Rota Image, PDF, or Document
                    </p>
                    <p className="text-[11px] text-[#656A6D] mt-0.5 font-mono">Supports PNG, JPG, PDF, XLSX, CSV (Max 10MB)</p>
                  </div>
                  <input
                    type="file"
                    accept="image/*,.pdf,.xlsx,.csv"
                    onChange={(e) => setFile(e.target.files?.[0] || null)}
                    className="hidden"
                    id="rota-file-input"
                  />
                  <label
                    htmlFor="rota-file-input"
                    className="inline-block px-4 py-2 bg-white hover:bg-[#F2EFE9] border border-[#E8E5DF] rounded-xl text-xs font-semibold text-[#1D5E57] cursor-pointer transition-all shadow-xs"
                  >
                    {file ? file.name : "Select File"}
                  </label>
                </div>

                <div className="pt-2 flex justify-end">
                  <button
                    type="submit"
                    disabled={!file || isLoading}
                    className="px-4 py-2 bg-[#2B7A72] hover:bg-[#1D5E57] text-white rounded-xl text-xs font-semibold shadow-xs disabled:opacity-50 transition-all"
                  >
                    {isLoading ? "Extracting Schedule..." : "Extract & Preview"}
                  </button>
                </div>
              </form>
            )}

            {activeTab === "ai-vision" && isPremium === false && !showCouponPrompt && (
              <div className="space-y-5 py-2">
                <div className="text-center">
                  <h4 className="text-lg font-bold text-[#1F2223] tracking-tight">Upgrade to Premium</h4>
                  <p className="text-xs text-[#656A6D] mt-1.5">
                    Unlock instant AI Vision extraction. Just snap a picture of your rota and let our AI do the rest.
                  </p>
                </div>
                
                <div className="grid grid-cols-1 md:grid-cols-3 gap-3">
                  {/* Plan 1 */}
                  <div className="p-4 rounded-xl border border-[#E8E5DF] bg-[#FAF9F6] flex flex-col">
                    <h5 className="font-bold text-[#1F2223] text-sm">Basic Rota</h5>
                    <div className="mt-1 flex items-end gap-1">
                      <span className="text-lg font-bold text-[#1F2223]">Free</span>
                    </div>
                    <ul className="mt-3 space-y-2 flex-1">
                      <li className="text-[11px] text-[#656A6D] flex items-start gap-1.5"><Check className="w-3.5 h-3.5 text-[#2B7A72] shrink-0" /> Manual Calendar Entry</li>
                      <li className="text-[11px] text-[#656A6D] flex items-start gap-1.5"><Check className="w-3.5 h-3.5 text-[#2B7A72] shrink-0" /> External AI Import</li>
                    </ul>
                    <button onClick={() => setActiveTab("manual")} className="mt-4 w-full py-2 bg-white border border-[#E8E5DF] rounded-lg text-xs font-bold text-[#656A6D] hover:bg-[#F2EFE9] transition-colors">
                      Current Plan
                    </button>
                  </div>

                  {/* Plan 2 */}
                  <div className="p-4 rounded-xl border-2 border-[#81D8D0] bg-[#FAF9F6] flex flex-col relative shadow-xs">
                    <div className="absolute -top-2.5 left-1/2 -translate-x-1/2 bg-[#81D8D0] text-[#1D5E57] text-[9px] font-bold uppercase tracking-wider px-2 py-0.5 rounded-full">
                      Recommended
                    </div>
                    <h5 className="font-bold text-[#1F2223] text-sm flex items-center gap-1.5"><Star className="w-4 h-4 text-[#2B7A72]" /> Pro Assistant</h5>
                    <div className="mt-1 flex items-end gap-1">
                      <span className="text-lg font-bold text-[#1F2223]">$4.99</span>
                      <span className="text-[10px] text-[#656A6D] mb-1">/mo</span>
                    </div>
                    <ul className="mt-3 space-y-2 flex-1">
                      <li className="text-[11px] text-[#656A6D] flex items-start gap-1.5"><Check className="w-3.5 h-3.5 text-[#2B7A72] shrink-0" /> Everything in Basic</li>
                      <li className="text-[11px] font-bold text-[#1D5E57] flex items-start gap-1.5"><Check className="w-3.5 h-3.5 text-[#2B7A72] shrink-0" /> Automatic AI Vision Extraction</li>
                      <li className="text-[11px] text-[#656A6D] flex items-start gap-1.5"><Check className="w-3.5 h-3.5 text-[#2B7A72] shrink-0" /> Read Images, PDFs, Excel</li>
                    </ul>
                    <button onClick={() => setShowCouponPrompt(true)} className="mt-4 w-full py-2 bg-[#2B7A72] hover:bg-[#1D5E57] rounded-lg text-xs font-bold text-white shadow-xs transition-colors">
                      Subscribe
                    </button>
                  </div>

                  {/* Plan 3 */}
                  <div className="p-4 rounded-xl border border-[#E8E5DF] bg-[#FAF9F6] flex flex-col">
                    <h5 className="font-bold text-[#1F2223] text-sm flex items-center gap-1.5"><Crown className="w-4 h-4 text-[#6A3E94]" /> Ultimate</h5>
                    <div className="mt-1 flex items-end gap-1">
                      <span className="text-lg font-bold text-[#1F2223]">$9.99</span>
                      <span className="text-[10px] text-[#656A6D] mb-1">/mo</span>
                    </div>
                    <ul className="mt-3 space-y-2 flex-1">
                      <li className="text-[11px] text-[#656A6D] flex items-start gap-1.5"><Check className="w-3.5 h-3.5 text-[#2B7A72] shrink-0" /> Everything in Pro</li>
                      <li className="text-[11px] text-[#656A6D] flex items-start gap-1.5"><Check className="w-3.5 h-3.5 text-[#2B7A72] shrink-0" /> Advanced Team Features</li>
                      <li className="text-[11px] text-[#656A6D] flex items-start gap-1.5"><Check className="w-3.5 h-3.5 text-[#2B7A72] shrink-0" /> Multi-user Syncing</li>
                    </ul>
                    <button onClick={() => setShowCouponPrompt(true)} className="mt-4 w-full py-2 bg-white border border-[#E8E5DF] rounded-lg text-xs font-bold text-[#656A6D] hover:bg-[#F2EFE9] transition-colors">
                      Subscribe
                    </button>
                  </div>
                </div>
              </div>
            )}

            {activeTab === "ai-vision" && isPremium === false && showCouponPrompt && (
              <form onSubmit={handleRedeemCoupon} className="py-6 px-4 border border-[#E8E5DF] rounded-2xl bg-[#FAF9F6] space-y-4 max-w-sm mx-auto mt-4 shadow-sm">
                <div className="text-center">
                  <ShieldCheck className="w-8 h-8 text-[#2B7A72] mx-auto mb-2" />
                  <h4 className="font-bold text-[#1F2223]">Redeem Premium Access</h4>
                  <p className="text-[11px] text-[#656A6D] mt-1">
                    Enter your unique coupon code below to permanently unlock Premium AI extraction.
                  </p>
                </div>
                
                <div>
                  <input
                    type="text"
                    required
                    placeholder="Enter Coupon Code"
                    value={couponCode}
                    onChange={(e) => setCouponCode(e.target.value)}
                    className="w-full bg-white border border-[#E8E5DF] rounded-xl px-3 py-2 text-xs text-[#1F2223] font-mono outline-none focus:border-[#81D8D0] text-center tracking-widest uppercase"
                  />
                </div>

                <div className="flex gap-2 pt-2">
                  <button
                    type="button"
                    onClick={() => { setShowCouponPrompt(false); setError(null); setCouponCode(""); }}
                    className="flex-1 py-2 bg-white border border-[#E8E5DF] rounded-xl text-xs font-bold text-[#656A6D] hover:bg-[#F2EFE9] transition-colors"
                  >
                    Cancel
                  </button>
                  <button
                    type="submit"
                    disabled={isRedeeming || !couponCode.trim()}
                    className="flex-1 py-2 bg-[#2B7A72] hover:bg-[#1D5E57] rounded-xl text-xs font-bold text-white shadow-xs transition-colors disabled:opacity-50"
                  >
                    {isRedeeming ? "Verifying..." : "Redeem"}
                  </button>
                </div>
              </form>
            )}

            {activeTab === "ai-external" && (
              <form onSubmit={handleExternalImport} className="space-y-4">
                <div className="p-4 rounded-xl bg-[#FAF9F6] border border-[#E8E5DF] space-y-3">
                  <p className="text-xs text-[#656A6D] leading-relaxed">
                    Use any AI tool (like ChatGPT or Claude) that can read your rota. Upload your rota, paste the prompt below, and ask it to return the rota in the required format. Then copy the complete response and paste it here.
                  </p>
                  <button
                    type="button"
                    onClick={copyPrompt}
                    className="flex items-center gap-1.5 px-3 py-1.5 bg-white border border-[#E8E5DF] hover:bg-[#F2EFE9] rounded-lg text-[11px] font-bold text-[#1D5E57] transition-all shadow-xs"
                  >
                    {isCopied ? <Check className="w-3 h-3" /> : <Copy className="w-3 h-3" />}
                    {isCopied ? "Copied Prompt!" : "Copy AI Prompt"}
                  </button>
                </div>

                <div>
                  <label className="block text-[10px] font-bold text-[#656A6D] uppercase mb-1.5 flex items-center gap-1">
                    <FileJson className="w-3 h-3" /> Paste AI JSON Response
                  </label>
                  <textarea
                    rows={6}
                    placeholder={`{\n  "entries": [\n    ...\n  ]\n}`}
                    value={externalJson}
                    onChange={(e) => setExternalJson(e.target.value)}
                    className="w-full bg-white border border-[#E8E5DF] rounded-xl px-3 py-2 text-xs text-[#1F2223] font-mono outline-none focus:border-[#81D8D0] shadow-inner"
                  />
                </div>

                <div className="pt-2 flex justify-end">
                  <button
                    type="submit"
                    disabled={!externalJson.trim()}
                    className="px-4 py-2 bg-[#2B7A72] hover:bg-[#1D5E57] text-white rounded-xl text-xs font-semibold shadow-xs disabled:opacity-50 transition-all"
                  >
                    Validate & Preview
                  </button>
                </div>
              </form>
            )}
          </div>
        ) : (
          <div className="space-y-4">
            <div className="p-3 rounded-xl bg-[#81D8D0]/18 border border-[#81D8D0]/40 text-xs text-[#1D5E57]">
              <p className="font-bold flex items-center gap-1"><Check className="w-3.5 h-3.5" /> Validation Successful</p>
              <p className="text-[11px] opacity-90 mt-0.5">
                Review the {previewEntries.length} extracted shifts below. You can edit any dates or times before confirming.
              </p>
            </div>

            <div className="space-y-2 max-h-[300px] overflow-y-auto pr-1">
              {previewEntries.map((e, idx) => (
                <div key={idx} className="p-3 rounded-xl bg-[#FAF9F6] border border-[#E8E5DF] grid grid-cols-1 sm:grid-cols-4 gap-2 text-xs">
                  <div>
                    <label className="block text-[10px] font-bold text-[#656A6D] uppercase mb-0.5">Date</label>
                    <input
                      type="date"
                      value={e.date}
                      onChange={(ev) => handleEntryChange(idx, "date", ev.target.value)}
                      className="w-full bg-white border border-[#E8E5DF] rounded-lg px-2 py-1 text-xs text-[#1F2223] font-mono outline-none focus:border-[#81D8D0]"
                    />
                  </div>

                  <div>
                    <label className="block text-[10px] font-bold text-[#656A6D] uppercase mb-0.5">Label</label>
                    <input
                      type="text"
                      value={e.shift_label || e.label || ""}
                      onChange={(ev) => handleEntryChange(idx, "shift_label", ev.target.value)}
                      className="w-full bg-white border border-[#E8E5DF] rounded-lg px-2 py-1 text-xs text-[#1F2223] outline-none focus:border-[#81D8D0]"
                    />
                  </div>

                  <div>
                    <label className="block text-[10px] font-bold text-[#656A6D] uppercase mb-0.5">Start Time</label>
                    <input
                      type="time"
                      value={e.start_time}
                      onChange={(ev) => handleEntryChange(idx, "start_time", ev.target.value)}
                      className="w-full bg-white border border-[#E8E5DF] rounded-lg px-2 py-1 text-xs text-[#1F2223] font-mono outline-none focus:border-[#81D8D0]"
                    />
                  </div>

                  <div>
                    <label className="block text-[10px] font-bold text-[#656A6D] uppercase mb-0.5">End Time</label>
                    <input
                      type="time"
                      value={e.end_time}
                      onChange={(ev) => handleEntryChange(idx, "end_time", ev.target.value)}
                      className="w-full bg-white border border-[#E8E5DF] rounded-lg px-2 py-1 text-xs text-[#1F2223] font-mono outline-none focus:border-[#81D8D0]"
                    />
                  </div>
                </div>
              ))}
            </div>

            <div className="pt-2 flex justify-between gap-2.5">
              <button
                type="button"
                onClick={resetState}
                className="px-3.5 py-2 bg-[#FAF9F6] text-[#656A6D] hover:text-[#1F2223] rounded-xl text-xs font-semibold border border-[#E8E5DF]"
              >
                Go Back
              </button>

              <button
                type="button"
                onClick={handleConfirm}
                disabled={isConfirming}
                className="px-4 py-2 bg-[#2B7A72] hover:bg-[#1D5E57] text-white rounded-xl text-xs font-semibold shadow-xs disabled:opacity-50 transition-all flex items-center gap-1.5"
              >
                {isConfirming ? "Saving Entries..." : <><Check className="w-3.5 h-3.5" /> Confirm & Import to Calendar</>}
              </button>
            </div>
          </div>
        )}
      </div>
    </div>
  );
}

