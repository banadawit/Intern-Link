"use client";

import { useCallback, useEffect, useState } from "react";
import api from "@/lib/api/client";
import { AlertCircle, Trash2 } from "lucide-react";

type Project = {
  id: number;
  name: string;
  students: { student: { id: number; user: { full_name: string; email: string } } }[];
};

type StudentOpt = { student: { id: number; user: { full_name: string; email: string } } };

export default function SupervisorProjectsPage() {
  const [projects, setProjects] = useState<Project[]>([]);
  const [students, setStudents] = useState<StudentOpt[]>([]);
  const [name, setName] = useState("");
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);
  const [pick, setPick] = useState<Record<number, string>>({});

  const load = useCallback(async () => {
    setLoading(true);
    setError(null);
    try {
      const [p, s] = await Promise.all([
        api.get<Project[]>("/supervisor/projects"),
        api.get<StudentOpt[]>("/supervisor/students"),
      ]);
      setProjects(p.data);
      setStudents(s.data);
    } catch {
      setError("Could not load projects.");
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
      await api.post("/supervisor/projects", { name: name.trim() });
      setName("");
      await load();
    } catch {
      setError("Failed to create project.");
    }
  };

  const removeProject = async (id: number) => {
    if (!confirm("Delete this project?")) return;
    try {
      await api.delete(`/supervisor/projects/${id}`);
      await load();
    } catch {
      setError("Failed to delete project.");
    }
  };

  const addMember = async (projectId: number) => {
    const sid = parseInt(pick[projectId] || "", 10);
    if (Number.isNaN(sid)) return;
    try {
      await api.post(`/supervisor/projects/${projectId}/members`, { studentId: sid });
      setPick((p) => ({ ...p, [projectId]: "" }));
      await load();
    } catch {
      setError("Could not add student (must be an active placement).");
    }
  };

  const removeMember = async (projectId: number, studentId: number) => {
    try {
      await api.delete(`/supervisor/projects/${projectId}/members/${studentId}`);
      await load();
    } catch {
      setError("Failed to remove student.");
    }
  };

  return (
    <div className="space-y-6">
      <div>
        <h1 className="text-2xl font-bold text-slate-900">Projects</h1>
        <p className="mt-1 text-sm text-slate-500">Shared projects for interns at your company.</p>
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
          placeholder="New project name"
          className="min-w-[200px] flex-1 rounded-xl border border-slate-200 px-3 py-2 text-sm"
        />
        <button
          type="button"
          onClick={() => void create()}
          className="rounded-xl bg-primary-600 px-4 py-2 text-sm font-semibold text-white hover:bg-primary-700"
        >
          Create project
        </button>
      </div>

      {loading ? (
        <p className="text-slate-500">Loading…</p>
      ) : (
        <div className="space-y-4">
          {projects.map((proj) => (
            <div
              key={proj.id}
              className="rounded-2xl border border-slate-200 bg-white p-5 shadow-sm"
            >
              <div className="flex items-start justify-between gap-4">
                <h2 className="text-lg font-bold text-slate-900">{proj.name}</h2>
                <button
                  type="button"
                  onClick={() => void removeProject(proj.id)}
                  className="rounded-lg p-2 text-red-600 hover:bg-red-50"
                  aria-label="Delete project"
                >
                  <Trash2 className="h-4 w-4" />
                </button>
              </div>
              <ul className="mt-3 space-y-1 text-sm text-slate-700">
                {proj.students.length === 0 ? (
                  <li className="text-slate-400">No students linked yet.</li>
                ) : (
                  proj.students.map((m) => (
                    <li key={m.student.id} className="flex items-center justify-between gap-2">
                      <span>
                        {m.student.user.full_name}{" "}
                        <span className="text-xs text-slate-500">({m.student.user.email})</span>
                      </span>
                      <button
                        type="button"
                        onClick={() => void removeMember(proj.id, m.student.id)}
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
                  value={pick[proj.id] ?? ""}
                  onChange={(e) => setPick((p) => ({ ...p, [proj.id]: e.target.value }))}
                  className="rounded-lg border border-slate-200 px-2 py-2 text-sm"
                >
                  <option value="">Assign student…</option>
                  {students.map((s) => (
                    <option key={s.student.id} value={String(s.student.id)}>
                      {s.student.user.full_name}
                    </option>
                  ))}
                </select>
                <button
                  type="button"
                  onClick={() => void addMember(proj.id)}
                  className="rounded-lg border border-slate-200 px-3 py-2 text-xs font-semibold hover:bg-slate-50"
                >
                  Link student
                </button>
              </div>
            </div>
          ))}
          {projects.length === 0 && <p className="text-slate-500">No projects yet.</p>}
        </div>
      )}
    </div>
  );
}
