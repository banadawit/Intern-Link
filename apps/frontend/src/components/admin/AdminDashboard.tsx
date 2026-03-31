import React from "react";
import Dashboard from "../../app/(dashboard)/admin/Dashboard";
import { MOCK_PROPOSALS } from "../../lib/superadmin/mockData";

/** CRA / legacy `src/App.tsx` wrapper — supplies pending count like the Next `/admin` shell. */
export default function AdminDashboard() {
  const pendingVerificationCount = MOCK_PROPOSALS.filter((p) => p.status === "Pending").length;
  return <Dashboard pendingVerificationCount={pendingVerificationCount} />;
}
