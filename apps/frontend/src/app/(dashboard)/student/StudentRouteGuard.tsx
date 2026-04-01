"use client";

import React from "react";
import RoleRouteGuard from "@/components/auth/RoleRouteGuard";

export default function StudentRouteGuard({ children }: { children: React.ReactNode }) {
  return <RoleRouteGuard allowedRole="STUDENT">{children}</RoleRouteGuard>;
}
