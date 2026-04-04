-- DropForeignKey
ALTER TABLE "Coordinator" DROP CONSTRAINT "Coordinator_universityId_fkey";

-- AddForeignKey
ALTER TABLE "Coordinator" ADD CONSTRAINT "Coordinator_universityId_fkey" FOREIGN KEY ("universityId") REFERENCES "University"("id") ON DELETE SET NULL ON UPDATE CASCADE;
