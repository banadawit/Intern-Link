"use client";

import { useCallback, useEffect, useState } from "react";
import api from "@/lib/api/client";
import { AlertCircle } from "lucide-react";
import { WeekDayStrip } from "@/components/attendance/WeekDayStrip";

type ReportRow = {
  id: number;
  attendanceStatus: "PRESENT" | "ABSENT" | "LATE";
  execution_status: string | null;
  remarks: string | null;
  submitted_at: string;
  student: {
    user: { full_name: string; email: string };
    assignments?: { start_date: string }[];
  };
  weeklyPlan: {
    id: number;
    week_number: number;
    status: string;
    daySubmissions?: { workDate: string | Date }[];
  } | null;
};

const STATUSES: Array<ReportRow["attendanceStatus"]> = ["PRESENT", "ABSENT", "LATE"];

function ymdFromApi(d: string | Date): string {
  return typeof d === "string" ? d.slice(0, 10) : new Date(d).toISOString().slice(0, 10);
}

export default function SupervisorAttendanceReportsPage() {
  const [rows, setRows] = useState<ReportRow[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);
  const [editing, setEditing] = useState<Record<number, { execution: string; status: ReportRow["attendanceStatus"] }>>(
    {},
  );
  const [saving, setSaving] = useState<number | null>(null);

  const load = useCallback(async () => {
    setLoading(true);
    setError(null);
    try {
      const repRes = await api.get<ReportRow[]>("/supervisor/weekly-reports");
      setRows(repRes.data);
      const next: Record<number, { execution: string; status: ReportRow["attendanceStatus"] }> = {};
      for (const r of repRes.data) {
        next[r.id] = {
          execution: r.execution_status ?? "",
          status: r.attendanceStatus,
        };
      }
      setEditing(next);
    } catch {
      setError("Could not load weekly reports.");
    } finally {
      setLoading(false);
    }
  }, []);

  useEffect(() => {
    void load();
  }, [load]);

  const save = async (id: number) => {
    const e = editing[id];
    if (!e) return;
    setSaving(id);
    setError(null);
    try {
      await api.patch(`/supervisor/weekly-reports/${id}`, {
        attendanceStatus: e.status,
        execution_status: e.execution.trim() || undefined,
      });
      await load();
    } catch {
      setError("Failed to save.");
    } finally {
      setSaving(null);
    }
  };

  return (
    <div className="space-y-6">
      <div>
        <h1 className="text-2xl font-bold text-slate-900">Weekly reports & attendance</h1>
        <p className="mt-1 text-sm text-slate-500">
          FR-6.5 weekly records: set attendance and execution notes per intern per week.
        </p>
      </div>

      {error && (
        <div className="flex items-center gap-2 rounded-xl border border-red-200 bg-red-50 px-4 py-3 text-sm text-red-800">
          <AlertCircle className="h-4 w-4 shrink-0" />
          {error}
        </div>
      )}

      {loading ? (
        <p className="py-8 text-center text-slate-500">Loading…</p>
      ) : (
        <div className="overflow-hidden rounded-2xl border border-slate-200 bg-white shadow-sm">
          {rows.length === 0 ? (
            <p className="p-8 text-center text-slate-500">No weekly reports yet.</p>
          ) : (
            <div className="overflow-x-auto">
              <table className="w-full min-w-[900px] text-left text-sm">
                <thead className="border-b border-slate-100 bg-slate-50/80">
                  <tr>
                    <th className="px-4 py-3 font-semibold text-slate-700">Student</th>
                    <th className="px-4 py-3 font-semibold text-slate-700">Week</th>
                    <th className="px-4 py-3 font-semibold text-slate-700">Daily streak</th>
                    <th className="px-4 py-3 font-semibold text-slate-700">Attendance</th>
                    <th className="px-4 py-3 font-semibold text-slate-700">Execution</th>
                    <th className="px-4 py-3 text-right font-semibold text-slate-700">Save</th>
                  </tr>
                </thead>
                <tbody className="divide-y divide-slate-100">
                  {rows.map((r) => {
                    const start = r.student.assignments?.[0]?.start_date;
                    const weekNum = r.weeklyPlan?.week_number;
                    const dayYmds = r.weeklyPlan?.daySubmissions?.map((d) => ymdFromApi(d.workDate)) ?? [];
                    return (
                      <tr key={r.id} className="align-top hover:bg-slate-50/50">
                        <td className="px-4 py-3">
                          <p className="font-medium text-slate-900">{r.student.user.full_name}</p>
                          <p className="text-xs text-slate-500">{r.student.user.email}</p>
                        </td>
                        <td className="px-4 py-3 text-slate-700">
                          {r.weeklyPlan ? `Week ${r.weeklyPlan.week_number}` : "—"}
                        </td>
                        <td className="px-4 py-3">
                          {start && weekNum != null ? (
                            <WeekDayStrip assignmentStart={start} weekNumber={weekNum} submittedYmds={dayYmds} />
                          ) : (
                            <span className="text-xs text-slate-400">—</span>
                          )}
                        </td>
                        <td className="px-4 py-3">
                          <select
                            value={editing[r.id]?.status ?? r.attendanceStatus}
                            onChange={(e) =>
                              setEditing((prev) => ({
                                ...prev,
                                [r.id]: {
                                  ...prev[r.id],
                                  execution: prev[r.id]?.execution ?? r.execution_status ?? "",
                                  status: e.target.value as ReportRow["attendanceStatus"],
                                },
                              }))
                            }
                            className="rounded-lg border border-slate-200 px-2 py-1.5 text-xs"
                          >
                            {STATUSES.map((s) => (
                              <option key={s} value={s}>
                                {s}
                              </option>
                            ))}
                          </select>
                        </td>
                        <td className="px-4 py-3">
                          <textarea
                            value={editing[r.id]?.execution ?? r.execution_status ?? ""}
                            onChange={(e) =>
                              setEditing((prev) => ({
                                ...prev,
                                [r.id]: {
                                  status: prev[r.id]?.status ?? r.attendanceStatus,
                                  execution: e.target.value,
                                },
                              }))
                            }
                            rows={2}
                            className="w-full min-w-[200px] rounded-lg border border-slate-200 px-2 py-1.5 text-xs"
                            placeholder="Execution / notes"
                          />
                        </td>
                        <td className="px-4 py-3 text-right">
                          <button
                            type="button"
                            disabled={saving === r.id}
                            onClick={() => void save(r.id)}
                            className="rounded-lg bg-primary-600 px-3 py-1.5 text-xs font-semibold text-white hover:bg-primary-700 disabled:opacity-50"
                          >
                            {saving === r.id ? "Saving…" : "Save"}
                          </button>
                        </td>
                      </tr>
                    );
                  })}
                </tbody>
              </table>
            </div>
          )}
        </div>
      )}
    </div>
  );
}
