export type HodStats = {
  totalStudents: number;
  pendingApprovals: number;
  placedStudents: number;
  reports: number;
};

export type HodStudentRow = {
  id: number;
  hod_approval_status: string;
  internship_status: string;
  department: string | null;
  user: { full_name: string; email: string };
};

export type HodCompanyRow = {
  id: number;
  name: string;
  official_email: string;
  address: string | null;
  approval_status: string;
  created_at: string;
  supervisorCount: number;
  activePlacementsCount: number;
};

export type HodProposalRow = {
  id: number;
  status: string;
  proposal_type: string;
  submitted_at: string;
  expected_duration_weeks: number | null;
  student: { user: { full_name: string; email: string } };
  company: { id: number; name: string };
};

export type HodReportRow = {
  id: number;
  pdf_url: string;
  stamped: boolean;
  generated_at: string;
  student: { user: { full_name: string; email: string } };
};
