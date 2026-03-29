"use client";

import React, { useState } from "react";
import {
  LayoutDashboard, 
  ClipboardList, 
  MessageSquare, 
  Building, 
  FileCheck,
  LogOut,
  GraduationCap
} from 'lucide-react';
import Link from "next/link";
import { usePathname, useRouter } from "next/navigation";
import { cn } from "@/lib/utils";
import { useAuth } from "@/lib/hooks/useAuth";
import LogoutModal from "@/components/common/LogoutModal";

const StudentSidebar = () => {
  const pathname = usePathname();
  const router = useRouter();
  const { user, logout } = useAuth();
  const [showLogout, setShowLogout] = useState(false);

  const handleLogout = () => {
    logout();
    router.push('/login');
  };

  const initials = user?.fullName
    ?.split(' ')
    .map((n) => n[0])
    .join('')
    .toUpperCase()
    .slice(0, 2) ?? 'ST';
  const navItems = [
    { icon: LayoutDashboard, label: 'Dashboard', path: '/student' },
    { icon: ClipboardList, label: 'Weekly Plans', path: '/student/plans' },
    { icon: MessageSquare, label: 'Common Page', path: '/student/common' },
    { icon: Building, label: 'Request Company', path: '/student/request-company' },
    { icon: FileCheck, label: 'Final Evaluation', path: '/student/evaluation' },
  ];

  return (
    <aside className="w-64 bg-white border-r border-slate-200 h-screen sticky top-0 flex flex-col">
      {showLogout && (
        <LogoutModal onConfirm={handleLogout} onCancel={() => setShowLogout(false)} />
      )}
      <div className="p-6 flex items-center gap-3 border-b border-slate-200">
        <div className="bg-teal-600 p-2 rounded-lg">
          <GraduationCap className="text-white w-6 h-6" />
        </div>
        <span className="font-bold text-lg text-slate-900">StudentPortal</span>
      </div>

      <nav className="flex-1 p-4 space-y-2">
        {navItems.map((item) => (
          <Link
            key={item.path}
            href={item.path}
            className={cn(
              "flex items-center gap-3 px-4 py-3 rounded-lg transition-all font-medium",
              item.path === "/student"
                ? pathname === item.path
                  ? "bg-teal-50 text-teal-600"
                  : "text-slate-500 hover:bg-slate-100 hover:text-slate-600"
                : pathname?.startsWith(item.path)
                  ? "bg-teal-50 text-teal-600"
                  : "text-slate-500 hover:bg-slate-100 hover:text-slate-600"
            )}
          >
            <item.icon className="w-5 h-5" />
            {item.label}
          </Link>
        ))}
      </nav>

      <div className="p-4 border-t border-slate-200 space-y-4">
        <div className="flex items-center gap-3 px-4 py-2">
          <div className="w-10 h-10 rounded-full bg-teal-50 flex items-center justify-center text-teal-600 font-bold">
            {initials}
          </div>
          <div className="flex-1 min-w-0">
            <p className="text-sm font-bold text-slate-900 truncate">{user?.fullName ?? 'Student'}</p>
            <p className="text-xs text-slate-500 truncate">Student</p>
          </div>
        </div>
        <button
          onClick={() => setShowLogout(true)}
          className="flex items-center gap-3 px-4 py-3 w-full rounded-lg text-red-500 hover:bg-red-50 transition-all font-medium"
        >
          <LogOut className="w-5 h-5" />
          Logout
        </button>
      </div>
    </aside>
  );
};

export default StudentSidebar;
