"use client";

import React, { useMemo } from "react";
import { useLocation, useNavigate } from "react-router-dom";
import Sidebar from "@/app/(dashboard)/admin/Sidebar";

import type { ViewKey } from "@/app/(dashboard)/admin/Sidebar";

function pathnameToView(pathname: string): ViewKey {
  if (pathname.includes("/pending") || pathname.includes("/approvals") || pathname.includes("/approved") || pathname.includes("/rejected") || pathname.includes("/suspended")) return "approvals";
  if (pathname.includes("/organizations")) return "organizations";
  if (pathname.includes("/audit-log")) return "audit-log";
  if (pathname.includes("/settings")) return "settings";
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

  const pendingCount = 0;

  return (
    <Sidebar activeView={activeView} onNavigate={onNavigate} pendingCount={pendingCount} />
  );
}
