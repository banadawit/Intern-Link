"use client";

import React, { useEffect, useState } from 'react';
import {
  Building2,
  User,
  Mail,
  CheckCircle2,
  Clock,
  XCircle,
  ArrowRight,
  ClipboardList,
  MessageSquare,
  TrendingUp,
} from 'lucide-react';
import api from '@/lib/api/client';
import { mapStudentProfileFromMe, mapWeeklyPlanRow, type StudentMeResponse } from '@/lib/api/mappers';
import { StudentProfile, WeeklyPlan } from '@/lib/superadmin/types';
import { cn } from '@/lib/utils';
import Link from 'next/link';
import StudentPageHero from './StudentPageHero';

const StudentDashboard = () => {
  const [student, setStudent] = useState<StudentProfile | null>(null);
  const [plans, setPlans] = useState<WeeklyPlan[]>([]);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    let cancelled = false;
    (async () => {
      try {
        const [meRes, plansRes] = await Promise.all([
          api.get<StudentMeResponse>('/students/me'),
          api.get('/progress/my-plans'),
        ]);
        if (cancelled) return;
        setStudent(mapStudentProfileFromMe(meRes.data));
        const rows = (plansRes.data as Record<string, unknown>[]) ?? [];
        setPlans(rows.map((row) => mapWeeklyPlanRow(row as Parameters<typeof mapWeeklyPlanRow>[0])));
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

  const latestPlans: WeeklyPlan[] = plans.slice(-3).reverse();
  const allPlans = plans;
  const statPending = allPlans.filter((p) => p.status === 'Pending').length;
  const statApproved = allPlans.filter((p) => p.status === 'Approved').length;
  const statRejected = allPlans.filter((p) => p.status === 'Rejected').length;

  const name = student?.name ?? 'Student';
  const placement = student?.internshipStatus ?? '—';

  if (loading) {
    return (
      <div className="pb-8 pt-4 text-sm text-slate-500" role="status">
        Loading dashboard…
      </div>
    );
  }

  return (
    <div className="space-y-8 pb-8 animate-in fade-in duration-500">
      <StudentPageHero
        badge="Student home"
        title={`Welcome back, ${name}`}
        description="Track your internship, submit weekly plans, and stay connected with your supervisor — all in one place."
        action={
          <div className="flex w-full shrink-0 items-center gap-2 rounded-xl border border-border-default bg-white/90 px-4 py-3 shadow-sm backdrop-blur-sm sm:w-auto">
            <TrendingUp className="h-5 w-5 shrink-0 text-primary-600" />
            <div className="min-w-0">
              <p className="text-xs font-medium uppercase tracking-wide text-slate-500">Placement</p>
              <p className="text-sm font-semibold text-slate-900">{placement}</p>
            </div>
          </div>
        }
      />

      <section className="grid grid-cols-1 gap-4 sm:grid-cols-3">
        {[
          {
            label: 'Pending review',
            value: statPending,
            icon: Clock,
            accent: 'bg-amber-50 text-amber-700 ring-amber-100',
          },
          {
            label: 'Approved',
            value: statApproved,
            icon: CheckCircle2,
            accent: 'bg-emerald-50 text-emerald-700 ring-emerald-100',
          },
          {
            label: 'Needs revision',
            value: statRejected,
            icon: XCircle,
            accent: 'bg-red-50 text-red-700 ring-red-100',
          },
        ].map((s) => (
          <div
            key={s.label}
            className="group flex items-center gap-4 rounded-2xl border border-border-default bg-white p-5 shadow-sm transition-all duration-200 hover:border-primary-200 hover:shadow-md"
          >
            <div
              className={cn(
                'flex h-12 w-12 items-center justify-center rounded-xl ring-1 transition-transform duration-200 group-hover:scale-105',
                s.accent
              )}
            >
              <s.icon className="h-6 w-6" />
            </div>
            <div>
              <p className="text-xs font-semibold uppercase tracking-wide text-slate-500">{s.label}</p>
              <p className="text-2xl font-bold tabular-nums text-slate-900">{s.value}</p>
            </div>
          </div>
        ))}
      </section>

      <div className="grid grid-cols-1 gap-6 lg:grid-cols-3 lg:gap-8">
        <div className="card group p-6 transition-shadow duration-200 hover:shadow-md lg:col-span-2">
          <div className="mb-6 flex flex-col gap-4 sm:flex-row sm:items-center sm:justify-between">
            <div className="flex items-center gap-2">
              <ClipboardList className="h-5 w-5 text-primary-600" />
              <h2 className="text-lg font-bold text-slate-900">Internship overview</h2>
            </div>
            <span
              className={cn(
                'inline-flex w-fit items-center rounded-full px-3 py-1 text-xs font-bold uppercase tracking-wider ring-1',
                student?.internshipStatus === 'Placed'
                  ? 'bg-emerald-50 text-emerald-800 ring-emerald-100'
                  : student?.internshipStatus === 'Completed'
                    ? 'bg-slate-100 text-slate-800 ring-slate-200'
                    : 'bg-amber-50 text-amber-800 ring-amber-100'
              )}
            >
              {student?.internshipStatus ?? '—'}
            </span>
          </div>

          <div className="grid grid-cols-1 gap-6 md:grid-cols-2 md:gap-8">
            <div className="space-y-5">
              <div className="flex items-start gap-3 rounded-xl bg-slate-50/80 p-3 ring-1 ring-slate-100 transition-colors hover:bg-slate-50">
                <div className="rounded-lg bg-teal-50 p-2.5 text-teal-600">
                  <Building2 className="h-5 w-5" />
                </div>
                <div className="min-w-0">
                  <p className="text-xs font-bold uppercase tracking-wide text-slate-500">Assigned company</p>
                  <p className="font-semibold text-slate-900">{student?.assignedCompany || 'Not assigned'}</p>
                </div>
              </div>
              <div className="flex items-start gap-3 rounded-xl bg-slate-50/80 p-3 ring-1 ring-slate-100 transition-colors hover:bg-slate-50">
                <div className="rounded-lg bg-blue-50 p-2.5 text-blue-600">
                  <User className="h-5 w-5" />
                </div>
                <div className="min-w-0">
                  <p className="text-xs font-bold uppercase tracking-wide text-slate-500">Supervisor</p>
                  <p className="font-semibold text-slate-900">{student?.supervisorName || 'Not assigned'}</p>
                </div>
              </div>
            </div>

            <div className="space-y-5">
              <div className="flex items-start gap-3 rounded-xl bg-slate-50/80 p-3 ring-1 ring-slate-100 transition-colors hover:bg-slate-50">
                <div className="rounded-lg bg-violet-50 p-2.5 text-violet-600">
                  <Mail className="h-5 w-5" />
                </div>
                <div className="min-w-0">
                  <p className="text-xs font-bold uppercase tracking-wide text-slate-500">Supervisor email</p>
                  <p className="break-all font-semibold text-slate-900">{student?.supervisorEmail || 'N/A'}</p>
                </div>
              </div>
            </div>
          </div>
        </div>

        <div className="card flex flex-col p-6 transition-shadow duration-200 hover:shadow-md">
          <h2 className="mb-5 text-lg font-bold text-slate-900">Quick actions</h2>
          <div className="flex flex-1 flex-col gap-3">
            <Link
              href="/student/plans"
              className="group flex items-center justify-between rounded-xl border border-transparent bg-slate-50 px-4 py-3.5 font-medium text-slate-800 transition-all hover:border-primary-200 hover:bg-white hover:shadow-sm"
            >
              <span className="flex items-center gap-3">
                <span className="rounded-lg bg-primary-100 p-2 text-primary-700 transition-colors group-hover:bg-primary-600 group-hover:text-white">
                  <ClipboardList className="h-4 w-4" />
                </span>
                Submit weekly plan
              </span>
              <ArrowRight className="h-4 w-4 shrink-0 text-slate-400 transition-transform group-hover:translate-x-0.5 group-hover:text-primary-600" />
            </Link>
            <Link
              href="/student/common"
              className="group flex items-center justify-between rounded-xl border border-transparent bg-slate-50 px-4 py-3.5 font-medium text-slate-800 transition-all hover:border-primary-200 hover:bg-white hover:shadow-sm"
            >
              <span className="flex items-center gap-3">
                <span className="rounded-lg bg-sky-100 p-2 text-sky-700 transition-colors group-hover:bg-sky-600 group-hover:text-white">
                  <MessageSquare className="h-4 w-4" />
                </span>
                Post experience
              </span>
              <ArrowRight className="h-4 w-4 shrink-0 text-slate-400 transition-transform group-hover:translate-x-0.5 group-hover:text-primary-600" />
            </Link>
          </div>
        </div>
      </div>

      <section className="card overflow-hidden p-0 transition-shadow duration-200 hover:shadow-md">
        <div className="flex flex-col gap-4 border-b border-border-default bg-slate-50/50 px-5 py-4 sm:flex-row sm:items-center sm:justify-between sm:px-6">
          <div>
            <h2 className="text-lg font-bold text-slate-900">Recent weekly plans</h2>
            <p className="text-sm text-slate-500">Latest submissions and status</p>
          </div>
          <Link
            href="/student/plans"
            className="inline-flex items-center justify-center rounded-lg bg-primary-600 px-4 py-2 text-sm font-semibold text-white shadow-sm transition hover:bg-primary-700 hover:shadow active:bg-primary-800"
          >
            View all
          </Link>
        </div>

        <div className="hidden overflow-x-auto md:block">
          <table className="w-full min-w-[520px] text-left text-sm">
            <thead>
              <tr className="border-b border-border-default bg-white text-xs font-semibold uppercase tracking-wide text-slate-500">
                <th className="px-6 py-3">Week</th>
                <th className="px-6 py-3">Submitted</th>
                <th className="px-6 py-3">Status</th>
                <th className="px-6 py-3 text-right">Open</th>
              </tr>
            </thead>
            <tbody className="divide-y divide-border-default">
              {latestPlans.length === 0 ? (
                <tr>
                  <td colSpan={4} className="px-6 py-8 text-center text-slate-500">
                    No weekly plans yet.
                  </td>
                </tr>
              ) : (
                latestPlans.map((plan) => (
                  <tr key={plan.id} className="bg-white transition-colors hover:bg-slate-50/80">
                    <td className="px-6 py-4">
                      <div className="flex items-center gap-3">
                        <div
                          className={cn(
                            'rounded-lg p-2',
                            plan.status === 'Approved'
                              ? 'bg-emerald-50 text-emerald-600'
                              : plan.status === 'Rejected'
                                ? 'bg-red-50 text-red-600'
                                : 'bg-amber-50 text-amber-600'
                          )}
                        >
                          {plan.status === 'Approved' ? (
                            <CheckCircle2 className="h-4 w-4" />
                          ) : plan.status === 'Rejected' ? (
                            <XCircle className="h-4 w-4" />
                          ) : (
                            <Clock className="h-4 w-4" />
                          )}
                        </div>
                        <span className="font-semibold text-slate-900">Week {plan.weekNumber}</span>
                      </div>
                    </td>
                    <td className="px-6 py-4 text-slate-600">
                      {new Date(plan.submittedAt).toLocaleDateString(undefined, {
                        year: 'numeric',
                        month: 'short',
                        day: 'numeric',
                      })}
                    </td>
                    <td className="px-6 py-4">
                      <span
                        className={cn(
                          'inline-flex rounded-full px-2.5 py-0.5 text-xs font-bold',
                          plan.status === 'Approved'
                            ? 'bg-emerald-100 text-emerald-800'
                            : plan.status === 'Rejected'
                              ? 'bg-red-100 text-red-800'
                              : 'bg-amber-100 text-amber-800'
                        )}
                      >
                        {plan.status}
                      </span>
                    </td>
                    <td className="px-6 py-4 text-right">
                      <Link
                        href="/student/plans"
                        className="inline-flex items-center gap-1 rounded-lg px-2 py-1.5 text-sm font-medium text-primary-700 hover:bg-primary-50"
                      >
                        View
                        <ArrowRight className="h-4 w-4" />
                      </Link>
                    </td>
                  </tr>
                ))
              )}
            </tbody>
          </table>
        </div>

        <div className="space-y-3 p-4 md:hidden">
          {latestPlans.length === 0 ? (
            <p className="py-6 text-center text-sm text-slate-500">No weekly plans yet.</p>
          ) : (
            latestPlans.map((plan) => (
              <div
                key={plan.id}
                className="flex items-center justify-between gap-3 rounded-xl border border-border-default bg-white p-4 shadow-sm"
              >
                <div className="flex min-w-0 items-center gap-3">
                  <div
                    className={cn(
                      'shrink-0 rounded-lg p-2.5',
                      plan.status === 'Approved'
                        ? 'bg-emerald-50 text-emerald-600'
                        : plan.status === 'Rejected'
                          ? 'bg-red-50 text-red-600'
                          : 'bg-amber-50 text-amber-600'
                    )}
                  >
                    {plan.status === 'Approved' ? (
                      <CheckCircle2 className="h-5 w-5" />
                    ) : plan.status === 'Rejected' ? (
                      <XCircle className="h-5 w-5" />
                    ) : (
                      <Clock className="h-5 w-5" />
                    )}
                  </div>
                  <div className="min-w-0">
                    <p className="font-bold text-slate-900">Week {plan.weekNumber}</p>
                    <p className="text-xs text-slate-500">{new Date(plan.submittedAt).toLocaleDateString()}</p>
                  </div>
                </div>
                <Link
                  href="/student/plans"
                  className="shrink-0 rounded-lg bg-primary-600 px-3 py-2 text-xs font-semibold text-white shadow-sm active:bg-primary-800"
                >
                  View
                </Link>
              </div>
            ))
          )}
        </div>
      </section>
    </div>
  );
};

export default StudentDashboard;
