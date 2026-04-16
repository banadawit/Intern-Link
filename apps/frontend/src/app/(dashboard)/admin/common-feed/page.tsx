"use client";

import CommonFeedPage from "@/app/(dashboard)/common-feed/page";
import Sidebar from "@/app/(dashboard)/admin/Sidebar";
import { useState } from "react";

type ViewKey =
  | "dashboard"
  | "approvals"
  | "approved"
  | "rejected"
  | "suspended"
  | "audit-log"
  | "settings";

export default function AdminCommonFeedPage() {
  const [activeView] = useState<ViewKey>("dashboard");

  const handleNavigate = (view: ViewKey) => {
    if (view === "dashboard") {
      window.location.href = "/admin";
    } else {
      window.location.href = `/admin?view=${view}`;
    }
  };

  return (
    <div className="flex min-h-screen flex-col bg-slate-50 text-slate-600 antialiased lg:flex-row">
      <Sidebar activeView={activeView} onNavigate={handleNavigate} pendingCount={0} pendingCoordinatorCount={0} pendingSupervisorCount={0} />
      <main className="min-h-0 min-w-0 flex-1">
        <CommonFeedPage />
      </main>
    </div>
  );
}

