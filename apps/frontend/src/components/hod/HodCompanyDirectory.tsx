"use client";

import { useMemo, useState } from "react";
import type { HodCompanyRow } from "./types";

type Props = { companies: HodCompanyRow[] };

export default function HodCompanyDirectory({ companies }: Props) {
  const [companyQuery, setCompanyQuery] = useState("");

  const filtered = useMemo(() => {
    const q = companyQuery.trim().toLowerCase();
    if (!q) return companies;
    return companies.filter((c) => c.name.toLowerCase().includes(q));
  }, [companies, companyQuery]);

  return (
    <section
      className="rounded-2xl border border-slate-200 bg-white p-5 shadow-sm sm:p-6"
      aria-label="Company directory"
    >
      <p className="text-sm text-slate-500">Search and browse verified organizations.</p>
      <input
        type="search"
        value={companyQuery}
        onChange={(e) => setCompanyQuery(e.target.value)}
        placeholder="Search by name…"
        className="mt-4 w-full max-w-md rounded-xl border border-slate-200 bg-white px-4 py-2.5 text-sm text-slate-900 placeholder:text-slate-400 focus:border-primary-500 focus:outline-none focus:ring-2 focus:ring-primary-500/20"
      />
      <ul className="mt-4 max-h-52 space-y-1 overflow-y-auto text-sm">
        {filtered.map((c) => (
          <li
            key={c.id}
            className="rounded-lg border border-slate-100 bg-slate-50/50 px-3 py-2 text-slate-800"
          >
            <span className="font-medium">{c.name}</span>{" "}
            <span className="text-slate-500">({c.official_email})</span>
          </li>
        ))}
      </ul>
      {filtered.length === 0 && (
        <p className="mt-4 text-sm text-slate-500">No companies match your filter.</p>
      )}
    </section>
  );
}
