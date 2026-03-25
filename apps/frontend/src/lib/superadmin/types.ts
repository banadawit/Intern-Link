export type OrgType = "University" | "Company";
export type VerificationStatus = "Pending" | "Approved" | "Rejected";

export interface VerificationProposal {
  id: string;
  organizationName: string;
  organizationType: OrgType;
  submittedAt: string;
  status: VerificationStatus;
  documents: string[];
  description: string;
  rejectionReason?: string;
  reviewedAt?: string;
}

export interface AuditLogEntry {
  id: string;
  action: "Approve" | "Reject";
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
