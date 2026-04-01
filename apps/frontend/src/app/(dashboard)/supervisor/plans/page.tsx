"use client";

import { useCallback, useEffect, useState } from "react";
import Link from "next/link";
import api from "@/lib/api/client";
import { AlertCircle, X } from "lucide-react";

type WeeklyPlanRow = {
  id: number;
  week_number: number;
  plan_description: string;
  status: string;
  submitted_at: string;
  feedback: string | null;
  student: {
    user: { full_name: string; email: string };
    university: { name: string };
  };
  presentation: { file_url: string } | null;
};

const apiOrigin = () => {
  const base = process.env.NEXT_PUBLIC_API_URL || "http://localhost:5000/api";
  return base.replace(/\/api\/?$/, "");
};

export default function SupervisorPlansPage() {
  const [rows, setRows] = useState<WeeklyPlanRow[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);
  const [filter, setFilter] = useState<"PENDING" | "ALL">("PENDING");
  const [selected, setSelected] = useState<WeeklyPlanRow | null>(null);
  const [remarks, setRemarks] = useState("");
  const [attendance, setAttendance] = useState(true);
  const [submitting, setSubmitting] = useState(false);

  const load = useCallback(async () => {
    setLoading(true);
    setError(null);
    try {
      const q = filter === "PENDING" ? "?status=PENDING" : "";
      const res = await api.get<WeeklyPlanRow[]>(`/supervisor/weekly-plans${q}`);
      setRows(res.data);
    } catch {
      setError("Could not load weekly plans.");
    } finally {
      setLoading(false);
    }
  }, [filter]);

  useEffect(() => {
    void load();
  }, [load]);

  const review = async (status: "APPROVED" | "REJECTED") => {
    if (!selected) return;
    setSubmitting(true);
    try {
      await api.patch(`/progress/review/${selected.id}`, {
        status,
        remarks: remarks.trim() || undefined,
        attendance: status === "APPROVED" ? attendance : undefined,
      });
      setSelected(null);
      setRemarks("");
      await load();
    } catch {
      setError("Failed to submit review.");
    } finally {
      setSubmitting(false);
    }
  };

  const open = (p: WeeklyPlanRow) => {
    setSelected(p);
    setRemarks("");
    setAttendance(true);
  };

  return (
    <div className="space-y-6">
      <div className="flex flex-col gap-4 sm:flex-row sm:items-end sm:justify-between">
        <div>
          <h1 className="text-2xl font-bold text-slate-900">Weekly plans</h1>
          <p className="mt-1 text-sm text-slate-500">
            Review and approve student weekly plans for your company.
          </p>
        </div>
        <div className="flex gap-2">
          <button
            type="button"
            onClick={() => setFilter("PENDING")}
            className={`rounded-xl px-4 py-2 text-sm font-semibold ${
              filter === "PENDING"
                ? "bg-primary-600 text-white"
                : "border border-slate-200 bg-white text-slate-700"
            }`}
          >
            Pending
          </button>
          <button
            type="button"
            onClick={() => setFilter("ALL")}
            className={`rounded-xl px-4 py-2 text-sm font-semibold ${
              filter === "ALL"
                ? "bg-primary-600 text-white"
                : "border border-slate-200 bg-white text-slate-700"
            }`}
          >
            All
          </button>
        </div>
      </div>

      {error && (
        <div className="flex items-center gap-2 rounded-xl border border-red-200 bg-red-50 px-4 py-3 text-sm text-red-800">
          <AlertCircle className="h-4 w-4 shrink-0" />
          {error}
        </div>
      )}

      <div className="overflow-hidden rounded-2xl border border-slate-200 bg-white shadow-sm">
        {loading ? (
          <p className="p-8 text-center text-slate-500">Loading…</p>
        ) : rows.length === 0 ? (
          <p className="p-8 text-center text-slate-500">No plans in this view.</p>
        ) : (
          <div className="overflow-x-auto">
            <table className="w-full min-w-[720px] text-left text-sm">
              <thead className="border-b border-slate-100 bg-slate-50/80">
                <tr>
                  <th className="px-4 py-3 font-semibold text-slate-700">Week</th>
                  <th className="px-4 py-3 font-semibold text-slate-700">Student</th>
                  <th className="px-4 py-3 font-semibold text-slate-700">Status</th>
                  <th className="px-4 py-3 font-semibold text-slate-700 text-right">Action</th>
                </tr>
              </thead>
              <tbody className="divide-y divide-slate-100">
                {rows.map((p) => (
                  <tr key={p.id} className="hover:bg-slate-50/50">
                    <td className="px-4 py-3 font-medium text-slate-900">Week {p.week_number}</td>
                    <td className="px-4 py-3">
                      <p className="font-medium text-slate-900">{p.student.user.full_name}</p>
                      <p className="text-xs text-slate-500">{p.student.university.name}</p>
                    </td>
                    <td className="px-4 py-3">
                      <span className="rounded-full bg-slate-100 px-2 py-0.5 text-xs font-medium text-slate-800">
                        {p.status}
                      </span>
                    </td>
                    <td className="px-4 py-3 text-right">
                      <button
                        type="button"
                        onClick={() => open(p)}
                        className="rounded-lg bg-primary-600 px-3 py-1.5 text-xs font-semibold text-white hover:bg-primary-700"
                      >
                        View / review
                      </button>
                    </td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
        )}
      </div>

      {selected && (
        <div className="fixed inset-0 z-50 flex items-center justify-center p-4">
          <button
            type="button"
            className="absolute inset-0 bg-slate-900/40"
            aria-label="Close"
            onClick={() => setSelected(null)}
          />
          <div className="relative z-10 max-h-[90vh] w-full max-w-lg overflow-y-auto rounded-2xl border border-slate-200 bg-white p-6 shadow-xl">
            <div className="flex items-start justify-between gap-4">
              <div>
                <h2 className="text-lg font-bold text-slate-900">
                  Week {selected.week_number} — {selected.student.user.full_name}
                </h2>
                <p className="text-xs text-slate-500">
                  Submitted {new Date(selected.submitted_at).toLocaleString()}
                </p>
              </div>
              <button
                type="button"
                onClick={() => setSelected(null)}
                className="rounded-lg p-1 text-slate-400 hover:bg-slate-100"
              >
                <X className="h-5 w-5" />
              </button>
            </div>
            <div className="mt-4 space-y-3">
              <p className="text-sm text-slate-700 whitespace-pre-wrap">{selected.plan_description}</p>
              {selected.presentation?.file_url && (
                <a
                  href={`${apiOrigin()}/${selected.presentation.file_url.replace(/^\//, "")}`}
                  target="_blank"
                  rel="noopener noreferrer"
                  className="inline-block text-sm font-semibold text-primary-600 hover:underline"
                >
                  Open presentation file
                </a>
              )}
            </div>
            {selected.status === "PENDING" && (
              <>
                <div className="mt-4 rounded-xl border border-slate-200 bg-slate-50 px-3 py-3 text-xs text-slate-600">
                  <p className="font-medium text-slate-800">AI feedback</p>
                  <p className="mt-1">
                    Draft feedback in the full chat — paste the plan or ask for review ideas, then copy text back into remarks
                    below. Nothing is approved automatically.
                  </p>
                  <Link
                    href="/supervisor/ai"
                    className="mt-2 inline-block font-semibold text-primary-600 hover:underline"
                  >
                    Open AI assistant
                  </Link>
                </div>
                <label className="mt-4 block text-sm font-medium text-slate-700">
                  Feedback / remarks
                  <textarea
                    value={remarks}
                    onChange={(e) => setRemarks(e.target.value)}
                    rows={3}
                    className="mt-1 w-full rounded-xl border border-slate-200 px-3 py-2 text-sm"
                    placeholder="Optional notes for the student"
                  />
                </label>
                <label className="mt-3 flex items-center gap-2 text-sm text-slate-700">
                  <input
                    type="checkbox"
                    checked={attendance}
                    onChange={(e) => setAttendance(e.target.checked)}
                  />
                  Mark attendance present (when approving)
                </label>
                <div className="mt-4 flex justify-end gap-2">
                  <button
                    type="button"
                    disabled={submitting}
                    onClick={() => void review("REJECTED")}
                    className="rounded-xl border border-slate-200 px-4 py-2 text-sm font-semibold text-slate-700 hover:bg-slate-50 disabled:opacity-50"
                  >
                    Reject
                  </button>
                  <button
                    type="button"
                    disabled={submitting}
                    onClick={() => void review("APPROVED")}
                    className="rounded-xl bg-primary-600 px-4 py-2 text-sm font-semibold text-white hover:bg-primary-700 disabled:opacity-50"
                  >
                    Approve
                  </button>
                </div>
              </>
            )}
            {selected.status !== "PENDING" && selected.feedback && (
              <p className="mt-4 text-sm text-slate-600">
                <span className="font-semibold">Previous feedback: </span>
                {selected.feedback}
              </p>
            )}
          </div>
        </div>
      )}
    </div>
  );
}
