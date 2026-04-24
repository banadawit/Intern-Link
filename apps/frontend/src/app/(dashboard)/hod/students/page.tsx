"use client";

import { useCallback, useEffect, useState } from "react";
import api from "@/lib/api/client";
import { Loader2, RefreshCw } from "lucide-react";
import HodPageHero from "@/app/(dashboard)/hod/HodPageHero";
import HodStudentApprovalsTable from "@/components/hod/HodStudentApprovalsTable";
import type { HodStudentRow } from "@/components/hod/types";

export default function HodStudentsPage() {
  const [students, setStudents] = useState<HodStudentRow[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);
  const [submitting, setSubmitting] = useState(false);

  const load = useCallback(async () => {
    setLoading(true);
    setError(null);
    try {
      const res = await api.get<{ success: boolean; data: HodStudentRow[] }>("/hod/students", { params: { status: "all" } });
      setStudents(Array.isArray(res.data.data) ? res.data.data : []);
    } catch {
      setError("Could not load students.");
    } finally {
      setLoading(false);
    }
  }, []);

  useEffect(() => {
    void load();
  }, [load]);

  const actOnStudent = async (id: number, action: "approve" | "reject") => {
    setSubmitting(true);
    try {
      await api.patch(`/hod/students/${id}/${action}`);
      await load();
    } catch {
      setError(`Failed to ${action} student.`);
    } finally {
      setSubmitting(false);
    }
  };

  return (
    <div className="space-y-6 pb-8">
      <HodPageHero
        badge="Student approvals"
        title="Student approvals"
        description="Approve or reject student registrations in your department. Switch between table and card layout for long lists."
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

      {loading && students.length === 0 ? (
        <div className="flex min-h-[40vh] items-center justify-center text-slate-500">
          <Loader2 className="h-10 w-10 animate-spin text-primary-600" aria-hidden />
        </div>
      ) : (
        <HodStudentApprovalsTable
          students={students}
          submitting={submitting}
          onApprove={(id) => void actOnStudent(id, "approve")}
          onReject={(id) => void actOnStudent(id, "reject")}
        />
      )}
    </div>
  );
}
