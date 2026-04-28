"use client";

import { useSearchParams, useRouter } from 'next/navigation';
import { ArrowLeft, Download, ZoomIn, ZoomOut } from 'lucide-react';
import { useState, Suspense } from 'react';
import { getFileUrl } from '@/lib/utils';
import { useAuth } from '@/lib/hooks/useAuth';
import dynamic from 'next/dynamic';

// Lazy-load each sidebar so we don't pull in all role code at once
const StudentSidebar    = dynamic(() => import('@/app/(dashboard)/student/StudentSidebar'));
const CoordinatorSidebar = dynamic(() => import('@/app/(dashboard)/coordinator/CoordinatorSidebar'));
const HodSidebar        = dynamic(() => import('@/app/(dashboard)/hod/HodSidebar'));
const SupervisorSidebar = dynamic(() => import('@/app/(dashboard)/supervisor/SupervisorSidebar'));
const AdminSidebar      = dynamic(() => import('@/app/(dashboard)/admin/Sidebar'));

/** Renders the correct sidebar for the current user's role */
function RoleSidebar() {
  const { user } = useAuth();
  switch (user?.role) {
    case 'STUDENT':     return <StudentSidebar />;
    case 'COORDINATOR': return <CoordinatorSidebar />;
    case 'HOD':         return <HodSidebar />;
    case 'SUPERVISOR':  return <SupervisorSidebar />;
    case 'ADMIN':
      // Admin sidebar needs props — render a minimal stub that matches the shell
      return (
        <AdminSidebar
          activeView="approvals"
          onNavigate={() => {}}
          pendingCount={0}
          pendingCoordinatorCount={0}
          pendingSupervisorCount={0}
        />
      );
    default: return null;
  }
}

function ViewDocumentContent() {
  const searchParams = useSearchParams();
  const router = useRouter();
  const [zoom, setZoom] = useState(100);

  const url   = searchParams.get('url');
  const title = searchParams.get('title') || 'Document';

  const fileUrl = url ? getFileUrl(url) : null;

  const handleDownload = () => {
    if (!fileUrl) return;
    const link = document.createElement('a');
    link.href = fileUrl;
    link.download = title;
    link.target = '_blank';
    document.body.appendChild(link);
    link.click();
    document.body.removeChild(link);
  };

  return (
    /* Full-screen flex row: sidebar + content */
    <div className="flex min-h-screen flex-col bg-slate-50 antialiased lg:flex-row">
      <RoleSidebar />

      {/* Right side: toolbar + iframe */}
      <div className="flex min-h-0 min-w-0 flex-1 flex-col">
        {/* Toolbar */}
        <div className="flex shrink-0 items-center justify-between border-b border-slate-200 bg-white px-4 py-3 shadow-sm">
          <div className="flex min-w-0 items-center gap-3">
            <button
              onClick={() => router.back()}
              className="shrink-0 rounded-lg p-2 hover:bg-slate-100 transition-colors"
              title="Go Back"
            >
              <ArrowLeft className="h-5 w-5 text-slate-700" />
            </button>
            <span className="truncate text-sm font-semibold text-slate-900">{title}</span>
          </div>

          <div className="flex items-center gap-1">
            <button
              onClick={() => setZoom(z => Math.max(z - 25, 50))}
              disabled={zoom <= 50}
              className="rounded-lg p-2 hover:bg-slate-100 disabled:opacity-40 transition-colors"
              title="Zoom Out"
            >
              <ZoomOut className="h-4 w-4 text-slate-700" />
            </button>
            <span className="w-12 text-center text-xs font-medium text-slate-600">{zoom}%</span>
            <button
              onClick={() => setZoom(z => Math.min(z + 25, 200))}
              disabled={zoom >= 200}
              className="rounded-lg p-2 hover:bg-slate-100 disabled:opacity-40 transition-colors"
              title="Zoom In"
            >
              <ZoomIn className="h-4 w-4 text-slate-700" />
            </button>
            <div className="mx-2 h-5 w-px bg-slate-200" />
            <button
              onClick={handleDownload}
              disabled={!fileUrl}
              className="rounded-lg p-2 hover:bg-slate-100 disabled:opacity-40 transition-colors"
              title="Download"
            >
              <Download className="h-4 w-4 text-slate-700" />
            </button>
          </div>
        </div>

        {/* PDF iframe */}
        {fileUrl ? (
          <div className="flex-1 bg-slate-100" style={{ height: 'calc(100vh - 57px)' }}>
            <iframe
              src={`${fileUrl}#toolbar=1&view=FitH`}
              title={title}
              className="h-full border-0"
              style={{ width: `${zoom}%`, minWidth: zoom < 100 ? undefined : '100%', display: 'block', margin: '0 auto', height: '100%' }}
            />
          </div>
        ) : (
          <div className="flex flex-1 items-center justify-center text-slate-500">
            <div className="text-center">
              <p>No document URL provided.</p>
              <button onClick={() => router.back()} className="mt-3 text-primary-600 hover:underline text-sm">
                Go Back
              </button>
            </div>
          </div>
        )}
      </div>
    </div>
  );
}

export default function ViewDocumentPage() {
  return (
    <Suspense fallback={
      <div className="flex min-h-screen items-center justify-center text-slate-500">
        Loading document…
      </div>
    }>
      <ViewDocumentContent />
    </Suspense>
  );
}
