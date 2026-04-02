'use client';

import Link from 'next/link';
import { Clock, Mail, CheckCircle } from 'lucide-react';

export default function PendingReviewPage() {
  return (
    <div className="space-y-6 animate-fade-in text-center">
      <div className="flex justify-center">
        <div className="h-20 w-20 rounded-full bg-amber-50 flex items-center justify-center">
          <Clock className="h-10 w-10 text-amber-500" />
        </div>
      </div>

      <div>
        <h1 className="text-2xl font-bold text-slate-900">Registration Submitted</h1>
        <p className="mt-3 text-sm text-slate-500 max-w-sm mx-auto">
          An administrator will review your university credentials. You will receive an email once your account is approved.
        </p>
      </div>

      <div className="rounded-xl bg-slate-50 border border-slate-200 p-4 text-left space-y-3">
        <div className="flex items-start gap-3">
          <CheckCircle className="h-5 w-5 text-emerald-500 mt-0.5 flex-shrink-0" />
          <p className="text-sm text-slate-600">Your registration details have been received</p>
        </div>
        <div className="flex items-start gap-3">
          <CheckCircle className="h-5 w-5 text-emerald-500 mt-0.5 flex-shrink-0" />
          <p className="text-sm text-slate-600">Your verification document is under review</p>
        </div>
        <div className="flex items-start gap-3">
          <Mail className="h-5 w-5 text-primary-500 mt-0.5 flex-shrink-0" />
          <p className="text-sm text-slate-600">You will be notified by email once approved</p>
        </div>
      </div>

      <Link
        href="/login"
        className="inline-flex items-center justify-center w-full rounded-xl bg-primary-600 py-3 text-sm font-bold text-white hover:bg-primary-700 transition-colors"
      >
        Back to Login
      </Link>
    </div>
  );
}
