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

const COMPLETENESS_OPTIONS: Array<{ label: string; value: ReportRow["attendanceStatus"] }> = [
  { label: ">90%", value: "PRESENT" },
  { label: ">50%", value: "LATE"    },
  { label: "<50%", value: "ABSENT"  },
];

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

  type HistoryEntry = {
    id: number;
    studentName: string;
    week: string;
    completeness: string;
    execution: string;
    savedAt: string;
  };
  const [history, setHistory] = useState<HistoryEntry[]>([]);

  const load = useCallback(async () => {
    setLoading(true);
    setError(null);
    try {
      const repRes = await api.get<{ success: boolean; data: ReportRow[] }>("/supervisor/weekly-reports");
      const rows = Array.isArray(repRes.data.data) ? repRes.data.data : [];
      setRows(rows);
      const next: Record<number, { execution: string; status: ReportRow["attendanceStatus"] }> = {};
      for (const r of rows) {
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
      const row = rows.find((r) => r.id === id);
      const completenessLabel = COMPLETENESS_OPTIONS.find((o) => o.value === e.status)?.label ?? e.status;
      setHistory((prev) => [
        {
          id,
          studentName: row?.student.user.full_name ?? "—",
          week: row?.weeklyPlan ? `Week ${row.weeklyPlan.week_number}` : "—",
          completeness: completenessLabel,
          execution: e.execution.trim() || "—",
          savedAt: new Date().toLocaleString(),
        },
        ...prev,
      ]);
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
                    <th className="px-4 py-3 font-semibold text-slate-700">Completeness</th>
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
                            className="rounded-lg border border-slate-200 px-2 py-1.5 text-xs dark:border-slate-700 dark:bg-slate-900 dark:text-slate-100"
                          >
                            {COMPLETENESS_OPTIONS.map((opt) => (
                              <option key={opt.value} value={opt.value}>
                                {opt.label}
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

      {/* Save history */}
      {history.length > 0 && (
        <div className="mt-8 space-y-3">
          <h2 className="text-base font-semibold text-slate-800 dark:text-slate-100">Save history</h2>
          <div className="overflow-hidden rounded-2xl border border-slate-200 bg-white shadow-sm dark:border-slate-700 dark:bg-slate-900">
            <div className="overflow-x-auto">
              <table className="w-full min-w-[600px] text-left text-sm">
                <thead className="border-b border-slate-100 bg-slate-50/80 dark:border-slate-700 dark:bg-slate-800/50">
                  <tr>
                    <th className="px-4 py-3 font-semibold text-slate-600 dark:text-slate-300">Student</th>
                    <th className="px-4 py-3 font-semibold text-slate-600 dark:text-slate-300">Week</th>
                    <th className="px-4 py-3 font-semibold text-slate-600 dark:text-slate-300">Completeness</th>
                    <th className="px-4 py-3 font-semibold text-slate-600 dark:text-slate-300">Execution notes</th>
                    <th className="px-4 py-3 font-semibold text-slate-600 dark:text-slate-300">Saved at</th>
                  </tr>
                </thead>
                <tbody className="divide-y divide-slate-100 dark:divide-slate-700">
                  {history.map((h, i) => (
                    <tr key={i} className="hover:bg-slate-50/50 dark:hover:bg-slate-800/40">
                      <td className="px-4 py-3 font-medium text-slate-900 dark:text-slate-100">{h.studentName}</td>
                      <td className="px-4 py-3 text-slate-600 dark:text-slate-300">{h.week}</td>
                      <td className="px-4 py-3">
                        <span className="inline-flex items-center rounded-full bg-teal-50 px-2.5 py-0.5 text-xs font-semibold text-teal-700 ring-1 ring-teal-200 dark:bg-teal-900/30 dark:text-teal-300 dark:ring-teal-700">
                          {h.completeness}
                        </span>
                      </td>
                      <td className="px-4 py-3 text-slate-500 dark:text-slate-400">{h.execution}</td>
                      <td className="px-4 py-3 text-xs text-slate-400 dark:text-slate-500">{h.savedAt}</td>
                    </tr>
                  ))}
                </tbody>
              </table>
            </div>
          </div>
        </div>
      )}
    </div>
  );
}
