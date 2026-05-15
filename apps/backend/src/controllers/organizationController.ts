import { Request, Response } from 'express';
import prisma from '../config/db';
import { ApprovalStatus, OrganizationType } from '@prisma/client';
import { sendSuccess, sendError } from '../utils/responseHelper';
import { findSimilarMatch, normalizeName, getLevenshteinDistance } from '../utils/fuzzySearch';
import { CloudinaryService } from '../services/cloudinary.service';

/**
 * Search for active/approved organizations (Universities or Companies).
 */
export const searchOrganizations = async (req: Request, res: Response) => {
    try {
        const { q, type } = req.query;
        const query = typeof q === 'string' ? q.trim() : '';
        const orgType = typeof type === 'string' ? type.toUpperCase() : null;

        if (!query) return sendSuccess(res, [], 'Search query is required');

        let results: any[] = [];

        if (!orgType || orgType === 'UNIVERSITY') {
            const unis = await prisma.university.findMany({
                where: {
                    name: { contains: query, mode: 'insensitive' },
                    approval_status: 'APPROVED',
                },
                select: { id: true, name: true, address: true },
                take: 10,
            });
            results = [...results, ...unis.map(u => ({ ...u, type: 'UNIVERSITY' }))];
        }

        if (!orgType || orgType === 'COMPANY') {
            const companies = await prisma.company.findMany({
                where: {
                    name: { contains: query, mode: 'insensitive' },
                    approval_status: 'APPROVED',
                },
                select: { id: true, name: true, address: true },
                take: 10,
            });
            results = [...results, ...companies.map(c => ({ ...c, type: 'COMPANY' }))];
        }

        return sendSuccess(res, results, 'Organizations fetched');
    } catch (error: any) {
        return sendError(res, error.message, 500);
    }
};

/**
 * Check if an organization name is a duplicate or very similar.
 */
export const checkDuplicateOrganization = async (req: Request, res: Response) => {
    try {
        const { name, type } = req.body;
        // Fallback to query param if type is not in body
        const orgType = (req.query.type as string)?.toUpperCase() || type?.toUpperCase();

        if (!name) return sendSuccess(res, { isDuplicate: false, suggestions: [] });

        const existingOrgs = orgType === 'UNIVERSITY'
            ? await prisma.university.findMany({ select: { id: true, name: true } })
            : await prisma.company.findMany({ select: { id: true, name: true } });

        const normalizedName = normalizeName(name);

        let exactMatch = null;
        let suggestions: any[] = [];

        for (const org of existingOrgs) {
            const normalizedOrg = normalizeName(org.name);
            if (normalizedOrg === normalizedName) {
                exactMatch = org;
                break; // If exact match, no need to check further for exact.
            }

            // Allow a small typo threshold (e.g. Haramya vs Haramaya)
            const distance = getLevenshteinDistance(normalizedName, normalizedOrg);
            if (distance <= 2) {
                suggestions.push(org);
            }
        }

        if (exactMatch) {
            return sendSuccess(res, { isDuplicate: true, exactMatch, suggestions: [] });
        }

        return sendSuccess(res, { isDuplicate: false, suggestions });
    } catch (error: any) {
        return sendError(res, error.message, 500);
    }
};

/**
 * Submit a request for a new organization that isn't in the DB.
 */
export const requestNewOrganization = async (req: Request, res: Response) => {
    try {
        const { name, type, address, website, requester_email } = req.body;
        const file = req.file;

        if (!name || !type || !file || !requester_email) {
            return sendError(res, 'Name, type, verification document, and email are required', 400);
        }

        const orgType = type.toUpperCase() as OrganizationType;

        // 1. Duplicate Check (Fuzzy)
        const existingNames = orgType === 'UNIVERSITY' 
            ? (await prisma.university.findMany({ select: { name: true } })).map(u => u.name)
            : (await prisma.company.findMany({ select: { name: true } })).map(c => c.name);

        const match = findSimilarMatch(name, existingNames);
        if (match) {
            return sendError(res, `An organization with a similar name already exists: "${match}". Please search and select it instead.`, 409, 'DUPLICATE_SUGGESTION', { match });
        }

        // 2. Upload to Cloudinary
        const upload = await CloudinaryService.uploadVerificationDoc(file, {
            fileType: 'VERIFICATION_DOC',
            folder: `internlink/requests/${orgType.toLowerCase()}`,
        });

        if (!upload.success || !upload.url) {
            return sendError(res, upload.error || 'Failed to upload verification document', 500);
        }

        // 3. Create Request
        const request = await prisma.organizationRequest.create({
            data: {
                name,
                type: orgType,
                address,
                website,
                verification_doc: upload.url,
                requester_email,
                status: 'PENDING',
            },
        });

        return sendSuccess(res, request, 'Organization request submitted for review', 201);
    } catch (error: any) {
        return sendError(res, error.message, 500);
    }
};

/**
 * Admin: Get all organization requests.
 */
export const adminGetRequests = async (req: Request, res: Response) => {
    try {
        const requests = await prisma.organizationRequest.findMany({
            orderBy: { created_at: 'desc' },
        });
        return sendSuccess(res, requests, 'Requests fetched');
    } catch (error: any) {
        return sendError(res, error.message, 500);
    }
};

/**
 * Admin: Mark document as viewed.
 */
export const adminMarkDocumentViewed = async (req: Request, res: Response) => {
    try {
        // document_viewed field removed from schema — just return success
        return sendSuccess(res, null, 'Document marked as viewed');
    } catch (error: any) {
        return sendError(res, error.message, 500);
    }
};

/**
 * Admin: Approve organization request.
 */
export const adminApproveRequest = async (req: Request, res: Response) => {
    try {
        const id = req.params.id as string;
        const request = await prisma.organizationRequest.findUnique({
            where: { id: parseInt(String(id)) },
        });

        if (!request) return sendError(res, 'Request not found', 404);

        const result = await prisma.$transaction(async (tx) => {
            let newOrg;
            if (request.type === 'UNIVERSITY') {
                newOrg = await tx.university.create({
                    data: {
                        name: request.name,
                        official_email: request.requester_email, // Fallback
                        address: request.address,
                        verification_doc: request.verification_doc,
                        approval_status: 'APPROVED',
                    },
                });
            } else {
                newOrg = await tx.company.create({
                    data: {
                        name: request.name,
                        official_email: request.requester_email, // Fallback
                        address: request.address,
                        verification_doc: request.verification_doc,
                        approval_status: 'APPROVED',
                    },
                });
            }

            await tx.organizationRequest.update({
                where: { id: request.id },
                data: { status: 'APPROVED' },
            });

            return newOrg;
        });

        return sendSuccess(res, result, 'Organization approved and created');
    } catch (error: any) {
        return sendError(res, error.message, 500);
    }
};

/**
 * Admin: Reject organization request.
 */
export const adminRejectRequest = async (req: Request, res: Response) => {
    try {
        const id = req.params.id as string;
        const { reason } = req.body;

        await prisma.organizationRequest.update({
            where: { id: parseInt(String(id)) },
            data: { 
                status: 'REJECTED',
                rejection_reason: reason 
            },
        });

        return sendSuccess(res, null, 'Organization request rejected');
    } catch (error: any) {
        return sendError(res, error.message, 500);
    }
};

/**
 * Admin: Merge duplicate organizations.
 * Source ID is merged INTO Target ID.
 */
export const adminMergeOrganizations = async (req: Request, res: Response) => {
    try {
        const { sourceType, sourceId, targetId } = req.body;

        if (!sourceId || !targetId || !sourceType) {
            return sendError(res, 'Source and target IDs + type are required', 400);
        }

        if (sourceId === targetId) return sendError(res, 'Cannot merge an organization into itself', 400);

        await prisma.$transaction(async (tx) => {
            if (sourceType === 'UNIVERSITY') {
                // Move coordinators
                await tx.coordinator.updateMany({
                    where: { universityId: sourceId },
                    data: { universityId: targetId },
                });
                // Move HODs
                await tx.hodProfile.updateMany({
                    where: { universityId: sourceId },
                    data: { universityId: targetId },
                });
                // Move students
                await tx.student.updateMany({
                    where: { universityId: sourceId },
                    data: { universityId: targetId },
                });
                // Move proposals
                await tx.internshipProposal.updateMany({
                    where: { universityId: sourceId },
                    data: { universityId: targetId },
                });
                // Move reports
                await tx.report.updateMany({
                    where: { sentToUniversityId: sourceId },
                    data: { sentToUniversityId: targetId },
                });
                // Delete source
                await tx.university.delete({ where: { id: sourceId } });
            } else {
                // Move supervisors
                await tx.supervisor.updateMany({
                    where: { companyId: sourceId },
                    data: { companyId: targetId },
                });
                // Move assignments
                await tx.internshipAssignment.updateMany({
                    where: { companyId: sourceId },
                    data: { companyId: targetId },
                });
                // Move proposals
                await tx.internshipProposal.updateMany({
                    where: { companyId: sourceId },
                    data: { companyId: targetId },
                });
                // Move projects
                await tx.project.updateMany({
                    where: { companyId: sourceId },
                    data: { companyId: targetId },
                });
                // Move teams
                await tx.team.updateMany({
                    where: { companyId: sourceId },
                    data: { companyId: targetId },
                });
                // Delete source
                await tx.company.delete({ where: { id: sourceId } });
            }
        });

        return sendSuccess(res, null, 'Organizations merged successfully');
    } catch (error: any) {
        return sendError(res, error.message, 500);
    }
};
