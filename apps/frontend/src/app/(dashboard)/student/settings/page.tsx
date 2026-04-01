"use client";

import React, { useEffect, useState } from "react";
import { Building2, Mail, User } from "lucide-react";
import api from "@/lib/api/client";
import { mapStudentProfileFromMe, type StudentMeResponse } from "@/lib/api/mappers";
import type { StudentProfile } from "@/lib/superadmin/types";
import { cn } from "@/lib/utils";
import StudentPageHero from "../StudentPageHero";

export default function StudentSettingsProfilePage() {
  const [student, setStudent] = useState<StudentProfile | null>(null);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    let cancelled = false;
    (async () => {
      try {
        const { data } = await api.get<StudentMeResponse>("/students/me");
        if (!cancelled) setStudent(mapStudentProfileFromMe(data));
      } catch {
        if (!cancelled) setStudent(null);
      } finally {
        if (!cancelled) setLoading(false);
      }
    })();
    return () => {
      cancelled = true;
    };
  }, []);

  if (loading) {
    return (
      <p className="pb-4 text-sm text-text-muted" role="status">
        Loading profile…
      </p>
    );
  }

  const s = student;
  if (!s) {
    return (
      <p className="text-sm text-red-600" role="alert">
        Could not load profile.
      </p>
    );
  }

  const initials = s.name
    .split(/\s+/)
    .map((p) => p[0])
    .join("")
    .slice(0, 2)
    .toUpperCase();

  return (
    <div className="space-y-8 pb-4 animate-in fade-in duration-300">
      <StudentPageHero
        badge="Settings"
        title="Profile"
        description="Your account details and internship placement summary."
      />

      <div className="card overflow-hidden p-0">
        <div className="flex flex-col gap-6 border-b border-border-default bg-slate-50/80 px-6 py-6 sm:flex-row sm:items-center sm:gap-8">
          <div className="flex h-20 w-20 shrink-0 items-center justify-center rounded-2xl bg-primary-light text-2xl font-bold text-primary-base ring-2 ring-white shadow-sm">
            {initials}
          </div>
          <div className="min-w-0">
            <h2 className="text-xl font-bold text-text-heading">{s.name}</h2>
            <p className="mt-1 text-sm text-text-muted">{s.email}</p>
            <span
              className={cn(
                "mt-3 inline-flex w-fit items-center rounded-full px-3 py-1 text-xs font-bold uppercase tracking-wider ring-1",
                s.internshipStatus === "Placed"
                  ? "bg-emerald-50 text-emerald-800 ring-emerald-100"
                  : s.internshipStatus === "Completed"
                    ? "bg-slate-100 text-slate-800 ring-slate-200"
                    : "bg-amber-50 text-amber-800 ring-amber-100"
              )}
            >
              {s.internshipStatus}
            </span>
          </div>
        </div>

        <div className="grid gap-6 p-6 sm:grid-cols-2">
          <div className="flex items-start gap-3 rounded-xl bg-slate-50/80 p-4 ring-1 ring-slate-100">
            <div className="rounded-lg bg-teal-50 p-2.5 text-teal-600">
              <Building2 className="h-5 w-5" />
            </div>
            <div className="min-w-0">
              <p className="text-xs font-bold uppercase tracking-wide text-slate-500">Assigned company</p>
              <p className="font-semibold text-slate-900">{s.assignedCompany || "Not assigned"}</p>
            </div>
          </div>
          <div className="flex items-start gap-3 rounded-xl bg-slate-50/80 p-4 ring-1 ring-slate-100">
            <div className="rounded-lg bg-blue-50 p-2.5 text-blue-600">
              <User className="h-5 w-5" />
            </div>
            <div className="min-w-0">
              <p className="text-xs font-bold uppercase tracking-wide text-slate-500">Supervisor</p>
              <p className="font-semibold text-slate-900">{s.supervisorName || "Not assigned"}</p>
            </div>
          </div>
          <div className="flex items-start gap-3 rounded-xl bg-slate-50/80 p-4 ring-1 ring-slate-100 sm:col-span-2">
            <div className="rounded-lg bg-violet-50 p-2.5 text-violet-600">
              <Mail className="h-5 w-5" />
            </div>
            <div className="min-w-0">
              <p className="text-xs font-bold uppercase tracking-wide text-slate-500">Supervisor email</p>
              <p className="break-all font-semibold text-slate-900">{s.supervisorEmail || "N/A"}</p>
            </div>
          </div>
        </div>
      </div>
    </div>
  );
}
