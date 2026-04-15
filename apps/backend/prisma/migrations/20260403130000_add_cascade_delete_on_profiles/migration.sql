-- Drop existing foreign key constraints and re-add with ON DELETE CASCADE

-- Coordinator
ALTER TABLE "Coordinator" DROP CONSTRAINT IF EXISTS "Coordinator_userId_fkey";
ALTER TABLE "Coordinator" ADD CONSTRAINT "Coordinator_userId_fkey"
  FOREIGN KEY ("userId") REFERENCES "User"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- Supervisor
ALTER TABLE "Supervisor" DROP CONSTRAINT IF EXISTS "Supervisor_userId_fkey";
ALTER TABLE "Supervisor" ADD CONSTRAINT "Supervisor_userId_fkey"
  FOREIGN KEY ("userId") REFERENCES "User"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- Student
ALTER TABLE "Student" DROP CONSTRAINT IF EXISTS "Student_userId_fkey";
ALTER TABLE "Student" ADD CONSTRAINT "Student_userId_fkey"
  FOREIGN KEY ("userId") REFERENCES "User"("id") ON DELETE CASCADE ON UPDATE CASCADE;
