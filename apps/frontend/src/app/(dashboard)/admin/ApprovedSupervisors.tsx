"use client";

import React, { useCallback, useEffect, useState } from "react";
import { format } from "date-fns";
import { User, Building, CheckCircle } from "lucide-react";
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

const ApprovedSupervisors = () => {
  const [supervisors, setSupervisors] = useState<ApprovedSupervisor[]>([]);
  const [loading, setLoading] = useState(true);

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

  return (
    <div className="card overflow-hidden">
      {loading && (
        <p className="p-6 text-sm text-slate-500" role="status">Loading approved supervisors…</p>
      )}
      <div className="overflow-x-auto">
        <table className="w-full text-left">
          <thead>
            <tr className="bg-slate-100 text-slate-500 text-xs uppercase tracking-wider">
              <th className="px-6 py-4 font-semibold">Supervisor</th>
              <th className="px-6 py-4 font-semibold">Company</th>
              <th className="px-6 py-4 font-semibold">Approved On</th>
              <th className="px-6 py-4 font-semibold">Status</th>
            </tr>
          </thead>
          <tbody className="divide-y divide-slate-200">
            {!loading && supervisors.length === 0 && (
              <tr>
                <td colSpan={4} className="px-6 py-12 text-center text-sm text-slate-500">
                  No approved supervisors yet.
                </td>
              </tr>
            )}
            {supervisors.map((s) => (
              <tr key={s.id} className="hover:bg-slate-50 transition-colors">
                <td className="px-6 py-4">
                  <div className="flex items-center gap-3">
                    <div className="p-2 rounded-lg bg-blue-50 text-blue-600">
                      <User className="w-4 h-4" />
                    </div>
                    <div>
                      <p className="font-semibold text-slate-900 text-sm">{s.user.full_name}</p>
                      <p className="text-xs text-slate-500">{s.user.email}</p>
                    </div>
                  </div>
                </td>
                <td className="px-6 py-4">
                  <div className="flex items-center gap-2 text-sm text-slate-600">
                    <Building className="w-4 h-4 text-slate-400" />
                    {s.company.name}
                  </div>
                </td>
                <td className="px-6 py-4 text-sm text-slate-500">
                  {format(new Date(s.user.created_at), "MMM d, yyyy")}
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

export default ApprovedSupervisors;
