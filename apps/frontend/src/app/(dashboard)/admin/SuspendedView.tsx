"use client";

import React, { useState } from "react";
import { Building2, UserCheck, Briefcase } from "lucide-react";
import { cn } from "@/lib/utils";
import VerificationList from "./VerificationList";
import SuspendedCoordinators from "./SuspendedCoordinators";
import SuspendedSupervisors from "./SuspendedSupervisors";
import AdminPageHero from "./AdminPageHero";
import { VerificationProposal } from "@/lib/superadmin/types";

type Tab = "organizations" | "coordinators" | "supervisors";

interface Props {
  proposals: VerificationProposal[];
  listsLoading: boolean;
  onReview: (p: VerificationProposal) => void;
  suspendedCoordinatorCount: number;
  suspendedSupervisorCount: number;
}

const tabs: Array<{ id: Tab; label: string; icon: React.ComponentType<{ className?: string }>; title: string; description: string }> = [
  { id: "organizations", label: "Organizations", icon: Building2, title: "Suspended Organizations", description: "Universities and companies currently suspended from the platform." },
  { id: "coordinators", label: "Coordinators", icon: UserCheck, title: "Suspended Coordinators", description: "Coordinator accounts currently suspended." },
  { id: "supervisors", label: "Supervisors", icon: Briefcase, title: "Suspended Supervisors", description: "Supervisor accounts currently suspended." },
];

export default function SuspendedView({ proposals, listsLoading, onReview, suspendedCoordinatorCount, suspendedSupervisorCount }: Props) {
  const [activeTab, setActiveTab] = useState<Tab>("organizations");
  const active = tabs.find((t) => t.id === activeTab)!;

  const countFor = (id: Tab) => {
    if (id === "coordinators") return suspendedCoordinatorCount;
    if (id === "supervisors") return suspendedSupervisorCount;
    if (id === "organizations") return proposals.filter((p) => p.status === "Suspended").length;
    return 0;
  };

  return (
    <div className="space-y-6 animate-in fade-in slide-in-from-bottom-4 duration-500">
      <AdminPageHero badge="Suspended" title={active.title} description={active.description} />

      <div className="flex gap-1 rounded-2xl border border-slate-200 bg-slate-50 p-1">
        {tabs.map((tab) => {
          const isActive = activeTab === tab.id;
          const count = countFor(tab.id);
          return (
            <button
              key={tab.id}
              type="button"
              onClick={() => setActiveTab(tab.id)}
              className={cn(
                "flex flex-1 items-center justify-center gap-2 rounded-xl px-4 py-2.5 text-sm font-medium transition-all duration-200",
                isActive ? "bg-white text-teal-700 shadow-sm ring-1 ring-slate-200" : "text-slate-500 hover:text-slate-700"
              )}
            >
              <tab.icon className="h-4 w-4 shrink-0" />
              <span className="hidden sm:inline">{tab.label}</span>
              {count > 0 && (
                <span className={cn("rounded-full px-1.5 py-0.5 text-[10px] font-bold tabular-nums",
                  isActive ? "bg-teal-100 text-teal-800 ring-1 ring-teal-200/80" : "bg-slate-200 text-slate-700 ring-1 ring-slate-300/80"
                )}>
                  {count > 99 ? "99+" : count}
                </span>
              )}
            </button>
          );
        })}
      </div>

      <div>
        {activeTab === "organizations" && (
          <VerificationList title="Suspended Organizations" proposals={proposals.filter((p) => p.status === "Suspended")} onReview={onReview} loading={listsLoading} hideHero />
        )}
        {activeTab === "coordinators" && <SuspendedCoordinators />}
        {activeTab === "supervisors" && <SuspendedSupervisors />}
      </div>
    </div>
  );
}
