"use client";

import React from "react";
import RoleRouteGuard from "@/components/auth/RoleRouteGuard";

export default function SupervisorRouteGuard({ children }: { children: React.ReactNode }) {
  return <RoleRouteGuard allowedRole="SUPERVISOR">{children}</RoleRouteGuard>;
}
