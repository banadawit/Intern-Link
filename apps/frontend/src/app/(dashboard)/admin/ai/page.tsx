"use client";

import Link from "next/link";
import { ArrowLeft } from "lucide-react";
import AIChat from "@/components/ai/AIChat";
import AdminRouteGuard from "@/app/(dashboard)/admin/AdminRouteGuard";

export default function AdminAiChatPage() {
  return (
    <AdminRouteGuard>
      <div className="min-h-screen bg-slate-50 px-4 py-8 sm:px-6 lg:px-8">
        <div className="mx-auto w-full max-w-4xl space-y-4">
          <Link
            href="/admin"
            className="inline-flex items-center gap-2 text-sm font-medium text-slate-600 hover:text-slate-900"
          >
            <ArrowLeft className="h-4 w-4" />
            Back to admin
          </Link>
          <AIChat variant="page" role="admin" title="AI assistant" />
        </div>
      </div>
    </AdminRouteGuard>
  );
}
