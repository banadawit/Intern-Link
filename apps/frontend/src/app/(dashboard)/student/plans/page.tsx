"use client";

import { Suspense, useState } from "react";
import Link from "next/link";
import { ClipboardList, Calendar } from "lucide-react";
import { cn } from "@/lib/utils";
import WeeklyPlans from "../WeeklyPlans";
import DailyPlanView from "../DailyPlanView";
import { useTranslations } from "next-intl";

type Tab = "weekly" | "daily";

export default function StudentPlansPage() {
  const t = useTranslations("StudentPortal.plans");
  const [activeTab, setActiveTab] = useState<Tab>("weekly");

  return (
    <div className="space-y-6">
      {/* Top nav tabs */}
      <div className="flex gap-1 rounded-2xl border border-slate-200 bg-slate-50 p-1 dark:border-slate-700 dark:bg-slate-800/50">
        <button
          type="button"
          onClick={() => setActiveTab("weekly")}
          className={cn(
            "flex flex-1 items-center justify-center gap-2 rounded-xl px-4 py-2.5 text-sm font-medium transition-all duration-200",
            activeTab === "weekly"
              ? "bg-white text-teal-700 shadow-sm ring-1 ring-slate-200 dark:bg-slate-900 dark:text-teal-400 dark:ring-slate-700"
              : "text-slate-500 hover:text-slate-700 dark:text-slate-400 dark:hover:text-slate-200"
          )}
        >
          <ClipboardList className="h-4 w-4 shrink-0" />
          {t("weeklyPlans")}
        </button>
        <button
          type="button"
          onClick={() => setActiveTab("daily")}
          className={cn(
            "flex flex-1 items-center justify-center gap-2 rounded-xl px-4 py-2.5 text-sm font-medium transition-all duration-200",
            activeTab === "daily"
              ? "bg-white text-teal-700 shadow-sm ring-1 ring-slate-200 dark:bg-slate-900 dark:text-teal-400 dark:ring-slate-700"
              : "text-slate-500 hover:text-slate-700 dark:text-slate-400 dark:hover:text-slate-200"
          )}
        >
          <Calendar className="h-4 w-4 shrink-0" />
          {t("dailyPlan")}
        </button>
      </div>

      {/* Tab content */}
      {activeTab === "weekly" && (
        <Suspense fallback={<div className="py-12 text-center text-sm text-text-muted">{t("loadingWeekly")}</div>}>
          <div className="mb-6 rounded-2xl border border-primary-100 bg-primary-50/80 p-4 sm:p-5 dark:border-primary-800 dark:bg-primary-900/20">
            <h2 className="text-base font-semibold text-slate-900 dark:text-slate-100">{t("aiAssistant")}</h2>
            <p className="mt-1 text-sm text-slate-600 dark:text-slate-300">
              {t("aiAssistantDesc")}
            </p>
            <Link
              href="/student/ai"
              className="mt-3 inline-flex items-center justify-center rounded-xl bg-primary-600 px-4 py-2 text-sm font-semibold text-white transition-colors hover:bg-primary-700"
            >
              {t("openAiChat")}
            </Link>
          </div>
          <WeeklyPlans />
        </Suspense>
      )}

      {activeTab === "daily" && (
        <Suspense fallback={<div className="py-12 text-center text-sm text-text-muted">{t("loadingDaily")}</div>}>
          <DailyPlanView />
        </Suspense>
      )}
    </div>
  );
}
