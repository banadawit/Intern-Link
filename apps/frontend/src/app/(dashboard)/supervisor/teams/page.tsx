"use client";

import { useCallback, useEffect, useState } from "react";
import api from "@/lib/api/client";
import { AlertCircle, Trash2 } from "lucide-react";

type Team = {
  id: number;
  name: string;
  members: { student: { id: number; user: { full_name: string; email: string } } }[];
};

type StudentOpt = { student: { id: number; user: { full_name: string; email: string } } };

export default function SupervisorTeamsPage() {
  const [teams, setTeams] = useState<Team[]>([]);
  const [students, setStudents] = useState<StudentOpt[]>([]);
  const [name, setName] = useState("");
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);
  const [pick, setPick] = useState<Record<number, string>>({});

  const load = useCallback(async () => {
    setLoading(true);
    setError(null);
    try {
      const [t, s] = await Promise.all([
        api.get<Team[]>("/supervisor/teams"),
        api.get<StudentOpt[]>("/supervisor/students"),
      ]);
      setTeams(t.data);
      setStudents(s.data);
    } catch {
      setError("Could not load teams.");
    } finally {
      setLoading(false);
    }
  }, []);

  useEffect(() => {
    void load();
  }, [load]);

  const create = async () => {
    if (!name.trim()) return;
    try {
      await api.post("/supervisor/teams", { name: name.trim() });
      setName("");
      await load();
    } catch {
      setError("Failed to create team.");
    }
  };

  const removeTeam = async (id: number) => {
    if (!confirm("Delete this team?")) return;
    try {
      await api.delete(`/supervisor/teams/${id}`);
      await load();
    } catch {
      setError("Failed to delete team.");
    }
  };

  const addMember = async (teamId: number) => {
    const sid = parseInt(pick[teamId] || "", 10);
    if (Number.isNaN(sid)) return;
    try {
      await api.post(`/supervisor/teams/${teamId}/members`, { studentId: sid });
      setPick((p) => ({ ...p, [teamId]: "" }));
      await load();
    } catch {
      setError("Could not add member (must be an active placement).");
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

  return (
    <div className="space-y-6">
      <div>
        <h1 className="text-2xl font-bold text-slate-900">Teams</h1>
        <p className="mt-1 text-sm text-slate-500">Organize interns into teams at your company.</p>
      </div>

      {error && (
        <div className="flex items-center gap-2 rounded-xl border border-red-200 bg-red-50 px-4 py-3 text-sm text-red-800">
          <AlertCircle className="h-4 w-4 shrink-0" />
          {error}
        </div>
      )}

      <div className="flex flex-wrap gap-2 rounded-2xl border border-slate-200 bg-white p-4 shadow-sm">
        <input
          value={name}
          onChange={(e) => setName(e.target.value)}
          placeholder="New team name"
          className="min-w-[200px] flex-1 rounded-xl border border-slate-200 px-3 py-2 text-sm"
        />
        <button
          type="button"
          onClick={() => void create()}
          className="rounded-xl bg-primary-600 px-4 py-2 text-sm font-semibold text-white hover:bg-primary-700"
        >
          Create team
        </button>
      </div>

      {loading ? (
        <p className="text-slate-500">Loading…</p>
      ) : (
        <div className="space-y-4">
          {teams.map((team) => (
            <div
              key={team.id}
              className="rounded-2xl border border-slate-200 bg-white p-5 shadow-sm"
            >
              <div className="flex items-start justify-between gap-4">
                <h2 className="text-lg font-bold text-slate-900">{team.name}</h2>
                <button
                  type="button"
                  onClick={() => void removeTeam(team.id)}
                  className="rounded-lg p-2 text-red-600 hover:bg-red-50"
                  aria-label="Delete team"
                >
                  <Trash2 className="h-4 w-4" />
                </button>
              </div>
              <ul className="mt-3 space-y-1 text-sm text-slate-700">
                {team.members.length === 0 ? (
                  <li className="text-slate-400">No members yet.</li>
                ) : (
                  team.members.map((m) => (
                    <li key={m.student.id} className="flex items-center justify-between gap-2">
                      <span>
                        {m.student.user.full_name}{" "}
                        <span className="text-xs text-slate-500">({m.student.user.email})</span>
                      </span>
                      <button
                        type="button"
                        onClick={() => void removeMember(team.id, m.student.id)}
                        className="text-xs font-semibold text-red-600 hover:underline"
                      >
                        Remove
                      </button>
                    </li>
                  ))
                )}
              </ul>
              <div className="mt-4 flex flex-wrap gap-2">
                <select
                  value={pick[team.id] ?? ""}
                  onChange={(e) => setPick((p) => ({ ...p, [team.id]: e.target.value }))}
                  className="rounded-lg border border-slate-200 px-2 py-2 text-sm"
                >
                  <option value="">Add student…</option>
                  {students.map((s) => (
                    <option key={s.student.id} value={String(s.student.id)}>
                      {s.student.user.full_name}
                    </option>
                  ))}
                </select>
                <button
                  type="button"
                  onClick={() => void addMember(team.id)}
                  className="rounded-lg border border-slate-200 px-3 py-2 text-xs font-semibold hover:bg-slate-50"
                >
                  Add to team
                </button>
              </div>
            </div>
          ))}
          {teams.length === 0 && <p className="text-slate-500">No teams yet.</p>}
        </div>
      )}
    </div>
  );
}
