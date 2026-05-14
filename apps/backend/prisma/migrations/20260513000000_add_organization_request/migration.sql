-- CreateEnum (only if it doesn't exist)
DO $$ BEGIN
    CREATE TYPE "OrganizationType" AS ENUM ('UNIVERSITY', 'COMPANY');
EXCEPTION
    WHEN duplicate_object THEN null;
END $$;

-- CreateTable
CREATE TABLE IF NOT EXISTS "organization_requests" (
    "id" SERIAL NOT NULL,
    "name" TEXT NOT NULL,
    "type" "OrganizationType" NOT NULL,
    "address" TEXT,
    "website" TEXT,
    "verification_doc" TEXT,
    "requester_email" TEXT NOT NULL,
    "status" "ApprovalStatus" NOT NULL DEFAULT 'PENDING',
    "document_viewed" BOOLEAN NOT NULL DEFAULT false,
    "rejection_reason" TEXT,
    "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "organization_requests_pkey" PRIMARY KEY ("id")
);

-- CreateIndex
CREATE INDEX IF NOT EXISTS "organization_requests_status_type_idx" ON "organization_requests"("status", "type");
