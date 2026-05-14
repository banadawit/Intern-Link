/*
  Warnings:

  - You are about to drop the `AuditLog` table. If the table is not empty, all the data it contains will be lost.
  - Made the column `verification_doc` on table `organization_requests` required. This step will fail if there are existing NULL values in that column.

*/
-- DropForeignKey
ALTER TABLE "Notification" DROP CONSTRAINT "Notification_recipientId_fkey";

-- DropForeignKey
ALTER TABLE "TeamDailyPlan" DROP CONSTRAINT "TeamDailyPlan_submittedById_fkey";

-- DropForeignKey
ALTER TABLE "TeamDailyPlan" DROP CONSTRAINT "TeamDailyPlan_teamWeeklyPlanId_fkey";

-- DropForeignKey
ALTER TABLE "TeamWeeklyPlan" DROP CONSTRAINT "TeamWeeklyPlan_projectId_fkey";

-- DropForeignKey
ALTER TABLE "TeamWeeklyPlan" DROP CONSTRAINT "TeamWeeklyPlan_submittedById_fkey";

-- DropForeignKey
ALTER TABLE "TeamWeeklyPlan" DROP CONSTRAINT "TeamWeeklyPlan_teamId_fkey";

-- DropIndex
DROP INDEX "Company_invited_by_hod_id_idx";

-- DropIndex
DROP INDEX "Project_companyId_deleted_at_idx";

-- DropIndex
DROP INDEX "organization_requests_status_type_idx";

-- AlterTable
ALTER TABLE "CoordinatorReport" ALTER COLUMN "id" DROP DEFAULT;

-- AlterTable
ALTER TABLE "HodSuggestion" ALTER COLUMN "id" DROP DEFAULT;

-- AlterTable
ALTER TABLE "StudentPlan" ALTER COLUMN "id" DROP DEFAULT;

-- AlterTable
ALTER TABLE "SupervisorFeedback" ALTER COLUMN "id" DROP DEFAULT;

-- AlterTable
ALTER TABLE "TeamWeeklyPlan" ADD COLUMN     "tl_comment" TEXT,
ADD COLUMN     "tl_reviewed_at" TIMESTAMP(3),
ADD COLUMN     "tl_status" TEXT NOT NULL DEFAULT 'PENDING';

-- AlterTable
ALTER TABLE "UniversityConfig" ALTER COLUMN "updatedAt" DROP DEFAULT;

-- AlterTable
ALTER TABLE "organization_requests" ALTER COLUMN "verification_doc" SET NOT NULL,
ALTER COLUMN "updated_at" DROP DEFAULT;

-- DropTable
DROP TABLE "AuditLog";

-- CreateIndex
CREATE INDEX "organization_requests_status_idx" ON "organization_requests"("status");

-- AddForeignKey
ALTER TABLE "Notification" ADD CONSTRAINT "Notification_recipientId_fkey" FOREIGN KEY ("recipientId") REFERENCES "User"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "TeamWeeklyPlan" ADD CONSTRAINT "TeamWeeklyPlan_teamId_fkey" FOREIGN KEY ("teamId") REFERENCES "Team"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "TeamWeeklyPlan" ADD CONSTRAINT "TeamWeeklyPlan_projectId_fkey" FOREIGN KEY ("projectId") REFERENCES "Project"("id") ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "TeamWeeklyPlan" ADD CONSTRAINT "TeamWeeklyPlan_submittedById_fkey" FOREIGN KEY ("submittedById") REFERENCES "Student"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "TeamDailyPlan" ADD CONSTRAINT "TeamDailyPlan_teamWeeklyPlanId_fkey" FOREIGN KEY ("teamWeeklyPlanId") REFERENCES "TeamWeeklyPlan"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "TeamDailyPlan" ADD CONSTRAINT "TeamDailyPlan_submittedById_fkey" FOREIGN KEY ("submittedById") REFERENCES "Student"("id") ON DELETE RESTRICT ON UPDATE CASCADE;
