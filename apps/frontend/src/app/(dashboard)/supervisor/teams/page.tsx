"use client";

import { useCallback, useEffect, useState } from "react";
import api from "@/lib/api/client";
import {
  AlertCircle, UsersRound, Plus, Trash2, UserPlus,
  UserMinus, Users, X, RefreshCw, UserSquare2,
} from "lucide-react";
import { cn } from "@/lib/utils";
import StudentPicker from "@/components/supervisor/StudentPicker";

type Team = {
  id: number;
  name: string;
  members: { student: { id: number; user: { full_name: string; email: string } } }[];
};

type DeletedTeam = { id: number; name: string; deleted_at: string };
type StudentOpt = { student: { id: number; user: { full_name: string; email: string } } };

function initials(name: string) {
  return name.split(/\s+/).map((n) => n[0]).join("").toUpperCase().slice(0, 2);
}

function colorForId(id: number) {
  const colors = [
    "bg-teal-100 text-teal-700",
    "bg-blue-100 text-blue-700",
    "bg-violet-100 text-violet-700",
    "bg-amber-100 text-amber-700",
    "bg-rose-100 text-rose-700",
    "bg-emerald-100 text-emerald-700",
  ];
  return colors[id % colors.length];
}

export default function SupervisorTeamsPage() {
  const [teams, setTeams] = useState<Team[]>([]);
  const [deletedTeams, setDeletedTeams] = useState<DeletedTeam[]>([]);
  const [students, setStudents] = useState<StudentOpt[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);
  const [pick, setPick] = useState<Record<number, string>>({});
  const [assigning, setAssigning] = useState<number | null>(null);

  // Create modal
  const [showCreate, setShowCreate] = useState(false);
  const [newName, setNewName] = useState("");
  const [creating, setCreating] = useState(false);

  const load = useCallback(async () => {
    setLoading(true);
    setError(null);
    try {
      const [t, s] = await Promise.all([
        api.get<{ active: Team[]; deleted: DeletedTeam[] }>("/supervisor/teams"),
        api.get<{ success: boolean; data: StudentOpt[] }>("/supervisor/students"),
      ]);
      setTeams(t.data.active);
      setDeletedTeams(t.data.deleted);
      setStudents(Array.isArray(s.data.data) ? s.data.data : []);
    } catch {
      setError("Could not load teams.");
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
      await api.post("/supervisor/teams", { name: newName.trim() });
      setNewName("");
      setShowCreate(false);
      await load();
    } catch {
      setError("Failed to create team.");
    } finally {
      setCreating(false);
    }
  };

  // Delete confirmation modal
  const [deleteModal, setDeleteModal] = useState<{ id: number; name: string } | null>(null);
  const [deleting, setDeleting] = useState(false);

  const confirmDelete = async () => {
    if (!deleteModal) return;
    setDeleting(true);
    try {
      await api.delete(`/supervisor/teams/${deleteModal.id}`);
      setDeleteModal(null);
      await load();
    } catch {
      setError("Failed to delete team.");
    } finally {
      setDeleting(false);
    }
  };

  const restoreTeam = async (id: number) => {
    try {
      await api.patch(`/supervisor/teams/${id}/restore`);
      await load();
    } catch {
      setError("Failed to restore team.");
    }
  };

  const addMember = async (teamId: number) => {
    const sid = parseInt(pick[teamId] || "", 10);
    if (Number.isNaN(sid)) return;
    setAssigning(teamId);
    try {
      await api.post(`/supervisor/teams/${teamId}/members`, { studentId: sid });
      setPick((p) => ({ ...p, [teamId]: "" }));
      await load();
    } catch {
      setError("Could not add member — they must have an active placement.");
    } finally {
      setAssigning(null);
    }
  };

  const removeMember = async (teamId: number, studentId: number) => {
    try {
      await api.delete(`/supervisor/teams/${teamId}/members/${studentId}`);
      await load();
    } catch {
      setError("Failed to remove member.");
    }
  };

  const availableFor = (team: Team) => {
    const assigned = new Set(team.members.map((m) => m.student.id));
    return students.filter((s) => !assigned.has(s.student.id));
  };

  return (
    <div className="space-y-6 pb-8">
      {/* Header */}
      <div className="flex flex-col gap-4 sm:flex-row sm:items-center sm:justify-between">
        <div>
          <h1 className="text-2xl font-bold tracking-tight text-slate-900 md:text-3xl">Teams</h1>
          <p className="mt-1 text-sm text-slate-500">
            Organize interns into teams and manage group assignments.
          </p>
        </div>
        <div className="flex gap-2">
          <button
            type="button"
            onClick={() => void load()}
            disabled={loading}
            className="inline-flex items-center gap-2 rounded-xl border border-slate-200 bg-white px-4 py-2.5 text-sm font-medium text-slate-700 shadow-sm hover:bg-slate-50 disabled:opacity-60"
          >
            <RefreshCw className={cn("h-4 w-4", loading && "animate-spin")} />
            Refresh
          </button>
          <button
            type="button"
            onClick={() => setShowCreate(true)}
            className="inline-flex items-center gap-2 rounded-xl bg-primary-600 px-4 py-2.5 text-sm font-semibold text-white shadow-sm hover:bg-primary-700"
          >
            <Plus className="h-4 w-4" />
            New team
          </button>
        </div>
      </div>

      {error && (
        <div className="flex items-center gap-2 rounded-xl border border-red-200 bg-red-50 px-4 py-3 text-sm text-red-800">
          <AlertCircle className="h-4 w-4 shrink-0" />
          {error}
          <button type="button" onClick={() => setError(null)} className="ml-auto text-red-400 hover:text-red-600">
            <X className="h-4 w-4" />
          </button>
        </div>
      )}

      {/* Stats bar */}
      {!loading && (
        <div className="grid grid-cols-2 gap-4 sm:grid-cols-3">
          {[
            { label: "Total teams", value: teams.length, icon: UsersRound, color: "bg-primary-50 text-primary-600" },
            { label: "Total students", value: students.length, icon: Users, color: "bg-blue-50 text-blue-600" },
            { label: "Team members", value: teams.reduce((a, t) => a + t.members.length, 0), icon: UserPlus, color: "bg-emerald-50 text-emerald-600" },
          ].map((s) => (
            <div key={s.label} className="flex items-center gap-3 rounded-2xl border border-slate-200 bg-white p-4 shadow-sm">
              <div className={cn("rounded-xl p-2.5", s.color)}>
                <s.icon className="h-5 w-5" />
              </div>
              <div>
                <p className="text-xs font-semibold uppercase tracking-wide text-slate-400">{s.label}</p>
                <p className="text-xl font-bold text-slate-900">{s.value}</p>
              </div>
            </div>
          ))}
        </div>
      )}

      {/* Team cards */}
      {loading ? (
        <div className="flex min-h-[30vh] items-center justify-center text-slate-500">
          <RefreshCw className="h-8 w-8 animate-spin text-primary-600" />
        </div>
      ) : teams.length === 0 ? (
        <div className="flex flex-col items-center justify-center rounded-2xl border-2 border-dashed border-slate-200 bg-white py-16 text-center">
          <UserSquare2 className="h-12 w-12 text-slate-300 mb-3" />
          <p className="text-base font-semibold text-slate-600">No teams yet</p>
          <p className="text-sm text-slate-400 mt-1">Create your first team to start organizing interns.</p>
          <button
            type="button"
            onClick={() => setShowCreate(true)}
            className="mt-4 inline-flex items-center gap-2 rounded-xl bg-primary-600 px-4 py-2.5 text-sm font-semibold text-white hover:bg-primary-700"
          >
            <Plus className="h-4 w-4" />
            Create team
          </button>
        </div>
      ) : (
        <div className="grid gap-5 sm:grid-cols-2 xl:grid-cols-3">
          {teams.map((team) => {
            const available = availableFor(team);
            return (
              <div key={team.id} className="flex flex-col rounded-2xl border border-slate-200 bg-white shadow-sm transition-shadow hover:shadow-md">
                {/* Card header */}
                <div className="flex items-start justify-between gap-3 border-b border-slate-100 px-5 py-4">
                  <div className="flex items-center gap-3 min-w-0">
                    <div className="rounded-xl bg-primary-50 p-2.5 text-primary-600 shrink-0">
                      <UsersRound className="h-5 w-5" />
                    </div>
                    <div className="min-w-0">
                      <h2 className="truncate font-bold text-slate-900">{team.name}</h2>
                      <p className="text-xs text-slate-400">
                        {team.members.length} member{team.members.length !== 1 ? "s" : ""}
                      </p>
                    </div>
                  </div>
                  <button
                    type="button"
                    onClick={() => setDeleteModal({ id: team.id, name: team.name })}
                    className="shrink-0 rounded-lg p-1.5 text-slate-400 hover:bg-red-50 hover:text-red-600 transition-colors"
                    aria-label="Delete team"
                  >
                    <Trash2 className="h-4 w-4" />
                  </button>
                </div>

                {/* Member avatars row */}
                {team.members.length > 0 && (
                  <div className="flex items-center gap-1 px-5 pt-3">
                    {team.members.slice(0, 5).map((m) => (
                      <div
                        key={m.student.id}
                        title={m.student.user.full_name}
                        className={cn("flex h-8 w-8 items-center justify-center rounded-full text-xs font-bold ring-2 ring-white", colorForId(m.student.id))}
                      >
                        {initials(m.student.user.full_name)}
                      </div>
                    ))}
                    {team.members.length > 5 && (
                      <div className="flex h-8 w-8 items-center justify-center rounded-full bg-slate-100 text-xs font-bold text-slate-600 ring-2 ring-white">
                        +{team.members.length - 5}
                      </div>
                    )}
                  </div>
                )}

                {/* Members list */}
                <div className="flex-1 px-5 py-3 space-y-2">
                  {team.members.length === 0 ? (
                    <p className="text-sm text-slate-400 italic">No members yet.</p>
                  ) : (
                    team.members.map((m) => (
                      <div key={m.student.id} className="flex items-center justify-between gap-2 rounded-xl bg-slate-50 px-3 py-2">
                        <div className="flex items-center gap-2.5 min-w-0">
                          <div className={cn("flex h-8 w-8 shrink-0 items-center justify-center rounded-full text-xs font-bold", colorForId(m.student.id))}>
                            {initials(m.student.user.full_name)}
                          </div>
                          <div className="min-w-0">
                            <p className="truncate text-sm font-semibold text-slate-900">{m.student.user.full_name}</p>
                            <p className="truncate text-xs text-slate-500">{m.student.user.email}</p>
                          </div>
                        </div>
                        <button
                          type="button"
                          onClick={() => void removeMember(team.id, m.student.id)}
                          className="shrink-0 rounded-lg p-1.5 text-slate-400 hover:bg-red-50 hover:text-red-600 transition-colors"
                          aria-label="Remove member"
                        >
                          <UserMinus className="h-3.5 w-3.5" />
                        </button>
                      </div>
                    ))
                  )}
                </div>

                {/* Add member */}
                <div className="border-t border-slate-100 px-5 py-3">
                  <div className="flex gap-2">
                    <StudentPicker
                      students={available.map((s) => s.student)}
                      value={pick[team.id] ?? ""}
                      onChange={(val) => setPick((p) => ({ ...p, [team.id]: val }))}
                      placeholder="Add member…"
                    />
                    <button
                      type="button"
                      onClick={() => void addMember(team.id)}
                      disabled={!pick[team.id] || assigning === team.id}
                      className="inline-flex items-center gap-1.5 rounded-xl bg-primary-600 px-3 py-2 text-xs font-semibold text-white hover:bg-primary-700 disabled:opacity-50 disabled:cursor-not-allowed transition-colors"
                    >
                      <UserPlus className="h-3.5 w-3.5" />
                      Add
                    </button>
                  </div>
                  {available.length === 0 && (
                    <p className="mt-1.5 text-xs text-slate-400">All active students are already in this team.</p>
                  )}
                </div>
              </div>
            );
          })}
        </div>
      )}

      {/* Recently deleted */}
      {deletedTeams.length > 0 && (
        <section className="rounded-2xl border border-slate-200 bg-white p-5 shadow-sm">
          <h2 className="text-sm font-bold text-slate-500 uppercase tracking-wide mb-3">🗑️ Recently deleted</h2>
          <p className="text-xs text-slate-400 mb-4">Teams are permanently deleted after 24 hours. Restore them before then.</p>
          <div className="space-y-2">
            {deletedTeams.map((t) => {
              const deletedAt = new Date(t.deleted_at);
              const expiresAt = new Date(deletedAt.getTime() + 24 * 60 * 60 * 1000);
              const msLeft = expiresAt.getTime() - Date.now();
              const hLeft = Math.max(0, Math.floor(msLeft / 3600000));
              const mLeft = Math.max(0, Math.floor((msLeft % 3600000) / 60000));
              return (
                <div key={t.id} className="flex items-center justify-between gap-3 rounded-xl border border-slate-100 bg-slate-50 px-4 py-3">
                  <div>
                    <p className="font-semibold text-slate-700 text-sm">{t.name}</p>
                    <p className="text-xs text-slate-400">Expires in {hLeft}h {mLeft}m</p>
                  </div>
                  <button
                    type="button"
                    onClick={() => void restoreTeam(t.id)}
                    className="inline-flex items-center gap-1.5 rounded-lg border border-primary-200 bg-primary-50 px-3 py-1.5 text-xs font-semibold text-primary-700 hover:bg-primary-100 transition-colors"
                  >
                    Restore
                  </button>
                </div>
              );
            })}
          </div>
        </section>
      )}

      {/* Create team modal */}
      {showCreate && (
        <div className="fixed inset-0 z-50 flex items-center justify-center bg-black/40 backdrop-blur-sm">
          <div className="w-full max-w-sm rounded-2xl bg-white p-6 shadow-xl mx-4 space-y-4">
            <div className="flex items-center justify-between">
              <h3 className="text-lg font-bold text-slate-900">New team</h3>
              <button type="button" onClick={() => setShowCreate(false)} className="rounded-lg p-1.5 text-slate-400 hover:bg-slate-100">
                <X className="h-5 w-5" />
              </button>
            </div>
            <form onSubmit={(e) => void create(e)} className="space-y-4">
              <div>
                <label className="text-sm font-medium text-slate-700">Team name</label>
                <input
                  autoFocus
                  required
                  value={newName}
                  onChange={(e) => setNewName(e.target.value)}
                  placeholder="e.g. Frontend Team"
                  className="mt-1.5 w-full rounded-xl border border-slate-200 px-4 py-2.5 text-sm text-slate-900 focus:outline-none focus:ring-2 focus:ring-primary-500/20 focus:border-primary-500"
                />
              </div>
              <div className="flex gap-3 pt-1">
                <button type="button" onClick={() => setShowCreate(false)}
                  className="flex-1 rounded-xl border border-slate-200 py-2.5 text-sm font-semibold text-slate-600 hover:bg-slate-50">
                  Cancel
                </button>
                <button type="submit" disabled={creating || !newName.trim()}
                  className="flex-1 rounded-xl bg-primary-600 py-2.5 text-sm font-semibold text-white hover:bg-primary-700 disabled:opacity-60">
                  {creating ? "Creating…" : "Create team"}
                </button>
              </div>
            </form>
          </div>
        </div>
      )}
      {/* Delete confirmation modal */}
      {deleteModal && (
        <div className="fixed inset-0 z-50 flex items-center justify-center bg-black/40 backdrop-blur-sm">
          <div className="w-full max-w-sm rounded-2xl bg-white p-6 shadow-xl mx-4 space-y-4">
            <div className="flex items-center gap-3">
              <div className="rounded-xl bg-red-50 p-2.5 text-red-600">
                <Trash2 className="h-5 w-5" />
              </div>
              <h3 className="text-lg font-bold text-slate-900">Delete team?</h3>
            </div>
            <p className="text-sm text-slate-500">
              <strong>"{deleteModal.name}"</strong> will be moved to trash. You have <strong>24 hours</strong> to restore it before it's permanently deleted.
            </p>
            <div className="flex gap-3 pt-1">
              <button type="button" onClick={() => setDeleteModal(null)}
                className="flex-1 rounded-xl border border-slate-200 py-2.5 text-sm font-semibold text-slate-600 hover:bg-slate-50">
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
