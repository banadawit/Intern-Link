import { Suspense } from "react";
import App from "@/app/(dashboard)/admin/App";

export default function AdminDashboardPage() {
  return (
    <Suspense fallback={<div className="min-h-screen bg-slate-50 p-8 text-center text-slate-500">Loading admin…</div>}>
      <App />
    </Suspense>
  );
}
