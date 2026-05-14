"use client";

import { Suspense } from "react";
import Link from "next/link";
import WeeklyPlans from "../WeeklyPlans";

export default function StudentPlansPage() {
  return (
    <div className="space-y-6">
      <Suspense fallback={<div className="py-12 text-center text-sm text-text-muted">Loading weekly plans…</div>}>
        <div className="mb-6 rounded-2xl border border-primary-100 bg-primary-50/80 p-4 sm:p-5 dark:border-primary-800 dark:bg-primary-900/20">
          <h2 className="text-base font-semibold text-slate-900 dark:text-slate-100">AI assistant</h2>
          <p className="mt-1 text-sm text-slate-600 dark:text-slate-300">
            Use the full chat to draft tasks, goals, and deliverables for your week.
          </p>
          <Link
            href="/student/ai"
            className="mt-3 inline-flex items-center justify-center rounded-xl bg-primary-600 px-4 py-2 text-sm font-semibold text-white transition-colors hover:bg-primary-700"
          >
            Open AI chat
          </Link>
        </div>
        <WeeklyPlans />
      </Suspense>
    </div>
  );
}
