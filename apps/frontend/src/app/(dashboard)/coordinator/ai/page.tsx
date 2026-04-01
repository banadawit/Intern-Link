"use client";

import Link from "next/link";
import { ArrowLeft } from "lucide-react";
import AIChat from "@/components/ai/AIChat";

export default function CoordinatorAiChatPage() {
  return (
    <div className="mx-auto w-full max-w-4xl space-y-4">
      <Link
        href="/coordinator"
        className="inline-flex items-center gap-2 text-sm font-medium text-slate-600 hover:text-slate-900"
      >
        <ArrowLeft className="h-4 w-4" />
        Back to dashboard
      </Link>
      <AIChat variant="page" role="coordinator" title="AI assistant" />
    </div>
  );
}
