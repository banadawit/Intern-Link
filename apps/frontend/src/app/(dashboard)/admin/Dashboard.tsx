import React from "react";
import Link from "next/link";
import {
  Users,
  Building2,
  GraduationCap,
  Briefcase,
  TrendingUp,
  AlertCircle,
  Clock,
  FileText,
  ArrowRight,
  CheckCircle,
  XCircle,
} from "lucide-react";
import { BarChart, Bar, XAxis, YAxis, CartesianGrid, Tooltip, ResponsiveContainer } from "recharts";
import { cn } from "@/lib/utils";
import AdminPageHero from "./AdminPageHero";

export type AdminDashboardStats = {
  pendingUniversities: number;
  pendingCompanies: number;
  approvedUniversities: number;
  approvedCompanies: number;
  totalStudents: number;
  activeInternships: number;
  pendingCoordinators?: number;
  pendingSupervisors?: number;
  rejectedCoordinators?: number;
  rejectedSupervisors?: number;
  suspendedCoordinators?: number;
  suspendedSupervisors?: number;
};

const StatCard = ({
  icon: Icon,
  label,
  value,
  subValue,
  colorClass,
}: {
  icon: React.ComponentType<{ className?: string }>;
  label: string;
  value: string | number;
  subValue?: string;
  colorClass: string;
}) => (
  <div className="card flex items-start justify-between p-6 transition-shadow duration-200 hover:shadow-md">
    <div>
      <p className="mb-1 text-sm font-medium text-slate-500">{label}</p>
      <h3 className="text-2xl font-bold text-slate-900">{value}</h3>
      {subValue && <p className="mt-1 text-xs text-slate-500">{subValue}</p>}
    </div>
    <div className={cn("rounded-xl p-3", colorClass)}>
      <Icon className="h-6 w-6" />
    </div>
  </div>
);

type DashboardProps = {
  pendingVerificationCount: number;
  stats: AdminDashboardStats | null;
  statsLoading?: boolean;
};

const Dashboard = ({ pendingVerificationCount, stats, statsLoading }: DashboardProps) => {
  const chartData = stats
    ? [
        { name: "Universities", approved: stats.approvedUniversities, pending: stats.pendingUniversities },
        { name: "Companies", approved: stats.approvedCompanies, pending: stats.pendingCompanies },
      ]
    : [];

  const quickLinks = [
    { href: "/admin?view=pending", label: "Review pending", icon: Clock, accent: "bg-amber-50 text-amber-700 ring-amber-100" },
    { href: "/admin?view=approved", label: "Approved orgs", icon: CheckCircle, accent: "bg-emerald-50 text-emerald-700 ring-emerald-100" },
    { href: "/admin?view=rejected", label: "Rejected orgs", icon: XCircle, accent: "bg-red-50 text-red-700 ring-red-100" },
    { href: "/admin?view=audit-log", label: "Audit log", icon: FileText, accent: "bg-slate-100 text-slate-700 ring-slate-200" },
  ];

  return (
    <div className="space-y-8 animate-in fade-in duration-500">
      <AdminPageHero
        badge="Platform"
        title="System overview"
        description="Real-time statistics and platform health monitoring for universities, companies, and internships."
      />

      {pendingVerificationCount > 0 && (
        <div
          role="status"
          className="flex flex-col gap-3 rounded-2xl border border-amber-200 bg-amber-50/90 p-4 sm:flex-row sm:items-center sm:justify-between"
        >
          <div className="flex gap-3">
            <Clock className="mt-0.5 h-5 w-5 shrink-0 text-amber-600" aria-hidden />
            <div>
              <p className="font-semibold text-amber-950">{pendingVerificationCount} verification request(s) pending</p>
              <p className="text-sm text-amber-900/80">Review organization credentials to keep onboarding moving.</p>
            </div>
          </div>
          <Link
            href="/admin?view=pending"
            className="inline-flex shrink-0 items-center justify-center gap-2 rounded-xl bg-amber-600 px-4 py-2.5 text-sm font-semibold text-white shadow-sm transition hover:bg-amber-700"
          >
            Open queue
            <ArrowRight className="h-4 w-4" />
          </Link>
        </div>
      )}

      <div className="grid grid-cols-1 gap-4 sm:grid-cols-2 lg:grid-cols-4 lg:gap-6">
        <StatCard
          icon={GraduationCap}
          label="Universities"
          value={statsLoading ? "…" : stats?.approvedUniversities ?? "—"}
          subValue={stats ? `${stats.pendingUniversities} pending verification` : undefined}
          colorClass="bg-teal-50 text-teal-600"
        />
        <StatCard
          icon={Building2}
          label="Companies"
          value={statsLoading ? "…" : stats?.approvedCompanies ?? "—"}
          subValue={stats ? `${stats.pendingCompanies} pending verification` : undefined}
          colorClass="bg-blue-50 text-blue-600"
        />
        <StatCard
          icon={Users}
          label="Total Students"
          value={statsLoading ? "…" : stats?.totalStudents.toLocaleString() ?? "—"}
          colorClass="bg-purple-50 text-purple-600"
        />
        <StatCard
          icon={Briefcase}
          label="Active Internships"
          value={statsLoading ? "…" : stats?.activeInternships ?? "—"}
          colorClass="bg-orange-50 text-orange-600"
        />
      </div>

      <section>
        <h2 className="mb-4 text-sm font-semibold uppercase tracking-wide text-slate-500">Quick navigation</h2>
        <div className="grid grid-cols-1 gap-3 sm:grid-cols-2 lg:grid-cols-4">
          {quickLinks.map((q) => (
            <Link
              key={q.href}
              href={q.href}
              className={cn(
                "card group flex items-center justify-between gap-3 p-4 transition-all hover:border-teal-200 hover:shadow-md",
                "ring-1 ring-transparent hover:ring-teal-100"
              )}
            >
              <span className="flex min-w-0 items-center gap-3">
                <span className={cn("rounded-xl p-2.5 ring-1", q.accent)}>
                  <q.icon className="h-5 w-5" />
                </span>
                <span className="font-semibold text-slate-900">{q.label}</span>
              </span>
              <ArrowRight className="h-4 w-4 shrink-0 text-slate-400 transition-transform group-hover:translate-x-0.5 group-hover:text-teal-600" />
            </Link>
          ))}
        </div>
      </section>

      <div className="grid grid-cols-1 gap-6 lg:grid-cols-3">
        <div className="card p-6 lg:col-span-2">
          <h3 className="mb-6 text-lg font-bold text-slate-900">Verification distribution</h3>
          <div className="h-[300px]">
            {stats && chartData.length > 0 ? (
              <ResponsiveContainer width="100%" height="100%">
                <BarChart data={chartData}>
                  <CartesianGrid strokeDasharray="3 3" vertical={false} stroke="#E2E8F0" />
                  <XAxis dataKey="name" axisLine={false} tickLine={false} />
                  <YAxis axisLine={false} tickLine={false} />
                  <Tooltip contentStyle={{ borderRadius: "12px", border: "none", boxShadow: "0 4px 12px rgba(0,0,0,0.1)" }} />
                  <Bar dataKey="approved" fill="#0D9488" radius={[4, 4, 0, 0]} name="Approved" />
                  <Bar dataKey="pending" fill="#EAB308" radius={[4, 4, 0, 0]} name="Pending" />
                </BarChart>
              </ResponsiveContainer>
            ) : (
              <p className="text-sm text-slate-500">{statsLoading ? "Loading chart…" : "No statistics yet."}</p>
            )}
          </div>
        </div>

        <div className="card flex flex-col p-6">
          <h3 className="mb-6 text-lg font-bold text-slate-900">Security alerts</h3>
          <div className="space-y-4">
            <div className="flex items-start gap-3 rounded-lg border border-red-100 bg-red-50 p-3">
              <AlertCircle className="mt-0.5 h-5 w-5 shrink-0 text-red-600" />
              <div>
                <p className="text-sm font-semibold text-red-900">Suspicious activity</p>
                <p className="text-xs text-red-700">Multiple failed logins from IP 192.168.1.45</p>
              </div>
            </div>
            <div className="flex items-start gap-3 rounded-lg border border-yellow-100 bg-yellow-50 p-3">
              <TrendingUp className="mt-0.5 h-5 w-5 shrink-0 text-yellow-600" />
              <div>
                <p className="text-sm font-semibold text-yellow-900">High traffic</p>
                <p className="text-xs text-yellow-700">20% increase in student registrations today</p>
              </div>
            </div>
          </div>
          <Link
            href="/admin?view=audit-log"
            className="mt-6 w-full text-center text-sm font-medium text-teal-600 transition hover:text-teal-800 hover:underline"
          >
            View audit log
          </Link>
        </div>
      </div>
    </div>
  );
};

export default Dashboard;
