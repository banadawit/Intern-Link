"use client";

import CoordinatorSidebar from "./CoordinatorSidebar";
import CoordinatorRouteGuard from "./CoordinatorRouteGuard";
import AiChatFloating from "@/components/ai/AiChatFloating";
import NotificationBell from "@/components/shared/NotificationBell";
import MaintenanceGuard from "@/components/auth/MaintenanceGuard";
import ThemeToggle from "@/components/theme/ThemeToggle";
import PageLoader from "@/components/shared/PageLoader";

export default function CoordinatorLayout({ children }: { children: React.ReactNode }) {
  return (
    <CoordinatorRouteGuard>
      <MaintenanceGuard>
      <PageLoader />
      <div className="flex min-h-screen flex-col bg-slate-50 text-slate-600 antialiased lg:flex-row dark:bg-slate-950 dark:text-slate-300">
        <CoordinatorSidebar />
        <div className="flex min-h-0 min-w-0 flex-1 flex-col">
          <div className="flex items-center justify-end gap-2 border-b border-border-default bg-bg-main/95 dark:bg-slate-900/95 dark:border-slate-700 px-4 py-3 backdrop-blur-sm sm:px-6 lg:px-8">
            <ThemeToggle variant="inline" className="px-2.5 py-2 [&>span]:hidden" />
            <NotificationBell />
          </div>
          <main className="relative z-0 flex min-h-0 min-w-0 flex-1 flex-col px-4 py-6 sm:px-6 sm:py-8 lg:px-8 lg:py-10">
            <div className="mx-auto w-full max-w-7xl">{children}</div>
          </main>
        </div>
        <AiChatFloating role="coordinator" />
      </div>
      </MaintenanceGuard>
    </CoordinatorRouteGuard>
  );
}
