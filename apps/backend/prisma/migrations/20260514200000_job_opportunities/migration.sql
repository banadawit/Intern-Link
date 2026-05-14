-- Job Opportunity feature: extended metadata, questions, applications, answers

CREATE TABLE IF NOT EXISTS "JobOpportunity" (
    "id"       SERIAL PRIMARY KEY,
    "postId"   INTEGER NOT NULL,
    "deadline" TIMESTAMP(3),
    "slots"    INTEGER NOT NULL DEFAULT 1,
    "status"   TEXT NOT NULL DEFAULT 'OPEN',
    CONSTRAINT "JobOpportunity_postId_fkey"
        FOREIGN KEY ("postId") REFERENCES "CommonPost"("id") ON DELETE CASCADE ON UPDATE CASCADE
);
CREATE UNIQUE INDEX IF NOT EXISTS "JobOpportunity_postId_key" ON "JobOpportunity"("postId");
CREATE INDEX IF NOT EXISTS "JobOpportunity_status_idx" ON "JobOpportunity"("status");

CREATE TABLE IF NOT EXISTS "JobQuestion" (
    "id"            SERIAL PRIMARY KEY,
    "opportunityId" INTEGER NOT NULL,
    "question"      TEXT NOT NULL,
    "required"      BOOLEAN NOT NULL DEFAULT TRUE,
    "order"         INTEGER NOT NULL DEFAULT 0,
    CONSTRAINT "JobQuestion_opportunityId_fkey"
        FOREIGN KEY ("opportunityId") REFERENCES "JobOpportunity"("id") ON DELETE CASCADE ON UPDATE CASCADE
);
CREATE INDEX IF NOT EXISTS "JobQuestion_opportunityId_idx" ON "JobQuestion"("opportunityId");

CREATE TABLE IF NOT EXISTS "JobApplication" (
    "id"            SERIAL PRIMARY KEY,
    "opportunityId" INTEGER NOT NULL,
    "studentId"     INTEGER NOT NULL,
    "status"        TEXT NOT NULL DEFAULT 'PENDING',
    "appliedAt"     TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "reviewedAt"    TIMESTAMP(3),
    CONSTRAINT "JobApplication_opportunityId_fkey"
        FOREIGN KEY ("opportunityId") REFERENCES "JobOpportunity"("id") ON DELETE CASCADE ON UPDATE CASCADE,
    CONSTRAINT "JobApplication_studentId_fkey"
        FOREIGN KEY ("studentId") REFERENCES "Student"("id") ON DELETE CASCADE ON UPDATE CASCADE
);
CREATE UNIQUE INDEX IF NOT EXISTS "JobApplication_opportunityId_studentId_key"
    ON "JobApplication"("opportunityId", "studentId");
CREATE INDEX IF NOT EXISTS "JobApplication_opportunityId_idx" ON "JobApplication"("opportunityId");
CREATE INDEX IF NOT EXISTS "JobApplication_studentId_idx" ON "JobApplication"("studentId");

CREATE TABLE IF NOT EXISTS "JobAnswer" (
    "id"            SERIAL PRIMARY KEY,
    "applicationId" INTEGER NOT NULL,
    "questionId"    INTEGER NOT NULL,
    "answer"        TEXT NOT NULL,
    CONSTRAINT "JobAnswer_applicationId_fkey"
        FOREIGN KEY ("applicationId") REFERENCES "JobApplication"("id") ON DELETE CASCADE ON UPDATE CASCADE,
    CONSTRAINT "JobAnswer_questionId_fkey"
        FOREIGN KEY ("questionId") REFERENCES "JobQuestion"("id") ON DELETE CASCADE ON UPDATE CASCADE
);
CREATE UNIQUE INDEX IF NOT EXISTS "JobAnswer_applicationId_questionId_key"
    ON "JobAnswer"("applicationId", "questionId");
