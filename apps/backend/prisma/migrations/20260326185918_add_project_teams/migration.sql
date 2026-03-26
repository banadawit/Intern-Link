-- AlterTable
ALTER TABLE "Company" ADD COLUMN     "rejection_reason" TEXT;

-- AlterTable
ALTER TABLE "InternshipAssignment" ADD COLUMN     "project_name" TEXT;

-- AlterTable
ALTER TABLE "University" ADD COLUMN     "rejection_reason" TEXT;

-- CreateTable
CREATE TABLE "AuditLog" (
    "id" SERIAL NOT NULL,
    "adminId" INTEGER NOT NULL,
    "action" TEXT NOT NULL,
    "targetId" INTEGER NOT NULL,
    "details" TEXT,
    "timestamp" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "AuditLog_pkey" PRIMARY KEY ("id")
);
