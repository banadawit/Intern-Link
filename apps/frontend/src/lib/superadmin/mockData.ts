import { VerificationProposal, AuditLogEntry, PlatformStats } from "./types";

export const MOCK_PROPOSALS: VerificationProposal[] = [
  {
    id: "1",
    organizationName: "Stanford University",
    organizationType: "University",
    submittedAt: new Date(Date.now() - 1000 * 60 * 60 * 2).toISOString(),
    status: "Pending",
    documents: ["https://example.com/stanford-credentials.pdf"],
    description:
      "Requesting access to the internship portal for our computer science students.",
  },
  {
    id: "2",
    organizationName: "TechCorp Inc.",
    organizationType: "Company",
    submittedAt: new Date(Date.now() - 1000 * 60 * 60 * 24).toISOString(),
    status: "Pending",
    documents: ["https://example.com/techcorp-license.pdf"],
    description:
      "Global technology firm looking to hire interns for software engineering roles.",
  },
  {
    id: "3",
    organizationName: "MIT",
    organizationType: "University",
    submittedAt: new Date(Date.now() - 1000 * 60 * 60 * 48).toISOString(),
    status: "Approved",
    documents: ["https://example.com/mit-credentials.pdf"],
    description:
      "Leading research university seeking to connect students with industry partners.",
    reviewedAt: new Date(Date.now() - 1000 * 60 * 60 * 40).toISOString(),
  },
  {
    id: "4",
    organizationName: "Fake University",
    organizationType: "University",
    submittedAt: new Date(Date.now() - 1000 * 60 * 60 * 72).toISOString(),
    status: "Rejected",
    documents: ["https://example.com/fake-creds.pdf"],
    description: "Suspicious application with incomplete documentation.",
    rejectionReason: "Incomplete documentation and unverified physical address.",
    reviewedAt: new Date(Date.now() - 1000 * 60 * 60 * 60).toISOString(),
  },
];

export const MOCK_AUDIT_LOG: AuditLogEntry[] = [
  {
    id: "a1",
    action: "Approve",
    targetId: "3",
    targetName: "MIT",
    adminId: "admin_1",
    timestamp: new Date(Date.now() - 1000 * 60 * 60 * 40).toISOString(),
    notes: "All credentials verified successfully.",
  },
  {
    id: "a2",
    action: "Reject",
    targetId: "4",
    targetName: "Fake University",
    adminId: "admin_1",
    timestamp: new Date(Date.now() - 1000 * 60 * 60 * 60).toISOString(),
    notes: "Failed verification check.",
  },
];

export const MOCK_STATS: PlatformStats = {
  totalUniversities: { approved: 45, pending: 12 },
  totalCompanies: { approved: 89, pending: 24 },
  totalStudents: 12450,
  activeInternships: 856,
};
