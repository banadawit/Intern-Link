import { Response } from 'express';
import { AuthRequest } from '../middlewares/authMiddleware';
import prisma from '../config/db';

// 1. Post to Feed (Students/Coordinators/Admins)
export const createPost = async (req: AuthRequest, res: Response) => {
    try {
        const { title, content } = req.body;
        const post = await prisma.announcement.create({
            data: {
                title,
                content,
                authorId: req.user!.userId
            }
        });
        res.status(201).json(post);
    } catch (error: any) {
        res.status(500).json({ error: error.message });
    }
};

// 2. Get All Feed Items (SRS FR-7.3 - Chronological Order)
export const getFeed = async (req: AuthRequest, res: Response) => {
    try {
        const feed = await prisma.announcement.findMany({
            orderBy: { created_at: 'desc' },
            include: { author: { select: { full_name: true, role: true } } }
        });
        res.json(feed);
    } catch (error: any) {
        res.status(500).json({ error: error.message });
    }
};