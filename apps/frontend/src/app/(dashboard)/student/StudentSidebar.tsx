import React from 'react';
import { 
  LayoutDashboard, 
  ClipboardList, 
  MessageSquare, 
  Building, 
  FileCheck,
  LogOut,
  User,
  GraduationCap
} from 'lucide-react';
import { NavLink } from 'react-router-dom';
import { cn } from '../../lib/utils';

const StudentSidebar = () => {
  const navItems = [
    { icon: LayoutDashboard, label: 'Dashboard', path: '/student' },
    { icon: ClipboardList, label: 'Weekly Plans', path: '/student/plans' },
    { icon: MessageSquare, label: 'Common Page', path: '/student/common' },
    { icon: Building, label: 'Request Company', path: '/student/request-company' },
    { icon: FileCheck, label: 'Final Evaluation', path: '/student/evaluation' },
  ];

  return (
    <aside className="w-64 bg-bg-main border-r border-border-default h-screen sticky top-0 flex flex-col">
      <div className="p-6 flex items-center gap-3 border-b border-border-default">
        <div className="bg-primary-base p-2 rounded-lg">
          <GraduationCap className="text-white w-6 h-6" />
        </div>
        <span className="font-bold text-lg text-text-heading">StudentPortal</span>
      </div>

      <nav className="flex-1 p-4 space-y-2">
        {navItems.map((item) => (
          <NavLink
            key={item.path}
            to={item.path}
            end={item.path === '/student'}
            className={({ isActive }) => cn(
              "flex items-center gap-3 px-4 py-3 rounded-lg transition-all font-medium",
              isActive 
                ? "bg-primary-light text-primary-base" 
                : "text-text-muted hover:bg-bg-tertiary hover:text-text-body"
            )}
          >
            <item.icon className="w-5 h-5" />
            {item.label}
          </NavLink>
        ))}
      </nav>

      <div className="p-4 border-t border-border-default space-y-4">
        <div className="flex items-center gap-3 px-4 py-2">
          <div className="w-10 h-10 rounded-full bg-primary-light flex items-center justify-center text-primary-base font-bold">
            JD
          </div>
          <div className="flex-1 min-w-0">
            <p className="text-sm font-bold text-text-heading truncate">John Doe</p>
            <p className="text-xs text-text-muted truncate">Student</p>
          </div>
        </div>
        <button className="flex items-center gap-3 px-4 py-3 w-full rounded-lg text-status-error hover:bg-red-50 transition-all font-medium">
          <LogOut className="w-5 h-5" />
          Logout
        </button>
      </div>
    </aside>
  );
};

export default StudentSidebar;
