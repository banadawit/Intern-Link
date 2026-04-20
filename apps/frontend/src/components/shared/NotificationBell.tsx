"use client";

import { useCallback, useEffect, useRef, useState } from "react";
import { createPortal } from "react-dom";
import { Bell, MessageSquare, FolderKanban, CheckCircle2, Info, X, Megaphone } from "lucide-react";
import { formatDistanceToNow } from "date-fns";
import { useRouter } from "next/navigation";
import { useAuth } from "@/lib/hooks/useAuth";
import api from "@/lib/api/client";
import { cn } from "@/lib/utils";

type Notification = {
  id: number;
  message: string;
  is_read: boolean;
  created_at: string;
};

function iconFor(message: string) {
  const m = message.toLowerCase();
  if (m.startsWith("📢") || m.includes("announcement")) return <Megaphone className="h-4 w-4 text-amber-500" />;
  if (m.includes("message") || m.includes("chat")) return <MessageSquare className="h-4 w-4 text-blue-500" />;
  if (m.includes("project") || m.includes("assigned")) return <FolderKanban className="h-4 w-4 text-teal-600" />;
  if (m.includes("approved") || m.includes("approval")) return <CheckCircle2 className="h-4 w-4 text-emerald-500" />;
  return <Info className="h-4 w-4 text-slate-400" />;
}

function linkFor(message: string, role: string | undefined): string | null {
  const m = message.toLowerCase();
  const r = role?.toLowerCase() ?? '';
  // Broadcast announcements → common feed for that role
  if (m.startsWith("📢") || m.includes("announcement")) {
    if (r === 'student') return '/student/common';
    if (r === 'coordinator') return '/coordinator/common-feed';
    if (r === 'supervisor') return '/supervisor/common-feed';
    if (r === 'hod') return '/hod/common-feed';
    return null;
  }
  return null;
}

export default function NotificationBell() {
  const [open, setOpen] = useState(false);
  const [notifications, setNotifications] = useState<Notification[]>([]);
  const [unread, setUnread] = useState(0);
  const [panelPos, setPanelPos] = useState({ top: 0, right: 0 });
  const buttonRef = useRef<HTMLButtonElement>(null);
  const router = useRouter();
  const { user } = useAuth();

  const load = useCallback(async () => {
    try {
      const { data } = await api.get<Notification[]>("/notifications");
      setNotifications(data);
      setUnread(data.filter((n) => !n.is_read).length);
    } catch { /* ignore */ }
  }, []);

  useEffect(() => {
    void load();
    const interval = setInterval(() => void load(), 10000);
    return () => clearInterval(interval);
  }, [load]);

  const toggle = () => {
    if (!open && buttonRef.current) {
      const rect = buttonRef.current.getBoundingClientRect();
      setPanelPos({
        top: rect.bottom + window.scrollY + 8,
        right: window.innerWidth - rect.right,
      });
    }
    setOpen((o) => !o);
  };

  const markAllRead = async () => {
    try {
      await api.patch("/notifications/read-all");
      setNotifications((prev) => prev.map((n) => ({ ...n, is_read: true })));
      setUnread(0);
    } catch { /* ignore */ }
  };

  const markOne = async (id: number) => {
    try {
      await api.patch(`/notifications/${id}/read`);
      setNotifications((prev) => prev.map((n) => n.id === id ? { ...n, is_read: true } : n));
      setUnread((c) => Math.max(0, c - 1));
    } catch { /* ignore */ }
  };

  const panel = open ? (
    <>
      {/* Backdrop */}
      <div
        className="fixed inset-0 z-[9998]"
        onClick={() => setOpen(false)}
      />
      {/* Panel */}
      <div
        style={{ top: panelPos.top, right: panelPos.right }}
        className="fixed z-[9999] w-[min(100vw-2rem,22rem)] overflow-hidden rounded-2xl border border-slate-200 bg-white shadow-2xl"
      >
        {/* Header */}
        <div className="flex items-center justify-between border-b border-slate-100 px-4 py-3">
          <p className="text-sm font-bold text-slate-900">Notifications</p>
          <div className="flex items-center gap-3">
            {unread > 0 && (
              <button
                type="button"
                onClick={() => void markAllRead()}
                className="text-xs font-medium text-primary-600 hover:underline"
              >
                Mark all read
              </button>
            )}
            <button
              type="button"
              onClick={() => setOpen(false)}
              className="rounded-lg p-1 text-slate-400 hover:bg-slate-100 hover:text-slate-600"
            >
              <X className="h-4 w-4" />
            </button>
          </div>
        </div>

        {/* List */}
        <ul className="max-h-[70vh] overflow-y-auto divide-y divide-slate-50">
          {notifications.length === 0 ? (
            <li className="px-4 py-10 text-center text-sm text-slate-400">
              No notifications yet.
            </li>
          ) : (
            notifications.map((n) => {
              const link = linkFor(n.message, user?.role);
              return (
                <li
                  key={n.id}
                  onClick={() => {
                    if (!n.is_read) void markOne(n.id);
                    if (link) { setOpen(false); router.push(link); }
                  }}
                  className={cn(
                    "flex items-start gap-3 px-4 py-3 transition-colors hover:bg-slate-50",
                    link ? "cursor-pointer" : !n.is_read ? "cursor-pointer" : "cursor-default",
                    !n.is_read && "bg-primary-50/50"
                  )}
                >
                  <span className="mt-0.5 shrink-0">{iconFor(n.message)}</span>
                  <div className="min-w-0 flex-1">
                    <p className={cn(
                      "text-sm leading-snug text-slate-700",
                      !n.is_read && "font-semibold text-slate-900"
                    )}>
                      {n.message}
                    </p>
                    <p className="mt-0.5 text-xs text-slate-400">
                      {formatDistanceToNow(new Date(n.created_at), { addSuffix: true })}
                    </p>
                    {link && (
                      <p className="mt-0.5 text-xs font-medium text-primary-600">
                        View in Common Feed →
                      </p>
                    )}
                  </div>
                  {!n.is_read && (
                    <span className="mt-1.5 h-2 w-2 shrink-0 rounded-full bg-primary-600" />
                  )}
                </li>
              );
            })
          )}
        </ul>
      </div>
    </>
  ) : null;

  return (
    <>
      <button
        ref={buttonRef}
        type="button"
        onClick={toggle}
        className="relative flex h-10 w-10 items-center justify-center rounded-xl border border-border-default bg-bg-secondary text-text-heading shadow-sm transition-all hover:bg-bg-tertiary hover:shadow-md active:scale-95"
        aria-label={unread > 0 ? `${unread} unread notifications` : "Notifications"}
      >
        <Bell className="h-5 w-5" />
        {unread > 0 && (
          <span className="absolute -right-1 -top-1 flex h-5 min-w-[1.25rem] items-center justify-center rounded-full bg-red-500 px-1 text-[10px] font-bold text-white">
            {unread > 9 ? "9+" : unread}
          </span>
        )}
      </button>

      {typeof window !== "undefined" && createPortal(panel, document.body)}
    </>
  );
}
