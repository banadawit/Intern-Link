import { Response } from 'express';
import { AuthRequest } from '../middlewares/authMiddleware';
import prisma from '../config/db';
import { ApprovalStatus } from '@prisma/client';

// 1. COORDINATOR: Send Placement Proposal to a Company
export const sendPlacementProposal = async (req: AuthRequest, res: Response) => {
    try {
        const { studentId, companyId, proposal_type } = req.body;
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

        // Create the proposal
        const proposal = await prisma.internshipProposal.create({
            data: {
                studentId,
                companyId,
                universityId: coordinator.universityId,
                proposal_type: proposal_type || "University_Initiated",
                status: 'PENDING'
            }
        });

        res.status(201).json({ message: "Proposal sent to company.", proposal });
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
                university: true
            }
        });

        res.json(proposals);
    } catch (error: any) {
        res.status(500).json({ error: error.message });
    }
};

// 3. SUPERVISOR: Accept or Reject Proposal
export const respondToProposal = async (req: AuthRequest, res: Response) => {
    try {
        const { id } = req.params; // Proposal ID
        const { status } = req.body; // 'APPROVED' (Accept) or 'REJECTED'

        // Ensure id is a string (handle string | string[])
        const proposalId = Array.isArray(id) ? id[0] : id;

        // Start a Transaction (FR-4.6 Automation)
        const result = await prisma.$transaction(async (tx) => {
            // Update Proposal Status
            const proposal = await tx.internshipProposal.update({
                where: { id: parseInt(proposalId) },
                data: { status }
            });

            if (status === 'APPROVED') {
                // 1. Create Internship Assignment
                await tx.internshipAssignment.create({
                    data: {
                        studentId: proposal.studentId,
                        companyId: proposal.companyId,
                        start_date: new Date(),
                        status: 'ACTIVE'
                    }
                });

                // 2. Update Student Status to PLACED
                await tx.student.update({
                    where: { id: proposal.studentId },
                    data: { internship_status: 'PLACED' }
                });
            }

            return proposal;
        });

        res.json({ message: `Proposal ${status}`, result });
    } catch (error: any) {
        res.status(500).json({ error: error.message });
    }
};