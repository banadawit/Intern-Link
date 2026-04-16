import { Response } from 'express';
import { AuthRequest } from '../middlewares/authMiddleware';
import prisma from '../config/db';
import { attachProposalSla } from '../utils/verificationSla';
import { sendInternshipAcceptanceEmail, sendInternshipRejectionEmail } from '../services/email.service';

// 1. COORDINATOR: Send Placement Proposal to a Company
export const sendPlacementProposal = async (req: AuthRequest, res: Response) => {
    try {
        const { studentId, companyId, proposal_type, expected_duration_weeks, expected_outcomes } = req.body;
        const coordinatorUserId = req.user?.userId;

        // Verify Coordinator exists and get their University ID
        const coordinator = await prisma.coordinator.findUnique({
            where: { userId: coordinatorUserId }
        });

        if (!coordinator) return res.status(403).json({ message: "Coordinator profile not found." });

        // Verify Student belongs to this University
        const student = await prisma.student.findUnique({ where: { id: studentId } });
        if (!student || student.universityId !== coordinator.universityId) {
            return res.status(400).json({ message: "Student does not belong to your university." });
        }
        if (student.hod_approval_status !== 'APPROVED') {
            return res.status(400).json({ message: "Student must be approved by the Head of Department before placement." });
        }

        const pendingDup = await prisma.internshipProposal.findFirst({
            where: { studentId, companyId, status: 'PENDING' },
        });
        if (pendingDup) {
            return res.status(400).json({ message: "A pending proposal already exists for this student and company." });
        }

        // Create the proposal
        const proposal = await prisma.internshipProposal.create({
            data: {
                studentId,
                companyId,
                universityId: coordinator.universityId,
                proposal_type: proposal_type || "University_Initiated",
                status: 'PENDING',
                expected_duration_weeks:
                    expected_duration_weeks != null ? parseInt(String(expected_duration_weeks), 10) : null,
                expected_outcomes: typeof expected_outcomes === 'string' ? expected_outcomes : null,
            }
        });

        res.status(201).json({ message: "Proposal sent to company.", proposal });
    } catch (error: any) {
        res.status(500).json({ error: error.message });
    }
};

/** STUDENT: list internship proposals for this student */
export const getMyProposals = async (req: AuthRequest, res: Response) => {
    try {
        const student = await prisma.student.findUnique({
            where: { userId: req.user?.userId },
        });
        if (!student) return res.status(403).json({ message: "Student profile not found." });

        const proposals = await prisma.internshipProposal.findMany({
            where: { studentId: student.id },
            orderBy: { submitted_at: "desc" },
            include: {
                company: { select: { id: true, name: true, official_email: true } },
                university: { select: { id: true, name: true } },
            },
        });
        res.json(proposals);
    } catch (error: any) {
        res.status(500).json({ error: error.message });
    }
};

// 2. SUPERVISOR: Get Proposals sent to their Company
export const getIncomingProposals = async (req: AuthRequest, res: Response) => {
    try {
        const supervisor = await prisma.supervisor.findUnique({
            where: { userId: req.user?.userId }
        });

        if (!supervisor) return res.status(403).json({ message: "Supervisor profile not found." });

        const proposals = await prisma.internshipProposal.findMany({
            where: { companyId: supervisor.companyId, status: 'PENDING' },
            include: {
                student: { include: { user: { select: { full_name: true, email: true } } } },
                university: true,
            },
        });

        const withSla = proposals.map((p) => attachProposalSla(p));
        res.json(withSla);
    } catch (error: any) {
        res.status(500).json({ error: error.message });
    }
};

// 3. SUPERVISOR: Accept or Reject Proposal
export const respondToProposal = async (req: AuthRequest, res: Response) => {
    try {
        const { id } = req.params;
        const { status, reason } = req.body as { status: 'APPROVED' | 'REJECTED'; reason?: string };
        const proposalId = parseInt(String(Array.isArray(id) ? id[0] : id), 10);

        const supervisorProfile = await prisma.supervisor.findUnique({
            where: { userId: req.user?.userId },
            include: { user: { select: { full_name: true } } },
        });
        if (!supervisorProfile) return res.status(403).json({ message: 'Supervisor profile not found.' });

        const existing = await prisma.internshipProposal.findUnique({ where: { id: proposalId } });
        if (!existing || existing.companyId !== supervisorProfile.companyId) {
            return res.status(403).json({ message: 'This proposal does not belong to your company.' });
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
                // Reset student to PENDING so HOD can reassign to another company
                await tx.student.update({
                    where: { id: proposal.studentId },
                    data: { internship_status: 'PENDING' },
                });
            }

            return proposal;
        });

        res.json({ message: `Proposal ${status}`, result });

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
        res.status(500).json({ error: error.message });
    }
};