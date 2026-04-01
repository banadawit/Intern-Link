"use client";

import AiChatFloating from "@/components/ai/AiChatFloating";

export default function CoordinatorLayout({ children }: { children: React.ReactNode }) {
  return (
    <>
      {children}
      <AiChatFloating role="coordinator" />
    </>
  );
}
