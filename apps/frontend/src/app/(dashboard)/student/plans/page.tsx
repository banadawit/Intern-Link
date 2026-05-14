"use client";

import { Suspense, useEffect, useState } from "react";
import Link from "next/link";
import { ClipboardList, Crown, Calendar, UsersRound } from "lucide-react";
import { cn } from "@/lib/utils";
import WeeklyPlans from "../WeeklyPlans";
import MyTeamView from "../my-team/page";
import TeamPlansView from "../team-plans/page";
import api from "@/lib/api/client";
import dynamic from "next/dynamic";

// Lazy-load the collect views from the team page
const CollectPlansView = dynamic(
  () => import("../team/page").then((m) => {
    // Extract CollectPlansView — it's not exported by default, so we use the team page's tab
    return { default: () => null };
  }),
  { ssr: false }
);

type Tab = "weekly" | "my-team" | "team-plans" | "collect" | "collect-daily";

export default function StudentPlansPage() {
  const [activeTab, setActiveTab] = useState<Tab>("weekly");
  const [isLeader, setIsLeader] = useState(false);
  const [isInTeam, setIsInTeam] = useState(false);

  useEffect(() => {
    api.get("/progress/team-plans/my")
      .then(({ data }) => {
        const d = (data as { success?: boolean; data?: unknown })?.data;
        if (d && typeof d === "object" && !Array.isArray(d)) {
          const obj = d as { isManager?: boolean; team?: unknown };
          setIsLeader(obj.isManager === true);
          setIsInTeam(!!obj.team);
        }
      })
      .catch(() => {});
  }, []);

  const tabs = [
    { id: "weekly" as Tab, label: "Weekly Plans", icon: ClipboardList, show: true, amber: false },
    { id: "my-team" as Tab, label: "My Team", icon: UsersRound, show: isInTeam || isLeader, amber: false },
    { id: "team-plans" as Tab, label: "Team Plans", icon: ClipboardList, show: isInTeam || isLeader, amber: false },
    { id: "collect" as Tab, label: "Collect Weekly Plans", icon: Crown, show: isLeader, amber: true },
    { id: "collect-daily" as Tab, label: "Collect Daily Plans", icon: Calendar, show: isLeader, amber: true },
  ].filter((t) => t.show);

  return (
    <div className="space-y-6">
      {/* Top nav tabs */}
      <div className="flex flex-wrap gap-1 rounded-2xl border border-slate-200 bg-slate-50 p-1 dark:border-slate-700 dark:bg-slate-800/50">
        {tabs.map((tab) => (
          <button
            key={tab.id}
            type="button"
            onClick={() => setActiveTab(tab.id)}
            className={cn(
              "flex flex-1 items-center justify-center gap-2 rounded-xl px-4 py-2.5 text-sm font-medium transition-all duration-200 min-w-[120px]",
              activeTab === tab.id
                ? tab.amber
                  ? "bg-white text-amber-700 shadow-sm ring-1 ring-slate-200 dark:bg-slate-900 dark:text-amber-400 dark:ring-slate-700"
                  : "bg-white text-teal-700 shadow-sm ring-1 ring-slate-200 dark:bg-slate-900 dark:text-teal-400 dark:ring-slate-700"
                : "text-slate-500 hover:text-slate-700 dark:text-slate-400 dark:hover:text-slate-200"
            )}
          >
            <tab.icon className={cn("h-4 w-4 shrink-0", tab.amber && "text-amber-500")} />
            {tab.label}
          </button>
        ))}
      </div>

      {/* Tab content */}
      {activeTab === "weekly" && (
        <Suspense fallback={<div className="py-12 text-center text-sm text-text-muted">Loading weekly plans…</div>}>
          <div className="mb-6 rounded-2xl border border-primary-100 bg-primary-50/80 p-4 sm:p-5 dark:border-primary-800 dark:bg-primary-900/20">
            <h2 className="text-base font-semibold text-slate-900 dark:text-slate-100">AI assistant</h2>
            <p className="mt-1 text-sm text-slate-600 dark:text-slate-300">
              Use the full chat to draft tasks, goals, and deliverables for your week.
            </p>
            <Link
              href="/student/ai"
              className="mt-3 inline-flex items-center justify-center rounded-xl bg-primary-600 px-4 py-2 text-sm font-semibold text-white transition-colors hover:bg-primary-700"
            >
              Open AI chat
            </Link>
          </div>
          <WeeklyPlans />
        </Suspense>
      )}

      {activeTab === "my-team" && (
        <Suspense fallback={<div className="py-12 text-center text-sm text-text-muted">Loading…</div>}>
          <MyTeamView />
        </Suspense>
      )}

      {activeTab === "team-plans" && (
        <Suspense fallback={<div className="py-12 text-center text-sm text-text-muted">Loading…</div>}>
          <TeamPlansView />
        </Suspense>
      )}

      {activeTab === "collect" && isLeader && (
        <Suspense fallback={<div className="py-12 text-center text-sm text-text-muted">Loading…</div>}>
          {/* Redirect to team page collect tab */}
          <div className="rounded-2xl border border-amber-200 bg-amber-50 dark:border-amber-800 dark:bg-amber-900/20 p-6 text-center">
            <Crown className="h-10 w-10 text-amber-500 mx-auto mb-3" />
            <p className="font-semibold text-amber-900 dark:text-amber-200 mb-2">Collect Weekly Plans</p>
            <p className="text-sm text-amber-700 dark:text-amber-300 mb-4">
              Review and approve your teammates&apos; weekly plans, then forward the compiled team plan to your supervisor.
            </p>
            <Link
              href="/student/team"
              className="inline-flex items-center gap-2 rounded-xl bg-amber-600 px-4 py-2.5 text-sm font-semibold text-white hover:bg-amber-700 transition-colors"
            >
              <Crown className="h-4 w-4" />
              Open Team Dashboard
            </Link>
          </div>
        </Suspense>
      )}

      {activeTab === "collect-daily" && isLeader && (
        <Suspense fallback={<div className="py-12 text-center text-sm text-text-muted">Loading…</div>}>
          <div className="rounded-2xl border border-amber-200 bg-amber-50 dark:border-amber-800 dark:bg-amber-900/20 p-6 text-center">
            <Calendar className="h-10 w-10 text-amber-500 mx-auto mb-3" />
            <p className="font-semibold text-amber-900 dark:text-amber-200 mb-2">Collect Daily Plans</p>
            <p className="text-sm text-amber-700 dark:text-amber-300 mb-4">
              Review your teammates&apos; daily submissions and forward them to your supervisor.
            </p>
            <Link
              href="/student/team"
              className="inline-flex items-center gap-2 rounded-xl bg-amber-600 px-4 py-2.5 text-sm font-semibold text-white hover:bg-amber-700 transition-colors"
            >
              <Calendar className="h-4 w-4" />
              Open Team Dashboard
            </Link>
          </div>
        </Suspense>
      )}
    </div>
  );
}
