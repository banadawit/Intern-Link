"use client";

import { useMemo, useState } from "react";
import { Building2, Mail, MapPin, Users, Briefcase, Search, Calendar } from "lucide-react";
import { format } from "date-fns";
import type { HodCompanyRow } from "./types";
import { cn } from "@/lib/utils";

type Props = { companies: HodCompanyRow[] };

export default function HodCompanyDirectory({ companies }: Props) {
  const [searchQuery, setSearchQuery] = useState("");
  const [sortBy, setSortBy] = useState<"name" | "placements" | "recent">("name");

  const filtered = useMemo(() => {
    const q = searchQuery.trim().toLowerCase();
    let result = q ? companies.filter((c) => 
      c.name.toLowerCase().includes(q) || 
      c.official_email.toLowerCase().includes(q) ||
      c.address?.toLowerCase().includes(q)
    ) : companies;

    // Sort
    if (sortBy === "name") {
      result = [...result].sort((a, b) => a.name.localeCompare(b.name));
    } else if (sortBy === "placements") {
      result = [...result].sort((a, b) => b.activePlacementsCount - a.activePlacementsCount);
    } else if (sortBy === "recent") {
      result = [...result].sort((a, b) => new Date(b.created_at).getTime() - new Date(a.created_at).getTime());
    }

    return result;
  }, [companies, searchQuery, sortBy]);

  return (
    <div className="space-y-6">
      {/* Search and filters */}
      <div className="flex flex-col gap-4 sm:flex-row sm:items-center sm:justify-between">
        <div className="relative flex-1 max-w-md">
          <Search className="absolute left-3 top-1/2 -translate-y-1/2 h-4 w-4 text-slate-400" />
          <input
            type="search"
            value={searchQuery}
            onChange={(e) => setSearchQuery(e.target.value)}
            placeholder="Search companies by name, email, or location..."
            className="w-full rounded-xl border border-slate-200 bg-white pl-10 pr-4 py-2.5 text-sm text-slate-900 placeholder:text-slate-400 focus:border-primary-500 focus:outline-none focus:ring-2 focus:ring-primary-500/20"
          />
        </div>

        <div className="flex items-center gap-2">
          <span className="text-sm text-slate-500 shrink-0">Sort by:</span>
          <select
            value={sortBy}
            onChange={(e) => setSortBy(e.target.value as typeof sortBy)}
            className="rounded-lg border border-slate-200 bg-white px-3 py-2 text-sm text-slate-700 focus:border-primary-500 focus:outline-none focus:ring-2 focus:ring-primary-500/20"
          >
            <option value="name">Name (A-Z)</option>
            <option value="placements">Active placements</option>
            <option value="recent">Recently added</option>
          </select>
        </div>
      </div>

      {/* Stats summary */}
      <div className="grid grid-cols-2 gap-4 sm:grid-cols-4">
        {[
          { label: "Total companies", value: companies.length, icon: Building2, color: "bg-primary-50 text-primary-600" },
          { label: "Active placements", value: companies.reduce((sum, c) => sum + c.activePlacementsCount, 0), icon: Briefcase, color: "bg-emerald-50 text-emerald-600" },
          { label: "Total supervisors", value: companies.reduce((sum, c) => sum + c.supervisorCount, 0), icon: Users, color: "bg-blue-50 text-blue-600" },
          { label: "Showing results", value: filtered.length, icon: Search, color: "bg-violet-50 text-violet-600" },
        ].map((stat) => (
          <div key={stat.label} className="flex items-center gap-3 rounded-2xl border border-slate-200 bg-white p-4 shadow-sm">
            <div className={cn("rounded-xl p-2.5", stat.color)}>
              <stat.icon className="h-5 w-5" />
            </div>
            <div>
              <p className="text-xs font-semibold uppercase tracking-wide text-slate-400">{stat.label}</p>
              <p className="text-xl font-bold text-slate-900">{stat.value}</p>
            </div>
          </div>
        ))}
      </div>

      {/* Company cards grid */}
      {filtered.length === 0 ? (
        <div className="flex flex-col items-center justify-center rounded-2xl border-2 border-dashed border-slate-200 bg-white py-16 text-center">
          <Building2 className="h-12 w-12 text-slate-300 mb-3" />
          <p className="text-base font-semibold text-slate-600">No companies found</p>
          <p className="text-sm text-slate-400 mt-1">Try adjusting your search or filters.</p>
        </div>
      ) : (
        <div className="grid gap-5 sm:grid-cols-2 xl:grid-cols-3">
          {filtered.map((company) => (
            <div
              key={company.id}
              className="group flex flex-col rounded-2xl border border-slate-200 bg-white shadow-sm transition-all hover:shadow-md hover:border-primary-200"
            >
              {/* Card header */}
              <div className="flex items-start gap-3 border-b border-slate-100 px-5 py-4">
                <div className="rounded-xl bg-primary-50 p-2.5 text-primary-600 shrink-0 group-hover:bg-primary-100 transition-colors">
                  <Building2 className="h-5 w-5" />
                </div>
                <div className="min-w-0 flex-1">
                  <h3 className="font-bold text-slate-900 truncate group-hover:text-primary-600 transition-colors">
                    {company.name}
                  </h3>
                  <p className="text-xs text-slate-400 mt-0.5">
                    Joined {format(new Date(company.created_at), "MMM yyyy")}
                  </p>
                </div>
              </div>

              {/* Card body */}
              <div className="flex-1 px-5 py-4 space-y-3">
                <div className="flex items-start gap-2.5">
                  <Mail className="h-4 w-4 text-slate-400 shrink-0 mt-0.5" />
                  <div className="min-w-0">
                    <p className="text-xs font-medium text-slate-500">Email</p>
                    <p className="text-sm text-slate-700 truncate">{company.official_email}</p>
                  </div>
                </div>

                {company.address && (
                  <div className="flex items-start gap-2.5">
                    <MapPin className="h-4 w-4 text-slate-400 shrink-0 mt-0.5" />
                    <div className="min-w-0">
                      <p className="text-xs font-medium text-slate-500">Location</p>
                      <p className="text-sm text-slate-700 line-clamp-2">{company.address}</p>
                    </div>
                  </div>
                )}

                <div className="flex items-center gap-4 pt-2">
                  <div className="flex items-center gap-1.5">
                    <Users className="h-4 w-4 text-slate-400" />
                    <span className="text-sm font-medium text-slate-700">{company.supervisorCount}</span>
                    <span className="text-xs text-slate-400">supervisor{company.supervisorCount !== 1 ? "s" : ""}</span>
                  </div>
                  <div className="flex items-center gap-1.5">
                    <Briefcase className="h-4 w-4 text-emerald-500" />
                    <span className="text-sm font-medium text-emerald-700">{company.activePlacementsCount}</span>
                    <span className="text-xs text-slate-400">active</span>
                  </div>
                </div>
              </div>

              {/* Card footer */}
              <div className="border-t border-slate-100 px-5 py-3 bg-slate-50/50">
                <div className="flex items-center justify-between">
                  <span className="inline-flex items-center gap-1.5 rounded-full bg-emerald-100 px-2.5 py-1 text-xs font-medium text-emerald-700">
                    <span className="h-1.5 w-1.5 rounded-full bg-emerald-500" />
                    Verified
                  </span>
                  <span className="text-xs text-slate-400">ID: {company.id}</span>
                </div>
              </div>
            </div>
          ))}
        </div>
      )}
    </div>
  );
}
