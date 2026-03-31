"use client";

import React, { useEffect, useState } from "react";
import { useRouter } from "next/navigation";
import { useAuth } from "@/lib/hooks/useAuth";
import { Loader2 } from "lucide-react";

export default function SupervisorRouteGuard({ children }: { children: React.ReactNode }) {
  const { user } = useAuth();
  const router = useRouter();
  const [hasToken, setHasToken] = useState<boolean | null>(null);

  useEffect(() => {
    setHasToken(!!localStorage.getItem("token"));
  }, []);

  useEffect(() => {
    if (hasToken === null) return;
    if (!hasToken) {
      router.replace("/login");
    }
  }, [hasToken, router]);

  useEffect(() => {
    if (hasToken === null || !hasToken || !user) return;
    if (user.role !== "SUPERVISOR") {
      if (user.role === "ADMIN") router.replace("/admin");
      else if (user.role === "COORDINATOR") router.replace("/coordinator");
      else router.replace("/student");
    }
  }, [user, hasToken, router]);

  if (hasToken === null) {
    return (
      <div className="flex min-h-screen items-center justify-center bg-slate-50">
        <Loader2 className="h-8 w-8 animate-spin text-primary-600" aria-hidden />
      </div>
    );
  }

  if (!hasToken) {
    return (
      <div className="flex min-h-screen items-center justify-center bg-slate-50">
        <Loader2 className="h-8 w-8 animate-spin text-primary-600" aria-hidden />
      </div>
    );
  }

  if (!user) {
    return (
      <div className="flex min-h-screen items-center justify-center bg-slate-50">
        <Loader2 className="h-8 w-8 animate-spin text-primary-600" aria-hidden />
      </div>
    );
  }

  if (user.role !== "SUPERVISOR") {
    return (
      <div className="flex min-h-screen items-center justify-center bg-slate-50">
        <Loader2 className="h-8 w-8 animate-spin text-primary-600" aria-hidden />
      </div>
    );
  }

  return <>{children}</>;
}
