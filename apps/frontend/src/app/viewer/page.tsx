"use client";

import React, { Suspense } from "react";
import { useSearchParams, useRouter } from "next/navigation";
import { ChevronLeft, Download, ExternalLink, FileText, Loader2 } from "lucide-react";

function PDFViewerContent() {
  const searchParams = useSearchParams();
  const router = useRouter();
  const url = searchParams.get("url");

  if (!url) {
    return (
      <div className="flex min-h-screen flex-col items-center justify-center bg-slate-50 p-6 text-center">
        <div className="mb-4 rounded-full bg-red-100 p-4 text-red-600">
          <FileText className="h-8 w-8" />
        </div>
        <h1 className="text-xl font-bold text-slate-900">No Document Specified</h1>
        <p className="mt-2 text-slate-500">Please provide a valid document URL to view.</p>
        <button
          onClick={() => router.back()}
          className="mt-6 rounded-xl bg-slate-900 px-6 py-2.5 text-sm font-semibold text-white transition-all hover:bg-slate-800"
        >
          Go Back
        </button>
      </div>
    );
  }

  return (
    <div className="flex h-screen flex-col bg-slate-100">
      {/* Header */}
      <header className="flex items-center justify-between border-b border-slate-200 bg-white px-4 py-3 shadow-sm sm:px-6">
        <div className="flex items-center gap-4">
          <button
            onClick={() => router.back()}
            className="flex h-9 w-9 items-center justify-center rounded-lg border border-slate-200 text-slate-500 transition-colors hover:bg-slate-50 hover:text-slate-900"
            title="Go Back"
          >
            <ChevronLeft className="h-5 w-5" />
          </button>
          <div>
            <h1 className="text-sm font-bold text-slate-900 sm:text-base">Document Viewer</h1>
            <p className="hidden text-[10px] text-slate-500 sm:block truncate max-w-[300px]">
              {url.split('/').pop()}
            </p>
          </div>
        </div>

        <div className="flex items-center gap-2">
          <a
            href={url}
            download
            className="flex items-center gap-2 rounded-lg border border-slate-200 px-3 py-1.5 text-xs font-semibold text-slate-700 transition-colors hover:bg-slate-50 sm:text-sm"
          >
            <Download className="h-4 w-4" />
            <span className="hidden sm:inline">Download</span>
          </a>
          <a
            href={url}
            target="_blank"
            rel="noopener noreferrer"
            className="flex items-center gap-2 rounded-lg bg-slate-900 px-3 py-1.5 text-xs font-semibold text-white transition-all hover:bg-slate-800 sm:text-sm"
          >
            <ExternalLink className="h-4 w-4" />
            <span className="hidden sm:inline">Open in New Tab</span>
          </a>
        </div>
      </header>

      {/* Viewer Area */}
      <main className="relative flex-1 overflow-hidden">
        <iframe
          src={url}
          className="h-full w-full border-none"
          title="Document Content"
        />
      </main>
    </div>
  );
}

export default function PDFViewerPage() {
  return (
    <Suspense fallback={
      <div className="flex min-h-screen items-center justify-center bg-slate-50">
        <Loader2 className="h-8 w-8 animate-spin text-primary-600" />
      </div>
    }>
      <PDFViewerContent />
    </Suspense>
  );
}
