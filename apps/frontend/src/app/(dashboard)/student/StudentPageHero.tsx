import React from "react";
import { Sparkles } from "lucide-react";
import { cn } from "@/lib/utils";

export type StudentPageHeroProps = {
  badge: string;
  title: string;
  description: string;
  /** Optional right column (e.g. primary actions) — matches dashboard hero layout */
  action?: React.ReactNode;
  className?: string;
};

export default function StudentPageHero({
  badge,
  title,
  description,
  action,
  className,
}: StudentPageHeroProps) {
  return (
    <section
      className={cn(
        "relative overflow-hidden rounded-2xl border border-border-default bg-gradient-to-br from-primary-50/80 via-white to-slate-50 p-6 shadow-sm sm:p-8",
        className
      )}
    >
      <div
        className="pointer-events-none absolute -right-8 -top-8 h-32 w-32 rounded-full bg-primary-200/40 blur-2xl"
        aria-hidden
      />
      <div
        className="pointer-events-none absolute -bottom-4 left-1/4 h-24 w-48 rounded-full bg-teal-100/50 blur-xl"
        aria-hidden
      />
      <div className="relative flex flex-col gap-4 sm:flex-row sm:items-end sm:justify-between">
        <div className="space-y-2">
          <p className="inline-flex items-center gap-2 rounded-full bg-white/80 px-3 py-1 text-xs font-semibold uppercase tracking-wider text-primary-700 shadow-sm ring-1 ring-primary-100">
            <Sparkles className="h-3.5 w-3.5 shrink-0" />
            {badge}
          </p>
          <h1 className="text-2xl font-bold tracking-tight text-slate-900 sm:text-3xl md:text-4xl">
            {title}
          </h1>
          <p className="max-w-xl text-sm leading-relaxed text-slate-600 sm:text-base">
            {description}
          </p>
        </div>
        {action ? (
          <div className="flex w-full shrink-0 flex-col gap-2 sm:w-auto sm:flex-row sm:items-end">
            {action}
          </div>
        ) : null}
      </div>
    </section>
  );
}
