"use client";

import React from "react";
import RoleRouteGuard from "@/components/auth/RoleRouteGuard";

export default function CoordinatorRouteGuard({ children }: { children: React.ReactNode }) {
  return <RoleRouteGuard allowedRole="COORDINATOR">{children}</RoleRouteGuard>;
}
