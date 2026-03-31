import prisma from '../config/db';

export async function assertUniversityVerificationProposalExists(universityId: number): Promise<void> {
    const u = await prisma.university.findUnique({
        where: { id: universityId },
        include: { coordinators: { include: { user: true } } },
    });
    if (!u) {
        throw new Error('University not found.');
    }
    const hasOrgDoc = Boolean(u.verification_doc);
    const hasCoordinatorCredential = u.coordinators.some((c) => Boolean(c.user.verification_document));
    if (!hasOrgDoc && !hasCoordinatorCredential) {
        throw new Error(
            'Cannot approve: verification proposal with credentials (e.g. official stamped letter) must be submitted first.'
        );
    }
}

export async function assertCompanyVerificationProposalExists(companyId: number): Promise<void> {
    const c = await prisma.company.findUnique({
        where: { id: companyId },
        include: { supervisors: { include: { user: true } } },
    });
    if (!c) throw new Error('Company not found.');
    const hasCompanyEvidence = Boolean(c.verification_doc || c.stamp_image_url);
    const hasSupervisorCredential = c.supervisors.some((s) => Boolean(s.user.verification_document));
    if (!hasCompanyEvidence && !hasSupervisorCredential) {
        throw new Error(
            'Cannot approve: verification proposal with credentials (document or official stamp) must be submitted first.'
        );
    }
}
