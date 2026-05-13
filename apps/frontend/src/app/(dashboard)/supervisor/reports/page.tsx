"use client";

import { useCallback, useEffect, useRef, useState } from "react";
import api from "@/lib/api/client";
import { AlertCircle, Download, FileCheck, Send, Eye, Stamp, Upload, CheckCircle2, ImageIcon, X } from "lucide-react";

type EvalForm = {
  technical_skills: string;
  problem_solving: string;
  communication: string;
  team_collaboration: string;
  time_management: string;
  adaptability: string;
  professionalism: string;
  initiative_creativity: string;
  attendance_punctuality: string;
  task_completion_quality: string;
  comments: string;
};

const CRITERIA: Array<{ key: keyof Omit<EvalForm, "comments">; label: string }> = [
  { key: "technical_skills", label: "Technical Skills" },
  { key: "problem_solving", label: "Problem Solving" },
  { key: "communication", label: "Communication" },
  { key: "team_collaboration", label: "Team Collaboration" },
  { key: "time_management", label: "Time Management" },
  { key: "adaptability", label: "Adaptability" },
  { key: "professionalism", label: "Professionalism" },
  { key: "initiative_creativity", label: "Initiative & Creativity" },
  { key: "attendance_punctuality", label: "Attendance & Punctuality" },
  { key: "task_completion_quality", label: "Task Completion Quality" },
];

const emptyForm = (): EvalForm => ({
  technical_skills: "",
  problem_solving: "",
  communication: "",
  team_collaboration: "",
  time_management: "",
  adaptability: "",
  professionalism: "",
  initiative_creativity: "",
  attendance_punctuality: "",
  task_completion_quality: "",
  comments: "",
});

type FinalEvaluation = {
  technical_skills: number;
  problem_solving: number;
  communication: number;
  team_collaboration: number;
  time_management: number;
  adaptability: number;
  professionalism: number;
  initiative_creativity: number;
  attendance_punctuality: number;
  task_completion_quality: number;
  comments: string | null;
};

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
    finalEvaluation?: FinalEvaluation | null;
  };
};

function avgEval(ev: FinalEvaluation): number {
  return Math.round((
    Number(ev.technical_skills) + Number(ev.problem_solving) + Number(ev.communication) +
    Number(ev.team_collaboration) + Number(ev.time_management) + Number(ev.adaptability) +
    Number(ev.professionalism) + Number(ev.initiative_creativity) + Number(ev.attendance_punctuality) +
    Number(ev.task_completion_quality)
  ) / 10 * 10) / 10;
}

export default function SupervisorReportsPage() {
  const [rows, setRows] = useState<StudentRow[]>([]);
  const [stampUrl, setStampUrl] = useState<string | null>(null);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);
  const [form, setForm] = useState<Record<number, EvalForm>>({});
  const [busy, setBusy] = useState<number | null>(null);
  const [stampUploading, setStampUploading] = useState(false);
  const [stampSuccess, setStampSuccess] = useState(false);
  const [confirmSend, setConfirmSend] = useState<{ studentId: number; studentName: string } | null>(null);
  const PAGE_SIZE = 2;
  const [search, setSearch] = useState("");
  const [page, setPage] = useState(1);
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
      const init: Record<number, EvalForm> = {};
      for (const r of rows) {
        const ev = r.student.finalEvaluation;
        init[r.student.id] = ev ? {
          technical_skills: String(ev.technical_skills),
          problem_solving: String(ev.problem_solving),
          communication: String(ev.communication),
          team_collaboration: String(ev.team_collaboration),
          time_management: String(ev.time_management),
          adaptability: String(ev.adaptability),
          professionalism: String(ev.professionalism),
          initiative_creativity: String(ev.initiative_creativity),
          attendance_punctuality: String(ev.attendance_punctuality),
          task_completion_quality: String(ev.task_completion_quality),
          comments: ev.comments ?? "",
        } : emptyForm();
      }
      setForm(init);
    } catch {
      setError("Could not load students.");
    } finally {
      setLoading(false);
    }
  }, []);

  useEffect(() => { void load(); }, [load]);

  const handleFileSelect = (file: File) => {
    const previewUrl = URL.createObjectURL(file);
    setPendingStamp({ file, previewUrl });
  };

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

  const setField = (studentId: number, key: keyof EvalForm, value: string) => {
    setForm((prev) => ({ ...prev, [studentId]: { ...prev[studentId], [key]: value } }));
  };

  const submitEval = async (studentId: number) => {
    const f = form[studentId];
    const allFilled = CRITERIA.every((c) => f?.[c.key] !== "");
    if (!allFilled) {
      setError("Please fill in all 10 evaluation criteria.");
      return;
    }
    setBusy(studentId);
    setError(null);
    try {
      await api.post("/reports/evaluate", {
        studentId,
        technical_skills: parseFloat(f.technical_skills),
        problem_solving: parseFloat(f.problem_solving),
        communication: parseFloat(f.communication),
        team_collaboration: parseFloat(f.team_collaboration),
        time_management: parseFloat(f.time_management),
        adaptability: parseFloat(f.adaptability),
        professionalism: parseFloat(f.professionalism),
        initiative_creativity: parseFloat(f.initiative_creativity),
        attendance_punctuality: parseFloat(f.attendance_punctuality),
        task_completion_quality: parseFloat(f.task_completion_quality),
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
      setConfirmSend(null);
    }
  };

  // Reset to page 1 when search changes
  const filteredRows = rows.filter((r) =>
    r.student.user.full_name.toLowerCase().includes(search.toLowerCase()) ||
    r.student.user.email.toLowerCase().includes(search.toLowerCase())
  );
  const totalPages = Math.max(1, Math.ceil(filteredRows.length / PAGE_SIZE));
  const pagedRows = filteredRows.slice((page - 1) * PAGE_SIZE, page * PAGE_SIZE);

  return (
    <div className="space-y-6">
      {/* Header + Stamp side by side */}
      <div className="flex flex-col gap-4 sm:flex-row sm:items-start sm:justify-between">
        <div>
          <h1 className="text-2xl font-bold text-slate-900 dark:text-slate-100">Final evaluation & reports</h1>
          <p className="mt-1 text-sm text-slate-500 dark:text-slate-400">
            Submit scores across 10 criteria, generate stamped PDFs, then send to the university.
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
                <img src={pendingStamp.previewUrl} alt="Stamp preview" className="h-32 w-32 object-contain" />
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

      {/* Send to university confirmation modal */}
      {confirmSend && (
        <div className="fixed inset-0 z-50 flex items-center justify-center bg-black/50 backdrop-blur-sm p-4">
          <div className="w-full max-w-sm rounded-2xl bg-white shadow-2xl dark:bg-slate-900 dark:border dark:border-slate-700">
            <div className="flex items-center justify-between px-5 pt-5 pb-3 border-b border-slate-100 dark:border-slate-700">
              <h3 className="text-sm font-bold text-slate-900 dark:text-slate-100">Send report to university</h3>
              <button type="button" onClick={() => setConfirmSend(null)} className="rounded-lg p-1 hover:bg-slate-100 dark:hover:bg-slate-800">
                <X className="h-4 w-4 text-slate-500" />
              </button>
            </div>
            <div className="px-5 py-5 space-y-3">
              <div className="flex items-center gap-3 rounded-xl border border-amber-200 bg-amber-50 px-4 py-3 dark:border-amber-900/50 dark:bg-amber-900/20">
                <Send className="h-5 w-5 shrink-0 text-amber-600 dark:text-amber-400" />
                <p className="text-sm text-amber-800 dark:text-amber-200">
                  This action is <strong>irreversible</strong>. The report will be locked after sending.
                </p>
              </div>
              <p className="text-sm text-slate-600 dark:text-slate-300">
                Send the final report for <strong>{confirmSend.studentName}</strong> to the university?
              </p>
            </div>
            <div className="flex gap-3 px-5 pb-5">
              <button
                type="button"
                onClick={() => setConfirmSend(null)}
                className="flex-1 rounded-xl border border-slate-200 py-2.5 text-sm font-semibold text-slate-600 hover:bg-slate-50 dark:border-slate-700 dark:text-slate-300 dark:hover:bg-slate-800"
              >
                Cancel
              </button>
              <button
                type="button"
                disabled={busy === confirmSend.studentId}
                onClick={() => void sendToUniversity(confirmSend.studentId)}
                className="flex-1 rounded-xl bg-primary-600 py-2.5 text-sm font-semibold text-white hover:bg-primary-700 disabled:opacity-60"
              >
                {busy === confirmSend.studentId ? "Sending…" : "Yes, send it"}
              </button>
            </div>
          </div>
        </div>
      )}

      {/* Search bar */}
      {!loading && rows.length > 0 && (
        <div className="flex items-center gap-3">
          <div className="relative flex-1 max-w-sm">
            <svg className="absolute left-3 top-1/2 -translate-y-1/2 h-4 w-4 text-slate-400" fill="none" viewBox="0 0 24 24" stroke="currentColor"><path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M21 21l-4.35-4.35M17 11A6 6 0 1 1 5 11a6 6 0 0 1 12 0z" /></svg>
            <input
              type="text"
              placeholder="Search by name or email…"
              value={search}
              onChange={(e) => { setSearch(e.target.value); setPage(1); }}
              className="w-full rounded-xl border border-slate-200 bg-white pl-9 pr-4 py-2.5 text-sm text-slate-900 placeholder-slate-400 shadow-sm focus:outline-none focus:ring-2 focus:ring-primary-500/20 focus:border-primary-500 dark:border-slate-700 dark:bg-slate-900 dark:text-slate-100 dark:placeholder-slate-500"
            />
          </div>
          <p className="text-xs text-slate-500 dark:text-slate-400 shrink-0">
            {filteredRows.length} student{filteredRows.length !== 1 ? "s" : ""}
          </p>
        </div>
      )}

      {/* Student evaluation cards */}
      <div className="space-y-4">
        {loading ? (
          <p className="text-slate-500 dark:text-slate-400">Loading…</p>
        ) : rows.length === 0 ? (
          <p className="text-slate-500 dark:text-slate-400">No placed students yet.</p>
        ) : filteredRows.length === 0 ? (
          <p className="text-slate-500 dark:text-slate-400">No students match your search.</p>
        ) : (
          <>
            {pagedRows.map((r, idx) => {
            const fr = r.student.finalReport;
            const locked = fr?.locked === true;
            const ev = r.student.finalEvaluation;
            return (
              <div
                key={`${r.student.id}-${idx}`}
                className="rounded-2xl border border-slate-200 bg-white p-5 shadow-sm dark:border-slate-700 dark:bg-slate-900"
              >
                <div className="flex flex-col gap-4 sm:flex-row sm:items-start sm:justify-between">
                  <div>
                    <p className="font-semibold text-slate-900 dark:text-slate-100">{r.student.user.full_name}</p>
                    <p className="text-xs text-slate-500 dark:text-slate-400">{r.student.university.name}</p>
                    {ev && (
                      <p className="mt-1 text-xs font-medium text-emerald-700 dark:text-emerald-300">
                        Evaluation saved — Avg score: {avgEval(ev)}/100
                        {ev.comments ? ` · "${ev.comments}"` : ""}
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
                        onClick={() => setConfirmSend({ studentId: r.student.id, studentName: r.student.user.full_name })}
                        className="inline-flex items-center gap-1.5 rounded-xl bg-primary-600 px-3 py-2 text-xs font-semibold text-white hover:bg-primary-700 disabled:opacity-50"
                      >
                        <Send className="h-4 w-4" />
                        Send to university
                      </button>
                    )}
                  </div>
                </div>

                {/* 10-criteria grid */}
                <div className="mt-4 grid gap-3 sm:grid-cols-2 lg:grid-cols-3">
                  {CRITERIA.map((c) => (
                    <label key={c.key} className="text-xs font-medium text-slate-600 dark:text-slate-300">
                      {c.label} (0–100)
                      <input
                        type="number" min={0} max={100} step={0.1} disabled={locked}
                        value={form[r.student.id]?.[c.key] ?? ""}
                        onChange={(e) => setField(r.student.id, c.key, e.target.value)}
                        className="mt-1 w-full rounded-lg border border-slate-200 px-3 py-2 text-sm disabled:bg-slate-50 dark:border-slate-700 dark:bg-slate-900 dark:text-slate-100 dark:disabled:bg-slate-800"
                      />
                    </label>
                  ))}
                  <label className="text-xs font-medium text-slate-600 dark:text-slate-300 sm:col-span-2 lg:col-span-3">
                    Comments
                    <input
                      type="text" disabled={locked}
                      value={form[r.student.id]?.comments ?? ""}
                      onChange={(e) => setField(r.student.id, "comments", e.target.value)}
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
          })}

            {/* Pagination */}
            {totalPages > 1 && (
              <div className="flex flex-col items-center gap-2 pt-2">
                <p className="text-xs text-slate-500 dark:text-slate-400">
                  Page {page} of {totalPages} · {filteredRows.length} student{filteredRows.length !== 1 ? "s" : ""}
                </p>
                <div className="flex items-center gap-1">
                  <button
                    type="button"
                    disabled={page === 1}
                    onClick={() => setPage((p) => p - 1)}
                    className="rounded-lg border border-slate-200 px-3 py-1.5 text-xs font-semibold text-slate-600 hover:bg-slate-50 disabled:opacity-40 dark:border-slate-700 dark:text-slate-300 dark:hover:bg-slate-800"
                  >
                    ← Prev
                  </button>
                  {Array.from({ length: totalPages }, (_, i) => i + 1).map((p) => (
                    <button
                      key={p}
                      type="button"
                      onClick={() => setPage(p)}
                      className={`rounded-lg border px-3 py-1.5 text-xs font-semibold transition-colors ${
                        p === page
                          ? "border-primary-600 bg-primary-600 text-white"
                          : "border-slate-200 text-slate-600 hover:bg-slate-50 dark:border-slate-700 dark:text-slate-300 dark:hover:bg-slate-800"
                      }`}
                    >
                      {p}
                    </button>
                  ))}
                  <button
                    type="button"
                    disabled={page === totalPages}
                    onClick={() => setPage((p) => p + 1)}
                    className="rounded-lg border border-slate-200 px-3 py-1.5 text-xs font-semibold text-slate-600 hover:bg-slate-50 disabled:opacity-40 dark:border-slate-700 dark:text-slate-300 dark:hover:bg-slate-800"
                  >
                    Next →
                  </button>
                </div>
              </div>
            )}
          </>
        )}
      </div>
    </div>
  );
}
