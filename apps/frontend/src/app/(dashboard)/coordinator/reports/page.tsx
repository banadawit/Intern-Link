"use client";

import { useCallback, useEffect, useState } from "react";
import { Loader2, RefreshCw } from "lucide-react";
import api from "@/lib/api/client";
import CoordinatorPageHero from "../CoordinatorPageHero";

type ReportRow = {
  id: number;
  pdf_url: string;
  stamped: boolean;
  generated_at: string;
  student: {
    department: string | null;
    user: { full_name: string; email: string };
  };
};

export default function CoordinatorReportsPage() {
  const [reports, setReports] = useState<ReportRow[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  const load = useCallback(async () => {
    setLoading(true);
    setError(null);
    try {
      const { data } = await api.get<ReportRow[]>("/coordinator-portal/reports/overview");
      setReports(data);
    } catch {
      setError("Could not load reports.");
      setReports([]);
    } finally {
      setLoading(false);
    }
  }, []);

  useEffect(() => {
    void load();
  }, [load]);

  return (
    <div className="space-y-6 pb-8">
      <CoordinatorPageHero
        badge="Reports"
        title="Final reports"
        description="Submitted final reports from students across your university. Open PDFs in a new tab."
        action={
          <button
            type="button"
            onClick={() => void load()}
            disabled={loading}
            className="inline-flex w-full shrink-0 items-center justify-center gap-2 rounded-xl border border-border-default bg-white/90 px-4 py-3 text-sm font-medium text-slate-800 shadow-sm backdrop-blur-sm transition-colors hover:bg-white disabled:opacity-60 sm:w-auto"
          >
            <RefreshCw className={`h-4 w-4 ${loading ? "animate-spin" : ""}`} aria-hidden />
            Refresh
          </button>
        }
      />

      {error && (
        <div className="rounded-2xl border border-red-200 bg-red-50 px-4 py-3 text-sm text-red-800">{error}</div>
      )}

      {loading && reports.length === 0 ? (
        <div className="flex min-h-[40vh] items-center justify-center text-slate-500">
          <Loader2 className="h-10 w-10 animate-spin text-primary-600" aria-hidden />
        </div>
      ) : (
        <section className="overflow-x-auto rounded-2xl border border-slate-200 bg-white shadow-sm">
          <table className="w-full min-w-[640px] text-left text-sm">
            <thead className="border-b border-slate-100 bg-slate-50/80">
              <tr>
                <th className="px-4 py-3 font-semibold text-slate-700">Student</th>
                <th className="px-4 py-3 font-semibold text-slate-700">Department</th>
                <th className="px-4 py-3 font-semibold text-slate-700">Stamped</th>
                <th className="px-4 py-3 font-semibold text-slate-700">Generated</th>
                <th className="px-4 py-3 font-semibold text-slate-700">PDF</th>
              </tr>
            </thead>
            <tbody className="divide-y divide-slate-100">
              {reports.map((r) => (
                <tr key={r.id} className="hover:bg-slate-50/50">
                  <td className="px-4 py-3 font-medium text-slate-900">{r.student.user.full_name}</td>
                  <td className="px-4 py-3 text-slate-600">{r.student.department ?? "—"}</td>
                  <td className="px-4 py-3 text-slate-700">{r.stamped ? "Yes" : "No"}</td>
                  <td className="px-4 py-3 text-slate-500">
                    {new Date(r.generated_at).toLocaleString()}
                  </td>
                  <td className="px-4 py-3">
                    <a
                      href={r.pdf_url}
                      target="_blank"
                      rel="noopener noreferrer"
                      className="font-medium text-primary-600 hover:underline"
                    >
                      Open
                    </a>
                  </td>
                </tr>
              ))}
            </tbody>
          </table>
          {reports.length === 0 && (
            <p className="py-10 text-center text-sm text-slate-500">No reports yet.</p>
          )}
        </section>
      )}
    </div>
  );
}
