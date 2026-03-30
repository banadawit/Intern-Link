export type OrgType = 'University' | 'Company';
export type VerificationStatus = 'Pending' | 'Approved' | 'Rejected';

export interface VerificationProposal {
  id: string;
  organizationName: string;
  organizationType: OrgType;
  submittedAt: string;
  status: VerificationStatus;
  documents: string[]; // URLs to PDFs
  description: string;
  rejectionReason?: string;
  reviewedAt?: string;
}

export interface AuditLogEntry {
  id: string;
  action: 'Approve' | 'Reject';
  targetId: string;
  targetName: string;
  adminId: string;
  timestamp: string;
  notes?: string;
}

export interface PlatformStats {
  totalUniversities: { approved: number; pending: number };
  totalCompanies: { approved: number; pending: number };
  totalStudents: number;
  activeInternships: number;
}

// Student Types
export type InternshipStatus = 'Pending Placement' | 'Placed' | 'Completed';
export type PlanStatus = 'Pending' | 'Approved' | 'Rejected';

export interface WeeklyPlan {
  id: string;
  weekNumber: number;
  tasks: string;
  presentationUrl?: string;
  /** Original filename when uploaded in the student UI (for display with blob URLs). */
  presentationFileName?: string;
  status: PlanStatus;
  feedback?: string;
  submittedAt: string;
  reviewedAt?: string;
  version: number;
}

export interface Post {
  id: string;
  authorName: string;
  authorRole: string;
  content: string;
  timestamp: string;
  likes: number;
}

export interface CompanyRequest {
  id: string;
  companyName: string;
  contactEmail: string;
  status: 'Pending' | 'Invited' | 'Onboarded';
  requestedAt: string;
}

export interface FinalEvaluation {
  technicalScore: number;
  softSkillScore: number;
  comments: string;
  reportUrl: string;
}

export interface StudentProfile {
  id: string;
  name: string;
  email: string;
  internshipStatus: InternshipStatus;
  assignedCompany?: string;
  supervisorName?: string;
  supervisorEmail?: string;
}
