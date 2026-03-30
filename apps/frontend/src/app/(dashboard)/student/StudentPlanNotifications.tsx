"use client";

import React, { useEffect, useState } from "react";
import { Bell, CheckCircle2, Clock, XCircle } from "lucide-react";
import { MOCK_WEEKLY_PLANS } from "@/lib/superadmin/mockData";
import type { WeeklyPlan } from "@/lib/superadmin/types";
import { STUDENT_WEEKLY_PLANS_EVENT } from "@/lib/student/planNotificationEvents";
import { cn } from "@/lib/utils";

const STORAGE_KEY = "internlink_student_plan_notifications_on";

type Notice = {
  id: string;
  weekNumber: number;
  version: number;
  status: WeeklyPlan["status"];
  title: string;
};

function plansToNotices(plans: WeeklyPlan[]): Notice[] {
  return plans
    .slice()
    .sort((a, b) => new Date(b.submittedAt).getTime() - new Date(a.submittedAt).getTime())
    .map((p) => ({
      id: p.id,
      weekNumber: p.weekNumber,
      version: p.version,
      status: p.status,
      title:
        p.status === "Approved"
          ? `Week ${p.weekNumber} (v${p.version}) — Approved`
          : p.status === "Rejected"
            ? `Week ${p.weekNumber} (v${p.version}) — Rejected`
            : `Week ${p.weekNumber} (v${p.version}) — Pending review`,
    }));
}

export default function StudentPlanNotifications() {
  const [enabled, setEnabled] = useState(true);
  const [panelOpen, setPanelOpen] = useState(false);
  const [notices, setNotices] = useState<Notice[]>(() => plansToNotices(MOCK_WEEKLY_PLANS));

  useEffect(() => {
    try {
      const v = localStorage.getItem(STORAGE_KEY);
      if (v !== null) setEnabled(v === "true");
    } catch {
      /* ignore */
    }
  }, []);

  useEffect(() => {
    const handler = (e: Event) => {
      const ce = e as CustomEvent<{ plans: WeeklyPlan[] }>;
      if (ce.detail?.plans) {
        setNotices(plansToNotices(ce.detail.plans));
      }
    };
    window.addEventListener(STUDENT_WEEKLY_PLANS_EVENT, handler as EventListener);
    return () => window.removeEventListener(STUDENT_WEEKLY_PLANS_EVENT, handler as EventListener);
  }, []);

  const persistEnabled = (on: boolean) => {
    setEnabled(on);
    try {
      localStorage.setItem(STORAGE_KEY, String(on));
    } catch {
      /* ignore */
    }
  };

  const badgeCount = enabled ? notices.length : 0;

  return (
    <div className="flex shrink-0 items-center justify-between gap-4 border-b border-border-default bg-bg-main px-4 py-3 md:px-8">
      <div className="flex min-w-0 flex-1 items-center gap-3">
        <span className="truncate text-sm font-semibold text-text-heading">Plan updates</span>
        <label className="flex cursor-pointer items-center gap-2">
          <span className="sr-only">Notify about weekly plan status updates</span>
          <button
            type="button"
            role="switch"
            aria-checked={enabled}
            onClick={() => persistEnabled(!enabled)}
            className={cn(
              "relative inline-flex h-7 w-12 shrink-0 items-center rounded-full transition-colors focus:outline-none focus:ring-2 focus:ring-ring-focus focus:ring-offset-2",
              enabled ? "bg-primary-base" : "bg-slate-300"
            )}
          >
            <span
              className={cn(
                "inline-block h-5 w-5 transform rounded-full bg-white shadow transition-transform",
                enabled ? "translate-x-6" : "translate-x-1"
              )}
            />
          </button>
          <span className="hidden text-xs text-text-muted sm:inline">
            {enabled ? "On — you’ll see Approved, Rejected, Pending" : "Off"}
          </span>
        </label>
      </div>

      <div className="relative">
        <button
          type="button"
          onClick={() => enabled && setPanelOpen((o) => !o)}
          disabled={!enabled}
          className={cn(
            "relative flex h-10 w-10 items-center justify-center rounded-xl border transition-colors",
            enabled
              ? "border-border-default bg-bg-secondary text-text-heading hover:bg-bg-tertiary"
              : "cursor-not-allowed border-border-default bg-bg-secondary text-text-muted opacity-60"
          )}
          aria-label="Open plan notifications"
        >
          <Bell className="h-5 w-5" />
          {badgeCount > 0 && (
            <span className="absolute -right-1 -top-1 flex h-5 min-w-[1.25rem] items-center justify-center rounded-full bg-primary-base px-1 text-[10px] font-bold text-white">
              {badgeCount > 9 ? "9+" : badgeCount}
            </span>
          )}
        </button>

        {enabled && panelOpen && (
          <>
            <button
              type="button"
              className="fixed inset-0 z-40 cursor-default bg-transparent"
              aria-hidden
              onClick={() => setPanelOpen(false)}
            />
            <div className="absolute right-0 top-full z-50 mt-2 w-[min(100vw-2rem,22rem)] rounded-2xl border border-border-default bg-bg-main py-2 shadow-modal">
              <p className="border-b border-border-default px-4 pb-2 text-xs font-semibold uppercase tracking-wide text-text-muted">
                Status updates
              </p>
              <ul className="max-h-72 overflow-y-auto py-1">
                {notices.length === 0 ? (
                  <li className="px-4 py-6 text-center text-sm text-text-muted">No plan activity yet.</li>
                ) : (
                  notices.map((n) => (
                    <li
                      key={n.id}
                      className="flex gap-3 border-b border-border-default/80 px-4 py-3 last:border-0"
                    >
                      <span className="mt-0.5 shrink-0">
                        {n.status === "Approved" && <CheckCircle2 className="h-4 w-4 text-green-600" />}
                        {n.status === "Rejected" && <XCircle className="h-4 w-4 text-red-500" />}
                        {n.status === "Pending" && <Clock className="h-4 w-4 text-yellow-500" />}
                      </span>
                      <span className="text-sm leading-snug text-text-body">{n.title}</span>
                    </li>
                  ))
                )}
              </ul>
            </div>
          </>
        )}
      </div>
    </div>
  );
}
