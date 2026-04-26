import { Response } from 'express';
import { AuthRequest } from '../middlewares/authMiddleware';
import prisma from '../config/db';
import { attachProposalSla } from '../utils/verificationSla';
import { sendInternshipAcceptanceEmail, sendInternshipRejectionEmail } from '../services/email.service';
import { sendSuccess, sendError } from '../utils/responseHelper';
import { Role } from '@prisma/client';

// 1. COORDINATOR / HOD: Send Placement Proposal to a Company
export const sendPlacementProposal = async (req: AuthRequest, res: Response) => {
    try {
        const { studentId, companyId, proposal_type, expected_duration_weeks, expected_outcomes } = req.body;
        const userId = req.user?.userId;
        const role = req.user?.role;

        let universityId: number | null = null;

        if (role === Role.COORDINATOR) {
            const coordinator = await prisma.coordinator.findUnique({ where: { userId } });
            if (!coordinator || !coordinator.universityId) {
                return sendError(res, "Coordinator profile not linked to a university.", 403);
            }
            universityId = coordinator.universityId;
        } else if (role === Role.HOD) {
            const hod = await prisma.hodProfile.findUnique({ where: { userId } });
            if (!hod) return sendError(res, "HoD profile not found.", 403);
            universityId = hod.universityId;
        }

        if (!universityId) return sendError(res, "Unauthorized role for this action.", 403);

        // Verify Student belongs to this University
        const student = await prisma.student.findUnique({ where: { id: studentId } });
        if (!student || student.universityId !== universityId) {
            return sendError(res, "Student does not belong to your university.", 400);
        }
        
        // HOD must have approved student for university-led placement
        if (student.hod_approval_status !== 'APPROVED') {
            return sendError(res, "Student must be approved by the Head of Department before placement.", 400);
        }

        const pendingDup = await prisma.internshipProposal.findFirst({
            where: { studentId, companyId, status: 'PENDING' },
        });
        if (pendingDup) {
            return sendError(res, "A pending proposal already exists for this student and company.", 400);
        }

        // Create the proposal
        const proposal = await prisma.internshipProposal.create({
            data: {
                studentId,
                companyId,
                universityId,
                proposal_type: proposal_type || (role === Role.HOD ? "HoD_Initiated" : "University_Initiated"),
                status: 'PENDING',
                expected_duration_weeks: expected_duration_weeks != null ? parseInt(String(expected_duration_weeks), 10) : null,
                expected_outcomes: typeof expected_outcomes === 'string' ? expected_outcomes : null,
            },
            include: {
                student: { include: { user: { select: { full_name: true, email: true } } } },
                company: { select: { name: true } },
                university: { select: { name: true } },
            },
        });

        // Notify all supervisors of the target company
        const supervisors = await prisma.supervisor.findMany({
            where: { companyId },
            select: { userId: true, user: { select: { full_name: true } } },
        });
        const { sendNotification } = await import('../utils/notificationHelper');
        for (const sup of supervisors) {
            await sendNotification(
                sup.userId,
                `📋 New internship proposal: ${proposal.student.user.full_name} from ${proposal.university.name} is applying for an internship at your company. Please review and respond within 24 hours.`
            );
        }

        return sendSuccess(res, proposal, "Proposal sent to company.", 201);
    } catch (error: any) {
        return sendError(res, error.message);
    }
};

/** STUDENT: list internship proposals for this student */
export const getMyProposals = async (req: AuthRequest, res: Response) => {
    try {
        const student = await prisma.student.findUnique({
            where: { userId: req.user?.userId },
        });
        if (!student) return sendError(res, "Student profile not found.", 403);

        const proposals = await prisma.internshipProposal.findMany({
            where: { studentId: student.id },
            orderBy: { submitted_at: "desc" },
            include: {
                company: { select: { id: true, name: true, official_email: true } },
                university: { select: { id: true, name: true } },
            },
        });
        return sendSuccess(res, proposals);
    } catch (error: any) {
        return sendError(res, error.message);
    }
};

// 2. SUPERVISOR: Get Proposals sent to their Company
export const getIncomingProposals = async (req: AuthRequest, res: Response) => {
    try {
        const supervisor = await prisma.supervisor.findUnique({
            where: { userId: req.user?.userId }
        });

        if (!supervisor) return sendError(res, "Supervisor profile not found.", 403);

        const proposals = await prisma.internshipProposal.findMany({
            where: { companyId: supervisor.companyId, status: 'PENDING' },
            include: {
                student: {
                    include: {
                        user: { select: { full_name: true, email: true, verification_document: true } },
                        university: { select: { name: true } },
                    },
                },
                university: true,
            },
            orderBy: { submitted_at: 'desc' },
        });

        const withSla = proposals.map((p) => attachProposalSla(p));
        return sendSuccess(res, withSla);
    } catch (error: any) {
        return sendError(res, error.message);
    }
};

// 3. SUPERVISOR: Accept or Reject Proposal
export const respondToProposal = async (req: AuthRequest, res: Response) => {
    try {
        const { id } = req.params;
        const { status, reason } = req.body as { status: 'APPROVED' | 'REJECTED'; reason?: string };
        const proposalId = parseInt(String(id), 10);

        const supervisorProfile = await prisma.supervisor.findUnique({
            where: { userId: req.user?.userId },
            include: { user: { select: { full_name: true } } },
        });
        if (!supervisorProfile) return sendError(res, 'Supervisor profile not found.', 403);

        const existing = await prisma.internshipProposal.findUnique({ where: { id: proposalId } });
        if (!existing || existing.companyId !== supervisorProfile.companyId) {
            return sendError(res, 'This proposal does not belong to your company.', 403);
        }

        const result = await prisma.$transaction(async (tx) => {
            const now = new Date();
            const proposal = await tx.internshipProposal.update({
                where: { id: proposalId },
                data: { status, responded_at: now },
                include: {
                    student: { include: { user: { select: { email: true, full_name: true } } } },
                    company: { select: { name: true } },
                },
            });

            if (status === 'APPROVED') {
                let endDate: Date | null = null;
                if (proposal.expected_duration_weeks != null && proposal.expected_duration_weeks > 0) {
                    const end = new Date(now);
                    end.setDate(end.getDate() + proposal.expected_duration_weeks * 7);
                    endDate = end;
                }
                await tx.internshipAssignment.create({
                    data: {
                        studentId: proposal.studentId,
                        companyId: proposal.companyId,
                        start_date: now,
                        end_date: endDate,
                        status: 'ACTIVE',
                    },
                });
                await tx.student.update({
                    where: { id: proposal.studentId },
                    data: { internship_status: 'PLACED' },
                });
            }

            if (status === 'REJECTED') {
                await tx.student.update({
                    where: { id: proposal.studentId },
                    data: { internship_status: 'PENDING' },
                });
            }

            return proposal;
        });

        sendSuccess(res, result, `Proposal ${status}`);

        // Post-response emails (fire-and-forget)
        if (status === 'APPROVED') {
            sendInternshipAcceptanceEmail({
                to: result.student.user.email,
                studentName: result.student.user.full_name,
                companyName: result.company.name,
                supervisorName: supervisorProfile.user.full_name,
                startDate: new Date().toLocaleDateString('en-US', { year: 'numeric', month: 'long', day: 'numeric' }),
            }).catch((e) => console.error('Acceptance email error:', e?.message));
        }

        if (status === 'REJECTED') {
            const rejectionReason = (typeof reason === 'string' && reason.trim())
                ? reason.trim()
                : 'The company was unable to accommodate your application at this time.';

            sendInternshipRejectionEmail({
                to: result.student.user.email,
                studentName: result.student.user.full_name,
                companyName: result.company.name,
                supervisorName: supervisorProfile.user.full_name,
                reason: rejectionReason,
            }).catch((e) => console.error('Rejection email error:', e?.message));
        }

    } catch (error: any) {
        return sendError(res, error.message);
    }
};
