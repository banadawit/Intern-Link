-- CreateTable
CREATE TABLE "WeeklyPlanDaySubmission" (
    "id" SERIAL NOT NULL,
    "weeklyPlanId" INTEGER NOT NULL,
    "workDate" DATE NOT NULL,
    "notes" TEXT,
    "submittedAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "WeeklyPlanDaySubmission_pkey" PRIMARY KEY ("id")
);

-- CreateIndex
CREATE UNIQUE INDEX "WeeklyPlanDaySubmission_weeklyPlanId_workDate_key" ON "WeeklyPlanDaySubmission"("weeklyPlanId", "workDate");

-- CreateIndex
CREATE INDEX "WeeklyPlanDaySubmission_weeklyPlanId_idx" ON "WeeklyPlanDaySubmission"("weeklyPlanId");

-- AddForeignKey
ALTER TABLE "WeeklyPlanDaySubmission" ADD CONSTRAINT "WeeklyPlanDaySubmission_weeklyPlanId_fkey" FOREIGN KEY ("weeklyPlanId") REFERENCES "WeeklyPlan"("id") ON DELETE CASCADE ON UPDATE CASCADE;
