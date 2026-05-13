-- Add project manager to Team
ALTER TABLE "Team" ADD COLUMN IF NOT EXISTS "managerId" INTEGER;
ALTER TABLE "Team" DROP CONSTRAINT IF EXISTS "Team_managerId_fkey";
ALTER TABLE "Team" ADD CONSTRAINT "Team_managerId_fkey"
    FOREIGN KEY ("managerId") REFERENCES "Student"("id") ON DELETE SET NULL ON UPDATE CASCADE;

-- Team weekly plans (submitted by project manager on behalf of team)
CREATE TABLE IF NOT EXISTS "TeamWeeklyPlan" (
    "id"              SERIAL PRIMARY KEY,
    "teamId"          INTEGER NOT NULL,
    "projectId"       INTEGER,
    "submittedById"   INTEGER NOT NULL,
    "week_number"     INTEGER NOT NULL,
    "plan_description" TEXT NOT NULL,
    "status"          TEXT NOT NULL DEFAULT 'PENDING',
    "feedback"        TEXT,
    "reviewed_at"     TIMESTAMP(3),
    "submitted_at"    TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "version"         INTEGER NOT NULL DEFAULT 1,
    CONSTRAINT "TeamWeeklyPlan_teamId_fkey" FOREIGN KEY ("teamId") REFERENCES "Team"("id") ON DELETE CASCADE,
    CONSTRAINT "TeamWeeklyPlan_projectId_fkey" FOREIGN KEY ("projectId") REFERENCES "Project"("id") ON DELETE SET NULL,
    CONSTRAINT "TeamWeeklyPlan_submittedById_fkey" FOREIGN KEY ("submittedById") REFERENCES "Student"("id")
);
CREATE UNIQUE INDEX IF NOT EXISTS "TeamWeeklyPlan_teamId_week_number_key" ON "TeamWeeklyPlan"("teamId", "week_number");
CREATE INDEX IF NOT EXISTS "TeamWeeklyPlan_teamId_idx" ON "TeamWeeklyPlan"("teamId");

-- Team daily plans (submitted by project manager on behalf of team)
CREATE TABLE IF NOT EXISTS "TeamDailyPlan" (
    "id"              SERIAL PRIMARY KEY,
    "teamWeeklyPlanId" INTEGER NOT NULL,
    "submittedById"   INTEGER NOT NULL,
    "workDate"        DATE NOT NULL,
    "notes"           TEXT,
    "status"          TEXT NOT NULL DEFAULT 'PENDING',
    "supervisorNote"  TEXT,
    "reviewedAt"      TIMESTAMP(3),
    "submittedAt"     TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT "TeamDailyPlan_teamWeeklyPlanId_fkey" FOREIGN KEY ("teamWeeklyPlanId") REFERENCES "TeamWeeklyPlan"("id") ON DELETE CASCADE,
    CONSTRAINT "TeamDailyPlan_submittedById_fkey" FOREIGN KEY ("submittedById") REFERENCES "Student"("id")
);
CREATE UNIQUE INDEX IF NOT EXISTS "TeamDailyPlan_teamWeeklyPlanId_workDate_key" ON "TeamDailyPlan"("teamWeeklyPlanId", "workDate");
CREATE INDEX IF NOT EXISTS "TeamDailyPlan_teamWeeklyPlanId_idx" ON "TeamDailyPlan"("teamWeeklyPlanId");
