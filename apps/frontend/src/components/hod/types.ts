export type HodStats = {
  totalStudents: number;
  pendingApprovals: number;
  approvedStudents: number;
  rejectedStudents: number;
  placedStudents: number;
  approvedNotPlaced: number;
  reports: number;
  proposals: { pending: number; approved: number; rejected: number };
  recentPendingStudents: { id: number; full_name: string; email: string }[];
  university: { name: string };
  department: string;
  // Enhanced stats
  placementRate: number;
  reportsCompletionRate: number;
  approvalSuccessRate: number;
  alerts: {
    type: 'UNPLACED' | 'NEEDS_REASSIGNMENT' | 'INACTIVE';
    message: string;
    studentId: number;
    studentName: string;
    daysElapsed?: number;
  }[];
  weeklyPlacementTrend: { weekLabel: string; weekStart: string; count: number }[];
};

export type HodStudentRow = {
  id: number;
  hod_approval_status: string;
  internship_status: string;
  department: string | null;
  studentId: string | null;
  flag_type: string | null;
  flag_note: string | null;
  user: { full_name: string; email: string; verification_document: string | null };
  latestProposal: {
    id: number;
    status: string;
    companyId: number;
    companyName: string;
    submittedAt: string;
    proposalType: string;
  } | null;
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
  student: {
    user: { full_name: string; email: string };
    finalEvaluation: {
      technical_skills: number;
      problem_solving: number;
      communication: number;
      team_collaboration: number;
      time_management: number;
      adaptability: number;
      professionalism: number;
      initiative_creativity: number;
      attendance_punctuality: number;
      task_completion_quality: number;
      comments: string | null;
      evaluated_at: string;
    } | null;
  };
};
