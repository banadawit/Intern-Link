-- Add status column to WeeklyPlanDaySubmission for supervisor review
ALTER TABLE "WeeklyPlanDaySubmission" ADD COLUMN IF NOT EXISTS "status" TEXT NOT NULL DEFAULT 'PENDING';
ALTER TABLE "WeeklyPlanDaySubmission" ADD COLUMN IF NOT EXISTS "supervisor_note" TEXT;
ALTER TABLE "WeeklyPlanDaySubmission" ADD COLUMN IF NOT EXISTS "reviewed_at" TIMESTAMP(3);
