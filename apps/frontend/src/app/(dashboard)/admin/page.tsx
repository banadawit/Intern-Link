import { Suspense } from "react";
import App from "@/app/(dashboard)/admin/App";
import AdminRouteGuard from "@/app/(dashboard)/admin/AdminRouteGuard";

export default function AdminDashboardPage() {
  return (
    <AdminRouteGuard>
      <Suspense fallback={<div className="min-h-screen bg-slate-50 p-8 text-center text-slate-500">Loading admin…</div>}>
        <App />
      </Suspense>
    </AdminRouteGuard>
  );
}
