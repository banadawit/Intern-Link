"use client";

import React, { useCallback, useEffect, useState } from "react";
import { format } from "date-fns";
import { User, Building, CheckCircle } from "lucide-react";
import api from "@/lib/api/client";

interface ApprovedCoordinator {
  id: number;
  userId: number;
  university: { id: number; name: string } | null;
  user: {
    id: number;
    full_name: string;
    email: string;
    created_at: string;
    institution_access_approval: string;
  };
}

const ApprovedCoordinators = () => {
  const [coordinators, setCoordinators] = useState<ApprovedCoordinator[]>([]);
  const [loading, setLoading] = useState(true);

  const load = useCallback(async () => {
    setLoading(true);
    try {
      const { data } = await api.get<ApprovedCoordinator[]>("/admin/approved-coordinators");
      setCoordinators(data);
    } finally {
      setLoading(false);
    }
  }, []);

  useEffect(() => { load(); }, [load]);

  return (
    <div className="card overflow-hidden">
      {loading && (
        <p className="p-6 text-sm text-slate-500" role="status">Loading approved coordinators…</p>
      )}
      <div className="overflow-x-auto">
        <table className="w-full text-left">
          <thead>
            <tr className="bg-slate-100 text-slate-500 text-xs uppercase tracking-wider">
              <th className="px-6 py-4 font-semibold">Coordinator</th>
              <th className="px-6 py-4 font-semibold">University</th>
              <th className="px-6 py-4 font-semibold">Approved On</th>
              <th className="px-6 py-4 font-semibold">Status</th>
            </tr>
          </thead>
          <tbody className="divide-y divide-slate-200">
            {!loading && coordinators.length === 0 && (
              <tr>
                <td colSpan={4} className="px-6 py-12 text-center text-sm text-slate-500">
                  No approved coordinators yet.
                </td>
              </tr>
            )}
            {coordinators.map((c) => (
              <tr key={c.id} className="hover:bg-slate-50 transition-colors">
                <td className="px-6 py-4">
                  <div className="flex items-center gap-3">
                    <div className="p-2 rounded-lg bg-teal-50 text-teal-600">
                      <User className="w-4 h-4" />
                    </div>
                    <div>
                      <p className="font-semibold text-slate-900 text-sm">{c.user.full_name}</p>
                      <p className="text-xs text-slate-500">{c.user.email}</p>
                    </div>
                  </div>
                </td>
                <td className="px-6 py-4">
                  <div className="flex items-center gap-2 text-sm text-slate-600">
                    <Building className="w-4 h-4 text-slate-400" />
                    {c.university?.name ?? "—"}
                  </div>
                </td>
                <td className="px-6 py-4 text-sm text-slate-500">
                  {format(new Date(c.user.created_at), "MMM d, yyyy")}
                </td>
                <td className="px-6 py-4">
                  <span className="inline-flex items-center gap-1.5 rounded-full bg-emerald-50 px-2.5 py-1 text-xs font-semibold text-emerald-700 ring-1 ring-emerald-200">
                    <CheckCircle className="w-3 h-3" />
                    Approved
                  </span>
                </td>
              </tr>
            ))}
          </tbody>
        </table>
      </div>
    </div>
  );
};

export default ApprovedCoordinators;
