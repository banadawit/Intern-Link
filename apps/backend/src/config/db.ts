
import { PrismaClient, ApprovalStatus } from '@prisma/client';

const prisma = new PrismaClient();

// Monkey-patch internshipProposal.findFirst to sanitize `where.status` inputs
// This prevents invalid enum values (e.g., 'SENT', 'DRAFT') from reaching Prisma
try {
	const validStatuses = new Set<string>(Object.values(ApprovalStatus) as string[]);
	const ip: any = (prisma as any).internshipProposal;
	if (ip && typeof ip.findFirst === 'function') {
		const _origFindFirst = ip.findFirst.bind(ip);
		ip.findFirst = (args: any) => {
			try {
				const where = args?.where;
				if (where && where.status != null) {
					let arr: string[] = [];
					if (Array.isArray(where.status)) arr = where.status.map((v: any) => String(v));
					else if (typeof where.status === 'object' && Array.isArray(where.status.in)) arr = where.status.in.map((v: any) => String(v));
					else arr = [String(where.status)];

					const filtered = arr.map((s) => s.toUpperCase()).filter((s) => validStatuses.has(s));
					if (filtered.length === 0) {
						delete where.status;
					} else if (filtered.length === 1) {
						where.status = filtered[0];
					} else {
						where.status = { in: filtered };
					}
				}
			} catch (_) { /* swallow sanitizer errors and proceed */ }
			return _origFindFirst(args);
		};
	}
} catch (_) { /* ignore patching errors */ }

export default prisma;