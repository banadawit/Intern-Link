"use client";

import React, { useMemo, useState } from "react";
import { format, formatDistanceToNow } from "date-fns";
import { useTranslations } from "next-intl";
import {
  CheckCircle2,
  XCircle,
  Ban,
  RotateCcw,
  Trash2,
  Activity,
  User,
  Search,
  ChevronLeft,
  ChevronRight,
  Filter,
  FileText,
  X,
  Building2,
  Briefcase,
} from "lucide-react";
import { AuditLogEntry, AuditOrgItem } from "@/lib/superadmin/types";
import { cn } from "@/lib/utils";
import AdminPageHero from "./AdminPageHero";

interface Props {
  logs: AuditLogEntry[];
  currentStats?: { approved: number; rejected: number; suspended: number } | null;
  approvedList?: AuditOrgItem[];
  rejectedList?: AuditOrgItem[];
  suspendedList?: AuditOrgItem[];
}

const PAGE_SIZE = 10;

const ACTION_CONFIG: Record<
  AuditLogEntry["action"],
  { icon: React.ComponentType<{ className?: string }>; label: string; bg: string; text: string; dot: string }
> = {
  Approve:    { icon: CheckCircle2, label: "Approved",    bg: "bg-emerald-50 dark:bg-emerald-900/20", text: "text-emerald-700 dark:text-emerald-400", dot: "bg-emerald-500" },
  Reject:     { icon: XCircle,      label: "Rejected",    bg: "bg-red-50 dark:bg-red-900/20",         text: "text-red-700 dark:text-red-400",         dot: "bg-red-500"     },
  Suspend:    { icon: Ban,          label: "Suspended",   bg: "bg-amber-50 dark:bg-amber-900/20",     text: "text-amber-700 dark:text-amber-400",     dot: "bg-amber-500"   },
  Reactivate: { icon: RotateCcw,    label: "Reactivated", bg: "bg-teal-50 dark:bg-teal-900/20",       text: "text-teal-700 dark:text-teal-400",       dot: "bg-teal-500"    },
  Delete:     { icon: Trash2,       label: "Deleted",     bg: "bg-rose-50 dark:bg-rose-900/20",       text: "text-rose-700 dark:text-rose-400",       dot: "bg-rose-500"    },
  Other:      { icon: Activity,     label: "Other",       bg: "bg-slate-100 dark:bg-slate-800",       text: "text-slate-600 dark:text-slate-400",     dot: "bg-slate-400"   },
};

const FILTER_OPTIONS = ["All", "Approve", "Reject", "Suspend", "Delete", "Other"] as const;
type FilterOption = (typeof FILTER_OPTIONS)[number];

type PanelKind = "approved" | "rejected" | "suspended" | null;

const TYPE_ICON: Record<AuditOrgItem["type"], React.ComponentType<{ className?: string }>> = {
  University:  Building2,
  Company:     Briefcase,
  Coordinator: User,
};

const TYPE_COLOR: Record<AuditOrgItem["type"], string> = {
  University:  "bg-indigo-50 text-indigo-700 dark:bg-indigo-900/20 dark:text-indigo-400",
  Company:     "bg-amber-50 text-amber-700 dark:bg-amber-900/20 dark:text-amber-400",
  Coordinator: "bg-teal-50 text-teal-700 dark:bg-teal-900/20 dark:text-teal-400",
};

// ── Slide-over panel ──────────────────────────────────────────────────────────
function OrgListPanel({
  kind,
  items,
  onClose,
}: {
  kind: PanelKind;
  items: AuditOrgItem[];
  onClose: () => void;
}) {
  const [search, setSearch] = useState("");
  const [typeFilter, setTypeFilter] = useState<AuditOrgItem["type"] | "All">("All");

  const filtered = useMemo(() => {
    const q = search.trim().toLowerCase();
    return items.filter((item) => {
      const matchType = typeFilter === "All" || item.type === typeFilter;
      if (!matchType) return false;
      if (!q) return true;
      return (
        item.name.toLowerCase().includes(q) ||
        item.email.toLowerCase().includes(q) ||
        (item.universityName ?? "").toLowerCase().includes(q)
      );
    });
  }, [items, search, typeFilter]);

  if (!kind) return null;

  const titles: Record<NonNullable<PanelKind>, string> = {
    approved: "Currently Approved",
    rejected: "Currently Rejected",
    suspended: "Currently Suspended",
  };
  const headerColors: Record<NonNullable<PanelKind>, string> = {
    approved: "bg-emerald-600",
    rejected: "bg-red-600",
    suspended: "bg-amber-600",
  };

  const types = [...new Set(items.map((i) => i.type))] as AuditOrgItem["type"][];

  return (
    <>
      {/* Backdrop */}
      <div
        className="fixed inset-0 z-40 bg-black/30 backdrop-blur-sm"
        onClick={onClose}
      />
      {/* Panel */}
      <div className="fixed inset-y-0 right-0 z-50 flex w-full max-w-md flex-col bg-white dark:bg-slate-900 shadow-2xl">
        {/* Header */}
        <div className={cn("flex items-center justify-between px-6 py-4 text-white", headerColors[kind])}>
          <div>
            <p className="text-xs font-semibold uppercase tracking-wider opacity-80">{titles[kind]}</p>
            <p className="text-2xl font-bold">{items.length} {items.length === 1 ? "entry" : "entries"}</p>
          </div>
          <button
            type="button"
            onClick={onClose}
            className="rounded-xl p-2 hover:bg-white/20 transition-colors"
          >
            <X className="h-5 w-5" />
          </button>
        </div>

        {/* Search + type filter */}
        <div className="border-b border-slate-100 dark:border-slate-700 px-4 py-3 space-y-2">
          <div className="relative">
            <Search className="absolute left-3 top-1/2 h-4 w-4 -translate-y-1/2 text-slate-400" />
            <input
              type="text"
              value={search}
              onChange={(e) => setSearch(e.target.value)}
              placeholder="Search by name or email…"
              className="w-full rounded-xl border border-slate-200 dark:border-slate-700 bg-slate-50 dark:bg-slate-800 py-2 pl-9 pr-4 text-sm text-slate-900 dark:text-slate-100 placeholder:text-slate-400 focus:border-teal-500 focus:outline-none focus:ring-2 focus:ring-teal-500/20"
            />
          </div>
          {types.length > 1 && (
            <div className="flex gap-1.5 flex-wrap">
              {(["All", ...types] as const).map((t) => (
                <button
                  key={t}
                  type="button"
                  onClick={() => setTypeFilter(t as AuditOrgItem["type"] | "All")}
                  className={cn(
                    "rounded-full px-3 py-1 text-xs font-semibold transition-all",
                    typeFilter === t
                      ? "bg-slate-800 text-white dark:bg-slate-100 dark:text-slate-900"
                      : "bg-slate-100 dark:bg-slate-800 text-slate-600 dark:text-slate-300 hover:bg-slate-200 dark:hover:bg-slate-700"
                  )}
                >
                  {t === "All" ? `All (${items.length})` : `${t} (${items.filter((i) => i.type === t).length})`}
                </button>
              ))}
            </div>
          )}
        </div>

        {/* List */}
        <div className="flex-1 overflow-y-auto divide-y divide-slate-100 dark:divide-slate-700">
          {filtered.length === 0 ? (
            <div className="flex flex-col items-center justify-center gap-2 py-16 text-slate-400">
              <FileText className="h-8 w-8 opacity-40" />
              <p className="text-sm">No entries match your search.</p>
            </div>
          ) : (
            filtered.map((item) => {
              const Icon = TYPE_ICON[item.type];
              return (
                <div key={`${item.type}-${item.id}`} className="flex items-start gap-3 px-4 py-3 hover:bg-slate-50 dark:hover:bg-slate-800/50 transition-colors">
                  <div className={cn("mt-0.5 shrink-0 rounded-xl p-2", TYPE_COLOR[item.type].split(" ").slice(0, 2).join(" "))}>
                    <Icon className={cn("h-4 w-4", TYPE_COLOR[item.type].split(" ").slice(2).join(" "))} />
                  </div>
                  <div className="min-w-0 flex-1">
                    <div className="flex items-center gap-2 flex-wrap">
                      <span className="text-sm font-semibold text-slate-900 dark:text-slate-100 truncate">
                        {item.name}
                      </span>
                      <span className={cn("rounded-full px-2 py-0.5 text-[10px] font-bold", TYPE_COLOR[item.type])}>
                        {item.type}
                      </span>
                    </div>
                    <p className="text-xs text-slate-500 dark:text-slate-400 truncate">{item.email}</p>
                    {item.universityName && (
                      <p className="text-xs text-slate-400 dark:text-slate-500 truncate">
                        {item.universityName}
                      </p>
                    )}
                    <p className="mt-0.5 text-[10px] text-slate-400">
                      Since {format(new Date(item.since), "MMM d, yyyy")}
                    </p>
                  </div>
                </div>
              );
            })
          )}
        </div>

        {/* Footer count */}
        <div className="border-t border-slate-100 dark:border-slate-700 px-4 py-3 text-xs text-slate-400 text-center">
          Showing {filtered.length} of {items.length}
        </div>
      </div>
    </>
  );
}

// ── Main component ────────────────────────────────────────────────────────────
const AuditLog = ({ logs, currentStats, approvedList = [], rejectedList = [], suspendedList = [] }: Props) => {
  const t = useTranslations("AdminPortal.audit");
  const [search, setSearch] = useState("");
  const [actionFilter, setActionFilter] = useState<FilterOption>("All");
  const [page, setPage] = useState(1);
  const [openPanel, setOpenPanel] = useState<PanelKind>(null);

  const filtered = useMemo(() => {
    const q = search.trim().toLowerCase();
    return logs.filter((l) => {
      const matchesAction = actionFilter === "All" || l.action === actionFilter;
      if (!matchesAction) return false;
      if (!q) return true;
      return (
        l.targetName.toLowerCase().includes(q) ||
        l.adminId.toLowerCase().includes(q) ||
        (l.notes ?? "").toLowerCase().includes(q) ||
        l.rawAction.toLowerCase().includes(q) ||
        l.targetId.includes(q)
      );
    });
  }, [logs, search, actionFilter]);

  const totalPages = Math.max(1, Math.ceil(filtered.length / PAGE_SIZE));
  const safePage = Math.min(page, totalPages);
  const paginated = filtered.slice((safePage - 1) * PAGE_SIZE, safePage * PAGE_SIZE);

  const handleSearch = (v: string) => { setSearch(v); setPage(1); };
  const handleFilter = (v: FilterOption) => { setActionFilter(v); setPage(1); };
  const clearSearch = () => { setSearch(""); setPage(1); };

  const panelItems: Record<NonNullable<PanelKind>, AuditOrgItem[]> = {
    approved: approvedList,
    rejected: rejectedList,
    suspended: suspendedList,
  };

  const statCards = [
    {
      kind: "approved" as const,
      action: "Approve" as const,
      count: currentStats?.approved ?? approvedList.length,
      label: "Currently Approved",
      clickable: approvedList.length > 0,
    },
    {
      kind: "rejected" as const,
      action: "Reject" as const,
      count: currentStats?.rejected ?? rejectedList.length,
      label: "Currently Rejected",
      clickable: rejectedList.length > 0,
    },
    {
      kind: "suspended" as const,
      action: "Suspend" as const,
      count: currentStats?.suspended ?? suspendedList.length,
      label: "Currently Suspended",
      clickable: suspendedList.length > 0,
    },
    {
      kind: null,
      action: "Delete" as const,
      count: logs.filter((l) => l.action === "Delete").length,
      label: "Total Deleted",
      clickable: false,
    },
  ];

  return (
    <div className="space-y-6 animate-in fade-in duration-500">
      <AdminPageHero
        badge={t("heroBadge")}
        title={t("heroTitle")}
        description={t("heroDescription")}
      />

      {/* Stat cards */}
      <div className="grid grid-cols-2 gap-3 sm:grid-cols-4">
        {statCards.map(({ kind, action, count, label, clickable }) => {
          const cfg = ACTION_CONFIG[action];
          return (
            <button
              key={action}
              type="button"
              onClick={() => {
                if (kind) setOpenPanel(kind);
                else handleFilter(actionFilter === action ? "All" : action);
              }}
              className={cn(
                "flex items-center gap-3 rounded-2xl border p-4 text-left transition-all hover:shadow-sm",
                clickable && "cursor-pointer hover:border-teal-300 dark:hover:border-teal-700",
                actionFilter === action && !kind
                  ? "border-teal-200 dark:border-teal-800 bg-teal-50 dark:bg-teal-950/30 shadow-sm"
                  : "border-slate-200 dark:border-slate-700 bg-white dark:bg-slate-900"
              )}
            >
              <div className={cn("rounded-xl p-2", cfg.bg)}>
                <cfg.icon className={cn("h-4 w-4", cfg.text)} />
              </div>
              <div className="min-w-0">
                <p className="text-xl font-bold text-slate-900 dark:text-slate-100">{count}</p>
                <p className="text-xs text-slate-500 dark:text-slate-400 truncate">{label}</p>
                {clickable && (
                  <p className="text-[10px] text-teal-600 dark:text-teal-400 font-medium">View list →</p>
                )}
              </div>
            </button>
          );
        })}
      </div>

      {/* Toolbar */}
      <div className="flex flex-col gap-3 sm:flex-row sm:items-center sm:justify-between">
        <div className="relative max-w-sm flex-1">
          <Search className="absolute left-3 top-1/2 h-4 w-4 -translate-y-1/2 text-slate-400" />
          <input
            type="text"
            value={search}
            onChange={(e) => handleSearch(e.target.value)}
            placeholder="Search by name, admin, action, details…"
            className="w-full rounded-xl border border-slate-200 dark:border-slate-700 bg-white dark:bg-slate-900 py-2.5 pl-9 pr-9 text-sm text-slate-900 dark:text-slate-100 placeholder:text-slate-400 dark:placeholder:text-slate-500 focus:border-teal-500 focus:outline-none focus:ring-2 focus:ring-teal-500/20"
          />
          {search && (
            <button type="button" onClick={clearSearch} className="absolute right-3 top-1/2 -translate-y-1/2 text-slate-400 hover:text-slate-600 dark:hover:text-slate-200">
              <X className="h-4 w-4" />
            </button>
          )}
        </div>
        <div className="flex items-center gap-1.5 flex-wrap">
          <Filter className="h-4 w-4 text-slate-400 shrink-0" />
          {FILTER_OPTIONS.map((a) => (
            <button
              key={a}
              type="button"
              onClick={() => handleFilter(a)}
              className={cn(
                "rounded-full px-3 py-1 text-xs font-semibold transition-all",
                actionFilter === a
                  ? "bg-teal-600 text-white shadow-sm"
                  : "bg-slate-100 dark:bg-slate-800 text-slate-600 dark:text-slate-300 hover:bg-slate-200 dark:hover:bg-slate-700"
              )}
            >
              {a === "All" ? "All Actions" : ACTION_CONFIG[a].label}
            </button>
          ))}
        </div>
      </div>

      {(search || actionFilter !== "All") && (
        <p className="text-xs text-slate-500 dark:text-slate-400">
          {filtered.length === 0 ? "No entries match your search." : `Showing ${filtered.length} of ${logs.length} entries`}
          <button type="button" onClick={() => { clearSearch(); handleFilter("All"); }} className="ml-2 text-teal-600 hover:underline">
            Clear filters
          </button>
        </p>
      )}

      {/* Log entries */}
      <div className="overflow-hidden rounded-2xl border border-slate-200 dark:border-slate-700 bg-white dark:bg-slate-900 shadow-sm">
        {paginated.length === 0 ? (
          <div className="flex flex-col items-center justify-center gap-3 py-16 text-slate-400">
            <FileText className="h-10 w-10 opacity-40" />
            <p className="text-sm font-medium">
              {search || actionFilter !== "All" ? "No entries match your search." : t("empty")}
            </p>
          </div>
        ) : (
          <div className="divide-y divide-slate-100 dark:divide-slate-700">
            {paginated.map((log, idx) => {
              const cfg = ACTION_CONFIG[log.action];
              const date = new Date(log.timestamp);
              const rawLabel = log.rawAction.replace(/_/g, " ").toLowerCase().replace(/\b\w/g, (c) => c.toUpperCase());
              return (
                <div
                  key={log.id}
                  className={cn(
                    "flex items-start gap-4 px-6 py-4 transition-colors hover:bg-slate-50/60 dark:hover:bg-slate-800/40",
                    idx === 0 && "rounded-t-2xl"
                  )}
                >
                  <div className={cn("mt-0.5 shrink-0 rounded-xl p-2", cfg.bg)}>
                    <cfg.icon className={cn("h-4 w-4", cfg.text)} />
                  </div>
                  <div className="min-w-0 flex-1">
                    <div className="flex flex-wrap items-center gap-2">
                      <span className={cn("inline-flex items-center rounded-full px-2.5 py-0.5 text-xs font-bold", cfg.bg, cfg.text)}>
                        {rawLabel}
                      </span>
                      <span className="text-sm font-semibold text-slate-900 dark:text-slate-100 truncate max-w-xs">
                        {log.targetName}
                      </span>
                    </div>
                    {log.notes && log.notes !== log.targetName && (
                      <p className="mt-1 text-xs text-slate-500 dark:text-slate-400 line-clamp-2">{log.notes}</p>
                    )}
                    <div className="mt-2 flex flex-wrap items-center gap-3 text-xs text-slate-400">
                      <span className="flex items-center gap-1"><User className="h-3 w-3" />{log.adminId}</span>
                      <span className="flex items-center gap-1" title={format(date, "PPpp")}>
                        {format(date, "MMM d, yyyy · HH:mm")}
                        <span className="text-slate-300 dark:text-slate-600">·</span>
                        {formatDistanceToNow(date, { addSuffix: true })}
                      </span>
                    </div>
                  </div>
                  <span className="shrink-0 rounded-lg bg-slate-100 dark:bg-slate-800 px-2 py-1 text-[10px] font-mono text-slate-500 dark:text-slate-400">
                    #{log.targetId}
                  </span>
                </div>
              );
            })}
          </div>
        )}
      </div>

      {/* Pagination */}
      {filtered.length > PAGE_SIZE && (
        <div className="flex flex-col items-center gap-3 pb-6">
          <p className="text-sm text-slate-500 dark:text-slate-400">
            {t("paginationRange", {
              start: (safePage - 1) * PAGE_SIZE + 1,
              end: Math.min(safePage * PAGE_SIZE, filtered.length),
              total: filtered.length,
            })}
          </p>
          <div className="flex items-center gap-1">
            <button type="button" onClick={() => setPage((p) => Math.max(1, p - 1))} disabled={safePage === 1}
              className="rounded-xl border border-slate-200 dark:border-slate-700 bg-white dark:bg-slate-900 p-2 text-slate-600 dark:text-slate-300 hover:bg-slate-50 dark:hover:bg-slate-800 disabled:opacity-40 disabled:cursor-not-allowed transition-colors">
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
                  <button key={p} type="button" onClick={() => setPage(p as number)}
                    className={cn("min-w-[2rem] rounded-xl border px-3 py-1.5 text-sm font-medium transition-all",
                      safePage === p
                        ? "border-teal-600 bg-teal-600 text-white shadow-sm"
                        : "border-slate-200 dark:border-slate-700 bg-white dark:bg-slate-900 text-slate-600 dark:text-slate-300 hover:bg-slate-50 dark:hover:bg-slate-800"
                    )}>
                    {p}
                  </button>
                )
              )}
            <button type="button" onClick={() => setPage((p) => Math.min(totalPages, p + 1))} disabled={safePage === totalPages}
              className="rounded-xl border border-slate-200 dark:border-slate-700 bg-white dark:bg-slate-900 p-2 text-slate-600 dark:text-slate-300 hover:bg-slate-50 dark:hover:bg-slate-800 disabled:opacity-40 disabled:cursor-not-allowed transition-colors">
              <ChevronRight className="h-4 w-4" />
            </button>
          </div>
        </div>
      )}

      {/* Slide-over panel */}
      {openPanel && (
        <OrgListPanel
          kind={openPanel}
          items={panelItems[openPanel]}
          onClose={() => setOpenPanel(null)}
        />
      )}
    </div>
  );
};

export default AuditLog;
