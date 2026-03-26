import React from "react";
import {
  LayoutDashboard,
  CheckCircle,
  Clock,
  XCircle,
  FileText,
  Settings,
  LogOut,
  ShieldCheck,
} from "lucide-react";
import { cn } from "@/lib/utils";

type ViewKey =
  | "dashboard"
  | "pending"
  | "approved"
  | "rejected"
  | "audit-log"
  | "settings";

interface Props {
  activeView: ViewKey;
  onNavigate: (view: ViewKey) => void;
}

const Sidebar = ({ activeView, onNavigate }: Props) => {
  const navItems: Array<{ icon: React.ComponentType<{ className?: string }>; label: string; view: ViewKey }> = [
    { icon: LayoutDashboard, label: "Dashboard", view: "dashboard" },
    { icon: Clock, label: "Pending Approvals", view: "pending" },
    { icon: CheckCircle, label: "Approved History", view: "approved" },
    { icon: XCircle, label: "Rejected History", view: "rejected" },
    { icon: FileText, label: "Audit Log", view: "audit-log" },
    { icon: Settings, label: "System Config", view: "settings" },
  ];

  return (
    <aside className="w-64 bg-white border-r border-slate-200 h-screen sticky top-0 flex flex-col">
      <div className="p-6 flex items-center gap-3 border-b border-slate-200">
        <div className="bg-teal-600 p-2 rounded-lg">
          <ShieldCheck className="text-white w-6 h-6" />
        </div>
        <span className="font-bold text-lg text-slate-900">SuperAdmin</span>
      </div>

      <nav className="flex-1 p-4 space-y-2">
        {navItems.map((item) => (
          <button
            key={item.view}
            onClick={() => onNavigate(item.view)}
            className={cn(
              "w-full flex items-center gap-3 px-4 py-3 rounded-lg transition-all font-medium text-left",
              activeView === item.view
                ? "bg-teal-50 text-teal-600"
                : "text-slate-500 hover:bg-slate-100 hover:text-slate-600"
            )}
          >
            <item.icon className="w-5 h-5" />
            {item.label}
          </button>
        ))}
      </nav>

      <div className="p-4 border-t border-slate-200 space-y-4">
        <div className="flex items-center gap-3 px-4 py-2">
          <div className="w-10 h-10 rounded-full bg-teal-50 flex items-center justify-center text-teal-600 font-bold">
            EA
          </div>
          <div className="flex-1 min-w-0">
            <p className="text-sm font-bold text-slate-900 truncate">Emmanuella Abate</p>
            <p className="text-xs text-slate-500 truncate">Super Admin</p>
          </div>
        </div>
        <button className="flex items-center gap-3 px-4 py-3 w-full rounded-lg text-red-500 hover:bg-red-50 transition-all font-medium">
          <LogOut className="w-5 h-5" />
          Logout
        </button>
      </div>
    </aside>
  );
};

export default Sidebar;
