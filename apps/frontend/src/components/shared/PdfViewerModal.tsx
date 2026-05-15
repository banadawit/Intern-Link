"use client";

import { useEffect, useState } from 'react';
import { X, Download, ExternalLink } from 'lucide-react';
import { getFileUrl } from '@/lib/utils';

interface PdfViewerModalProps {
  pdfUrl: string;
  title?: string;
  isOpen: boolean;
  onClose: () => void;
}

function detectType(url: string): 'image' | 'pdf' | 'doc' {
  const clean = url.split('?')[0].toLowerCase();
  if (/\.(png|jpe?g|gif|webp|svg|bmp)$/.test(clean)) return 'image';
  if (/\.pdf$/.test(clean)) return 'pdf';
  return 'doc';
}

export default function PdfViewerModal({ pdfUrl, title, isOpen, onClose }: PdfViewerModalProps) {
  const [iframeError, setIframeError] = useState(false);

  useEffect(() => {
    setIframeError(false);
  }, [pdfUrl]);

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
  const type = detectType(fileUrl);

  // For PDFs and docs, use Google Docs Viewer which renders inline regardless of
  // Content-Disposition headers set by the storage provider.
  const viewerUrl = type === 'image'
    ? fileUrl
    : `https://docs.google.com/viewer?url=${encodeURIComponent(fileUrl)}&embedded=true`;

  return (
    <div className="fixed inset-0 z-[200] flex items-center justify-center p-4 sm:p-6">
      {/* Backdrop */}
      <div
        className="absolute inset-0 bg-black/60 backdrop-blur-sm"
        onClick={onClose}
        aria-hidden
      />

      {/* Panel */}
      <div
        className="relative z-10 flex w-full max-w-3xl flex-col overflow-hidden rounded-2xl border border-slate-200 bg-white shadow-2xl dark:border-slate-700 dark:bg-slate-900"
        style={{ maxHeight: '88vh' }}
      >
        {/* Header */}
        <div className="flex items-center justify-between gap-3 border-b border-slate-200 bg-slate-50 px-4 py-3 dark:border-slate-700 dark:bg-slate-800">
          <span className="truncate text-sm font-semibold text-slate-800 dark:text-slate-100">
            {title || 'Verification Document'}
          </span>
          <div className="flex items-center gap-2 shrink-0">
            <a
              href={fileUrl}
              target="_blank"
              rel="noopener noreferrer"
              className="inline-flex items-center gap-1.5 rounded-lg border border-slate-200 bg-white px-3 py-1.5 text-xs font-semibold text-slate-600 transition-colors hover:bg-slate-50 dark:border-slate-700 dark:bg-slate-900 dark:text-slate-300"
            >
              <ExternalLink className="h-3.5 w-3.5" />
              Open
            </a>
            <a
              href={fileUrl}
              download
              className="inline-flex items-center gap-1.5 rounded-lg border border-slate-200 bg-white px-3 py-1.5 text-xs font-semibold text-slate-600 transition-colors hover:bg-slate-50 dark:border-slate-700 dark:bg-slate-900 dark:text-slate-300"
            >
              <Download className="h-3.5 w-3.5" />
              Download
            </a>
            <button
              type="button"
              onClick={onClose}
              className="inline-flex items-center gap-1.5 rounded-lg border border-slate-200 bg-white px-3 py-1.5 text-xs font-semibold text-slate-600 transition-colors hover:bg-red-50 hover:border-red-200 hover:text-red-600 dark:border-slate-700 dark:bg-slate-900 dark:text-slate-300 dark:hover:bg-red-950/30 dark:hover:text-red-400"
              aria-label="Close"
            >
              <X className="h-3.5 w-3.5" />
              Close
            </button>
          </div>
        </div>

        {/* Content */}
        <div className="flex-1 overflow-auto bg-slate-100 dark:bg-slate-950" style={{ minHeight: '480px' }}>
          {type === 'image' ? (
            <div className="flex items-center justify-center p-4 min-h-[480px]">
              <img
                src={fileUrl}
                alt={title || 'Document'}
                className="max-w-full max-h-[72vh] rounded-lg object-contain shadow-md"
              />
            </div>
          ) : iframeError ? (
            /* Fallback when Google Docs Viewer fails (e.g. private/restricted URL) */
            <div className="flex flex-col items-center justify-center gap-4 p-10 text-center min-h-[480px]">
              <p className="text-sm text-slate-500 dark:text-slate-400">
                Preview unavailable. Use the buttons above to open or download the file.
              </p>
              <a
                href={fileUrl}
                target="_blank"
                rel="noopener noreferrer"
                className="inline-flex items-center gap-2 rounded-xl bg-teal-600 px-5 py-2.5 text-sm font-semibold text-white hover:bg-teal-700 transition-colors"
              >
                <ExternalLink className="h-4 w-4" />
                Open in new tab
              </a>
            </div>
          ) : (
            <iframe
              key={viewerUrl}
              src={viewerUrl}
              title={title || 'Document'}
              className="h-full w-full border-0"
              style={{ minHeight: '480px' }}
              onError={() => setIframeError(true)}
            />
          )}
        </div>
      </div>
    </div>
  );
}
