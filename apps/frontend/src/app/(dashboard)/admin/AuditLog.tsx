"use client";

import React, { useMemo, useState } from "react";
import { format, formatDistanceToNow } from "date-fns";
import {
  CheckCircle2,
  XCircle,
  Ban,
  RotateCcw,
  User,
  Search,
  ChevronLeft,
  ChevronRight,
  Filter,
  FileText,
} from "lucide-react";
import { AuditLogEntry } from "@/lib/superadmin/types";
import { cn } from "@/lib/utils";
import AdminPageHero from "./AdminPageHero";

interface Props {
  logs: AuditLogEntry[];
}

const PAGE_SIZE = 10;

const ACTION_CONFIG: Record<
  AuditLogEntry["action"],
  { icon: React.ComponentType<{ className?: string }>; label: string; bg: string; text: string; dot: string }
> = {
  Approve: {
    icon: CheckCircle2,
    label: "Approved",
    bg: "bg-emerald-50",
    text: "text-emerald-700",
    dot: "bg-emerald-500",
  },
  Reject: {
    icon: XCircle,
    label: "Rejected",
    bg: "bg-red-50",
    text: "text-red-700",
    dot: "bg-red-500",
  },
  Suspend: {
    icon: Ban,
    label: "Suspended",
    bg: "bg-amber-50",
    text: "text-amber-700",
    dot: "bg-amber-500",
  },
  Reactivate: {
    icon: RotateCcw,
    label: "Reactivated",
    bg: "bg-teal-50",
    text: "text-teal-700",
    dot: "bg-teal-500",
  },
};

const AuditLog = ({ logs }: Props) => {
  const [search, setSearch] = useState("");
  const [actionFilter, setActionFilter] = useState<AuditLogEntry["action"] | "All">("All");
  const [page, setPage] = useState(1);

  const filtered = useMemo(() => {
    const q = search.toLowerCase();
    return logs.filter((l) => {
      const matchesSearch =
        !q ||
        l.targetName.toLowerCase().includes(q) ||
        l.adminId.toLowerCase().includes(q) ||
        (l.notes ?? "").toLowerCase().includes(q);
      const matchesAction = actionFilter === "All" || l.action === actionFilter;
      return matchesSearch && matchesAction;
    });
  }, [logs, search, actionFilter]);

  const totalPages = Math.max(1, Math.ceil(filtered.length / PAGE_SIZE));
  const safePage = Math.min(page, totalPages);
  const paginated = filtered.slice((safePage - 1) * PAGE_SIZE, safePage * PAGE_SIZE);

  const handleSearch = (v: string) => { setSearch(v); setPage(1); };
  const handleFilter = (v: AuditLogEntry["action"] | "All") => { setActionFilter(v); setPage(1); };

  return (
    <div className="space-y-6 animate-in fade-in duration-500">
      <AdminPageHero
        badge="Compliance"
        title="Audit Log"
        description="Complete history of verification decisions and administrative actions."
      />

      {/* Toolbar */}
      <div className="flex flex-col gap-3 sm:flex-row sm:items-center sm:justify-between">
        {/* Search */}
        <div className="relative max-w-sm flex-1">
          <Search className="absolute left-3 top-1/2 h-4 w-4 -translate-y-1/2 text-slate-400" />
          <input
            type="text"
            value={search}
            onChange={(e) => handleSearch(e.target.value)}
            placeholder="Search by organization, admin, or notes…"
            className="w-full rounded-xl border border-slate-200 bg-white py-2.5 pl-9 pr-4 text-sm text-slate-900 placeholder:text-slate-400 focus:border-teal-500 focus:outline-none focus:ring-2 focus:ring-teal-500/20"
          />
        </div>

        {/* Action filter pills */}
        <div className="flex items-center gap-1.5 flex-wrap">
          <Filter className="h-4 w-4 text-slate-400 shrink-0" />
          {(["All", "Approve", "Reject", "Suspend", "Reactivate"] as const).map((a) => (
            <button
              key={a}
              type="button"
              onClick={() => handleFilter(a)}
              className={cn(
                "rounded-full px-3 py-1 text-xs font-semibold transition-all",
                actionFilter === a
                  ? "bg-teal-600 text-white shadow-sm"
                  : "bg-slate-100 text-slate-600 hover:bg-slate-200"
              )}
            >
              {a === "All" ? "All actions" : ACTION_CONFIG[a].label}
            </button>
          ))}
        </div>
      </div>

      {/* Stats row */}
      <div className="grid grid-cols-2 gap-3 sm:grid-cols-4">
        {(["Approve", "Reject", "Suspend", "Reactivate"] as const).map((a) => {
          const cfg = ACTION_CONFIG[a];
          const count = logs.filter((l) => l.action === a).length;
          return (
            <button
              key={a}
              type="button"
              onClick={() => handleFilter(actionFilter === a ? "All" : a)}
              className={cn(
                "flex items-center gap-3 rounded-2xl border p-4 text-left transition-all hover:shadow-sm",
                actionFilter === a ? "border-teal-200 bg-teal-50 shadow-sm" : "border-slate-200 bg-white"
              )}
            >
              <div className={cn("rounded-xl p-2", cfg.bg)}>
                <cfg.icon className={cn("h-4 w-4", cfg.text)} />
              </div>
              <div>
                <p className="text-xl font-bold text-slate-900">{count}</p>
                <p className="text-xs text-slate-500">{cfg.label}</p>
              </div>
            </button>
          );
        })}
      </div>

      {/* Log entries */}
      <div className="overflow-hidden rounded-2xl border border-slate-200 bg-white shadow-sm">
        {paginated.length === 0 ? (
          <div className="flex flex-col items-center justify-center gap-3 py-16 text-slate-400">
            <FileText className="h-10 w-10 opacity-40" />
            <p className="text-sm font-medium">No audit entries match your filters.</p>
          </div>
        ) : (
          <div className="divide-y divide-slate-100">
            {paginated.map((log, idx) => {
              const cfg = ACTION_CONFIG[log.action];
              const date = new Date(log.timestamp);
              return (
                <div
                  key={log.id}
                  className={cn(
                    "flex items-start gap-4 px-6 py-4 transition-colors hover:bg-slate-50/60",
                    idx === 0 && "rounded-t-2xl"
                  )}
                >
                  {/* Action icon */}
                  <div className={cn("mt-0.5 shrink-0 rounded-xl p-2", cfg.bg)}>
                    <cfg.icon className={cn("h-4 w-4", cfg.text)} />
                  </div>

                  {/* Main content */}
                  <div className="min-w-0 flex-1">
                    <div className="flex flex-wrap items-center gap-2">
                      <span
                        className={cn(
                          "inline-flex items-center rounded-full px-2.5 py-0.5 text-xs font-bold",
                          cfg.bg,
                          cfg.text
                        )}
                      >
                        {cfg.label}
                      </span>
                      <span className="text-sm font-semibold text-slate-900 truncate max-w-xs">
                        {log.targetName}
                      </span>
                    </div>

                    {log.notes && (
                      <p className="mt-1 text-xs text-slate-500 line-clamp-2">{log.notes}</p>
                    )}

                    <div className="mt-2 flex flex-wrap items-center gap-3 text-xs text-slate-400">
                      <span className="flex items-center gap-1">
                        <User className="h-3 w-3" />
                        {log.adminId}
                      </span>
                      <span className="flex items-center gap-1" title={format(date, "PPpp")}>
                        {format(date, "MMM d, yyyy · HH:mm")}
                        <span className="text-slate-300">·</span>
                        {formatDistanceToNow(date, { addSuffix: true })}
                      </span>
                    </div>
                  </div>

                  {/* Target ID badge */}
                  <span className="shrink-0 rounded-lg bg-slate-100 px-2 py-1 text-[10px] font-mono text-slate-500">
                    #{log.targetId}
                  </span>
                </div>
              );
            })}
          </div>
        )}
      </div>

      {/* Pagination */}
      {totalPages > 1 && (
        <div className="flex flex-col items-center gap-3 pb-6">
          <p className="text-sm text-slate-500">
            Showing{" "}
            <span className="font-semibold text-slate-700">
              {(safePage - 1) * PAGE_SIZE + 1}–{Math.min(safePage * PAGE_SIZE, filtered.length)}
            </span>{" "}
            of <span className="font-semibold text-slate-700">{filtered.length}</span> entries
          </p>

          <div className="flex items-center gap-1">
            <button
              type="button"
              onClick={() => setPage((p) => Math.max(1, p - 1))}
              disabled={safePage === 1}
              className="rounded-xl border border-slate-200 bg-white p-2 text-slate-600 hover:bg-slate-50 disabled:opacity-40 disabled:cursor-not-allowed transition-colors"
            >
              <ChevronLeft className="h-4 w-4" />
            </button>

            {Array.from({ length: totalPages }, (_, i) => i + 1)
              .filter((p) => p === 1 || p === totalPages || Math.abs(p - safePage) <= 1)
              .reduce<(number | "…")[]>((acc, p, i, arr) => {
                if (i > 0 && (p as number) - (arr[i - 1] as number) > 1) acc.push("…");
                acc.push(p);
                return acc;
              }, [])
              .map((p, i) =>
                p === "…" ? (
                  <span key={`ellipsis-${i}`} className="px-2 text-slate-400 text-sm">…</span>
                ) : (
                  <button
                    key={p}
                    type="button"
                    onClick={() => setPage(p as number)}
                    className={cn(
                      "min-w-[2rem] rounded-xl border px-3 py-1.5 text-sm font-medium transition-all",
                      safePage === p
                        ? "border-teal-600 bg-teal-600 text-white shadow-sm"
                        : "border-slate-200 bg-white text-slate-600 hover:bg-slate-50"
                    )}
                  >
                    {p}
                  </button>
                )
              )}

            <button
              type="button"
              onClick={() => setPage((p) => Math.min(totalPages, p + 1))}
              disabled={safePage === totalPages}
              className="rounded-xl border border-slate-200 bg-white p-2 text-slate-600 hover:bg-slate-50 disabled:opacity-40 disabled:cursor-not-allowed transition-colors"
            >
              <ChevronRight className="h-4 w-4" />
            </button>
          </div>
        </div>
      )}
    </div>
  );
};

export default AuditLog;
