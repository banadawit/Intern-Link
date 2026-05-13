"use client";

import { useRouter } from "next/navigation";
import type { HodReportRow } from "./types";
import { getViewerUrl } from "@/lib/utils";
import { format } from "date-fns";

type Props = { reports: HodReportRow[] };

export default function HodReportsTable({ reports }: Props) {
  const router = useRouter();

  return (
    <section className="rounded-2xl border border-slate-200 bg-white p-5 shadow-sm sm:p-6 dark:border-slate-700 dark:bg-slate-900">
      <h2 className="text-lg font-bold text-slate-900 dark:text-slate-100">Final reports</h2>
      <p className="mt-1 text-sm text-slate-500 dark:text-slate-400">Stamped PDFs and evaluation scores.</p>
      <div className="mt-4 overflow-x-auto rounded-xl border border-slate-100 dark:border-slate-700">
        <table className="w-full text-sm">
          <thead className="border-b border-slate-100 bg-slate-50/80 dark:border-slate-700 dark:bg-slate-800/70">
            <tr>
              <th className="px-4 py-3 text-left font-semibold text-slate-700 dark:text-slate-200">Student</th>
              <th className="px-4 py-3 text-left font-semibold text-slate-700 dark:text-slate-200">Technical</th>
              <th className="px-4 py-3 text-left font-semibold text-slate-700 dark:text-slate-200">Soft Skills</th>
              <th className="px-4 py-3 text-left font-semibold text-slate-700 dark:text-slate-200">Evaluated</th>
              <th className="px-4 py-3 text-left font-semibold text-slate-700 dark:text-slate-200">Stamped</th>
              <th className="px-4 py-3 text-left font-semibold text-slate-700 dark:text-slate-200">Report</th>
            </tr>
          </thead>
          <tbody className="divide-y divide-slate-100 dark:divide-slate-700">
            {reports.map((r) => {
              const ev = r.student.finalEvaluation;
              return (
                <tr key={r.id} className="hover:bg-slate-50/50 dark:hover:bg-slate-800/60">
                  <td className="px-4 py-3">
                    <p className="font-medium text-slate-900 dark:text-slate-100">{r.student.user.full_name}</p>
                    <p className="text-xs text-slate-500 dark:text-slate-400">{r.student.user.email}</p>
                  </td>
                  <td className="px-4 py-3">
                    {ev ? (
                      <span className="inline-flex items-center rounded-lg bg-teal-50 px-2.5 py-1 text-sm font-bold text-teal-700 dark:bg-teal-900/30 dark:text-teal-300">
                        {Number(ev.technical_score)}
                      </span>
                    ) : (
                      <span className="text-slate-400 dark:text-slate-500">—</span>
                    )}
                  </td>
                  <td className="px-4 py-3">
                    {ev ? (
                      <span className="inline-flex items-center rounded-lg bg-blue-50 px-2.5 py-1 text-sm font-bold text-blue-700 dark:bg-blue-900/30 dark:text-blue-300">
                        {Number(ev.soft_skill_score)}
                      </span>
                    ) : (
                      <span className="text-slate-400 dark:text-slate-500">—</span>
                    )}
                  </td>
                  <td className="px-4 py-3 text-slate-600 dark:text-slate-300">
                    {ev ? format(new Date(ev.evaluated_at), "MMM d, yyyy") : "—"}
                  </td>
                  <td className="px-4 py-3">
                    <span className={`inline-flex rounded-full px-2.5 py-0.5 text-xs font-semibold ${r.stamped ? "bg-emerald-100 text-emerald-700 dark:bg-emerald-900/30 dark:text-emerald-300" : "bg-slate-100 text-slate-600 dark:bg-slate-700 dark:text-slate-300"}`}>
                      {r.stamped ? "Yes" : "No"}
                    </span>
                  </td>
                  <td className="px-4 py-3">
                    <button
                      onClick={() => router.push(getViewerUrl(r.pdf_url) + `&title=${encodeURIComponent(r.student.user.full_name + " - Final Report")}`)}
                      className="font-medium text-primary-600 hover:text-primary-700 hover:underline"
                    >
                      View PDF
                    </button>
                  </td>
                </tr>
              );
            })}
          </tbody>
        </table>
        {reports.length === 0 && (
          <p className="py-8 text-center text-sm text-slate-500 dark:text-slate-400">No reports yet.</p>
        )}
      </div>
    </section>
  );
}
