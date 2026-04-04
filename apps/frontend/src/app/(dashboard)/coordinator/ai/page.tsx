"use client";

import Link from "next/link";
import { ArrowLeft } from "lucide-react";
import AIChat from "@/components/ai/AIChat";
import CoordinatorPageHero from "../CoordinatorPageHero";

export default function CoordinatorAiChatPage() {
  return (
    <div className="mx-auto w-full max-w-4xl space-y-6 pb-8">
      <CoordinatorPageHero
        badge="Assistant"
        title="AI assistant"
        description="Ask about university oversight, HOD workflows, and placement policies. Verify critical decisions independently."
        action={
          <Link
            href="/coordinator"
            className="inline-flex w-full shrink-0 items-center justify-center gap-2 rounded-xl border border-border-default bg-white/90 px-4 py-3 text-sm font-medium text-slate-800 shadow-sm backdrop-blur-sm transition-colors hover:bg-white sm:w-auto"
          >
            <ArrowLeft className="h-4 w-4" aria-hidden />
            Back to dashboard
          </Link>
        }
      />
      <AIChat variant="page" role="coordinator" title="AI assistant" />
    </div>
  );
}
