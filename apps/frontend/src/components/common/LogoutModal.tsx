'use client';

import { useTranslations } from 'next-intl';
import { LogOut, X } from 'lucide-react';

interface LogoutModalProps {
  onConfirm: () => void;
  onCancel: () => void;
}

export default function LogoutModal({ onConfirm, onCancel }: LogoutModalProps) {
  const t = useTranslations('LogoutModal');

  return (
    <div className="fixed inset-0 z-[200] flex items-center justify-center p-4">
      <div
        className="absolute inset-0 bg-black/40 backdrop-blur-sm"
        onClick={onCancel}
        aria-hidden
      />
      <div
        className="card relative mx-auto w-full max-w-sm space-y-6 p-6 sm:p-8 dark:border-slate-700"
        role="dialog"
        aria-modal="true"
        aria-labelledby="logout-modal-title"
        aria-describedby="logout-modal-desc"
      >
        <button
          type="button"
          onClick={onCancel}
          className="absolute right-3 top-3 rounded-lg p-2 text-text-muted transition-colors hover:bg-bg-tertiary hover:text-text-body"
          aria-label={t('closeAria')}
        >
          <X className="h-5 w-5" />
        </button>

        <div className="flex flex-col items-center space-y-3 text-center">
          <div className="flex h-14 w-14 items-center justify-center rounded-2xl bg-primary-light dark:bg-teal-900/40">
            <LogOut className="h-7 w-7 text-primary-600 dark:text-teal-400" />
          </div>
          <h2 id="logout-modal-title" className="text-xl font-bold text-text-heading dark:text-slate-100">
            {t('title')}
          </h2>
          <p id="logout-modal-desc" className="text-sm text-text-muted dark:text-slate-400">
            {t('subtitle')}
          </p>
        </div>

        <div className="flex gap-3">
          <button
            type="button"
            onClick={onCancel}
            className="flex-1 rounded-xl border border-border-default bg-bg-main px-4 py-2.5 text-sm font-semibold text-text-body shadow-sm transition-colors hover:bg-bg-tertiary dark:border-slate-600 dark:bg-slate-900 dark:text-slate-200 dark:hover:bg-slate-800"
          >
            {t('cancel')}
          </button>
          <button type="button" onClick={onConfirm} className="btn-primary flex-1 justify-center rounded-xl py-2.5">
            {t('confirm')}
          </button>
        </div>
      </div>
    </div>
  );
}
