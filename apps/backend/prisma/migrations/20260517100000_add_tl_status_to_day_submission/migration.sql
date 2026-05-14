-- Add tl_status column to WeeklyPlanDaySubmission for Team Leader review workflow
ALTER TABLE "WeeklyPlanDaySubmission" ADD COLUMN IF NOT EXISTS "tl_status" TEXT NOT NULL DEFAULT 'PENDING';
ALTER TABLE "WeeklyPlanDaySubmission" ADD COLUMN IF NOT EXISTS "tl_comment" TEXT;
ALTER TABLE "WeeklyPlanDaySubmission" ADD COLUMN IF NOT EXISTS "tl_reviewed_at" TIMESTAMP(3);
