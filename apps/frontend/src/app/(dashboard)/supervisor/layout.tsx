"use client";

import React from "react";
import SupervisorSidebar from "./SupervisorSidebar";
import SupervisorRouteGuard from "./SupervisorRouteGuard";
import AiChatFloating from "@/components/ai/AiChatFloating";
import NotificationBell from "@/components/shared/NotificationBell";
import MaintenanceGuard from "@/components/auth/MaintenanceGuard";
import ThemeToggle from "@/components/theme/ThemeToggle";
import PageLoader from "@/components/shared/PageLoader";

export default function SupervisorLayout({ children }: { children: React.ReactNode }) {
  return (
    <SupervisorRouteGuard>
      <MaintenanceGuard>
      <PageLoader />
      <div className="flex min-h-screen flex-col bg-slate-50 text-slate-600 antialiased lg:flex-row dark:bg-slate-950 dark:text-slate-300">
        <SupervisorSidebar />
        <div className="flex min-h-0 min-w-0 flex-1 flex-col">
          <div className="flex items-center justify-end gap-2 border-b border-border-default bg-bg-main/95 px-4 py-3 backdrop-blur-sm sm:px-6 lg:px-8">
            <ThemeToggle variant="inline" className="px-2.5 py-2 [&>span]:hidden" />
            <NotificationBell />
          </div>
          <main className="relative z-0 flex min-h-0 min-w-0 flex-1 flex-col px-4 py-6 sm:px-6 sm:py-8 lg:px-8 lg:py-10">
            <div className="mx-auto w-full max-w-7xl">{children}</div>
          </main>
        </div>
        <AiChatFloating role="supervisor" />
      </div>
      </MaintenanceGuard>
    </SupervisorRouteGuard>
  );
}
