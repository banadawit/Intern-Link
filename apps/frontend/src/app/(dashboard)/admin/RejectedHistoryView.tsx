"use client";

import React, { useState } from "react";
import { Building2, UserCheck, Briefcase } from "lucide-react";
import { cn } from "@/lib/utils";
import VerificationList from "./VerificationList";
import RejectedCoordinators from "./RejectedCoordinators";
import RejectedSupervisors from "./RejectedSupervisors";
import AdminPageHero from "./AdminPageHero";
import { VerificationProposal } from "@/lib/superadmin/types";

type Tab = "organizations" | "coordinators" | "supervisors";

interface Props {
  proposals: VerificationProposal[];
  listsLoading: boolean;
  onReview: (p: VerificationProposal) => void;
  rejectedCoordinatorCount: number;
  rejectedSupervisorCount: number;
}

const tabs: Array<{ id: Tab; label: string; icon: React.ComponentType<{ className?: string }>; title: string; description: string }> = [
  { id: "organizations", label: "Organizations", icon: Building2, title: "Rejected Organizations", description: "Universities and companies whose verification was rejected." },
  { id: "coordinators", label: "Coordinators", icon: UserCheck, title: "Rejected Coordinators", description: "Coordinator registrations that were rejected." },
  { id: "supervisors", label: "Supervisors", icon: Briefcase, title: "Rejected Supervisors", description: "Supervisor registrations that were rejected." },
];

export default function RejectedHistoryView({ proposals, listsLoading, onReview, rejectedCoordinatorCount, rejectedSupervisorCount }: Props) {
  const [activeTab, setActiveTab] = useState<Tab>("organizations");
  const active = tabs.find((t) => t.id === activeTab)!;

  const countFor = (id: Tab) => {
    if (id === "coordinators") return rejectedCoordinatorCount;
    if (id === "supervisors") return rejectedSupervisorCount;
    if (id === "organizations") return proposals.filter((p) => p.status === "Rejected").length;
    return 0;
  };

  return (
    <div className="space-y-6 animate-in fade-in slide-in-from-bottom-4 duration-500">
      <AdminPageHero badge="Rejected" title={active.title} description={active.description} />

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
                  isActive ? "bg-teal-100 text-teal-800 ring-1 ring-teal-200/80" : "bg-red-100 text-red-700 ring-1 ring-red-200/80"
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
          <VerificationList title="Rejected Organizations" proposals={proposals.filter((p) => p.status === "Rejected")} onReview={onReview} loading={listsLoading} hideHero />
        )}
        {activeTab === "coordinators" && <RejectedCoordinators />}
        {activeTab === "supervisors" && <RejectedSupervisors />}
      </div>
    </div>
  );
}
