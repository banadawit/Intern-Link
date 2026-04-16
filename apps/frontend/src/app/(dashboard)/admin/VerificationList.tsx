"use client";

import React, { useState } from "react";
import { Search, Filter, Eye, Calendar, Building2, GraduationCap } from "lucide-react";
import { format } from "date-fns";
import { VerificationProposal } from "@/lib/superadmin/types";
import { getPendingVerificationSla } from "@/lib/superadmin/verificationSla";
import { cn } from "@/lib/utils";
import AdminPageHero from "./AdminPageHero";
import { Timer } from "lucide-react";

interface Props {
  title: string;
  proposals: VerificationProposal[];
  onReview: (proposal: VerificationProposal) => void;
  loading?: boolean;
  hideHero?: boolean;
}

const VerificationList = ({ title, proposals, onReview, loading, hideHero = false }: Props) => {
  const [searchTerm, setSearchTerm] = useState("");
  const [typeFilter, setTypeFilter] = useState<"All" | "University" | "Company">("All");

  const filteredProposals = proposals.filter((p) => {
    const matchesSearch = p.organizationName.toLowerCase().includes(searchTerm.toLowerCase());
    const matchesType = typeFilter === "All" || p.organizationType === typeFilter;
    return matchesSearch && matchesType;
  });

  return (
    <div className="space-y-6 animate-in fade-in slide-in-from-bottom-4 duration-500">
      {!hideHero && (
        <AdminPageHero
          badge="Verification"
          title={title}
          description="Manage and review institutional verification requests."
        />
      )}

      {loading && (
        <p className="text-sm text-slate-500" role="status">
          Loading organizations…
        </p>
      )}

      <div className="card overflow-hidden">
        <div className="p-4 border-b border-slate-200 bg-slate-50 flex flex-col md:flex-row gap-4">
          <div className="relative flex-1">
            <Search className="absolute left-3 top-1/2 -translate-y-1/2 w-4 h-4 text-slate-500" />
            <input type="text" placeholder="Search organizations..." className="w-full rounded-lg border border-slate-200 bg-white pl-10 py-2 text-sm text-slate-600 placeholder:text-slate-400 focus:outline-none focus:ring-2 focus:ring-teal-500" value={searchTerm} onChange={(e) => setSearchTerm(e.target.value)} />
          </div>
          <div className="flex gap-2">
            <select className="rounded-lg border border-slate-200 bg-white px-3 py-2 text-sm text-slate-600 focus:outline-none focus:ring-2 focus:ring-teal-500" value={typeFilter} onChange={(e) => setTypeFilter(e.target.value as "All" | "University" | "Company")}>
              <option value="All">All Types</option>
              <option value="University">Universities</option>
              <option value="Company">Companies</option>
            </select>
            <button className="flex items-center gap-2 rounded-lg bg-teal-600 px-4 py-2 text-sm font-medium text-white hover:bg-teal-700 active:bg-teal-800">
              <Filter className="w-4 h-4" />
              More Filters
            </button>
          </div>
        </div>

        <div className="overflow-x-auto">
          <table className="w-full text-left">
            <thead>
              <tr className="bg-slate-100 text-slate-500 text-xs uppercase tracking-wider">
                <th className="px-6 py-4 font-semibold">Organization</th>
                <th className="px-6 py-4 font-semibold">Type</th>
                <th className="px-6 py-4 font-semibold">Submitted</th>
                <th className="px-6 py-4 font-semibold">24h response</th>
                <th className="px-6 py-4 font-semibold">Status</th>
                <th className="px-6 py-4 font-semibold text-right">Actions</th>
              </tr>
            </thead>
            <tbody className="divide-y divide-slate-200">
              {filteredProposals.map((p) => {
                const sla = p.status === "Pending" ? getPendingVerificationSla(p.submittedAt) : null;
                return (
                <tr key={p.id} className={cn("hover:bg-slate-50 transition-colors group", sla?.isOverdue && "bg-red-50/40")}>
                  <td className="px-6 py-4">
                    <div className="flex items-center gap-3">
                      <div className={cn("p-2 rounded-lg", p.organizationType === "University" ? "bg-teal-50 text-teal-600" : "bg-blue-50 text-blue-600")}>
                        {p.organizationType === "University" ? <GraduationCap className="w-5 h-5" /> : <Building2 className="w-5 h-5" />}
                      </div>
                      <span className="font-semibold text-slate-900">{p.organizationName}</span>
                    </div>
                  </td>
                  <td className="px-6 py-4 text-sm text-slate-600">{p.organizationType}</td>
                  <td className="px-6 py-4 text-sm text-slate-500">
                    <div className="flex items-center gap-2">
                      <Calendar className="w-4 h-4" />
                      {format(new Date(p.submittedAt), "MMM d, yyyy HH:mm")}
                    </div>
                  </td>
                  <td className="px-6 py-4 text-sm">
                    {sla ? (
                      <div className="flex flex-col gap-1">
                        <span
                          className={cn(
                            "inline-flex w-fit items-center gap-1 rounded-full px-2 py-0.5 text-xs font-semibold tabular-nums",
                            sla.isOverdue
                              ? "bg-red-100 text-red-800 ring-1 ring-red-200"
                              : "bg-amber-50 text-amber-900 ring-1 ring-amber-200"
                          )}
                        >
                          <Timer className="h-3 w-3 shrink-0" aria-hidden />
                          {sla.label}
                        </span>
                        <span className="text-[11px] text-slate-500">
                          Due {format(sla.deadline, "MMM d, HH:mm")}
                        </span>
                      </div>
                    ) : (
                      <span className="text-slate-400">—</span>
                    )}
                  </td>
                  <td className="px-6 py-4">
                    <span
                      className={cn(
                        "px-2.5 py-1 rounded-full text-xs font-medium",
                        p.status === "Pending" && "bg-yellow-50 text-yellow-500 border border-yellow-100",
                        p.status === "Approved" && "bg-green-50 text-green-600 border border-green-100",
                        p.status === "Rejected" && "bg-red-50 text-red-500 border border-red-100",
                        p.status === "Suspended" && "bg-slate-100 text-slate-700 border border-slate-200"
                      )}
                    >
                      {p.status}
                    </span>
                  </td>
                  <td className="px-6 py-4 text-right">
                    <button onClick={() => onReview(p)} className="p-2 hover:bg-slate-100 rounded-lg transition-colors text-teal-600" title="Review Proposal">
                      <Eye className="w-5 h-5" />
                    </button>
                  </td>
                </tr>
              );
              })}
              {filteredProposals.length === 0 && (
                <tr>
                  <td colSpan={6} className="px-6 py-12 text-center text-slate-500">
                    No proposals found matching your criteria.
                  </td>
                </tr>
              )}
            </tbody>
          </table>
        </div>
      </div>
    </div>
  );
};

export default VerificationList;
