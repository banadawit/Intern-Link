"use client";

import { useEffect } from 'react';
import { X } from 'lucide-react';
import { getFileUrl } from '@/lib/utils';

interface PdfViewerModalProps {
  pdfUrl: string;
  title?: string;
  isOpen: boolean;
  onClose: () => void;
}

export default function PdfViewerModal({ pdfUrl, title, isOpen, onClose }: PdfViewerModalProps) {
  useEffect(() => {
    document.body.style.overflow = isOpen ? 'hidden' : '';
    return () => { document.body.style.overflow = ''; };
  }, [isOpen]);

  useEffect(() => {
    const onKey = (e: KeyboardEvent) => { if (e.key === 'Escape') onClose(); };
    if (isOpen) document.addEventListener('keydown', onKey);
    return () => document.removeEventListener('keydown', onKey);
  }, [isOpen, onClose]);

  if (!isOpen) return null;

  const fileUrl = getFileUrl(pdfUrl);

  return (
    <div className="fixed inset-0 z-[200] flex items-center justify-center p-4 sm:p-6">
      {/* Backdrop */}
      <div
        className="absolute inset-0 bg-black/50 backdrop-blur-sm"
        onClick={onClose}
        aria-hidden
      />

      {/* Panel — compact, content-sized */}
      <div className="relative z-10 flex w-full max-w-2xl flex-col overflow-hidden rounded-2xl border border-slate-200 bg-white shadow-2xl dark:border-slate-700 dark:bg-slate-900"
        style={{ maxHeight: '80vh' }}
      >
        {/* Header */}
        <div className="flex items-center justify-between gap-3 border-b border-slate-200 bg-slate-50 px-4 py-3 dark:border-slate-700 dark:bg-slate-800">
          <div className="flex items-center gap-2 min-w-0">
            <span className="truncate text-sm font-semibold text-slate-800 dark:text-slate-100">
              {title || 'Verification Document'}
            </span>
          </div>
          <button
            type="button"
            onClick={onClose}
            className="shrink-0 inline-flex items-center gap-1.5 rounded-lg border border-slate-200 bg-white px-3 py-1.5 text-xs font-semibold text-slate-600 transition-colors hover:bg-red-50 hover:border-red-200 hover:text-red-600 dark:border-slate-700 dark:bg-slate-900 dark:text-slate-300 dark:hover:bg-red-950/30 dark:hover:text-red-400"
            aria-label="Close document viewer"
          >
            <X className="h-3.5 w-3.5" />
            Close
          </button>
        </div>

        {/* Document */}
        <div className="flex-1 overflow-hidden bg-slate-100 dark:bg-slate-950" style={{ minHeight: '400px' }}>
          <iframe
            src={`${fileUrl}#view=FitH`}
            title={title || 'Verification Document'}
            className="h-full w-full border-0"
            style={{ minHeight: '400px' }}
          />
        </div>
      </div>
    </div>
  );
}
