'use client';

import { useState } from 'react';
import { useRouter } from 'next/navigation';
import api from '@/lib/api/client';
import { Briefcase, Plus, Trash2, ArrowLeft, GripVertical } from 'lucide-react';

interface Question {
  question: string;
  required: boolean;
  order: number;
}

export default function CreateJobOpportunityPage() {
  const router = useRouter();
  const [title, setTitle] = useState('');
  const [content, setContent] = useState('');
  const [deadline, setDeadline] = useState('');
  const [slots, setSlots] = useState(1);
  const [questions, setQuestions] = useState<Question[]>([
    { question: '', required: true, order: 0 },
  ]);
  const [submitting, setSubmitting] = useState(false);
  const [toast, setToast] = useState<{ msg: string; type: 'success' | 'error' } | null>(null);

  const showToast = (msg: string, type: 'success' | 'error' = 'success') => {
    setToast({ msg, type });
    setTimeout(() => setToast(null), 4000);
  };

  const addQuestion = () => {
    setQuestions((prev) => [...prev, { question: '', required: true, order: prev.length }]);
  };

  const removeQuestion = (i: number) => {
    setQuestions((prev) => prev.filter((_, idx) => idx !== i).map((q, idx) => ({ ...q, order: idx })));
  };

  const updateQuestion = (i: number, field: keyof Question, value: string | boolean | number) => {
    setQuestions((prev) => prev.map((q, idx) => idx === i ? { ...q, [field]: value } : q));
  };

  const handleSubmit = async () => {
    if (!title.trim() || !content.trim()) { showToast('Title and description are required.', 'error'); return; }
    const validQuestions = questions.filter((q) => q.question.trim());
    setSubmitting(true);
    try {
      await api.post('/job-opportunities', {
        title: title.trim(),
        content: content.trim(),
        deadline: deadline || null,
        slots,
        questions: validQuestions,
      });
      showToast('Opportunity posted successfully!');
      setTimeout(() => router.push('/supervisor/job-opportunities'), 1200);
    } catch (e: unknown) {
      const err = e as { response?: { data?: { message?: string } } };
      showToast(err.response?.data?.message ?? 'Failed to post opportunity.', 'error');
    } finally {
      setSubmitting(false);
    }
  };

  return (
    <div className="max-w-2xl mx-auto px-4 py-8">
      <button
        onClick={() => router.back()}
        className="flex items-center gap-1.5 text-sm text-slate-500 dark:text-slate-400 hover:text-slate-700 dark:hover:text-slate-200 mb-6 transition-colors"
      >
        <ArrowLeft className="h-4 w-4" /> Back
      </button>

      <div className="flex items-center gap-3 mb-8">
        <div className="flex h-10 w-10 items-center justify-center rounded-xl bg-teal-100 dark:bg-teal-900/30">
          <Briefcase className="h-5 w-5 text-teal-600 dark:text-teal-400" />
        </div>
        <div>
          <h1 className="text-xl font-bold text-slate-900 dark:text-slate-100">Post a Job Opportunity</h1>
          <p className="text-sm text-slate-500 dark:text-slate-400">This will appear on the common feed as an Opportunity post</p>
        </div>
      </div>

      <div className="space-y-6">
        {/* Title */}
        <div>
          <label className="block text-sm font-semibold text-slate-700 dark:text-slate-300 mb-1.5">Job Title <span className="text-red-500">*</span></label>
          <input
            type="text"
            value={title}
            onChange={(e) => setTitle(e.target.value)}
            placeholder="e.g. Frontend Developer Intern"
            className="w-full rounded-xl border border-slate-300 dark:border-slate-600 bg-white dark:bg-slate-800 px-4 py-2.5 text-sm text-slate-900 dark:text-slate-100 placeholder:text-slate-400 focus:outline-none focus:ring-2 focus:ring-teal-500"
          />
        </div>

        {/* Description */}
        <div>
          <label className="block text-sm font-semibold text-slate-700 dark:text-slate-300 mb-1.5">Description <span className="text-red-500">*</span></label>
          <textarea
            value={content}
            onChange={(e) => setContent(e.target.value)}
            placeholder="Describe the role, responsibilities, requirements, and what you're looking for..."
            rows={6}
            className="w-full rounded-xl border border-slate-300 dark:border-slate-600 bg-white dark:bg-slate-800 px-4 py-2.5 text-sm text-slate-900 dark:text-slate-100 placeholder:text-slate-400 focus:outline-none focus:ring-2 focus:ring-teal-500 resize-none"
          />
        </div>

        {/* Deadline + Slots */}
        <div className="grid grid-cols-2 gap-4">
          <div>
            <label className="block text-sm font-semibold text-slate-700 dark:text-slate-300 mb-1.5">Application Deadline</label>
            <input
              type="date"
              value={deadline}
              onChange={(e) => setDeadline(e.target.value)}
              min={new Date().toISOString().split('T')[0]}
              className="w-full rounded-xl border border-slate-300 dark:border-slate-600 bg-white dark:bg-slate-800 px-4 py-2.5 text-sm text-slate-900 dark:text-slate-100 focus:outline-none focus:ring-2 focus:ring-teal-500"
            />
          </div>
          <div>
            <label className="block text-sm font-semibold text-slate-700 dark:text-slate-300 mb-1.5">Available Slots</label>
            <input
              type="number"
              value={slots}
              onChange={(e) => setSlots(Math.max(1, parseInt(e.target.value) || 1))}
              min={1}
              className="w-full rounded-xl border border-slate-300 dark:border-slate-600 bg-white dark:bg-slate-800 px-4 py-2.5 text-sm text-slate-900 dark:text-slate-100 focus:outline-none focus:ring-2 focus:ring-teal-500"
            />
          </div>
        </div>

        {/* Questions */}
        <div>
          <div className="flex items-center justify-between mb-3">
            <div>
              <label className="block text-sm font-semibold text-slate-700 dark:text-slate-300">Application Questions</label>
              <p className="text-xs text-slate-500 dark:text-slate-400 mt-0.5">Students will answer these when applying</p>
            </div>
            <button
              type="button"
              onClick={addQuestion}
              className="flex items-center gap-1.5 rounded-lg border border-teal-200 dark:border-teal-800 bg-teal-50 dark:bg-teal-900/20 px-3 py-1.5 text-xs font-semibold text-teal-700 dark:text-teal-400 hover:bg-teal-100 dark:hover:bg-teal-900/40 transition-colors"
            >
              <Plus className="h-3.5 w-3.5" /> Add Question
            </button>
          </div>

          <div className="space-y-3">
            {questions.map((q, i) => (
              <div key={i} className="flex items-start gap-3 bg-slate-50 dark:bg-slate-800/50 rounded-xl p-3 border border-slate-200 dark:border-slate-700">
                <GripVertical className="h-5 w-5 text-slate-300 dark:text-slate-600 mt-2 shrink-0" />
                <div className="flex-1 space-y-2">
                  <input
                    type="text"
                    value={q.question}
                    onChange={(e) => updateQuestion(i, 'question', e.target.value)}
                    placeholder={`Question ${i + 1}`}
                    className="w-full rounded-lg border border-slate-300 dark:border-slate-600 bg-white dark:bg-slate-800 px-3 py-2 text-sm text-slate-900 dark:text-slate-100 placeholder:text-slate-400 focus:outline-none focus:ring-2 focus:ring-teal-500"
                  />
                  <label className="flex items-center gap-2 text-xs text-slate-600 dark:text-slate-400 cursor-pointer">
                    <input
                      type="checkbox"
                      checked={q.required}
                      onChange={(e) => updateQuestion(i, 'required', e.target.checked)}
                      className="rounded border-slate-300 text-teal-600 focus:ring-teal-500"
                    />
                    Required
                  </label>
                </div>
                {questions.length > 1 && (
                  <button
                    type="button"
                    onClick={() => removeQuestion(i)}
                    className="mt-1.5 rounded-lg p-1.5 text-slate-400 hover:text-red-500 hover:bg-red-50 dark:hover:bg-red-900/20 transition-colors shrink-0"
                  >
                    <Trash2 className="h-4 w-4" />
                  </button>
                )}
              </div>
            ))}
          </div>
        </div>

        {/* Submit */}
        <button
          onClick={handleSubmit}
          disabled={submitting || !title.trim() || !content.trim()}
          className="w-full rounded-xl bg-teal-600 py-3 text-sm font-semibold text-white hover:bg-teal-700 transition-colors disabled:opacity-50 disabled:cursor-not-allowed shadow-sm"
        >
          {submitting ? 'Posting…' : 'Post Opportunity'}
        </button>
      </div>

      {toast && (
        <div className={`fixed bottom-6 left-1/2 -translate-x-1/2 z-50 rounded-2xl px-5 py-3 shadow-2xl text-sm font-semibold text-white ${toast.type === 'error' ? 'bg-red-600' : 'bg-slate-900'}`}>
          {toast.msg}
        </div>
      )}
    </div>
  );
}
