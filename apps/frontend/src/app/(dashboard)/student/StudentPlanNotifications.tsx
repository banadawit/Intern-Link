"use client";

import React, { useEffect, useRef, useState } from "react";
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
import api from "@/lib/api/client";
import { mapWeeklyPlanRow } from "@/lib/api/mappers";
import type { WeeklyPlan } from "@/lib/superadmin/types";
import {
  STUDENT_WEEKLY_PLANS_EVENT,
  STUDENT_PLAN_NOTICES_READ_KEY,
} from "@/lib/student/planNotificationEvents";
import { cn } from "@/lib/utils";
import { notifyDesktop } from "@/lib/student/desktopNotifications";

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

function loadReadIdsFromStorage(): Set<string> {
  if (typeof window === "undefined") return new Set();
  try {
    const raw = localStorage.getItem(STUDENT_PLAN_NOTICES_READ_KEY);
    if (!raw) return new Set();
    const parsed = JSON.parse(raw) as unknown;
    if (!Array.isArray(parsed)) return new Set();
    return new Set(parsed.filter((x): x is string => typeof x === "string"));
  } catch {
    return new Set();
  }
}

function persistReadIds(ids: Set<string>) {
  try {
    localStorage.setItem(STUDENT_PLAN_NOTICES_READ_KEY, JSON.stringify([...ids]));
  } catch {
    /* ignore quota / private mode */
  }
}

export default function StudentPlanNotifications() {
  const [panelOpen, setPanelOpen] = useState(false);
  const [notices, setNotices] = useState<Notice[]>([]);
  const [readIds, setReadIds] = useState<Set<string>>(() => new Set());

  useEffect(() => {
    setReadIds(loadReadIdsFromStorage());
  }, []);

  useEffect(() => {
    const applyPlans = (plans: WeeklyPlan[]) => {
      setNotices(plansToNotices(plans));
    };
    const load = async () => {
      try {
        const { data } = await api.get("/progress/my-plans");
        const rows = (data as Record<string, unknown>[]) ?? [];
        applyPlans(rows.map((row) => mapWeeklyPlanRow(row as Parameters<typeof mapWeeklyPlanRow>[0])));
      } catch {
        applyPlans([]);
      }
    };
    load();
    const onPlans = (e: Event) => {
      const ce = e as CustomEvent<{ plans: WeeklyPlan[] }>;
      if (ce.detail?.plans) applyPlans(ce.detail.plans);
    };
    window.addEventListener(STUDENT_WEEKLY_PLANS_EVENT, onPlans);
    return () => window.removeEventListener(STUDENT_WEEKLY_PLANS_EVENT, onPlans);
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

  const prevNoticeCount = useRef<number | null>(null);
  useEffect(() => {
    if (prevNoticeCount.current === null) {
      prevNoticeCount.current = notices.length;
      return;
    }
    if (notices.length > prevNoticeCount.current) {
      notifyDesktop(
        "Internship — plan activity",
        "Open the bell to see the latest weekly plan updates.",
        "plan-activity-feed"
      );
    }
    prevNoticeCount.current = notices.length;
  }, [notices.length]);

  /** While the panel is open, treat all listed activity as seen (badge stays cleared for those). */
  useEffect(() => {
    if (!panelOpen) return;
    setReadIds((prev) => {
      const next = new Set(prev);
      let changed = false;
      for (const n of notices) {
        if (!next.has(n.id)) {
          next.add(n.id);
          changed = true;
        }
      }
      if (changed) persistReadIds(next);
      return changed ? next : prev;
    });
  }, [panelOpen, notices]);

  const unreadCount = notices.filter((n) => !readIds.has(n.id)).length;

  return (
    <div
      className={cn(
        "flex shrink-0 items-center gap-3 py-3",
        panelOpen && "relative z-[100]"
      )}
    >
      <div className="relative">
        <button
          type="button"
          onClick={() => setPanelOpen((o) => !o)}
          className="relative flex h-10 w-10 items-center justify-center rounded-xl border border-border-default bg-bg-secondary text-text-heading shadow-sm transition-all hover:bg-bg-tertiary hover:shadow-md active:scale-95"
          aria-label={
            unreadCount > 0
              ? `Plan notifications, ${unreadCount} unread`
              : "Plan notifications, no unread items"
          }
        >
          <Bell className="h-5 w-5" />
          {unreadCount > 0 && (
            <span className="absolute -right-1 -top-1 flex h-5 min-w-[1.25rem] items-center justify-center rounded-full bg-red-500 px-1 text-[10px] font-bold text-white">
              {unreadCount > 9 ? "9+" : unreadCount}
            </span>
          )}
        </button>

        {panelOpen && (
          <>
            <button
              type="button"
              className="fixed inset-0 z-[90] cursor-default bg-transparent"
              aria-hidden
              onClick={() => setPanelOpen(false)}
            />
            <div className="absolute right-0 top-full z-[110] mt-2 w-[min(100vw-2rem,22rem)] animate-in fade-in duration-200 rounded-2xl border border-border-default bg-bg-main py-2 shadow-modal">
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
                        onClick={() => {
                          setPanelOpen(false);
                          setReadIds((prev) => {
                            if (prev.has(n.id)) return prev;
                            const next = new Set(prev);
                            next.add(n.id);
                            persistReadIds(next);
                            return next;
                          });
                        }}
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
