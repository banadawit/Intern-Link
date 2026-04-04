import { Response } from 'express';
import { AuthRequest } from '../middlewares/authMiddleware';
import prisma from '../config/db';

function ymdUtc(d: Date): string {
    return d.toISOString().slice(0, 10);
}

/** GET /api/activity — last 365 calendar days (inclusive) ending today UTC. */
export const getActivity = async (req: AuthRequest, res: Response) => {
    try {
        const userId = req.user!.userId;
        const now = new Date();
        const end = new Date(Date.UTC(now.getUTCFullYear(), now.getUTCMonth(), now.getUTCDate()));
        const start = new Date(end);
        start.setUTCDate(start.getUTCDate() - 364);

        const rows = await prisma.activityLog.findMany({
            where: {
                userId,
                date: { gte: start, lte: end },
            },
            orderBy: { date: 'asc' },
        });

        const series = rows.map((r) => ({
            date: ymdUtc(r.date),
            count: r.count,
        }));

        const totalContributions = series.reduce((s, r) => s + r.count, 0);

        const byDate = new Map(series.map((r) => [r.date, r.count]));

        const datesWithActivity = series
            .filter((r) => r.count > 0)
            .map((r) => r.date)
            .sort();
        let longestStreak = 0;
        let run = 0;
        let prevD: string | null = null;
        for (const ds of datesWithActivity) {
            if (prevD && dayAfter(prevD) === ds) {
                run += 1;
            } else {
                run = 1;
            }
            longestStreak = Math.max(longestStreak, run);
            prevD = ds;
        }

        const todayStr = ymdUtc(end);
        const startStr = ymdUtc(start);
        let currentStreak = 0;
        let d = todayStr;
        while (d >= startStr) {
            const c = byDate.get(d) ?? 0;
            if (c <= 0) break;
            currentStreak += 1;
            d = dayBefore(d);
        }

        let mostActiveDate: string | null = null;
        let mostActiveCount = 0;
        for (const r of series) {
            if (r.count > mostActiveCount) {
                mostActiveCount = r.count;
                mostActiveDate = r.date;
            }
        }

        res.json({
            series,
            stats: {
                totalContributions,
                currentStreak,
                longestStreak,
                mostActiveDate,
                mostActiveCount,
            },
        });
    } catch (error: unknown) {
        const message = error instanceof Error ? error.message : 'Server error';
        res.status(500).json({ error: message });
    }
};

function dayBefore(ymd: string): string {
    const [y, m, d] = ymd.split('-').map(Number);
    const dt = new Date(Date.UTC(y, m - 1, d));
    dt.setUTCDate(dt.getUTCDate() - 1);
    return dt.toISOString().slice(0, 10);
}

function dayAfter(ymd: string): string {
    const [y, m, d] = ymd.split('-').map(Number);
    const dt = new Date(Date.UTC(y, m - 1, d));
    dt.setUTCDate(dt.getUTCDate() + 1);
    return dt.toISOString().slice(0, 10);
}
