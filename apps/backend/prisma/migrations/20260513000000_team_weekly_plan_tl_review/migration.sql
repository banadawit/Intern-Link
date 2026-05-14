-- Add TL review fields to TeamWeeklyPlan.
-- Guard against environments where TeamWeeklyPlan is created by a later migration.
DO $$
BEGIN
	IF to_regclass('public."TeamWeeklyPlan"') IS NOT NULL THEN
		ALTER TABLE "TeamWeeklyPlan" ADD COLUMN IF NOT EXISTS "tl_status" TEXT NOT NULL DEFAULT 'PENDING';
		ALTER TABLE "TeamWeeklyPlan" ADD COLUMN IF NOT EXISTS "tl_comment" TEXT;
		ALTER TABLE "TeamWeeklyPlan" ADD COLUMN IF NOT EXISTS "tl_reviewed_at" TIMESTAMP(3);
	END IF;
END $$;
