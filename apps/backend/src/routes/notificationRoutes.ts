import { Router } from 'express';
import { authenticate } from '../middlewares/authMiddleware';
import prisma from '../config/db';
import { AuthRequest } from '../middlewares/authMiddleware';
import { Response } from 'express';
import { sendSuccess, sendError } from '../utils/responseHelper';

const router = Router();
router.use(authenticate);

// GET /notifications — latest 50 for the logged-in user
router.get('/', async (req: AuthRequest, res: Response) => {
    try {
        const notifications = await prisma.notification.findMany({
            where: { recipientId: req.user!.userId },
            orderBy: { created_at: 'desc' },
            take: 50,
        });
        return sendSuccess(res, notifications);
    } catch (e: any) { return sendError(res, e.message); }
});

// GET /notifications/unread-count — fast badge count
router.get('/unread-count', async (req: AuthRequest, res: Response) => {
    try {
        const count = await prisma.notification.count({
            where: { recipientId: req.user!.userId, is_read: false },
        });
        return sendSuccess(res, { count });
    } catch (e: any) { return sendError(res, e.message); }
});

// PATCH /notifications/read-all — must be before /:id/read
router.patch('/read-all', async (req: AuthRequest, res: Response) => {
    try {
        const result = await prisma.notification.updateMany({
            where: { recipientId: req.user!.userId, is_read: false },
            data: { is_read: true },
        });
        return sendSuccess(res, { updated: result.count }, 'All notifications marked as read.');
    } catch (e: any) { return sendError(res, e.message); }
});

// PATCH /notifications/:id/read
router.patch('/:id/read', async (req: AuthRequest, res: Response) => {
    try {
        const id = parseInt(String(req.params.id), 10);
        if (Number.isNaN(id)) return sendError(res, 'Invalid notification id.', 400);
        await prisma.notification.updateMany({
            where: { id, recipientId: req.user!.userId },
            data: { is_read: true },
        });
        return sendSuccess(res, { id }, 'Notification marked as read.');
    } catch (e: any) { return sendError(res, e.message); }
});

export default router;
