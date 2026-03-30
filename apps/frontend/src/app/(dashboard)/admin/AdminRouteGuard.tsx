"use client";

import React, { useEffect } from "react";
import { useRouter } from "next/navigation";
import { useAuth } from "@/lib/hooks/useAuth";

/**
 * Frontend-only guard: signed-in users who are not ADMIN cannot stay on /admin.
 * Unauthenticated users can still load the page for local/demo builds without a backend.
 */
export default function AdminRouteGuard({ children }: { children: React.ReactNode }) {
  const { user } = useAuth();
  const router = useRouter();

  useEffect(() => {
    if (!user) return;
    if (user.role !== "ADMIN") {
      router.replace("/student");
    }
  }, [user, router]);

  return <>{children}</>;
}
