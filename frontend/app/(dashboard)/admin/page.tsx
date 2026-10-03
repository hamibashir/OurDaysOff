"use client";

import { useEffect, useState } from "react";
import { apiClient } from "@/lib/api-client";
import { useAuth } from "@/features/auth/auth-context";
import Link from "next/link";
import {
  ShieldCheck,
  ShieldAlert,
  Users,
  Star,
  Ticket,
  Circle as CircleIcon,
  Search,
  Plus,
  Check,
  X,
  Loader2,
  CalendarCheck,
  Clock,
  Sparkles,
  RefreshCw,
  ArrowLeft,
} from "lucide-react";
import { User, Circle } from "@/types/api";

interface AdminStats {
  total_users: number;
  premium_users: number;
  total_circles: number;
  total_plans: number;
  total_schedules: number;
  active_coupons: number;
}

interface CouponItem {
  id: number;
  code: string;
  is_active: boolean;
  expires_at: string | null;
  created_at: string;
}

export default function AdminPage() {
  const { user: currentUser, isLoading: isAuthLoading } = useAuth();
  const [activeTab, setActiveTab] = useState<"users" | "coupons" | "circles">("users");

  const [stats, setStats] = useState<AdminStats | null>(null);
  const [users, setUsers] = useState<User[]>([]);
  const [coupons, setCoupons] = useState<CouponItem[]>([]);
  const [circles, setCircles] = useState<any[]>([]);

  const [searchQuery, setSearchQuery] = useState("");
  const [newCouponCode, setNewCouponCode] = useState("");
  const [couponExpiry, setCouponExpiry] = useState("");
  
  const [isLoadingStats, setIsLoadingStats] = useState(true);
  const [isLoadingTab, setIsLoadingTab] = useState(false);
  const [isSubmittingCoupon, setIsSubmittingCoupon] = useState(false);
  const [actionSuccess, setActionSuccess] = useState<string | null>(null);

  const fetchStats = async () => {
    try {
      const res = await apiClient.get<{ data: AdminStats }>("/admin/stats");
      setStats(res.data);
    } catch (err) {
      console.error("Failed to load admin stats", err);
    } finally {
      setIsLoadingStats(false);
    }
  };

  const fetchUsers = async () => {
    setIsLoadingTab(true);
    try {
      const url = searchQuery ? `/admin/users?search=${encodeURIComponent(searchQuery)}` : "/admin/users";
      const res = await apiClient.get<{ data: User[] }>(url);
      setUsers(res.data || []);
    } catch (err) {
      console.error("Failed to load users", err);
    } finally {
      setIsLoadingTab(false);
    }
  };

  const fetchCoupons = async () => {
    setIsLoadingTab(true);
    try {
      const res = await apiClient.get<{ data: CouponItem[] }>("/admin/coupons");
      setCoupons(res.data || []);
    } catch (err) {
      console.error("Failed to load coupons", err);
    } finally {
      setIsLoadingTab(false);
    }
  };

  const fetchCircles = async () => {
    setIsLoadingTab(true);
    try {
      const res = await apiClient.get<{ data: any[] }>("/admin/circles");
      setCircles(res.data || []);
    } catch (err) {
      console.error("Failed to load circles", err);
    } finally {
      setIsLoadingTab(false);
    }
  };

  useEffect(() => {
    fetchStats();
  }, []);

  useEffect(() => {
    if (activeTab === "users") {
      fetchUsers();
    } else if (activeTab === "coupons") {
      fetchCoupons();
    } else if (activeTab === "circles") {
      fetchCircles();
    }
  }, [activeTab]);

  const handleSearchSubmit = (e: React.FormEvent) => {
    e.preventDefault();
    if (activeTab === "users") {
      fetchUsers();
    }
  };

  const handleToggleAdmin = async (userId: number) => {
    try {
      await apiClient.put(`/admin/users/${userId}/toggle-admin`);
      setActionSuccess("Updated user administrator status.");
      setTimeout(() => setActionSuccess(null), 3000);
      fetchUsers();
      fetchStats();
    } catch (err: any) {
      alert("Failed to toggle admin status: " + (err.message || "Unknown error"));
    }
  };

  const handleTogglePremium = async (userId: number) => {
    try {
      await apiClient.put(`/admin/users/${userId}/toggle-premium`);
      setActionSuccess("Updated user premium status.");
      setTimeout(() => setActionSuccess(null), 3000);
      fetchUsers();
      fetchStats();
    } catch (err: any) {
      alert("Failed to toggle premium: " + (err.message || "Unknown error"));
    }
  };

  const handleCreateCoupon = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!newCouponCode.trim()) return;

    setIsSubmittingCoupon(true);
    try {
      await apiClient.post("/admin/coupons", {
        code: newCouponCode,
        expires_at: couponExpiry || null,
      });
      setNewCouponCode("");
      setCouponExpiry("");
      setActionSuccess("New coupon created successfully!");
      setTimeout(() => setActionSuccess(null), 3000);
      fetchCoupons();
      fetchStats();
    } catch (err: any) {
      alert("Failed to create coupon: " + (err.message || "Unknown error"));
    } finally {
      setIsSubmittingCoupon(false);
    }
  };

  const handleToggleCoupon = async (couponId: number) => {
    try {
      await apiClient.put(`/admin/coupons/${couponId}/toggle`);
      fetchCoupons();
      fetchStats();
    } catch (err: any) {
      alert("Failed to toggle coupon status: " + (err.message || "Unknown error"));
    }
  };

  if (!isAuthLoading && !currentUser?.is_admin) {
    return (
      <div className="max-w-md mx-auto py-16 text-center space-y-5">
        <div className="w-16 h-16 rounded-2xl bg-rose-50 border border-rose-200 text-rose-600 flex items-center justify-center mx-auto shadow-sm">
          <ShieldAlert className="w-8 h-8" />
        </div>
        <div className="space-y-2">
          <h2 className="text-xl font-bold text-[#1F2223]">Access Restricted</h2>
          <p className="text-xs text-[#656A6D] leading-relaxed">
            You do not have system administrator privileges. Access to the system control panel is restricted to authorized administrative accounts only.
          </p>
        </div>
        <div>
          <Link
            href="/dashboard"
            className="inline-flex items-center gap-2 px-4 py-2 bg-[#2B7A72] text-white text-xs font-semibold rounded-xl hover:bg-[#1D5E57] transition-all shadow-xs"
          >
            <ArrowLeft className="w-4 h-4" /> Return to Dashboard
          </Link>
        </div>
      </div>
    );
  }

  return (
    <div className="max-w-6xl mx-auto space-y-6 md:space-y-8">
      {/* Header Banner */}
      <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-4 bg-white border border-[#E8E5DF] rounded-2xl p-5 md:p-6 shadow-xs">
        <div className="flex items-start gap-3.5">
          <div className="w-10 h-10 rounded-xl bg-purple-500/10 border border-purple-500/30 flex items-center justify-center shrink-0 mt-0.5 shadow-xs">
            <ShieldCheck className="w-5 h-5 text-purple-700" />
          </div>
          <div>
            <div className="flex items-center gap-2">
              <h1 className="text-xl font-bold text-[#1F2223] tracking-tight">
                System Admin Control Panel
              </h1>
              <span className="inline-flex items-center gap-1 px-2 py-0.5 rounded-full bg-purple-100 text-purple-800 text-[10px] font-mono font-semibold">
                System Admin
              </span>
            </div>
            <p className="text-xs text-[#656A6D] mt-1 leading-relaxed">
              Global system monitoring, user account controls, premium subscriptions, and promo coupon management.
            </p>
          </div>
        </div>

        <button
          onClick={() => {
            fetchStats();
            if (activeTab === "users") fetchUsers();
            if (activeTab === "coupons") fetchCoupons();
            if (activeTab === "circles") fetchCircles();
          }}
          className="px-3.5 py-2 bg-[#FAF9F6] hover:bg-[#F2EFE9] text-[#1F2223] border border-[#E8E5DF] rounded-xl text-xs font-semibold transition-all shadow-xs flex items-center gap-1.5 shrink-0 cursor-pointer"
        >
          <RefreshCw className="w-3.5 h-3.5 text-[#2B7A72]" /> Refresh System Data
        </button>
      </div>

      {actionSuccess && (
        <div className="p-3.5 rounded-xl bg-emerald-50 border border-emerald-200 text-emerald-800 text-xs font-semibold flex items-center gap-2 shadow-xs">
          <Check className="w-4 h-4 text-emerald-600" /> {actionSuccess}
        </div>
      )}

      {/* Overview Analytics Row */}
      <div className="grid grid-cols-2 lg:grid-cols-4 gap-3.5 md:gap-4">
        <div className="bg-white border border-[#E8E5DF] rounded-xl p-4 space-y-1.5 shadow-xs">
          <div className="flex items-center justify-between text-[#656A6D]">
            <span className="text-[10px] font-bold uppercase tracking-wider">Total Users</span>
            <Users className="w-4 h-4 text-[#2B7A72]" />
          </div>
          <div className="text-2xl font-bold text-[#1F2223] font-mono">
            {isLoadingStats ? "..." : stats?.total_users || 0}
          </div>
          <p className="text-[11px] text-[#2B7A72] font-semibold">Registered Accounts</p>
        </div>

        <div className="bg-white border border-[#E8E5DF] rounded-xl p-4 space-y-1.5 shadow-xs">
          <div className="flex items-center justify-between text-[#656A6D]">
            <span className="text-[10px] font-bold uppercase tracking-wider">Premium Users</span>
            <Star className="w-4 h-4 text-[#D7D982]" />
          </div>
          <div className="text-2xl font-bold text-[#1F2223] font-mono">
            {isLoadingStats ? "..." : stats?.premium_users || 0}
          </div>
          <p className="text-[11px] text-[#2B7A72] font-semibold">Pro Subscriptions Active</p>
        </div>

        <div className="bg-white border border-[#E8E5DF] rounded-xl p-4 space-y-1.5 shadow-xs">
          <div className="flex items-center justify-between text-[#656A6D]">
            <span className="text-[10px] font-bold uppercase tracking-wider">Active Circles</span>
            <CircleIcon className="w-4 h-4 text-[#6A3E94]" />
          </div>
          <div className="text-2xl font-bold text-[#1F2223] font-mono">
            {isLoadingStats ? "..." : stats?.total_circles || 0}
          </div>
          <p className="text-[11px] text-[#6A3E94] font-semibold">Platform Teams</p>
        </div>

        <div className="bg-white border border-[#E8E5DF] rounded-xl p-4 space-y-1.5 shadow-xs">
          <div className="flex items-center justify-between text-[#656A6D]">
            <span className="text-[10px] font-bold uppercase tracking-wider">Active Coupons</span>
            <Ticket className="w-4 h-4 text-[#D99E82]" />
          </div>
          <div className="text-2xl font-bold text-[#1F2223] font-mono">
            {isLoadingStats ? "..." : stats?.active_coupons || 0}
          </div>
          <p className="text-[11px] text-[#D99E82] font-semibold">Redeemable Codes</p>
        </div>
      </div>

      {/* Main Tab Controls & Content Box */}
      <div className="bg-white border border-[#E8E5DF] rounded-2xl p-5 md:p-6 space-y-5 shadow-xs">
        {/* Section Tabs */}
        <div className="flex p-1 bg-[#FAF9F6] border border-[#E8E5DF] rounded-xl overflow-hidden max-w-md">
          <button
            onClick={() => setActiveTab("users")}
            className={`flex-1 flex items-center justify-center gap-1.5 p-2 text-xs font-bold rounded-lg transition-colors cursor-pointer ${
              activeTab === "users" ? "bg-white text-[#2B7A72] shadow-xs" : "text-[#656A6D] hover:text-[#1F2223]"
            }`}
          >
            <Users className="w-3.5 h-3.5" />
            Users Control
          </button>

          <button
            onClick={() => setActiveTab("coupons")}
            className={`flex-1 flex items-center justify-center gap-1.5 p-2 text-xs font-bold rounded-lg transition-colors cursor-pointer ${
              activeTab === "coupons" ? "bg-white text-[#2B7A72] shadow-xs" : "text-[#656A6D] hover:text-[#1F2223]"
            }`}
          >
            <Ticket className="w-3.5 h-3.5" />
            Coupons & Promo
          </button>

          <button
            onClick={() => setActiveTab("circles")}
            className={`flex-1 flex items-center justify-center gap-1.5 p-2 text-xs font-bold rounded-lg transition-colors cursor-pointer ${
              activeTab === "circles" ? "bg-white text-[#2B7A72] shadow-xs" : "text-[#656A6D] hover:text-[#1F2223]"
            }`}
          >
            <CircleIcon className="w-3.5 h-3.5" />
            Circles Monitor
          </button>
        </div>

        {/* TAB 1: USERS CONTROL */}
        {activeTab === "users" && (
          <div className="space-y-4">
            <form onSubmit={handleSearchSubmit} className="flex gap-2">
              <div className="relative flex-1">
                <Search className="w-4 h-4 text-[#959A9E] absolute left-3 top-3" />
                <input
                  type="text"
                  placeholder="Search user by name, email, or handle..."
                  value={searchQuery}
                  onChange={(e) => setSearchQuery(e.target.value)}
                  className="w-full pl-9 pr-3 py-2 bg-[#FAF9F6] border border-[#E8E5DF] focus:border-[#81D8D0] rounded-xl text-xs outline-none font-medium"
                />
              </div>
              <button
                type="submit"
                className="px-4 py-2 bg-[#2B7A72] hover:bg-[#1D5E57] text-white rounded-xl text-xs font-semibold shadow-xs"
              >
                Search
              </button>
            </form>

            {isLoadingTab ? (
              <div className="py-8 text-center flex justify-center">
                <Loader2 className="w-6 h-6 text-[#2B7A72] animate-spin" />
              </div>
            ) : (
              <div className="overflow-x-auto border border-[#E8E5DF] rounded-xl">
                <table className="w-full text-left border-collapse">
                  <thead>
                    <tr className="bg-[#FAF9F6] border-b border-[#E8E5DF] text-[10px] font-bold uppercase tracking-wider text-[#656A6D]">
                      <th className="p-3">User</th>
                      <th className="p-3">Email</th>
                      <th className="p-3">Handle</th>
                      <th className="p-3">Role</th>
                      <th className="p-3">Subscription</th>
                      <th className="p-3 text-right">Actions</th>
                    </tr>
                  </thead>
                  <tbody className="divide-y divide-[#E8E5DF] text-xs">
                    {users.map((u) => (
                      <tr key={u.id} className="hover:bg-[#FAF9F6]/60 transition-colors">
                        <td className="p-3 font-semibold text-[#1F2223] flex items-center gap-2">
                          <div className="w-7 h-7 rounded-full bg-gradient-to-br from-[#81D8D0] to-[#AE82D9] text-white font-bold flex items-center justify-center text-xs shrink-0">
                            {u.name.charAt(0)}
                          </div>
                          <span>{u.name}</span>
                        </td>
                        <td className="p-3 text-[#656A6D] font-mono">{u.email}</td>
                        <td className="p-3 text-[#656A6D] font-mono">{u.handle ? `@${u.handle}` : "—"}</td>
                        <td className="p-3">
                          {u.is_admin ? (
                            <span className="inline-flex items-center gap-1 px-2 py-0.5 rounded-full bg-purple-100 text-purple-800 text-[10px] font-bold">
                              <ShieldCheck className="w-3 h-3 text-purple-700" /> Admin
                            </span>
                          ) : (
                            <span className="inline-flex items-center gap-1 px-2 py-0.5 rounded-full bg-zinc-100 text-zinc-600 text-[10px] font-medium">
                              User
                            </span>
                          )}
                        </td>
                        <td className="p-3">
                          {u.is_premium ? (
                            <span className="inline-flex items-center gap-1 px-2 py-0.5 rounded-full bg-emerald-100 text-emerald-800 text-[10px] font-bold">
                              <Star className="w-3 h-3 fill-emerald-600 text-emerald-600" /> Premium Active
                            </span>
                          ) : (
                            <span className="inline-flex items-center gap-1 px-2 py-0.5 rounded-full bg-zinc-100 text-zinc-600 text-[10px] font-semibold">
                              Free Plan
                            </span>
                          )}
                        </td>
                        <td className="p-3 text-right">
                          <div className="flex items-center justify-end gap-1.5">
                            <button
                              onClick={() => handleToggleAdmin(u.id)}
                              disabled={u.id === currentUser?.id}
                              title={u.id === currentUser?.id ? "You cannot revoke your own admin rights" : undefined}
                              className={`px-2.5 py-1 rounded-lg text-[11px] font-bold transition-all shadow-2xs cursor-pointer ${
                                u.id === currentUser?.id
                                  ? "opacity-50 cursor-not-allowed bg-zinc-100 text-zinc-500"
                                  : u.is_admin
                                  ? "bg-purple-50 text-purple-700 hover:bg-purple-100 border border-purple-200"
                                  : "bg-purple-600 text-white hover:bg-purple-700"
                              }`}
                            >
                              {u.is_admin ? "Revoke Admin" : "Make Admin"}
                            </button>
                            <button
                              onClick={() => handleTogglePremium(u.id)}
                              className={`px-2.5 py-1 rounded-lg text-[11px] font-bold transition-all shadow-2xs cursor-pointer ${
                                u.is_premium
                                  ? "bg-rose-50 text-rose-700 hover:bg-rose-100 border border-rose-200"
                                  : "bg-emerald-50 text-emerald-700 hover:bg-emerald-100 border border-emerald-200"
                              }`}
                            >
                              {u.is_premium ? "Revoke Pro" : "Grant Pro"}
                            </button>
                          </div>
                        </td>
                      </tr>
                    ))}
                  </tbody>
                </table>
              </div>
            )}
          </div>
        )}

        {/* TAB 2: COUPONS & PROMO */}
        {activeTab === "coupons" && (
          <div className="space-y-6">
            <form onSubmit={handleCreateCoupon} className="p-4 bg-[#FAF9F6] border border-[#E8E5DF] rounded-xl space-y-3">
              <h4 className="text-xs font-bold text-[#1F2223] flex items-center gap-1.5">
                <Plus className="w-4 h-4 text-[#2B7A72]" /> Create New Coupon Code
              </h4>
              <div className="grid grid-cols-1 sm:grid-cols-2 gap-3">
                <div>
                  <label className="block text-[10px] font-bold uppercase tracking-wider text-[#656A6D] mb-1">
                    Coupon Code
                  </label>
                  <input
                    type="text"
                    required
                    placeholder="e.g. WELCOME100, PROMO2026"
                    value={newCouponCode}
                    onChange={(e) => setNewCouponCode(e.target.value)}
                    className="w-full bg-white border border-[#E8E5DF] focus:border-[#81D8D0] rounded-xl px-3 py-2 text-xs font-mono outline-none font-bold tracking-widest uppercase"
                  />
                </div>
                <div>
                  <label className="block text-[10px] font-bold uppercase tracking-wider text-[#656A6D] mb-1">
                    Expiry Date (Optional)
                  </label>
                  <input
                    type="date"
                    value={couponExpiry}
                    onChange={(e) => setCouponExpiry(e.target.value)}
                    className="w-full bg-white border border-[#E8E5DF] focus:border-[#81D8D0] rounded-xl px-3 py-2 text-xs font-mono outline-none font-semibold cursor-pointer"
                  />
                </div>
              </div>
              <div className="flex justify-end pt-1">
                <button
                  type="submit"
                  disabled={isSubmittingCoupon || !newCouponCode.trim()}
                  className="px-4 py-2 bg-[#2B7A72] hover:bg-[#1D5E57] text-white rounded-xl text-xs font-semibold shadow-xs disabled:opacity-50"
                >
                  {isSubmittingCoupon ? "Saving..." : "Create Coupon"}
                </button>
              </div>
            </form>

            {isLoadingTab ? (
              <div className="py-8 text-center flex justify-center">
                <Loader2 className="w-6 h-6 text-[#2B7A72] animate-spin" />
              </div>
            ) : (
              <div className="overflow-x-auto border border-[#E8E5DF] rounded-xl">
                <table className="w-full text-left border-collapse">
                  <thead>
                    <tr className="bg-[#FAF9F6] border-b border-[#E8E5DF] text-[10px] font-bold uppercase tracking-wider text-[#656A6D]">
                      <th className="p-3">Coupon Code</th>
                      <th className="p-3">Status</th>
                      <th className="p-3">Expires At</th>
                      <th className="p-3 text-right">Toggle Active</th>
                    </tr>
                  </thead>
                  <tbody className="divide-y divide-[#E8E5DF] text-xs">
                    {coupons.map((c) => (
                      <tr key={c.id} className="hover:bg-[#FAF9F6]/60 transition-colors">
                        <td className="p-3 font-mono font-bold text-[#1D5E57] tracking-wider">{c.code}</td>
                        <td className="p-3">
                          {c.is_active ? (
                            <span className="inline-flex items-center gap-1 px-2 py-0.5 rounded-full bg-emerald-100 text-emerald-800 text-[10px] font-bold">
                              <Check className="w-3 h-3 text-emerald-600" /> Active
                            </span>
                          ) : (
                            <span className="inline-flex items-center gap-1 px-2 py-0.5 rounded-full bg-rose-100 text-rose-800 text-[10px] font-bold">
                              <X className="w-3 h-3 text-rose-600" /> Disabled
                            </span>
                          )}
                        </td>
                        <td className="p-3 text-[#656A6D] font-mono">{c.expires_at ? c.expires_at.slice(0, 10) : "Never"}</td>
                        <td className="p-3 text-right">
                          <button
                            onClick={() => handleToggleCoupon(c.id)}
                            className={`px-3 py-1 rounded-lg text-[11px] font-bold transition-all shadow-2xs ${
                              c.is_active
                                ? "bg-rose-50 text-rose-700 hover:bg-rose-100 border border-rose-200"
                                : "bg-emerald-50 text-emerald-700 hover:bg-emerald-100 border border-emerald-200"
                            }`}
                          >
                            {c.is_active ? "Deactivate" : "Activate"}
                          </button>
                        </td>
                      </tr>
                    ))}
                  </tbody>
                </table>
              </div>
            )}
          </div>
        )}

        {/* TAB 3: CIRCLES MONITOR */}
        {activeTab === "circles" && (
          <div className="space-y-4">
            {isLoadingTab ? (
              <div className="py-8 text-center flex justify-center">
                <Loader2 className="w-6 h-6 text-[#2B7A72] animate-spin" />
              </div>
            ) : (
              <div className="overflow-x-auto border border-[#E8E5DF] rounded-xl">
                <table className="w-full text-left border-collapse">
                  <thead>
                    <tr className="bg-[#FAF9F6] border-b border-[#E8E5DF] text-[10px] font-bold uppercase tracking-wider text-[#656A6D]">
                      <th className="p-3">Circle Name</th>
                      <th className="p-3">Handle</th>
                      <th className="p-3">Owner</th>
                      <th className="p-3">Members</th>
                      <th className="p-3">Created Date</th>
                    </tr>
                  </thead>
                  <tbody className="divide-y divide-[#E8E5DF] text-xs">
                    {circles.map((c) => (
                      <tr key={c.id} className="hover:bg-[#FAF9F6]/60 transition-colors">
                        <td className="p-3 font-bold text-[#1F2223]">{c.name}</td>
                        <td className="p-3 text-[#656A6D] font-mono">{c.handle ? `@${c.handle}` : "—"}</td>
                        <td className="p-3 text-[#656A6D]">
                          {c.owner ? `${c.owner.name} (${c.owner.email})` : "—"}
                        </td>
                        <td className="p-3 font-mono font-bold text-[#1D5E57]">{c.members_count || 0} members</td>
                        <td className="p-3 text-[#656A6D] font-mono">{c.created_at ? c.created_at.slice(0, 10) : "—"}</td>
                      </tr>
                    ))}
                  </tbody>
                </table>
              </div>
            )}
          </div>
        )}
      </div>
    </div>
  );
}
