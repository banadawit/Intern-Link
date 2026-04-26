"use client";

import { ArrowLeft, Download, ZoomIn, ZoomOut } from 'lucide-react';
import { useState } from 'react';
import { getFileUrl } from '@/lib/utils';

interface PdfViewerPageProps {
  url: string;
  title?: string;
  onClose: () => void;
}

/**
 * Renders a full-height PDF viewer that replaces the current page content.
 * The parent page should conditionally render this instead of its normal content
 * when a PDF is selected. This keeps the sidebar/header intact.
 *
 * Usage:
 *   const [pdf, setPdf] = useState<{url:string; title:string} | null>(null);
 *   if (pdf) return <PdfViewerPage url={pdf.url} title={pdf.title} onClose={() => setPdf(null)} />;
 *   return <NormalPageContent ... />;
 */
export default function PdfViewerPage({ url, title = 'Document', onClose }: PdfViewerPageProps) {
  const [zoom, setZoom] = useState(100);
  const fileUrl = getFileUrl(url);

  const handleDownload = () => {
    const link = document.createElement('a');
    link.href = fileUrl;
    link.download = title;
    link.target = '_blank';
    document.body.appendChild(link);
    link.click();
    document.body.removeChild(link);
  };

  return (
    /*
     * Escape the layout's padding with negative margins, then fill the full
     * remaining viewport height. The values mirror each layout's padding:
     *   px-4 py-6  →  -mx-4 -my-6
     *   sm:px-6 sm:py-8  →  sm:-mx-6 sm:-my-8
     *   lg:px-8 lg:py-10 →  lg:-mx-8 lg:-my-10
     */
    <div className="
      -mx-4 -my-6 sm:-mx-6 sm:-my-8 lg:-mx-8 lg:-my-10
      flex flex-col bg-white
      h-[calc(100vh_-_0px)]
    ">
      {/* Toolbar */}
      <div className="flex shrink-0 items-center justify-between border-b border-slate-200 bg-slate-50 px-4 py-3">
        <div className="flex items-center gap-3 min-w-0">
          <button
            onClick={onClose}
            className="shrink-0 flex items-center gap-2 rounded-lg px-3 py-2 text-sm font-medium text-slate-700 hover:bg-slate-200 transition-colors"
          >
            <ArrowLeft className="h-4 w-4" />
            Back
          </button>
          <div className="h-5 w-px bg-slate-300" />
          <span className="truncate text-sm font-semibold text-slate-900">{title}</span>
        </div>

        <div className="flex items-center gap-1">
          <button
            onClick={() => setZoom(z => Math.max(z - 25, 50))}
            disabled={zoom <= 50}
            className="rounded-lg p-2 hover:bg-slate-200 disabled:opacity-40 transition-colors"
            title="Zoom Out"
          >
            <ZoomOut className="h-4 w-4 text-slate-700" />
          </button>
          <span className="w-12 text-center text-xs font-medium text-slate-600">{zoom}%</span>
          <button
            onClick={() => setZoom(z => Math.min(z + 25, 200))}
            disabled={zoom >= 200}
            className="rounded-lg p-2 hover:bg-slate-200 disabled:opacity-40 transition-colors"
            title="Zoom In"
          >
            <ZoomIn className="h-4 w-4 text-slate-700" />
          </button>
          <div className="mx-2 h-5 w-px bg-slate-300" />
          <button
            onClick={handleDownload}
            className="rounded-lg p-2 hover:bg-slate-200 transition-colors"
            title="Download"
          >
            <Download className="h-4 w-4 text-slate-700" />
          </button>
        </div>
      </div>

      {/* PDF iframe — fills all remaining height */}
      <div className="flex-1 overflow-hidden bg-slate-100">
        <iframe
          src={`${fileUrl}#toolbar=1&view=FitH`}
          title={title}
          className="h-full w-full border-0"
          style={{ display: 'block', width: `${zoom}%`, margin: '0 auto', height: '100%' }}
        />
      </div>
    </div>
  );
}
