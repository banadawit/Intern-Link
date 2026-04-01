"use client";

import React from "react";
import StudentSettingsTopNav from "./StudentSettingsTopNav";

/** Settings routes only: Profile + Alerts top bar, then page content. */
export default function StudentSettingsShell({ children }: { children: React.ReactNode }) {
  return (
    <div className="min-w-0 space-y-6">
      <StudentSettingsTopNav />
      <div>{children}</div>
    </div>
  );
}
