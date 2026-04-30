-- Add CANCELLED to ApprovalStatus enum
ALTER TYPE "ApprovalStatus" ADD VALUE IF NOT EXISTS 'CANCELLED';

-- Add flag fields to Student table
ALTER TABLE "Student" ADD COLUMN IF NOT EXISTS "flag_type" TEXT;
ALTER TABLE "Student" ADD COLUMN IF NOT EXISTS "flag_note" TEXT;
