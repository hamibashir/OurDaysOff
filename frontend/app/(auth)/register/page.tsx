"use client";

import { useState } from "react";
import Link from "next/link";
import { useRouter } from "next/navigation";
import { useAuth } from "@/features/auth/auth-context";
import { Calendar, Lock, Mail, User as UserIcon, AtSign, ArrowRight } from "lucide-react";

export default function RegisterPage() {
  const [formData, setFormData] = useState({
    name: "",
    email: "",
    password: "",
    handle: "",
  });
  const [error, setError] = useState<string | null>(null);
  const [isSubmitting, setIsSubmitting] = useState(false);
  const { register } = useAuth();
  const router = useRouter();

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    setError(null);
    setIsSubmitting(true);

    try {
      await register(formData);
      router.push("/dashboard");
    } catch (err: any) {
      setError(err.message || "Registration failed. Please check your inputs.");
    } finally {
      setIsSubmitting(false);
    }
  };

  return (
    <div className="min-h-screen flex items-center justify-center bg-[#FAF9F6] text-[#1F2223] p-4 font-sans">
      <div className="w-full max-w-md bg-white border border-[#E8E5DF] rounded-2xl shadow-xs p-8 space-y-6">
        <div className="flex flex-col items-center text-center">
          <div className="w-12 h-12 rounded-2xl bg-gradient-to-br from-[#81D8D0] to-[#AE82D9] flex items-center justify-center shadow-xs mb-3">
            <Calendar className="w-6 h-6 text-white" />
          </div>
          <h1 className="text-xl font-bold tracking-tight text-[#1F2223]">Create Account</h1>
          <p className="text-xs text-[#656A6D] mt-1 leading-relaxed">Join Our Days Off & sync availability effortlessly</p>
        </div>

        {error && (
          <div className="p-3.5 rounded-xl bg-rose-50 border border-rose-200 text-rose-800 text-xs font-medium flex items-center gap-2.5">
            <div className="w-1.5 h-1.5 rounded-full bg-rose-500 shrink-0" />
            <span>{error}</span>
          </div>
        )}

        <form onSubmit={handleSubmit} className="space-y-4">
          <div>
            <label className="block text-[11px] font-bold uppercase tracking-wider text-[#656A6D] mb-1">
              Full Name
            </label>
            <div className="relative">
              <UserIcon className="absolute left-3.5 top-3 w-4 h-4 text-[#959A9E]" />
              <input
                type="text"
                required
                value={formData.name}
                onChange={(e) => setFormData({ ...formData, name: e.target.value })}
                placeholder="Alice Johnson"
                className="w-full bg-[#FAF9F6] border border-[#E8E5DF] focus:border-[#81D8D0] text-[#1F2223] placeholder-[#959A9E] rounded-xl py-2.5 pl-10 pr-3 text-xs outline-none font-medium"
              />
            </div>
          </div>

          <div>
            <label className="block text-[11px] font-bold uppercase tracking-wider text-[#656A6D] mb-1">
              Email Address
            </label>
            <div className="relative">
              <Mail className="absolute left-3.5 top-3 w-4 h-4 text-[#959A9E]" />
              <input
                type="email"
                required
                value={formData.email}
                onChange={(e) => setFormData({ ...formData, email: e.target.value })}
                placeholder="alice@example.com"
                className="w-full bg-[#FAF9F6] border border-[#E8E5DF] focus:border-[#81D8D0] text-[#1F2223] placeholder-[#959A9E] rounded-xl py-2.5 pl-10 pr-3 text-xs outline-none font-medium"
              />
            </div>
          </div>

          <div>
            <label className="block text-[11px] font-bold uppercase tracking-wider text-[#656A6D] mb-1">
              Public Handle (Optional)
            </label>
            <div className="relative">
              <AtSign className="absolute left-3.5 top-3 w-4 h-4 text-[#959A9E]" />
              <input
                type="text"
                value={formData.handle}
                onChange={(e) => setFormData({ ...formData, handle: e.target.value })}
                placeholder="alice_j"
                className="w-full bg-[#FAF9F6] border border-[#E8E5DF] focus:border-[#81D8D0] text-[#1F2223] placeholder-[#959A9E] rounded-xl py-2.5 pl-10 pr-3 text-xs outline-none font-medium"
              />
            </div>
          </div>

          <div>
            <label className="block text-[11px] font-bold uppercase tracking-wider text-[#656A6D] mb-1">
              Password
            </label>
            <div className="relative">
              <Lock className="absolute left-3.5 top-3 w-4 h-4 text-[#959A9E]" />
              <input
                type="password"
                required
                minLength={8}
                value={formData.password}
                onChange={(e) => setFormData({ ...formData, password: e.target.value })}
                placeholder="Minimum 8 characters"
                className="w-full bg-[#FAF9F6] border border-[#E8E5DF] focus:border-[#81D8D0] text-[#1F2223] placeholder-[#959A9E] rounded-xl py-2.5 pl-10 pr-3 text-xs outline-none font-medium"
              />
            </div>
          </div>

          <button
            type="submit"
            disabled={isSubmitting}
            className="w-full py-2.5 px-4 mt-2 bg-[#2B7A72] hover:bg-[#1D5E57] text-white font-semibold rounded-xl text-xs transition-all shadow-xs flex items-center justify-center gap-2 disabled:opacity-50 disabled:cursor-not-allowed"
          >
            {isSubmitting ? (
              <div className="w-4 h-4 border-2 border-white/30 border-t-white rounded-full animate-spin" />
            ) : (
              <>
                Create Account
                <ArrowRight className="w-3.5 h-3.5 text-[#D7D982]" />
              </>
            )}
          </button>
        </form>

        <div className="pt-4 border-t border-[#E8E5DF] text-center">
          <p className="text-xs text-[#656A6D]">
            Already have an account?{" "}
            <Link href="/login" className="font-semibold text-[#2B7A72] hover:underline">
              Sign In
            </Link>
          </p>
        </div>
      </div>
    </div>
  );
}
