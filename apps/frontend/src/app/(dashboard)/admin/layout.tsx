"use client";

import AiChatFloating from "@/components/ai/AiChatFloating";
import PageLoader from "@/components/shared/PageLoader";

export default function AdminLayout({ children }: { children: React.ReactNode }) {
  return (
    <>
      <PageLoader />
      {children}
      <AiChatFloating role="admin" />
    </>
  );
}
