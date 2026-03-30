"use client";

import React, { useEffect, useState } from 'react';
import { 
  Plus, 
  FileText, 
  Upload, 
  CheckCircle2, 
  XCircle, 
  Clock, 
  ChevronRight,
  AlertCircle,
  History,
  ExternalLink
} from 'lucide-react';
import { MOCK_WEEKLY_PLANS } from '@/lib/superadmin/mockData';
import { WeeklyPlan } from '@/lib/superadmin/types';
import { cn } from '@/lib/utils';
import { motion, AnimatePresence } from 'framer-motion';
import { STUDENT_WEEKLY_PLANS_EVENT } from '@/lib/student/planNotificationEvents';

const WeeklyPlans = () => {
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

  const closeSubmitModal = () => {
    setShowSubmitForm(false);
    setReviseFromPlan(null);
  };

  useEffect(() => {
    window.dispatchEvent(
      new CustomEvent(STUDENT_WEEKLY_PLANS_EVENT, { detail: { plans } })
    );
  }, [plans]);

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
      <header className="flex flex-col md:flex-row md:items-center justify-between gap-4">
        <div>
          <h1 className="text-3xl font-bold mb-2">Weekly Plans</h1>
          <p className="text-text-muted">Submit your weekly tasks and track supervisor feedback.</p>
        </div>
        <button 
          onClick={() => {
            setReviseFromPlan(null);
            setShowSubmitForm(true);
          }}
          className="btn-primary flex items-center gap-2"
        >
          <Plus className="w-5 h-5" />
          Submit New Plan
        </button>
      </header>

      <div className="grid grid-cols-1 lg:grid-cols-3 gap-8">
        {/* Plans List */}
        <div className="lg:col-span-2 space-y-4">
          {plans.slice().reverse().map((plan) => (
            <div 
              key={plan.id} 
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
          <div className="fixed inset-0 z-50 flex items-center justify-center p-4 bg-black/50 backdrop-blur-sm">
            <motion.div 
              initial={{ opacity: 0, scale: 0.95, y: 20 }}
              animate={{ opacity: 1, scale: 1, y: 0 }}
              exit={{ opacity: 0, scale: 0.95, y: 20 }}
              className="bg-bg-main rounded-2xl shadow-2xl w-full max-w-lg overflow-hidden"
            >
              <header className="p-6 border-b border-border-default flex items-center justify-between">
                <h2 className="text-xl font-bold">
                  {reviseFromPlan ? 'Revise & resubmit plan' : 'Submit Weekly Plan'}
                </h2>
                <button onClick={closeSubmitModal} className="p-2 hover:bg-bg-tertiary rounded-full transition-colors">
                  <XCircle className="w-6 h-6 text-text-muted" />
                </button>
              </header>

              <form onSubmit={handleSubmit} className="p-6 space-y-6">
                {reviseFromPlan && (
                  <p className="text-sm text-text-muted">
                    Submitting a new version (v{reviseFromPlan.version + 1}) for Week {reviseFromPlan.weekNumber}. Update your tasks below, then submit.
                  </p>
                )}

                <div className="space-y-2">
                  <label className="text-sm font-bold text-text-muted">Week Number</label>
                  <input 
                    type="number" 
                    className="input-field w-full"
                    value={formData.weekNumber}
                    readOnly={!!reviseFromPlan}
                    onChange={(e) => setFormData({ ...formData, weekNumber: parseInt(e.target.value, 10) })}
                  />
                </div>

                <div className="space-y-2">
                  <label className="text-sm font-bold text-text-muted">Planned Tasks</label>
                  <textarea 
                    className="input-field w-full min-h-[150px] text-sm"
                    placeholder="Describe your planned tasks for the upcoming week..."
                    value={formData.tasks}
                    onChange={(e) => setFormData({ ...formData, tasks: e.target.value })}
                    required
                  />
                </div>

                <div className="space-y-2">
                  <label className="text-sm font-bold text-text-muted">Presentation (Optional)</label>
                  <div className="border-2 border-dashed border-border-default rounded-xl p-8 text-center hover:border-primary-base transition-all cursor-pointer bg-bg-secondary group">
                    <Upload className="w-8 h-8 text-text-muted mx-auto mb-2 group-hover:text-primary-base transition-all" />
                    <p className="text-sm font-medium text-text-body">Click to upload or drag and drop</p>
                    <p className="text-xs text-text-muted mt-1">PDF, PPT, PPTX (Max 10MB)</p>
                  </div>
                </div>

                <div className="flex gap-3 pt-4">
                  <button type="submit" className="flex-1 btn-primary">
                    {reviseFromPlan ? 'Submit revised plan' : 'Submit Plan'}
                  </button>
                  <button 
                    type="button" 
                    onClick={closeSubmitModal}
                    className="px-6 py-2 border border-border-default rounded-lg hover:bg-bg-tertiary transition-colors"
                  >
                    Cancel
                  </button>
                </div>
              </form>
            </motion.div>
          </div>
        )}
      </AnimatePresence>
    </div>
  );
};

export default WeeklyPlans;
