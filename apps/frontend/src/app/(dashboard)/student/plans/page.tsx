import { Suspense } from "react";
import Link from "next/link";
import WeeklyPlans from "../WeeklyPlans";

export default function StudentPlansPage() {
  return (
    <Suspense fallback={<div className="py-12 text-center text-sm text-text-muted">Loading weekly plans…</div>}>
      <div className="mb-8 rounded-2xl border border-primary-100 bg-primary-50/80 p-4 sm:p-6">
        <h2 className="text-lg font-semibold text-slate-900">AI assistant</h2>
        <p className="mt-1 text-sm text-slate-600">
          Use the full chat to draft tasks, goals, and deliverables for your week. Nothing is submitted automatically — copy
          what you need into your plan form below.
        </p>
        <Link
          href="/student/ai"
          className="mt-4 inline-flex items-center justify-center rounded-xl bg-primary-600 px-4 py-2.5 text-sm font-semibold text-white transition-colors hover:bg-primary-700"
        >
          Open AI chat
        </Link>
      </div>
      <WeeklyPlans />
    </Suspense>
  );
}
