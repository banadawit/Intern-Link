'use client';

import { useState, useEffect, useCallback } from 'react';
import Link from 'next/link';
import { useAuth } from '@/lib/hooks/useAuth';
import { useRouter } from 'next/navigation';
import LogoutModal from '@/components/common/LogoutModal';
import CoordinatorRouteGuard from './CoordinatorRouteGuard';
import api from '@/lib/api/client';

type PendingHod = {
  id: number;
  department: string;
  user: { id: number; email: string; full_name: string };
};

export default function CoordinatorDashboardPage() {
  const { user, logout } = useAuth();
  const router = useRouter();
  const [showLogout, setShowLogout] = useState(false);
  const [pendingHods, setPendingHods] = useState<PendingHod[]>([]);
  const [hodLoading, setHodLoading] = useState(false);

  const loadPendingHods = useCallback(async () => {
    setHodLoading(true);
    try {
      const { data } = await api.get<PendingHod[]>('/coordinator-portal/pending-hods');
      setPendingHods(data);
    } catch {
      setPendingHods([]);
    } finally {
      setHodLoading(false);
    }
  }, []);

  useEffect(() => {
    void loadPendingHods();
  }, [loadPendingHods]);

  const actHod = async (userId: number, action: 'approve' | 'reject') => {
    try {
      await api.post(`/coordinator-portal/hods/${userId}/${action}`);
      await loadPendingHods();
    } catch {
      /* ignore */
    }
  };

  const handleLogout = () => {
    logout();
    router.push('/login');
  };

  return (
    <CoordinatorRouteGuard>
      <div className="min-h-screen bg-slate-50 flex items-center justify-center relative">
        {showLogout && (
          <LogoutModal
            onConfirm={handleLogout}
            onCancel={() => setShowLogout(false)}
          />
        )}
        <div className="bg-white rounded-2xl shadow-sm border border-slate-200 p-10 max-w-lg w-full text-center space-y-4">
          <div className="h-16 w-16 rounded-2xl bg-primary-50 flex items-center justify-center mx-auto">
            <span className="text-3xl">🏛️</span>
          </div>
          <h1 className="text-2xl font-bold text-slate-900">Coordinator Dashboard</h1>
          <p className="text-slate-500 text-sm">
            Welcome, {user?.fullName}. This dashboard is under construction.
          </p>

          <div className="rounded-xl border border-amber-100 bg-amber-50/50 p-4 text-left">
            <h2 className="text-sm font-bold text-slate-900">Pending HOD approvals</h2>
            {hodLoading ? (
              <p className="mt-2 text-xs text-slate-500">Loading…</p>
            ) : pendingHods.length === 0 ? (
              <p className="mt-2 text-xs text-slate-500">No pending Head of Department accounts.</p>
            ) : (
              <ul className="mt-2 space-y-2 text-sm">
                {pendingHods.map((h) => (
                  <li
                    key={h.id}
                    className="flex flex-wrap items-center justify-between gap-2 rounded-lg border border-slate-100 bg-white px-2 py-2"
                  >
                    <span>
                      {h.user.full_name}{' '}
                      <span className="text-slate-500">
                        ({h.department}) — {h.user.email}
                      </span>
                    </span>
                    <span className="flex gap-1">
                      <button
                        type="button"
                        onClick={() => void actHod(h.user.id, 'approve')}
                        className="rounded bg-emerald-600 px-2 py-1 text-xs text-white"
                      >
                        Approve
                      </button>
                      <button
                        type="button"
                        onClick={() => void actHod(h.user.id, 'reject')}
                        className="rounded border border-slate-200 px-2 py-1 text-xs"
                      >
                        Reject
                      </button>
                    </span>
                  </li>
                ))}
              </ul>
            )}
          </div>

          <Link
            href="/coordinator/ai"
            className="block w-full rounded-xl bg-primary-600 py-2.5 text-center text-sm font-semibold text-white transition-colors hover:bg-primary-700"
          >
            Open AI assistant
          </Link>
          <button
            onClick={() => setShowLogout(true)}
            className="w-full py-2.5 rounded-xl bg-slate-100 text-slate-700 text-sm font-semibold hover:bg-slate-200 transition-colors"
          >
            Logout
          </button>
        </div>
      </div>
    </CoordinatorRouteGuard>
  );
}
