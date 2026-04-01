import React from "react";
import Dashboard from "../../app/(dashboard)/admin/Dashboard";

/** CRA / legacy `src/App.tsx` wrapper — real stats come from Next `/admin` shell. */
export default function AdminDashboard() {
  return <Dashboard pendingVerificationCount={0} stats={null} statsLoading={false} />;
}
