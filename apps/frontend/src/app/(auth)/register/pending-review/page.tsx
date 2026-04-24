'use client';

import Link from 'next/link';
import { Clock, Mail, CheckCircle, Suspense } from 'lucide-react';
import { useSearchParams } from 'next/navigation';

function PendingReviewContent() {
  const searchParams = useSearchParams();
  const role = searchParams.get('role') ?? 'coordinator';

  const config: Record<string, { title: string; description: string; steps: string[] }> = {
    student: {
      title: 'Registration Submitted',
      description: 'Your email is verified. Your Head of Department will review your registration and approve your account.',
      steps: [
        'Your registration details have been received',
        'Your Head of Department has been notified',
        'You will receive an email once your account is approved',
      ],
    },
    coordinator: {
      title: 'Registration Submitted',
      description: 'An administrator will review your university credentials. You will receive an email once your account is approved.',
      steps: [
        'Your registration details have been received',
        'Your verification document is under review',
        'You will be notified by email once approved',
      ],
    },
    hod: {
      title: 'Registration Submitted',
      description: 'Your University Coordinator will review your department credentials. You will receive an email once approved.',
      steps: [
        'Your registration details have been received',
        'Your coordinator has been notified',
        'You will be notified by email once approved',
      ],
    },
    supervisor: {
      title: 'Registration Submitted',
      description: 'An administrator will review your company credentials. You will receive an email once your account is approved.',
      steps: [
        'Your registration details have been received',
        'Your verification document is under review',
        'You will be notified by email once approved',
      ],
    },
  };

  const { title, description, steps } = config[role] ?? config.coordinator;

  return (
    <div className="space-y-6 animate-fade-in text-center">
      <div className="flex justify-center">
        <div className="h-20 w-20 rounded-full bg-amber-50 flex items-center justify-center">
          <Clock className="h-10 w-10 text-amber-500" />
        </div>
      </div>

      <div>
        <h1 className="text-2xl font-bold text-slate-900">{title}</h1>
        <p className="mt-3 text-sm text-slate-500 max-w-sm mx-auto">{description}</p>
      </div>

      <div className="rounded-xl bg-slate-50 border border-slate-200 p-4 text-left space-y-3">
        {steps.map((step, i) => (
          <div key={i} className="flex items-start gap-3">
            {i < steps.length - 1 ? (
              <CheckCircle className="h-5 w-5 text-emerald-500 mt-0.5 shrink-0" />
            ) : (
              <Mail className="h-5 w-5 text-primary-500 mt-0.5 shrink-0" />
            )}
            <p className="text-sm text-slate-600">{step}</p>
          </div>
        ))}
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

export default function PendingReviewPage() {
  return (
    <Suspense fallback={
      <div className="flex justify-center py-16">
        <Clock className="h-8 w-8 animate-pulse text-amber-500" />
      </div>
    }>
      <PendingReviewContent />
    </Suspense>
  );
}
