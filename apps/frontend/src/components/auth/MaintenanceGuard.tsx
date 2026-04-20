"use client";

import React, { useEffect, useState } from "react";
import { Wrench, Clock } from "lucide-react";
import { useAuth } from "@/lib/hooks/useAuth";
import api from "@/lib/api/client";

interface MaintenanceStatus {
  active: boolean;
  message: string;
}

interface Props {
  children: React.ReactNode;
}

export default function MaintenanceGuard({ children }: Props) {
  const { user } = useAuth();
  const [status, setStatus] = useState<MaintenanceStatus | null>(null);

  useEffect(() => {
    // Poll every 30 seconds so users get unblocked automatically when maintenance ends
    const check = async () => {
      try {
        const { data } = await api.get<MaintenanceStatus>("/maintenance-status");
        setStatus(data);
      } catch {
        // If we can't reach the server, don't block the user
        setStatus({ active: false, message: "" });
      }
    };

    void check();
    const interval = setInterval(() => void check(), 30_000);
    return () => clearInterval(interval);
  }, []);

  // Still loading — don't flash anything
  if (status === null) return <>{children}</>;

  // Admins bypass maintenance mode
  if (user?.role === "ADMIN") return <>{children}</>;

  // Maintenance is active — show blocking screen
  if (status.active) {
    return (
      <div className="flex min-h-screen flex-col items-center justify-center bg-slate-900 px-4 text-center">
        <div className="max-w-md space-y-6">
          {/* Icon */}
          <div className="mx-auto flex h-20 w-20 items-center justify-center rounded-full bg-amber-500/10 ring-1 ring-amber-500/20">
            <Wrench className="h-10 w-10 text-amber-400" />
          </div>

          {/* Heading */}
          <div className="space-y-2">
            <h1 className="text-3xl font-bold text-white">Under Maintenance</h1>
            <p className="text-slate-400">
              {status.message || "The platform is currently under maintenance. Please check back soon."}
            </p>
          </div>

          {/* Auto-refresh notice */}
          <div className="flex items-center justify-center gap-2 rounded-xl border border-slate-700 bg-slate-800 px-4 py-3 text-sm text-slate-400">
            <Clock className="h-4 w-4 shrink-0 text-slate-500" />
            This page checks automatically every 30 seconds. You will be redirected as soon as the platform is back online.
          </div>

          {/* Branding */}
          <p className="text-xs text-slate-600">InternLink — Smart Internship Management</p>
        </div>
      </div>
    );
  }

  return <>{children}</>;
}
