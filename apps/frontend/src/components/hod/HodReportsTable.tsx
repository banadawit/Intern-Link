"use client";

import type { HodReportRow } from "./types";

type Props = { reports: HodReportRow[] };

export default function HodReportsTable({ reports }: Props) {
  return (
    <section className="rounded-2xl border border-slate-200 bg-white p-5 shadow-sm sm:p-6">
      <h2 className="text-lg font-bold text-slate-900">Final reports</h2>
      <p className="mt-1 text-sm text-slate-500">Stamped PDFs and downloads.</p>
      <div className="mt-4 overflow-x-auto rounded-xl border border-slate-100">
        <table className="w-full text-sm">
          <thead className="border-b border-slate-100 bg-slate-50/80">
            <tr>
              <th className="px-4 py-3 text-left font-semibold text-slate-700">Student</th>
              <th className="px-4 py-3 text-left font-semibold text-slate-700">Stamped</th>
              <th className="px-4 py-3 text-left font-semibold text-slate-700">Download</th>
            </tr>
          </thead>
          <tbody className="divide-y divide-slate-100">
            {reports.map((r) => (
              <tr key={r.id} className="hover:bg-slate-50/50">
                <td className="px-4 py-3 font-medium text-slate-900">{r.student.user.full_name}</td>
                <td className="px-4 py-3 text-slate-700">{r.stamped ? "Yes" : "No"}</td>
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
          <p className="py-8 text-center text-sm text-slate-500">No reports yet.</p>
        )}
      </div>
    </section>
  );
}
