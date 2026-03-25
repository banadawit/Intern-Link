import React, { useState } from "react";
import { Search, Filter, Eye, Calendar, Building2, GraduationCap } from "lucide-react";
import { format } from "date-fns";
import { VerificationProposal } from "@/lib/superadmin/types";
import { cn } from "@/lib/utils";

interface Props {
  title: string;
  proposals: VerificationProposal[];
  onReview: (proposal: VerificationProposal) => void;
}

const VerificationList = ({ title, proposals, onReview }: Props) => {
  const [searchTerm, setSearchTerm] = useState("");
  const [typeFilter, setTypeFilter] = useState<"All" | "University" | "Company">("All");

  const filteredProposals = proposals.filter((p) => {
    const matchesSearch = p.organizationName.toLowerCase().includes(searchTerm.toLowerCase());
    const matchesType = typeFilter === "All" || p.organizationType === typeFilter;
    return matchesSearch && matchesType;
  });

  return (
    <div className="space-y-6 animate-in fade-in slide-in-from-bottom-4 duration-500">
      <header className="flex flex-col md:flex-row md:items-center justify-between gap-4">
        <div>
          <h1 className="text-3xl font-bold text-slate-900 mb-1">{title}</h1>
          <p className="text-slate-500">Manage and review institutional verification requests.</p>
        </div>
      </header>

      <div className="rounded-2xl border border-slate-200 bg-white overflow-hidden">
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
                <th className="px-6 py-4 font-semibold">Status</th>
                <th className="px-6 py-4 font-semibold text-right">Actions</th>
              </tr>
            </thead>
            <tbody className="divide-y divide-slate-200">
              {filteredProposals.map((p) => (
                <tr key={p.id} className="hover:bg-slate-50 transition-colors group">
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
                      {format(new Date(p.submittedAt), "MMM d, yyyy")}
                    </div>
                  </td>
                  <td className="px-6 py-4">
                    <span
                      className={cn(
                        "px-2.5 py-1 rounded-full text-xs font-medium",
                        p.status === "Pending" && "bg-yellow-50 text-yellow-500 border border-yellow-100",
                        p.status === "Approved" && "bg-green-50 text-green-600 border border-green-100",
                        p.status === "Rejected" && "bg-red-50 text-red-500 border border-red-100"
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
              ))}
              {filteredProposals.length === 0 && (
                <tr>
                  <td colSpan={5} className="px-6 py-12 text-center text-slate-500">
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
