"use client";

import { useCallback, useEffect, useState } from "react";
import api from "@/lib/api/client";
import {
  AlertCircle, FolderKanban, Plus, Trash2,
  Users, X, RefreshCw, FolderOpen, UsersRound, UserMinus, Crown,
} from "lucide-react";
import { cn } from "@/lib/utils";

type TeamMember = {
  studentId: number;
  student: { id: number; user: { full_name: string; email: string } };
};

type Team = {
  id: number;
  name: string;
  managerId: number | null;
  members: TeamMember[];
};

type Project = {
  id: number;
  name: string;
  teams: Team[];
};

type DeletedProject = { id: number; name: string; deleted_at: string };

function initials(name: string) {
  return name.split(/\s+/).map((n) => n[0]).join("").toUpperCase().slice(0, 2);
}

const COLORS = [
  "bg-teal-100 text-teal-700",
  "bg-blue-100 text-blue-700",
  "bg-violet-100 text-violet-700",
  "bg-amber-100 text-amber-700",
  "bg-rose-100 text-rose-700",
  "bg-emerald-100 text-emerald-700",
];
function colorForId(id: number) { return COLORS[id % COLORS.length]; }

export default function SupervisorProjectsPage() {
  const [projects, setProjects] = useState<Project[]>([]);
  const [deletedProjects, setDeletedProjects] = useState<DeletedProject[]>([]);
  const [allTeams, setAllTeams] = useState<Team[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  // Per-project selected team to assign
  const [pick, setPick] = useState<Record<number, string>>({});
  const [assigning, setAssigning] = useState<number | null>(null);
  const [unassigning, setUnassigning] = useState<number | null>(null);

  // Create modal
  const [showCreate, setShowCreate] = useState(false);
  const [newName, setNewName] = useState("");
  const [creating, setCreating] = useState(false);

  // Delete modal
  const [deleteModal, setDeleteModal] = useState<{ id: number; name: string } | null>(null);
  const [deleting, setDeleting] = useState(false);

  const load = useCallback(async () => {
    setLoading(true);
    setError(null);
    try {
      const [p, t] = await Promise.all([
        api.get<{ success: boolean; data: { active: Project[]; deleted: DeletedProject[] } }>("/supervisor/projects"),
        api.get<{ success: boolean; data: { active: Team[] } }>("/supervisor/teams"),
      ]);
      setProjects(p.data.data?.active ?? []);
      setDeletedProjects(p.data.data?.deleted ?? []);
      setAllTeams(t.data.data?.active ?? []);
    } catch {
      setError("Could not load projects.");
    } finally {
      setLoading(false);
    }
  }, []);

  useEffect(() => { void load(); }, [load]);

  const create = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!newName.trim()) return;
    setCreating(true);
    try {
      await api.post("/supervisor/projects", { name: newName.trim() });
      setNewName("");
      setShowCreate(false);
      await load();
    } catch {
      setError("Failed to create project.");
    } finally {
      setCreating(false);
    }
  };

  const confirmDelete = async () => {
    if (!deleteModal) return;
    setDeleting(true);
    try {
      await api.delete(`/supervisor/projects/${deleteModal.id}`);
      setDeleteModal(null);
      await load();
    } catch {
      setError("Failed to delete project.");
    } finally {
      setDeleting(false);
    }
  };

  const restoreProject = async (id: number) => {
    try {
      await api.patch(`/supervisor/projects/${id}/restore`);
      await load();
    } catch {
      setError("Failed to restore project.");
    }
  };

  /** Assign a team to a project via moveTeamToProject */
  const assignTeam = async (projectId: number) => {
    const teamId = parseInt(pick[projectId] || "", 10);
    if (Number.isNaN(teamId)) return;
    setAssigning(projectId);
    try {
      await api.patch(`/supervisor/assignments/teams/${teamId}/project`, { projectId });
      setPick((p) => ({ ...p, [projectId]: "" }));
      await load();
    } catch (err: unknown) {
      const msg = (err as { response?: { data?: { message?: string } } })?.response?.data?.message;
      setError(msg ?? "Could not assign team to project.");
    } finally {
      setAssigning(null);
    }
  };

  /** Unassign a team from its project */
  const unassignTeam = async (projectId: number, teamId: number) => {
    setUnassigning(teamId);
    try {
      await api.patch(`/supervisor/projects/${projectId}/teams/${teamId}`);
      await load();
    } catch {
      setError("Failed to unassign team.");
    } finally {
      setUnassigning(null);
    }
  };

  // Teams not yet assigned to any project
  const assignedTeamIds = new Set(projects.flatMap((p) => p.teams.map((t) => t.id)));
  const availableTeamsFor = (proj: Project) => {
    const inThisProject = new Set(proj.teams.map((t) => t.id));
    return allTeams.filter((t) => !assignedTeamIds.has(t.id) || inThisProject.has(t.id))
      .filter((t) => !inThisProject.has(t.id));
  };

  const totalMembers = projects.reduce((a, p) => a + p.teams.reduce((b, t) => b + t.members.length, 0), 0);

  return (
    <div className="space-y-6 pb-8">
      {/* Header */}
      <div className="flex flex-col gap-4 sm:flex-row sm:items-center sm:justify-between">
        <div>
          <h1 className="text-2xl font-bold tracking-tight text-slate-900 dark:text-slate-100 md:text-3xl">Projects</h1>
          <p className="mt-1 text-sm text-slate-500 dark:text-slate-400">
            Manage internship projects and assign teams to each one.
          </p>
        </div>
        <div className="flex gap-2">
          <button type="button" onClick={() => void load()} disabled={loading}
            className="inline-flex items-center gap-2 rounded-xl border border-slate-200 dark:border-slate-700 bg-white dark:bg-slate-900 px-4 py-2.5 text-sm font-medium text-slate-700 dark:text-slate-200 shadow-sm hover:bg-slate-50 dark:hover:bg-slate-800 disabled:opacity-60">
            <RefreshCw className={cn("h-4 w-4", loading && "animate-spin")} />
            Refresh
          </button>
          <button type="button" onClick={() => setShowCreate(true)}
            className="inline-flex items-center gap-2 rounded-xl bg-primary-600 px-4 py-2.5 text-sm font-semibold text-white shadow-sm hover:bg-primary-700">
            <Plus className="h-4 w-4" />
            New project
          </button>
        </div>
      </div>

      {error && (
        <div className="flex items-center gap-2 rounded-xl border border-red-200 dark:border-red-800 bg-red-50 dark:bg-red-950/20 px-4 py-3 text-sm text-red-800 dark:text-red-300">
          <AlertCircle className="h-4 w-4 shrink-0" />
          {error}
          <button type="button" onClick={() => setError(null)} className="ml-auto text-red-400 hover:text-red-600">
            <X className="h-4 w-4" />
          </button>
        </div>
      )}

      {/* Stats */}
      {!loading && (
        <div className="grid grid-cols-2 gap-4 sm:grid-cols-3">
          {[
            { label: "Total projects", value: projects.length, icon: FolderKanban, color: "bg-primary-50 text-primary-600" },
            { label: "Assigned teams", value: projects.reduce((a, p) => a + p.teams.length, 0), icon: UsersRound, color: "bg-blue-50 text-blue-600" },
            { label: "Total members", value: totalMembers, icon: Users, color: "bg-emerald-50 text-emerald-600" },
          ].map((s) => (
            <div key={s.label} className="flex items-center gap-3 rounded-2xl border border-slate-200 dark:border-slate-700 bg-white dark:bg-slate-900 p-4 shadow-sm">
              <div className={cn("rounded-xl p-2.5", s.color)}>
                <s.icon className="h-5 w-5" />
              </div>
              <div>
                <p className="text-xs font-semibold uppercase tracking-wide text-slate-400 dark:text-slate-500">{s.label}</p>
                <p className="text-xl font-bold text-slate-900 dark:text-slate-100">{s.value}</p>
              </div>
            </div>
          ))}
        </div>
      )}

      {/* Project cards */}
      {loading ? (
        <div className="flex min-h-[30vh] items-center justify-center">
          <RefreshCw className="h-8 w-8 animate-spin text-primary-600" />
        </div>
      ) : projects.length === 0 ? (
        <div className="flex flex-col items-center justify-center rounded-2xl border-2 border-dashed border-slate-200 dark:border-slate-700 bg-white dark:bg-slate-900 py-16 text-center">
          <FolderOpen className="h-12 w-12 text-slate-300 dark:text-slate-600 mb-3" />
          <p className="text-base font-semibold text-slate-600 dark:text-slate-400">No projects yet</p>
          <p className="text-sm text-slate-400 dark:text-slate-500 mt-1">Create your first project to start assigning teams.</p>
          <button type="button" onClick={() => setShowCreate(true)}
            className="mt-4 inline-flex items-center gap-2 rounded-xl bg-primary-600 px-4 py-2.5 text-sm font-semibold text-white hover:bg-primary-700">
            <Plus className="h-4 w-4" />
            Create project
          </button>
        </div>
      ) : (
        <div className="grid gap-5 sm:grid-cols-2 xl:grid-cols-3">
          {projects.map((proj) => {
            const available = availableTeamsFor(proj);
            const memberCount = proj.teams.reduce((a, t) => a + t.members.length, 0);
            return (
              <div key={proj.id} className="flex flex-col rounded-2xl border border-slate-200 dark:border-slate-700 bg-white dark:bg-slate-900 shadow-sm transition-shadow hover:shadow-md">
                {/* Card header */}
                <div className="flex items-start justify-between gap-3 border-b border-slate-100 dark:border-slate-700 px-5 py-4">
                  <div className="flex items-center gap-3 min-w-0">
                    <div className="rounded-xl bg-primary-50 p-2.5 text-primary-600 shrink-0">
                      <FolderKanban className="h-5 w-5" />
                    </div>
                    <div className="min-w-0">
                      <h2 className="truncate font-bold text-slate-900 dark:text-slate-100">{proj.name}</h2>
                      <p className="text-xs text-slate-400 dark:text-slate-500">
                        {proj.teams.length} team{proj.teams.length !== 1 ? "s" : ""} · {memberCount} member{memberCount !== 1 ? "s" : ""}
                      </p>
                    </div>
                  </div>
                  <button type="button" onClick={() => setDeleteModal({ id: proj.id, name: proj.name })}
                    className="shrink-0 rounded-lg p-1.5 text-slate-400 hover:bg-red-50 hover:text-red-600 transition-colors"
                    aria-label="Delete project">
                    <Trash2 className="h-4 w-4" />
                  </button>
                </div>

                {/* Assigned teams */}
                <div className="flex-1 px-5 py-4 space-y-3">
                  {proj.teams.length === 0 ? (
                    <p className="text-sm text-slate-400 dark:text-slate-500 italic">No teams assigned yet.</p>
                  ) : (
                    proj.teams.map((team) => (
                      <div key={team.id} className="rounded-xl border border-slate-200 dark:border-slate-700 bg-slate-50 dark:bg-slate-800 px-3 py-2.5">
                        {/* Team header */}
                        <div className="flex items-center justify-between gap-2 mb-2">
                          <div className="flex items-center gap-2 min-w-0">
                            <UsersRound className="h-4 w-4 shrink-0 text-primary-500" />
                            <span className="font-semibold text-sm text-slate-900 dark:text-slate-100 truncate">{team.name}</span>
                          </div>
                          <button type="button"
                            disabled={unassigning === team.id}
                            onClick={() => void unassignTeam(proj.id, team.id)}
                            className="shrink-0 rounded-lg p-1 text-slate-400 hover:bg-red-50 hover:text-red-600 transition-colors disabled:opacity-40"
                            aria-label="Unassign team">
                            {unassigning === team.id
                              ? <RefreshCw className="h-3.5 w-3.5 animate-spin" />
                              : <UserMinus className="h-3.5 w-3.5" />
                            }
                          </button>
                        </div>
                        {/* Team members */}
                        <div className="flex flex-wrap gap-1.5">
                          {team.members.map((m) => (
                            <div key={m.studentId} className="flex items-center gap-1.5 rounded-lg bg-white dark:bg-slate-900 border border-slate-200 dark:border-slate-700 px-2 py-1">
                              <div className={cn("flex h-5 w-5 shrink-0 items-center justify-center rounded-full text-[9px] font-bold", colorForId(m.studentId))}>
                                {initials(m.student.user.full_name)}
                              </div>
                              <span className="text-xs text-slate-700 dark:text-slate-300 font-medium">{m.student.user.full_name}</span>
                              {team.managerId === m.studentId && (
                                <Crown className="h-3 w-3 text-amber-500 shrink-0" />
                              )}
                            </div>
                          ))}
                          {team.members.length === 0 && (
                            <p className="text-xs text-slate-400 dark:text-slate-500 italic">No members yet</p>
                          )}
                        </div>
                      </div>
                    ))
                  )}
                </div>

                {/* Assign team */}
                <div className="border-t border-slate-100 dark:border-slate-700 px-5 py-3">
                  <div className="flex gap-2">
                    <select
                      value={pick[proj.id] ?? ""}
                      onChange={(e) => setPick((p) => ({ ...p, [proj.id]: e.target.value }))}
                      className="flex-1 rounded-xl border border-slate-200 dark:border-slate-700 bg-white dark:bg-slate-900 px-3 py-2 text-sm text-slate-900 dark:text-slate-100 focus:outline-none focus:ring-2 focus:ring-primary-500/20"
                    >
                      <option value="">Assign team…</option>
                      {available.map((t) => (
                        <option key={t.id} value={t.id}>
                          {t.name} ({t.members.length} member{t.members.length !== 1 ? "s" : ""})
                        </option>
                      ))}
                    </select>
                    <button type="button"
                      onClick={() => void assignTeam(proj.id)}
                      disabled={!pick[proj.id] || assigning === proj.id}
                      className="inline-flex items-center gap-1.5 rounded-xl bg-primary-600 px-3 py-2 text-xs font-semibold text-white hover:bg-primary-700 disabled:opacity-50 disabled:cursor-not-allowed transition-colors">
                      {assigning === proj.id ? <RefreshCw className="h-3.5 w-3.5 animate-spin" /> : <Plus className="h-3.5 w-3.5" />}
                      Assign
                    </button>
                  </div>
                  {available.length === 0 && (
                    <p className="mt-1.5 text-xs text-slate-400 dark:text-slate-500">All teams are already assigned to projects.</p>
                  )}
                </div>
              </div>
            );
          })}
        </div>
      )}

      {/* Recently deleted */}
      {deletedProjects.length > 0 && (
        <section className="rounded-2xl border border-slate-200 dark:border-slate-700 bg-white dark:bg-slate-900 p-5 shadow-sm">
          <h2 className="text-sm font-bold text-slate-500 dark:text-slate-400 uppercase tracking-wide mb-3">🗑️ Recently deleted</h2>
          <p className="text-xs text-slate-400 dark:text-slate-500 mb-4">Projects are permanently deleted after 24 hours.</p>
          <div className="space-y-2">
            {deletedProjects.map((p) => {
              const deletedAt = new Date(p.deleted_at);
              const expiresAt = new Date(deletedAt.getTime() + 24 * 60 * 60 * 1000);
              const msLeft = expiresAt.getTime() - Date.now();
              const hLeft = Math.max(0, Math.floor(msLeft / 3600000));
              const mLeft = Math.max(0, Math.floor((msLeft % 3600000) / 60000));
              return (
                <div key={p.id} className="flex items-center justify-between gap-3 rounded-xl border border-slate-100 dark:border-slate-700 bg-slate-50 dark:bg-slate-800 px-4 py-3">
                  <div>
                    <p className="font-semibold text-slate-700 dark:text-slate-300 text-sm">{p.name}</p>
                    <p className="text-xs text-slate-400 dark:text-slate-500">Expires in {hLeft}h {mLeft}m</p>
                  </div>
                  <button type="button" onClick={() => void restoreProject(p.id)}
                    className="inline-flex items-center gap-1.5 rounded-lg border border-primary-200 bg-primary-50 px-3 py-1.5 text-xs font-semibold text-primary-700 hover:bg-primary-100 transition-colors">
                    Restore
                  </button>
                </div>
              );
            })}
          </div>
        </section>
      )}

      {/* Create project modal */}
      {showCreate && (
        <div className="fixed inset-0 z-50 flex items-center justify-center bg-black/40 backdrop-blur-sm">
          <div className="w-full max-w-sm rounded-2xl bg-white dark:bg-slate-900 p-6 shadow-xl mx-4 space-y-4">
            <div className="flex items-center justify-between">
              <h3 className="text-lg font-bold text-slate-900 dark:text-slate-100">New project</h3>
              <button type="button" onClick={() => setShowCreate(false)} className="rounded-lg p-1.5 text-slate-400 hover:bg-slate-100 dark:hover:bg-slate-800">
                <X className="h-5 w-5" />
              </button>
            </div>
            <form onSubmit={(e) => void create(e)} className="space-y-4">
              <div>
                <label className="text-sm font-medium text-slate-700 dark:text-slate-300">Project name</label>
                <input autoFocus required value={newName} onChange={(e) => setNewName(e.target.value)}
                  placeholder="e.g. Web Portal Development"
                  className="mt-1.5 w-full rounded-xl border border-slate-200 dark:border-slate-700 bg-white dark:bg-slate-900 px-4 py-2.5 text-sm text-slate-900 dark:text-slate-100 focus:outline-none focus:ring-2 focus:ring-primary-500/20 focus:border-primary-500" />
              </div>
              <div className="flex gap-3 pt-1">
                <button type="button" onClick={() => setShowCreate(false)}
                  className="flex-1 rounded-xl border border-slate-200 dark:border-slate-700 py-2.5 text-sm font-semibold text-slate-600 dark:text-slate-300 hover:bg-slate-50 dark:hover:bg-slate-800">
                  Cancel
                </button>
                <button type="submit" disabled={creating || !newName.trim()}
                  className="flex-1 rounded-xl bg-primary-600 py-2.5 text-sm font-semibold text-white hover:bg-primary-700 disabled:opacity-60">
                  {creating ? "Creating…" : "Create project"}
                </button>
              </div>
            </form>
          </div>
        </div>
      )}

      {/* Delete confirmation modal */}
      {deleteModal && (
        <div className="fixed inset-0 z-50 flex items-center justify-center bg-black/40 backdrop-blur-sm">
          <div className="w-full max-w-sm rounded-2xl bg-white dark:bg-slate-900 p-6 shadow-xl mx-4 space-y-4">
            <div className="flex items-center gap-3">
              <div className="rounded-xl bg-red-50 p-2.5 text-red-600">
                <Trash2 className="h-5 w-5" />
              </div>
              <h3 className="text-lg font-bold text-slate-900 dark:text-slate-100">Delete project?</h3>
            </div>
            <p className="text-sm text-slate-500 dark:text-slate-400">
              <strong>"{deleteModal.name}"</strong> will be moved to trash. You have <strong>24 hours</strong> to restore it.
            </p>
            <div className="flex gap-3 pt-1">
              <button type="button" onClick={() => setDeleteModal(null)}
                className="flex-1 rounded-xl border border-slate-200 dark:border-slate-700 py-2.5 text-sm font-semibold text-slate-600 dark:text-slate-300 hover:bg-slate-50 dark:hover:bg-slate-800">
                Cancel
              </button>
              <button type="button" onClick={() => void confirmDelete()} disabled={deleting}
                className="flex-1 rounded-xl bg-red-600 py-2.5 text-sm font-semibold text-white hover:bg-red-700 disabled:opacity-60">
                {deleting ? "Deleting…" : "Move to trash"}
              </button>
            </div>
          </div>
        </div>
      )}
    </div>
  );
}
