import React from "react";
import StudentSidebar from "./StudentSidebar";
import StudentPlanNotifications from "./StudentPlanNotifications";

import AiChatFloating from "@/components/ai/AiChatFloating";

import StudentRouteGuard from "./StudentRouteGuard";


export default function StudentLayout({ children }: { children: React.ReactNode }) {
  return (
    <StudentRouteGuard>
      <div className="flex min-h-screen flex-col bg-slate-50 text-slate-600 antialiased lg:flex-row">
        <StudentSidebar />
        <div className="flex min-h-0 min-w-0 flex-1 flex-col">
          <StudentPlanNotifications />
          <main className="relative z-0 flex-1 px-4 py-6 sm:px-6 sm:py-8 lg:px-8 lg:py-10">
            <div className="mx-auto w-full max-w-7xl">{children}</div>
          </main>
        </div>
        <AiChatFloating role="student" />
      </div>
    </StudentRouteGuard>
  );
}
