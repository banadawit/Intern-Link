"use client";

import { useEffect, useState } from "react";
import api from "@/lib/api/client";
import { Building2, ClipboardList, Inbox, Users } from "lucide-react";

type MeResponse = {
  supervisor: {
    id: number;
    companyId: number;
    company: { id: number; name: string; official_email: string };
    user: { full_name: string; email: string };
  };
  stats: {
    pendingProposalsCount: number;
    pendingWeeklyPlansCount: number;
    placedStudentsCount: number;
  };
};

export default function SupervisorDashboardPage() {
  const [data, setData] = useState<MeResponse | null>(null);
  const [error, setError] = useState<string | null>(null);

  useEffect(() => {
    let cancelled = false;
    (async () => {
      try {
        const res = await api.get<{ success: boolean; data: MeResponse }>("/supervisor/me");
        if (!cancelled) setData(res.data.data);
      } catch (e: unknown) {
        const msg = e && typeof e === "object" && "response" in e ? String((e as { response?: { data?: { message?: string } } }).response?.data?.message) : "Failed to load dashboard.";
        if (!cancelled) setError(msg || "Failed to load dashboard.");
      }
    })();
    return () => {
      cancelled = true;
    };
  }, []);

  if (error) {
    return (
      <div className="rounded-2xl border border-red-200 bg-red-50 p-6 text-sm text-red-800">
        {error}
      </div>
    );
  }

  if (!data) {
    return (
      <div className="flex min-h-[40vh] items-center justify-center text-slate-500">
        Loading dashboard…
      </div>
    );
  }

  const { supervisor, stats } = data;

  if (!supervisor?.company) {
    return (
      <div className="flex min-h-[40vh] items-center justify-center text-slate-500">
        Company profile not linked. Contact support.
      </div>
    );
  }

  const cards = [
    {
      label: "Company",
      value: supervisor.company.name,
      sub: supervisor.company.official_email,
      icon: Building2,
    },
    {
      label: "Pending proposals",
      value: String(stats.pendingProposalsCount),
      sub: "Awaiting your response",
      icon: Inbox,
    },
    {
      label: "Pending weekly plans",
      value: String(stats.pendingWeeklyPlansCount),
      sub: "Need review",
      icon: ClipboardList,
    },
    {
      label: "Placed students",
      value: String(stats.placedStudentsCount),
      sub: "Active at your company",
      icon: Users,
    },
  ];

  return (
    <div className="space-y-8">
      <div>
        <h1 className="text-2xl font-bold tracking-tight text-slate-900 md:text-3xl">
          Welcome back, {supervisor.user.full_name}
        </h1>
        <p className="mt-1 text-sm text-slate-500">
          Overview of internship activity for {supervisor.company.name}.
        </p>
      </div>

      <div className="grid gap-4 sm:grid-cols-2 xl:grid-cols-4">
        {cards.map((c) => (
          <div
            key={c.label}
            className="rounded-2xl border border-slate-200 bg-white p-5 shadow-sm"
          >
            <div className="flex items-start justify-between gap-3">
              <div>
                <p className="text-xs font-semibold uppercase tracking-wide text-slate-400">
                  {c.label}
                </p>
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
    </div>
  );
}
