"use client";

import React, { useState } from "react";
import {
  LayoutDashboard,
  Users,
  Inbox,
  ClipboardList,
  FileCheck,
  LogOut,
  Building2,
  CalendarDays,
  ListChecks,
  UsersRound,
  FolderKanban,
  Sparkles,
} from "lucide-react";
import Link from "next/link";
import { usePathname, useRouter } from "next/navigation";
import { cn } from "@/lib/utils";
import { useAuth } from "@/lib/hooks/useAuth";
import LogoutModal from "@/components/common/LogoutModal";

const SupervisorSidebar = () => {
  const pathname = usePathname();
  const router = useRouter();
  const { user, logout } = useAuth();
  const [showLogout, setShowLogout] = useState(false);

  const handleLogout = () => {
    logout();
    setShowLogout(false);
    router.push("/login");
  };

  const displayName = user?.fullName ?? "Supervisor";
  const initials =
    user?.fullName
      ?.split(/\s+/)
      .map((n) => n[0])
      .join("")
      .toUpperCase()
      .slice(0, 2) ?? "SV";

  const navItems = [
    { icon: LayoutDashboard, label: "Dashboard", path: "/supervisor" },
    { icon: Users, label: "Students", path: "/supervisor/students" },
    { icon: UsersRound, label: "Teams", path: "/supervisor/teams" },
    { icon: FolderKanban, label: "Projects", path: "/supervisor/projects" },
    { icon: Inbox, label: "Proposals", path: "/supervisor/proposals" },
    { icon: ClipboardList, label: "Weekly plans", path: "/supervisor/plans" },
    { icon: Sparkles, label: "AI assistant", path: "/supervisor/ai" },
    { icon: FileCheck, label: "Reports", path: "/supervisor/reports" },
  ];

  const attendanceNavItems = [
    { icon: CalendarDays, label: "Student check-ins", path: "/supervisor/attendance/students" },
    { icon: ListChecks, label: "Weekly reports", path: "/supervisor/attendance/reports" },
  ];

  const linkClass = (active: boolean) =>
    cn(
      "flex shrink-0 items-center gap-2 rounded-xl px-3 py-2.5 text-sm font-medium transition-all duration-200 lg:gap-3 lg:px-4 lg:py-3",
      active
        ? "bg-primary-light text-primary-base shadow-sm ring-1 ring-primary-100"
        : "text-text-muted hover:bg-bg-tertiary hover:text-text-body active:scale-[0.98]",
    );

  return (
    <aside className="sticky top-0 z-40 w-full shrink-0 border-b border-border-default bg-bg-main shadow-sm lg:flex lg:h-screen lg:w-64 lg:flex-col lg:border-r lg:border-b-0 lg:shadow-none">
      {showLogout && (
        <LogoutModal onConfirm={handleLogout} onCancel={() => setShowLogout(false)} />
      )}
      <div className="flex items-center gap-3 border-b border-border-default px-4 py-4 lg:px-6">
        <div className="rounded-xl bg-primary-base p-2.5 shadow-sm shadow-primary-900/10">
          <Building2 className="h-6 w-6 text-white" />
        </div>
        <div className="min-w-0">
          <span className="block truncate text-lg font-bold tracking-tight text-text-heading">
            Company Portal
          </span>
          <span className="hidden text-xs text-text-muted sm:block">Supervisor workspace</span>
        </div>
      </div>

      <nav
        className="flex gap-1 overflow-x-auto px-2 py-2 [-ms-overflow-style:none] [scrollbar-width:none] lg:flex-col lg:gap-1.5 lg:overflow-y-auto lg:p-4 lg:pt-3 [&::-webkit-scrollbar]:hidden"
        aria-label="Supervisor navigation"
      >
        {navItems.map((item) => {
          const active =
            item.path === "/supervisor"
              ? pathname === item.path
              : pathname?.startsWith(item.path) ?? false;
          return (
            <Link key={item.path} href={item.path} className={linkClass(!!active)}>
              <item.icon className="h-5 w-5 shrink-0" />
              <span className="whitespace-nowrap">{item.label}</span>
            </Link>
          );
        })}

        <div className="mt-0.5 flex w-full min-w-0 flex-col gap-0.5 border-t border-border-default/60 pt-2 lg:mt-1 lg:border-t-0 lg:pt-0">
          <p className="hidden px-3 pb-0.5 text-[10px] font-semibold uppercase tracking-wide text-text-muted lg:block">
            Attendance
          </p>
          <div className="flex gap-1 lg:flex-col lg:gap-1.5">
            {attendanceNavItems.map((item) => {
              const active = pathname === item.path || (pathname?.startsWith(`${item.path}/`) ?? false);
              return (
                <Link key={item.path} href={item.path} className={linkClass(!!active)}>
                  <item.icon className="h-5 w-5 shrink-0" />
                  <span className="whitespace-nowrap">{item.label}</span>
                </Link>
              );
            })}
          </div>
        </div>
      </nav>

      <div className="mt-auto hidden border-t border-border-default lg:block">
        <div className="flex items-center gap-3 p-4">
          <div className="flex h-10 w-10 shrink-0 items-center justify-center rounded-full bg-primary-light text-sm font-bold text-primary-base ring-2 ring-white shadow-sm">
            {initials}
          </div>
          <div className="min-w-0 flex-1">
            <p className="truncate text-sm font-bold text-text-heading">{displayName}</p>
            <p className="truncate text-xs text-text-muted">Supervisor</p>
          </div>
        </div>
        <button
          type="button"
          onClick={() => setShowLogout(true)}
          className="mb-4 flex w-full items-center gap-3 rounded-xl px-4 py-3 text-left text-sm font-medium text-red-600 transition-colors hover:bg-red-50"
        >
          <LogOut className="h-5 w-5 shrink-0" />
          Logout
        </button>
      </div>

      <div className="flex items-center justify-between gap-2 border-t border-border-default px-3 py-3 lg:hidden">
        <div className="flex min-w-0 items-center gap-2">
          <div className="flex h-9 w-9 shrink-0 items-center justify-center rounded-full bg-primary-light text-xs font-bold text-primary-base">
            {initials}
          </div>
          <span className="truncate text-sm font-semibold text-text-heading">{displayName}</span>
        </div>
        <button
          type="button"
          onClick={() => setShowLogout(true)}
          className="rounded-lg p-2 text-red-600 hover:bg-red-50"
          aria-label="Logout"
        >
          <LogOut className="h-5 w-5" />
        </button>
      </div>
    </aside>
  );
};

export default SupervisorSidebar;
