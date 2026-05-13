-- Add status and supervisor feedback to WeeklyPlanDaySubmission
ALTER TABLE "WeeklyPlanDaySubmission"
    ADD COLUMN IF NOT EXISTS "status" TEXT NOT NULL DEFAULT 'PENDING',
    ADD COLUMN IF NOT EXISTS "supervisorNote" TEXT,
    ADD COLUMN IF NOT EXISTS "reviewedAt" TIMESTAMP(3);
