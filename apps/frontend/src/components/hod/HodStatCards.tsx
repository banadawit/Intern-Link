"use client";

import Link from "next/link";
import { Users, FileCheck, Building2, FileText, Clock, CheckCircle2, XCircle, Send, ChevronRight, UserCheck } from "lucide-react";
import { cn } from "@/lib/utils";
import type { HodStats } from "./types";

type Props = { stats: HodStats | null };

export default function HodStatCards({ stats }: Props) {
  if (!stats) return null;

  const proposals = stats.proposals ?? { pending: 0, approved: 0, rejected: 0 };
  const placementRate = stats.approvedStudents > 0
    ? Math.round((stats.placedStudents / stats.approvedStudents) * 100)
    : 0;

  const approvalRate = stats.totalStudents > 0
    ? Math.round(((stats.approvedStudents ?? 0) / stats.totalStudents) * 100)
    : 0;

  const approvedNotPlaced = stats.approvedNotPlaced ?? 0;
  const approvedStudents = stats.approvedStudents ?? 0;
  const rejectedStudents = stats.rejectedStudents ?? 0;
  const recentPending = stats.recentPendingStudents ?? [];

  return (
    <div className="space-y-6">
      {/* Primary stat cards */}
      <div className="grid gap-4 sm:grid-cols-2 xl:grid-cols-4">
        {/* Total students */}
        <div className="rounded-2xl border border-slate-200 bg-white p-5 shadow-sm">
          <div className="flex items-start justify-between gap-3">
            <div className="min-w-0">
              <p className="text-xs font-semibold uppercase tracking-wide text-slate-400">Department students</p>
              <p className="mt-2 text-3xl font-bold text-slate-900">{stats.totalStudents}</p>
              <div className="mt-2 flex items-center gap-2 flex-wrap">
                <span className="inline-flex items-center gap-1 rounded-full bg-emerald-100 px-2 py-0.5 text-xs font-medium text-emerald-700">
                  <CheckCircle2 className="h-3 w-3" />{approvedStudents} approved
                </span>
                {rejectedStudents > 0 && (
                  <span className="inline-flex items-center gap-1 rounded-full bg-red-100 px-2 py-0.5 text-xs font-medium text-red-700">
                    <XCircle className="h-3 w-3" />{rejectedStudents} rejected
                  </span>
                )}
              </div>
            </div>
            <div className="rounded-xl bg-primary-50 p-2.5 text-primary-600 shrink-0">
              <Users className="h-5 w-5" />
            </div>
          </div>
          {/* Approval rate bar */}
          <div className="mt-4">
            <div className="flex items-center justify-between text-xs text-slate-500 mb-1">
              <span>Approval rate</span>
              <span className="font-semibold text-slate-700">{approvalRate}%</span>
            </div>
            <div className="h-1.5 w-full rounded-full bg-slate-100">
              <div className="h-full rounded-full bg-emerald-500 transition-all" style={{ width: `${approvalRate}%` }} />
            </div>
          </div>
        </div>

        {/* Pending approvals */}
        <Link href="/hod/students?status=pending" className="group rounded-2xl border border-slate-200 bg-white p-5 shadow-sm hover:border-amber-300 hover:shadow-md transition-all">
          <div className="flex items-start justify-between gap-3">
            <div>
              <p className="text-xs font-semibold uppercase tracking-wide text-slate-400">Pending approvals</p>
              <p className={cn("mt-2 text-3xl font-bold", stats.pendingApprovals > 0 ? "text-amber-600" : "text-slate-900")}>
                {stats.pendingApprovals}
              </p>
              <p className="mt-1 text-xs text-slate-500">
                {stats.pendingApprovals > 0 ? "Awaiting your review" : "All caught up"}
              </p>
            </div>
            <div className={cn("rounded-xl p-2.5 shrink-0", stats.pendingApprovals > 0 ? "bg-amber-50 text-amber-600" : "bg-slate-50 text-slate-400")}>
              <Clock className="h-5 w-5" />
            </div>
          </div>
          {stats.pendingApprovals > 0 && (
            <div className="mt-4 flex items-center gap-1 text-xs font-semibold text-amber-600 group-hover:text-amber-700">
              Review now <ChevronRight className="h-3.5 w-3.5" />
            </div>
          )}
        </Link>

        {/* Placements */}
        <div className="rounded-2xl border border-slate-200 bg-white p-5 shadow-sm">
          <div className="flex items-start justify-between gap-3">
            <div className="min-w-0">
              <p className="text-xs font-semibold uppercase tracking-wide text-slate-400">Placements</p>
              <p className="mt-2 text-3xl font-bold text-slate-900">{stats.placedStudents}</p>
              <p className="mt-1 text-xs text-slate-500">
                {approvedNotPlaced > 0
                  ? `${approvedNotPlaced} approved, not yet placed`
                  : "All approved students placed"}
              </p>
            </div>
            <div className="rounded-xl bg-emerald-50 p-2.5 text-emerald-600 shrink-0">
              <Building2 className="h-5 w-5" />
            </div>
          </div>
          {/* Placement rate bar */}
          <div className="mt-4">
            <div className="flex items-center justify-between text-xs text-slate-500 mb-1">
              <span>Placement rate</span>
              <span className="font-semibold text-slate-700">{placementRate}%</span>
            </div>
            <div className="h-1.5 w-full rounded-full bg-slate-100">
              <div className="h-full rounded-full bg-emerald-500 transition-all" style={{ width: `${placementRate}%` }} />
            </div>
          </div>
        </div>

        {/* Proposals & Reports */}
        <div className="rounded-2xl border border-slate-200 bg-white p-5 shadow-sm">
          <div className="flex items-start justify-between gap-3">
            <div>
              <p className="text-xs font-semibold uppercase tracking-wide text-slate-400">Proposals</p>
              <p className="mt-2 text-3xl font-bold text-slate-900">{proposals.pending + proposals.approved + proposals.rejected}</p>
            </div>
            <div className="rounded-xl bg-blue-50 p-2.5 text-blue-600 shrink-0">
              <Send className="h-5 w-5" />
            </div>
          </div>
          <div className="mt-3 space-y-1.5">
            <div className="flex items-center justify-between text-xs">
              <span className="flex items-center gap-1.5 text-amber-600"><span className="h-2 w-2 rounded-full bg-amber-400" />Pending</span>
              <span className="font-semibold text-slate-700">{proposals.pending}</span>
            </div>
            <div className="flex items-center justify-between text-xs">
              <span className="flex items-center gap-1.5 text-emerald-600"><span className="h-2 w-2 rounded-full bg-emerald-400" />Approved</span>
              <span className="font-semibold text-slate-700">{proposals.approved}</span>
            </div>
            <div className="flex items-center justify-between text-xs">
              <span className="flex items-center gap-1.5 text-slate-500"><FileText className="h-3 w-3" />Final reports</span>
              <span className="font-semibold text-slate-700">{stats.reports}</span>
            </div>
          </div>
        </div>
      </div>

      {/* Recent pending students */}
      {recentPending.length > 0 && (
        <div className="rounded-2xl border border-amber-200 bg-amber-50/50 p-5 shadow-sm">
          <div className="flex items-center justify-between mb-4">
            <div className="flex items-center gap-2">
              <div className="rounded-lg bg-amber-100 p-1.5 text-amber-600">
                <Clock className="h-4 w-4" />
              </div>
              <div>
                <h3 className="text-sm font-bold text-slate-900">Students awaiting approval</h3>
                <p className="text-xs text-slate-500">{stats.pendingApprovals} student{stats.pendingApprovals !== 1 ? "s" : ""} need your review</p>
              </div>
            </div>
            <Link
              href="/hod/students?status=pending"
              className="inline-flex items-center gap-1 rounded-lg bg-amber-600 px-3 py-1.5 text-xs font-semibold text-white hover:bg-amber-700 transition-colors"
            >
              Review all <ChevronRight className="h-3.5 w-3.5" />
            </Link>
          </div>
          <div className="space-y-2">
            {recentPending.map((s) => (
              <div key={s.id} className="flex items-center gap-3 rounded-xl border border-amber-100 bg-white px-4 py-2.5">
                <div className="flex h-8 w-8 shrink-0 items-center justify-center rounded-full bg-amber-100 text-xs font-bold text-amber-700">
                  {s.full_name.split(" ").map((n) => n[0]).join("").toUpperCase().slice(0, 2)}
                </div>
                <div className="min-w-0 flex-1">
                  <p className="text-sm font-semibold text-slate-900 truncate">{s.full_name}</p>
                  <p className="text-xs text-slate-500 truncate">{s.email}</p>
                </div>
                <Link
                  href="/hod/students?status=pending"
                  className="shrink-0 rounded-lg border border-amber-200 bg-amber-50 px-2.5 py-1 text-xs font-semibold text-amber-700 hover:bg-amber-100 transition-colors"
                >
                  Review
                </Link>
              </div>
            ))}
          </div>
        </div>
      )}
    </div>
  );
}
