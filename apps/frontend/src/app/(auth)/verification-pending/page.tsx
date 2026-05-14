'use client';

import React, { Suspense } from 'react';
import Link from 'next/link';
import { useSearchParams } from 'next/navigation';
import { Clock3, ArrowLeft, ShieldAlert } from 'lucide-react';
import { useTranslations } from 'next-intl';

function VerificationPendingContent() {
  const t = useTranslations('Auth.verificationPending');
  const searchParams = useSearchParams();
  const message =
    searchParams.get('message') ||
    'Your account cannot access the dashboard yet. Please wait for administrator approval.';

  return (
    <div className="space-y-8 animate-fade-in text-center lg:text-left">
      <div className="flex flex-col items-center lg:items-start">
        <div className="h-16 w-16 rounded-2xl bg-amber-50 flex items-center justify-center mb-6">
          <Clock3 className="h-8 w-8 text-amber-600" />
        </div>
        <h1 className="text-3xl font-bold text-slate-900 dark:text-slate-100">{t('title')}</h1>
        <p className="mt-2 text-sm text-slate-500 max-w-md dark:text-slate-400">{t('subtitle')}</p>
      </div>

      <div className="rounded-2xl border border-amber-100 bg-amber-50 p-6 dark:border-amber-900/60 dark:bg-amber-900/20">
        <div className="flex items-start gap-3 text-amber-800 dark:text-amber-200">
          <ShieldAlert className="h-5 w-5 flex-shrink-0 mt-0.5" />
          <p className="text-sm">{message}</p>
        </div>
      </div>

      <div className="space-y-3">
        <p className="text-sm text-slate-500 dark:text-slate-400">
          {t('checkBackLater')}
        </p>
        <Link
          href="/login"
          className="inline-flex items-center justify-center gap-2 rounded-xl bg-primary-600 px-5 py-3 text-sm font-bold text-white shadow-lg shadow-primary-600/20 transition-all hover:bg-primary-700"
        >
          <ArrowLeft className="h-4 w-4" />
          {t('backToLogin')}
        </Link>
      </div>
    </div>
  );
}

export default function VerificationPendingPage() {
  return (
    <Suspense fallback={<div className="space-y-8 animate-fade-in text-center" />}>
      <VerificationPendingContent />
    </Suspense>
  );
}
