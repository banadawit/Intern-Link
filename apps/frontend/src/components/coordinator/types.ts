export type CoordinatorDashboardStats = {
  universityId: number;
  hods: { total: number; pending: number; approved: number; rejected: number };
  students: {
    total: number;
    byInternshipStatus: Record<string, number>;
    hodApprovalPending: number;
  };
  proposalsPending: number;
  activeAssignments: number;
  reportsCount: number;
  recentNotifications: Array<{
    id: number;
    message: string;
    is_read: boolean;
    created_at: string;
  }>;
};

export type CoordinatorHodRow = {
  id: number;
  department: string;
  user: {
    id: number;
    email: string;
    full_name: string;
    created_at: string;
    institution_access_approval: string;
    verification_status: string;
  };
  university: { id: number; name: string };
};

export type CoordinatorCompanyRow = {
  id: number;
  name: string;
  official_email: string;
  approval_status: string;
  created_at: string;
  address: string | null;
};
