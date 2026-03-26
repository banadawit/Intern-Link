'use client';

import React, { useState } from 'react';
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

const WeeklyPlans = () => {
  const [plans, setPlans] = useState<WeeklyPlan[]>(MOCK_WEEKLY_PLANS);
  const [showSubmitForm, setShowSubmitForm] = useState(false);
  const [selectedPlan, setSelectedPlan] = useState<WeeklyPlan | null>(null);

  const [formData, setFormData] = useState({
    weekNumber: plans.length + 1,
    tasks: '',
    presentation: null as File | null,
  });

  const handleSubmit = (e: React.FormEvent) => {
    e.preventDefault();
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
          <h1 className="text-3xl font-bold mb-2 text-slate-900">Weekly Plans</h1>
          <p className="text-slate-600">Submit your weekly tasks and track supervisor feedback.</p>
        </div>
        <button 
          onClick={() => setShowSubmitForm(true)}
          className="btn-primary flex items-center gap-2 bg-teal-600 hover:bg-teal-700 text-white font-medium py-2 px-4 rounded-lg transition-all"
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
                "card p-6 cursor-pointer transition-all hover:border-teal-600/50 bg-white border border-slate-200",
                selectedPlan?.id === plan.id ? "border-teal-600 ring-1 ring-teal-600" : ""
              )}
            >
              <div className="flex items-center justify-between mb-4">
                <div className="flex items-center gap-4">
                  <div className={cn(
                    "p-3 rounded-xl",
                    plan.status === 'Approved' ? "bg-green-50 text-green-600" : 
                    plan.status === 'Rejected' ? "bg-red-50 text-red-500" : "bg-yellow-50 text-yellow-500"
                  )}>
                    {plan.status === 'Approved' ? <CheckCircle2 className="w-5 h-5" /> : 
                     plan.status === 'Rejected' ? <XCircle className="w-5 h-5" /> : <Clock className="w-5 h-5" />}
                  </div>
                  <div>
                    <h3 className="font-bold text-lg text-slate-900">Week {plan.weekNumber}</h3>
                    <p className="text-xs text-slate-500">Version {plan.version} • Submitted {new Date(plan.submittedAt).toLocaleDateString()}</p>
                  </div>
                </div>
                <span className={cn(
                  "px-3 py-1 rounded-full text-xs font-bold uppercase tracking-wider",
                  plan.status === 'Approved' ? "bg-green-50 text-green-600" : 
                  plan.status === 'Rejected' ? "bg-red-50 text-red-500" : "bg-yellow-50 text-yellow-500"
                )}>
                  {plan.status}
                </span>
              </div>
              <p className="text-sm text-slate-600 line-clamp-2">{plan.tasks}</p>
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
                className="card p-6 sticky top-24 bg-white border border-slate-200"
              >
                <h3 className="text-lg font-bold mb-6 flex items-center gap-2">
                  <FileText className="w-5 h-5 text-teal-600" />
                  Week {selectedPlan.weekNumber} Details
                </h3>
                
                <div className="space-y-6">
                  <div>
                    <p className="text-xs text-slate-500 uppercase font-bold tracking-tight mb-2">Tasks Planned</p>
                    <p className="text-sm leading-relaxed text-slate-600 bg-slate-50 p-4 rounded-xl border border-slate-200">
                      {selectedPlan.tasks}
                    </p>
                  </div>

                  {selectedPlan.presentationUrl && (
                    <div>
                      <p className="text-xs text-slate-500 uppercase font-bold tracking-tight mb-2">Presentation</p>
                      <a 
                        href={selectedPlan.presentationUrl} 
                        target="_blank" 
                        rel="noopener noreferrer"
                        className="flex items-center justify-between p-3 rounded-xl border border-slate-200 hover:bg-slate-100 transition-all group"
                      >
                        <div className="flex items-center gap-3">
                          <FileText className="w-5 h-5 text-slate-500 group-hover:text-teal-600" />
                          <span className="text-sm font-medium">Weekly_Presentation.pdf</span>
                        </div>
                        <ExternalLink className="w-4 h-4 text-slate-500 group-hover:text-teal-600" />
                      </a>
                    </div>
                  )}

                  {selectedPlan.feedback && (
                    <div className={cn(
                      "p-4 rounded-xl border",
                      selectedPlan.status === 'Approved' ? "bg-green-50 border-green-200" : "bg-red-50 border-red-200"
                    )}>
                      <p className="text-xs text-slate-500 uppercase font-bold tracking-tight mb-2">Supervisor Feedback</p>
                      <p className={cn(
                        "text-sm font-medium",
                        selectedPlan.status === 'Approved' ? "text-green-700" : "text-red-700"
                      )}>
                        {selectedPlan.feedback}
                      </p>
                    </div>
                  )}

                  {selectedPlan.status === 'Rejected' && (
                    <button className="w-full bg-teal-600 hover:bg-teal-700 text-white font-medium py-2 px-4 rounded-lg transition-all flex items-center justify-center gap-2">
                      <History className="w-5 h-5" />
                      Revise and Resubmit
                    </button>
                  )}
                </div>
              </motion.div>
            ) : (
              <div className="card p-12 text-center flex flex-col items-center justify-center space-y-4 text-slate-500 bg-white border border-slate-200">
                <div className="p-4 bg-slate-50 rounded-full">
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
              className="bg-white rounded-2xl shadow-2xl w-full max-w-lg overflow-hidden border border-slate-200"
            >
              <header className="p-6 border-b border-slate-200 flex items-center justify-between">
                <h2 className="text-xl font-bold text-slate-900">Submit Weekly Plan</h2>
                <button onClick={() => setShowSubmitForm(false)} className="p-2 hover:bg-slate-100 rounded-full transition-colors">
                  <XCircle className="w-6 h-6 text-text-muted" />
                </button>
              </header>

              <form onSubmit={handleSubmit} className="p-6 space-y-6">
                <div className="space-y-2">
                  <label className="text-sm font-bold text-slate-500">Week Number</label>
                  <input 
                    type="number" 
                    className="w-full px-3 py-2 border border-slate-200 rounded-lg focus:outline-none focus:ring-2 focus:ring-teal-600 focus:border-transparent transition-all bg-white text-slate-900"
                    value={formData.weekNumber}
                    onChange={(e) => setFormData({ ...formData, weekNumber: parseInt(e.target.value) })}
                  />
                </div>

                <div className="space-y-2">
                  <label className="text-sm font-bold text-slate-500">Planned Tasks</label>
                  <textarea 
                    className="w-full min-h-[150px] px-3 py-2 border border-slate-200 rounded-lg focus:outline-none focus:ring-2 focus:ring-teal-600 focus:border-transparent transition-all bg-white text-slate-900 text-sm"
                    placeholder="Describe your planned tasks for the upcoming week..."
                    value={formData.tasks}
                    onChange={(e) => setFormData({ ...formData, tasks: e.target.value })}
                    required
                  />
                </div>

                <div className="space-y-2">
                  <label className="text-sm font-bold text-slate-500">Presentation (Optional)</label>
                  <div className="border-2 border-dashed border-slate-200 rounded-xl p-8 text-center hover:border-teal-600 transition-all cursor-pointer bg-slate-50 group">
                    <Upload className="w-8 h-8 text-slate-500 mx-auto mb-2 group-hover:text-teal-600 transition-all" />
                    <p className="text-sm font-medium text-slate-600">Click to upload or drag and drop</p>
                    <p className="text-xs text-slate-500 mt-1">PDF, PPT, PPTX (Max 10MB)</p>
                  </div>
                </div>

                <div className="flex gap-3 pt-4">
                  <button type="submit" className="flex-1 bg-teal-600 hover:bg-teal-700 text-white font-medium py-2 px-4 rounded-lg transition-all">Submit Plan</button>
                  <button 
                    type="button" 
                    onClick={() => setShowSubmitForm(false)}
                    className="px-6 py-2 border border-slate-200 rounded-lg hover:bg-slate-100 transition-colors text-slate-600 font-medium"
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
