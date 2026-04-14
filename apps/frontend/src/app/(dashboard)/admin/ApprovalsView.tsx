"use client";

import React, { useState } from "react";
import { Clock, UserCheck, Briefcase } from "lucide-react";
import { cn } from "@/lib/utils";
import VerificationList from "./VerificationList";
import CoordinatorApprovals from "./CoordinatorApprovals";
import SupervisorApprovals from "./SupervisorApprovals";
import AdminPageHero from "./AdminPageHero";
import { VerificationProposal } from "@/lib/superadmin/types";

type ApprovalTab = "pending" | "coordinator-approvals" | "supervisor-approvals";

interface Props {
  proposals: VerificationProposal[];
  listsLoading: boolean;
  pendingCount: number;
  pendingCoordinatorCount: number;
  pendingSupervisorCount: number;
  onReview: (p: VerificationProposal) => void;
  onActionComplete: () => void;
  initialTab?: ApprovalTab;
}

const tabs: Array<{
  id: ApprovalTab;
  label: string;
  icon: React.ComponentType<{ className?: string }>;
  badge: string;
  title: string;
  description: string;
}> = [
  {
    id: "pending",
    label: "Verification",
    icon: Clock,
    badge: "Verification",
    title: "Pending Organization Approvals",
    description: "Manage and review institutional verification requests.",
  },
  {
    id: "coordinator-approvals",
    label: "Coordinators",
    icon: UserCheck,
    badge: "Coordinators",
    title: "Pending Coordinator Approvals",
    description: "Review and approve university coordinator registrations.",
  },
  {
    id: "supervisor-approvals",
    label: "Supervisors",
    icon: Briefcase,
    badge: "Supervisors",
    title: "Pending Supervisor Approvals",
    description: "Review and approve company supervisor registrations.",
  },
];

export default function ApprovalsView({
  proposals,
  listsLoading,
  pendingCount,
  pendingCoordinatorCount,
  pendingSupervisorCount,
  onReview,
  onActionComplete,
  initialTab = "coordinator-approvals",
}: Props) {
  const [activeTab, setActiveTab] = useState<ApprovalTab>(initialTab);

  const badgeFor = (tab: ApprovalTab) => {
    if (tab === "pending") return pendingCount;
    if (tab === "coordinator-approvals") return pendingCoordinatorCount;
    if (tab === "supervisor-approvals") return pendingSupervisorCount;
    return 0;
  };

  const active = tabs.find((t) => t.id === activeTab)!;

  return (
    <div className="space-y-6 animate-in fade-in slide-in-from-bottom-4 duration-500">
      {/* Dynamic hero — updates per active tab */}
      <AdminPageHero
        badge={active.badge}
        title={active.title}
        description={active.description}
      />

      {/* Tab bar */}
      <div className="flex gap-1 rounded-2xl border border-slate-200 bg-slate-50 p-1">
        {tabs.map((tab) => {
          const count = badgeFor(tab.id);
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
              {count > 0 && (
                <span
                  className={cn(
                    "rounded-full px-1.5 py-0.5 text-[10px] font-bold tabular-nums",
                    isActive
                      ? "bg-teal-100 text-teal-800"
                      : "bg-slate-200 text-slate-600"
                  )}
                >
                  {count > 99 ? "99+" : count}
                </span>
              )}
            </button>
          );
        })}
      </div>

      {/* Tab content — sub-components render without their own hero */}
      <div>
        {activeTab === "pending" && (
          <VerificationList
            title="Pending Organization Approvals"
            proposals={proposals.filter((p) => p.status === "Pending")}
            onReview={onReview}
            loading={listsLoading}
            hideHero
          />
        )}
        {activeTab === "coordinator-approvals" && (
          <CoordinatorApprovals onActionComplete={onActionComplete} hideHero />
        )}
        {activeTab === "supervisor-approvals" && (
          <SupervisorApprovals onActionComplete={onActionComplete} hideHero />
        )}
      </div>
    </div>
  );
}
