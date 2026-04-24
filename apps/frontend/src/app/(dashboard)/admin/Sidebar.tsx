import React, { useState } from "react";
import Link from "next/link";
import {
  LayoutDashboard,
  CheckCircle,
  Clock,
  XCircle,
  FileText,
  Settings,
  LogOut,
  ShieldCheck,
  Ban,
  MessageSquare,
  Building2,
  BarChart3,
} from "lucide-react";
import { cn } from "@/lib/utils";
import { useAuth } from "@/lib/hooks/useAuth";
import { useRouter } from "next/navigation";
import LogoutModal from "@/components/common/LogoutModal";

type ViewKey =
  | "dashboard"
  | "approvals"
  | "organizations"
  | "analytics"
  | "approved"
  | "rejected"
  | "suspended"
  | "audit-log"
  | "settings";

interface Props {
  activeView: ViewKey;
  onNavigate: (view: ViewKey) => void;
  pendingCount?: number;
  pendingCoordinatorCount?: number;
  pendingSupervisorCount?: number;
}

const Sidebar = ({ activeView, onNavigate, pendingCount = 0, pendingCoordinatorCount = 0, pendingSupervisorCount = 0 }: Props) => {
  const { user, logout } = useAuth();
  const router = useRouter();
  const [showLogout, setShowLogout] = useState(false);

  const handleLogout = () => {
    logout();
    router.push('/login');
  };

  const initials = user?.fullName
    ?.split(' ')
    .map((n) => n[0])
    .join('')
    .toUpperCase()
    .slice(0, 2) ?? 'AD';
  const navItems: Array<{ icon: React.ComponentType<{ className?: string }>; label: string; view: ViewKey }> = [
    { icon: LayoutDashboard, label: "Dashboard", view: "dashboard" },
    { icon: Clock, label: "Approvals", view: "approvals" },
    { icon: Building2, label: "Organizations", view: "organizations" },
    { icon: BarChart3, label: "Analytics", view: "analytics" },
    { icon: CheckCircle, label: "Approved History", view: "approved" },
    { icon: Ban, label: "Suspended", view: "suspended" },
    { icon: XCircle, label: "Rejected History", view: "rejected" },
    { icon: FileText, label: "Audit Log", view: "audit-log" },
    { icon: Settings, label: "System Config", view: "settings" },
  ];

  return (
    <aside className="sticky top-0 z-40 flex w-full shrink-0 flex-col border-b border-slate-200 bg-white shadow-sm lg:h-screen lg:w-64 lg:border-b-0 lg:border-r lg:shadow-none">
      {showLogout && (
        <LogoutModal onConfirm={handleLogout} onCancel={() => setShowLogout(false)} />
      )}
      <div className="flex items-center gap-3 border-b border-slate-200 px-4 py-4 lg:px-6">
        <div className="rounded-xl bg-teal-600 p-2.5 shadow-sm shadow-teal-900/10">
          <ShieldCheck className="h-6 w-6 text-white" />
        </div>
        <div className="min-w-0">
          <span className="block truncate text-lg font-bold tracking-tight text-slate-900">Admin</span>
          <span className="hidden text-xs text-slate-500 sm:block">Verification & platform</span>
        </div>
      </div>

      <nav
        className="flex gap-1 overflow-x-auto px-2 py-2 [-ms-overflow-style:none] [scrollbar-width:none] lg:flex lg:flex-col lg:gap-1.5 lg:overflow-y-auto lg:p-4 lg:pt-3 [&::-webkit-scrollbar]:hidden"
        aria-label="Admin navigation"
      >
        {navItems.map((item) => (
          <button
            key={item.view}
            type="button"
            onClick={() => onNavigate(item.view)}
            className={cn(
              "flex shrink-0 items-center gap-2 rounded-xl px-3 py-2.5 text-left text-sm font-medium transition-all duration-200 lg:w-full lg:gap-3 lg:px-4 lg:py-3",
              activeView === item.view
                ? "bg-teal-50 text-teal-700 shadow-sm ring-1 ring-teal-100"
                : "text-slate-500 hover:bg-slate-100 hover:text-slate-700 active:scale-[0.98]"
            )}
          >
            <item.icon className="h-5 w-5 shrink-0" />
            <span className="min-w-0 flex-1 whitespace-nowrap text-left">{item.label}</span>
            {item.view === "approvals" && (pendingCount + pendingCoordinatorCount + pendingSupervisorCount) > 0 && (
              <span className="shrink-0 rounded-full bg-rose-100 px-2 py-0.5 text-[10px] font-bold tabular-nums text-rose-700 ring-1 ring-rose-200/80">
                {(pendingCount + pendingCoordinatorCount + pendingSupervisorCount) > 99
                  ? "99+"
                  : pendingCount + pendingCoordinatorCount + pendingSupervisorCount}
              </span>
            )}
          </button>
        ))}
        <Link
          href="/admin/common-feed"
          className="flex shrink-0 items-center gap-2 rounded-xl px-3 py-2.5 text-sm font-medium text-slate-500 transition-all duration-200 hover:bg-slate-100 hover:text-slate-700 lg:w-full lg:gap-3 lg:px-4 lg:py-3"
        >
          <MessageSquare className="h-5 w-5 shrink-0" />
          <span className="min-w-0 flex-1 whitespace-nowrap text-left">Common Feed</span>
        </Link>
      </nav>

      <div className="mt-auto hidden border-t border-slate-200 lg:block">
        <div className="flex items-center gap-3 p-4">
          <div className="flex h-10 w-10 shrink-0 items-center justify-center rounded-full bg-teal-50 text-sm font-bold text-teal-600 ring-2 ring-white shadow-sm">
            {initials}
          </div>
          <div className="min-w-0 flex-1">
            <p className="truncate text-sm font-bold text-slate-900">{user?.fullName ?? "Admin"}</p>
            <p className="truncate text-xs text-slate-500">Admin</p>
          </div>
        </div>
        <button
          type="button"
          onClick={() => setShowLogout(true)}
          className="mb-4 flex w-full items-center gap-3 rounded-xl px-4 py-3 text-left text-sm font-medium text-red-600 transition-colors hover:bg-red-50"
        >
          <LogOut className="h-5 w-5 shrink-0" />
          Logout
        </button>
      </div>

      <div className="flex items-center justify-between gap-2 border-t border-slate-200 px-3 py-3 lg:hidden">
        <div className="flex min-w-0 items-center gap-2">
          <div className="flex h-9 w-9 shrink-0 items-center justify-center rounded-full bg-teal-50 text-xs font-bold text-teal-600">
            {initials}
          </div>
          <span className="truncate text-sm font-semibold text-slate-900">{user?.fullName ?? "Admin"}</span>
        </div>
        <button
          type="button"
          onClick={() => setShowLogout(true)}
          className="rounded-lg p-2 text-red-600 transition-colors hover:bg-red-50"
          aria-label="Logout"
        >
          <LogOut className="h-5 w-5" />
        </button>
      </div>
    </aside>
  );
};

export default Sidebar;
