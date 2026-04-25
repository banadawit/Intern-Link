import { Router } from 'express';
import { authenticate } from '../middlewares/authMiddleware';
import prisma from '../config/db';
import { AuthRequest } from '../middlewares/authMiddleware';
import { Response } from 'express';

const router = Router();
router.use(authenticate);

// GET /notifications — latest 30 for the logged-in user
router.get('/', async (req: AuthRequest, res: Response) => {
    try {
        const notifications = await prisma.notification.findMany({
            where: { recipientId: req.user!.userId },
            orderBy: { created_at: 'desc' },
            take: 30,
        });
        res.json(notifications);
    } catch (e: any) { res.status(500).json({ error: e.message }); }
});

// PATCH /notifications/read-all — must be before /:id/read
router.patch('/read-all', async (req: AuthRequest, res: Response) => {
    try {
        await prisma.notification.updateMany({
            where: { recipientId: req.user!.userId, is_read: false },
            data: { is_read: true },
        });
        res.json({ ok: true });
    } catch (e: any) { res.status(500).json({ error: e.message }); }
});

// PATCH /notifications/:id/read
router.patch('/:id/read', async (req: AuthRequest, res: Response) => {
    try {
        const id = parseInt(String(req.params.id), 10);
        await prisma.notification.updateMany({
            where: { id, recipientId: req.user!.userId },
            data: { is_read: true },
        });
        res.json({ ok: true });
    } catch (e: any) { res.status(500).json({ error: e.message }); }
});

export default router;
