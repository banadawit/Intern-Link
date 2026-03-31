import React from "react";
import StudentDesktopNotifyToggle from "../../StudentDesktopNotifyToggle";
import StudentPageHero from "../../StudentPageHero";

export default function StudentSettingsAlertsPage() {
  return (
    <div className="space-y-8 pb-4 animate-in fade-in duration-300">
      <StudentPageHero
        badge="Settings"
        title="Alerts"
        description="Choose whether to receive browser notifications for weekly plan deadlines and activity."
      />

      <div className="card p-6">
        <div className="flex flex-col gap-4 sm:flex-row sm:items-center sm:justify-between">
          <div className="min-w-0">
            <h2 className="text-lg font-bold text-text-heading">Desktop notifications</h2>
            <p className="mt-1 text-sm text-text-muted">
              When enabled, your browser can show reminders for deadlines and plan updates. You may need to
              allow notifications for this site in your browser settings.
            </p>
          </div>
          <div className="shrink-0">
            <StudentDesktopNotifyToggle />
          </div>
        </div>
      </div>
    </div>
  );
}
