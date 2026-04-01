import React, { useState } from 'react';
import { BrowserRouter as Router, Routes, Route, Link, Navigate } from 'react-router-dom';
import Layout from '@/components/layout/Layout';
import AdminSidebar from '@/components/admin/AdminSidebar';
import AdminDashboard from '@/components/admin/AdminDashboard';
import VerificationList from '@/components/admin/VerificationList';
import VerificationDetail from '@/components/admin/VerificationDetail';
import AuditLog from '@/components/admin/AuditLog';

import StudentSidebar from '@/components/student/StudentSidebar';
import StudentDashboard from '@/components/student/StudentDashboard';
import WeeklyPlans from '@/components/student/WeeklyPlans';
import CommonPage from '@/components/student/CommonPage';
import RequestCompany from '@/components/student/RequestCompany';
import FinalEvaluation from '@/components/student/FinalEvaluation';

import { VerificationProposal, AuditLogEntry } from '@/lib/superadmin/types';
import { ShieldCheck, GraduationCap } from 'lucide-react';

export default function App() {
  const [proposals, setProposals] = useState<VerificationProposal[]>([]);
  const [auditLogs, setAuditLogs] = useState<AuditLogEntry[]>([]);
  const [selectedProposal, setSelectedProposal] = useState<VerificationProposal | null>(null);

  const handleApprove = (id: string) => {
    const proposal = proposals.find(p => p.id === id);
    if (!proposal) return;

    const updatedProposals = proposals.map(p => 
      p.id === id ? { ...p, status: 'Approved' as const, reviewedAt: new Date().toISOString() } : p
    );
    setProposals(updatedProposals);

    const newLog: AuditLogEntry = {
      id: `log_${Date.now()}`,
      action: 'Approve',
      targetId: id,
      targetName: proposal.organizationName,
      adminId: 'Admin_1',
      timestamp: new Date().toISOString(),
      notes: 'Organization credentials verified and approved.',
    };
    setAuditLogs([newLog, ...auditLogs]);
    setSelectedProposal(null);
  };

  const handleReject = (id: string, reason: string) => {
    const proposal = proposals.find(p => p.id === id);
    if (!proposal) return;

    const updatedProposals = proposals.map(p => 
      p.id === id ? { ...p, status: 'Rejected' as const, rejectionReason: reason, reviewedAt: new Date().toISOString() } : p
    );
    setProposals(updatedProposals);

    const newLog: AuditLogEntry = {
      id: `log_${Date.now()}`,
      action: 'Reject',
      targetId: id,
      targetName: proposal.organizationName,
      adminId: 'Admin_1',
      timestamp: new Date().toISOString(),
      notes: `Rejected: ${reason}`,
    };
    setAuditLogs([newLog, ...auditLogs]);
    setSelectedProposal(null);
  };

  const handleSuspend = (id: string) => {
    const proposal = proposals.find((p) => p.id === id);
    if (!proposal) return;
    setProposals(
      proposals.map((p) =>
        p.id === id ? { ...p, status: 'Suspended' as const, reviewedAt: new Date().toISOString() } : p
      )
    );
    const newLog: AuditLogEntry = {
      id: `log_${Date.now()}`,
      action: 'Suspend',
      targetId: id,
      targetName: proposal.organizationName,
      adminId: 'Admin_1',
      timestamp: new Date().toISOString(),
      notes: 'Organization suspended after approval.',
    };
    setAuditLogs([newLog, ...auditLogs]);
    setSelectedProposal(null);
  };

  const handleReactivate = (id: string) => {
    const proposal = proposals.find((p) => p.id === id);
    if (!proposal) return;
    setProposals(
      proposals.map((p) =>
        p.id === id ? { ...p, status: 'Approved' as const, reviewedAt: new Date().toISOString() } : p
      )
    );
    const newLog: AuditLogEntry = {
      id: `log_${Date.now()}`,
      action: 'Reactivate',
      targetId: id,
      targetName: proposal.organizationName,
      adminId: 'Admin_1',
      timestamp: new Date().toISOString(),
      notes: 'Organization reactivated.',
    };
    setAuditLogs([newLog, ...auditLogs]);
    setSelectedProposal(null);
  };

  return (
    <Router>
      <Routes>
        {/* Role Selector / Landing Page */}
        <Route path="/" element={
          <div className="min-h-screen bg-bg-secondary flex items-center justify-center p-6">
            <div className="max-w-4xl w-full grid grid-cols-1 md:grid-cols-2 gap-8">
              <Link to="/admin" className="card p-12 flex flex-col items-center text-center hover:border-primary-base transition-all group">
                <div className="bg-primary-light p-6 rounded-2xl mb-6 group-hover:scale-110 transition-transform">
                  <ShieldCheck className="w-12 h-12 text-primary-base" />
                </div>
                <h2 className="text-2xl font-bold mb-2">Admin</h2>
                <p className="text-text-muted">Manage institutional verifications and platform security.</p>
              </Link>
              <Link to="/student" className="card p-12 flex flex-col items-center text-center hover:border-primary-base transition-all group">
                <div className="bg-blue-50 p-6 rounded-2xl mb-6 group-hover:scale-110 transition-transform">
                  <GraduationCap className="w-12 h-12 text-blue-600" />
                </div>
                <h2 className="text-2xl font-bold mb-2">Student Portal</h2>
                <p className="text-text-muted">Track internship progress, submit plans, and view feedback.</p>
              </Link>
            </div>
          </div>
        } />

        {/* Admin Routes */}
        <Route path="/admin" element={<Layout sidebar={<AdminSidebar />} />}>
          <Route index element={<AdminDashboard />} />
          <Route 
            path="pending" 
            element={
              <VerificationList 
                title="Pending Approvals" 
                proposals={proposals.filter(p => p.status === 'Pending')} 
                onReview={setSelectedProposal}
              />
            } 
          />
          <Route 
            path="approved" 
            element={
              <VerificationList 
                title="Approved History" 
                proposals={proposals.filter(p => p.status === 'Approved')} 
                onReview={setSelectedProposal}
              />
            } 
          />
          <Route 
            path="rejected" 
            element={
              <VerificationList 
                title="Rejected History" 
                proposals={proposals.filter(p => p.status === 'Rejected')} 
                onReview={setSelectedProposal}
              />
            } 
          />
          <Route path="audit-log" element={<AuditLog logs={auditLogs} />} />
          <Route path="settings" element={
            <div className="card p-8 text-center">
              <h1 className="text-2xl font-bold mb-4">System Configuration</h1>
              <p className="text-text-muted">Global settings and platform parameters management.</p>
            </div>
          } />
        </Route>

        {/* Student Routes */}
        <Route path="/student" element={<Layout sidebar={<StudentSidebar />} />}>
          <Route index element={<StudentDashboard />} />
          <Route path="plans" element={<WeeklyPlans />} />
          <Route path="common" element={<CommonPage />} />
          <Route path="request-company" element={<RequestCompany />} />
          <Route path="evaluation" element={<FinalEvaluation />} />
        </Route>

        {/* Fallback */}
        <Route path="*" element={<Navigate to="/" replace />} />
      </Routes>

      <VerificationDetail
        proposal={selectedProposal}
        onClose={() => setSelectedProposal(null)}
        onApprove={handleApprove}
        onReject={handleReject}
        onSuspend={handleSuspend}
        onReactivate={handleReactivate}
      />
    </Router>
  );
}
