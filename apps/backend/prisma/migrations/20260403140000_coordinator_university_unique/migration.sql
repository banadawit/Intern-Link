-- One university can only have one coordinator
CREATE UNIQUE INDEX IF NOT EXISTS "Coordinator_universityId_key" ON "Coordinator"("universityId");
