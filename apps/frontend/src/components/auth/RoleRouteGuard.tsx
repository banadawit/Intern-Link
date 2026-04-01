"use client";

import React, { useEffect, useState } from "react";
import { useRouter } from "next/navigation";
import { Loader2 } from "lucide-react";
import { useAuth } from "@/lib/hooks/useAuth";

type AppRole = "ADMIN" | "COORDINATOR" | "SUPERVISOR" | "STUDENT";

interface RoleRouteGuardProps {
  allowedRole: AppRole;
  children: React.ReactNode;
}

const roleHome: Record<AppRole, string> = {
  ADMIN: "/admin",
  COORDINATOR: "/coordinator",
  SUPERVISOR: "/supervisor",
  STUDENT: "/student",
};

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
  const [hasToken, setHasToken] = useState<boolean | null>(null);
  const [hydrationTimedOut, setHydrationTimedOut] = useState(false);

  useEffect(() => {
    setHasToken(Boolean(localStorage.getItem("token")));
  }, []);

  useEffect(() => {
    if (!hasToken || user) return;
    const timeout = setTimeout(() => setHydrationTimedOut(true), 1500);
    return () => clearTimeout(timeout);
  }, [hasToken, user]);

  useEffect(() => {
    if (hasToken === null) return;
    if (!hasToken) {
      router.replace("/login");
      return;
    }
    if (!user && hydrationTimedOut) {
      router.replace("/login");
      return;
    }
    if (!user) return;
    if (user.role !== allowedRole) {
      router.replace(roleHome[user.role]);
    }
  }, [allowedRole, hasToken, hydrationTimedOut, router, user]);

  if (hasToken === null || !hasToken || !user || user.role !== allowedRole) {
    return <LoadingScreen />;
  }

  return <>{children}</>;
}
