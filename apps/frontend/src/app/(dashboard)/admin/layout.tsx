"use client";

import AiChatFloating from "@/components/ai/AiChatFloating";

export default function AdminLayout({ children }: { children: React.ReactNode }) {
  return (
    <>
      {children}
      <AiChatFloating role="admin" />
    </>
  );
}
