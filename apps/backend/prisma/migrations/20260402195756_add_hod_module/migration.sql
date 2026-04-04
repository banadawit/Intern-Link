-- AlterEnum
ALTER TYPE "Role" ADD VALUE 'HOD';

-- AlterTable
ALTER TABLE "InternshipProposal" ADD COLUMN     "expected_duration_weeks" INTEGER,
ADD COLUMN     "expected_outcomes" TEXT,
ADD COLUMN     "responded_at" TIMESTAMP(3);

-- AlterTable
ALTER TABLE "Student" ADD COLUMN     "hod_approval_status" "ApprovalStatus" NOT NULL DEFAULT 'APPROVED';

-- CreateTable
CREATE TABLE "Hod" (
    "id" SERIAL NOT NULL,
    "userId" INTEGER NOT NULL,
    "universityId" INTEGER NOT NULL,
    "department" TEXT NOT NULL,
    "phone_number" TEXT,

    CONSTRAINT "Hod_pkey" PRIMARY KEY ("id")
);

-- CreateIndex
CREATE UNIQUE INDEX "Hod_userId_key" ON "Hod"("userId");

-- CreateIndex
CREATE INDEX "Hod_universityId_department_idx" ON "Hod"("universityId", "department");

-- CreateIndex
CREATE INDEX "InternshipProposal_studentId_companyId_status_idx" ON "InternshipProposal"("studentId", "companyId", "status");

-- AddForeignKey
ALTER TABLE "Hod" ADD CONSTRAINT "Hod_userId_fkey" FOREIGN KEY ("userId") REFERENCES "User"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "Hod" ADD CONSTRAINT "Hod_universityId_fkey" FOREIGN KEY ("universityId") REFERENCES "University"("id") ON DELETE RESTRICT ON UPDATE CASCADE;
