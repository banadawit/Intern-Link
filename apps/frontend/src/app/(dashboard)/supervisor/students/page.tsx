"use client";

import { useEffect, useState } from "react";
import api from "@/lib/api/client";

type Row = {
  student: {
    id: number;
    internship_status: string;
    department: string | null;
    user: { full_name: string; email: string };
    university: { name: string };
  };
  assignment: {
    id: number;
    start_date: string;
    end_date: string | null;
    project_name: string | null;
  };
};

export default function SupervisorStudentsPage() {
  const [rows, setRows] = useState<Row[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  useEffect(() => {
    let cancelled = false;
    (async () => {
      try {
        const res = await api.get<{ success: boolean; data: Row[] }>("/supervisor/students");
        if (!cancelled) setRows(Array.isArray(res.data.data) ? res.data.data : []);
      } catch {
        if (!cancelled) setError("Could not load students.");
      } finally {
        if (!cancelled) setLoading(false);
      }
    })();
    return () => {
      cancelled = true;
    };
  }, []);

  if (error) {
    return (
      <div className="rounded-2xl border border-red-200 bg-red-50 p-6 text-sm text-red-800">
        {error}
      </div>
    );
  }

  return (
    <div className="space-y-6">
      <div>
        <h1 className="text-2xl font-bold text-slate-900">Students</h1>
        <p className="mt-1 text-sm text-slate-500">
          Students with an active placement at your company (read-only).
        </p>
      </div>

      <div className="overflow-hidden rounded-2xl border border-slate-200 bg-white shadow-sm">
        {loading ? (
          <p className="p-8 text-center text-slate-500">Loading…</p>
        ) : rows.length === 0 ? (
          <p className="p-8 text-center text-slate-500">No active placements yet.</p>
        ) : (
          <div className="overflow-x-auto">
            <table className="w-full min-w-[720px] text-left text-sm">
              <thead className="border-b border-slate-100 bg-slate-50/80">
                <tr>
                  <th className="px-4 py-3 font-semibold text-slate-700">Name</th>
                  <th className="px-4 py-3 font-semibold text-slate-700">University</th>
                  <th className="px-4 py-3 font-semibold text-slate-700">Status</th>
                  <th className="px-4 py-3 font-semibold text-slate-700">Project</th>
                  <th className="px-4 py-3 font-semibold text-slate-700">Started</th>
                </tr>
              </thead>
              <tbody className="divide-y divide-slate-100">
                {rows.map((r) => (
                  <tr key={r.student.id} className="hover:bg-slate-50/50">
                    <td className="px-4 py-3">
                      <p className="font-medium text-slate-900">{r.student.user.full_name}</p>
                      <p className="text-xs text-slate-500">{r.student.user.email}</p>
                    </td>
                    <td className="px-4 py-3 text-slate-700">{r.student.university.name}</td>
                    <td className="px-4 py-3">
                      <span className="rounded-full bg-emerald-50 px-2 py-0.5 text-xs font-medium text-emerald-800">
                        {r.student.internship_status}
                      </span>
                    </td>
                    <td className="px-4 py-3 text-slate-600">
                      {r.assignment.project_name ?? "—"}
                    </td>
                    <td className="px-4 py-3 text-slate-600">
                      {new Date(r.assignment.start_date).toLocaleDateString()}
                    </td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
        )}
      </div>
    </div>
  );
}
