"use client";

import React, { useEffect, useState } from "react";
import { BellRing } from "lucide-react";
import { cn } from "@/lib/utils";
import {
  canUseDesktopNotify,
  getDesktopNotifyOptIn,
  requestDesktopNotifyPermission,
  setDesktopNotifyOptIn,
} from "@/lib/student/desktopNotifications";

/** Opt-in to browser (desktop) notifications for deadlines and reminders. Requires user gesture to enable. */
export default function StudentDesktopNotifyToggle() {
  const [enabled, setEnabled] = useState(false);
  const [unsupported, setUnsupported] = useState(true);

  useEffect(() => {
    const ok = canUseDesktopNotify();
    setUnsupported(!ok);
    setEnabled(ok && getDesktopNotifyOptIn() && Notification.permission === "granted");
  }, []);

  const onClick = async () => {
    if (unsupported) return;
    if (!enabled) {
      const p = await requestDesktopNotifyPermission();
      if (p !== "granted") return;
      setDesktopNotifyOptIn(true);
      setEnabled(true);
    } else {
      setDesktopNotifyOptIn(false);
      setEnabled(false);
    }
  };

  return (
    <button
      type="button"
      onClick={onClick}
      disabled={unsupported}
      title={
        unsupported
          ? "Notifications are not supported in this browser"
          : enabled
            ? "Turn off desktop notifications"
            : "Turn on desktop notifications for deadlines and plan activity"
      }
      className={cn(
        "relative flex h-10 items-center gap-2 rounded-xl border px-3 text-sm font-medium transition-all",
        unsupported
          ? "cursor-not-allowed border-border-default bg-bg-secondary/80 text-text-muted"
          : enabled
            ? "border-primary-200 bg-primary-light/60 text-primary-800 shadow-sm hover:bg-primary-light"
            : "border-border-default bg-bg-secondary text-text-heading shadow-sm hover:bg-bg-tertiary"
      )}
    >
      <BellRing className={cn("h-4 w-4 shrink-0", enabled && "text-primary-700")} />
      <span className="hidden sm:inline">{enabled ? "Alerts on" : "Alerts"}</span>
    </button>
  );
}
