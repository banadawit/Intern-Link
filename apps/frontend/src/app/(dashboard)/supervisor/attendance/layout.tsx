"use client";

import Link from "next/link";
import { usePathname } from "next/navigation";
import { cn } from "@/lib/utils";

const tabs = [
  { href: "/supervisor/attendance/students", label: "Student check-ins" },
  { href: "/supervisor/attendance/reports", label: "Weekly reports" },
] as const;

export default function SupervisorAttendanceLayout({ children }: { children: React.ReactNode }) {
  const pathname = usePathname();

  return (
    <div className="w-full min-w-0 space-y-6">
      <div
        className="flex flex-wrap gap-1 rounded-xl border border-slate-200/80 bg-slate-50/80 p-1 sm:inline-flex"
        role="tablist"
        aria-label="Attendance sections"
      >
        {tabs.map((t) => {
          const active = pathname === t.href || pathname?.startsWith(`${t.href}/`);
          return (
            <Link
              key={t.href}
              href={t.href}
              role="tab"
              aria-selected={active}
              className={cn(
                "rounded-lg px-3 py-2 text-sm font-medium transition-colors sm:px-4",
                active
                  ? "bg-white text-primary-700 shadow-sm ring-1 ring-slate-200/80"
                  : "text-slate-600 hover:bg-white/60 hover:text-slate-900",
              )}
            >
              {t.label}
            </Link>
          );
        })}
      </div>
      {children}
    </div>
  );
}
