"use client";

import React, { useEffect, useRef, useState } from 'react';
import { useRouter, useSearchParams } from 'next/navigation';
import { 
  Plus, 
  FileText, 
  Upload, 
  CheckCircle2, 
  XCircle, 
  Clock, 
  ChevronRight,
  History,
  ExternalLink,
  X,
  Sparkles,
  Calendar,
  ClipboardList,
  Send,
} from 'lucide-react';
import { MOCK_WEEKLY_PLANS } from '@/lib/superadmin/mockData';
import { WeeklyPlan } from '@/lib/superadmin/types';
import { cn } from '@/lib/utils';
import { motion, AnimatePresence } from 'framer-motion';
import { STUDENT_WEEKLY_PLANS_EVENT } from '@/lib/student/planNotificationEvents';
import StudentPageHero from './StudentPageHero';

const WeeklyPlans = () => {
  const router = useRouter();
  const searchParams = useSearchParams();
  const [plans, setPlans] = useState<WeeklyPlan[]>(MOCK_WEEKLY_PLANS);
  const [showSubmitForm, setShowSubmitForm] = useState(false);
  const [selectedPlan, setSelectedPlan] = useState<WeeklyPlan | null>(null);
  /** When set, the modal is revising this rejected plan (new version on submit). */
  const [reviseFromPlan, setReviseFromPlan] = useState<WeeklyPlan | null>(null);

  const [formData, setFormData] = useState({
    weekNumber: plans.length + 1,
    tasks: '',
    presentation: null as File | null,
  });
  const presentationInputRef = useRef<HTMLInputElement>(null);

  const closeSubmitModal = () => {
    setShowSubmitForm(false);
    setReviseFromPlan(null);
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

  const handleSubmit = (e: React.FormEvent) => {
    e.preventDefault();
    if (reviseFromPlan) {
      const newPlan: WeeklyPlan = {
        id: `w${formData.weekNumber}-v${reviseFromPlan.version + 1}-${Date.now()}`,
        weekNumber: formData.weekNumber,
        tasks: formData.tasks,
        status: 'Pending',
        submittedAt: new Date().toISOString(),
        version: reviseFromPlan.version + 1,
      };
      setPlans((prev) => [...prev, newPlan]);
      setShowSubmitForm(false);
      setReviseFromPlan(null);
      setSelectedPlan(newPlan);
      setFormData((prev) => ({
        weekNumber: prev.weekNumber,
        tasks: '',
        presentation: null,
      }));
      return;
    }
    const newPlan: WeeklyPlan = {
      id: `w${formData.weekNumber}-${Date.now()}`,
      weekNumber: formData.weekNumber,
      tasks: formData.tasks,
      status: 'Pending',
      submittedAt: new Date().toISOString(),
      version: 1,
    };
    setPlans([...plans, newPlan]);
    setShowSubmitForm(false);
    setFormData({ weekNumber: plans.length + 2, tasks: '', presentation: null });
  };

  return (
    <div className="space-y-8 animate-in fade-in duration-500">
      <StudentPageHero
        badge="Weekly plans"
        title="Weekly Plans"
        description="Submit your weekly tasks and track supervisor feedback."
        action={
          <button
            type="button"
            onClick={() => {
              setReviseFromPlan(null);
              setShowSubmitForm(true);
            }}
            className="btn-primary flex w-full items-center justify-center gap-2 sm:w-auto"
          >
            <Plus className="h-5 w-5" />
            Submit New Plan
          </button>
        }
      />

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
                    plan.status === 'Approved' ? "bg-green-50 text-green-600" : 
                    plan.status === 'Rejected' ? "bg-red-50 text-red-600" : "bg-yellow-50 text-yellow-600"
                  )}>
                    {plan.status === 'Approved' ? <CheckCircle2 className="w-5 h-5" /> : 
                     plan.status === 'Rejected' ? <XCircle className="w-5 h-5" /> : <Clock className="w-5 h-5" />}
                  </div>
                  <div>
                    <h3 className="font-bold text-lg">Week {plan.weekNumber}</h3>
                    <p className="text-xs text-text-muted">Version {plan.version} • Submitted {new Date(plan.submittedAt).toLocaleDateString()}</p>
                  </div>
                </div>
                <span className={cn(
                  "px-3 py-1 rounded-full text-xs font-bold uppercase tracking-wider",
                  plan.status === 'Approved' ? "bg-green-100 text-green-700" : 
                  plan.status === 'Rejected' ? "bg-red-100 text-red-700" : "bg-yellow-100 text-yellow-700"
                )}>
                  {plan.status}
                </span>
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
                  <div>
                    <p className="text-xs text-text-muted uppercase font-bold tracking-tight mb-2">Tasks Planned</p>
                    <p className="text-sm leading-relaxed text-text-body bg-bg-secondary p-4 rounded-xl border border-border-default">
                      {selectedPlan.tasks}
                    </p>
                  </div>

                  {selectedPlan.presentationUrl && (
                    <div>
                      <p className="text-xs text-text-muted uppercase font-bold tracking-tight mb-2">Presentation</p>
                      <a 
                        href={selectedPlan.presentationUrl} 
                        target="_blank" 
                        rel="noopener noreferrer"
                        className="flex items-center justify-between p-3 rounded-xl border border-border-default hover:bg-bg-tertiary transition-all group"
                      >
                        <div className="flex items-center gap-3">
                          <FileText className="w-5 h-5 text-text-muted group-hover:text-primary-base" />
                          <span className="text-sm font-medium">Weekly_Presentation.pdf</span>
                        </div>
                        <ExternalLink className="w-4 h-4 text-text-muted group-hover:text-primary-base" />
                      </a>
                    </div>
                  )}

                  {selectedPlan.feedback && (
                    <div className={cn(
                      "p-4 rounded-xl border",
                      selectedPlan.status === 'Approved' ? "bg-green-50 border-green-100" : "bg-red-50 border-red-100"
                    )}>
                      <p className="text-xs text-text-muted uppercase font-bold tracking-tight mb-2">Supervisor Feedback</p>
                      <p className={cn(
                        "text-sm font-medium",
                        selectedPlan.status === 'Approved' ? "text-green-900" : "text-red-900"
                      )}>
                        {selectedPlan.feedback}
                      </p>
                    </div>
                  )}

                  {selectedPlan.status === 'Rejected' && (
                    <button
                      type="button"
                      onClick={(e) => {
                        e.stopPropagation();
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
              className="relative z-10 w-full max-w-xl overflow-hidden rounded-3xl border border-white/60 bg-bg-main shadow-[0_25px_50px_-12px_rgba(15,23,42,0.35)] ring-1 ring-slate-900/5"
            >
              <div className="relative overflow-hidden bg-gradient-to-br from-primary-50/90 via-white to-slate-50 px-6 pb-5 pt-6 sm:px-8 sm:pb-6 sm:pt-7">
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
                      {reviseFromPlan ? 'New version' : 'Weekly submission'}
                    </p>
                    <h2
                      id="weekly-plan-modal-title"
                      className="text-xl font-bold tracking-tight text-slate-900 sm:text-2xl"
                    >
                      {reviseFromPlan ? 'Revise & resubmit plan' : 'Submit weekly plan'}
                    </h2>
                    <p className="max-w-md text-sm leading-relaxed text-slate-600">
                      {reviseFromPlan
                        ? `You’re submitting v${reviseFromPlan.version + 1} for Week ${reviseFromPlan.weekNumber}. Update your tasks, then send for review.`
                        : 'Outline what you’ll focus on this week. Your supervisor will review and may leave feedback.'}
                    </p>
                  </div>
                  <button
                    type="button"
                    onClick={closeSubmitModal}
                    className="shrink-0 rounded-xl border border-border-default bg-white/80 p-2 text-slate-500 shadow-sm transition-all hover:bg-white hover:text-slate-800 hover:shadow-md active:scale-95"
                  >
                    <X className="h-5 w-5" />
                  </button>
                </div>
              </div>

              <form onSubmit={handleSubmit} className="space-y-5 px-6 py-6 sm:px-8 sm:pb-8">
                <div className="space-y-2">
                  <label className="flex items-center gap-2 text-sm font-semibold text-slate-700">
                    <Calendar className="h-4 w-4 text-primary-600" />
                    Week number
                  </label>
                  <div className="relative">
                    <span className="pointer-events-none absolute left-3 top-1/2 flex h-8 w-8 -translate-y-1/2 items-center justify-center rounded-lg bg-slate-100 text-xs font-bold text-slate-500">
                      W
                    </span>
                    <input
                      type="number"
                      min={1}
                      className={cn(
                        'input-field w-full rounded-xl border-border-default py-3 pl-14 text-base font-semibold text-slate-900 transition-shadow focus:border-primary-300 focus:ring-2 focus:ring-primary-200',
                        reviseFromPlan && 'cursor-not-allowed bg-slate-50 text-slate-600'
                      )}
                      value={formData.weekNumber}
                      readOnly={!!reviseFromPlan}
                      onChange={(e) =>
                        setFormData({ ...formData, weekNumber: parseInt(e.target.value, 10) })
                      }
                    />
                  </div>
                </div>

                <div className="space-y-2">
                  <label className="flex items-center gap-2 text-sm font-semibold text-slate-700">
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
                  <p className="text-xs text-slate-500">Be specific — it helps your supervisor give useful feedback.</p>
                </div>

                <div className="space-y-2">
                  <label className="flex items-center gap-2 text-sm font-semibold text-slate-700">
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
                      'group relative w-full overflow-hidden rounded-2xl border-2 border-dashed border-slate-200 bg-gradient-to-b from-slate-50/80 to-white p-6 text-center transition-all duration-200',
                      'hover:border-primary-300 hover:shadow-md hover:shadow-primary-900/5 focus:outline-none focus:ring-2 focus:ring-primary-200'
                    )}
                  >
                    <div className="mx-auto mb-2 flex h-12 w-12 items-center justify-center rounded-2xl bg-primary-100 text-primary-600 transition-transform group-hover:scale-105 group-hover:bg-primary-200/80">
                      <Upload className="h-6 w-6" />
                    </div>
                    <p className="text-sm font-semibold text-slate-800">Drop a file or click to browse</p>
                    <p className="mt-1 text-xs text-slate-500">PDF or PowerPoint — up to ~10MB</p>
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
                    className="btn-primary flex flex-1 items-center justify-center gap-2 rounded-xl px-6 py-3.5 text-sm shadow-lg shadow-primary-900/15 transition-transform hover:shadow-xl active:scale-[0.99] sm:flex-initial sm:min-w-[200px]"
                  >
                    <Send className="h-4 w-4" />
                    {reviseFromPlan ? 'Submit revised plan' : 'Submit plan'}
                  </button>
                </div>
              </form>
            </motion.div>
          </motion.div>
        )}
      </AnimatePresence>
    </div>
  );
};

export default WeeklyPlans;
