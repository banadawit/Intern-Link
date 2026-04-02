"use client";

import { Users, FileCheck, Building2, FileText } from "lucide-react";
import type { HodStats } from "./types";

type Props = { stats: HodStats | null };

export default function HodStatCards({ stats }: Props) {
  if (!stats) return null;

  const cards = [
    {
      label: "Department students",
      value: String(stats.totalStudents),
      sub: "In your department",
      icon: Users,
    },
    {
      label: "Pending approvals",
      value: String(stats.pendingApprovals),
      sub: "Awaiting your review",
      icon: FileCheck,
    },
    {
      label: "Placed students",
      value: String(stats.placedStudents),
      sub: "Active placements",
      icon: Building2,
    },
    {
      label: "Reports",
      value: String(stats.reports),
      sub: "Final reports received",
      icon: FileText,
    },
  ];

  return (
    <div className="grid gap-4 sm:grid-cols-2 xl:grid-cols-4">
      {cards.map((c) => (
        <div key={c.label} className="rounded-2xl border border-slate-200 bg-white p-5 shadow-sm">
          <div className="flex items-start justify-between gap-3">
            <div>
              <p className="text-xs font-semibold uppercase tracking-wide text-slate-400">{c.label}</p>
              <p className="mt-2 text-lg font-bold text-slate-900">{c.value}</p>
              <p className="mt-1 text-xs text-slate-500">{c.sub}</p>
            </div>
            <div className="rounded-xl bg-primary-50 p-2.5 text-primary-600">
              <c.icon className="h-5 w-5" aria-hidden />
            </div>
          </div>
        </div>
      ))}
    </div>
  );
}
