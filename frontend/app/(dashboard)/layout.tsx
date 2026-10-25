"use client";

import { useEffect, useState, useRef } from "react";
import { useRouter, usePathname } from "next/navigation";
import Link from "next/link";
import { useAuth } from "@/features/auth/auth-context";
import { NotificationCenter } from "@/features/notifications/components/notification-center";
import {
  Calendar,
  Clock,
  Users,
  Sliders,
  CalendarCheck,
  User as UserIcon,
  LogOut,
  Sparkles,
  Smartphone,
  Bell,
  ShieldCheck,
} from "lucide-react";

export default function DashboardLayout({
  children,
}: {
  children: React.ReactNode;
}) {
  const { user, isLoading, logout } = useAuth();
  const router = useRouter();
  const pathname = usePathname();
  const [isPageTransitioning, setIsPageTransitioning] = useState(false);
  const mainContainerRef = useRef<HTMLInputElement | HTMLElement | null>(null);

  useEffect(() => {
    setIsPageTransitioning(true);
    const timer = setTimeout(() => setIsPageTransitioning(false), 80);
    if (mainContainerRef.current) {
      mainContainerRef.current.scrollTop = 0;
    }
    if (typeof window !== "undefined") {
      window.scrollTo({ top: 0, left: 0, behavior: "instant" });
    }
    return () => clearTimeout(timer);
  }, [pathname]);

  useEffect(() => {
    if (!isLoading && !user) {
      router.replace("/login");
    }
  }, [user, isLoading, router]);

  if (isLoading || !user) {
    return (
      <div className="min-h-screen bg-[#FAF9F6] flex items-center justify-center">
        <div className="w-8 h-8 border-2 border-[#81D8D0] border-t-transparent rounded-full animate-spin" />
      </div>
    );
  }

  const navItems = [
    { name: "Dashboard", href: "/dashboard", icon: Calendar },
    { name: "My Schedule", href: "/schedule", icon: Clock },
    { name: "Circles", href: "/circles", icon: Users },
    { name: "Compare", href: "/compare", icon: Sliders },
    { name: "Plans", href: "/plans", icon: CalendarCheck },
    { name: "Profile", href: "/profile", icon: UserIcon },
    ...(user?.is_admin ? [{ name: "Admin Panel", href: "/admin", icon: ShieldCheck }] : []),
  ];

  const mobileNavItems = [
    { name: "Dashboard", href: "/dashboard", icon: Calendar },
    { name: "Schedule", href: "/schedule", icon: Clock },
    { name: "Circles", href: "/circles", icon: Users },
    { name: "Compare", href: "/compare", icon: Sliders },
    { name: "Plans", href: "/plans", icon: CalendarCheck },
    ...(user?.is_admin ? [{ name: "Admin", href: "/admin", icon: ShieldCheck }] : []),
  ];

  return (
    <div className="min-h-screen flex bg-[#FAF9F6] text-[#1F2223] font-sans selection:bg-[#81D8D0]/30">
      {/* Route Transition Top Progress Indicator */}
      {isPageTransitioning && (
        <div className="fixed top-0 left-0 right-0 h-0.5 bg-gradient-to-r from-[#81D8D0] via-[#D7D982] to-[#AE82D9] animate-pulse z-50" />
      )}

      {/* Desktop / Tablet Compact Left Sidebar */}
      <aside className="w-52 bg-white border-r border-[#E8E5DF] hidden md:flex flex-col shrink-0 sticky top-0 h-screen z-40">
        {/* Brand Header */}
        <div className="p-4 border-b border-[#E8E5DF]">
          <Link href="/dashboard" className="flex items-center gap-2.5 group">
            <div className="w-8.5 h-8.5 rounded-xl bg-gradient-to-br from-[#81D8D0] to-[#AE82D9] flex items-center justify-center shadow-xs transition-transform group-hover:scale-105 shrink-0">
              <Calendar className="w-4.5 h-4.5 text-white" />
            </div>
            <div className="min-w-0 flex-1">
              <h2 className="font-bold text-sm text-[#1F2223] tracking-tight leading-none truncate">Our Days Off</h2>
              <p className="text-[10px] text-[#656A6D] font-medium mt-0.5 truncate">Schedule Coordination</p>
            </div>
          </Link>
        </div>

        {/* Navigation Destination Items */}
        <nav className="flex-1 p-3 space-y-1 overflow-y-auto">
          {navItems.map((item) => {
            const Icon = item.icon;
            const isActive = pathname === item.href || (item.href !== "/dashboard" && pathname.startsWith(`${item.href}`));

            return (
              <Link
                key={item.name}
                href={item.href}
                className={`flex items-center gap-2.5 px-3 py-2 rounded-xl text-xs transition-all outline-none focus:outline-none focus-visible:outline-none focus:ring-0 focus-visible:ring-0 select-none ${
                  isActive
                    ? "bg-[#81D8D0]/20 text-[#1D5E57] font-bold border border-[#81D8D0]/50 shadow-2xs"
                    : "text-[#656A6D] hover:text-[#1F2223] hover:bg-[#FAF9F6] font-medium"
                }`}
              >
                <Icon className={`w-4 h-4 shrink-0 ${isActive ? "text-[#23756C]" : "text-[#959A9E]"}`} />
                <span className="truncate">{item.name}</span>
              </Link>
            );
          })}
        </nav>

        {/* User Card & Logout Footer */}
        <div className="p-3 border-t border-[#E8E5DF] bg-[#FAF9F6]/60">
          <div className="flex items-center justify-between gap-2 p-2 bg-white border border-[#E8E5DF] rounded-xl shadow-2xs">
            <div className="min-w-0 flex-1">
              <p className="text-xs font-bold text-[#1F2223] truncate leading-none">{user.name}</p>
              <p className="text-[10px] text-[#656A6D] truncate mt-0.5">@{user.handle || "user"}</p>
            </div>
            <button
              onClick={() => logout()}
              title="Sign Out"
              className="p-1.5 hover:bg-rose-50 hover:text-rose-600 text-[#959A9E] rounded-lg transition-colors shrink-0 outline-none focus:outline-none focus:ring-0"
            >
              <LogOut className="w-3.5 h-3.5" />
            </button>
          </div>
        </div>
      </aside>

      {/* Main Workspace Viewport Column */}
      <div className="flex-1 flex flex-col min-w-0 relative">
        {/* Top Header Bar */}
        <header className="h-14 border-b border-[#E8E5DF] px-4 md:px-6 flex items-center justify-between bg-white/95 backdrop-blur-md sticky top-0 z-30">
          <div className="flex items-center gap-3">
            <span className="inline-flex items-center gap-1.5 px-2.5 py-1 rounded-lg bg-[#81D8D0]/18 border border-[#81D8D0]/40 text-[#1D5E57] text-[11px] font-mono font-medium">
              <Sparkles className="w-3.5 h-3.5 text-[#2B7A72]" />
              @{user.handle || "friend"}
            </span>
          </div>

          <div className="flex items-center gap-3">
            <NotificationCenter />
            <Link
              href="/profile"
              className="w-7.5 h-7.5 rounded-full bg-gradient-to-br from-[#81D8D0] to-[#AE82D9] flex items-center justify-center font-bold text-xs text-white shadow-xs hover:opacity-90 transition-opacity outline-none focus:outline-none focus:ring-0"
              title="View Profile"
            >
              {user.name.charAt(0)}
            </Link>
          </div>
        </header>

        {/* Main Content Area */}
        <main ref={mainContainerRef as any} className="flex-1 p-4 sm:p-6 md:p-8 pb-24 md:pb-8 overflow-y-auto max-w-7xl w-full">
          {children}
        </main>
      </div>

      {/* Mobile Modern Floating Dock (<768px) */}
      <div className="fixed bottom-3 sm:bottom-4 inset-x-3 max-w-lg mx-auto z-50 md:hidden">
        <nav className="bg-white/90 backdrop-blur-xl border border-white/80 dark:border-white/10 rounded-2xl sm:rounded-3xl p-1.5 shadow-[0_12px_32px_-4px_rgba(0,0,0,0.08),0_4px_12px_-2px_rgba(0,0,0,0.04)] ring-1 ring-[#1F2223]/[0.05] flex items-center justify-around">
          {mobileNavItems.map((item) => {
            const Icon = item.icon;
            const isActive = pathname === item.href || (item.href !== "/dashboard" && pathname.startsWith(`${item.href}`));

            return (
              <Link
                key={item.name}
                href={item.href}
                className={`relative flex flex-col items-center justify-center py-2 px-2 rounded-xl transition-all duration-200 outline-none focus:outline-none select-none active:scale-95 flex-1 min-w-0 ${
                  isActive
                    ? "bg-[#81D8D0]/18 text-[#144A43] font-semibold"
                    : "text-[#707579] hover:text-[#1F2223] font-medium hover:bg-black/[0.02]"
                }`}
              >
                <div className="relative">
                  <Icon
                    className={`w-[18px] h-[18px] transition-transform duration-200 ${
                      isActive ? "text-[#1B635A] scale-105 stroke-[2.2]" : "text-[#8E9398] stroke-[1.8]"
                    }`}
                  />
                </div>
                <span className="text-[10.5px] leading-tight tracking-tight mt-1 truncate max-w-full">
                  {item.name}
                </span>
                {/* Active Indicator Micro-Pill */}
                <span
                  className={`absolute -bottom-0.5 w-1 h-1 rounded-full transition-all duration-300 ${
                    isActive ? "bg-[#23756C] opacity-100 scale-100" : "opacity-0 scale-50"
                  }`}
                />
              </Link>
            );
          })}
        </nav>
      </div>
    </div>
  );
}

