import { 
  VerificationProposal, 
  AuditLogEntry, 
  PlatformStats,
  StudentProfile,
  WeeklyPlan,
  Post,
  CompanyRequest,
  FinalEvaluation
} from './types';

export const MOCK_PROPOSALS: VerificationProposal[] = [
  {
    id: '1',
    organizationName: 'Stanford University',
    organizationType: 'University',
    submittedAt: new Date(Date.now() - 1000 * 60 * 60 * 2).toISOString(), // 2 hours ago
    status: 'Pending',
    documents: ['https://example.com/stanford-credentials.pdf'],
    description: 'Requesting access to the internship portal for our computer science students.',
  },
  {
    id: '2',
    organizationName: 'TechCorp Inc.',
    organizationType: 'Company',
    submittedAt: new Date(Date.now() - 1000 * 60 * 60 * 24).toISOString(), // 1 day ago
    status: 'Pending',
    documents: ['https://example.com/techcorp-license.pdf'],
    description: 'Global technology firm looking to hire interns for software engineering roles.',
  },
  {
    id: '3',
    organizationName: 'MIT',
    organizationType: 'University',
    submittedAt: new Date(Date.now() - 1000 * 60 * 60 * 48).toISOString(), // 2 days ago
    status: 'Approved',
    documents: ['https://example.com/mit-credentials.pdf'],
    description: 'Leading research university seeking to connect students with industry partners.',
    reviewedAt: new Date(Date.now() - 1000 * 60 * 60 * 40).toISOString(),
  },
  {
    id: '4',
    organizationName: 'Fake University',
    organizationType: 'University',
    submittedAt: new Date(Date.now() - 1000 * 60 * 60 * 72).toISOString(), // 3 days ago
    status: 'Rejected',
    documents: ['https://example.com/fake-creds.pdf'],
    description: 'Suspicious application with incomplete documentation.',
    rejectionReason: 'Incomplete documentation and unverified physical address.',
    reviewedAt: new Date(Date.now() - 1000 * 60 * 60 * 60).toISOString(),
  },
];

export const MOCK_AUDIT_LOG: AuditLogEntry[] = [
  {
    id: 'a1',
    action: 'Approve',
    targetId: '3',
    targetName: 'MIT',
    adminId: 'admin_1',
    timestamp: new Date(Date.now() - 1000 * 60 * 60 * 40).toISOString(),
    notes: 'All credentials verified successfully.',
  },
  {
    id: 'a2',
    action: 'Reject',
    targetId: '4',
    targetName: 'Fake University',
    adminId: 'admin_1',
    timestamp: new Date(Date.now() - 1000 * 60 * 60 * 60).toISOString(),
    notes: 'Failed verification check.',
  },
];

export const MOCK_STATS: PlatformStats = {
  totalUniversities: { approved: 45, pending: 12 },
  totalCompanies: { approved: 89, pending: 24 },
  totalStudents: 12450,
  activeInternships: 856,
};

// Student Mock Data
export const MOCK_STUDENT: StudentProfile = {
  id: 's1',
  name: 'John Doe',
  email: 'john.doe@university.edu',
  internshipStatus: 'Placed',
  assignedCompany: 'TechCorp Inc.',
  supervisorName: 'Jane Smith',
  supervisorEmail: 'jane.smith@techcorp.com',
};

export const MOCK_WEEKLY_PLANS: WeeklyPlan[] = [
  {
    id: 'w1',
    weekNumber: 1,
    tasks: 'Initial onboarding and environment setup. Learning the codebase structure.',
    presentationUrl: 'https://example.com/week1-presentation.pdf',
    presentationFileName: 'week1-presentation.pdf',
    status: 'Approved',
    feedback: 'Great start! Keep it up.',
    submittedAt: new Date(Date.now() - 1000 * 60 * 60 * 24 * 7).toISOString(),
    reviewedAt: new Date(Date.now() - 1000 * 60 * 60 * 24 * 6).toISOString(),
    version: 1,
  },
  {
    id: 'w2',
    weekNumber: 2,
    tasks: 'Implementing the user authentication flow using JWT.',
    presentationUrl: 'https://example.com/week2-presentation.pdf',
    presentationFileName: 'week2-presentation.pdf',
    status: 'Rejected',
    feedback: 'Please provide more details about the security measures taken.',
    submittedAt: new Date(Date.now() - 1000 * 60 * 60 * 24 * 2).toISOString(),
    reviewedAt: new Date(Date.now() - 1000 * 60 * 60 * 24 * 1).toISOString(),
    version: 1,
  },
  {
    id: 'w2-v2',
    weekNumber: 2,
    tasks: 'Implementing the user authentication flow using JWT. Added detailed security documentation and error handling.',
    presentationUrl: 'https://example.com/week2-v2-presentation.pdf',
    presentationFileName: 'week2-v2-presentation.pdf',
    status: 'Pending',
    submittedAt: new Date(Date.now() - 1000 * 60 * 60 * 5).toISOString(),
    version: 2,
  },
];

export const MOCK_POSTS: Post[] = [
  {
    id: 'p1',
    authorName: 'Alice Johnson',
    authorRole: 'Student',
    content: 'Just finished my first week at Google! The culture is amazing.',
    timestamp: new Date(Date.now() - 1000 * 60 * 60 * 3).toISOString(),
    likes: 12,
  },
  {
    id: 'p2',
    authorName: 'Bob Smith',
    authorRole: 'Coordinator',
    content: 'Reminder: The deadline for the final report is next Friday.',
    timestamp: new Date(Date.now() - 1000 * 60 * 60 * 24).toISOString(),
    likes: 45,
  },
];

export const MOCK_COMPANY_REQUESTS: CompanyRequest[] = [
  {
    id: 'cr1',
    companyName: 'Innovative Startups Ltd',
    contactEmail: 'hr@innovative.com',
    status: 'Pending',
    requestedAt: new Date(Date.now() - 1000 * 60 * 60 * 48).toISOString(),
  },
];

export const MOCK_FINAL_EVALUATION: FinalEvaluation = {
  technicalScore: 92,
  softSkillScore: 88,
  comments: 'John has been an exceptional intern. He is proactive and learns very quickly.',
  reportUrl: 'https://example.com/final-report.pdf',
};
