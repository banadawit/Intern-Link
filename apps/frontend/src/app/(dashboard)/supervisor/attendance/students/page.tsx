"use client";

import { useCallback, useEffect, useMemo, useState } from "react";
import api from "@/lib/api/client";
import { AlertCircle } from "lucide-react";
import { ContributionHeatmap } from "@/components/attendance/ContributionHeatmap";

type HeatmapResponse = {
  rangeStart: string;
  rangeEnd: string;
  students: { studentId: number; fullName: string; email: string; submittedDates: string[] }[];
};

export default function SupervisorAttendanceStudentsPage() {
  const [heatmap, setHeatmap] = useState<HeatmapResponse | null>(null);
  const [selectedStudentId, setSelectedStudentId] = useState<number | null>(null);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  const load = useCallback(async () => {
    setLoading(true);
    setError(null);
    try {
      const hmRes = await api.get<HeatmapResponse>("/supervisor/attendance-heatmap");
      setHeatmap(hmRes.data);
      setSelectedStudentId((prev) => {
        const list = hmRes.data.students;
        if (prev != null && list.some((s) => s.studentId === prev)) return prev;
        return list[0]?.studentId ?? null;
      });
    } catch {
      setError("Could not load student attendance.");
      setHeatmap(null);
    } finally {
      setLoading(false);
    }
  }, []);

  useEffect(() => {
    void load();
  }, [load]);

  const selectedHeatmap = useMemo(() => {
    if (!heatmap || selectedStudentId === null) return null;
    return heatmap.students.find((s) => s.studentId === selectedStudentId) ?? null;
  }, [heatmap, selectedStudentId]);

  return (
    <div className="space-y-6">
      <div>
        <h1 className="text-2xl font-bold text-slate-900">Student check-ins</h1>
        <p className="mt-1 text-sm text-slate-500">
          Daily task activity after each weekly plan is approved. Darker squares mean the intern logged work that calendar
          day.
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
      ) : heatmap && heatmap.students.length > 0 ? (
        <div className="space-y-4">
          <div className="flex flex-col gap-3 sm:flex-row sm:items-end sm:justify-between">
            <label className="block text-sm font-medium text-slate-700">
              Student
              <select
                value={selectedStudentId ?? ""}
                onChange={(e) => setSelectedStudentId(Number(e.target.value))}
                className="mt-1 block w-full max-w-md rounded-xl border border-slate-200 bg-white px-3 py-2 text-sm text-slate-900 shadow-sm sm:w-72"
              >
                {heatmap.students.map((s) => (
                  <option key={s.studentId} value={s.studentId}>
                    {s.fullName}
                  </option>
                ))}
              </select>
            </label>
            {selectedHeatmap && (
              <p className="text-xs text-slate-500">
                {selectedHeatmap.email} · {heatmap.rangeStart} → {heatmap.rangeEnd}
              </p>
            )}
          </div>
          {selectedHeatmap && (
            <ContributionHeatmap
              rangeStart={heatmap.rangeStart}
              rangeEnd={heatmap.rangeEnd}
              submittedDates={selectedHeatmap.submittedDates}
              className="w-full min-w-0"
            />
          )}
        </div>
      ) : (
        <p className="text-sm text-slate-500">No placed students for your company yet.</p>
      )}
    </div>
  );
}
