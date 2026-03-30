import React from "react";
import { format } from "date-fns";
import { CheckCircle, XCircle, User, Clock } from "lucide-react";
import { AuditLogEntry } from "@/lib/superadmin/types";
import { cn } from "@/lib/utils";
import AdminPageHero from "./AdminPageHero";

interface Props {
  logs: AuditLogEntry[];
}

const AuditLog = ({ logs }: Props) => {
  return (
    <div className="space-y-6 animate-in fade-in duration-500">
      <AdminPageHero
        badge="Compliance"
        title="Audit log"
        description="Complete history of verification decisions and system actions."
      />

      <div className="rounded-2xl border border-slate-200 bg-white overflow-hidden">
        <div className="overflow-x-auto">
          <table className="w-full text-left">
            <thead>
              <tr className="bg-slate-100 text-slate-500 text-xs uppercase tracking-wider">
                <th className="px-6 py-4 font-semibold">Action</th>
                <th className="px-6 py-4 font-semibold">Organization</th>
                <th className="px-6 py-4 font-semibold">Admin</th>
                <th className="px-6 py-4 font-semibold">Timestamp</th>
                <th className="px-6 py-4 font-semibold">Notes</th>
              </tr>
            </thead>
            <tbody className="divide-y divide-slate-200">
              {logs.map((log) => (
                <tr key={log.id} className="hover:bg-slate-50 transition-colors">
                  <td className="px-6 py-4">
                    <div className={cn("flex items-center gap-2 text-sm font-bold", log.action === "Approve" ? "text-green-600" : "text-red-500")}>
                      {log.action === "Approve" ? <CheckCircle className="w-4 h-4" /> : <XCircle className="w-4 h-4" />}
                      {log.action}
                    </div>
                  </td>
                  <td className="px-6 py-4">
                    <span className="text-sm font-semibold text-slate-900">{log.targetName}</span>
                  </td>
                  <td className="px-6 py-4">
                    <div className="flex items-center gap-2 text-sm text-slate-600">
                      <User className="w-4 h-4 text-slate-500" />
                      {log.adminId}
                    </div>
                  </td>
                  <td className="px-6 py-4 text-sm text-slate-500">
                    <div className="flex items-center gap-2">
                      <Clock className="w-4 h-4" />
                      {format(new Date(log.timestamp), "MMM d, yyyy HH:mm")}
                    </div>
                  </td>
                  <td className="px-6 py-4">
                    <p className="text-sm text-slate-500 max-w-xs truncate" title={log.notes}>
                      {log.notes || "No notes provided."}
                    </p>
                  </td>
                </tr>
              ))}
              {logs.length === 0 && (
                <tr>
                  <td colSpan={5} className="px-6 py-12 text-center text-slate-500">
                    No audit logs found.
                  </td>
                </tr>
              )}
            </tbody>
          </table>
        </div>
      </div>
    </div>
  );
};

export default AuditLog;
