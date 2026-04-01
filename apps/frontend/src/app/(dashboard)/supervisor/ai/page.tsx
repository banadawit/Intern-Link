"use client";

import AIChat from "@/components/ai/AIChat";

export default function SupervisorAiChatPage() {
  return (
    <div className="mx-auto w-full max-w-4xl">
      <AIChat variant="page" role="supervisor" title="AI assistant" />
    </div>
  );
}
