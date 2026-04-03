-- Add hodId to Student (nullable FK to Hod; Prisma model HodProfile @@map("Hod"))
ALTER TABLE "Student" ADD COLUMN IF NOT EXISTS "hodId" INTEGER;

-- Change hod_approval_status default to PENDING for new students
ALTER TABLE "Student" ALTER COLUMN "hod_approval_status" SET DEFAULT 'PENDING';

-- Foreign key (table name is "Hod", not "HodProfile")
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'Student_hodId_fkey') THEN
    ALTER TABLE "Student" ADD CONSTRAINT "Student_hodId_fkey"
      FOREIGN KEY ("hodId") REFERENCES "Hod"("id") ON DELETE SET NULL ON UPDATE CASCADE;
  END IF;
END $$;
