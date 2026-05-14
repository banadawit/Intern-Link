-- Add missing updated_at column to organization_requests if it doesn't exist
ALTER TABLE "organization_requests" ADD COLUMN IF NOT EXISTS "updated_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP;
