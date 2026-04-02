"use client";

import RoleRouteGuard from "@/components/auth/RoleRouteGuard";

export default function HodRouteGuard({ children }: { children: React.ReactNode }) {
  return <RoleRouteGuard allowedRole="HOD">{children}</RoleRouteGuard>;
}
