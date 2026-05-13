-- Add attachments column to WeeklyPlan if it doesn't exist
ALTER TABLE "WeeklyPlan" ADD COLUMN IF NOT EXISTS "attachments" JSONB NOT NULL DEFAULT '[]';
