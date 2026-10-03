"use client";

import { useEffect, useState } from "react";
import { useSearchParams, useRouter } from "next/navigation";
import { apiClient } from "@/lib/api-client";
import { sessionCache } from "@/lib/session-cache";
import { Users, Loader2, CheckCircle2, AlertCircle, ArrowRight } from "lucide-react";
import Link from "next/link";

export default function JoinCirclePage() {
  const searchParams = useSearchParams();
  const code = searchParams.get("code");
  const router = useRouter();

  const [status, setStatus] = useState<"processing" | "success" | "error">("processing");
  const [errorMessage, setErrorMessage] = useState("");
  const [circleName, setCircleName] = useState("");

  useEffect(() => {
    if (!code) {
      setStatus("error");
      setErrorMessage("No invite code provided in link.");
      return;
    }

    const processJoin = async () => {
      try {
        const res = await apiClient.post<{ message: string; data: { id: number; name: string } }>(
          "/invites/join",
          { invite_code: code }
        );

        setCircleName(res.data.name);
        setStatus("success");

        // Clear cached circle lists so the new circle shows up immediately
        sessionCache.invalidate("user_circles");
        sessionCache.invalidate("dashboard_overview");

        // Redirect after brief success feedback
        setTimeout(() => {
          router.replace(`/circles/${res.data.id}`);
        }, 1000);
      } catch (err: any) {
        setStatus("error");
        setErrorMessage(err.message || "Invalid or expired invite code.");
      }
    };

    processJoin();
  }, [code, router]);

  return (
    <div className="max-w-md mx-auto py-12 px-4">
      <div className="bg-white border border-[#E8E5DF] rounded-2xl p-8 text-center space-y-5 shadow-sm">
        <div className="w-14 h-14 rounded-2xl bg-[#81D8D0]/20 border border-[#81D8D0]/40 flex items-center justify-center mx-auto shadow-xs">
          <Users className="w-7 h-7 text-[#1D5E57]" />
        </div>

        {status === "processing" && (
          <div className="space-y-3">
            <h2 className="text-lg font-bold text-[#1F2223]">Joining Circle...</h2>
            <p className="text-xs text-[#656A6D]">
              Validating invite code <span className="font-mono font-bold text-[#1D5E57]">{code}</span>
            </p>
            <div className="pt-3 flex justify-center">
              <Loader2 className="w-6 h-6 text-[#2B7A72] animate-spin" />
            </div>
          </div>
        )}

        {status === "success" && (
          <div className="space-y-3">
            <div className="w-10 h-10 rounded-full bg-emerald-100 text-emerald-600 flex items-center justify-center mx-auto">
              <CheckCircle2 className="w-6 h-6" />
            </div>
            <h2 className="text-lg font-bold text-[#1F2223]">Welcome to {circleName}!</h2>
            <p className="text-xs text-[#656A6D]">
              You have successfully joined the circle. Redirecting to roster...
            </p>
          </div>
        )}

        {status === "error" && (
          <div className="space-y-4">
            <div className="w-10 h-10 rounded-full bg-rose-100 text-rose-600 flex items-center justify-center mx-auto">
              <AlertCircle className="w-6 h-6" />
            </div>
            <h2 className="text-lg font-bold text-[#1F2223]">Unable to Join Circle</h2>
            <p className="text-xs text-rose-700 bg-rose-50 border border-rose-200 rounded-xl p-3 font-medium">
              {errorMessage}
            </p>
            <div className="pt-2">
              <Link
                href="/circles"
                className="inline-flex items-center gap-2 px-4 py-2 bg-[#2B7A72] text-white rounded-xl text-xs font-semibold shadow-xs"
              >
                Go to My Circles <ArrowRight className="w-3.5 h-3.5" />
              </Link>
            </div>
          </div>
        )}
      </div>
    </div>
  );
}
