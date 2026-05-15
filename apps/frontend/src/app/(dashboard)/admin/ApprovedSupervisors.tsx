"use client";

import React, { useCallback, useEffect, useState } from "react";
import { format } from "date-fns";
import { User, Building, CheckCircle, Ban, XCircle, Trash2, AlertTriangle } from "lucide-react";
import api from "@/lib/api/client";

interface ApprovedSupervisor {
  id: number;
  userId: number;
  company: { id: number; name: string };
  user: {
    id: number;
    full_name: string;
    email: string;
    created_at: string;
    institution_access_approval: string;
  };
}

type ActionType = "suspend" | "deactivate" | null;

interface ConfirmState {
  type: ActionType;
  supervisor: ApprovedSupervisor | null;
  reason: string;
}

const ApprovedSupervisors = () => {
  const [supervisors, setSupervisors] = useState<ApprovedSupervisor[]>([]);
  const [loading, setLoading] = useState(true);
  const [confirm, setConfirm] = useState<ConfirmState>({ type: null, supervisor: null, reason: "" });
  const [acting, setActing] = useState(false);
  const [toast, setToast] = useState<{ msg: string; ok: boolean } | null>(null);

  const load = useCallback(async () => {
    setLoading(true);
    try {
      const { data } = await api.get<ApprovedSupervisor[]>("/admin/approved-supervisors");
      setSupervisors(data);
    } finally {
      setLoading(false);
    }
  }, []);

  useEffect(() => { load(); }, [load]);

  const showToast = (msg: string, ok: boolean) => {
    setToast({ msg, ok });
    setTimeout(() => setToast(null), 3500);
  };

  const openConfirm = (type: ActionType, supervisor: ApprovedSupervisor) =>
    setConfirm({ type, supervisor, reason: "" });

  const closeConfirm = () => setConfirm({ type: null, supervisor: null, reason: "" });

  const handleAction = async () => {
    if (!confirm.type || !confirm.supervisor) return;
    setActing(true);
    const uid = confirm.supervisor.user.id;
    try {
      if (confirm.type === "suspend") {
        await api.post(`/admin/supervisors/${uid}/suspend`, { reason: confirm.reason });
        showToast("Supervisor suspended.", true);
      } else if (confirm.type === "deactivate") {
        await api.post(`/admin/supervisors/${uid}/reject`, { reason: confirm.reason });
        showToast("Supervisor deactivated.", true);
      }
      closeConfirm();
      load();
    } catch (e: any) {
      showToast(e?.response?.data?.error || "Action failed.", false);
    } finally {
      setActing(false);
    }
  };

  const actionMeta: Record<NonNullable<ActionType>, { label: string; color: string; icon: React.ReactNode; desc: string }> = {
    suspend: {
      label: "Suspend",
      color: "bg-amber-600 hover:bg-amber-700",
      icon: <Ban className="w-4 h-4" />,
      desc: "The supervisor will lose platform access temporarily and can be reactivated later.",
    },
    deactivate: {
      label: "Deactivate",
      color: "bg-orange-600 hover:bg-orange-700",
      icon: <XCircle className="w-4 h-4" />,
      desc: "The supervisor's access will be revoked. They will need to re-apply.",
    },
  };

  return (
    <div className="relative">
      {/* Toast */}
      {toast && (
        <div className={`fixed top-4 right-4 z-50 px-4 py-3 rounded-lg shadow-lg text-sm font-medium text-white ${toast.ok ? "bg-emerald-600" : "bg-red-600"}`}>
          {toast.msg}
        </div>
      )}

      {/* Confirm Modal */}
      {confirm.type && confirm.supervisor && (
        <div className="fixed inset-0 z-40 flex items-center justify-center bg-black/50 backdrop-blur-sm">
          <div className="bg-white dark:bg-slate-900 rounded-xl shadow-2xl p-6 w-full max-w-md mx-4">
            <div className="flex items-center gap-3 mb-4">
              <div className="p-2 rounded-lg bg-red-50 text-red-600 dark:bg-red-900/30">
                <AlertTriangle className="w-5 h-5" />
              </div>
              <h3 className="text-lg font-semibold text-slate-900 dark:text-slate-100">
                {actionMeta[confirm.type].label} Supervisor
              </h3>
            </div>
            <p className="text-sm text-slate-600 dark:text-slate-400 mb-1">
              <span className="font-medium text-slate-800 dark:text-slate-200">{confirm.supervisor.user.full_name}</span> — {confirm.supervisor.company.name}
            </p>
            <p className="text-sm text-slate-500 dark:text-slate-400 mb-4">{actionMeta[confirm.type].desc}</p>
            {confirm.type !== "delete" && (
              <textarea
                className="w-full rounded-lg border border-slate-300 dark:border-slate-600 bg-white dark:bg-slate-800 text-sm text-slate-800 dark:text-slate-200 px-3 py-2 mb-4 resize-none focus:outline-none focus:ring-2 focus:ring-blue-500"
                rows={3}
                placeholder="Reason (optional)"
                value={confirm.reason}
                onChange={(e) => setConfirm((p) => ({ ...p, reason: e.target.value }))}
              />
            )}
            <div className="flex gap-3 justify-end">
              <button
                onClick={closeConfirm}
                disabled={acting}
                className="px-4 py-2 rounded-lg text-sm font-medium text-slate-700 dark:text-slate-300 bg-slate-100 dark:bg-slate-800 hover:bg-slate-200 dark:hover:bg-slate-700 transition-colors"
              >
                Cancel
              </button>
              <button
                onClick={handleAction}
                disabled={acting}
                className={`inline-flex items-center gap-2 px-4 py-2 rounded-lg text-sm font-medium text-white transition-colors ${actionMeta[confirm.type].color}`}
              >
                {acting ? "Processing…" : <>{actionMeta[confirm.type].icon} {actionMeta[confirm.type].label}</>}
              </button>
            </div>
          </div>
        </div>
      )}

      <div className="card overflow-hidden">
        {loading && (
          <p className="p-6 text-sm text-slate-500 dark:text-slate-400" role="status">Loading approved supervisors…</p>
        )}
        <div className="overflow-x-auto">
          <table className="w-full text-left">
            <thead>
              <tr className="bg-slate-100 text-slate-500 text-xs uppercase tracking-wider dark:bg-slate-800 dark:text-slate-400">
                <th className="px-6 py-4 font-semibold">Supervisor</th>
                <th className="px-6 py-4 font-semibold">Company</th>
                <th className="px-6 py-4 font-semibold">Approved On</th>
                <th className="px-6 py-4 font-semibold">Status</th>
                <th className="px-6 py-4 font-semibold">Actions</th>
              </tr>
            </thead>
            <tbody className="divide-y divide-slate-200 dark:divide-slate-700">
              {!loading && supervisors.length === 0 && (
                <tr>
                  <td colSpan={5} className="px-6 py-12 text-center text-sm text-slate-500 dark:text-slate-400">
                    No approved supervisors yet.
                  </td>
                </tr>
              )}
              {supervisors.map((s) => (
                <tr key={s.id} className="hover:bg-slate-50 transition-colors dark:hover:bg-slate-800/50">
                  <td className="px-6 py-4">
                    <div className="flex items-center gap-3">
                      <div className="p-2 rounded-lg bg-blue-50 text-blue-600 dark:bg-blue-900/30 dark:text-blue-400">
                        <User className="w-4 h-4" />
                      </div>
                      <div>
                        <p className="font-semibold text-slate-900 dark:text-slate-100 text-sm">{s.user.full_name}</p>
                        <p className="text-xs text-slate-500 dark:text-slate-400">{s.user.email}</p>
                      </div>
                    </div>
                  </td>
                  <td className="px-6 py-4">
                    <div className="flex items-center gap-2 text-sm text-slate-600 dark:text-slate-300">
                      <Building className="w-4 h-4 text-slate-400" />
                      {s.company.name}
                    </div>
                  </td>
                  <td className="px-6 py-4 text-sm text-slate-500 dark:text-slate-400">
                    {format(new Date(s.user.created_at), "MMM d, yyyy")}
                  </td>
                  <td className="px-6 py-4">
                    <span className="inline-flex items-center gap-1.5 rounded-full bg-emerald-50 px-2.5 py-1 text-xs font-semibold text-emerald-700 ring-1 ring-emerald-200">
                      <CheckCircle className="w-3 h-3" />
                      Approved
                    </span>
                  </td>
                  <td className="px-6 py-4">
                    <div className="flex items-center gap-2">
                      <button
                        onClick={() => openConfirm("suspend", s)}
                        title="Suspend"
                        className="inline-flex items-center gap-1 px-2.5 py-1.5 rounded-lg text-xs font-medium bg-amber-50 text-amber-700 hover:bg-amber-100 ring-1 ring-amber-200 transition-colors dark:bg-amber-900/20 dark:text-amber-400 dark:ring-amber-700 dark:hover:bg-amber-900/40"
                      >
                        <Ban className="w-3.5 h-3.5" /> Suspend
                      </button>
                      <button
                        onClick={() => openConfirm("deactivate", s)}
                        title="Deactivate"
                        className="inline-flex items-center gap-1 px-2.5 py-1.5 rounded-lg text-xs font-medium bg-orange-50 text-orange-700 hover:bg-orange-100 ring-1 ring-orange-200 transition-colors dark:bg-orange-900/20 dark:text-orange-400 dark:ring-orange-700 dark:hover:bg-orange-900/40"
                      >
                        <XCircle className="w-3.5 h-3.5" /> Deactivate
                      </button>
                    </div>
                  </td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>
      </div>
    </div>
  );
};

export default ApprovedSupervisors;
