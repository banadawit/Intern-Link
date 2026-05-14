"use client";

import { useEffect, useState } from "react";
import {
  LayoutDashboard,
  ClipboardList,
  MessageSquare,
  MessagesSquare,
  Building,
  FileCheck,
  LogOut,
  GraduationCap,
  Settings,
  Activity,
  Crown,
  Calendar,
} from "lucide-react";
import Link from "next/link";
import { usePathname, useRouter } from "next/navigation";
import { cn } from "@/lib/utils";
import { useAuth } from "@/lib/hooks/useAuth";
import LogoutModal from "@/components/common/LogoutModal";
import SupportLink from "@/components/shared/SupportLink";
import api from "@/lib/api/client";
import { useChatStore } from "@/lib/store/chatStore";

const StudentSidebar = () => {
  const pathname = usePathname();
  const router = useRouter();
  const { user, logout } = useAuth();
  const [showLogout, setShowLogout] = useState(false);
  const [universityName, setUniversityName] = useState<string | null>(null);
  const [isTeamLeader, setIsTeamLeader] = useState(false);
  const { unreadCount, fetchUnread } = useChatStore();

  useEffect(() => {
    api.get("/students/me")
      .then(({ data }) => {
        const profile = (data as { success?: boolean; data?: { university?: { name: string } } })?.data ?? data as { university?: { name: string } };
        if (profile?.university?.name) setUniversityName(profile.university.name);
      })
      .catch(() => {});
    api.get("/progress/team-plans/my")
      .then(({ data }) => {
        const d = (data as { success?: boolean; data?: unknown })?.data;
        if (d && typeof d === 'object' && !Array.isArray(d)) {
          setIsTeamLeader((d as { isManager?: boolean }).isManager === true);
        }
      })
      .catch(() => {});
    void fetchUnread();
    const interval = setInterval(() => void fetchUnread(), 10000);
    return () => clearInterval(interval);
  }, [fetchUnread]);

  const handleLogout = () => {
    logout();
    setShowLogout(false);
    router.push("/login");
  };

  const displayName = user?.fullName ?? "Student";
  const initials =
    user?.fullName
      ?.split(/\s+/)
      .map((n) => n[0])
      .join("")
      .toUpperCase()
      .slice(0, 2) ?? "JD";

  const navItems = [
    { icon: LayoutDashboard, label: "Dashboard", path: "/student", badge: 0 },
    { icon: ClipboardList, label: "Plans", path: "/student/plans", badge: 0 },
    { icon: MessagesSquare, label: "Messages", path: "/student/chat", badge: unreadCount },
    { icon: Building, label: "Request Company", path: "/student/request-company", badge: 0 },
    { icon: FileCheck, label: "Final Evaluation", path: "/student/evaluation", badge: 0 },
    { icon: Activity, label: "Activity", path: "/student/settings/activity", badge: 0 },
    { icon: Settings, label: "Profile", path: "/student/settings", badge: 0 },
    { icon: MessageSquare, label: "Common Feed", path: "/student/common", badge: 0 },
  ];

  const linkClass = (active: boolean) =>
    cn(
      "flex shrink-0 items-center gap-2 rounded-xl px-3 py-2.5 text-sm font-medium transition-all duration-200 lg:gap-3 lg:px-4 lg:py-3",
      active
        ? "bg-primary-light text-primary-base shadow-sm ring-1 ring-primary-100 dark:bg-teal-900/40 dark:text-teal-400 dark:ring-slate-700"
        : "text-text-muted hover:bg-bg-tertiary hover:text-text-body active:scale-[0.98] dark:text-slate-400 dark:hover:bg-slate-800 dark:hover:text-slate-300"
    );

  return (
    <aside className="sticky top-0 z-40 w-full shrink-0 border-b border-border-default bg-bg-main shadow-sm lg:flex lg:h-screen lg:w-64 lg:flex-col lg:border-r lg:border-b-0 lg:shadow-none dark:bg-slate-900 dark:border-slate-700">
      {showLogout && (
        <LogoutModal onConfirm={handleLogout} onCancel={() => setShowLogout(false)} />
      )}
      <div className="flex items-center gap-3 border-b border-border-default px-4 py-4 lg:px-6 dark:border-slate-700">
        <div className="rounded-xl bg-primary-base p-2.5 shadow-sm shadow-primary-900/10">
          <GraduationCap className="h-6 w-6 text-white" />
        </div>
        <div className="min-w-0 flex-1">
          <span className="block truncate text-lg font-bold tracking-tight text-text-heading dark:text-slate-100">StudentPortal</span>
          {universityName
            ? <span className="hidden truncate text-xs font-medium text-primary-600 sm:block">{universityName}</span>
            : <span className="hidden text-xs text-text-muted sm:block dark:text-slate-400">Internship workspace</span>
          }
        </div>
      </div>

      <nav
        className="flex gap-1 overflow-x-auto px-2 py-2 [-ms-overflow-style:none] [scrollbar-width:none] lg:flex-col lg:gap-1.5 lg:overflow-y-auto lg:p-4 lg:pt-3 [&::-webkit-scrollbar]:hidden"
        aria-label="Student navigation"
      >
        {navItems.map((item) => {
          const active =
            item.path === "/student"
              ? pathname === item.path
              : item.path === "/student/settings"
                ? pathname === "/student/settings" || pathname?.startsWith("/student/settings/")
                : pathname?.startsWith(item.path) ?? false;
          return (
            <Link key={item.path} href={item.path} className={linkClass(!!active)}>
              <item.icon className="h-5 w-5 shrink-0" />
              <span className="whitespace-nowrap flex-1">{item.label}</span>
              {item.badge > 0 && (
                <span className="shrink-0 rounded-full bg-rose-100 px-2 py-0.5 text-[10px] font-bold tabular-nums text-rose-700 ring-1 ring-rose-200/80">
                  {item.badge > 99 ? "99+" : item.badge}
                </span>
              )}
            </Link>
          );
        })}
      </nav>

      <div className="mt-auto hidden border-t border-border-default lg:block dark:border-slate-700">
        <div className="flex items-center gap-3 p-4">
          <div className="relative flex h-10 w-10 shrink-0 items-center justify-center rounded-full bg-primary-light text-sm font-bold text-primary-base ring-2 ring-white shadow-sm dark:ring-slate-800 dark:bg-teal-900/40 dark:text-teal-400">
            {initials}
            {isTeamLeader && (
              <span className="absolute -top-1 -right-1 flex h-4 w-4 items-center justify-center rounded-full bg-amber-400 ring-2 ring-white dark:ring-slate-900">
                <Crown className="h-2.5 w-2.5 text-white" />
              </span>
            )}
          </div>
          <div className="min-w-0 flex-1">
            <p className="truncate text-sm font-bold text-text-heading dark:text-slate-100">{displayName}</p>
            {isTeamLeader ? (
              <span className="inline-flex items-center gap-1 text-xs font-semibold text-amber-600 dark:text-amber-400">
                <Crown className="h-3 w-3" /> Team Leader
              </span>
            ) : (
              <p className="truncate text-xs text-text-muted dark:text-slate-400">Student</p>
            )}
          </div>
        </div>
        <SupportLink />
        <button
          type="button"
          onClick={() => setShowLogout(true)}
          className="mb-4 flex w-full items-center gap-3 rounded-xl px-4 py-3 text-left text-sm font-medium text-red-600 transition-colors hover:bg-red-50 dark:text-red-400 dark:hover:bg-red-950/30"
        >
          <LogOut className="h-5 w-5 shrink-0" />
          Logout
        </button>
      </div>

      <div className="flex items-center justify-between gap-2 border-t border-border-default px-3 py-3 lg:hidden dark:border-slate-700">
        <div className="flex min-w-0 items-center gap-2">
          <div className="relative flex h-9 w-9 shrink-0 items-center justify-center rounded-full bg-primary-light text-xs font-bold text-primary-base dark:bg-teal-900/40 dark:text-teal-400">
            {initials}
            {isTeamLeader && (
              <span className="absolute -top-1 -right-1 flex h-3.5 w-3.5 items-center justify-center rounded-full bg-amber-400 ring-2 ring-white dark:ring-slate-900">
                <Crown className="h-2 w-2 text-white" />
              </span>
            )}
          </div>
          <div className="min-w-0">
            <span className="block truncate text-sm font-semibold text-text-heading dark:text-slate-100">{displayName}</span>
            {isTeamLeader && (
              <span className="text-[10px] font-semibold text-amber-600 dark:text-amber-400">Team Leader</span>
            )}
          </div>
        </div>
        <button
          type="button"
          onClick={() => setShowLogout(true)}
          className="rounded-lg p-2 text-red-600 transition-colors hover:bg-red-50 dark:text-red-400 dark:hover:bg-red-950/30"
          aria-label="Logout"
        >
          <LogOut className="h-5 w-5" />
        </button>
      </div>
    </aside>
  );
};

export default StudentSidebar;
