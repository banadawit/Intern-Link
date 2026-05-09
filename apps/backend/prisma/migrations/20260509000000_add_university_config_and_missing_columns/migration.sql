-- Add UniversityConfig table (per-university student registration override)
CREATE TABLE IF NOT EXISTS "UniversityConfig" (
    "id" SERIAL NOT NULL,
    "universityId" INTEGER NOT NULL,
    "studentRegistrationEnabled" BOOLEAN,
    "updatedAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT "UniversityConfig_pkey" PRIMARY KEY ("id")
);

CREATE UNIQUE INDEX IF NOT EXISTS "UniversityConfig_universityId_key" ON "UniversityConfig"("universityId");

ALTER TABLE "UniversityConfig"
    DROP CONSTRAINT IF EXISTS "UniversityConfig_universityId_fkey";

ALTER TABLE "UniversityConfig"
    ADD CONSTRAINT "UniversityConfig_universityId_fkey"
    FOREIGN KEY ("universityId") REFERENCES "University"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- Add RESUBMITTED to ApprovalStatus enum (safe — only adds if not exists)
DO $$ BEGIN
    ALTER TYPE "ApprovalStatus" ADD VALUE IF NOT EXISTS 'RESUBMITTED';
EXCEPTION WHEN duplicate_object THEN null;
END $$;

-- Add PLAN_ATTACHMENT and PROPOSAL_ATTACHMENT to FileType enum
DO $$ BEGIN
    ALTER TYPE "FileType" ADD VALUE IF NOT EXISTS 'PLAN_ATTACHMENT';
EXCEPTION WHEN duplicate_object THEN null;
END $$;

DO $$ BEGIN
    ALTER TYPE "FileType" ADD VALUE IF NOT EXISTS 'PROPOSAL_ATTACHMENT';
EXCEPTION WHEN duplicate_object THEN null;
END $$;

-- Add attachments column to WeeklyPlan
ALTER TABLE "WeeklyPlan"
    ADD COLUMN IF NOT EXISTS "attachments" JSONB NOT NULL DEFAULT '[]';

-- Add attachments column to InternshipProposal
ALTER TABLE "InternshipProposal"
    ADD COLUMN IF NOT EXISTS "attachments" JSONB NOT NULL DEFAULT '[]';

-- Add missing columns to Project
ALTER TABLE "Project"
    ADD COLUMN IF NOT EXISTS "description" TEXT,
    ADD COLUMN IF NOT EXISTS "capacity" INTEGER NOT NULL DEFAULT 0,
    ADD COLUMN IF NOT EXISTS "requiredSkills" TEXT[] NOT NULL DEFAULT ARRAY[]::TEXT[],
    ADD COLUMN IF NOT EXISTS "supervisorId" INTEGER;

CREATE INDEX IF NOT EXISTS "Project_companyId_deleted_at_idx" ON "Project"("companyId", "deleted_at");

-- Add missing columns to Team
ALTER TABLE "Team"
    ADD COLUMN IF NOT EXISTS "projectId" INTEGER,
    ADD COLUMN IF NOT EXISTS "supervisorId" INTEGER;

ALTER TABLE "Team"
    DROP CONSTRAINT IF EXISTS "Team_projectId_fkey";

ALTER TABLE "Team"
    ADD CONSTRAINT "Team_projectId_fkey"
    FOREIGN KEY ("projectId") REFERENCES "Project"("id") ON DELETE SET NULL ON UPDATE CASCADE;

-- Add version column to WeeklyPlan if missing
ALTER TABLE "WeeklyPlan"
    ADD COLUMN IF NOT EXISTS "version" INTEGER NOT NULL DEFAULT 1;
