"use client";

import type { HodReportRow } from "./types";

type Props = { reports: HodReportRow[] };

export default function HodReportsTable({ reports }: Props) {
  return (
    <section className="rounded-2xl border border-slate-200 bg-white p-5 shadow-sm sm:p-6 dark:border-slate-700 dark:bg-slate-900">
      <h2 className="text-lg font-bold text-slate-900 dark:text-slate-100">Final reports</h2>
      <p className="mt-1 text-sm text-slate-500 dark:text-slate-400">Stamped PDFs and downloads.</p>
      <div className="mt-4 overflow-x-auto rounded-xl border border-slate-100 dark:border-slate-700">
        <table className="w-full text-sm">
          <thead className="border-b border-slate-100 bg-slate-50/80 dark:border-slate-700 dark:bg-slate-800/70">
            <tr>
              <th className="px-4 py-3 text-left font-semibold text-slate-700 dark:text-slate-200">Student</th>
              <th className="px-4 py-3 text-left font-semibold text-slate-700 dark:text-slate-200">Stamped</th>
              <th className="px-4 py-3 text-left font-semibold text-slate-700 dark:text-slate-200">Download</th>
            </tr>
          </thead>
          <tbody className="divide-y divide-slate-100 dark:divide-slate-700">
            {reports.map((r) => (
              <tr key={r.id} className="hover:bg-slate-50/50 dark:hover:bg-slate-800/60">
                <td className="px-4 py-3 font-medium text-slate-900 dark:text-slate-100">{r.student.user.full_name}</td>
                <td className="px-4 py-3 text-slate-700 dark:text-slate-300">{r.stamped ? "Yes" : "No"}</td>
                <td className="px-4 py-3">
                  <a
                    href={r.pdf_url}
                    target="_blank"
                    rel="noopener noreferrer"
                    className="font-medium text-primary-600 hover:text-primary-700 hover:underline"
                  >
                    Open PDF
                  </a>
                </td>
              </tr>
            ))}
          </tbody>
        </table>
        {reports.length === 0 && (
          <p className="py-8 text-center text-sm text-slate-500 dark:text-slate-400">No reports yet.</p>
        )}
      </div>
    </section>
  );
}
