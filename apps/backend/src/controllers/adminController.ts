import { Response } from 'express';
import { AuthRequest } from '../middlewares/authMiddleware';
import prisma from '../config/db';

// --- INSTITUTION MANAGEMENT ---

// Get all pending Universities and Companies
export const getDashboardStats = async (req: AuthRequest, res: Response) => {
    try {
        const pendingUniversities = await prisma.university.count({ where: { approval_status: 'PENDING' } });
        const pendingCompanies = await prisma.company.count({ where: { approval_status: 'PENDING' } });
        const totalUsers = await prisma.user.count();

        res.json({
            pendingUniversities,
            pendingCompanies,
            totalUsers
        });
    } catch (error: any) {
        res.status(500).json({ error: error.message });
    }
};

// List all pending universities
export const getPendingUniversities = async (req: AuthRequest, res: Response) => {
    const universities = await prisma.university.findMany({
        where: { approval_status: 'PENDING' }
    });
    res.json(universities);
};

// List all pending companies
export const getPendingCompanies = async (req: AuthRequest, res: Response) => {
    const companies = await prisma.company.findMany({
        where: { approval_status: 'PENDING' }
    });
    res.json(companies);
};

// Approve or Reject University
export const updateUniversityStatus = async (req: AuthRequest, res: Response) => {
    const { id } = req.params;
    const { status } = req.body; // 'APPROVED' or 'REJECTED'
    try {
        const universityId = Array.isArray(id) ? id[0] : id;
        const updated = await prisma.university.update({
            where: { id: parseInt(universityId) },
            data: { approval_status: status }
        });
        res.json({ message: `University ${status}`, updated });
    } catch (error: any) {
        res.status(400).json({ error: "Update failed" });
    }
};

// Approve or Reject Company
export const updateCompanyStatus = async (req: AuthRequest, res: Response) => {
    const { id } = req.params;
    const { status } = req.body;
    try {
        const companyId = Array.isArray(id) ? id[0] : id;
        const updated = await prisma.company.update({
            where: { id: parseInt(companyId) },
            data: { approval_status: status }
        });
        res.json({ message: `Company ${status}`, updated });
    } catch (error: any) {
        res.status(400).json({ error: "Update failed" });
    }
};

// --- USER MANAGEMENT ---

// View all users in the system
export const getAllUsers = async (req: AuthRequest, res: Response) => {
    const users = await prisma.user.findMany({
        select: { id: true, full_name: true, email: true, role: true, verification_status: true, created_at: true }
    });
    res.json(users);
};

// --- SYSTEM ANNOUNCEMENTS (SRS FR-7.2) ---
export const postAnnouncement = async (req: AuthRequest, res: Response) => {
    const { title, content } = req.body;
    try {
        const announcement = await prisma.announcement.create({
            data: {
                title,
                content,
                authorId: req.user!.userId
            }
        });
        res.status(201).json(announcement);
    } catch (error: any) {
        res.status(500).json({ error: error.message });
    }
};


export const verifyInstitution = async (req: AuthRequest, res: Response) => {
    try {
        const { id } = req.params;
        const { type, status, reason } = req.body; // type: 'UNIVERSITY' or 'COMPANY'
        const adminId = req.user!.userId;

        let updatedRecord;

        const institutionId = Array.isArray(id) ? id[0] : id;
        if (type === 'UNIVERSITY') {
            updatedRecord = await prisma.university.update({
                where: { id: parseInt(institutionId) },
                data: {
                    approval_status: status
                }
            });
        } else {
            updatedRecord = await prisma.company.update({
                where: { id: parseInt(institutionId) },
                data: {
                    approval_status: status
                }
            });
        }

        // --- THE AUDIT LOG (Requirement FR23) ---
        await prisma.auditLog.create({
            data: {
                adminId,
                action: `${status}_${type}`,
                targetId: parseInt(institutionId),
                details: status === 'REJECTED' ? `Reason: ${reason}` : `Approved ${type}`
            }
        });

        res.json({ message: `Verification processed as ${status}`, updatedRecord });
    } catch (error: any) {
        res.status(500).json({ error: error.message });
    }
};