"use client";

import { useCallback, useEffect, useState } from "react";
import api from "@/lib/api/client";
import { UsersRound, FolderKanban, Crown, User, AlertCircle, RefreshCw } from "lucide-react";
import { cn } from "@/lib/utils";

type TeamMember = {
  studentId: number;
  fullName: string;
  email: string;
  isManager: boolean;
  isMe: boolean;
};

type TeamData = {
  id: number;
  name: string;
  managerId: number | null;
  managerName: string | null;
  isManager: boolean;
  project: { id: number; name: string; description: string | null } | null;
  members: TeamMember[];
};

function initials(name: string) {
  return name.split(/\s+/).map((n) => n[0]).join("").toUpperCase().slice(0, 2);
}

const COLORS = [
  "bg-teal-100 text-teal-700 dark:bg-teal-900/40 dark:text-teal-300",
  "bg-blue-100 text-blue-700 dark:bg-blue-900/40 dark:text-blue-300",
  "bg-violet-100 text-violet-700 dark:bg-violet-900/40 dark:text-violet-300",
  "bg-amber-100 text-amber-700 dark:bg-amber-900/40 dark:text-amber-300",
  "bg-rose-100 text-rose-700 dark:bg-rose-900/40 dark:text-rose-300",
  "bg-emerald-100 text-emerald-700 dark:bg-emerald-900/40 dark:text-emerald-300",
];

function colorForId(id: number) { return COLORS[id % COLORS.length]; }

export default function StudentMyTeamPage() {
  const [team, setTeam] = useState<TeamData | null>(null);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  const load = useCallback(async () => {
    setLoading(true);
    setError(null);
    try {
      const res = await api.get<{ success: boolean; data: TeamData | null }>("/students/my-team");
      setTeam(res.data.data ?? null);
    } catch {
      setError("Could not load team information.");
    } finally {
      setLoading(false);
    }
  }, []);

  useEffect(() => { void load(); }, [load]);

  if (loading) {
    return (
      <div className="flex min-h-[40vh] items-center justify-center">
        <RefreshCw className="h-8 w-8 animate-spin text-primary-600" />
      </div>
    );
  }

  if (error) {
    return (
      <div className="flex items-center gap-2 rounded-xl border border-red-200 bg-red-50 px-4 py-3 text-sm text-red-800 dark:border-red-900/50 dark:bg-red-950/30 dark:text-red-300">
        <AlertCircle className="h-4 w-4 shrink-0" />{error}
      </div>
    );
  }

  if (!team) {
    return (
      <div className="flex flex-col items-center justify-center rounded-2xl border-2 border-dashed border-slate-200 dark:border-slate-700 bg-white dark:bg-slate-900 py-20 text-center">
        <UsersRound className="h-14 w-14 text-slate-300 dark:text-slate-600 mb-4" />
        <p className="text-lg font-semibold text-slate-600 dark:text-slate-400">You are not in a team yet</p>
        <p className="mt-1 text-sm text-slate-400 dark:text-slate-500">Your supervisor will add you to a team once your placement is confirmed.</p>
      </div>
    );
  }

  return (
    <div className="space-y-6 pb-8">
      {/* Header */}
      <div>
        <h1 className="text-2xl font-bold tracking-tight text-slate-900 dark:text-slate-100">My Team</h1>
        <p className="mt-1 text-sm text-slate-500 dark:text-slate-400">Your team details, members, and assigned project.</p>
      </div>

      {/* Team card */}
      <div className="rounded-2xl border border-slate-200 dark:border-slate-700 bg-white dark:bg-slate-900 shadow-sm overflow-hidden">
        {/* Team header */}
        <div className="flex items-center gap-4 border-b border-slate-100 dark:border-slate-700 bg-gradient-to-r from-primary-50 to-slate-50 dark:from-primary-900/20 dark:to-slate-900 px-6 py-5">
          <div className="flex h-14 w-14 shrink-0 items-center justify-center rounded-2xl bg-primary-600 shadow-sm shadow-primary-900/20">
            <UsersRound className="h-7 w-7 text-white" />
          </div>
          <div className="min-w-0">
            <h2 className="text-xl font-bold text-slate-900 dark:text-slate-100">{team.name}</h2>
            <div className="mt-1 flex flex-wrap items-center gap-2">
              {team.isManager && (
                <span className="inline-flex items-center gap-1 rounded-full bg-primary-100 dark:bg-primary-900/40 px-2.5 py-0.5 text-xs font-bold text-primary-700 dark:text-primary-300">
                  <Crown className="h-3 w-3" /> You are the Team Leader
                </span>
              )}
              {team.managerName && !team.isManager && (
                <span className="text-sm text-slate-500 dark:text-slate-400">
                  👑 TL: <span className="font-semibold text-amber-600 dark:text-amber-400">{team.managerName}</span>
                </span>
              )}
            </div>
          </div>
        </div>

        {/* Project info */}
        {team.project && (
          <div className="border-b border-slate-100 dark:border-slate-700 px-6 py-4">
            <div className="flex items-start gap-3">
              <div className="rounded-xl bg-primary-50 dark:bg-primary-900/30 p-2.5 text-primary-600 dark:text-primary-400 shrink-0">
                <FolderKanban className="h-5 w-5" />
              </div>
              <div className="min-w-0">
                <p className="text-xs font-semibold uppercase tracking-wide text-slate-400 dark:text-slate-500">Assigned Project</p>
                <p className="mt-0.5 font-bold text-slate-900 dark:text-slate-100">{team.project.name}</p>
                {team.project.description && (
                  <p className="mt-1 text-sm text-slate-600 dark:text-slate-400">{team.project.description}</p>
                )}
              </div>
            </div>
          </div>
        )}

        {/* Members */}
        <div className="px-6 py-5">
          <p className="mb-4 text-xs font-semibold uppercase tracking-wide text-slate-400 dark:text-slate-500">
            Team Members ({team.members.length})
          </p>
          <div className="space-y-3">
            {team.members.map((m) => (
              <div
                key={m.studentId}
                className={cn(
                  "flex items-center gap-3 rounded-xl border px-4 py-3 transition-colors",
                  m.isMe
                    ? "border-primary-200 bg-primary-50/60 dark:border-primary-800 dark:bg-primary-900/20"
                    : "border-slate-100 dark:border-slate-700 bg-slate-50/60 dark:bg-slate-800/40"
                )}
              >
                <div className={cn(
                  "flex h-10 w-10 shrink-0 items-center justify-center rounded-full text-sm font-bold ring-2 ring-white dark:ring-slate-900",
                  colorForId(m.studentId)
                )}>
                  {initials(m.fullName)}
                </div>
                <div className="min-w-0 flex-1">
                  <div className="flex items-center gap-2 flex-wrap">
                    <p className="font-semibold text-slate-900 dark:text-slate-100">{m.fullName}</p>
                    {m.isMe && (
                      <span className="rounded-full bg-slate-200 dark:bg-slate-700 px-2 py-0.5 text-[10px] font-bold text-slate-600 dark:text-slate-300">You</span>
                    )}
                    {m.isManager && (
                      <span className="inline-flex items-center gap-0.5 rounded-full bg-amber-100 dark:bg-amber-900/40 px-2 py-0.5 text-[10px] font-bold text-amber-700 dark:text-amber-300">
                        <Crown className="h-2.5 w-2.5" /> TL
                      </span>
                    )}
                  </div>
                  <p className="text-xs text-slate-500 dark:text-slate-400">{m.email}</p>
                </div>
                <div className="shrink-0 text-slate-400 dark:text-slate-500">
                  <User className="h-4 w-4" />
                </div>
              </div>
            ))}
          </div>
        </div>
      </div>
    </div>
  );
}
