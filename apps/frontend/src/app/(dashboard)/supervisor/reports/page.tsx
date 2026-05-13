"use client";

import { useCallback, useEffect, useRef, useState } from "react";
import api from "@/lib/api/client";
import { AlertCircle, Download, FileCheck, Send, Eye, Stamp, Upload, CheckCircle2, ImageIcon, X } from "lucide-react";

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
    finalEvaluation?: {
      technical_score: number;
      soft_skill_score: number;
      comments: string | null;
    } | null;
  };
};

export default function SupervisorReportsPage() {
  const [rows, setRows] = useState<StudentRow[]>([]);
  const [stampUrl, setStampUrl] = useState<string | null>(null);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);
  const [form, setForm] = useState<Record<number, { technical: string; soft: string; comments: string }>>({});
  const [busy, setBusy] = useState<number | null>(null);
  const [stampUploading, setStampUploading] = useState(false);
  const [stampSuccess, setStampSuccess] = useState(false);
  // Preview state — holds the selected file + local object URL before confirming
  const [pendingStamp, setPendingStamp] = useState<{ file: File; previewUrl: string } | null>(null);
  const fileInputRef = useRef<HTMLInputElement>(null);

  const load = useCallback(async () => {
    setLoading(true);
    setError(null);
    try {
      const [studentsRes, meRes] = await Promise.all([
        api.get<{ success: boolean; data: StudentRow[] }>("/supervisor/students"),
        api.get<{ success: boolean; data: { supervisor: { company: { stamp_image_url: string | null } } } }>("/supervisor/me"),
      ]);
      const rows = Array.isArray(studentsRes.data.data) ? studentsRes.data.data : [];
      setRows(rows);
      setStampUrl(meRes.data.data?.supervisor?.company?.stamp_image_url ?? null);
      const init: Record<number, { technical: string; soft: string; comments: string }> = {};
      for (const r of rows) {
        const ev = r.student.finalEvaluation;
        init[r.student.id] = {
          technical: ev ? String(ev.technical_score) : "",
          soft: ev ? String(ev.soft_skill_score) : "",
          comments: ev?.comments ?? "",
        };
      }
      setForm(init);
    } catch {
      setError("Could not load students.");
    } finally {
      setLoading(false);
    }
  }, []);

  useEffect(() => { void load(); }, [load]);

  // Step 1: file selected → show preview modal
  const handleFileSelect = (file: File) => {
    const previewUrl = URL.createObjectURL(file);
    setPendingStamp({ file, previewUrl });
  };

  // Step 2: user confirms → upload
  const confirmStampUpload = async () => {
    if (!pendingStamp) return;
    setStampUploading(true);
    setStampSuccess(false);
    setError(null);
    try {
      const formData = new FormData();
      formData.append("file", pendingStamp.file);
      const res = await api.post<{ url: string }>("/supervisor/upload-stamp", formData, {
        headers: { "Content-Type": "multipart/form-data" },
      });
      setStampUrl(res.data.url);
      setStampSuccess(true);
      setTimeout(() => setStampSuccess(false), 3000);
    } catch (e: unknown) {
      const msg = e && typeof e === "object" && "response" in e
        ? (e as { response?: { data?: { error?: string } } }).response?.data?.error
        : "Stamp upload failed.";
      setError(msg || "Stamp upload failed.");
    } finally {
      URL.revokeObjectURL(pendingStamp.previewUrl);
      setPendingStamp(null);
      setStampUploading(false);
    }
  };

  const cancelStampUpload = () => {
    if (pendingStamp) URL.revokeObjectURL(pendingStamp.previewUrl);
    setPendingStamp(null);
  };

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
          ? (e as { response?: { data?: { error?: string; message?: string } } }).response?.data?.error
            ?? (e as { response?: { data?: { error?: string; message?: string } } }).response?.data?.message
          : "Evaluation failed.";
      setError(msg || "Evaluation failed.");
    } finally {
      setBusy(null);
    }
  };

  const downloadPdf = async (studentId: number) => {
    setBusy(studentId);
    setError(null);
    try {
      const res = await api.get<{ reportUrl: string; message: string }>(`/reports/generate/${studentId}`);
      const url = res.data.reportUrl;
      await load();
      window.open(url, "_blank", "noopener,noreferrer");
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
      {/* Header + Stamp side by side */}
      <div className="flex flex-col gap-4 sm:flex-row sm:items-start sm:justify-between">
        <div>
          <h1 className="text-2xl font-bold text-slate-900 dark:text-slate-100">Final evaluation & reports</h1>
          <p className="mt-1 text-sm text-slate-500 dark:text-slate-400">
            Submit scores, generate stamped PDFs, then send to the university.
          </p>
        </div>

        {/* Compact stamp widget */}
        <div className="shrink-0 flex items-center gap-3 rounded-2xl border border-slate-200 bg-white px-4 py-3 shadow-sm dark:border-slate-700 dark:bg-slate-900">
          {stampUrl ? (
            <img src={stampUrl} alt="Company stamp" className="h-12 w-12 rounded-lg object-contain border border-slate-100 bg-slate-50 p-0.5 dark:border-slate-700 dark:bg-slate-800" />
          ) : (
            <div className="flex h-12 w-12 items-center justify-center rounded-lg border border-dashed border-slate-300 bg-slate-50 dark:border-slate-600 dark:bg-slate-800">
              <ImageIcon className="h-5 w-5 text-slate-400" />
            </div>
          )}
          <div className="min-w-0">
            <p className="text-xs font-semibold text-slate-700 dark:text-slate-200 flex items-center gap-1">
              <Stamp className="h-3.5 w-3.5 text-violet-500" />
              {stampUrl ? <span className="text-emerald-600 dark:text-emerald-400 flex items-center gap-1"><CheckCircle2 className="h-3 w-3" />Stamp active</span> : "No stamp"}
            </p>
            <input
              ref={fileInputRef}
              type="file"
              accept="image/png,image/jpeg,image/jpg"
              className="hidden"
              onChange={(e) => {
                const file = e.target.files?.[0];
                if (file) handleFileSelect(file);
                e.target.value = "";
              }}
            />
            <button
              type="button"
              disabled={stampUploading}
              onClick={() => fileInputRef.current?.click()}
              className="mt-0.5 inline-flex items-center gap-1 text-[11px] font-semibold text-primary-600 hover:text-primary-700 disabled:opacity-60"
            >
              <Upload className="h-3 w-3" />
              {stampUrl ? "Replace" : "Upload stamp"}
            </button>
            {stampSuccess && <p className="text-[11px] text-emerald-600 dark:text-emerald-400">Saved!</p>}
          </div>
        </div>
      </div>

      {error && (
        <div className="flex items-center gap-2 rounded-xl border border-red-200 bg-red-50 px-4 py-3 text-sm text-red-800 dark:border-red-900/50 dark:bg-red-950/30 dark:text-red-300">
          <AlertCircle className="h-4 w-4 shrink-0" />
          {error}
        </div>
      )}

      {/* Stamp preview confirmation modal */}
      {pendingStamp && (
        <div className="fixed inset-0 z-50 flex items-center justify-center bg-black/50 backdrop-blur-sm p-4">
          <div className="w-full max-w-sm rounded-2xl bg-white shadow-2xl dark:bg-slate-900 dark:border dark:border-slate-700">
            <div className="flex items-center justify-between px-5 pt-5 pb-3 border-b border-slate-100 dark:border-slate-700">
              <h3 className="text-sm font-bold text-slate-900 dark:text-slate-100">Confirm stamp</h3>
              <button type="button" onClick={cancelStampUpload} className="rounded-lg p-1 hover:bg-slate-100 dark:hover:bg-slate-800">
                <X className="h-4 w-4 text-slate-500" />
              </button>
            </div>
            <div className="px-5 py-5 flex flex-col items-center gap-4">
              <div className="rounded-xl border border-slate-200 bg-slate-50 p-4 dark:border-slate-700 dark:bg-slate-800">
                <img
                  src={pendingStamp.previewUrl}
                  alt="Stamp preview"
                  className="h-32 w-32 object-contain"
                />
              </div>
              <div className="text-center">
                <p className="text-sm font-semibold text-slate-900 dark:text-slate-100">
                  {stampUrl ? "Replace current stamp?" : "Use this as your company stamp?"}
                </p>
                <p className="mt-1 text-xs text-slate-500 dark:text-slate-400">
                  This image will be applied to the bottom-right of all generated PDFs.
                </p>
              </div>
            </div>
            <div className="flex gap-3 px-5 pb-5">
              <button
                type="button"
                onClick={cancelStampUpload}
                className="flex-1 rounded-xl border border-slate-200 py-2.5 text-sm font-semibold text-slate-600 hover:bg-slate-50 dark:border-slate-700 dark:text-slate-300 dark:hover:bg-slate-800"
              >
                Cancel
              </button>
              <button
                type="button"
                disabled={stampUploading}
                onClick={() => void confirmStampUpload()}
                className="flex-1 rounded-xl bg-primary-600 py-2.5 text-sm font-semibold text-white hover:bg-primary-700 disabled:opacity-60"
              >
                {stampUploading ? "Uploading…" : "Confirm & upload"}
              </button>
            </div>
          </div>
        </div>
      )}

      {/* Student evaluation cards */}
      <div className="space-y-4">
        {loading ? (
          <p className="text-slate-500 dark:text-slate-400">Loading…</p>
        ) : rows.length === 0 ? (
          <p className="text-slate-500 dark:text-slate-400">No placed students yet.</p>
        ) : (
          rows.map((r, idx) => {
            const fr = r.student.finalReport;
            const locked = fr?.locked === true;
            return (
              <div
                key={`${r.student.id}-${idx}`}
                className="rounded-2xl border border-slate-200 bg-white p-5 shadow-sm dark:border-slate-700 dark:bg-slate-900"
              >
                <div className="flex flex-col gap-4 sm:flex-row sm:items-start sm:justify-between">
                  <div>
                    <p className="font-semibold text-slate-900 dark:text-slate-100">{r.student.user.full_name}</p>
                    <p className="text-xs text-slate-500 dark:text-slate-400">{r.student.university.name}</p>
                    {r.student.finalEvaluation && (
                      <p className="mt-1 text-xs font-medium text-emerald-700 dark:text-emerald-300">
                        Evaluation saved — Technical: {r.student.finalEvaluation.technical_score} · Soft skills: {r.student.finalEvaluation.soft_skill_score}
                        {r.student.finalEvaluation.comments ? ` · "${r.student.finalEvaluation.comments}"` : ""}
                      </p>
                    )}
                    {locked && fr?.sent_at && (
                      <p className="mt-1 text-xs font-medium text-emerald-700 dark:text-emerald-300">
                        Sent to university on {new Date(fr.sent_at).toLocaleString()}
                      </p>
                    )}
                  </div>
                  <div className="flex flex-wrap gap-2">
                    <button
                      type="button"
                      disabled={busy === r.student.id || locked}
                      onClick={() => void downloadPdf(r.student.id)}
                      className="inline-flex items-center gap-1.5 rounded-xl border border-slate-200 px-3 py-2 text-xs font-semibold text-slate-700 hover:bg-slate-50 disabled:opacity-50 dark:border-slate-700 dark:text-slate-200 dark:hover:bg-slate-800"
                    >
                      <Download className="h-4 w-4" />
                      Generate PDF
                    </button>
                    {fr?.pdf_url && (
                      <button
                        type="button"
                        onClick={() => window.open(fr.pdf_url, "_blank", "noopener,noreferrer")}
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
                  <label className="text-xs font-medium text-slate-600 dark:text-slate-300">
                    Technical (0–100)
                    <input
                      type="number" min={0} max={100} step={0.1} disabled={locked}
                      value={form[r.student.id]?.technical ?? ""}
                      onChange={(e) => setForm((prev) => ({ ...prev, [r.student.id]: { ...prev[r.student.id], technical: e.target.value, soft: prev[r.student.id]?.soft ?? "", comments: prev[r.student.id]?.comments ?? "" } }))}
                      className="mt-1 w-full rounded-lg border border-slate-200 px-3 py-2 text-sm disabled:bg-slate-50 dark:border-slate-700 dark:bg-slate-900 dark:text-slate-100 dark:disabled:bg-slate-800"
                    />
                  </label>
                  <label className="text-xs font-medium text-slate-600 dark:text-slate-300">
                    Soft skills (0–100)
                    <input
                      type="number" min={0} max={100} step={0.1} disabled={locked}
                      value={form[r.student.id]?.soft ?? ""}
                      onChange={(e) => setForm((prev) => ({ ...prev, [r.student.id]: { ...prev[r.student.id], soft: e.target.value, technical: prev[r.student.id]?.technical ?? "", comments: prev[r.student.id]?.comments ?? "" } }))}
                      className="mt-1 w-full rounded-lg border border-slate-200 px-3 py-2 text-sm disabled:bg-slate-50 dark:border-slate-700 dark:bg-slate-900 dark:text-slate-100 dark:disabled:bg-slate-800"
                    />
                  </label>
                  <label className="text-xs font-medium text-slate-600 dark:text-slate-300 sm:col-span-1">
                    Comments
                    <input
                      type="text" disabled={locked}
                      value={form[r.student.id]?.comments ?? ""}
                      onChange={(e) => setForm((prev) => ({ ...prev, [r.student.id]: { ...prev[r.student.id], comments: e.target.value, technical: prev[r.student.id]?.technical ?? "", soft: prev[r.student.id]?.soft ?? "" } }))}
                      className="mt-1 w-full rounded-lg border border-slate-200 px-3 py-2 text-sm disabled:bg-slate-50 dark:border-slate-700 dark:bg-slate-900 dark:text-slate-100 dark:disabled:bg-slate-800"
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
