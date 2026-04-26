"use client";

import { useState } from 'react';
import { X, Download, ZoomIn, ZoomOut, Maximize2, Minimize2 } from 'lucide-react';
import { getFileUrl } from '@/lib/utils';

interface PdfViewerProps {
  pdfUrl: string;
  title?: string;
  onClose?: () => void;
  className?: string;
}

export default function PdfViewer({ pdfUrl, title, onClose, className = '' }: PdfViewerProps) {
  const [zoom, setZoom] = useState(100);
  const [isFullscreen, setIsFullscreen] = useState(false);
  
  const fileUrl = getFileUrl(pdfUrl);
  
  const handleZoomIn = () => setZoom(prev => Math.min(prev + 25, 200));
  const handleZoomOut = () => setZoom(prev => Math.max(prev - 25, 50));
  const toggleFullscreen = () => setIsFullscreen(prev => !prev);
  
  const handleDownload = () => {
    const link = document.createElement('a');
    link.href = fileUrl;
    link.download = title || 'document.pdf';
    link.target = '_blank';
    document.body.appendChild(link);
    link.click();
    document.body.removeChild(link);
  };

  return (
    <div className={`flex flex-col bg-white rounded-xl border border-slate-200 shadow-lg overflow-hidden ${isFullscreen ? 'fixed inset-4 z-50' : className}`}>
      {/* Header */}
      <div className="flex items-center justify-between px-4 py-3 bg-slate-50 border-b border-slate-200">
        <h3 className="text-sm font-semibold text-slate-900 truncate">
          {title || 'PDF Document'}
        </h3>
        
        <div className="flex items-center gap-2">
          {/* Zoom Controls */}
          <button
            onClick={handleZoomOut}
            disabled={zoom <= 50}
            className="p-1.5 rounded-lg hover:bg-slate-200 disabled:opacity-50 disabled:cursor-not-allowed transition-colors"
            title="Zoom Out"
          >
            <ZoomOut className="h-4 w-4 text-slate-700" />
          </button>
          
          <span className="text-xs font-medium text-slate-600 min-w-[3rem] text-center">
            {zoom}%
          </span>
          
          <button
            onClick={handleZoomIn}
            disabled={zoom >= 200}
            className="p-1.5 rounded-lg hover:bg-slate-200 disabled:opacity-50 disabled:cursor-not-allowed transition-colors"
            title="Zoom In"
          >
            <ZoomIn className="h-4 w-4 text-slate-700" />
          </button>
          
          <div className="w-px h-5 bg-slate-300 mx-1" />
          
          {/* Download Button */}
          <button
            onClick={handleDownload}
            className="p-1.5 rounded-lg hover:bg-slate-200 transition-colors"
            title="Download PDF"
          >
            <Download className="h-4 w-4 text-slate-700" />
          </button>
          
          {/* Fullscreen Toggle */}
          <button
            onClick={toggleFullscreen}
            className="p-1.5 rounded-lg hover:bg-slate-200 transition-colors"
            title={isFullscreen ? "Exit Fullscreen" : "Fullscreen"}
          >
            {isFullscreen ? (
              <Minimize2 className="h-4 w-4 text-slate-700" />
            ) : (
              <Maximize2 className="h-4 w-4 text-slate-700" />
            )}
          </button>
          
          {/* Close Button */}
          {onClose && (
            <>
              <div className="w-px h-5 bg-slate-300 mx-1" />
              <button
                onClick={onClose}
                className="p-1.5 rounded-lg hover:bg-red-100 transition-colors"
                title="Close"
              >
                <X className="h-4 w-4 text-red-600" />
              </button>
            </>
          )}
        </div>
      </div>
      
      {/* PDF Viewer */}
      <div className="flex-1 overflow-auto bg-slate-100 p-4 min-h-0">
        <div className="h-full mx-auto" style={{ width: `${zoom}%` }}>
          <iframe
            src={`${fileUrl}#view=FitH`}
            className="w-full h-full bg-white shadow-md"
            title={title || 'PDF Document'}
            style={{ minHeight: '100%', height: '100vh' }}
          />
        </div>
      </div>
    </div>
  );
}
