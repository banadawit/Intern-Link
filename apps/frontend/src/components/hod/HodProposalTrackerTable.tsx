"use client";

import type { HodProposalRow } from "./types";

type Props = { proposals: HodProposalRow[] };

export default function HodProposalTrackerTable({ proposals }: Props) {
  return (
    <section className="rounded-2xl border border-slate-200 bg-white p-5 shadow-sm sm:p-6">
      <h2 className="text-lg font-bold text-slate-900">Proposal tracker</h2>
      <div className="mt-4 overflow-x-auto rounded-xl border border-slate-100">
        <table className="w-full min-w-[640px] text-sm">
          <thead className="border-b border-slate-100 bg-slate-50/80">
            <tr>
              <th className="px-4 py-3 text-left font-semibold text-slate-700">Student</th>
              <th className="px-4 py-3 text-left font-semibold text-slate-700">Company</th>
              <th className="px-4 py-3 text-left font-semibold text-slate-700">Status</th>
              <th className="px-4 py-3 text-left font-semibold text-slate-700">Weeks</th>
              <th className="px-4 py-3 text-left font-semibold text-slate-700">Submitted</th>
            </tr>
          </thead>
          <tbody className="divide-y divide-slate-100">
            {proposals.map((p) => (
              <tr key={p.id} className="hover:bg-slate-50/50">
                <td className="px-4 py-3 text-slate-900">{p.student.user.full_name}</td>
                <td className="px-4 py-3 text-slate-700">{p.company.name}</td>
                <td className="px-4 py-3 text-slate-700">{p.status}</td>
                <td className="px-4 py-3 text-slate-700">{p.expected_duration_weeks ?? "—"}</td>
                <td className="px-4 py-3 text-slate-500">{new Date(p.submitted_at).toLocaleString()}</td>
              </tr>
            ))}
          </tbody>
        </table>
        {proposals.length === 0 && (
          <p className="py-8 text-center text-sm text-slate-500">No proposals yet.</p>
        )}
      </div>
    </section>
  );
}
