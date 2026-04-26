"use client";

import { useCallback, useEffect, useState } from "react";
import api from "@/lib/api/client";
import { AlertCircle, Download, FileCheck, Send, Eye } from "lucide-react";
import PdfViewerPage from "@/components/shared/PdfViewerPage";

type StudentRow = {
  student: {
    id: number;
    internship_status: string;
    user: { full_name: string; email: string };
    university: { name: string };
    finalReport?: {
      locked: boolean;
      sent_at: string | null;
      pdf_url: string;
      generated_at: string;
    } | null;
  };
};

export default function SupervisorReportsPage() {
 xport default function SupervisorReportsPage() {
  const [rows, setRows] = useState<StudentRow[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);
  const [form, setForm] = useState<Record<number, { technical: string; soft: string; comments: string }>>({});
  const [busy, setBusy] = useState<number | null>(null);
  const router = useRouter();

  const load = useCallback(async () => {
    setLoading(true);
    setError(null);
    try {
      const res = await api.get<StudentRow[]>("/supervisor/students");
      setRows(res.data);
      const init: Record<number, { technical: string; soft: string; comments: string }> = {};
      for (const r of res.data) {
        init[r.student.id] = { technical: "", soft: "", comments: "" };
      }
      setForm(init);
    } catch {
      setError("Could not load students.");
    } finally {
      setLoading(false);
    }
  }, []);

  useEffect(() => {
    void load();
  }, [load]);

  const submitEval = async (studentId: number) => {
    const f = form[studentId];
    if (!f?.technical || !f?.soft) {
      setError("Enter technical and soft-skill scores.");
      return;
    }
    setBusy(studentId);
    setError(null);
    try {
      await api.post("/reports/evaluate", {
        studentId,
        technical_score: parseFloat(f.technical),
        soft_skill_score: parseFloat(f.soft),
        comments: f.comments || undefined,
      });
      await load();
    } catch (e: unknown) {
      const msg =
        e && typeof e === "object" && "response" in e
          ? (e as { response?: { data?: { message?: string } } }).response?.data?.message
          : "Evaluation failed.";
      setError(msg || "Evaluation failed.");
    } finally {
      setBusy(null);
    }
  };

  const downloadPdf = async (studentId: number, studentName: string) => {
    setBusy(studentId);
    setError(null);
    try {
      const res = await api.get<{ reportUrl: string }>(`/reports/generate/${studentId}`);
      router.push(getViewerUrl(res.data.reportUrl) + `&title=${encodeURIComponent(studentName + ' - Final Report')}`);
      await load();
    } catch (e: unknown) {
      const msg =
        e && typeof e === "object" && "response" in e
          ? (e as { response?: { data?: { message?: string } } }).response?.data?.message
          : "Could not generate PDF.";
      setError(msg || "Could not generate PDF.");
    } finally {
      setBusy(null);
    }
  };

  const sendToUniversity = async (studentId: number) => {
    if (!confirm("Send this report to the university? It will be locked after sending.")) return;
    setBusy(studentId);
    setError(null);
    try {
      await api.post("/reports/send-to-university", { studentId });
      await load();
    } catch (e: unknown) {
      const msg =
        e && typeof e === "object" && "response" in e
          ? (e as { response?: { data?: { message?: string } } }).response?.data?.message
          : "Send failed.";
      setError(msg || "Send failed.");
    } finally {
      setBusy(null);
    }
  };

  return (
    <div className="space-y-6">
      <div>
        <h1 className="text-2xl font-bold text-slate-900">Final evaluation & reports</h1>
        <p className="mt-1 text-sm text-slate-500">
          Submit scores after all weekly plans are approved, generate the stamped PDF, then send to the university.
        </p>
      </div>

      {error && (
        <div className="flex items-center gap-2 rounded-xl border border-red-200 bg-red-50 px-4 py-3 text-sm text-red-800">
          <AlertCircle className="h-4 w-4 shrink-0" />
          {error}
        </div>
      )}

      <div className="space-y-4">
        {loading ? (
          <p className="text-slate-500">Loading…</p>
        ) : rows.length === 0 ? (
          <p className="text-slate-500">No placed students yet.</p>
        ) : (
          rows.map((r) => {
            const fr = r.student.finalReport;
            const locked = fr?.locked === true;
            return (
              <div
                key={r.student.id}
                className="rounded-2xl border border-slate-200 bg-white p-5 shadow-sm"
              >
                <div className="flex flex-col gap-4 sm:flex-row sm:items-start sm:justify-between">
                  <div>
                    <p className="font-semibold text-slate-900">{r.student.user.full_name}</p>
                    <p className="text-xs text-slate-500">{r.student.university.name}</p>
                    {locked && fr?.sent_at && (
                      <p className="mt-1 text-xs font-medium text-emerald-700">
                        Sent to university on {new Date(fr.sent_at).toLocaleString()}
                      </p>
                    )}
                  </div>
                  <div className="flex flex-wrap gap-2">
                    <button
                      type="button"
                      disabled={busy === r.student.id || locked}
                      onClick={() => void downloadPdf(r.student.id, r.student.user.full_name)}
                      className="inline-flex items-center gap-1.5 rounded-xl border border-slate-200 px-3 py-2 text-xs font-semibold text-slate-700 hover:bg-slate-50 disabled:opacity-50"
                    >
                      <Download className="h-4 w-4" />
                      Generate PDF
                    </button>
                    {fr?.pdf_url && (
                      <button
                        type="button"
                        onClick={() => router.push(getViewerUrl(fr.pdf_url) + `&title=${encodeURIComponent(r.student.user.full_name + ' - Final Report')}`)}
                        className="inline-flex items-center gap-1.5 rounded-xl border border-primary-200 bg-primary-50 px-3 py-2 text-xs font-semibold text-primary-700 hover:bg-primary-100 disabled:opacity-50"
                      >
                        <Eye className="h-4 w-4" />
                        View PDF
                      </button>
                    )}
                    {fr && !locked && (
                      <button
                        type="button"
                        disabled={busy === r.student.id}
                        onClick={() => void sendToUniversity(r.student.id)}
                        className="inline-flex items-center gap-1.5 rounded-xl bg-primary-600 px-3 py-2 text-xs font-semibold text-white hover:bg-primary-700 disabled:opacity-50"
                      >
                        <Send className="h-4 w-4" />
                        Send to university
                      </button>
                    )}
                  </div>
                </div>
                <div className="mt-4 grid gap-3 sm:grid-cols-3">
                  <label className="text-xs font-medium text-slate-600">
                    Technical (0–100)
                    <input
                      type="number"
                      min={0}
                      max={100}
                      step={0.1}
                      disabled={locked}
                      value={form[r.student.id]?.technical ?? ""}
                      onChange={(e) =>
                        setForm((prev) => ({
                          ...prev,
                          [r.student.id]: {
                            ...prev[r.student.id],
                            technical: e.target.value,
                            soft: prev[r.student.id]?.soft ?? "",
                            comments: prev[r.student.id]?.comments ?? "",
                          },
                        }))
                      }
                      className="mt-1 w-full rounded-lg border border-slate-200 px-3 py-2 text-sm disabled:bg-slate-50"
                    />
                  </label>
                  <label className="text-xs font-medium text-slate-600">
                    Soft skills (0–100)
                    <input
                      type="number"
                      min={0}
                      max={100}
                      step={0.1}
                      disabled={locked}
                      value={form[r.student.id]?.soft ?? ""}
                      onChange={(e) =>
                        setForm((prev) => ({
                          ...prev,
                          [r.student.id]: {
                            ...prev[r.student.id],
                            soft: e.target.value,
                            technical: prev[r.student.id]?.technical ?? "",
                            comments: prev[r.student.id]?.comments ?? "",
                          },
                        }))
                      }
                      className="mt-1 w-full rounded-lg border border-slate-200 px-3 py-2 text-sm disabled:bg-slate-50"
                    />
                  </label>
                  <label className="text-xs font-medium text-slate-600 sm:col-span-1">
                    Comments
                    <input
                      type="text"
                      disabled={locked}
                      value={form[r.student.id]?.comments ?? ""}
                      onChange={(e) =>
                        setForm((prev) => ({
                          ...prev,
                          [r.student.id]: {
                            ...prev[r.student.id],
                            comments: e.target.value,
                            technical: prev[r.student.id]?.technical ?? "",
                            soft: prev[r.student.id]?.soft ?? "",
                          },
                        }))
                      }
                      className="mt-1 w-full rounded-lg border border-slate-200 px-3 py-2 text-sm disabled:bg-slate-50"
                    />
                  </label>
                </div>
                <button
                  type="button"
                  disabled={busy === r.student.id || locked}
                  onClick={() => void submitEval(r.student.id)}
                  className="mt-4 inline-flex items-center gap-2 rounded-xl bg-primary-600 px-4 py-2 text-sm font-semibold text-white hover:bg-primary-700 disabled:opacity-50"
                >
                  <FileCheck className="h-4 w-4" />
                  Submit evaluation
                </button>
              </div>
            );
          })
        )}
      </div>
    </div>
  );
}
