"use client";

import React, { useState, useMemo } from "react";
import {
  Building,
  Briefcase,
  Search,
  CheckCircle2,
  XCircle,
  Ban,
  RotateCcw,
  Loader2,
  ExternalLink,
  Filter,
} from "lucide-react";
import { format } from "date-fns";
import { cn } from "@/lib/utils";
import AdminPageHero from "./AdminPageHero";
import { VerificationProposal } from "@/lib/superadmin/types";

type OrgTab = "universities" | "companies";

const STATUS_CONFIG = {
  Pending:   { bg: "bg-amber-50",   text: "text-amber-700",   ring: "ring-amber-200"   },
  Approved:  { bg: "bg-emerald-50", text: "text-emerald-700", ring: "ring-emerald-200" },
  Rejected:  { bg: "bg-red-50",     text: "text-red-700",     ring: "ring-red-200"     },
  Suspended: { bg: "bg-slate-100",  text: "text-slate-600",   ring: "ring-slate-200"   },
};

interface Props {
  proposals: VerificationProposal[];
  loading: boolean;
  onReview: (p: VerificationProposal) => void;
  onActionComplete: () => void;
}

export default function OrganizationsView({ proposals, loading, onReview }: Props) {
  const [tab, setTab] = useState<OrgTab>("universities");
  const [search, setSearch] = useState("");
  const [statusFilter, setStatusFilter] = useState<"All" | "Pending" | "Approved" | "Rejected" | "Suspended">("All");

  const filtered = useMemo(() => {
    const q = search.toLowerCase();
    return proposals.filter((p) => {
      const matchesType = tab === "universities" ? p.organizationType === "University" : p.organizationType === "Company";
      const matchesSearch = !q || p.organizationName.toLowerCase().includes(q) || (p.description ?? "").toLowerCase().includes(q);
      const matchesStatus = statusFilter === "All" || p.status === statusFilter;
      return matchesType && matchesSearch && matchesStatus;
    });
  }, [proposals, tab, search, statusFilter]);

  const counts = useMemo(() => {
    const byType = (type: "University" | "Company") => proposals.filter((p) => p.organizationType === type);
    return {
      universities: byType("University").length,
      uniPending: byType("University").filter((p) => p.status === "Pending").length,
      companies: byType("Company").length,
      compPending: byType("Company").filter((p) => p.status === "Pending").length,
    };
  }, [proposals]);

  return (
    <div className="space-y-6 animate-in fade-in slide-in-from-bottom-4 duration-500">
      <AdminPageHero
        badge="Organizations"
        title="Organizations"
        description="Manage all universities and companies registered on the platform."
      />

      {/* Tab bar */}
      <div className="flex gap-1 rounded-2xl border border-slate-200 bg-slate-50 p-1">
        {([
          { id: "universities" as const, label: "Universities", icon: Building, count: counts.universities, pending: counts.uniPending },
          { id: "companies" as const, label: "Companies", icon: Briefcase, count: counts.companies, pending: counts.compPending },
        ]).map((t) => (
          <button
            key={t.id}
            type="button"
            onClick={() => { setTab(t.id); setSearch(""); setStatusFilter("All"); }}
            className={cn(
              "flex flex-1 items-center justify-center gap-2 rounded-xl px-4 py-2.5 text-sm font-medium transition-all duration-200",
              tab === t.id ? "bg-white text-teal-700 shadow-sm ring-1 ring-slate-200" : "text-slate-500 hover:text-slate-700"
            )}
          >
            <t.icon className="h-4 w-4 shrink-0" />
            <span className="hidden sm:inline">{t.label}</span>
            <span className={cn("rounded-full px-1.5 py-0.5 text-[10px] font-bold tabular-nums",
              tab === t.id ? "bg-teal-100 text-teal-800" : "bg-slate-200 text-slate-600"
            )}>{t.count}</span>
            {t.pending > 0 && (
              <span className="rounded-full bg-amber-100 px-1.5 py-0.5 text-[10px] font-bold tabular-nums text-amber-800">
                {t.pending} pending
              </span>
            )}
          </button>
        ))}
      </div>

      {/* Toolbar */}
      <div className="flex flex-col gap-3 sm:flex-row sm:items-center">
        <div className="relative flex-1 max-w-sm">
          <Search className="absolute left-3 top-1/2 h-4 w-4 -translate-y-1/2 text-slate-400" />
          <input
            type="text"
            value={search}
            onChange={(e) => setSearch(e.target.value)}
            placeholder={`Search ${tab}…`}
            className="w-full rounded-xl border border-slate-200 bg-white py-2.5 pl-9 pr-4 text-sm text-slate-900 placeholder:text-slate-400 focus:border-teal-500 focus:outline-none focus:ring-2 focus:ring-teal-500/20"
          />
        </div>
        <div className="flex items-center gap-1.5 flex-wrap">
          <Filter className="h-4 w-4 text-slate-400 shrink-0" />
          {(["All", "Pending", "Approved", "Rejected", "Suspended"] as const).map((s) => (
            <button
              key={s}
              type="button"
              onClick={() => setStatusFilter(s)}
              className={cn(
                "rounded-full px-3 py-1 text-xs font-semibold transition-all",
                statusFilter === s ? "bg-teal-600 text-white shadow-sm" : "bg-slate-100 text-slate-600 hover:bg-slate-200"
              )}
            >
              {s}
            </button>
          ))}
        </div>
      </div>

      {/* Table */}
      <div className="overflow-hidden rounded-2xl border border-slate-200 bg-white shadow-sm">
        {loading ? (
          <div className="flex min-h-[30vh] items-center justify-center">
            <Loader2 className="h-8 w-8 animate-spin text-teal-600" />
          </div>
        ) : filtered.length === 0 ? (
          <div className="flex min-h-[20vh] items-center justify-center text-sm text-slate-400">
            No {tab} match your filters.
          </div>
        ) : (
          <div className="overflow-x-auto">
            <table className="w-full text-left text-sm">
              <thead>
                <tr className="border-b border-slate-100 bg-slate-50 text-xs font-semibold uppercase tracking-wider text-slate-500">
                  <th className="px-6 py-3">Name</th>
                  <th className="px-6 py-3">Status</th>
                  <th className="px-6 py-3">Registered</th>
                  <th className="px-6 py-3">Document</th>
                  <th className="px-6 py-3 text-right">Actions</th>
                </tr>
              </thead>
              <tbody className="divide-y divide-slate-100">
                {filtered.map((p) => {
                  const cfg = STATUS_CONFIG[p.status] ?? STATUS_CONFIG.Pending;
                  return (
                    <tr key={p.id} className="hover:bg-slate-50/60 transition-colors">
                      <td className="px-6 py-4">
                        <p className="font-semibold text-slate-900">{p.organizationName}</p>
                        {p.description && <p className="text-xs text-slate-400 truncate max-w-xs">{p.description}</p>}
                      </td>
                      <td className="px-6 py-4">
                        <span className={cn("inline-flex items-center rounded-full px-2.5 py-0.5 text-xs font-bold ring-1", cfg.bg, cfg.text, cfg.ring)}>
                          {p.status}
                        </span>
                      </td>
                      <td className="px-6 py-4 text-slate-500 text-xs">
                        {format(new Date(p.submittedAt), "MMM d, yyyy")}
                      </td>
                      <td className="px-6 py-4">
                        {p.documents?.[0] ? (
                          <a href={p.documents[0]} target="_blank" rel="noopener noreferrer"
                            className="inline-flex items-center gap-1 text-xs font-medium text-teal-600 hover:text-teal-700">
                            View <ExternalLink className="h-3 w-3" />
                          </a>
                        ) : (
                          <span className="text-xs text-slate-400 italic">None</span>
                        )}
                      </td>
                      <td className="px-6 py-4">
                        <div className="flex items-center justify-end gap-1.5">
                          <button
                            type="button"
                            onClick={() => onReview(p)}
                            className="rounded-lg border border-slate-200 bg-white px-3 py-1.5 text-xs font-semibold text-slate-700 hover:bg-slate-50 transition-colors"
                          >
                            Review
                          </button>
                          {p.status === "Pending" && (
                            <button type="button" onClick={() => onReview(p)}
                              className="inline-flex items-center gap-1 rounded-lg bg-emerald-600 px-3 py-1.5 text-xs font-semibold text-white hover:bg-emerald-700 transition-colors">
                              <CheckCircle2 className="h-3.5 w-3.5" /> Approve
                            </button>
                          )}
                          {p.status === "Approved" && (
                            <button type="button" onClick={() => onReview(p)}
                              className="inline-flex items-center gap-1 rounded-lg bg-amber-50 border border-amber-200 px-3 py-1.5 text-xs font-semibold text-amber-700 hover:bg-amber-100 transition-colors">
                              <Ban className="h-3.5 w-3.5" /> Suspend
                            </button>
                          )}
                          {p.status === "Suspended" && (
                            <button type="button" onClick={() => onReview(p)}
                              className="inline-flex items-center gap-1 rounded-lg bg-teal-50 border border-teal-200 px-3 py-1.5 text-xs font-semibold text-teal-700 hover:bg-teal-100 transition-colors">
                              <RotateCcw className="h-3.5 w-3.5" /> Reactivate
                            </button>
                          )}
                          {(p.status === "Pending" || p.status === "Approved") && (
                            <button type="button" onClick={() => onReview(p)}
                              className="inline-flex items-center gap-1 rounded-lg bg-red-50 border border-red-200 px-3 py-1.5 text-xs font-semibold text-red-600 hover:bg-red-100 transition-colors">
                              <XCircle className="h-3.5 w-3.5" /> Reject
                            </button>
                          )}
                        </div>
                      </td>
                    </tr>
                  );
                })}
              </tbody>
            </table>
          </div>
        )}
      </div>

      <p className="text-xs text-slate-400 text-right">
        Showing {filtered.length} of {proposals.filter((p) => tab === "universities" ? p.organizationType === "University" : p.organizationType === "Company").length} {tab}
      </p>
    </div>
  );
}
