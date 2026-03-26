import { Response } from 'express';
import { AuthRequest } from '../middlewares/authMiddleware';
import prisma from '../config/db';

export const setupCompany = async (req: AuthRequest, res: Response) => {
    try {
        const { name, official_email, address } = req.body;
        const userId = req.user?.userId;

        // Get the uploaded file path from Multer
        const stampUrl = req.file ? req.file.path : null;

        // 1. Check if user is already a supervisor
        const existingSupervisor = await prisma.supervisor.findUnique({ where: { userId } });
        if (existingSupervisor) {
            return res.status(400).json({ message: "You are already linked to a company." });
        }

        // 2. Create Company and link the Supervisor
        const company = await prisma.company.create({
            data: {
                name,
                official_email,
                address,
                stamp_image_url: stampUrl, // Save the path to the uploaded image
                approval_status: 'PENDING',
                supervisors: {
                    create: {
                        userId: userId!,
                        phone_number: req.body.phone_number || ""
                    }
                }
            }
        });

        res.status(201).json({ message: "Company created. Awaiting admin approval.", company });
    } catch (error: any) {
        res.status(500).json({ error: error.message });
    }
};

export const getMyCompanyProfile = async (req: AuthRequest, res: Response) => {
    try {
        const supervisor = await prisma.supervisor.findUnique({
            where: { userId: req.user?.userId },
            include: { company: true }
        });
        if (!supervisor) return res.status(404).json({ message: "Company not found" });
        res.json(supervisor.company);
    } catch (error: any) {
        res.status(500).json({ error: error.message });
    }
};