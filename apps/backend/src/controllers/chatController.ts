import { Response } from 'express';
import { AuthRequest } from '../middlewares/authMiddleware';
import prisma from '../config/db';

const ME = (req: AuthRequest) => req.user!.userId;

// GET /chat/conversations — list all users this user has chatted with + unread count
export const getConversations = async (req: AuthRequest, res: Response) => {
    try {
        const me = ME(req);

        // Find all distinct users this user has exchanged messages with
        const sent = await prisma.chatMessage.findMany({
            where: { senderId: me },
            select: { receiverId: true },
            distinct: ['receiverId'],
        });
        const received = await prisma.chatMessage.findMany({
            where: { receiverId: me },
            select: { senderId: true },
            distinct: ['senderId'],
        });

        const partnerIds = [...new Set([
            ...sent.map((m) => m.receiverId),
            ...received.map((m) => m.senderId),
        ])];

        const partners = await prisma.user.findMany({
            where: { id: { in: partnerIds } },
            select: { id: true, full_name: true, role: true },
        });

        // Last message + unread count per partner
        const conversations = await Promise.all(partners.map(async (p) => {
            const last = await prisma.chatMessage.findFirst({
                where: {
                    OR: [
                        { senderId: me, receiverId: p.id },
                        { senderId: p.id, receiverId: me },
                    ],
                },
                orderBy: { created_at: 'desc' },
                select: { content: true, created_at: true, senderId: true },
            });
            const unread = await prisma.chatMessage.count({
                where: { senderId: p.id, receiverId: me, is_read: false },
            });
            return { partner: p, lastMessage: last, unreadCount: unread };
        }));

        // Sort by last message time
        conversations.sort((a, b) => {
            const ta = a.lastMessage?.created_at?.getTime() ?? 0;
            const tb = b.lastMessage?.created_at?.getTime() ?? 0;
            return tb - ta;
        });

        res.json(conversations);
    } catch (e: any) {
        res.status(500).json({ error: e.message });
    }
};

// GET /chat/:userId — get messages between me and userId, mark as read
export const getMessages = async (req: AuthRequest, res: Response) => {
    try {
        const me = ME(req);
        const other = parseInt(String(req.params.userId), 10);
        const limit = Math.min(100, parseInt(String(req.query.limit ?? '50'), 10));

        const messages = await prisma.chatMessage.findMany({
            where: {
                OR: [
                    { senderId: me, receiverId: other },
                    { senderId: other, receiverId: me },
                ],
            },
            orderBy: { created_at: 'asc' },
            take: limit,
            select: {
                id: true, content: true, created_at: true,
                senderId: true, receiverId: true, is_read: true,
            },
        });

        // Mark incoming messages as read
        await prisma.chatMessage.updateMany({
            where: { senderId: other, receiverId: me, is_read: false },
            data: { is_read: true },
        });

        res.json(messages);
    } catch (e: any) {
        res.status(500).json({ error: e.message });
    }
};

// POST /chat/:userId — send a message
export const sendMessage = async (req: AuthRequest, res: Response) => {
    try {
        const me = ME(req);
        const other = parseInt(String(req.params.userId), 10);
        const content = typeof req.body?.content === 'string' ? req.body.content.trim() : '';
        if (!content) return res.status(400).json({ error: 'Message content is required.' });

        // Verify receiver exists
        const receiver = await prisma.user.findUnique({ where: { id: other }, select: { id: true } });
        if (!receiver) return res.status(404).json({ error: 'User not found.' });

        const message = await prisma.chatMessage.create({
            data: { senderId: me, receiverId: other, content },
            select: { id: true, content: true, created_at: true, senderId: true, receiverId: true, is_read: true },
        });

        // Create in-app notification for the receiver
        const sender = await prisma.user.findUnique({ where: { id: me }, select: { full_name: true } });
        if (sender) {
            await prisma.notification.create({
                data: {
                    recipientId: other,
                    message: `New message from ${sender.full_name}: "${content.slice(0, 60)}${content.length > 60 ? '…' : ''}"`,
                    is_read: false,
                },
            });
        }

        res.status(201).json(message);
    } catch (e: any) {
        res.status(500).json({ error: e.message });
    }
};

// GET /chat/contacts — list users this user can chat with based on role
export const getContacts = async (req: AuthRequest, res: Response) => {
    try {
        const me = ME(req);
        const user = await prisma.user.findUnique({ where: { id: me }, select: { role: true } });
        if (!user) return res.status(404).json({ error: 'User not found.' });

        let contacts: { id: number; full_name: string; role: string }[] = [];

        if (user.role === 'STUDENT') {
            // Student can chat with their supervisor and HOD
            const student = await prisma.student.findUnique({
                where: { userId: me },
                include: {
                    assignments: {
                        where: { status: 'ACTIVE' },
                        include: { company: { include: { supervisors: { include: { user: { select: { id: true, full_name: true } } } } } } },
                    },
                    hod: { include: { user: { select: { id: true, full_name: true } } } },
                },
            });
            if (student?.hod) contacts.push({ ...student.hod.user, role: 'HOD' });
            student?.assignments.forEach((a) =>
                a.company.supervisors.forEach((s) => contacts.push({ ...s.user, role: 'SUPERVISOR' }))
            );
        } else if (user.role === 'SUPERVISOR') {
            // Supervisor can chat with their placed students
            const sup = await prisma.supervisor.findUnique({ where: { userId: me } });
            if (sup) {
                const assignments = await prisma.internshipAssignment.findMany({
                    where: { companyId: sup.companyId, status: 'ACTIVE' },
                    include: { student: { include: { user: { select: { id: true, full_name: true } } } } },
                });
                contacts = assignments.map((a) => ({ ...a.student.user, role: 'STUDENT' }));
            }
        } else if (user.role === 'HOD') {
            // HOD can chat with their approved students AND the coordinator of their university
            const hod = await prisma.hodProfile.findUnique({ where: { userId: me } });
            if (hod) {
                const students = await prisma.student.findMany({
                    where: { hodId: hod.id, hod_approval_status: 'APPROVED' },
                    include: { user: { select: { id: true, full_name: true } } },
                });
                contacts = students.map((s) => ({ ...s.user, role: 'STUDENT' }));

                // Add the coordinator of the same university
                const coordinator = await prisma.coordinator.findUnique({
                    where: { universityId: hod.universityId },
                    include: { user: { select: { id: true, full_name: true } } },
                });
                if (coordinator) contacts.push({ ...coordinator.user, role: 'COORDINATOR' });
            }
        } else if (user.role === 'COORDINATOR') {
            // Coordinator can chat with all HODs at their university
            const coordinator = await prisma.coordinator.findUnique({ where: { userId: me } });
            if (coordinator?.universityId) {
                const hods = await prisma.hodProfile.findMany({
                    where: {
                        universityId: coordinator.universityId,
                        user: { institution_access_approval: 'APPROVED' },
                    },
                    include: { user: { select: { id: true, full_name: true } } },
                });
                contacts = hods.map((h) => ({ ...h.user, role: 'HOD' }));
            }
        }

        // Deduplicate
        const seen = new Set<number>();
        contacts = contacts.filter((c) => { if (seen.has(c.id)) return false; seen.add(c.id); return true; });

        res.json(contacts);
    } catch (e: any) {
        res.status(500).json({ error: e.message });
    }
};

// GET /chat/unread-count — total unread messages for badge
export const getUnreadCount = async (req: AuthRequest, res: Response) => {
    try {
        const count = await prisma.chatMessage.count({
            where: { receiverId: ME(req), is_read: false },
        });
        res.json({ count });
    } catch (e: any) {
        res.status(500).json({ error: e.message });
    }
};
