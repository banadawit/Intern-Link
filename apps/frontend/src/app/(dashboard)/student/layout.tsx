"use client";

import React from "react";
import StudentSidebar from "./StudentSidebar";
import AiChatFloating from "@/components/ai/AiChatFloating";
import StudentRouteGuard from "./StudentRouteGuard";
import NotificationBell from "@/components/shared/NotificationBell";
import MaintenanceGuard from "@/components/auth/MaintenanceGuard";

export default function StudentLayout({ children }: { children: React.ReactNode }) {
  return (
    <StudentRouteGuard>
      <MaintenanceGuard>
      <div className="flex min-h-screen flex-col bg-slate-50 text-slate-600 antialiased lg:flex-row">
        <StudentSidebar />
        <div className="flex min-h-0 min-w-0 flex-1 flex-col">
          <div className="flex items-center justify-end border-b border-border-default bg-bg-main/95 px-4 py-3 backdrop-blur-sm sm:px-6 lg:px-8">
            <NotificationBell />
          </div>
          <main className="relative z-0 flex-1 px-4 py-6 sm:px-6 sm:py-8 lg:px-8 lg:py-10">
            <div className="mx-auto w-full max-w-7xl">{children}</div>
          </main>
        </div>
        <AiChatFloating role="student" />
      </div>
      </MaintenanceGuard>
    </StudentRouteGuard>
  );
}
