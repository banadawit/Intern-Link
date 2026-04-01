-- CreateEnum
CREATE TYPE "AttendanceStatus" AS ENUM ('PRESENT', 'ABSENT', 'LATE');

-- AlterTable Report
ALTER TABLE "Report" ADD COLUMN "sent_at" TIMESTAMP(3),
ADD COLUMN "locked" BOOLEAN NOT NULL DEFAULT false,
ADD COLUMN "sentToUniversityId" INTEGER;

-- AddForeignKey Report -> University
ALTER TABLE "Report" ADD CONSTRAINT "Report_sentToUniversityId_fkey" FOREIGN KEY ("sentToUniversityId") REFERENCES "University"("id") ON DELETE SET NULL ON UPDATE CASCADE;

-- WeeklyReport: add new columns before data migration
ALTER TABLE "WeeklyReport" ADD COLUMN "weeklyPlanId" INTEGER,
ADD COLUMN "attendanceStatus" "AttendanceStatus",
ADD COLUMN "execution_status" TEXT;

-- Backfill attendance from legacy boolean
UPDATE "WeeklyReport" SET "attendanceStatus" = CASE WHEN "attendance" = true THEN 'PRESENT'::"AttendanceStatus" ELSE 'ABSENT'::"AttendanceStatus" END;

ALTER TABLE "WeeklyReport" ALTER COLUMN "attendanceStatus" SET NOT NULL,
ALTER COLUMN "attendanceStatus" SET DEFAULT 'PRESENT'::"AttendanceStatus";

ALTER TABLE "WeeklyReport" DROP COLUMN "attendance";

-- Unique weekly plan per report row (nullable allowed multiple times in PG)
CREATE UNIQUE INDEX "WeeklyReport_weeklyPlanId_key" ON "WeeklyReport"("weeklyPlanId");

-- FKs for WeeklyReport
ALTER TABLE "WeeklyReport" ADD CONSTRAINT "WeeklyReport_studentId_fkey" FOREIGN KEY ("studentId") REFERENCES "Student"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

ALTER TABLE "WeeklyReport" ADD CONSTRAINT "WeeklyReport_weeklyPlanId_fkey" FOREIGN KEY ("weeklyPlanId") REFERENCES "WeeklyPlan"("id") ON DELETE SET NULL ON UPDATE CASCADE;

-- Team / Project
CREATE TABLE "Team" (
    "id" SERIAL NOT NULL,
    "name" TEXT NOT NULL,
    "companyId" INTEGER NOT NULL,
    "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "Team_pkey" PRIMARY KEY ("id")
);

CREATE TABLE "StudentTeam" (
    "studentId" INTEGER NOT NULL,
    "teamId" INTEGER NOT NULL,

    CONSTRAINT "StudentTeam_pkey" PRIMARY KEY ("studentId","teamId")
);

CREATE TABLE "Project" (
    "id" SERIAL NOT NULL,
    "name" TEXT NOT NULL,
    "companyId" INTEGER NOT NULL,
    "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "Project_pkey" PRIMARY KEY ("id")
);

CREATE TABLE "StudentProject" (
    "studentId" INTEGER NOT NULL,
    "projectId" INTEGER NOT NULL,

    CONSTRAINT "StudentProject_pkey" PRIMARY KEY ("studentId","projectId")
);

ALTER TABLE "Team" ADD CONSTRAINT "Team_companyId_fkey" FOREIGN KEY ("companyId") REFERENCES "Company"("id") ON DELETE CASCADE ON UPDATE CASCADE;

ALTER TABLE "StudentTeam" ADD CONSTRAINT "StudentTeam_studentId_fkey" FOREIGN KEY ("studentId") REFERENCES "Student"("id") ON DELETE CASCADE ON UPDATE CASCADE;

ALTER TABLE "StudentTeam" ADD CONSTRAINT "StudentTeam_teamId_fkey" FOREIGN KEY ("teamId") REFERENCES "Team"("id") ON DELETE CASCADE ON UPDATE CASCADE;

ALTER TABLE "Project" ADD CONSTRAINT "Project_companyId_fkey" FOREIGN KEY ("companyId") REFERENCES "Company"("id") ON DELETE CASCADE ON UPDATE CASCADE;

ALTER TABLE "StudentProject" ADD CONSTRAINT "StudentProject_studentId_fkey" FOREIGN KEY ("studentId") REFERENCES "Student"("id") ON DELETE CASCADE ON UPDATE CASCADE;

ALTER TABLE "StudentProject" ADD CONSTRAINT "StudentProject_projectId_fkey" FOREIGN KEY ("projectId") REFERENCES "Project"("id") ON DELETE CASCADE ON UPDATE CASCADE;
