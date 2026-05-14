-- Add managerId column to Team table for Team Leader assignment
ALTER TABLE "Team" ADD COLUMN IF NOT EXISTS "managerId" INTEGER;

-- Add foreign key constraint
ALTER TABLE "Team" ADD CONSTRAINT "Team_managerId_fkey"
  FOREIGN KEY ("managerId") REFERENCES "Student"("id")
  ON DELETE SET NULL ON UPDATE CASCADE;
