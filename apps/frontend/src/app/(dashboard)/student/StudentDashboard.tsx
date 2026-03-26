import React from 'react';
import { 
  Building2, 
  User, 
  Mail, 
  CheckCircle2, 
  Clock, 
  XCircle,
  Calendar,
  ArrowRight
} from 'lucide-react';
import { MOCK_STUDENT, MOCK_WEEKLY_PLANS } from '@/lib/superadmin/mockData';
import { WeeklyPlan } from '@/lib/superadmin/types';
import { cn } from '@/lib/utils';
import Link from 'next/link';

const StudentDashboard = () => {
  const latestPlans: WeeklyPlan[] = MOCK_WEEKLY_PLANS.slice(-3).reverse();

  return (
    <div className="space-y-8 animate-in fade-in duration-500">
      <header>
        <h1 className="text-3xl font-bold mb-2 text-slate-900">Welcome back, {MOCK_STUDENT.name}!</h1>
        <p className="text-slate-600">Track your internship progress and manage your weekly submissions.</p>
      </header>

      <div className="grid grid-cols-1 lg:grid-cols-3 gap-6">
        {/* Internship Status Card */}
        <div className="card p-6 lg:col-span-2">
          <div className="flex items-center justify-between mb-6">
            <h3 className="text-lg font-bold">Internship Status</h3>
            <span className={cn(
              "px-3 py-1 rounded-full text-xs font-bold uppercase tracking-wider",
              MOCK_STUDENT.internshipStatus === 'Placed' ? "bg-green-50 text-green-600" : "bg-yellow-50 text-yellow-500"
            )}>
              {MOCK_STUDENT.internshipStatus}
            </span>
          </div>
          
          <div className="grid grid-cols-1 md:grid-cols-2 gap-8">
            <div className="space-y-4">
              <div className="flex items-center gap-3">
                <div className="p-2 bg-teal-50 text-teal-600 rounded-lg">
                  <Building2 className="w-5 h-5" />
                </div>
                <div>
                  <p className="text-xs text-slate-500 uppercase font-bold tracking-tight">Assigned Company</p>
                  <p className="font-semibold text-slate-900">{MOCK_STUDENT.assignedCompany || 'Not Assigned'}</p>
                </div>
              </div>
              <div className="flex items-center gap-3">
                <div className="p-2 bg-blue-50 text-blue-600 rounded-lg">
                  <User className="w-5 h-5" />
                </div>
                <div>
                  <p className="text-xs text-slate-500 uppercase font-bold tracking-tight">Supervisor</p>
                  <p className="font-semibold text-slate-900">{MOCK_STUDENT.supervisorName || 'Not Assigned'}</p>
                </div>
              </div>
            </div>
            
            <div className="space-y-4">
              <div className="flex items-center gap-3">
                <div className="p-2 bg-purple-50 text-purple-600 rounded-lg">
                  <Mail className="w-5 h-5" />
                </div>
                <div>
                  <p className="text-xs text-slate-500 uppercase font-bold tracking-tight">Supervisor Email</p>
                  <p className="font-semibold text-slate-900">{MOCK_STUDENT.supervisorEmail || 'N/A'}</p>
                </div>
              </div>
            </div>
          </div>
        </div>

        {/* Quick Actions */}
        <div className="card p-6">
          <h3 className="text-lg font-bold mb-6">Quick Actions</h3>
          <div className="space-y-3">
            <Link href="/student/plans" className="flex items-center justify-between p-4 rounded-xl bg-slate-50 hover:bg-slate-100 transition-all group">
              <span className="font-medium text-slate-600">Submit Weekly Plan</span>
              <ArrowRight className="w-4 h-4 text-slate-500 group-hover:text-teal-600 transition-all" />
            </Link>
            <Link href="/student/common" className="flex items-center justify-between p-4 rounded-xl bg-slate-50 hover:bg-slate-100 transition-all group">
              <span className="font-medium text-slate-600">Post Experience</span>
              <ArrowRight className="w-4 h-4 text-slate-500 group-hover:text-teal-600 transition-all" />
            </Link>
          </div>
        </div>
      </div>

      {/* Weekly Progress Tracker */}
      <div className="card p-6">
        <div className="flex items-center justify-between mb-6">
          <h3 className="text-lg font-bold">Recent Weekly Plans</h3>
          <Link href="/student/plans" className="text-sm font-medium text-teal-600 hover:underline">View all weeks</Link>
        </div>
        
        <div className="space-y-4">
          {latestPlans.map((plan) => (
            <div key={plan.id} className="flex items-center justify-between p-4 rounded-xl border border-slate-200 hover:border-teal-600/30 transition-all">
              <div className="flex items-center gap-4">
                <div className={cn(
                  "p-3 rounded-xl",
                  plan.status === 'Approved' ? "bg-green-50 text-green-600" : 
                  plan.status === 'Rejected' ? "bg-red-50 text-red-500" : "bg-yellow-50 text-yellow-500"
                )}>
                  {plan.status === 'Approved' ? <CheckCircle2 className="w-5 h-5" /> : 
                   plan.status === 'Rejected' ? <XCircle className="w-5 h-5" /> : <Clock className="w-5 h-5" />}
                </div>
                <div>
                  <p className="font-bold text-slate-900">Week {plan.weekNumber}</p>
                  <p className="text-xs text-slate-500">Submitted on {new Date(plan.submittedAt).toLocaleDateString()}</p>
                </div>
              </div>
              
              <div className="flex items-center gap-6">
                <div className="text-right hidden md:block">
                  <p className="text-xs text-slate-500 uppercase font-bold tracking-tight">Status</p>
                  <p className={cn(
                    "text-sm font-bold",
                    plan.status === 'Approved' ? "text-green-600" : 
                    plan.status === 'Rejected' ? "text-red-500" : "text-yellow-500"
                  )}>
                    {plan.status}
                  </p>
                </div>
                <Link href="/student/plans" className="p-2 hover:bg-slate-100 rounded-lg transition-colors">
                  <ArrowRight className="w-5 h-5 text-slate-500" />
                </Link>
              </div>
            </div>
          ))}
        </div>
      </div>
    </div>
  );
};

export default StudentDashboard;
