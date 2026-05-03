"use client";

import { cn } from "@/lib/utils";
import type { HodProposalRow } from "./types";

function StatusPill({ status }: { status: string }) {
  return (
    <span className={cn(
      "inline-flex rounded-full px-2.5 py-0.5 text-xs font-semibold",
      status === "PENDING"  && "bg-amber-100 text-amber-800",
      status === "APPROVED" && "bg-emerald-100 text-emerald-800",
      status === "REJECTED" && "bg-red-100 text-red-700",
      !["PENDING","APPROVED","REJECTED"].includes(status) && "bg-slate-100 text-slate-700",
    )}>
      {status}
    </span>
  );
}

type Props = { proposals: HodProposalRow[] };

export default function HodProposalTrackerTable({ proposals }: Props) {
  return (
    <section className="rounded-2xl border border-slate-200 bg-white p-5 shadow-sm sm:p-6 dark:border-slate-700 dark:bg-slate-900">
      <h2 className="text-lg font-bold text-slate-900 dark:text-slate-100">Proposal tracker</h2>
      <div className="mt-4 overflow-x-auto rounded-xl border border-slate-100 dark:border-slate-700">
        <table className="w-full min-w-[640px] text-sm">
          <thead className="border-b border-slate-100 bg-slate-50/80 dark:border-slate-700 dark:bg-slate-800/70">
            <tr>
              <th className="px-4 py-3 text-left font-semibold text-slate-700 dark:text-slate-200">Student</th>
              <th className="px-4 py-3 text-left font-semibold text-slate-700 dark:text-slate-200">Company</th>
              <th className="px-4 py-3 text-left font-semibold text-slate-700 dark:text-slate-200">Status</th>
              <th className="px-4 py-3 text-left font-semibold text-slate-700 dark:text-slate-200">Weeks</th>
              <th className="px-4 py-3 text-left font-semibold text-slate-700 dark:text-slate-200">Submitted</th>
            </tr>
          </thead>
          <tbody className="divide-y divide-slate-100 dark:divide-slate-700">
            {proposals.map((p) => (
              <tr key={p.id} className="hover:bg-slate-50/50 dark:hover:bg-slate-800/60">
                <td className="px-4 py-3 text-slate-900 dark:text-slate-100">{p.student.user.full_name}</td>
                <td className="px-4 py-3 text-slate-700 dark:text-slate-300">{p.company.name}</td>
                <td className="px-4 py-3"><StatusPill status={p.status} /></td>
                <td className="px-4 py-3 text-slate-700 dark:text-slate-300">{p.expected_duration_weeks ?? "—"}</td>
                <td className="px-4 py-3 text-slate-500 dark:text-slate-400">{new Date(p.submitted_at).toLocaleString()}</td>
              </tr>
            ))}
          </tbody>
        </table>
        {proposals.length === 0 && (
          <p className="py-8 text-center text-sm text-slate-500 dark:text-slate-400">No proposals yet.</p>
        )}
      </div>
    </section>
  );
}
