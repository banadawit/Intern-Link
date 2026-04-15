"use client";

import React, { useState } from "react";
import { Building2, UserCheck, Briefcase } from "lucide-react";
import { cn } from "@/lib/utils";
import VerificationList from "./VerificationList";
import ApprovedCoordinators from "./ApprovedCoordinators";
import ApprovedSupervisors from "./ApprovedSupervisors";
import AdminPageHero from "./AdminPageHero";
import { VerificationProposal } from "@/lib/superadmin/types";

type HistoryTab = "organizations" | "coordinators" | "supervisors";

interface Props {
  proposals: VerificationProposal[];
  listsLoading: boolean;
  onReview: (p: VerificationProposal) => void;
}

const tabs: Array<{
  id: HistoryTab;
  label: string;
  icon: React.ComponentType<{ className?: string }>;
  title: string;
  description: string;
}> = [
  {
    id: "organizations",
    label: "Organizations",
    icon: Building2,
    title: "Approved Organizations",
    description: "Universities and companies that have been verified and approved.",
  },
  {
    id: "coordinators",
    label: "Coordinators",
    icon: UserCheck,
    title: "Approved Coordinators",
    description: "University coordinators approved to manage internship programs.",
  },
  {
    id: "supervisors",
    label: "Supervisors",
    icon: Briefcase,
    title: "Approved Supervisors",
    description: "Company supervisors approved to mentor and evaluate interns.",
  },
];

export default function ApprovedHistoryView({ proposals, listsLoading, onReview }: Props) {
  const [activeTab, setActiveTab] = useState<HistoryTab>("organizations");

  const active = tabs.find((t) => t.id === activeTab)!;

  return (
    <div className="space-y-6 animate-in fade-in slide-in-from-bottom-4 duration-500">
      <AdminPageHero
        badge="History"
        title={active.title}
        description={active.description}
      />

      {/* Tab bar */}
      <div className="flex gap-1 rounded-2xl border border-slate-200 bg-slate-50 p-1">
        {tabs.map((tab) => {
          const isActive = activeTab === tab.id;
          return (
            <button
              key={tab.id}
              type="button"
              onClick={() => setActiveTab(tab.id)}
              className={cn(
                "flex flex-1 items-center justify-center gap-2 rounded-xl px-4 py-2.5 text-sm font-medium transition-all duration-200",
                isActive
                  ? "bg-white text-teal-700 shadow-sm ring-1 ring-slate-200"
                  : "text-slate-500 hover:text-slate-700"
              )}
            >
              <tab.icon className="h-4 w-4 shrink-0" />
              <span className="hidden sm:inline">{tab.label}</span>
            </button>
          );
        })}
      </div>

      <div>
        {activeTab === "organizations" && (
          <VerificationList
            title="Approved Organizations"
            proposals={proposals.filter((p) => p.status === "Approved")}
            onReview={onReview}
            loading={listsLoading}
            hideHero
          />
        )}
        {activeTab === "coordinators" && <ApprovedCoordinators />}
        {activeTab === "supervisors" && <ApprovedSupervisors />}
      </div>
    </div>
  );
}
