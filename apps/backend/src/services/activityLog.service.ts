import prisma from '../config/db';

/** Calendar day in UTC (matches `ActivityLog.date` @db.Date). */
export function utcTodayDate(): Date {
    const n = new Date();
    return new Date(Date.UTC(n.getUTCFullYear(), n.getUTCMonth(), n.getUTCDate()));
}

/**
 * Increment activity count for the given user for today (UTC).
 * Never throws — failures are logged only so primary requests are unaffected.
 */
export async function incrementActivityForUser(userId: number, amount = 1): Promise<void> {
    try {
        const date = utcTodayDate();
        await prisma.activityLog.upsert({
            where: {
                userId_date: {
                    userId,
                    date,
                },
            },
            create: {
                userId,
                date,
                count: amount,
            },
            update: {
                count: { increment: amount },
            },
        });
    } catch (e) {
        console.error('[activityLog] incrementActivityForUser failed', e);
    }
}
