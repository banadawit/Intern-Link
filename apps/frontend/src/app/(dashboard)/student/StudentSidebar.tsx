"use client";

import React from "react";
import {
  LayoutDashboard,
  ClipboardList,
  MessageSquare,
  Building,
  FileCheck,
  LogOut,
  GraduationCap,
} from "lucide-react";
import Link from "next/link";
import { usePathname } from "next/navigation";
import { cn } from "@/lib/utils";

const StudentSidebar = () => {
  const pathname = usePathname();
  const navItems = [
    { icon: LayoutDashboard, label: "Dashboard", path: "/student" },
    { icon: ClipboardList, label: "Weekly Plans", path: "/student/plans" },
    { icon: MessageSquare, label: "Common Page", path: "/student/common" },
    { icon: Building, label: "Request Company", path: "/student/request-company" },
    { icon: FileCheck, label: "Final Evaluation", path: "/student/evaluation" },
  ];

  const linkClass = (active: boolean) =>
    cn(
      "flex shrink-0 items-center gap-2 rounded-xl px-3 py-2.5 text-sm font-medium transition-all duration-200 lg:gap-3 lg:px-4 lg:py-3",
      active
        ? "bg-primary-light text-primary-base shadow-sm ring-1 ring-primary-100"
        : "text-text-muted hover:bg-bg-tertiary hover:text-text-body active:scale-[0.98]"
    );

  return (
    <aside className="sticky top-0 z-40 w-full shrink-0 border-b border-border-default bg-bg-main shadow-sm lg:flex lg:h-screen lg:w-64 lg:flex-col lg:border-r lg:border-b-0 lg:shadow-none">
      <div className="flex items-center gap-3 border-b border-border-default px-4 py-4 lg:px-6">
        <div className="rounded-xl bg-primary-base p-2.5 shadow-sm shadow-primary-900/10">
          <GraduationCap className="h-6 w-6 text-white" />
        </div>
        <div className="min-w-0">
          <span className="block truncate text-lg font-bold tracking-tight text-text-heading">StudentPortal</span>
          <span className="hidden text-xs text-text-muted sm:block">Internship workspace</span>
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
              : pathname?.startsWith(item.path) ?? false;
          return (
            <Link key={item.path} href={item.path} className={linkClass(!!active)}>
              <item.icon className="h-5 w-5 shrink-0" />
              <span className="whitespace-nowrap">{item.label}</span>
            </Link>
          );
        })}
      </nav>

      <div className="mt-auto hidden border-t border-border-default lg:block">
        <div className="flex items-center gap-3 p-4">
          <div className="flex h-10 w-10 shrink-0 items-center justify-center rounded-full bg-primary-light text-sm font-bold text-primary-base ring-2 ring-white shadow-sm">
            JD
          </div>
          <div className="min-w-0 flex-1">
            <p className="truncate text-sm font-bold text-text-heading">John Doe</p>
            <p className="truncate text-xs text-text-muted">Student</p>
          </div>
        </div>
        <button
          type="button"
          className="mb-4 flex w-full items-center gap-3 rounded-xl px-4 py-3 text-left text-sm font-medium text-red-600 transition-colors hover:bg-red-50"
        >
          <LogOut className="h-5 w-5 shrink-0" />
          Logout
        </button>
      </div>

      <div className="flex items-center justify-between gap-2 border-t border-border-default px-3 py-3 lg:hidden">
        <div className="flex min-w-0 items-center gap-2">
          <div className="flex h-9 w-9 shrink-0 items-center justify-center rounded-full bg-primary-light text-xs font-bold text-primary-base">
            JD
          </div>
          <span className="truncate text-sm font-semibold text-text-heading">John Doe</span>
        </div>
        <button
          type="button"
          className="rounded-lg p-2 text-red-600 transition-colors hover:bg-red-50"
          aria-label="Logout"
        >
          <LogOut className="h-5 w-5" />
        </button>
      </div>
    </aside>
  );
};

export default StudentSidebar;
