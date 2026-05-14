-- Add tl_status column to WeeklyPlan for Team Leader review workflow
ALTER TABLE "WeeklyPlan" ADD COLUMN IF NOT EXISTS "tl_status" TEXT NOT NULL DEFAULT 'PENDING';
ALTER TABLE "WeeklyPlan" ADD COLUMN IF NOT EXISTS "tl_comment" TEXT;
ALTER TABLE "WeeklyPlan" ADD COLUMN IF NOT EXISTS "tl_reviewed_at" TIMESTAMP(3);
