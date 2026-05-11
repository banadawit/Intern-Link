import prisma from '../config/db';

/**
 * Check if a university has submitted verification documents.
 * Returns { verified: boolean, warning?: string } instead of throwing,
 * so callers can decide whether to block or warn.
 */
export async function checkUniversityVerification(universityId: number): Promise<{ verified: boolean; warning?: string }> {
    const u = await prisma.university.findUnique({
        where: { id: universityId },
        include: { coordinators: { include: { user: true } } },
    });
    if (!u) {
        return { verified: false, warning: 'University not found.' };
    }
    const hasOrgDoc = Boolean(u.verification_doc);
    const hasCoordinatorCredential = u.coordinators.some((c) => Boolean(c.user.verification_document));
    if (!hasOrgDoc && !hasCoordinatorCredential) {
        return {
            verified: false,
            warning: 'No verification documents found. Approving without credentials — proceed with caution.',
        };
    }
    return { verified: true };
}

/**
 * Check if a company has submitted verification documents.
 * Returns { verified: boolean, warning?: string } instead of throwing.
 */
export async function checkCompanyVerification(companyId: number): Promise<{ verified: boolean; warning?: string }> {
    const c = await prisma.company.findUnique({
        where: { id: companyId },
        include: { supervisors: { include: { user: true } } },
    });
    if (!c) return { verified: false, warning: 'Company not found.' };
    const hasCompanyEvidence = Boolean(c.verification_doc || c.stamp_image_url);
    const hasSupervisorCredential = c.supervisors.some((s) => Boolean(s.user.verification_document));
    if (!hasCompanyEvidence && !hasSupervisorCredential) {
        return {
            verified: false,
            warning: 'No verification documents found. Approving without credentials — proceed with caution.',
        };
    }
    return { verified: true };
}

// Legacy hard-block versions kept for backward compatibility (not used in approval flow)
export async function assertUniversityVerificationProposalExists(universityId: number): Promise<void> {
    const result = await checkUniversityVerification(universityId);
    if (!result.verified && result.warning === 'University not found.') {
        throw new Error('University not found.');
    }
}

export async function assertCompanyVerificationProposalExists(companyId: number): Promise<void> {
    const result = await checkCompanyVerification(companyId);
    if (!result.verified && result.warning === 'Company not found.') {
        throw new Error('Company not found.');
    }
}
