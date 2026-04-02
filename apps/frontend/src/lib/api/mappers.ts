import type {
  AuditLogEntry,
  CompanyRequest,
  FinalEvaluation,
  Post,
  StudentProfile,
  VerificationProposal,
  VerificationStatus,
  WeeklyPlan,
  PlanStatus,
  InternshipStatus,
} from "@/lib/superadmin/types";
import { apiFileUrl } from "./publicUrl";

export function mapPlanStatus(s: string): PlanStatus {
  const m: Record<string, PlanStatus> = {
    PENDING: "Pending",
    APPROVED: "Approved",
    REJECTED: "Rejected",
  };
  return m[s] ?? "Pending";
}

export function mapVerificationStatus(s: string): VerificationStatus {
  const m: Record<string, VerificationStatus> = {
    PENDING: "Pending",
    APPROVED: "Approved",
    REJECTED: "Rejected",
    SUSPENDED: "Suspended",
  };
  return m[s] ?? "Pending";
}

export function mapInternshipStatus(s: string): InternshipStatus {
  const m: Record<string, InternshipStatus> = {
    PENDING: "Pending Placement",
    PLACED: "Placed",
    COMPLETED: "Completed",
  };
  return m[s] ?? "Pending Placement";
}

/** Prisma WeeklyPlan row from API */
export function mapWeeklyPlanRow(p: {
  id: number;
  week_number: number;
  plan_description: string;
  status: string;
  submitted_at: string;
  feedback?: string | null;
  reviewed_at?: string | null;
  version?: number;
  presentation?: { file_url: string } | null;
  day_submissions?: { workDate: string | Date }[];
  daySubmissions?: { workDate: string | Date }[];
}): WeeklyPlan {
  const url = p.presentation?.file_url ? apiFileUrl(p.presentation.file_url) : undefined;
  const path = p.presentation?.file_url ?? "";
  const fileName = path.split(/[/\\]/).pop() || "presentation";
  const rawDays = p.day_submissions ?? p.daySubmissions ?? [];
  return {
    id: String(p.id),
    weekNumber: p.week_number,
    tasks: p.plan_description,
    presentationUrl: url || undefined,
    presentationFileName: p.presentation ? fileName : undefined,
    status: mapPlanStatus(p.status),
    feedback: p.feedback ?? undefined,
    submittedAt: p.submitted_at,
    reviewedAt: p.reviewed_at ?? undefined,
    version: p.version ?? 1,
    daySubmissions: rawDays.map((d) => ({
      workDate:
        typeof d.workDate === "string"
          ? d.workDate.slice(0, 10)
          : new Date(d.workDate).toISOString().slice(0, 10),
    })),
  };
}

export type StudentMeResponse = {
  id: number;
  userId: number;
  internship_status: string;
  user?: { full_name: string; email: string };
  activeAssignment?: {
    company?: { name: string };
    start_date: string;
  } | null;
  supervisor?: { full_name: string; email: string } | null;
  currentInternshipWeek?: number;
};

export function mapStudentProfileFromMe(data: StudentMeResponse): StudentProfile {
  const assignment = data.activeAssignment;
  return {
    id: String(data.id),
    name: data.user?.full_name ?? "",
    email: data.user?.email ?? "",
    internshipStatus: mapInternshipStatus(data.internship_status),
    assignedCompany: assignment?.company?.name,
    supervisorName: data.supervisor?.full_name,
    supervisorEmail: data.supervisor?.email,
    currentInternshipWeek: data.currentInternshipWeek ?? 1,
    placementStartDate: assignment?.start_date,
  };
}

export function mapUniversityToProposal(u: {
  id: number;
  name: string;
  created_at: string;
  approval_status: string;
  verification_doc?: string | null;
  address?: string | null;
  rejection_reason?: string | null;
}): VerificationProposal {
  return {
    id: `uni-${u.id}`,
    organizationName: u.name,
    organizationType: "University",
    submittedAt: typeof u.created_at === "string" ? u.created_at : new Date(u.created_at).toISOString(),
    status: mapVerificationStatus(u.approval_status),
    documents: u.verification_doc ? [apiFileUrl(u.verification_doc)] : [],
    description: u.address ?? "",
    rejectionReason: u.rejection_reason ?? undefined,
  };
}

export function mapCompanyToProposal(c: {
  id: number;
  name: string;
  created_at: string;
  approval_status: string;
  verification_doc?: string | null;
  address?: string | null;
  rejection_reason?: string | null;
}): VerificationProposal {
  return {
    id: `com-${c.id}`,
    organizationName: c.name,
    organizationType: "Company",
    submittedAt: typeof c.created_at === "string" ? c.created_at : new Date(c.created_at).toISOString(),
    status: mapVerificationStatus(c.approval_status),
    documents: c.verification_doc ? [apiFileUrl(c.verification_doc)] : [],
    description: c.address ?? "",
    rejectionReason: c.rejection_reason ?? undefined,
  };
}

export function parseProposalId(
  id: string
): { kind: "university" | "company"; numericId: number } | null {
  if (id.startsWith("uni-")) {
    const n = parseInt(id.slice(4), 10);
    return Number.isFinite(n) ? { kind: "university", numericId: n } : null;
  }
  if (id.startsWith("com-")) {
    const n = parseInt(id.slice(4), 10);
    return Number.isFinite(n) ? { kind: "company", numericId: n } : null;
  }
  return null;
}

export function mapFeedAnnouncement(a: {
  id: number;
  title: string;
  content: string;
  created_at: string;
  author?: { full_name: string; role: string };
}): Post {
  return {
    id: String(a.id),
    authorName: a.author?.full_name ?? "User",
    authorRole: a.author?.role ?? "",
    content: a.title ? `${a.title}\n\n${a.content}` : a.content,
    timestamp: typeof a.created_at === "string" ? a.created_at : new Date(a.created_at).toISOString(),
    likes: 0,
  };
}

export type PlacementProposalApi = {
  id: number;
  status: string;
  submitted_at: string;
  company: { name: string; official_email: string };
};

export function mapPlacementToCompanyRequest(p: PlacementProposalApi): CompanyRequest {
  const st = p.status;
  let status: CompanyRequest["status"] = "Pending";
  if (st === "APPROVED") status = "Onboarded";
  else if (st === "REJECTED") status = "Pending";
  else if (st === "PENDING") status = "Pending";
  return {
    id: String(p.id),
    companyName: p.company.name,
    contactEmail: p.company.official_email,
    status,
    requestedAt:
      typeof p.submitted_at === "string" ? p.submitted_at : new Date(p.submitted_at).toISOString(),
  };
}

function mapAuditAction(action: string): AuditLogEntry["action"] {
  const u = action.toUpperCase();
  if (u.includes("REJECT")) return "Reject";
  if (u.includes("SUSPEND")) return "Suspend";
  if (u.includes("REACTIVATE")) return "Reactivate";
  return "Approve";
}

export function mapAuditApiToEntry(l: {
  id: number;
  adminId: number;
  action: string;
  targetId: number;
  details?: string | null;
  timestamp: string;
  admin?: { full_name: string; email: string } | null;
}): AuditLogEntry {
  return {
    id: String(l.id),
    action: mapAuditAction(l.action),
    targetId: String(l.targetId),
    targetName: l.details?.slice(0, 120) || `Target #${l.targetId}`,
    adminId: l.admin?.full_name ?? `Admin #${l.adminId}`,
    timestamp: typeof l.timestamp === "string" ? l.timestamp : new Date(l.timestamp).toISOString(),
    notes: l.details ?? undefined,
  };
}

export type EvaluationWithMeta = FinalEvaluation & {
  supervisorName: string;
  companyName: string;
  evaluatedAt: string;
};

export function mapEvaluationApi(e: {
  technicalScore: number;
  softSkillScore: number;
  comments: string;
  evaluatedAt: string;
  supervisorName: string;
  companyName: string;
}): EvaluationWithMeta {
  return {
    technicalScore: e.technicalScore,
    softSkillScore: e.softSkillScore,
    comments: e.comments,
    reportUrl: "#",
    supervisorName: e.supervisorName,
    companyName: e.companyName,
    evaluatedAt: e.evaluatedAt,
  };
}
