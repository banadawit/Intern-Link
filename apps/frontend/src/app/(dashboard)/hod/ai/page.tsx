"use client";

import Link from "next/link";
import { ArrowLeft } from "lucide-react";
import HodPageHero from "@/app/(dashboard)/hod/HodPageHero";
import AIChat from "@/components/ai/AIChat";

export default function HodAiChatPage() {
  return (
    <div className="mx-auto w-full max-w-4xl space-y-6 pb-8">
      <HodPageHero
        badge="Assistant"
        title="AI assistant"
        description="Ask questions about department workflows, placements, and policies. Answers are guidance only — verify important decisions."
        action={
          <Link
            href="/hod"
            className="inline-flex w-full shrink-0 items-center justify-center gap-2 rounded-xl border border-border-default bg-white/90 px-4 py-3 text-sm font-medium text-slate-800 shadow-sm backdrop-blur-sm transition-colors hover:bg-white sm:w-auto"
          >
            <ArrowLeft className="h-4 w-4" aria-hidden />
            Back to dashboard
          </Link>
        }
      />
      <AIChat variant="page" role="hod" title="AI assistant" />
    </div>
  );
}
