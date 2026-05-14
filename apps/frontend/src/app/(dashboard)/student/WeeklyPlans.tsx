"use client";

import React, { useEffect, useRef, useState } from 'react';
import Link from 'next/link';
import { useRouter, useSearchParams } from 'next/navigation';
import { 
  Plus, 
  FileText, 
  Upload, 
  CheckCircle2, 
  XCircle, 
  Clock, 
  ChevronRight,
  AlertTriangle,
  Info,
  History,
  Pencil,
  ExternalLink,
  X,
  Sparkles,
  Calendar,
  ClipboardList,
  Send,
  Trash2,
} from 'lucide-react';
import api from '@/lib/api/client';
import { mapStudentProfileFromMe, mapWeeklyPlanRow, type StudentMeResponse } from '@/lib/api/mappers';
import type { StudentProfile, WeeklyPlan } from '@/lib/superadmin/types';
import { cn, getViewerUrl } from '@/lib/utils';
import { motion, AnimatePresence } from 'framer-motion';
import { STUDENT_WEEKLY_PLANS_EVENT } from '@/lib/student/planNotificationEvents';
import {
  getMissedInternshipWeeks,
  hasPlanForInternshipWeek,
  WEEKLY_DEADLINE_POLICY,
  WEEKLY_SUBMISSION_DEADLINE_LABEL,
} from '@/lib/student/weeklyDeadline';
import {
  maybeNotifyCurrentWeekDue,
  maybeNotifyMissedDeadlines,
} from '@/lib/student/desktopNotifications';
import StudentPageHero from './StudentPageHero';
import { getInternshipWeekDateStrings, getCalendarWeekWorkdays } from '@/lib/student/internshipWeekDates';
import ConfirmDialog from '@/components/shared/ConfirmDialog';
import SuccessToast from '@/components/shared/SuccessToast';

const WeeklyPlans = () => {
  const router = useRouter();
  const searchParams = useSearchParams();
  const [plans, setPlans] = useState<WeeklyPlan[]>([]);
  const [profile, setProfile] = useState<StudentProfile | null>(null);
  const [loadError, setLoadError] = useState<string | null>(null);
  const [initialLoad, setInitialLoad] = useState(true);
  const [submitting, setSubmitting] = useState(false);
  const [teamChannelMessage, setTeamChannelMessage] = useState<string | null>(null);
  const [isTeamLeader, setIsTeamLeader] = useState(false);
  const [notInTeam, setNotInTeam] = useState(false);
  const [lastOneStatus, setLastOneStatus] = useState<{ weekNum: number; submittedCount: number; totalCount: number } | null>(null);

  const [showSubmitForm, setShowSubmitForm] = useState(false);
  const [selectedPlan, setSelectedPlan] = useState<WeeklyPlan | null>(null);
  /** When set, the modal is revising this rejected plan (new version on submit). */
  const [reviseFromPlan, setReviseFromPlan] = useState<WeeklyPlan | null>(null);
  /** When set, the modal edits this pending plan in place (before supervisor approval). */
  const [editPendingPlan, setEditPendingPlan] = useState<WeeklyPlan | null>(null);

  const [formData, setFormData] = useState({
    weekNumber: 1,
    tasks: '',
    presentation: null as File | null,
  });
  const presentationInputRef = useRef<HTMLInputElement>(null);

  const currentWeek = profile?.currentInternshipWeek ?? 1;

  const loadPlansAndProfile = async (): Promise<WeeklyPlan[] | null> => {
    try {
      setLoadError(null);
      const [meRes, plansRes] = await Promise.all([
        api.get('/students/me'),
        api.get('/progress/my-plans'),
      ]);
      const meRaw = meRes.data as { success?: boolean; data?: StudentMeResponse } | StudentMeResponse;
      const meData: StudentMeResponse = (meRaw as { success?: boolean; data?: StudentMeResponse })?.data ?? meRaw as StudentMeResponse;
      const mappedProfile = mapStudentProfileFromMe(meData);
      setProfile(mappedProfile);
      const plansRaw = plansRes.data as { success?: boolean; data?: unknown[] } | unknown[];
      const plansData = (plansRaw as { success?: boolean; data?: unknown[] })?.data ?? plansRaw as Record<string, unknown>[];
      const rows = Array.isArray(plansData) ? plansData as Record<string, unknown>[] : [];
      const mapped = rows.map((row) => mapWeeklyPlanRow(row as Parameters<typeof mapWeeklyPlanRow>[0]));
      setPlans(mapped);
      // Check if student is in a team with a TL (restricted from direct submission)
      try {
        const teamRes = await api.get<{ success: boolean; data: { isManager?: boolean; team?: { name: string } | null; plans?: { week_number: number }[] } | null }>("/progress/team-plans/my");
        const td = teamRes.data.data;
        if (td && td.team && !td.isManager) {
          setTeamChannelMessage(
            `You are in team "${(td.team as { name: string }).name}". Submit your weekly plan and daily check-ins here. Your Team Leader reviews them first; they compile the team weekly plan for your supervisor.`,
          );
          setIsTeamLeader(false);
          setNotInTeam(false);

          // Check if this student is the last one who hasn't submitted for the current week
          try {
            const membersRes = await api.get<{ success: boolean; data: { teamId: number; teamName: string; members: { studentId: number; weeklyPlans: { weekNumber: number }[] }[] } }>("/progress/team-plans/members");
            const membersData = membersRes.data.data;
            if (membersData) {
              const submittedWeeks = new Set(mapped.map((p) => p.weekNumber));
              const allMembers = membersData.members;
              const totalCount = allMembers.length + 1; // +1 for the TL (not in members list)

              // Find the highest week where others have submitted but this student hasn't
              const otherWeeks = new Set(allMembers.flatMap((m) => m.weeklyPlans.map((p) => p.weekNumber)));
              let lastOneWeek: number | null = null;
              for (const wk of otherWeeks) {
                if (!submittedWeeks.has(wk)) {
                  lastOneWeek = wk;
                  break;
                }
              }
              if (lastOneWeek !== null) {
                const submittedCount = allMembers.filter((m) =>
                  m.weeklyPlans.some((p) => p.weekNumber === lastOneWeek)
                ).length;
                const missing = totalCount - submittedCount - 1; // -1 for this student
                if (missing === 0) {
                  // This student is the only one who hasn't submitted
                  setLastOneStatus({ weekNum: lastOneWeek, submittedCount, totalCount });
                } else {
                  setLastOneStatus(null);
                }
              } else {
                setLastOneStatus(null);
              }
            }
          } catch {
            setLastOneStatus(null);
          }
        } else {
          setTeamChannelMessage(null);
          setIsTeamLeader(!!(td && td.team && td.isManager));
          setLastOneStatus(null);
          // td.team is null → student is not in any team
          // We'll let the backend enforce the block; just track it for UI
          setNotInTeam(!(td && td.team));
        }
      } catch {
        setTeamChannelMessage(null);
        setIsTeamLeader(false);
        setLastOneStatus(null);
        setNotInTeam(false);
      }
      // Find the next week number not yet submitted
      const submittedWeeks = new Set(mapped.map((p) => p.weekNumber));
      let nextWeek = 1;
      while (submittedWeeks.has(nextWeek)) nextWeek++;
      setFormData((prev) => ({
        ...prev,
        weekNumber: nextWeek,
      }));
      return mapped;
    } catch (e: unknown) {
      const msg = e && typeof e === 'object' && 'response' in e && e.response && typeof e.response === 'object' && 'data' in e.response
        ? JSON.stringify((e.response as { data?: unknown }).data)
        : 'Failed to load weekly plans.';
      setLoadError(typeof msg === 'string' ? msg : 'Failed to load.');
      return null;
    } finally {
      setInitialLoad(false);
    }
  };

  useEffect(() => {
    loadPlansAndProfile();
  }, []);

  const closeSubmitModal = () => {
    setShowSubmitForm(false);
    setReviseFromPlan(null);
    setEditPendingPlan(null);
  };

  useEffect(() => {
    window.dispatchEvent(
      new CustomEvent(STUDENT_WEEKLY_PLANS_EVENT, { detail: { plans } })
    );
  }, [plans]);

  /** Open the matching plan from /student/plans?plan=<id> (e.g. notification link). */
  useEffect(() => {
    const planId = searchParams.get('plan');
    if (!planId) return;
    const found = plans.find((p) => p.id === planId);
    if (!found) {
      router.replace('/student/plans', { scroll: false });
      return;
    }
    setSelectedPlan(found);
    queueMicrotask(() => {
      document.getElementById(`weekly-plan-${planId}`)?.scrollIntoView({
        behavior: 'smooth',
        block: 'center',
      });
    });
    router.replace('/student/plans', { scroll: false });
  }, [searchParams, plans, router]);

  const [dayToggleBusy, setDayToggleBusy] = useState<string | null>(null);
  const [toast, setToast] = useState<{ show: boolean; message: string }>({ show: false, message: "" });
  const [confirmSubmit, setConfirmSubmit] = useState<React.FormEvent | null>(null);
  // Inline edit state for team student daily plans
  const [editingDay, setEditingDay] = useState<string | null>(null); // "planId-ymd"
  const [editingDayNotes, setEditingDayNotes] = useState("");
  const [savingDay, setSavingDay] = useState<string | null>(null);

  const togglePlanDay = async (planId: string, ymd: string, currentlyOn: boolean) => {
    setDayToggleBusy(`${planId}-${ymd}`);
    setLoadError(null);
    try {
      if (currentlyOn) {
        await api.delete(`/progress/plan/${planId}/days/${ymd}`);
      } else {
        await api.post(`/progress/plan/${planId}/days`, { workDate: ymd });
      }
      const mapped = await loadPlansAndProfile();
      if (mapped && selectedPlan) {
        const u = mapped.find((p) => p.id === selectedPlan.id);
        if (u) setSelectedPlan(u);
      }
    } catch (err: unknown) {
      const data =
        err && typeof err === 'object' && 'response' in err
          ? (err as { response?: { data?: { message?: string } } }).response?.data
          : undefined;
      setLoadError(data?.message ?? 'Could not update daily check-in.');
    } finally {
      setDayToggleBusy(null);
    }
  };

  const saveDayEdit = async (planId: string, ymd: string, notes: string, isNew = false) => {
    const key = `${planId}-${ymd}`;
    setSavingDay(key);
    setLoadError(null);
    try {
      const res = await api.patch(`/progress/plan/${planId}/days/${ymd}`, { notes: notes.trim() || null });
      console.log('[saveDayEdit] success', res.data);
      setEditingDay(null);
      setEditingDayNotes("");
      const mapped = await loadPlansAndProfile();
      if (mapped) {
        const u = mapped.find((p) => p.id === planId);
        if (u) setSelectedPlan(u);
      }
      setToast({ show: true, message: isNew ? "✅ Daily plan submitted to Team Leader" : "✅ Daily plan updated and resubmitted to Team Leader" });
    } catch (err: unknown) {
      console.error('[saveDayEdit] error', err);
      const data =
        err && typeof err === 'object' && 'response' in err
          ? (err as { response?: { data?: { message?: string } } }).response?.data
          : undefined;
      setLoadError(data?.message ?? 'Could not save daily plan. Please try again.');
    } finally {
      setSavingDay(null);
    }
  };

  const [deletingPlan, setDeletingPlan] = useState<string | null>(null);
  const [confirmDeletePlan, setConfirmDeletePlan] = useState<WeeklyPlan | null>(null);

  const deleteWeeklyPlan = async (planId: string) => {
    setDeletingPlan(planId);
    setLoadError(null);
    try {
      await api.delete(`/progress/plan/${planId}`);
      if (selectedPlan?.id === planId) setSelectedPlan(null);
      await loadPlansAndProfile();
      setToast({ show: true, message: "🗑️ Weekly plan deleted" });
    } catch (err: unknown) {
      const data =
        err && typeof err === 'object' && 'response' in err
          ? (err as { response?: { data?: { message?: string } } }).response?.data
          : undefined;
      setLoadError(data?.message ?? 'Could not delete plan.');
    } finally {
      setDeletingPlan(null);
    }
  };

  const missedWeeks = getMissedInternshipWeeks(plans, currentWeek);
  const hasCurrentWeekPlan = hasPlanForInternshipWeek(plans, currentWeek);

  useEffect(() => {
    const missed = getMissedInternshipWeeks(plans, currentWeek);
    const hasCurrent = hasPlanForInternshipWeek(plans, currentWeek);
    maybeNotifyMissedDeadlines(missed);
    maybeNotifyCurrentWeekDue(currentWeek, hasCurrent);
  }, [plans, currentWeek]);

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    setSubmitting(true);
    try {
      if (editPendingPlan) {
        await api.patch(`/progress/plan/${editPendingPlan.id}`, {
          plan_description: formData.tasks,
        });
        await loadPlansAndProfile();
        closeSubmitModal();
        setToast({ show: true, message: "✅ Plan updated successfully" });
        return;
      }

      if (reviseFromPlan) {
        const isSupervisorRejected = reviseFromPlan.status === "Rejected";
        if (isSupervisorRejected) {
          const fd = new FormData();
          fd.append("plan_description", formData.tasks);
          if (formData.presentation) {
            fd.append("attachments", formData.presentation);
          }
          await api.post(`/progress/plan/${reviseFromPlan.id}/resubmit`, fd);
        } else {
          await api.patch(`/progress/plan/${reviseFromPlan.id}`, {
            plan_description: formData.tasks,
          });
        }
        await loadPlansAndProfile();
        setReviseFromPlan(null);
        setFormData({
          weekNumber: formData.weekNumber,
          tasks: "",
          presentation: null,
        });
        closeSubmitModal();
        setToast({
          show: true,
          message: isSupervisorRejected
            ? "✅ Revised plan submitted"
            : "✅ Updated plan sent back to your Team Leader",
        });
        return;
      }

      const fd = new FormData();
      fd.append("week_number", String(formData.weekNumber));
      fd.append("plan_description", formData.tasks);
      if (formData.presentation) {
        fd.append("presentation", formData.presentation);
      }
      await api.post("/progress/submit", fd);
      await loadPlansAndProfile();
      setReviseFromPlan(null);
      // Next week is recalculated by loadPlansAndProfile via the submittedWeeks logic
      setFormData({
        weekNumber: formData.weekNumber, // will be overwritten by loadPlansAndProfile
        tasks: '',
        presentation: null,
      });
      closeSubmitModal();
      setToast({ show: true, message: "✅ Weekly plan submitted successfully" });
    } catch (err: unknown) {
      const data = err && typeof err === 'object' && 'response' in err ? (err as { response?: { data?: { message?: string } } }).response?.data : undefined;
      setLoadError(data?.message ?? 'Could not submit plan. Are you placed with a company?');
    } finally {
      setSubmitting(false);
    }
  };

  return (
    <div className="space-y-8 animate-in fade-in duration-500">
      {loadError && (
        <div className="rounded-xl border border-red-200 bg-red-50 px-4 py-3 text-sm text-red-800 dark:border-red-900/50 dark:bg-red-950/30 dark:text-red-300" role="alert">
          {loadError}
        </div>
      )}
      {initialLoad && (
        <p className="text-sm text-text-muted" role="status">
          Loading weekly plans…
        </p>
      )}
      <StudentPageHero
        badge="Weekly plans"
        title="Weekly Plans"
        description={
          teamChannelMessage
            ? "Submit your weekly plan and daily check-ins; your Team Leader reviews them before the supervisor."
            : "Submit your weekly tasks and track supervisor feedback."
        }
        action={
          <button
            type="button"
            disabled={notInTeam}
            onClick={() => {
              if (notInTeam) return;
              setReviseFromPlan(null);
              setEditPendingPlan(null);
              setShowSubmitForm(true);
            }}
            className="btn-primary flex w-full items-center justify-center gap-2 sm:w-auto disabled:opacity-50 disabled:cursor-not-allowed"
          >
            <Plus className="h-5 w-5" />
            Submit New Plan
          </button>
        }
      />

      {/* Not in team — blocking banner */}
      {notInTeam && (
        <div
          role="alert"
          className="flex gap-3 rounded-2xl border border-red-200 bg-red-50/90 p-4 text-red-950 shadow-sm dark:border-red-800 dark:bg-red-900/20 dark:text-red-100"
        >
          <span className="text-xl shrink-0" aria-hidden>🚫</span>
          <div className="min-w-0 space-y-1">
            <p className="font-semibold text-red-900 dark:text-red-200">Team assignment required</p>
            <p className="text-sm leading-relaxed text-red-900/90 dark:text-red-300">
              You are not assigned to a team yet. Your supervisor must add you to a team before you can submit a weekly plan.
            </p>
          </div>
        </div>
      )}

      {/* Team workflow: member submits here → Team Leader → supervisor */}
      {teamChannelMessage && (
        <div className="flex items-start gap-3 rounded-2xl border border-primary-100 bg-primary-50/60 p-4 text-slate-800 shadow-sm dark:border-primary-900/50 dark:bg-primary-900/20 dark:text-slate-200">
          <span className="text-lg shrink-0" aria-hidden>
            👑
          </span>
          <div className="min-w-0 space-y-1">
            <p className="font-semibold text-slate-900 dark:text-slate-100">Team workflow</p>
            <p className="text-sm leading-relaxed">{teamChannelMessage}</p>
            <Link
              href="/student/team"
              className="inline-block mt-1 text-sm font-semibold text-primary-600 hover:underline dark:text-primary-400"
            >
              Open Team tab (Collect Plans is for your Team Leader)
            </Link>
          </div>
        </div>
      )}

      {/* Last-one-remaining banner for team students */}
      {lastOneStatus && (
        <div
          role="alert"
          className="flex gap-3 rounded-2xl border border-amber-300 bg-amber-50/90 p-4 text-amber-950 shadow-sm dark:border-amber-700 dark:bg-amber-900/20 dark:text-amber-100"
        >
          <span className="text-xl shrink-0" aria-hidden>⏳</span>
          <div className="min-w-0 space-y-1">
            <p className="font-semibold text-amber-900 dark:text-amber-200">
              You&apos;re the last one for Week {lastOneStatus.weekNum}!
            </p>
            <p className="text-sm leading-relaxed text-amber-900/90 dark:text-amber-300">
              {lastOneStatus.submittedCount} out of {lastOneStatus.totalCount} teammates have already submitted their Week {lastOneStatus.weekNum} plan. Submit yours so your Team Leader can compile and forward the team plan.
            </p>
          </div>
        </div>
      )}

      {missedWeeks.length > 0 && (        <div
          role="alert"
          className="flex gap-3 rounded-2xl border border-red-200 bg-red-50/90 p-4 text-red-950 shadow-sm"
        >
          <AlertTriangle className="mt-0.5 h-5 w-5 shrink-0 text-red-600" aria-hidden />
          <div className="min-w-0 space-y-1">
            <p className="font-semibold text-red-900">Missed weekly deadline</p>
            <p className="text-sm leading-relaxed text-red-900/90">
              You have no submission on file for{' '}
              {missedWeeks.length === 1
                ? `week ${missedWeeks[0]}`
                : `weeks ${missedWeeks.join(', ')}`}
              . Submit your plan as soon as possible — your supervisor may be notified for overdue work.
            </p>
          </div>
        </div>
      )}

      {!hasCurrentWeekPlan && (
        <div className="flex gap-3 rounded-2xl border border-amber-200 bg-amber-50/90 p-4 text-amber-950 shadow-sm">
          <Clock className="mt-0.5 h-5 w-5 shrink-0 text-amber-700" aria-hidden />
          <div className="min-w-0 space-y-1">
            <p className="font-semibold text-amber-900">Week {currentWeek} plan due</p>
            <p className="text-sm leading-relaxed text-amber-900/90">
              Submit your weekly plan before <strong>{WEEKLY_SUBMISSION_DEADLINE_LABEL}</strong>. Enable
              desktop alerts in the header to get reminders.
            </p>
          </div>
        </div>
      )}

      <details className="group rounded-2xl border border-border-default bg-white shadow-sm dark:bg-slate-900">
        <summary className="flex cursor-pointer list-none items-center gap-2 px-5 py-4 text-sm font-semibold text-text-heading hover:bg-bg-secondary/50 [&::-webkit-details-marker]:hidden">
          <Info className="h-4 w-4 shrink-0 text-primary-600" aria-hidden />
          What happens if you miss a weekly submission deadline?
          <span className="ml-auto text-xs font-normal text-text-muted group-open:hidden">Show</span>
          <span className="ml-auto hidden text-xs font-normal text-text-muted group-open:inline">Hide</span>
        </summary>
        <div className="space-y-3 border-t border-border-default px-5 py-4 text-sm leading-relaxed text-text-body">
          <p>
            Standard cutoff: <strong>{WEEKLY_DEADLINE_POLICY.deadlineLabel}</strong>. The platform
            compares your submissions to the current internship week (
            <strong>week {currentWeek}</strong> based on your placement start date).
          </p>
          <ul className="list-inside list-disc space-y-2 text-text-muted">
            {WEEKLY_DEADLINE_POLICY.points.map((line, idx) => (
              <li key={idx}>{line}</li>
            ))}
          </ul>
          <p className="text-xs text-text-muted">
            Turn on <strong>Alerts</strong> from the{' '}
            <Link href="/student/settings/alerts" className="font-semibold text-primary-600 underline-offset-2 hover:underline">
              top bar
            </Link>{' '}
            for browser notifications when deadlines are missed or your current week is still unsubmitted
            (once you allow notifications in the browser).
          </p>
        </div>
      </details>

      <div className="grid grid-cols-1 lg:grid-cols-3 gap-8">
        {/* Plans List */}
        <div className="lg:col-span-2 space-y-4">
          {plans.slice().reverse().map((plan) => (
            <div 
              key={plan.id}
              id={`weekly-plan-${plan.id}`}
              onClick={() => setSelectedPlan(plan)}
              className={cn(
                "card p-6 cursor-pointer transition-all hover:border-primary-base/50",
                selectedPlan?.id === plan.id ? "border-primary-base ring-1 ring-primary-base" : ""
              )}
            >
              <div className="flex items-center justify-between mb-4">
                <div className="flex items-center gap-4">
                  <div className={cn(
                    "p-3 rounded-xl",
                    // For team students: colour by TL status; for solo students: by supervisor status
                    teamChannelMessage
                      ? plan.tlStatus === "APPROVED"
                        ? "bg-emerald-50 text-emerald-600 dark:bg-emerald-900/30 dark:text-emerald-300"
                        : plan.tlStatus === "REVISION_REQUESTED"
                        ? "bg-orange-50 text-orange-600 dark:bg-orange-900/30 dark:text-orange-300"
                        : "bg-amber-50 text-amber-600 dark:bg-amber-900/30 dark:text-amber-300"
                      : plan.status === 'Approved' ? "bg-green-50 text-green-600 dark:bg-green-900/30 dark:text-green-300" : 
                        plan.status === 'Rejected' ? "bg-red-50 text-red-600 dark:bg-red-900/30 dark:text-red-300" : "bg-yellow-50 text-yellow-600 dark:bg-yellow-900/30 dark:text-yellow-300"
                  )}>
                    {teamChannelMessage
                      ? plan.tlStatus === "APPROVED"
                        ? <CheckCircle2 className="w-5 h-5" />
                        : plan.tlStatus === "REVISION_REQUESTED"
                        ? <XCircle className="w-5 h-5" />
                        : <Clock className="w-5 h-5" />
                      : plan.status === 'Approved' ? <CheckCircle2 className="w-5 h-5" /> : 
                        plan.status === 'Rejected' ? <XCircle className="w-5 h-5" /> : <Clock className="w-5 h-5" />}
                  </div>
                  <div>
                    <h3 className="font-bold text-lg">Week {plan.weekNumber}</h3>
                    <p className="text-xs text-text-muted">
                      Version {plan.version} • Submitted {new Date(plan.submittedAt).toLocaleDateString()}
                    </p>
                    {profile?.supervisorName && !teamChannelMessage && (
                      <p className="mt-1 text-xs text-text-muted">
                        Supervisor:{' '}
                        <span className="font-medium text-text-body">{profile.supervisorName}</span>
                      </p>
                    )}
                  </div>
                </div>
                <div className="flex shrink-0 flex-col items-end gap-2 sm:flex-row sm:items-center">
                  {plan.status === 'Pending' && !teamChannelMessage && (
                    <button
                      type="button"
                      onClick={(e) => {
                        e.stopPropagation();
                        setReviseFromPlan(null);
                        setEditPendingPlan(plan);
                        setFormData({
                          weekNumber: plan.weekNumber,
                          tasks: plan.tasks,
                          presentation: null,
                        });
                        setShowSubmitForm(true);
                      }}
                      className="inline-flex items-center gap-1.5 rounded-lg border border-primary-200 bg-primary-light/50 px-3 py-1.5 text-xs font-semibold text-primary-700 transition-colors hover:bg-primary-light"
                    >
                      <Pencil className="h-3.5 w-3.5" />
                      Edit
                    </button>
                  )}
                  {/* Team student: TL status is the primary badge; solo student: supervisor status */}
                  {teamChannelMessage ? (
                    <span className={cn(
                      "px-3 py-1 rounded-full text-xs font-bold uppercase tracking-wider",
                      plan.tlStatus === "APPROVED"
                        ? "bg-emerald-100 text-emerald-700 dark:bg-emerald-900/30 dark:text-emerald-300"
                        : plan.tlStatus === "REVISION_REQUESTED"
                        ? "bg-orange-100 text-orange-700 dark:bg-orange-900/30 dark:text-orange-300"
                        : "bg-amber-100 text-amber-700 dark:bg-amber-900/30 dark:text-amber-300"
                    )}>
                      👑 {plan.tlStatus === "APPROVED" ? "TL Approved" : plan.tlStatus === "REVISION_REQUESTED" ? "TL: Revise" : "Awaiting TL"}
                    </span>
                  ) : (
                    <>
                      <span className={cn(
                        "px-3 py-1 rounded-full text-xs font-bold uppercase tracking-wider",
                        plan.status === 'Approved' ? "bg-green-100 text-green-700" : 
                        plan.status === 'Rejected' ? "bg-red-100 text-red-700" : "bg-yellow-100 text-yellow-700"
                      )}>
                        {plan.status}
                      </span>
                      {plan.tlStatus && plan.tlStatus !== "PENDING" && (
                        <span className={cn(
                          "px-2.5 py-0.5 rounded-full text-[10px] font-bold uppercase tracking-wider",
                          plan.tlStatus === "APPROVED"
                            ? "bg-emerald-100 text-emerald-700 dark:bg-emerald-900/30 dark:text-emerald-300"
                            : "bg-orange-100 text-orange-700 dark:bg-orange-900/30 dark:text-orange-300"
                        )}>
                          👑 {plan.tlStatus === "APPROVED" ? "TL ✓" : "TL: Revise"}
                        </span>
                      )}
                    </>
                  )}
                </div>
              </div>
              <p className="text-sm text-text-body line-clamp-2">{plan.tasks}</p>
            </div>
          ))}
        </div>

        {/* Plan Details / Feedback */}
        <div className="space-y-6">
          <AnimatePresence mode="wait">
            {selectedPlan ? (
              <motion.div 
                key={selectedPlan.id}
                initial={{ opacity: 0, x: 20 }}
                animate={{ opacity: 1, x: 0 }}
                exit={{ opacity: 0, x: 20 }}
              className="card p-6 sticky top-24"
              >
                <h3 className="text-lg font-bold mb-6 flex items-center gap-2">
                  <FileText className="w-5 h-5 text-primary-base" />
                  Week {selectedPlan.weekNumber} Details
                </h3>
                
                <div className="space-y-6">
                  {profile?.supervisorName && !teamChannelMessage && (
                <div className="rounded-xl border border-border-default bg-bg-secondary/60 px-4 py-3">
                      <p className="text-xs font-bold uppercase tracking-tight text-text-muted">Assigned supervisor</p>
                      <p className="text-sm font-semibold text-text-heading">{profile.supervisorName}</p>
                      {profile.supervisorEmail && (
                        <p className="mt-0.5 text-xs text-text-muted">{profile.supervisorEmail}</p>
                      )}
                    </div>
                  )}

                  <div>
                    <p className="text-xs text-text-muted uppercase font-bold tracking-tight mb-2">Tasks Planned</p>
                    <p className="text-sm leading-relaxed text-text-body bg-bg-secondary p-4 rounded-xl border border-border-default">
                      {selectedPlan.tasks}
                    </p>
                  </div>

                  {/* Team student: show daily submissions with TL review status */}
                  {teamChannelMessage && selectedPlan.tlStatus === "APPROVED" && (
                    <div className="rounded-xl border border-border-default bg-bg-secondary/40 px-4 py-3">
                      <p className="mb-1 text-xs font-bold uppercase tracking-tight text-text-muted">Daily Plans</p>
                      <p className="mb-3 text-xs text-text-muted">
                        Submit your daily plans below. Your Team Leader reviews each one.
                      </p>
                      <div className="space-y-2">
                        {getCalendarWeekWorkdays(selectedPlan.submittedAt).map((ymd) => {
                          const sub = selectedPlan.daySubmissions?.find((d) => d.workDate === ymd);
                          const busy = dayToggleBusy === `${selectedPlan.id}-${ymd}`;
                          const tlStatus = sub?.tl_status;
                          const tlComment = sub?.tl_comment;
                          return (
                            <div key={ymd} className={cn(
                              "rounded-lg border px-3 py-2.5 transition-colors",
                              tlStatus === "APPROVED"
                                ? "border-emerald-200 bg-emerald-50 dark:border-emerald-800 dark:bg-emerald-900/20"
                                : tlStatus === "REVISION_REQUESTED"
                                ? "border-orange-200 bg-orange-50 dark:border-orange-800 dark:bg-orange-900/20"
                                : sub
                                ? "border-amber-200 bg-amber-50 dark:border-amber-800 dark:bg-amber-900/20"
                                : "border-border-default bg-white dark:bg-slate-900"
                            )}>
                              <div className="flex items-center justify-between gap-2">
                                <div className="flex items-center gap-2 min-w-0">
                                  <div className="text-left">
                                    <span className="block text-[10px] uppercase text-text-muted">
                                      {new Date(`${ymd}T12:00:00.000Z`).toLocaleDateString(undefined, { weekday: 'short' })}
                                    </span>
                                    <span className="text-xs font-semibold text-text-heading">{ymd.slice(5)}</span>
                                  </div>
                                  {tlStatus === "APPROVED" && (
                                    <span className="inline-flex items-center gap-1 rounded-full bg-emerald-100 px-2 py-0.5 text-[10px] font-bold text-emerald-700 dark:bg-emerald-900/30 dark:text-emerald-300">
                                      <CheckCircle2 className="h-3 w-3" /> TL Approved
                                    </span>
                                  )}
                                  {tlStatus === "REVISION_REQUESTED" && (
                                    <span className="inline-flex items-center gap-1 rounded-full bg-orange-100 px-2 py-0.5 text-[10px] font-bold text-orange-700 dark:bg-orange-900/30 dark:text-orange-300">
                                      <XCircle className="h-3 w-3" /> Revise
                                    </span>
                                  )}
                                  {sub && !tlStatus && (
                                    <span className="inline-flex items-center gap-1 rounded-full bg-amber-100 px-2 py-0.5 text-[10px] font-bold text-amber-700 dark:bg-amber-900/30 dark:text-amber-300">
                                      <Clock className="h-3 w-3" /> Awaiting TL
                                    </span>
                                  )}
                                </div>
                                <button
                                  type="button"
                                  onClick={(e) => {
                                    e.stopPropagation();
                                    if (!sub) {
                                      // No submission yet — open edit modal to write notes then submit
                                      setEditingDay(`${selectedPlan.id}-${ymd}`);
                                      setEditingDayNotes("");
                                    } else if (tlStatus !== "APPROVED") {
                                      // Has submission, not yet approved — open edit
                                      setEditingDay(`${selectedPlan.id}-${ymd}`);
                                      setEditingDayNotes(sub.notes ?? "");
                                    }
                                  }}
                                  disabled={tlStatus === "APPROVED" || !!savingDay}
                                  className={cn(
                                    'inline-flex items-center gap-1 rounded-lg border px-2.5 py-1 text-[10px] font-bold transition-colors',
                                    tlStatus === "APPROVED"
                                      ? 'border-emerald-300 bg-emerald-100 text-emerald-700 cursor-not-allowed dark:border-emerald-700 dark:bg-emerald-900/30 dark:text-emerald-300'
                                      : sub
                                      ? 'border-primary-200 bg-primary-50 text-primary-700 hover:bg-primary-100 dark:border-primary-800 dark:bg-primary-900/20 dark:text-primary-300'
                                      : 'border-primary-200 bg-primary-50 text-primary-700 hover:bg-primary-100 dark:border-primary-800 dark:bg-primary-900/20 dark:text-primary-300',
                                    busy && 'opacity-60',
                                  )}
                                >
                                  {tlStatus === "APPROVED"
                                    ? "✓ Done"
                                    : sub
                                    ? <><Pencil className="h-3 w-3" /> Edit</>
                                    : "+ Submit"}
                                </button>
                              </div>

                              {/* Inline edit form */}
                              {editingDay === `${selectedPlan.id}-${ymd}` && (
                                <div className="mt-2 space-y-2" onClick={(e) => e.stopPropagation()}>
                                  <textarea
                                    value={editingDayNotes}
                                    onChange={(e) => setEditingDayNotes(e.target.value)}
                                    rows={3}
                                    placeholder="Describe what you worked on today…"
                                    className="w-full rounded-lg border border-slate-200 dark:border-slate-700 bg-white dark:bg-slate-900 px-3 py-2 text-xs text-slate-900 dark:text-slate-100 focus:outline-none focus:ring-2 focus:ring-primary-500/20 resize-none"
                                    autoFocus
                                  />
                                  <div className="flex gap-2">
                                    <button
                                      type="button"
                                      onClick={() => { setEditingDay(null); setEditingDayNotes(""); }}
                                      className="flex-1 rounded-lg border border-slate-200 dark:border-slate-700 py-1.5 text-[10px] font-bold text-slate-600 dark:text-slate-300 hover:bg-slate-50 dark:hover:bg-slate-800 transition-colors"
                                    >
                                      Cancel
                                    </button>
                                    <button
                                      type="button"
                                      disabled={savingDay === `${selectedPlan.id}-${ymd}` || dayToggleBusy === `${selectedPlan.id}-${ymd}`}
                                      onClick={(e) => {
                                        e.stopPropagation();
                                        void saveDayEdit(selectedPlan.id, ymd, editingDayNotes, !sub);
                                      }}
                                      className="flex-1 rounded-lg bg-primary-600 py-1.5 text-[10px] font-bold text-white hover:bg-primary-700 disabled:opacity-60 transition-colors"
                                    >
                                      {savingDay === `${selectedPlan.id}-${ymd}` ? "Saving…" : sub ? "Save & Resubmit" : "Submit"}
                                    </button>
                                  </div>
                                </div>
                              )}

                              {/* TL revision comment */}
                              {tlStatus === "REVISION_REQUESTED" && tlComment && editingDay !== `${selectedPlan.id}-${ymd}` && (
                                <div className="mt-2 rounded-lg border border-orange-200 bg-white dark:border-orange-800 dark:bg-slate-900 px-3 py-2">
                                  <p className="text-[10px] font-bold uppercase tracking-wide text-orange-600 dark:text-orange-400 mb-0.5">👑 TL Comment</p>
                                  <p className="text-xs text-orange-900 dark:text-orange-200 leading-relaxed">{tlComment}</p>
                                </div>
                              )}
                            </div>
                          );
                        })}
                      </div>
                    </div>
                  )}

                  {/* Team student: weekly plan not yet TL-approved — daily plans locked */}
                  {teamChannelMessage && selectedPlan.tlStatus !== "APPROVED" && (
                    <div className="rounded-xl border border-border-default bg-bg-secondary/40 px-4 py-3">
                      <p className="mb-1 text-xs font-bold uppercase tracking-tight text-text-muted">Daily Plans</p>
                      <p className="text-xs text-text-muted leading-relaxed">
                        Daily plans unlock after your Team Leader approves your weekly plan.
                      </p>
                    </div>
                  )}

                  {selectedPlan.presentationUrl && (
                    <div>
                      <p className="text-xs text-text-muted uppercase font-bold tracking-tight mb-2">Presentation</p>
                      <Link 
                        href={getViewerUrl(selectedPlan.presentationUrl)} 
                        className="flex items-center justify-between p-3 rounded-xl border border-border-default hover:bg-bg-tertiary transition-all group"
                      >
                        <div className="flex items-center gap-3 min-w-0">
                          <FileText className="w-5 h-5 shrink-0 text-text-muted group-hover:text-primary-base" />
                          <span className="text-sm font-medium truncate">
                            {selectedPlan.presentationFileName ?? 'Weekly_Presentation.pdf'}
                          </span>
                        </div>
                        <ExternalLink className="w-4 h-4 shrink-0 text-text-muted group-hover:text-primary-base" />
                      </Link>
                    </div>
                  )}

                  {/* Supervisor feedback — only shown for solo students (team students don't get individual supervisor review) */}
                  {selectedPlan.feedback && !teamChannelMessage && (
                    <div className={cn(
                      "p-4 rounded-xl border",
                      selectedPlan.status === 'Approved' ? "bg-green-50 border-green-100 dark:bg-green-900/20 dark:border-green-900/50" : "bg-red-50 border-red-100 dark:bg-red-900/20 dark:border-red-900/50"
                    )}>
                      <p className="text-xs text-text-muted uppercase font-bold tracking-tight mb-2">Supervisor Feedback</p>
                      <p className={cn(
                        "text-sm font-medium",
                        selectedPlan.status === 'Approved' ? "text-green-900 dark:text-green-200" : "text-red-900 dark:text-red-200"
                      )}>
                        {selectedPlan.feedback}
                      </p>
                    </div>
                  )}

                  {/* Team Leader feedback */}
                  {selectedPlan.tlStatus && selectedPlan.tlStatus !== "PENDING" && (
                    <div className={cn(
                      "p-4 rounded-xl border",
                      selectedPlan.tlStatus === "APPROVED"
                        ? "bg-emerald-50 border-emerald-100 dark:bg-emerald-900/20 dark:border-emerald-900/50"
                        : "bg-orange-50 border-orange-200 dark:bg-orange-900/20 dark:border-orange-900/50"
                    )}>
                      <p className="text-xs text-text-muted uppercase font-bold tracking-tight mb-2">
                        👑 Team Leader Review
                      </p>
                      <p className={cn(
                        "text-sm font-semibold mb-1",
                        selectedPlan.tlStatus === "APPROVED" ? "text-emerald-700 dark:text-emerald-300" : "text-orange-700 dark:text-orange-300"
                      )}>
                        {selectedPlan.tlStatus === "APPROVED" ? "✅ Approved by Team Leader" : "🔄 Revision Requested"}
                      </p>
                      {selectedPlan.tlComment && (
                        <p className="text-sm text-slate-700 dark:text-slate-300">{selectedPlan.tlComment}</p>
                      )}
                    </div>
                  )}

                  {/* Edit pending plan — only for solo students (team students edit via TL revision flow) */}
                  {selectedPlan.status === 'Pending' && !teamChannelMessage && (
                    <button
                      type="button"
                      onClick={(e) => {
                        e.stopPropagation();
                        setReviseFromPlan(null);
                        setEditPendingPlan(selectedPlan);
                        setFormData({
                          weekNumber: selectedPlan.weekNumber,
                          tasks: selectedPlan.tasks,
                          presentation: null,
                        });
                        setShowSubmitForm(true);
                      }}
                      className="w-full btn-primary flex items-center justify-center gap-2"
                    >
                      <Pencil className="w-5 h-5" />
                      Edit submission
                    </button>
                  )}

                  {/* Supervisor rejected — only for solo students */}
                  {selectedPlan.status === 'Rejected' && !teamChannelMessage && (
                    <button
                      type="button"
                      onClick={(e) => {
                        e.stopPropagation();
                        setEditPendingPlan(null);
                        setReviseFromPlan(selectedPlan);
                        setFormData({
                          weekNumber: selectedPlan.weekNumber,
                          tasks: selectedPlan.tasks,
                          presentation: null,
                        });
                        setShowSubmitForm(true);
                      }}
                      className="w-full btn-primary flex items-center justify-center gap-2"
                    >
                      <History className="w-5 h-5" />
                      Revise and Resubmit
                    </button>
                  )}

                  {/* TL requested revision — resubmit to Team Leader */}
                  {selectedPlan.tlStatus === 'REVISION_REQUESTED' && (
                    <button
                      type="button"
                      onClick={(e) => {
                        e.stopPropagation();
                        setEditPendingPlan(null);
                        setReviseFromPlan(selectedPlan);
                        setFormData({
                          weekNumber: selectedPlan.weekNumber,
                          tasks: selectedPlan.tasks,
                          presentation: null,
                        });
                        setShowSubmitForm(true);
                      }}
                      className="w-full inline-flex items-center justify-center gap-2 rounded-xl border-2 border-orange-400 bg-orange-50 px-5 py-3 text-sm font-semibold text-orange-700 hover:bg-orange-100 transition-colors dark:border-orange-600 dark:bg-orange-900/20 dark:text-orange-300"
                    >
                      <History className="w-5 h-5" />
                      Revise and Resubmit to Team Leader
                    </button>
                  )}

                  {/* Team Leader: delete plan (testing / reset) */}
                  {isTeamLeader && (
                    <button
                      type="button"
                      disabled={deletingPlan === selectedPlan.id}
                      onClick={(e) => {
                        e.stopPropagation();
                        setConfirmDeletePlan(selectedPlan);
                      }}
                      className="w-full inline-flex items-center justify-center gap-2 rounded-xl border-2 border-red-300 bg-red-50 px-5 py-3 text-sm font-semibold text-red-700 hover:bg-red-100 transition-colors dark:border-red-700 dark:bg-red-900/20 dark:text-red-300 disabled:opacity-60"
                    >
                      <Trash2 className="w-4 h-4" />
                      {deletingPlan === selectedPlan.id ? 'Deleting…' : 'Delete Plan'}
                    </button>
                  )}
                </div>
              </motion.div>
            ) : (
              <div className="card p-12 text-center flex flex-col items-center justify-center space-y-4 text-text-muted">
                <div className="p-4 bg-bg-secondary rounded-full">
                  <FileText className="w-8 h-8" />
                </div>
                <p className="text-sm font-medium">Select a plan to view details and feedback.</p>
              </div>
            )}
          </AnimatePresence>
        </div>
      </div>

      {/* Submit Form Modal */}
      <AnimatePresence>
        {showSubmitForm && (
          <motion.div
            role="presentation"
            initial={{ opacity: 0 }}
            animate={{ opacity: 1 }}
            exit={{ opacity: 0 }}
            transition={{ duration: 0.2 }}
            className="fixed inset-0 z-50 flex items-center justify-center p-4 sm:p-6"
          >
            <button
              type="button"
              aria-label="Close dialog"
              className="absolute inset-0 bg-slate-900/55 backdrop-blur-md transition-opacity"
              onClick={closeSubmitModal}
            />
            <motion.div
              role="dialog"
              aria-modal="true"
              aria-labelledby="weekly-plan-modal-title"
              initial={{ opacity: 0, scale: 0.96, y: 16 }}
              animate={{ opacity: 1, scale: 1, y: 0 }}
              exit={{ opacity: 0, scale: 0.96, y: 16 }}
              transition={{ type: 'spring', damping: 26, stiffness: 320 }}
              onClick={(e) => e.stopPropagation()}
              className="relative z-10 w-full max-w-xl overflow-hidden rounded-3xl border border-white/60 bg-bg-main shadow-[0_25px_50px_-12px_rgba(15,23,42,0.35)] ring-1 ring-slate-900/5 dark:border-slate-700"
            >
              <div className="relative overflow-hidden bg-gradient-to-br from-primary-50/90 via-white to-slate-50 px-6 pb-5 pt-6 sm:px-8 sm:pb-6 sm:pt-7 dark:from-primary-900/30 dark:via-slate-900 dark:to-slate-950">
                <div
                  className="pointer-events-none absolute -right-10 -top-10 h-36 w-36 rounded-full bg-primary-300/35 blur-3xl"
                  aria-hidden
                />
                <div
                  className="pointer-events-none absolute -bottom-8 left-1/3 h-24 w-40 rounded-full bg-teal-200/30 blur-2xl"
                  aria-hidden
                />
                <div className="relative flex items-start justify-between gap-4">
                  <div className="space-y-3">
                    <p className="inline-flex items-center gap-2 rounded-full bg-white/90 px-3 py-1 text-[11px] font-semibold uppercase tracking-wider text-primary-700 shadow-sm ring-1 ring-primary-100 sm:text-xs">
                      <Sparkles className="h-3.5 w-3.5 shrink-0" />
                      {reviseFromPlan ? 'New version' : editPendingPlan ? 'Pending review' : 'Weekly submission'}
                    </p>
                    <h2
                      id="weekly-plan-modal-title"
                      className="text-xl font-bold tracking-tight text-slate-900 sm:text-2xl"
                    >
                      {reviseFromPlan
                        ? 'Revise & resubmit plan'
                        : editPendingPlan
                          ? 'Edit weekly plan'
                          : 'Submit weekly plan'}
                    </h2>
                    <p className="max-w-md text-sm leading-relaxed text-slate-600">
                      {reviseFromPlan
                        ? `You’re submitting v${reviseFromPlan.version + 1} for Week ${reviseFromPlan.weekNumber}. Update your tasks, then send for review.`
                        : editPendingPlan
                          ? 'Update your tasks or presentation while your plan is still awaiting supervisor approval.'
                          : teamChannelMessage
                            ? 'Outline what you will focus on this week. Your Team Leader reviews it first; after the team weekly plan is forwarded, your supervisor will review as usual.'
                            : 'Outline what you’ll focus on this week. Your supervisor will review and may leave feedback.'}
                    </p>
                  </div>
                  <button
                    type="button"
                    onClick={closeSubmitModal}
                    className="shrink-0 rounded-xl border border-border-default bg-white/80 p-2 text-slate-500 shadow-sm transition-all hover:bg-white hover:text-slate-800 hover:shadow-md active:scale-95 dark:bg-slate-900 dark:text-slate-400 dark:hover:bg-slate-800 dark:hover:text-slate-100"
                  >
                    <X className="h-5 w-5" />
                  </button>
                </div>
              </div>

              <form onSubmit={(e) => { e.preventDefault(); setConfirmSubmit(e); }} className="space-y-5 px-6 py-6 sm:px-8 sm:pb-8">
                <div className="space-y-2">
                  <label className="flex items-center gap-2 text-sm font-semibold text-slate-700 dark:text-slate-200">
                    <Calendar className="h-4 w-4 text-primary-600" />
                    Week number
                    {!reviseFromPlan && !editPendingPlan && (
                      <span className="ml-auto text-xs font-normal text-slate-400">Auto-assigned</span>
                    )}
                  </label>
                  <div className="relative">
                    <span className="pointer-events-none absolute left-3 top-1/2 flex h-8 w-8 -translate-y-1/2 items-center justify-center rounded-lg bg-slate-100 text-xs font-bold text-slate-500">
                      W
                    </span>
                    <input
                      type="number"
                      min={1}
                      className={cn(
                        'input-field w-full rounded-xl border-border-default py-3 pl-14 text-base font-semibold text-slate-900 transition-shadow dark:text-slate-100 cursor-not-allowed bg-slate-50 text-slate-600 dark:bg-slate-800 dark:text-slate-300'
                      )}
                      value={formData.weekNumber}
                      readOnly
                    />
                  </div>
                </div>

                <div className="space-y-2">
                  <label className="flex items-center gap-2 text-sm font-semibold text-slate-700 dark:text-slate-200">
                    <ClipboardList className="h-4 w-4 text-primary-600" />
                    Planned tasks
                  </label>
                  <textarea
                    className="input-field min-h-[160px] w-full resize-y rounded-xl border-border-default bg-white text-sm leading-relaxed text-slate-800 placeholder:text-slate-400 focus:border-primary-300 focus:ring-2 focus:ring-primary-200"
                    placeholder="e.g. Finish API integration, attend team sync, document test cases…"
                    value={formData.tasks}
                    onChange={(e) => setFormData({ ...formData, tasks: e.target.value })}
                    required
                  />
                  <p className="text-xs text-slate-500 dark:text-slate-400">Be specific — it helps your supervisor give useful feedback.</p>
                </div>

                <div className="space-y-2">
                  <label className="flex items-center gap-2 text-sm font-semibold text-slate-700 dark:text-slate-200">
                    <Upload className="h-4 w-4 text-primary-600" />
                    Presentation <span className="font-normal text-slate-400">(optional)</span>
                  </label>
                  <input
                    ref={presentationInputRef}
                    type="file"
                    accept=".pdf,.ppt,.pptx,application/pdf"
                    className="sr-only"
                    onChange={(e) =>
                      setFormData({
                        ...formData,
                        presentation: e.target.files?.[0] ?? null,
                      })
                    }
                  />
                  <button
                    type="button"
                    onClick={() => presentationInputRef.current?.click()}
                    className={cn(
                      'group relative w-full overflow-hidden rounded-2xl border-2 border-dashed border-slate-200 bg-gradient-to-b from-slate-50/80 to-white p-6 text-center transition-all duration-200 dark:border-slate-700 dark:from-slate-800 dark:to-slate-900',
                      'hover:border-primary-300 hover:shadow-md hover:shadow-primary-900/5 focus:outline-none focus:ring-2 focus:ring-primary-200'
                    )}
                  >
                    <div className="mx-auto mb-2 flex h-12 w-12 items-center justify-center rounded-2xl bg-primary-100 text-primary-600 transition-transform group-hover:scale-105 group-hover:bg-primary-200/80">
                      <Upload className="h-6 w-6" />
                    </div>
                    <p className="text-sm font-semibold text-slate-800 dark:text-slate-100">Drop a file or click to browse</p>
                    <p className="mt-1 text-xs text-slate-500 dark:text-slate-400">PDF or PowerPoint — up to ~10MB</p>
                    {editPendingPlan && editPendingPlan.presentationFileName && !formData.presentation && (
                      <p className="mt-2 text-xs text-slate-500">
                        Current file:{' '}
                        <span className="font-medium text-slate-700">{editPendingPlan.presentationFileName}</span>
                        {' — '}
                        choose a new file to replace it.
                      </p>
                    )}
                    {formData.presentation && (
                      <p className="mt-3 inline-flex max-w-full items-center gap-2 truncate rounded-lg bg-primary-50 px-3 py-1.5 text-xs font-medium text-primary-800 ring-1 ring-primary-100">
                        <FileText className="h-3.5 w-3.5 shrink-0" />
                        <span className="truncate">{formData.presentation.name}</span>
                      </p>
                    )}
                  </button>
                </div>

                <div className="flex flex-col-reverse gap-3 border-t border-border-default pt-6 sm:flex-row sm:justify-end">
                  <button
                    type="button"
                    onClick={closeSubmitModal}
                    className="rounded-xl border border-border-default px-5 py-3 text-sm font-semibold text-slate-700 transition-colors hover:bg-slate-50 active:scale-[0.99] sm:min-w-[120px]"
                  >
                    Cancel
                  </button>
                  <button
                    type="submit"
                    disabled={submitting}
                    className="btn-primary flex flex-1 items-center justify-center gap-2 rounded-xl px-6 py-3.5 text-sm shadow-lg shadow-primary-900/15 transition-transform hover:shadow-xl active:scale-[0.99] disabled:opacity-60 sm:flex-initial sm:min-w-[200px]"
                  >
                    <Send className="h-4 w-4" />
                    {editPendingPlan
                      ? 'Save changes'
                      : reviseFromPlan
                        ? 'Submit revised plan'
                        : 'Submit plan'}
                  </button>
                </div>
              </form>
            </motion.div>
          </motion.div>
        )}
      </AnimatePresence>

      <ConfirmDialog
        open={confirmSubmit !== null}
        title={
          editPendingPlan
            ? "Update plan?"
            : reviseFromPlan
              ? reviseFromPlan.status === "Rejected"
                ? "Resubmit revised plan?"
                : "Send update to Team Leader?"
              : "Submit weekly plan?"
        }
        message={
          editPendingPlan
            ? "Your changes will be saved and sent to your supervisor for review."
            : reviseFromPlan
              ? reviseFromPlan.status === "Rejected"
                ? "Your supervisor will be notified to review this new version."
                : "Your Team Leader will be notified to review your updated week plan."
              : teamChannelMessage
                ? `You are submitting Week ${formData.weekNumber} for Team Leader review first, then your supervisor.`
                : `You're submitting Week ${formData.weekNumber} plan. Your supervisor will be notified to review it.`
        }
        confirmLabel={editPendingPlan ? "Save changes" : "Submit plan"}
        variant="confirm"
        loading={submitting}
        onConfirm={() => {
          if (confirmSubmit) {
            setConfirmSubmit(null);
            void handleSubmit(confirmSubmit);
          }
        }}
        onCancel={() => setConfirmSubmit(null)}
      />

      <SuccessToast
        show={toast.show}
        message={toast.message}
        onClose={() => setToast({ show: false, message: "" })}
      />

      <ConfirmDialog
        open={confirmDeletePlan !== null}
        title="Delete weekly plan?"
        message={`This will permanently delete Week ${confirmDeletePlan?.weekNumber} plan and all its daily submissions for this student. This cannot be undone.`}
        confirmLabel="Delete"
        variant="danger"
        loading={deletingPlan !== null}
        onConfirm={() => {
          if (confirmDeletePlan) {
            const id = confirmDeletePlan.id;
            setConfirmDeletePlan(null);
            void deleteWeeklyPlan(id);
          }
        }}
        onCancel={() => setConfirmDeletePlan(null)}
      />
    </div>
  );
};

export default WeeklyPlans;
