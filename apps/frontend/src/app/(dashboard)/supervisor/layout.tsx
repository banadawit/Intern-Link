"use client";

import React from "react";
import SupervisorSidebar from "./SupervisorSidebar";
import SupervisorRouteGuard from "./SupervisorRouteGuard";
import AiChatFloating from "@/components/ai/AiChatFloating";

export default function SupervisorLayout({ children }: { children: React.ReactNode }) {
  return (
    <SupervisorRouteGuard>
      <div className="flex min-h-screen flex-col bg-slate-50 text-slate-600 antialiased lg:flex-row">
        <SupervisorSidebar />
        <main className="relative z-0 flex min-h-0 min-w-0 flex-1 flex-col px-4 py-6 sm:px-6 sm:py-8 lg:px-8 lg:py-10">
          <div className="mx-auto w-full max-w-7xl">{children}</div>
        </main>
        <AiChatFloating role="supervisor" />
      </div>
    </SupervisorRouteGuard>
  );
}
