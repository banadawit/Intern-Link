'use client';

import { useState } from 'react';
import { useAuth } from '@/lib/hooks/useAuth';
import { useRouter } from 'next/navigation';
import LogoutModal from '@/components/common/LogoutModal';

export default function CoordinatorDashboardPage() {
  const { user, logout } = useAuth();
  const router = useRouter();
  const [showLogout, setShowLogout] = useState(false);

  const handleLogout = () => {
    logout();
    router.push('/login');
  };

  return (
    <div className="min-h-screen bg-slate-50 flex items-center justify-center">
      {showLogout && (
        <LogoutModal
          onConfirm={handleLogout}
          onCancel={() => setShowLogout(false)}
        />
      )}
      <div className="bg-white rounded-2xl shadow-sm border border-slate-200 p-10 max-w-md w-full text-center space-y-4">
        <div className="h-16 w-16 rounded-2xl bg-primary-50 flex items-center justify-center mx-auto">
          <span className="text-3xl">🏛️</span>
        </div>
        <h1 className="text-2xl font-bold text-slate-900">Coordinator Dashboard</h1>
        <p className="text-slate-500 text-sm">Welcome, {user?.fullName}. This dashboard is under construction.</p>
        <button
          onClick={() => setShowLogout(true)}
          className="w-full py-2.5 rounded-xl bg-slate-100 text-slate-700 text-sm font-semibold hover:bg-slate-200 transition-colors"
        >
          Logout
        </button>
      </div>
    </div>
  );
}
