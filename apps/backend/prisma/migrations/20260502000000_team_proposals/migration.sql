-- Add proposal_kind and team_name to InternshipProposal (backward-compatible defaults)
ALTER TABLE "InternshipProposal" ADD COLUMN IF NOT EXISTS "proposal_kind" TEXT NOT NULL DEFAULT 'INDIVIDUAL';
ALTER TABLE "InternshipProposal" ADD COLUMN IF NOT EXISTS "team_name" TEXT;

-- Create ProposalTeamMember join table
CREATE TABLE IF NOT EXISTS "ProposalTeamMember" (
    "id"         SERIAL PRIMARY KEY,
    "proposalId" INTEGER NOT NULL,
    "studentId"  INTEGER NOT NULL,
    CONSTRAINT "ProposalTeamMember_proposalId_fkey" FOREIGN KEY ("proposalId") REFERENCES "InternshipProposal"("id") ON DELETE CASCADE,
    CONSTRAINT "ProposalTeamMember_studentId_fkey"  FOREIGN KEY ("studentId")  REFERENCES "Student"("id"),
    CONSTRAINT "ProposalTeamMember_proposalId_studentId_key" UNIQUE ("proposalId", "studentId")
);

CREATE INDEX IF NOT EXISTS "ProposalTeamMember_proposalId_idx" ON "ProposalTeamMember"("proposalId");
CREATE INDEX IF NOT EXISTS "ProposalTeamMember_studentId_idx"  ON "ProposalTeamMember"("studentId");
