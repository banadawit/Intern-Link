"use client";

import React, { useEffect, useState } from "react";
import Link from "next/link";
import { format } from "date-fns";
import {
  Bell,
  Calendar,
  CheckCircle2,
  Clock,
  FileText,
  MessageSquare,
  Send,
  XCircle,
} from "lucide-react";
import { MOCK_WEEKLY_PLANS } from "@/lib/superadmin/mockData";
import type { WeeklyPlan } from "@/lib/superadmin/types";
import { STUDENT_WEEKLY_PLANS_EVENT } from "@/lib/student/planNotificationEvents";

type NoticeKind = "submitted" | "status" | "feedback" | "reviewed" | "presentation";

type Notice = {
  id: string;
  /** Weekly plan id — all rows for the same plan link to this */
  planId: string;
  weekNumber: number;
  version: number;
  kind: NoticeKind;
  status: WeeklyPlan["status"];
  title: string;
  sortTime: number;
};

function plansToNotices(plans: WeeklyPlan[]): Notice[] {
  const out: Notice[] = [];

  for (const p of plans) {
    const submittedMs = new Date(p.submittedAt).getTime();
    const label = `Week ${p.weekNumber} (v${p.version})`;

    out.push({
      id: `${p.id}-submitted`,
      planId: p.id,
      weekNumber: p.weekNumber,
      version: p.version,
      kind: "submitted",
      status: p.status,
      title: `${label} — Plan submitted (${format(new Date(p.submittedAt), "MMM d, yyyy HH:mm")})`,
      sortTime: submittedMs,
    });

    out.push({
      id: `${p.id}-status`,
      planId: p.id,
      weekNumber: p.weekNumber,
      version: p.version,
      kind: "status",
      status: p.status,
      title:
        p.status === "Approved"
          ? `${label} — Status: Approved`
          : p.status === "Rejected"
            ? `${label} — Status: Rejected`
            : `${label} — Status: Pending review`,
      sortTime: submittedMs + 1,
    });

    if (p.feedback?.trim()) {
      out.push({
        id: `${p.id}-feedback`,
        planId: p.id,
        weekNumber: p.weekNumber,
        version: p.version,
        kind: "feedback",
        status: p.status,
        title: `${label} — Supervisor feedback received`,
        sortTime: (p.reviewedAt ? new Date(p.reviewedAt).getTime() : submittedMs) + 2,
      });
    }

    if (p.reviewedAt) {
      out.push({
        id: `${p.id}-reviewed`,
        planId: p.id,
        weekNumber: p.weekNumber,
        version: p.version,
        kind: "reviewed",
        status: p.status,
        title: `${label} — Reviewed on ${format(new Date(p.reviewedAt), "MMM d, yyyy HH:mm")}`,
        sortTime: new Date(p.reviewedAt).getTime() + 3,
      });
    }

    if (p.presentationUrl?.trim()) {
      out.push({
        id: `${p.id}-presentation`,
        planId: p.id,
        weekNumber: p.weekNumber,
        version: p.version,
        kind: "presentation",
        status: p.status,
        title: `${label} — Presentation file attached`,
        sortTime: submittedMs + 4,
      });
    }
  }

  return out.sort((a, b) => b.sortTime - a.sortTime);
}

export default function StudentPlanNotifications() {
  const [panelOpen, setPanelOpen] = useState(false);
  const [notices, setNotices] = useState<Notice[]>(() => plansToNotices(MOCK_WEEKLY_PLANS));

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

  const badgeCount = notices.length;

  return (
    <div className="flex shrink-0 items-center justify-end gap-4 border-b border-border-default bg-bg-main px-4 py-3 md:px-8">
      <div className="relative">
        <button
          type="button"
          onClick={() => setPanelOpen((o) => !o)}
          className="relative flex h-10 w-10 items-center justify-center rounded-xl border border-border-default bg-bg-secondary text-text-heading transition-colors hover:bg-bg-tertiary"
          aria-label="Open plan notifications"
        >
          <Bell className="h-5 w-5" />
          {badgeCount > 0 && (
            <span className="absolute -right-1 -top-1 flex h-5 min-w-[1.25rem] items-center justify-center rounded-full bg-red-500 px-1 text-[10px] font-bold text-white">
              {badgeCount > 9 ? "9+" : badgeCount}
            </span>
          )}
        </button>

        {panelOpen && (
          <>
            <button
              type="button"
              className="fixed inset-0 z-40 cursor-default bg-transparent"
              aria-hidden
              onClick={() => setPanelOpen(false)}
            />
            <div className="absolute right-0 top-full z-50 mt-2 w-[min(100vw-2rem,22rem)] rounded-2xl border border-border-default bg-bg-main py-2 shadow-modal">
              <p className="border-b border-border-default px-4 pb-2 text-xs font-semibold uppercase tracking-wide text-text-muted">
                All activity
              </p>
              <ul className="max-h-72 overflow-y-auto py-1">
                {notices.length === 0 ? (
                  <li className="px-4 py-6 text-center text-sm text-text-muted">No plan activity yet.</li>
                ) : (
                  notices.map((n) => (
                    <li key={n.id} className="border-b border-border-default/80 last:border-0">
                      <Link
                        href={`/student/plans?plan=${encodeURIComponent(n.planId)}`}
                        scroll
                        onClick={() => setPanelOpen(false)}
                        className="flex gap-3 px-4 py-3 text-left transition-colors hover:bg-bg-secondary"
                      >
                        <span className="mt-0.5 shrink-0">
                          {n.kind === "submitted" && <Send className="h-4 w-4 text-blue-500" />}
                          {n.kind === "status" && n.status === "Approved" && (
                            <CheckCircle2 className="h-4 w-4 text-green-600" />
                          )}
                          {n.kind === "status" && n.status === "Rejected" && (
                            <XCircle className="h-4 w-4 text-red-500" />
                          )}
                          {n.kind === "status" && n.status === "Pending" && (
                            <Clock className="h-4 w-4 text-yellow-500" />
                          )}
                          {n.kind === "feedback" && <MessageSquare className="h-4 w-4 text-indigo-500" />}
                          {n.kind === "reviewed" && <Calendar className="h-4 w-4 text-slate-600" />}
                          {n.kind === "presentation" && <FileText className="h-4 w-4 text-teal-600" />}
                        </span>
                        <span className="text-sm leading-snug text-text-body">{n.title}</span>
                      </Link>
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
