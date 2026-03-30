"use client";

import React, { useMemo } from "react";
import { useLocation, useNavigate } from "react-router-dom";
import Sidebar from "@/app/(dashboard)/admin/Sidebar";
import { MOCK_PROPOSALS } from "@/lib/superadmin/mockData";

type ViewKey = "dashboard" | "pending" | "approved" | "rejected" | "suspended" | "audit-log" | "settings";

function pathnameToView(pathname: string): ViewKey {
  if (pathname.includes("/pending")) return "pending";
  if (pathname.includes("/approved")) return "approved";
  if (pathname.includes("/rejected")) return "rejected";
  if (pathname.includes("/audit-log")) return "audit-log";
  if (pathname.includes("/settings")) return "settings";
  if (pathname.includes("/suspended")) return "suspended";
  return "dashboard";
}

/**
 * Bridges the legacy CRA `App.tsx` router to the Next-based admin `Sidebar` props.
 * (The main product uses `/admin` in the App Router; this exists so `src/App.tsx` typechecks.)
 */
export default function AdminSidebar() {
  const { pathname } = useLocation();
  const navigate = useNavigate();

  const activeView = useMemo(() => pathnameToView(pathname), [pathname]);

  const onNavigate = (view: ViewKey) => {
    if (view === "dashboard") navigate("/admin");
    else if (view === "audit-log") navigate("/admin/audit-log");
    else if (view === "settings") navigate("/admin/settings");
    else navigate(`/admin/${view}`);
  };

  const pendingCount = MOCK_PROPOSALS.filter((p) => p.status === "Pending").length;

  return (
    <Sidebar activeView={activeView} onNavigate={onNavigate} pendingCount={pendingCount} />
  );
}
