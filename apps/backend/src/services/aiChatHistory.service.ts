import prisma from '../config/db';

const MAX_STORED = 200;

export async function appendChatTurn(userId: number, userContent: string, assistantContent: string): Promise<void> {
    await prisma.$transaction([
        prisma.aiChatMessage.create({
            data: { userId, speaker: 'user', content: userContent.slice(0, 32000) },
        }),
        prisma.aiChatMessage.create({
            data: { userId, speaker: 'assistant', content: assistantContent.slice(0, 32000) },
        }),
    ]);
    const count = await prisma.aiChatMessage.count({ where: { userId } });
    if (count > MAX_STORED) {
        const excess = count - MAX_STORED;
        const oldest = await prisma.aiChatMessage.findMany({
            where: { userId },
            orderBy: { createdAt: 'asc' },
            take: excess,
            select: { id: true },
        });
        if (oldest.length > 0) {
            await prisma.aiChatMessage.deleteMany({
                where: { id: { in: oldest.map((o) => o.id) } },
            });
        }
    }
}

export async function listChatHistory(userId: number, limit = 100): Promise<{ role: 'user' | 'assistant'; content: string }[]> {
    const rows = await prisma.aiChatMessage.findMany({
        where: { userId },
        orderBy: { createdAt: 'asc' },
        take: Math.min(limit, 200),
        select: { speaker: true, content: true },
    });
    return rows.map((r) => ({
        role: r.speaker === 'assistant' ? 'assistant' : 'user',
        content: r.content,
    }));
}

export async function clearChatHistory(userId: number): Promise<void> {
    await prisma.aiChatMessage.deleteMany({ where: { userId } });
}
