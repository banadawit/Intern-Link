"use client";

import { useEffect, useState } from "react";
import { useParams, useRouter } from "next/navigation";
import {
  ArrowLeft,
  Building2,
  Mail,
  MapPin,
  Calendar,
  Users,
  Briefcase,
  GraduationCap,
  FileText,
  Phone,
  CheckCircle2,
  Clock,
  XCircle,
  Loader2,
  RefreshCw,
} from "lucide-react";
import { format } from "date-fns";
import api from "@/lib/api/client";
import HodPageHero from "@/app/(dashboard)/hod/HodPageHero";

// ─── Types ────────────────────────────────────────────────────────────────────

type Supervisor = {
  id: number;
  full_name: string;
  email: string;
  phone_number: string | null;
  verification_status: string;
};

type ActiveStudent = {
  assignmentId: number;
  studentId: number;
  full_name: string;
  email: string;
  start_date: string;
  end_date: string | null;
  project_name: string | null;
};

type Proposal = {
  id: number;
  status: string;
  proposal_type: string;
  submitted_at: string;
  student_name: string;
  student_email: string;
};

type CompanyDetail = {
  id: number;
  name: string;
  official_email: string;
  address: string | null;
  approval_status: string;
  created_at: string;
  supervisors: Supervisor[];
  activeStudents: ActiveStudent[];
  proposals: Proposal[];
};

// ─── Helpers ──────────────────────────────────────────────────────────────────

function initials(name: string) {
  return name.split(" ").map((n) => n[0]).join("").slice(0, 2).toUpperCase();
}

function StatusBadge({ status }: { status: string }) {
  const map: Record<string, { label: string; cls: string; icon: React.ReactNode }> = {
    APPROVED: {
      label: "Approved",
      cls: "bg-emerald-50 text-emerald-700 ring-1 ring-emerald-200 dark:bg-emerald-900/30 dark:text-emerald-300 dark:ring-emerald-800",
      icon: <CheckCircle2 className="h-3.5 w-3.5" />,
    },
    PENDING: {
      label: "Pending",
      cls: "bg-amber-50 text-amber-700 ring-1 ring-amber-200 dark:bg-amber-900/30 dark:text-amber-300 dark:ring-amber-800",
      icon: <Clock className="h-3.5 w-3.5" />,
    },
    REJECTED: {
      label: "Rejected",
      cls: "bg-red-50 text-red-700 ring-1 ring-red-200 dark:bg-red-900/30 dark:text-red-300 dark:ring-red-800",
      icon: <XCircle className="h-3.5 w-3.5" />,
    },
  };
  const s = map[status] ?? {
    label: status,
    cls: "bg-slate-100 text-slate-600 ring-1 ring-slate-200 dark:bg-slate-800 dark:text-slate-300",
    icon: null,
  };
  return (
    <span className={`inline-flex items-center gap-1.5 rounded-full px-2.5 py-1 text-xs font-medium ${s.cls}`}>
      {s.icon}
      {s.label}
    </span>
  );
}

function SectionHeader({ icon: Icon, title, count }: { icon: React.ElementType; title: string; count: number }) {
  return (
    <div className="flex items-center gap-3 mb-4">
      <div className="rounded-xl bg-primary-50 p-2 text-primary-600 dark:bg-primary-900/30 dark:text-primary-400">
        <Icon className="h-5 w-5" />
      </div>
      <h2 className="text-lg font-bold text-slate-900 dark:text-slate-100">{title}</h2>
      <span className="rounded-full bg-slate-100 px-2.5 py-0.5 text-sm font-semibold text-slate-600 dark:bg-slate-800 dark:text-slate-300">
        {count}
      </span>
    </div>
  );
}

function EmptyCard({ icon: Icon, message }: { icon: React.ElementType; message: string }) {
  return (
    <div className="flex flex-col items-center justify-center rounded-2xl border-2 border-dashed border-slate-200 bg-white py-14 text-center dark:border-slate-700 dark:bg-slate-900">
      <Icon className="h-12 w-12 text-slate-300 dark:text-slate-600 mb-3" />
      <p className="text-sm text-slate-500 dark:text-slate-400">{message}</p>
    </div>
  );
}

// ─── Page ─────────────────────────────────────────────────────────────────────

export default function HodCompanyDetailPage() {
  const { id } = useParams<{ id: string }>();
  const router = useRouter();

  const [detail, setDetail] = useState<CompanyDetail | null>(null);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  const load = async () => {
    setLoading(true);
    setError(null);
    try {
      const res = await api.get(`/hod/companies/${id}`);
      setDetail(res.data.data);
    } catch {
      setError("Could not load company details.");
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => { void load(); }, [id]);

  if (loading) {
    return (
      <div className="flex min-h-[60vh] items-center justify-center">
        <Loader2 className="h-10 w-10 animate-spin text-primary-600" />
      </div>
    );
  }

  if (error || !detail) {
    return (
      <div className="space-y-4 pb-8">
        <button onClick={() => router.back()} className="inline-flex items-center gap-2 text-sm font-medium text-slate-500 hover:text-slate-800 dark:text-slate-400 dark:hover:text-slate-200">
          <ArrowLeft className="h-4 w-4" /> Back to companies
        </button>
        <div className="rounded-2xl border border-red-200 bg-red-50 px-4 py-3 text-sm text-red-800 dark:border-red-900/50 dark:bg-red-950/30 dark:text-red-300">
          {error ?? "Company not found."}
        </div>
      </div>
    );
  }

  const proposalStatusCounts = detail.proposals.reduce<Record<string, number>>((acc, p) => {
    acc[p.status] = (acc[p.status] ?? 0) + 1;
    return acc;
  }, {});

  return (
    <div className="space-y-8 pb-12">
      {/* Back nav */}
      <button
        onClick={() => router.back()}
        className="inline-flex items-center gap-2 text-sm font-medium text-slate-500 hover:text-slate-800 dark:text-slate-400 dark:hover:text-slate-200 transition-colors"
      >
        <ArrowLeft className="h-4 w-4" />
        Back to companies
      </button>

      {/* Hero */}
      <HodPageHero
        badge="Company"
        title={detail.name}
        description={`Verified company · Joined ${format(new Date(detail.created_at), "MMMM yyyy")}`}
        action={
          <button
            onClick={() => void load()}
            disabled={loading}
            className="inline-flex w-full shrink-0 items-center justify-center gap-2 rounded-xl border border-border-default bg-white/90 px-4 py-3 text-sm font-medium text-slate-800 shadow-sm backdrop-blur-sm transition-colors hover:bg-white disabled:opacity-60 sm:w-auto dark:bg-slate-900/90 dark:text-slate-100 dark:hover:bg-slate-900"
          >
            <RefreshCw className={`h-4 w-4 ${loading ? "animate-spin" : ""}`} />
            Refresh
          </button>
        }
      />

      {/* ── Summary stats ── */}
      <div className="grid grid-cols-2 gap-4 sm:grid-cols-4">
        {[
          { label: "Active students",  value: detail.activeStudents.length, icon: GraduationCap, color: "bg-emerald-50 text-emerald-600 dark:bg-emerald-900/30 dark:text-emerald-400" },
          { label: "Supervisors",      value: detail.supervisors.length,    icon: Users,         color: "bg-blue-50 text-blue-600 dark:bg-blue-900/30 dark:text-blue-400" },
          { label: "Total proposals",  value: detail.proposals.length,      icon: FileText,      color: "bg-violet-50 text-violet-600 dark:bg-violet-900/30 dark:text-violet-400" },
          { label: "Pending proposals",value: proposalStatusCounts["PENDING"] ?? 0, icon: Clock, color: "bg-amber-50 text-amber-600 dark:bg-amber-900/30 dark:text-amber-400" },
        ].map((s) => (
          <div key={s.label} className="flex items-center gap-3 rounded-2xl border border-slate-200 bg-white p-5 shadow-sm dark:border-slate-700 dark:bg-slate-900">
            <div className={`rounded-xl p-2.5 shrink-0 ${s.color}`}>
              <s.icon className="h-5 w-5" />
            </div>
            <div>
              <p className="text-2xl font-bold text-slate-900 dark:text-slate-100">{s.value}</p>
              <p className="text-xs text-slate-500 dark:text-slate-400">{s.label}</p>
            </div>
          </div>
        ))}
      </div>

      {/* ── Two-column layout: company info + supervisors ── */}
      <div className="grid gap-6 lg:grid-cols-2">

        {/* Company info card */}
        <div className="rounded-2xl border border-slate-200 bg-white p-6 shadow-sm dark:border-slate-700 dark:bg-slate-900">
          <SectionHeader icon={Building2} title="Company information" count={1} />
          <div className="space-y-4">
            <InfoRow icon={Mail} label="Official email" value={detail.official_email} />
            {detail.address && <InfoRow icon={MapPin} label="Address" value={detail.address} />}
            <InfoRow icon={Calendar} label="Registered" value={format(new Date(detail.created_at), "dd MMMM yyyy")} />
            <div className="flex items-center gap-2 pt-1">
              <span className="text-sm text-slate-500 dark:text-slate-400">Status</span>
              <StatusBadge status={detail.approval_status} />
            </div>
          </div>
        </div>

        {/* Supervisors card */}
        <div className="rounded-2xl border border-slate-200 bg-white p-6 shadow-sm dark:border-slate-700 dark:bg-slate-900">
          <SectionHeader icon={Users} title="Supervisors" count={detail.supervisors.length} />
          {detail.supervisors.length === 0 ? (
            <EmptyCard icon={Users} message="No supervisors registered at this company yet." />
          ) : (
            <div className="space-y-3">
              {detail.supervisors.map((sv) => (
                <div key={sv.id} className="flex items-start justify-between gap-3 rounded-xl border border-slate-100 bg-slate-50 p-4 dark:border-slate-700 dark:bg-slate-800">
                  <div className="flex items-center gap-3">
                    <div className="flex h-10 w-10 shrink-0 items-center justify-center rounded-full bg-blue-100 text-sm font-bold text-blue-700 dark:bg-blue-900/40 dark:text-blue-300">
                      {initials(sv.full_name)}
                    </div>
                    <div>
                      <p className="text-sm font-semibold text-slate-800 dark:text-slate-100">{sv.full_name}</p>
                      <p className="text-xs text-slate-500 dark:text-slate-400">{sv.email}</p>
                      {sv.phone_number && (
                        <p className="mt-0.5 flex items-center gap-1 text-xs text-slate-400 dark:text-slate-500">
                          <Phone className="h-3 w-3" />{sv.phone_number}
                        </p>
                      )}
                    </div>
                  </div>
                  <StatusBadge status={sv.verification_status} />
                </div>
              ))}
            </div>
          )}
        </div>
      </div>

      {/* ── Active students ── */}
      <div className="rounded-2xl border border-slate-200 bg-white p-6 shadow-sm dark:border-slate-700 dark:bg-slate-900">
        <SectionHeader icon={GraduationCap} title="Students currently placed" count={detail.activeStudents.length} />
        {detail.activeStudents.length === 0 ? (
          <EmptyCard icon={GraduationCap} message="No students from your university are currently placed at this company." />
        ) : (
          <div className="grid gap-4 sm:grid-cols-2 xl:grid-cols-3">
            {detail.activeStudents.map((s) => (
              <div key={s.assignmentId} className="rounded-xl border border-slate-100 bg-slate-50 p-4 dark:border-slate-700 dark:bg-slate-800">
                <div className="flex items-center gap-3 mb-3">
                  <div className="flex h-10 w-10 shrink-0 items-center justify-center rounded-full bg-primary-100 text-sm font-bold text-primary-700 dark:bg-primary-900/40 dark:text-primary-300">
                    {initials(s.full_name)}
                  </div>
                  <div className="min-w-0">
                    <p className="truncate text-sm font-semibold text-slate-800 dark:text-slate-100">{s.full_name}</p>
                    <p className="truncate text-xs text-slate-500 dark:text-slate-400">{s.email}</p>
                  </div>
                </div>
                <div className="space-y-1.5 text-xs text-slate-500 dark:text-slate-400">
                  {s.project_name && (
                    <div className="flex items-center gap-1.5">
                      <Briefcase className="h-3.5 w-3.5 shrink-0 text-slate-400" />
                      <span className="truncate">{s.project_name}</span>
                    </div>
                  )}
                  <div className="flex items-center gap-1.5">
                    <Calendar className="h-3.5 w-3.5 shrink-0 text-slate-400" />
                    <span>Started {format(new Date(s.start_date), "dd MMM yyyy")}</span>
                  </div>
                  {s.end_date && (
                    <div className="flex items-center gap-1.5">
                      <Calendar className="h-3.5 w-3.5 shrink-0 text-slate-400" />
                      <span>Ends {format(new Date(s.end_date), "dd MMM yyyy")}</span>
                    </div>
                  )}
                </div>
                <div className="mt-3 pt-3 border-t border-slate-200 dark:border-slate-700">
                  <span className="inline-flex items-center gap-1 rounded-full bg-emerald-50 px-2.5 py-0.5 text-xs font-medium text-emerald-700 ring-1 ring-emerald-200 dark:bg-emerald-900/30 dark:text-emerald-300 dark:ring-emerald-800">
                    <span className="h-1.5 w-1.5 rounded-full bg-emerald-500" />
                    Active placement
                  </span>
                </div>
              </div>
            ))}
          </div>
        )}
      </div>

      {/* ── Proposals ── */}
      <div className="rounded-2xl border border-slate-200 bg-white p-6 shadow-sm dark:border-slate-700 dark:bg-slate-900">
        <SectionHeader icon={FileText} title="Proposals from your university" count={detail.proposals.length} />
        {detail.proposals.length === 0 ? (
          <EmptyCard icon={FileText} message="No proposals have been sent to this company from your university yet." />
        ) : (
          <div className="overflow-x-auto">
            <table className="w-full text-sm">
              <thead>
                <tr className="border-b border-slate-100 bg-slate-50 text-left text-xs font-semibold uppercase tracking-wide text-slate-500 dark:border-slate-700 dark:bg-slate-800 dark:text-slate-400">
                  <th className="px-4 py-3">Student</th>
                  <th className="px-4 py-3">Type</th>
                  <th className="px-4 py-3">Submitted</th>
                  <th className="px-4 py-3">Status</th>
                </tr>
              </thead>
              <tbody className="divide-y divide-slate-100 dark:divide-slate-700">
                {detail.proposals.map((p) => (
                  <tr key={p.id} className="hover:bg-slate-50/60 dark:hover:bg-slate-800/60 transition-colors">
                    <td className="px-4 py-3">
                      <p className="font-medium text-slate-800 dark:text-slate-100">{p.student_name}</p>
                      <p className="text-xs text-slate-400 dark:text-slate-500">{p.student_email}</p>
                    </td>
                    <td className="px-4 py-3 text-slate-600 dark:text-slate-300">
                      {p.proposal_type
                        .replace("HoD_Initiated", "HOD Initiated")
                        .replace(/^HoD_Team:([^:]+):.*$/, "Team: $1")}
                    </td>
                    <td className="px-4 py-3 text-slate-500 dark:text-slate-400">
                      {format(new Date(p.submitted_at), "dd MMM yyyy")}
                    </td>
                    <td className="px-4 py-3">
                      <StatusBadge status={p.status} />
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

function InfoRow({ icon: Icon, label, value }: { icon: React.ElementType; label: string; value: string }) {
  return (
    <div className="flex items-start gap-3">
      <Icon className="h-4 w-4 shrink-0 text-slate-400 mt-0.5" />
      <div>
        <p className="text-xs font-medium text-slate-400 dark:text-slate-500">{label}</p>
        <p className="text-sm text-slate-700 dark:text-slate-300">{value}</p>
      </div>
    </div>
  );
}
