"use client";

import React from "react";
import Link from "next/link";
import { usePathname } from "next/navigation";
import { Activity, BellRing, User } from "lucide-react";
import { cn } from "@/lib/utils";

const items = [
  { href: "/student/settings", label: "Profile", icon: User, exact: true },
  { href: "/student/settings/activity", label: "Activity", icon: Activity, exact: false },
  { href: "/student/settings/alerts", label: "Alerts", icon: BellRing, exact: false },
];

export default function StudentSettingsTopNav() {
  const pathname = usePathname();

  const isActive = (href: string, exact: boolean) => {
    if (exact) return pathname === href;
    return pathname === href || pathname?.startsWith(`${href}/`);
  };

  return (
    <nav
      className="flex flex-wrap gap-2 border-b border-border-default pb-4"
      aria-label="Settings sections"
    >
      {items.map((item) => {
        const active = isActive(item.href, item.exact);
        return (
          <Link
            key={item.href}
            href={item.href}
            className={cn(
              "inline-flex items-center gap-2 rounded-xl px-3 py-2 text-sm font-medium transition-all duration-200 sm:px-4",
              active
                ? "bg-primary-light text-primary-base shadow-sm ring-1 ring-primary-100"
                : "text-text-muted hover:bg-bg-tertiary hover:text-text-body"
            )}
          >
            <item.icon className="h-4 w-4 shrink-0 sm:h-5 sm:w-5" aria-hidden />
            {item.label}
          </Link>
        );
      })}
    </nav>
  );
}
