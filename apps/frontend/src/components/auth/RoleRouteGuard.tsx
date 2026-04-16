"use client";

import React, { useEffect, useRef, useState } from "react";
import { useRouter } from "next/navigation";
import { Loader2 } from "lucide-react";
import { useAuth } from "@/lib/hooks/useAuth";

type AppRole = "ADMIN" | "COORDINATOR" | "HOD" | "SUPERVISOR" | "STUDENT";

interface RoleRouteGuardProps {
  allowedRole: AppRole;
  children: React.ReactNode;
}

const roleHome: Record<AppRole, string> = {
  ADMIN: "/admin",
  COORDINATOR: "/coordinator",
  HOD: "/hod",
  SUPERVISOR: "/supervisor",
  STUDENT: "/student",
};

const requiresInstitutionApproval: AppRole[] = ["COORDINATOR", "HOD", "SUPERVISOR"];

function LoadingScreen() {
  return (
    <div className="flex min-h-screen items-center justify-center bg-slate-50">
      <Loader2 className="h-8 w-8 animate-spin text-primary-600" aria-hidden />
    </div>
  );
}

export default function RoleRouteGuard({ allowedRole, children }: RoleRouteGuardProps) {
  const { user } = useAuth();
  const router = useRouter();
  const [ready, setReady] = useState(false);
  const redirected = useRef(false);

  useEffect(() => {
    // Read persisted auth directly from localStorage — avoids Zustand hydration race
    let storedUser: { role?: string; institutionAccessApproval?: string } | null = null;
    try {
      const raw = localStorage.getItem("auth-storage");
      if (raw) {
        const parsed = JSON.parse(raw);
        storedUser = parsed?.state?.user ?? null;
      }
    } catch {
      storedUser = null;
    }

    const token = localStorage.getItem("token");

    if (!token || !storedUser) {
      if (!redirected.current) {
        redirected.current = true;
        router.replace("/login");
      }
      return;
    }

    const role = storedUser.role as AppRole;

    if (role !== allowedRole) {
      if (!redirected.current) {
        redirected.current = true;
        router.replace(roleHome[role] ?? "/login");
      }
      return;
    }

    if (
      requiresInstitutionApproval.includes(allowedRole) &&
      storedUser.institutionAccessApproval !== "APPROVED"
    ) {
      if (!redirected.current) {
        redirected.current = true;
        const msg = encodeURIComponent(
          allowedRole === "COORDINATOR"
            ? "Your coordinator account is pending administrator approval."
            : allowedRole === "HOD"
            ? "Your Head of Department account is pending coordinator approval."
            : "Your account is pending institutional approval."
        );
        router.replace(`/verification-pending?message=${msg}`);
      }
      return;
    }

    setReady(true);
  // eslint-disable-next-line react-hooks/exhaustive-deps
  }, []);

  if (!ready) return <LoadingScreen />;

  // Double-check with live Zustand state once hydrated
  if (user && user.role !== allowedRole) {
    router.replace(roleHome[user.role]);
    return <LoadingScreen />;
  }

  return <>{children}</>;
}
