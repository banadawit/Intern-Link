-- AlterTable
ALTER TABLE "WeeklyPlan" ADD COLUMN     "feedback" TEXT,
ADD COLUMN     "reviewed_at" TIMESTAMP(3),
ADD COLUMN     "version" INTEGER NOT NULL DEFAULT 1;
