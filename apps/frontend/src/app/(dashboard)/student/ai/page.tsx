"use client";

import AIChat from "@/components/ai/AIChat";

export default function StudentAiChatPage() {
  return (
    <div className="mx-auto w-full max-w-4xl">
      <AIChat variant="page" role="student" title="AI assistant" />
    </div>
  );
}
