"use client";

import React from "react";
import RoleRouteGuard from "@/components/auth/RoleRouteGuard";

/**
 * Frontend-only guard: signed-in users who are not ADMIN cannot stay on /admin.
 * Unauthenticated users can still load the page for local/demo builds without a backend.
 */
export default function AdminRouteGuard({ children }: { children: React.ReactNode }) {
  return <RoleRouteGuard allowedRole="ADMIN">{children}</RoleRouteGuard>;
}
