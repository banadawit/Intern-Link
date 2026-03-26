import React from "react";
import { Users, Building2, GraduationCap, Briefcase, TrendingUp, AlertCircle } from "lucide-react";
import { BarChart, Bar, XAxis, YAxis, CartesianGrid, Tooltip, ResponsiveContainer } from "recharts";
import { MOCK_STATS } from "@/lib/superadmin/mockData";

const StatCard = ({ icon: Icon, label, value, subValue, colorClass }: any) => (
  <div className="rounded-2xl border border-slate-200 bg-white p-6 flex items-start justify-between">
    <div>
      <p className="text-slate-500 text-sm font-medium mb-1">{label}</p>
      <h3 className="text-2xl font-bold text-slate-900">{value}</h3>
      {subValue && <p className="text-xs text-slate-500 mt-1">{subValue}</p>}
    </div>
    <div className={`p-3 rounded-xl ${colorClass}`}>
      <Icon className="w-6 h-6" />
    </div>
  </div>
);

const Dashboard = () => {
  const chartData = [
    { name: "Universities", approved: MOCK_STATS.totalUniversities.approved, pending: MOCK_STATS.totalUniversities.pending },
    { name: "Companies", approved: MOCK_STATS.totalCompanies.approved, pending: MOCK_STATS.totalCompanies.pending },
  ];

  return (
    <div className="space-y-8 animate-in fade-in duration-500">
      <header>
        <h1 className="text-3xl font-bold text-slate-900 mb-2">System Overview</h1>
        <p className="text-slate-500">Real-time statistics and platform health monitoring.</p>
      </header>

      <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-6">
        <StatCard icon={GraduationCap} label="Universities" value={MOCK_STATS.totalUniversities.approved} subValue={`${MOCK_STATS.totalUniversities.pending} pending verification`} colorClass="bg-teal-50 text-teal-600" />
        <StatCard icon={Building2} label="Companies" value={MOCK_STATS.totalCompanies.approved} subValue={`${MOCK_STATS.totalCompanies.pending} pending verification`} colorClass="bg-blue-50 text-blue-600" />
        <StatCard icon={Users} label="Total Students" value={MOCK_STATS.totalStudents.toLocaleString()} colorClass="bg-purple-50 text-purple-600" />
        <StatCard icon={Briefcase} label="Active Internships" value={MOCK_STATS.activeInternships} colorClass="bg-orange-50 text-orange-600" />
      </div>

      <div className="grid grid-cols-1 lg:grid-cols-3 gap-6">
        <div className="rounded-2xl border border-slate-200 bg-white p-6 lg:col-span-2">
          <h3 className="text-lg font-bold text-slate-900 mb-6">Verification Distribution</h3>
          <div className="h-[300px]">
            <ResponsiveContainer width="100%" height="100%">
              <BarChart data={chartData}>
                <CartesianGrid strokeDasharray="3 3" vertical={false} stroke="#E2E8F0" />
                <XAxis dataKey="name" axisLine={false} tickLine={false} />
                <YAxis axisLine={false} tickLine={false} />
                <Tooltip contentStyle={{ borderRadius: "12px", border: "none", boxShadow: "0 4px 12px rgba(0,0,0,0.1)" }} />
                <Bar dataKey="approved" fill="#0D9488" radius={[4, 4, 0, 0]} name="Approved" />
                <Bar dataKey="pending" fill="#EAB308" radius={[4, 4, 0, 0]} name="Pending" />
              </BarChart>
            </ResponsiveContainer>
          </div>
        </div>

        <div className="rounded-2xl border border-slate-200 bg-white p-6">
          <h3 className="text-lg font-bold text-slate-900 mb-6">Security Alerts</h3>
          <div className="space-y-4">
            <div className="flex items-start gap-3 p-3 rounded-lg bg-red-50 border border-red-100">
              <AlertCircle className="w-5 h-5 text-red-600 mt-0.5" />
              <div>
                <p className="text-sm font-semibold text-red-900">Suspicious Activity</p>
                <p className="text-xs text-red-700">Multiple failed logins from IP 192.168.1.45</p>
              </div>
            </div>
            <div className="flex items-start gap-3 p-3 rounded-lg bg-yellow-50 border border-yellow-100">
              <TrendingUp className="w-5 h-5 text-yellow-600 mt-0.5" />
              <div>
                <p className="text-sm font-semibold text-yellow-900">High Traffic</p>
                <p className="text-xs text-yellow-700">20% increase in student registrations today</p>
              </div>
            </div>
          </div>
          <button className="w-full mt-6 text-sm font-medium text-blue-500 hover:underline">View all security logs</button>
        </div>
      </div>
    </div>
  );
};

export default Dashboard;
