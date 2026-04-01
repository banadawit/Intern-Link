"use client";

import React from "react";
import Link from "next/link";
import { usePathname } from "next/navigation";
import { BellRing, User } from "lucide-react";
import { cn } from "@/lib/utils";

export default function StudentSettingsShell({ children }: { children: React.ReactNode }) {
  const pathname = usePathname();

  const items = [
    { href: "/student/settings", label: "Profile", icon: User, exact: true },
    { href: "/student/settings/alerts", label: "Alerts", icon: BellRing, exact: false },
  ];

  const isActive = (href: string, exact: boolean) => {
    if (exact) return pathname === href;
    return pathname === href || pathname?.startsWith(`${href}/`);
  };

  return (
    <div className="flex flex-col gap-8 lg:flex-row lg:items-start lg:gap-10">
      <aside
        className="shrink-0 lg:w-56"
        aria-label="Settings sections"
      >
        <p className="mb-3 text-xs font-semibold uppercase tracking-wide text-text-muted">Settings</p>
        <nav className="flex gap-2 overflow-x-auto pb-1 [-ms-overflow-style:none] [scrollbar-width:none] lg:flex-col lg:gap-1 lg:overflow-visible [&::-webkit-scrollbar]:hidden">
          {items.map((item) => {
            const active = isActive(item.href, item.exact);
            return (
              <Link
                key={item.href}
                href={item.href}
                className={cn(
                  "flex shrink-0 items-center gap-2 rounded-xl px-3 py-2.5 text-sm font-medium transition-all duration-200 lg:px-4",
                  active
                    ? "bg-primary-light text-primary-base shadow-sm ring-1 ring-primary-100"
                    : "text-text-muted hover:bg-bg-tertiary hover:text-text-body"
                )}
              >
                <item.icon className="h-5 w-5 shrink-0" />
                {item.label}
              </Link>
            );
          })}
        </nav>
      </aside>
      <div className="min-w-0 flex-1">{children}</div>
    </div>
  );
}
