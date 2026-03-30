import React from "react";
import StudentSidebar from "./StudentSidebar";
import StudentPlanNotifications from "./StudentPlanNotifications";

export default function StudentLayout({ children }: { children: React.ReactNode }) {
  return (
    <div className="flex min-h-screen bg-slate-50 text-slate-600">
      <StudentSidebar />
      <div className="flex min-h-screen min-w-0 flex-1 flex-col">
        <StudentPlanNotifications />
        <main className="flex-1 p-8">
          <div className="mx-auto max-w-7xl">{children}</div>
        </main>
      </div>
    </div>
  );
}

