"use client";

import { useEffect } from 'react';
import PdfViewer from './PdfViewer';

interface PdfViewerModalProps {
  pdfUrl: string;
  title?: string;
  isOpen: boolean;
  onClose: () => void;
}

export default function PdfViewerModal({ pdfUrl, title, isOpen, onClose }: PdfViewerModalProps) {
  useEffect(() => {
    if (isOpen) {
      document.body.style.overflow = 'hidden';
    } else {
      document.body.style.overflow = 'unset';
    }
    
    return () => {
      document.body.style.overflow = 'unset';
    };
  }, [isOpen]);
  
  useEffect(() => {
    const handleEscape = (e: KeyboardEvent) => {
      if (e.key === 'Escape' && isOpen) {
        onClose();
      }
    };
    
    document.addEventListener('keydown', handleEscape);
    return () => document.removeEventListener('keydown', handleEscape);
  }, [isOpen, onClose]);
  
  if (!isOpen) return null;
  
  return (
    <div className="fixed inset-0 z-50 flex items-center justify-center">
      {/* Backdrop */}
      <div 
        className="absolute inset-0 bg-black/50 backdrop-blur-sm"
        onClick={onClose}
      />
      
      {/* Modal Content */}
      <div className="relative w-full h-full max-w-7xl max-h-[95vh] m-4 flex">
        <PdfViewer 
          pdfUrl={pdfUrl} 
          title={title} 
          onClose={onClose}
          className="w-full h-full"
        />
      </div>
    </div>
  );
}
