-- Add TL review fields to TeamWeeklyPlan
ALTER TABLE "TeamWeeklyPlan" ADD COLUMN IF NOT EXISTS "tl_status" TEXT NOT NULL DEFAULT 'PENDING';
ALTER TABLE "TeamWeeklyPlan" ADD COLUMN IF NOT EXISTS "tl_comment" TEXT;
ALTER TABLE "TeamWeeklyPlan" ADD COLUMN IF NOT EXISTS "tl_reviewed_at" TIMESTAMP(3);
