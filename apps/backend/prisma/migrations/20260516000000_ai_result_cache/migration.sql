-- Cached AI outputs (reduce external API calls)

CREATE TABLE "StudentPlan" (
    "id" UUID NOT NULL DEFAULT gen_random_uuid(),
    "studentId" TEXT NOT NULL,
    "content" TEXT NOT NULL,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "StudentPlan_pkey" PRIMARY KEY ("id")
);

CREATE UNIQUE INDEX "StudentPlan_studentId_key" ON "StudentPlan"("studentId");

CREATE TABLE "SupervisorFeedback" (
    "id" UUID NOT NULL DEFAULT gen_random_uuid(),
    "studentId" TEXT NOT NULL,
    "week" INTEGER NOT NULL,
    "content" TEXT NOT NULL,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "SupervisorFeedback_pkey" PRIMARY KEY ("id")
);

CREATE UNIQUE INDEX "SupervisorFeedback_studentId_week_key" ON "SupervisorFeedback"("studentId", "week");
CREATE INDEX "SupervisorFeedback_studentId_idx" ON "SupervisorFeedback"("studentId");

CREATE TABLE "HodSuggestion" (
    "id" UUID NOT NULL DEFAULT gen_random_uuid(),
    "studentId" TEXT NOT NULL,
    "content" TEXT NOT NULL,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "HodSuggestion_pkey" PRIMARY KEY ("id")
);

CREATE UNIQUE INDEX "HodSuggestion_studentId_key" ON "HodSuggestion"("studentId");

CREATE TABLE "CoordinatorReport" (
    "id" UUID NOT NULL DEFAULT gen_random_uuid(),
    "coordinatorUserId" INTEGER NOT NULL,
    "content" TEXT NOT NULL,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "CoordinatorReport_pkey" PRIMARY KEY ("id")
);

CREATE UNIQUE INDEX "CoordinatorReport_coordinatorUserId_key" ON "CoordinatorReport"("coordinatorUserId");
