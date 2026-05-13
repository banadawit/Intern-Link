-- Add TL review fields to WeeklyPlan
ALTER TABLE "WeeklyPlan"
    ADD COLUMN IF NOT EXISTS "tl_status" TEXT NOT NULL DEFAULT 'PENDING',
    ADD COLUMN IF NOT EXISTS "tl_comment" TEXT,
    ADD COLUMN IF NOT EXISTS "tl_reviewed_at" TIMESTAMP(3);
