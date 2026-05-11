import { Response } from 'express';
import { AuthRequest } from '../middlewares/authMiddleware';
import prisma from '../config/db';
import { sendSuccess, sendError } from '../utils/responseHelper';

const ME = (req: AuthRequest) => req.user!.userId;

// ─── Permission helper ────────────────────────────────────────────────────────
// Returns true if `senderId` is allowed to message `receiverId` based on role rules.
async function canMessage(senderId: number, receiverId: number): Promise<boolean> {
    const [sender, receiver] = await Promise.all([
        prisma.user.findUnique({ where: { id: senderId }, select: { role: true } }),
        prisma.user.findUnique({ where: { id: receiverId }, select: { role: true } }),
    ]);
    if (!sender || !receiver) return false;

    const s = sender.role;
    const r = receiver.role;

    // Admin can message anyone
    if (s === 'ADMIN') return true;
    // Anyone can message Admin
    if (r === 'ADMIN') return true;

    if (s === 'COORDINATOR') {
        // Coordinator ↔ HOD (same university)
        if (r === 'HOD') {
            const coord = await prisma.coordinator.findUnique({ where: { userId: senderId } });
            const hod = await prisma.hodProfile.findUnique({ where: { userId: receiverId } });
            return !!coord?.universityId && coord.universityId === hod?.universityId;
        }
        // Coordinator ↔ Supervisor (any, for coordination)
        if (r === 'SUPERVISOR') return true;
        return false;
    }

    if (s === 'HOD') {
        // HOD ↔ Coordinator (same university)
        if (r === 'COORDINATOR') {
            const hod = await prisma.hodProfile.findUnique({ where: { userId: senderId } });
            const coord = await prisma.coordinator.findUnique({ where: { userId: receiverId } });
            return !!hod?.universityId && hod.universityId === coord?.universityId;
        }
        // HOD ↔ Student (in their department)
        if (r === 'STUDENT') {
            const hod = await prisma.hodProfile.findUnique({ where: { userId: senderId } });
            if (!hod) return false;
            const student = await prisma.student.findUnique({ where: { userId: receiverId } });
            return student?.hodId === hod.id;
        }
        // HOD ↔ Supervisor (related to their students)
        if (r === 'SUPERVISOR') {
            const hod = await prisma.hodProfile.findUnique({ where: { userId: senderId } });
            if (!hod) return false;
            const students = await prisma.student.findMany({ where: { hodId: hod.id }, select: { id: true } });
            const studentIds = students.map((s) => s.id);
            const assignment = await prisma.internshipAssignment.findFirst({
                where: { studentId: { in: studentIds }, status: 'ACTIVE' },
                include: { company: { include: { supervisors: { where: { userId: receiverId } } } } },
            });
            return !!assignment?.company.supervisors.length;
        }
        return false;
    }

    if (s === 'SUPERVISOR') {
        // Supervisor ↔ HOD
        if (r === 'HOD') return canMessage(receiverId, senderId); // symmetric
        // Supervisor ↔ assigned Student
        if (r === 'STUDENT') {
            const sup = await prisma.supervisor.findUnique({ where: { userId: senderId } });
            if (!sup) return false;
            const student = await prisma.student.findUnique({ where: { userId: receiverId } });
            if (!student) return false;
            const assignment = await prisma.internshipAssignment.findFirst({
                where: { studentId: student.id, companyId: sup.companyId, status: 'ACTIVE' },
            });
            return !!assignment;
        }
        return false;
    }

    if (s === 'STUDENT') {
        // Student ↔ assigned Supervisor
        if (r === 'SUPERVISOR') {
            const student = await prisma.student.findUnique({ where: { userId: senderId } });
            if (!student) return false;
            const sup = await prisma.supervisor.findUnique({ where: { userId: receiverId } });
            if (!sup) return false;
            const assignment = await prisma.internshipAssignment.findFirst({
                where: { studentId: student.id, companyId: sup.companyId, status: 'ACTIVE' },
            });
            return !!assignment;
        }
        // Student ↔ their HOD
        if (r === 'HOD') {
            const student = await prisma.student.findUnique({ where: { userId: senderId }, include: { hod: true } });
            return student?.hod?.userId === receiverId;
        }
        return false;
    }

    return false;
}

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

        return sendSuccess(res, conversations);
    } catch (e: any) {
        return sendError(res, e.message);
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

        // Role-based permission check
        const allowed = await canMessage(me, other);
        if (!allowed) {
            return res.status(403).json({ error: 'You are not allowed to message this user.' });
        }

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

        if (user.role === 'ADMIN') {
            // Admin sees all coordinators, HODs, supervisors
            contacts = await prisma.user.findMany({
                where: { role: { in: ['COORDINATOR', 'HOD', 'SUPERVISOR'] }, id: { not: me } },
                select: { id: true, full_name: true, role: true },
            });

        } else if (user.role === 'COORDINATOR') {
            // Coordinator sees: Admin + HODs of their university + Supervisors
            const coord = await prisma.coordinator.findUnique({ where: { userId: me } });
            const admins = await prisma.user.findMany({
                where: { role: 'ADMIN' },
                select: { id: true, full_name: true, role: true },
            });
            contacts.push(...admins);
            if (coord?.universityId) {
                const hods = await prisma.hodProfile.findMany({
                    where: { universityId: coord.universityId },
                    include: { user: { select: { id: true, full_name: true } } },
                });
                contacts.push(...hods.map((h) => ({ ...h.user, role: 'HOD' })));
            }
            const supervisors = await prisma.user.findMany({
                where: { role: 'SUPERVISOR', id: { not: me } },
                select: { id: true, full_name: true, role: true },
            });
            contacts.push(...supervisors);

        } else if (user.role === 'HOD') {
            // HOD sees: Admin + Coordinator of their university + their students + related supervisors
            const hod = await prisma.hodProfile.findUnique({ where: { userId: me } });
            const admins = await prisma.user.findMany({
                where: { role: 'ADMIN' },
                select: { id: true, full_name: true, role: true },
            });
            contacts.push(...admins);
            if (hod?.universityId) {
                const coord = await prisma.coordinator.findFirst({
                    where: { universityId: hod.universityId },
                    include: { user: { select: { id: true, full_name: true } } },
                });
                if (coord) contacts.push({ ...coord.user, role: 'COORDINATOR' });

                // Students in their department
                const students = await prisma.student.findMany({
                    where: { hodId: hod.id, hod_approval_status: 'APPROVED' },
                    include: { user: { select: { id: true, full_name: true } } },
                });
                contacts.push(...students.map((s) => ({ ...s.user, role: 'STUDENT' })));

                // Supervisors related to their students
                const studentIds = students.map((s) => s.id);
                if (studentIds.length > 0) {
                    const assignments = await prisma.internshipAssignment.findMany({
                        where: { studentId: { in: studentIds }, status: 'ACTIVE' },
                        include: { company: { include: { supervisors: { include: { user: { select: { id: true, full_name: true } } } } } } },
                    });
                    assignments.forEach((a) =>
                        a.company.supervisors.forEach((s) => contacts.push({ ...s.user, role: 'SUPERVISOR' }))
                    );
                }
            }

        } else if (user.role === 'SUPERVISOR') {
            // Supervisor sees: Admin + HOD of their students + assigned students
            const sup = await prisma.supervisor.findUnique({ where: { userId: me } });
            const admins = await prisma.user.findMany({
                where: { role: 'ADMIN' },
                select: { id: true, full_name: true, role: true },
            });
            contacts.push(...admins);
            if (sup) {
                const assignments = await prisma.internshipAssignment.findMany({
                    where: { companyId: sup.companyId, status: 'ACTIVE' },
                    include: {
                        student: {
                            include: {
                                user: { select: { id: true, full_name: true } },
                                hod: { include: { user: { select: { id: true, full_name: true } } } },
                            },
                        },
                    },
                });
                assignments.forEach((a) => {
                    contacts.push({ ...a.student.user, role: 'STUDENT' });
                    if (a.student.hod?.user) contacts.push({ ...a.student.hod.user, role: 'HOD' });
                });
            }

        } else if (user.role === 'STUDENT') {
            // Student sees: assigned Supervisor + their HOD
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
        }

        // Deduplicate by id
        const seen = new Set<number>();
        contacts = contacts.filter((c) => {
            if (seen.has(c.id) || c.id === me) return false;
            seen.add(c.id);
            return true;
        });

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
        return sendSuccess(res, { count });
    } catch (e: any) {
        return sendError(res, e.message);
    }
};

// DELETE /chat/:userId — delete all messages between me and userId (only for the requester's view)
export const deleteConversation = async (req: AuthRequest, res: Response) => {
    try {
        const me = ME(req);
        const other = parseInt(String(req.params.userId), 10);

        await prisma.chatMessage.deleteMany({
            where: {
                OR: [
                    { senderId: me, receiverId: other },
                    { senderId: other, receiverId: me },
                ],
            },
        });

        res.json({ success: true });
    } catch (e: any) {
        res.status(500).json({ error: e.message });
    }
};

// PATCH /chat/message/:messageId — edit a message
export const editMessage = async (req: AuthRequest, res: Response) => {
    try {
        const me = ME(req);
        const messageId = parseInt(String(req.params.messageId), 10);
        const content = typeof req.body?.content === 'string' ? req.body.content.trim() : '';

        if (!content) return res.status(400).json({ error: 'Message content is required.' });

        const message = await prisma.chatMessage.findUnique({ where: { id: messageId } });
        if (!message) return res.status(404).json({ error: 'Message not found.' });
        if (message.senderId !== me) return res.status(403).json({ error: 'You can only edit your own messages.' });

        const updated = await prisma.chatMessage.update({
            where: { id: messageId },
            data: { content },
            select: { id: true, content: true, created_at: true, senderId: true, receiverId: true, is_read: true },
        });

        res.json(updated);
    } catch (e: any) {
        res.status(500).json({ error: e.message });
    }
};

// DELETE /chat/message/:messageId — delete a single message
export const deleteMessage = async (req: AuthRequest, res: Response) => {
    try {
        const me = ME(req);
        const messageId = parseInt(String(req.params.messageId), 10);

        const message = await prisma.chatMessage.findUnique({ where: { id: messageId } });
        if (!message) return res.status(404).json({ error: 'Message not found.' });
        if (message.senderId !== me) return res.status(403).json({ error: 'You can only delete your own messages.' });

        await prisma.chatMessage.delete({ where: { id: messageId } });

        res.json({ success: true });
    } catch (e: any) {
        res.status(500).json({ error: e.message });
    }
};
