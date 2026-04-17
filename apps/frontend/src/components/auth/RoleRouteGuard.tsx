"use client";

import React, { useEffect, useState } from "react";
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
  const [hasToken, setHasToken] = useState<boolean | null>(null);
  const [hydrationTimedOut, setHydrationTimedOut] = useState(false);
  // Wait for Zustand to rehydrate from localStorage before making approval checks
  const [isHydrated, setIsHydrated] = useState(false);

  useEffect(() => {
    setHasToken(Boolean(localStorage.getItem("token")));
    // Give Zustand persist a tick to rehydrate
    const t = setTimeout(() => setIsHydrated(true), 50);
    return () => clearTimeout(t);
  }, []);

  useEffect(() => {
    if (!hasToken || user) return;
    const timeout = setTimeout(() => setHydrationTimedOut(true), 1500);
    return () => clearTimeout(timeout);
  }, [hasToken, user]);

  useEffect(() => {
    if (hasToken === null || !isHydrated) return;
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
      return;
    }
    // Block access if institution approval is still pending
    if (
      requiresInstitutionApproval.includes(allowedRole) &&
      user.institutionAccessApproval !== "APPROVED"
    ) {
      const msg = encodeURIComponent(
        allowedRole === "COORDINATOR"
          ? "Your coordinator account is pending administrator approval. You will receive an email once approved."
          : allowedRole === "HOD"
          ? "Your Head of Department account is pending coordinator approval. You will receive an email once approved."
          : "Your account is pending institutional approval."
      );
      router.replace(`/verification-pending?message=${msg}`);
    }
  }, [allowedRole, hasToken, hydrationTimedOut, isHydrated, router, user]);

  // Show loader until hydrated and user is confirmed
  if (hasToken === null || !isHydrated || !hasToken || !user || user.role !== allowedRole) {
    return <LoadingScreen />;
  }

  // Block render if institution approval pending
  if (
    requiresInstitutionApproval.includes(allowedRole) &&
    user.institutionAccessApproval !== "APPROVED"
  ) {
    return <LoadingScreen />;
  }

  return <>{children}</>;
}
